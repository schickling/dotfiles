Dynamic Tab Titles in Zellij via a WASM Plugin

Confirming the Plugin Approach

You’re correct – using a Zellij WASM plugin is the viable way to achieve dynamic tab names reflecting the current command. Zellij by default does not propagate the usual ANSI OSC title sequence to tab names (there’s an open issue about this) ￼. In fact, Zellij does recognize the OSC escape sequence for setting titles (ESC ] 0 ; title BEL), but it applies it to pane titles rather than tab titles ￼. This means when a shell or program inside Zellij sets the terminal title, Zellij updates an internal pane title property, but the tab label remains the generic “Tab #N”.

Because of this, a plugin is needed to bridge the gap. The plugin can listen for pane title updates and then programmatically rename the tab to match. This approach has been validated in experimentation: Zellij’s plugin API allows subscribing to pane updates and renaming tabs, making it suitable for our use-case ￼ ￼.

Alternative solutions (like shell hooks to call zellij action rename-tab) exist and can partially work – for example, using Zsh or Fish hooks to rename the tab on each command ￼. However, those methods only update the tab when a new command starts or finishes, and won’t capture title changes that occur during a running program (e.g. Vim updating the title to the current file). They also require per-shell configuration and add slight overhead ￼. A plugin integrated into Zellij itself can react to any title change (including mid-command) and work across all shells, which makes it a more robust and general solution.

Conclusion: Yes, a Zellij WASM plugin is the right approach to get dynamic tab names. Next, we’ll lay out a detailed implementation plan and then a comprehensive testing strategy to ensure it works with minimal manual intervention.

Implementation Plan

1. Enable Shell and Program Title Updates via OSC

To have tab names reflect the current command or context, we first need the shell/program to emit the appropriate title update signals. Zellij will pick these up as pane title changes. Key steps:
	•	Configure your Shell to set the title on commands: Set up your shell’s pre-execution and post-execution hooks to send an ANSI OSC 0 sequence with the desired title. For example:
	•	For Zsh: Use the preexec hook to set title to the command being run, and precmd (runs before each prompt display) to set title back to something like the current directory. The following snippet (from Jonathan Davies’ solution) illustrates this:

function change_tab_title() {
  local title=$1
  command nohup zellij action rename-tab "$title" >/dev/null 2>&1
}
function set_tab_to_working_dir() {
  local title=$(basename "$PWD")   # or derive current dir
  change_tab_title "$title"
}
function set_tab_to_command_line() {
  local cmd="$1"
  change_tab_title "$cmd"
}
if [[ -n $ZELLIJ ]]; then
  add-zsh-hook precmd  set_tab_to_working_dir
  add-zsh-hook preexec set_tab_to_command_line
fi

In our plugin-based approach, we’ll modify this idea: instead of calling rename-tab directly from the shell, we’ll just emit the OSC sequence so the plugin can handle it. For example:

# Zsh pseudocode for OSC title
function set_title_osc() {
  print -n "\033]0;$1\007"
}
if [[ -n $ZELLIJ ]]; then
  add-zsh-hook preexec  'set_title_osc "$1"'   # $1 = full command line
  add-zsh-hook precmd   'set_title_osc "$(basename $PWD)"'
fi


	•	For Fish shell: Use fish_preexec and fish_postexec events. For example:

function fish_preexec --on-event fish_preexec
  if test -n "$ZELLIJ"
    set cmd (string split " " -- $argv | head -1)
    printf "\033]0;%s\007" "$cmd"
  end
end
function fish_postexec --on-event fish_postexec
  if test -n "$ZELLIJ"
    printf "\033]0;%s\007" (basename (pwd))
  end
end

This will set the pane title to the command name on execution, and back to the current directory on return to prompt. (In earlier experimentation, Fish could send OSC titles successfully ￼.)

	•	For Bash: Bash doesn’t have built-in preexec hooks by default, but you can use the DEBUG trap or install a framework like bash-preexec. For brevity: using a DEBUG trap, capture the command and echo the OSC sequence; use PROMPT_COMMAND to set title on each prompt (for directory or idle state).

	•	Ensure programs update titles if needed: Many full-screen programs (vim, less, etc.) can be configured to update the terminal title. For example, in Vim you can enable :set title which will send OSC title updates (often containing the filename). Verify such options are on. Our plugin will catch these as well.

