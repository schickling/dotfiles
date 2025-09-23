# Git worktree helper used by the `gwt` function.

# Share root path with completion helpers.
if not set -q __gwt_worktrees_root
    set -g __gwt_worktrees_root /home/schickling/code/worktrees
end

if functions -q __gwt_sanitize_path
    functions -e __gwt_sanitize_path
end
function __gwt_sanitize_path --description 'Normalize worktree directory name'
    set -l raw $argv[1]
    set -l sanitized (string replace -a '/' '--' -- $raw)
    set sanitized (string replace -ra '[^A-Za-z0-9._-]+' '-' -- $sanitized)
    set sanitized (string replace -r '^-+|-+$' '' -- $sanitized)
    if test -z "$sanitized"
        echo ""
    else
        echo $sanitized
    end
end

if functions -q __gwt_random_slug
    functions -e __gwt_random_slug
end
function __gwt_random_slug --description 'Generate default slug for new worktree'
    set -l adjectives \
        agile \
        bold \
        bright \
        clever \
        eager \
        gentle \
        keen \
        lively \
        noble \
        rapid \
        swift \
        valiant
    set -l surnames \
        ada \
        babbage \
        bernerslee \
        curie \
        hopper \
        kapor \
        lamarr \
        lovelace \
        meitner \
        newton \
        tesla \
        turing

    set -l adj_count (count $adjectives)
    set -l noun_count (count $surnames)
    if test $adj_count -eq 0 -o $noun_count -eq 0
        echo branch-(random)
        return 0
    end

    set -l rand_adj (random)
    set -l rand_noun (random)
    set -l rand_suffix (random)

    set -l adj_index (math "($rand_adj % $adj_count) + 1")
    set -l noun_index (math "($rand_noun % $noun_count) + 1")
    set -l suffix (math "($rand_suffix % 100) + 1")

    set -l slug "$adjectives[$adj_index]-$surnames[$noun_index]-$suffix"
    echo $slug
end

if functions -q __gwt_pull_main_worktree
    functions -e __gwt_pull_main_worktree
end
function __gwt_pull_main_worktree --description 'Ensure main worktree is up-to-date'
    set -l main_worktree $argv[1]
    if test -z "$main_worktree"
        return 0
    end

    git -C $main_worktree pull --ff-only
    if test $status -ne 0
        echo "gwt: failed to pull latest changes in $main_worktree" >&2
        return $status
    end

    return 0
end

set -l usage_lines \
    "Usage:" \
    "  gwt setup-repo <repo> <git-url>" \
    "  gwt new <repo> [slug] [--carry-changes]" \
    "  gwt branch <repo> <remote/branch>" \
    "  gwt archive <repo> <worktree|branch>" \
    "  gwt zellij" \
    "      --carry-changes  Carry current worktree changes into the new worktree (uses patches)" \
    "" \
    "Examples:" \
    "  gwt setup-repo livestore git@github.com:schickling/livestore.git" \
    "  gwt new livestore bugfix-reconcile" \
    "  gwt branch livestore origin/feature/improve-sync" \
    "  gwt archive livestore origin/feature/improve-sync"

set -l target_dir ""
set -l exit_code 0

if test (count $argv) -lt 1
    for line in $usage_lines
        echo $line >&2
    end
    return 1
end

set -l worktrees_root $__gwt_worktrees_root