Why this step matters: The plugin can only react to title changes if something triggers those changes. By setting up your shell and programs to emit OSC \033]0;…\007 sequences, you ensure the pane’s title is always reflecting the current context (command or active task). Zellij will internally register those (even though it won’t display them on its own) ￼ ￼. This provides the raw data our plugin will use.

2. Develop the Zellij WASM Plugin

Next, we create a Rust-based plugin that listens for pane title changes and renames tabs accordingly. Key steps in development:
	•	Set up Rust project for the plugin: Create a new Rust library project (since Zellij plugins are compiled to WebAssembly). Ensure you have the WASM target installed:

rustup target add wasm32-wasip1

Add zellij-tile (the Zellij plugin API crate) as a dependency, using the version matching your Zellij (e.g., 0.42.x). The plugin in our example will be named “auto-tabname” for clarity.

	•	Implement the plugin structure: At minimum, you need to define a struct and implement the ZellijPlugin trait for it, then register the plugin. For example: ￼ ￼

use zellij_tile::prelude::*;

struct AutoTabName;           // plugin state (can store config if needed)
impl Default for AutoTabName {
    fn default() -> Self { AutoTabName }
}
register_plugin!(AutoTabName);

impl ZellijPlugin for AutoTabName {
    fn load(&mut self, config: BTreeMap<String, String>) {
        // Request necessary permissions from Zellij
        request_permission(&[
            PermissionType::ReadApplicationState,   // to read pane info
            PermissionType::ChangeApplicationState // to rename tabs
        ]);
        subscribe(&[EventType::PaneUpdate]);  // subscribe to pane updates
        // (You could also handle TabUpdate events, but PaneUpdate suffices here)
    }
    fn update(&mut self, event: Event) -> bool {
        if let Event::PaneUpdate(panes_manifest) = event {
            // (We'll fill in logic below)
            // ...
        }
        true  // return true to continue receiving events
    }
    fn render(&mut self, rows: usize, cols: usize) {
        // Minimal render to avoid "plugin pane error". We don't actually need to display anything.
        print!("\u{2800}");  // print a blank Braille pattern character (invisible) or a space
    }
}

This sets up the plugin to listen for PaneUpdate events. The call to request_permission is crucial: renaming tabs is an action that changes application state, so we must declare that permission ￼. Subscribing to PaneUpdate means our update function will be called whenever any pane’s state (size, focus, title, etc.) changes.

	•	Implement the core logic in update: We need to scan the pane update information to find the relevant pane and title. Zellij’s PaneUpdate event provides a manifest of all tabs and panes. In practice, you’ll get something like a map of tab IDs to lists of pane info. We should find the focused pane in each tab (or specifically in the tab where our plugin instance lives) and if that pane has a non-empty title, use it for the tab name. For example:

if let Event::PaneUpdate(manifest) = event {
    for (tab_index, panes) in manifest.panes {
        for pane in panes {
            if pane.is_focused && !pane.title.is_empty() {
                let new_name = format!("> {}", pane.title);
                rename_tab(tab_index, &new_name);
            }
        }
    }
}

This pseudocode loops through each tab’s panes; whenever it finds a focused pane with a title, it calls rename_tab(tab_index, new_name). Here rename_tab is a plugin API function (or macro) that renames the tab given its index (or ID) ￼. We prepend a prefix ("> ") to the title to visually distinguish it (configurable, see below). This is the heart of the plugin: it effectively syncs the pane title to the tab title in real time.
A few implementation notes:
	•	Determining tab_index: The manifest.panes structure keys are the tab identifiers (likely indices). In the loop above, tab_index corresponds to that tab. So renaming using it ensures we rename the correct tab.
	•	Focus logic: We use pane.is_focused to decide which pane’s title to take. This means if you have multiple panes in a tab, the tab name will reflect whichever pane is currently focused (which is a sensible choice – presumably that’s the one you’re actively using). This way, if you switch focus between splits, the tab title will update accordingly.
	•	Empty titles: We check !pane.title.is_empty() to avoid renaming the tab to an empty string (which could happen if no title has been set yet). If no pane in a tab has a title, the plugin simply won’t change that tab name (it will stay at the default or previous name).
	•	Permissions recap: Because we subscribed to PaneUpdate and call rename_tab, we ensured to request ReadApplicationState and ChangeApplicationState. Zellij requires explicit permission for plugins to do these operations for security.
	•	Prefix configuration (optional): In the example we prefix the title with "> ". You can make this configurable via the plugin config. Zellij passes a config map into load() (the config: BTreeMap<String, String> parameter) that can include user-defined keys. For instance, we could allow a config like { prefix = "> " } and use that instead of a hardcoded “>”. This would be defined in the Zellij config when loading the plugin (see next section).
	•	Avoiding flicker or loops: Renaming a tab might itself emit a PaneUpdate (as the tab state changed). To avoid any potential feedback loop or thrash, we could add logic to only rename if the tab’s current name differs from the desired name. (The plugin API may have a way to get the current tab name, or we might track the last name we set.) This ensures we don’t continuously call rename on every event if nothing truly changed. It’s a minor optimization since PaneUpdate events may fire frequently. The logic could be: if focused pane title is not empty and different from the tab’s existing name (minus prefix), then rename. (However, the overhead of an extra rename is small, so this is just a precaution).

	•	Compile the plugin to WASM: Run cargo build --release --target wasm32-wasip1. This will produce a .wasm file (e.g., target/wasm32-wasip1/release/zellij_auto_tabname.wasm). This is the file Zellij can load as a plugin.

By following these steps, we build a plugin that listens for pane title changes and updates tab names accordingly. This addresses both scenarios you care about:
	•	When launching a new command: your shell’s preexec hook will send an OSC with the command name, triggering a pane title update and thus a plugin rename for the tab (e.g. tab name becomes “> vim” when you launch vim) ￼.
	•	During a running command: if the application sends title updates (e.g. Vim changing the title to the current file or mode), each update will fire a PaneUpdate event and the plugin will update the tab name to match (e.g. changing file in Vim could update tab name to “> vim - file.txt” if that’s what Vim sets as title).

Importantly, this plugin works for all tabs (we will ensure it’s loaded in each tab or globally), and it uses the actual program/shell-provided title, which typically corresponds to the current shell command or program state.

3. Integrate the Plugin into Zellij Configuration

With the plugin built, the next step is to load it in Zellij so that it’s active for your sessions. There are a couple of ways to do this; we’ll choose the method that works reliably with minimal user intervention:
	•	Place the plugin file: Decide on a location for the compiled .wasm plugin file. A convenient location is within Zellij’s config directory. For example, you could put it at ~/.config/zellij/plugins/auto-tabname.wasm (ensure the directory exists). The path can be anything; we’ll refer to it in the config.
	•	Register and load the plugin via Zellij config/layout:
	•	In Zellij’s configuration (typically ~/.config/zellij/config.kdl), under the plugins section, register the plugin with a name and location. For example, in config.kdl:

plugins {
    auto-tabname location "file:/home/youruser/.config/zellij/plugins/auto-tabname.wasm" {
        prefix "> "
    }
}

This declares a plugin named auto-tabname and where to load it from. The block { prefix "> " } is an example of passing a configuration option to the plugin (so inside our plugin’s load function, we could read config.get("prefix")). This is optional – you can hardcode the prefix in code if desired.

	•	Next, we need to ensure the plugin actually runs. There are two approaches:
	1.	Using a layout with a plugin pane: You can create a custom layout that automatically opens a tiny pane running the plugin in each tab. For example, create a layout file ~/.config/zellij/layouts/auto_tabname_layout.kdl:

layout {
  tab {
    name "Main"  // initial tab name (will be overridden by plugin once running)
    pane size=1 borderless=true {
      plugin auto-tabname  // use the plugin (prefix config is already set via config.kdl)
    }
    pane {  // main working pane
      command "fish"   // or your shell, to ensure it opens the shell in this pane
    }
  }
}

This layout defines a tab with two panes: a very small (1-row) borderless pane running the plugin, and a main pane (running your shell). The plugin pane being size=1 and borderless means it will occupy only one line at the top and have no visible border, minimizing its interference. The plugin’s render just prints a blank, so effectively you won’t see anything there. Zellij requires plugin panes to have at least 1 line of height (size=0 is not allowed) ￼, hence the minimal size.
Now, when you start Zellij with this layout, the plugin will be running in the background of that tab and will rename tabs as needed. To use the layout, launch Zellij as:

zellij --layout ~/.config/zellij/layouts/auto_tabname_layout.kdl

You can make this the default by aliasing zellij to that command or configuring Zellij to use a default layout (if supported).
New tabs: If you open additional tabs, you’ll want the plugin to run there as well. One way is to always open new tabs via the same layout. Zellij’s new-tab action accepts a --layout parameter; you can bind a key for opening a new tab with the plugin. For example, in config.kdl under keybinds, add something like:

keybinds {
  normal {
    "Ctrl-t" => { new_tab layout "~/.config/zellij/layouts/auto_tabname_layout.kdl" }
  }
}

This means Ctrl+t will open a new tab using our layout (so it includes the plugin pane). Alternatively, you could duplicate the plugin pane in all tabs manually, but using a layout or binding makes it automatic.

	2.	Using load_plugins (headless plugin): Zellij has an option to load plugins in the background via the layout or config load_plugins section. In theory, you could do:

load_plugins {
  auto-tabname
}

in your config, to load the plugin without requiring a visible pane. However, current versions have reported issues with this method ￼ ￼ – some users found that load_plugins didn’t reliably start the plugin, or the plugin might not run without a UI pane. Because we want a reliable, minimal-effort solution, the layout/pane method described above is the surest path right now.
Note: Keep an eye on Zellij’s updates – if they improve headless plugin support, you could switch to using load_plugins to have the plugin run globally for the session (covering all tabs by design). But until confirmed, the layout approach is our recommended solution.

	•	Security considerations: Since you mentioned being careful about security – our plugin is fairly simple and runs inside Zellij’s sandboxed environment. It only reacts to data (pane titles) that programs themselves set. Ensure you only use trusted plugin code (in this case, it’s your own) and be mindful that the plugin has ChangeApplicationState permission (meaning it can automate Zellij actions like renaming tabs). We do not read or write any files or execute external commands, so the surface for security issues is minimal. Just avoid any plugin logic that would interpret the pane title in a dangerous way. For instance, treat the pane title as plain text; do not attempt to execute it or use it in file paths without sanitization. Our implementation simply copies it into the tab name string, which is safe.
	•	Performance considerations: Renaming tabs is a lightweight operation. Even if a program updates the title frequently (say, every second), the overhead should be negligible. Zellij handles tab name changes internally. We just ensure to not do it more often than necessary. In testing, no performance issues were observed ￼ (the shell-hook approach added only a few milliseconds delay; the plugin approach should be even more efficient since it’s internal).

After integrating the plugin, you should start a Zellij session with the plugin active (via the specified layout or config). Immediately, you can test by running a command or two and seeing if the tab title changes. We’ll outline a rigorous test plan next.

Testing Plan (End-to-End)

To ensure the plugin and setup work correctly without extensive manual fiddling, we can devise both automated and structured manual tests. The goal is to cover various scenarios: new commands, long-running programs with dynamic titles, multiple panes, multiple tabs, etc.

1. Unit Testing the Plugin Logic (Isolation)

It’s good practice to test the core logic of the plugin in isolation. We can simulate the events it will receive:
	•	Simulate PaneUpdate events: Write a unit test in Rust for the plugin crate (you can create a non-WASM test that calls the update function directly). Construct a dummy Event::PaneUpdate with a panes manifest that includes a focused pane with a given title, and verify that after calling update, the tab rename action is triggered appropriately. (We might need to refactor the plugin code to allow injecting a mock for the rename_tab function or check some state because in actual plugin, rename_tab directly performs the action. Another strategy is to refactor the logic of selecting a title into a pure function that we can test.)
	•	Test title selection: Feed different scenarios:
	•	No pane has a title: plugin should do nothing (tab name unchanged).
	•	A focused pane with title “vim” and another unfocused pane with title “bash”: ensure the plugin picks “vim”.
	•	Focused pane title empty, another pane has title: nothing happens because focused one is what we key off (which is correct as we only rename for the focused pane).
	•	Special characters in title (spaces, symbols): ensure they would be formatted correctly (the plugin just copies them into the string; Zellij should handle displaying them).
	•	Security check: Try a malicious-looking title (e.g. a title that contains an OSC sequence or newline). In practice, Zellij should not forward raw control characters in pane titles to plugins or UI beyond the OSC termination. Titles might be sanitized or limited to plain text. Our plugin would just take the pane.title string given by Zellij. We can assert that our plugin does not alter or execute such strings – it only uses them as-is for tab naming. (This is more a code inspection, since our function is straightforward.)

These unit tests give confidence that the logic does what we expect with controlled input.

2. Integration Testing in a Live Zellij Session

The real proof is running Zellij with the plugin and observing the behavior. We want to automate this as much as possible:

Automated integration test approach: We can leverage Zellij’s CLI actions and a multiplexed environment to verify tab names:
	1.	Start a Zellij session with plugin: Launch zellij --layout auto_tabname_layout.kdl --session testSession (naming the session “testSession” so we can target it).
	2.	Initial state check: Immediately run (from outside, in a regular shell) zellij action query-tab-names --session testSession. This will output the list of tab names ￼. Initially, it might show "Main" (or “Tab #1”) if our layout named it “Main”. That’s fine.
	3.	Programmatic command execution: We need to run commands inside the Zellij pane. One way is to simulate keystrokes or use zellij action write to send keystrokes to the terminal pane. For example,

zellij action write "vim\n" --session testSession

might type “vim” and Enter in the active pane (starting Vim). However, this might be tricky if Zellij’s write action is not implemented or if timing is an issue. An easier method is to attach another Zellij client to the session and drive it via a pseudo-tty or expect script. This gets complex, so consider a simpler approach:
	•	Instead, for testing, you can start Zellij with a predetermined command in the pane. For example, modify the layout to automatically run a test script:

pane { command "/path/to/test_script.sh" }

where test_script.sh runs a sequence of commands and sleeps, allowing us to observe changes. For instance, the script could be:

#!/usr/bin/env bash
echo -ne "\033]0;TEST1\007"; sleep 2
echo -ne "\033]0;TEST2\007"; sleep 2

This will simulate a program that first sets the title “TEST1”, waits 2 seconds (to allow observation), then sets “TEST2”. With the plugin running, the tab title should change accordingly.

	•	We could have the script then exit, which returns control to shell, and then maybe script ends the session. But we might not need to fully automate exit; we can just close manually after observing output.

	4.	Observe tab name changes: While the above test script runs, use zellij action query-tab-names in a loop or with delays to capture the tab name changes. For example:

while :; do zellij action query-tab-names --session testSession; sleep 1; done

You should see the output switching from "Main" to "> TEST1" and then to "> TEST2". This confirms that the plugin catches mid-program title changes.

	5.	Test normal shell usage: After the script or as a separate test, attach to the session interactively (just run zellij attach testSession), open a new tab (via our Ctrl+t binding or layout command) and try a few real commands manually:
	•	Run a simple command like ls – the tab name should briefly become "> ls" while ls runs (which is very quick). If your shell’s preexec hook is set up, it will set the title to “ls” before execution. Because ls finishes almost instantly, you might not visually catch the change unless the hook also sets a postexec title (like directory) after – which we did configure. In that case, you might see "> ls" flash, then the tab name might become "> myfolder" (assuming the prefix and current directory name) once back at prompt.
	•	Run a longer command, e.g., sleep 5 – the tab should show "> sleep" during those 5 seconds, then switch to "> directory" afterward.
	•	Open Vim in that tab (assuming Vim is configured to set terminal titles, e.g., :set title). The tab should change to something like "> vim" or "> vim - somefile" when Vim starts (depending on what title Vim sets by default; it might include the file name). Within Vim, open a file or switch to a different file; if Vim updates the title to the file name, the tab name should update accordingly without leaving Vim. This tests dynamic in-app updates.
	•	Try multiple panes in one tab: Split the pane (e.g., Zellij default key Ctrl-p then % for vertical split). In one pane run top (if it doesn’t set title, manually set a title by running echo -ne "\033]0;TOP\007" in that pane). In the other pane, maybe run htop or another command with a different title. Now, switch focus between the panes (with Zellij’s pane focus keys). The tab title should switch between "> TOP" and "> htop" (or whatever titles you set) depending on which pane is focused. This verifies the “focused pane drives the title” logic.
	•	Open another tab (again with the plugin loaded via our keybind/new-tab layout). In that tab, do a different command. Ensure that each tab independently updates its name based on its own focused pane. For example, Tab1 running Vim, Tab2 at a shell prompt – Tab1 might show "> vim", Tab2 might show "> ~" (if ~ is your current directory as set by precmd). Switch between tabs and verify the names persist and update correctly when you go back.
	•	Also test the case of closing a program: e.g., in a tab run a command that ends or press Ctrl+C – after it ends, the shell should reset the title to the directory (via precmd hook), and the plugin should update the tab to that. So you don’t end up with a stale command name after the command is done.
	•	Finally, test undo: If you ever manually rename a tab (with the keyboard shortcut or zellij action rename-tab manually) while the plugin is running, the plugin may override it on the next pane title change. Our plugin currently doesn’t check for a “user set name” vs automated. If this matters, one could enhance the plugin to detect manual renames (maybe by listening to TabUpdate events or tracking if the new name matches pane title). For now, just be aware in testing that manual renames will be temporary. Using undo-rename-tab (Zellij action) will revert to default numbering, which the plugin will then overwrite on the next update as well.
Throughout these manual tests, keep an eye on the tab labels in the status bar to ensure they match expectations at each step. The changes should be nearly instantaneous on receiving the OSC sequences.

Minimal manual effort: The above can be semi-automated. For example, the use of query-tab-names allows checking the tab titles programmatically at any point ￼. You could write an Expect script to spawn zellij with the plugin, send commands, and parse the output of query-tab-names. However, given that visual confirmation in the UI is straightforward, it might be sufficient to manually observe the tab titles for each scenario. The key is that by following the structured scenarios above, you are systematically covering all important cases with predictable outcomes, reducing any guesswork.

3. Testing Edge Cases and Robustness
	•	No OSC/title support: What if a command doesn’t set any title and the shell hook didn’t run (perhaps user forgot to configure it)? In this case, the pane title stays empty and the plugin will not rename the tab (leaving the default “Tab #N” or last name). This is expected. We should test that it at least doesn’t crash. For example, if you remove the shell OSC hooks and run a command, nothing should happen (and no errors). Our checks for !pane.title.is_empty() ensure we skip empties.
	•	Special characters: Test a command or title with spaces or special characters. For example:
	•	In the shell, try: echo -ne "\033]0;Hello World!\007". The tab should become "> Hello World!" (including space and exclamation). Or name a vim window weirdly. Ensure the UI displays it properly. Zellij tab bar should handle basic UTF-8 and ASCII fine. If you see any rendering issues (very long titles truncating, etc.), that’s mostly cosmetic and handled by Zellij (tabs might truncate if too long for the screen width).
	•	Performance under rapid changes: If you have a program that rapidly updates the title (say every 0.1s), you might want to see that Zellij handles it. (Perhaps simulate with a loop that prints OSC titles in quick succession.) The expectation is that it will work, but very rapid changes might not be human-readable anyway. The main thing is to ensure it doesn’t lock up or crash. The plugin logic is simple enough that it should be fine.
	•	Multiple clients: If you attach two viewers/clients to the same Zellij session (possible with Zellij), and each is on a different tab, our plugin is still running once per tab in the session context, so it will update tab names session-wide. There shouldn’t be an issue, but it’s an esoteric case to note.

4. Iterative Development and Debugging

To minimize pain in testing, adopt an iterative approach:
	1.	Start with the simplest case: maybe initially have the plugin just print something visible when it loads or when it gets an event. For example, in update, do eprintln!("Got pane update!") or write to the plugin pane output (via print!) for debugging. Run Zellij and ensure the plugin is indeed loading (you might see a flash of “Got pane update” text in the tiny pane or check Zellij logs).
	2.	Once confirmed, enable the actual renaming logic. Test with one tab, one pane, one simple command.
	3.	Gradually test more complex scenarios (multiple panes, multiple tabs, long-running commands).
	4.	If something isn’t working, use available tools: zellij action query-pane-tiles or list-clients to see what Zellij thinks the running command is, etc. Remember that debugging prints from a WASM plugin can be tricky – eprintln! might not show up easily. One method is to have the plugin draw debug info in its render output (since we have a pane, we can temporarily print the last seen title in the plugin pane for debugging).
	5.	Clean up the debug output and ensure the plugin pane is effectively invisible (our use of borderless and printing just a blank character achieves that without causing the “ERROR IN PLUGIN” message ￼).

By following these steps and test cases, you should arrive at a solution where each Zellij tab automatically displays the name of the currently running command or program. From launching a new editor to switching between builds, your tab titles will update in real time, making it much easier to navigate your workspace at a glance.

And because we’ve emphasized automated hooks and a plugin-driven approach, once this is set up, no manual intervention is needed during daily use – it will “just work”. The testing ensures reliability so you won’t encounter surprises during normal operation.

Sources
	•	Zellij Plugin development notes and code examples ￼ ￼
	•	User community solutions for dynamic tab names (shell hook methods) ￼ ￼
	•	Zellij documentation on actions and plugin configuration ￼ ￼