switch $argv[1]
    case setup-repo
        if test (count $argv) -lt 3
            for line in $usage_lines
                echo $line >&2
            end
            return 1
        end

        set -l repo_name $argv[2]
        set -l remote_url $argv[3]
        set -l repo_root $worktrees_root/$repo_name
        set -l main_worktree $repo_root/.main

        if test -d $main_worktree
            echo "gwt: worktree repo '$repo_name' already exists at $main_worktree"
            set target_dir $main_worktree
        else
            mkdir -p $repo_root
            git clone $remote_url $main_worktree
            if test $status -ne 0
                echo "gwt: failed to clone $remote_url" >&2
                return $status
            end

            set target_dir $main_worktree
        end

    case new
        set -l invocation $argv[2..-1]
        argparse 'carry-changes' -- $invocation
        if test $status -ne 0
            return 1
        end

        set -l carry_changes 0
        if set -q _flag_carry_changes
            set carry_changes 1
        end

        set -l positionals $argv
        set -e argv
        set -e _flag_carry_changes

        if test (count $positionals) -lt 1
            for line in $usage_lines
                echo $line >&2
            end
            return 1
        end

        set -l repo_name $positionals[1]
        set -l raw_slug ""
        if test (count $positionals) -ge 2
            set raw_slug $positionals[2]
        end
        set -l repo_root $worktrees_root/$repo_name
        set -l main_worktree $repo_root/.main

        if not test -d $main_worktree
            echo "gwt: worktree repo '$repo_name' not initialized. Run: gwt setup-repo $repo_name <git-url>" >&2
            return 1
        end

        set -l carry_git_root ""
        set -l carry_staged_patch ""
        set -l carry_unstaged_patch ""
        set -l carry_untracked_files

        if test $carry_changes -eq 1
            set -l cwd (pwd)
            if not string match -q -- "$repo_root/*" $cwd
                echo "gwt: --carry-changes must be run from inside $repo_root" >&2
                return 1
            end

            set carry_git_root (git -C $cwd rev-parse --show-toplevel 2>/dev/null)
            if test $status -ne 0 -o -z "$carry_git_root"
                echo "gwt: failed to locate git root in current directory" >&2
                return 1
            end

            if not string match -q -- "$repo_root/*" $carry_git_root
                echo "gwt: current directory does not belong to repo '$repo_name'" >&2
                return 1
            end

            set carry_staged_patch (mktemp /tmp/gwt-staged-XXXXXX.patch)
            set carry_unstaged_patch (mktemp /tmp/gwt-unstaged-XXXXXX.patch)
            if test -z "$carry_staged_patch" -o -z "$carry_unstaged_patch"
                echo "gwt: failed to create temporary patch files" >&2
                return 1
            end

            git -C $carry_git_root diff --staged --binary >$carry_staged_patch
            if test $status -ne 0
                command rm -f $carry_staged_patch $carry_unstaged_patch
                echo "gwt: failed to capture staged changes" >&2
                return 1
            end

            git -C $carry_git_root diff --binary >$carry_unstaged_patch
            if test $status -ne 0
                command rm -f $carry_staged_patch $carry_unstaged_patch
                echo "gwt: failed to capture unstaged changes" >&2
                return 1
            end

            set carry_untracked_files (git -C $carry_git_root ls-files -z --others --exclude-standard | string split0)
        end

        set -l remotes (git -C $main_worktree remote)
        if test $status -ne 0 -o (count $remotes) -eq 0
            if test $carry_changes -eq 1
                command rm -f $carry_staged_patch $carry_unstaged_patch
            end
            echo "gwt: no git remotes configured in $main_worktree" >&2
            return 1
        end

        set -l primary_remote
        if contains -- origin $remotes
            set primary_remote origin
        else
            set primary_remote $remotes[1]
        end

        set -l worktree_lines (git -C $main_worktree worktree list --porcelain)

        set -l slug_source user
        if test -z "$raw_slug"
            set raw_slug (__gwt_random_slug)
            set slug_source auto
        end

        set -l slug (string lower -- $raw_slug | string replace -ra '[^a-z0-9]+' '-' | string replace -r '^-+|-+$' "")
        if test -z "$slug"
            if test $slug_source = auto
                set raw_slug (__gwt_random_slug)
                set slug (string lower -- $raw_slug | string replace -ra '[^a-z0-9]+' '-' | string replace -r '^-+|-+$' "")
            end
        end

        if test -z "$slug"
            if test $carry_changes -eq 1
                command rm -f $carry_staged_patch $carry_unstaged_patch
            end
            echo "gwt: slug must include at least one letter or number" >&2
            return 1
        end

        set -l github_username (git config --global --get github.user 2>/dev/null)
        if test -z "$github_username"
            set github_username (git -C $main_worktree config --get github.user 2>/dev/null)
        end

        if test -z "$github_username"
            if test $carry_changes -eq 1
                command rm -f $carry_staged_patch $carry_unstaged_patch
            end
            echo "gwt: GitHub username not configured. Run: git config --global github.user YOUR_USERNAME" >&2
            return 1
        end

        set -l today (date +%Y-%m-%d)
        set -l branch_name "$github_username/$today-$slug"
        set -l branch_dir (__gwt_sanitize_path $branch_name)
        if test -z "$branch_dir"
            if test $carry_changes -eq 1
                command rm -f $carry_staged_patch $carry_unstaged_patch
            end
            echo "gwt: failed to derive worktree directory name from branch $branch_name" >&2
            return 1
        end
        set -l target $repo_root/$branch_dir

        set -l existing_branch_path ""
        set -l current_worktree ""
        for line in $worktree_lines
            if string match -q 'worktree *' $line
                set current_worktree (string replace -r '^worktree ' "" -- $line)
            else if string match -q 'branch *' $line
                set -l listed_branch (string replace -r '^branch ' "" -- $line)
                set -l short_branch (string replace -r '^refs/heads/' "" -- $listed_branch)
                if test $short_branch = $branch_name
                    set existing_branch_path $current_worktree
                    break
                end
            end
        end

        set -l need_creation 1
        set -l add_status 0
        if test -n "$existing_branch_path"
            set target $existing_branch_path
            set need_creation 0
        else if string match -q -- "worktree $target" $worktree_lines
            set need_creation 0
        else if test -d $target
            set need_creation 0
        end

        if test $carry_changes -eq 1 -a $need_creation -eq 0
            command rm -f $carry_staged_patch $carry_unstaged_patch
            echo "gwt: --carry-changes requires creating a new worktree" >&2
            return 1
        end

        if test $need_creation -eq 1
            set -l default_ref (git -C $main_worktree symbolic-ref --quiet refs/remotes/$primary_remote/HEAD 2>/dev/null)
            if test $status -eq 0
                set -l default_branch (string replace -r "^refs/remotes/$primary_remote/" "" -- $default_ref)
            else
                set -l default_branch main
            end

            __gwt_pull_main_worktree $main_worktree
            set -l pull_status $status
            if test $pull_status -ne 0
                if test $carry_changes -eq 1
                    command rm -f $carry_staged_patch $carry_unstaged_patch
                end
                return $pull_status
            end

            git -C $main_worktree show-ref --verify --quiet "refs/heads/$branch_name"
            set -l branch_exists $status

            if test $branch_exists -eq 0
                git -C $main_worktree worktree add $target $branch_name >/dev/null
                set add_status $status
            else
                git -C $main_worktree fetch $primary_remote $default_branch >/dev/null 2>&1
                set -l fetch_status $status
                if test $fetch_status -ne 0
                    if test $carry_changes -eq 1
                        command rm -f $carry_staged_patch $carry_unstaged_patch
                    end
                    echo "gwt: failed to fetch $primary_remote/$default_branch" >&2
                    return $fetch_status
                end

                git -C $main_worktree worktree add -b $branch_name $target $primary_remote/$default_branch >/dev/null
                set add_status $status
            end

            if test $add_status -ne 0
                if test $carry_changes -eq 1
                    command rm -f $carry_staged_patch $carry_unstaged_patch
                end
                echo "gwt: failed to create worktree $branch_name" >&2
                return $add_status
            end
        end

        if not test -d $target
            if test -n "$existing_branch_path"; and test -d $existing_branch_path
                set target $existing_branch_path
            else
                if test $carry_changes -eq 1
                    command rm -f $carry_staged_patch $carry_unstaged_patch
                end
                echo "gwt: expected worktree directory $target missing" >&2
                return 1
            end
        end

        if test $carry_changes -eq 1
            set -l apply_failed 0

            if test -s $carry_staged_patch
                git -C $target apply --whitespace=nowarn --binary --index $carry_staged_patch
                if test $status -ne 0
                    set apply_failed 1
                end
            end

            if test $apply_failed -eq 0 -a -s $carry_unstaged_patch
                git -C $target apply --whitespace=nowarn --binary $carry_unstaged_patch
                if test $status -ne 0
                    set apply_failed 1
                end
            end

            if test $apply_failed -eq 0
                for file in $carry_untracked_files
                    if test -z "$file"
                        continue
                    end
                    set -l src_path $carry_git_root/$file
                    set -l dest_path $target/$file
                    set -l dest_dir (dirname $dest_path)
                    if test "$dest_dir" != "."
                        mkdir -p -- "$dest_dir"
                    end
                    command cp -p -- "$src_path" "$dest_path"
                end
            end

            if test -n "$carry_staged_patch" -o -n "$carry_unstaged_patch"
                command rm -f $carry_staged_patch $carry_unstaged_patch
            end

            if test $apply_failed -ne 0
                git -C $main_worktree worktree remove --force $target >/dev/null 2>&1
                rm -rf $target
                echo "gwt: failed to carry changes into new worktree" >&2
                return 1
            end
        end

        set target_dir $target

    case branch
        if test (count $argv) -lt 3
            for line in $usage_lines
                echo $line >&2
            end
            return 1
        end

        set -l repo_name $argv[2]
        set -l remote_ref $argv[3]
        set -l repo_root $worktrees_root/$repo_name
        set -l main_worktree $repo_root/.main

        if not test -d $main_worktree
            echo "gwt: worktree repo '$repo_name' not initialized. Run: gwt setup-repo $repo_name <git-url>" >&2
            return 1
        end

        set -l parts (string split -m1 '/' -- $remote_ref)
        if test (count $parts) -lt 2
            echo "gwt: branch must include remote prefix (e.g. origin/main)" >&2
            return 1
        end

        set -l remote_name $parts[1]
        set -l branch_ref $parts[2]
        if test -z "$branch_ref"
            echo "gwt: branch name is empty" >&2
            return 1
        end

        git -C $main_worktree remote get-url $remote_name >/dev/null 2>&1
        if test $status -ne 0
            echo "gwt: remote '$remote_name' not found" >&2
            return 1
        end

        set -l local_branch $branch_ref
        set -l dir_name (__gwt_sanitize_path $remote_ref)
        if test -z "$dir_name"
            set dir_name (__gwt_sanitize_path $local_branch)
            if test -z "$dir_name"
                set dir_name $local_branch
            end
        end
        set -l target $repo_root/$dir_name
        set -l worktree_lines (git -C $main_worktree worktree list --porcelain)

        set -l existing_branch_path ""
        set -l current_worktree ""
        for line in $worktree_lines
            if string match -q 'worktree *' $line
                set current_worktree (string replace -r '^worktree ' "" -- $line)
            else if string match -q 'branch *' $line
                set -l listed_branch (string replace -r '^branch ' "" -- $line)
                set -l short_branch (string replace -r '^refs/heads/' "" -- $listed_branch)
                if test $short_branch = $local_branch
                    set existing_branch_path $current_worktree
                    break
                end
            end
        end

        if test -n "$existing_branch_path"; and test $existing_branch_path != $target
            if test -d $target
                set target $existing_branch_path
            else
                git -C $main_worktree worktree move $existing_branch_path $target >/dev/null
                if test $status -ne 0
                    echo "gwt: failed to normalise worktree directory name" >&2
                    return $status
                end
                set existing_branch_path $target
            end
        end

        set -l need_creation 1
        set -l add_status 0
        if test -n "$existing_branch_path"
            set target $existing_branch_path
            set need_creation 0
        else if string match -q -- "worktree $target" $worktree_lines
            set need_creation 0
        else if test -d $target
            set need_creation 0
        end

        if test $need_creation -eq 1
            __gwt_pull_main_worktree $main_worktree
            set -l pull_status $status
            if test $pull_status -ne 0
                return $pull_status
            end

            git -C $main_worktree fetch $remote_name $branch_ref >/dev/null 2>&1
            set -l fetch_status $status
            if test $fetch_status -ne 0
                echo "gwt: failed to fetch $remote_name/$branch_ref" >&2
                return $fetch_status
            end

            git -C $main_worktree show-ref --verify --quiet "refs/heads/$local_branch"
            set -l branch_exists $status

            if test $branch_exists -eq 0
                git -C $main_worktree worktree add $target $local_branch >/dev/null
                set add_status $status
            else
                git -C $main_worktree worktree add --track -b $local_branch $target $remote_name/$branch_ref >/dev/null
                set add_status $status
            end

            if test $add_status -ne 0
                echo "gwt: failed to create worktree for $remote_name/$branch_ref" >&2
                return $add_status
            end
        end

        if not test -d $target
            if test -n "$existing_branch_path"; and test -d $existing_branch_path
                set target $existing_branch_path
            else
                echo "gwt: expected worktree directory $target missing" >&2
                return 1
            end
        end

        set target_dir $target

    case archive
        set -l use_cwd 0
        set -l inferred_path ""
        set -l inferred_branch ""
        set -l repo_name ""
        set -l identifier ""

        if test (count $argv) -ge 3
            set repo_name $argv[2]
            set identifier $argv[3]
        else if test (count $argv) -eq 1
            set use_cwd 1

            set -l cwd (pwd)
            set -l root $__gwt_worktrees_root
            if test -z "$root"
                echo "gwt: worktree root not configured" >&2
                return 1
            end

            if not string match -q -- "$root/*" $cwd
                echo "gwt: current directory '$cwd' is not within $root" >&2
                return 1
            end

            set -l root_pattern (string escape --style=regex $root)
            set -l relative (string replace -r "^$root_pattern/" "" -- $cwd)
            set -l path_parts (string split '/' -- $relative)
            if test (count $path_parts) -lt 2
                echo "gwt: run this subcommand from inside a specific worktree directory" >&2
                return 1
            end

            set repo_name $path_parts[1]
            set identifier $path_parts[2]
            set inferred_path $root/$repo_name/$identifier

            if not test -d $inferred_path
                echo "gwt: expected worktree directory $inferred_path missing" >&2
                return 1
            end

            set inferred_branch (git -C $inferred_path rev-parse --abbrev-ref HEAD 2>/dev/null)
            if test -z "$inferred_branch" -o "$inferred_branch" = HEAD
                set inferred_branch ""
            end
        else
            for line in $usage_lines
                echo $line >&2
            end
            return 1
        end

        set -l repo_root $worktrees_root/$repo_name
        set -l main_worktree $repo_root/.main

        if not test -d $main_worktree
            echo "gwt: worktree repo '$repo_name' not initialized. Run: gwt setup-repo $repo_name <git-url>" >&2
            return 1
        end

        set -l worktree_lines (git -C $main_worktree worktree list --porcelain)
        set -l worktree_paths
        set -l worktree_branches
        set -l current_worktree ""
        for line in $worktree_lines
            if string match -q 'worktree *' $line
                set current_worktree (string replace -r '^worktree ' "" -- $line)
            else if string match -q 'branch *' $line
                set -l listed_branch (string replace -r '^branch ' "" -- $line)
                set -l short_branch (string replace -r '^refs/heads/' "" -- $listed_branch)
                set worktree_paths $worktree_paths $current_worktree
                set worktree_branches $worktree_branches $short_branch
            end
        end

        set -l sanitized_identifier (__gwt_sanitize_path $identifier)
        set -l branch_lookup $identifier
        if test $use_cwd -eq 1; and test -n "$inferred_branch"
            set branch_lookup $inferred_branch
        end
        if string match -q '*/*' -- $identifier
            set -l split_parts (string split -m1 '/' -- $identifier)
            if test (count $split_parts) -ge 2
                set branch_lookup $split_parts[2]
            end
        end

        set -l candidate_paths
        if test -n "$sanitized_identifier"
            set candidate_paths $candidate_paths $repo_root/$sanitized_identifier
        end
        set candidate_paths $candidate_paths $repo_root/$identifier
        if test -n "$inferred_path"
            set candidate_paths $candidate_paths $inferred_path
        end

        set -l target_path ""
        set -l target_branch ""

        for candidate in $candidate_paths
            if test -z "$candidate"
                continue
            end
            if test -d $candidate
                set target_path $candidate
                break
            end
        end

        if test -z "$target_path"; and test -n "$branch_lookup"
            for idx in (seq (count $worktree_paths))
                if test $worktree_branches[$idx] = $branch_lookup
                    set target_path $worktree_paths[$idx]
                    set target_branch $worktree_branches[$idx]
                    break
                end
            end
        end

        if test -z "$target_branch"; and test -n "$target_path"
            for idx in (seq (count $worktree_paths))
                if test $worktree_paths[$idx] = $target_path
                    set target_branch $worktree_branches[$idx]
                    break
                end
            end
        end

        if test -z "$target_path"
            echo "gwt: could not locate worktree '$identifier' for repo '$repo_name'" >&2
            return 1
        end

        if test $target_path = $main_worktree
            echo "gwt: refusing to archive the primary .main worktree" >&2
            return 1
        end

        if not test -d $target_path
            echo "gwt: expected worktree directory $target_path missing" >&2
            return 1
        end

        set -l archive_dir $repo_root/.archive
        mkdir -p $archive_dir

        set -l base_name (basename $target_path)
        set -l archive_target $archive_dir/$base_name
        set -l counter 1
        while test -e $archive_target
            set archive_target $archive_dir/$base_name-$counter
            set counter (math $counter + 1)
        end

        mv -- $target_path $archive_target
        if test $status -ne 0
            echo "gwt: failed to move worktree to archive" >&2
            return $status
        end

        set -l archive_readme $archive_dir/README.md
        if not test -f $archive_readme
            printf "# Archived worktrees\n\n" >>$archive_readme
        end

        set -l timestamp (date -u "+%Y-%m-%dT%H:%M:%SZ")
        set -l worktree_name (basename $archive_target)
        set -l branch_note "unknown"
        if test -n "$target_branch"
            set branch_note $target_branch
        else if test -n "$branch_lookup"
            set branch_note $branch_lookup
        end

        set -l summary "## $timestamp\n- Repo: $repo_name\n- Worktree: $worktree_name\n- Branch: $branch_note\n- Source identifier: $identifier\n\n"
        printf '%s' "$summary" >>$archive_readme

        git -C $main_worktree worktree prune >/dev/null 2>&1

        if test -n "$target_branch"
            git -C $main_worktree show-ref --verify --quiet "refs/heads/$target_branch"
            if test $status -eq 0
                git -C $main_worktree branch -D $target_branch >/dev/null 2>&1
            end
        end

        set target_dir $archive_target

    case zellij
        if set -q ZELLIJ_SESSION_NAME
            echo "gwt: already inside zellij session '$ZELLIJ_SESSION_NAME'" >&2
            return 1
        end

        if not type -q zellij
            echo "gwt: zellij binary not found in PATH" >&2
            return 1
        end

        set -l cwd (pwd)
        set -l root $__gwt_worktrees_root
        if test -z "$root"
            echo "gwt: worktree root not configured" >&2
            return 1
        end

        if not string match -q -- "$root/*" $cwd
            echo "gwt: current directory '$cwd' is not within $root" >&2
            return 1
        end

        set -l root_pattern (string escape --style=regex $root)
        set -l relative (string replace -r "^$root_pattern/" "" -- $cwd)
        set -l path_parts (string split '/' -- $relative)
        if test (count $path_parts) -lt 2
            echo "gwt: run this subcommand from inside a specific worktree directory" >&2
            return 1
        end

        set -l repo_name $path_parts[1]
        set -l default_branch_component $path_parts[2]

        set -l branch_name (git -C $cwd rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test $status -ne 0 -o -z "$branch_name" -o "$branch_name" = HEAD
            set branch_name $default_branch_component
        end

        set -l session_name (__gwt_sanitize_path "$repo_name/$branch_name")
        if test -z "$session_name"
            set session_name (__gwt_sanitize_path $repo_name)
        end

        if test -z "$session_name"
            echo "gwt: failed to derive session name" >&2
            return 1
        end

        echo "gwt: attaching to zellij session '$session_name'" >&2
        zellij attach -c $session_name
        return $status

    case '*'
        for line in $usage_lines
            echo $line >&2
        end
        return 1
end

if test -n "$target_dir"
    if cd $target_dir
        pwd
        if test -f .envrc; and type -q direnv
            direnv allow >/dev/null 2>&1
        end
        return $exit_code
    else
        echo "gwt: failed to enter $target_dir" >&2
        return 1
    end
end

return $exit_code
