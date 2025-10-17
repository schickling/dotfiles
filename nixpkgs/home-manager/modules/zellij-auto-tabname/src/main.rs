use std::collections::BTreeMap;
use zellij_tile::prelude::*;

struct AutoTab;

impl Default for AutoTab {
    fn default() -> Self {
        Self
    }
}

register_plugin!(AutoTab);


impl ZellijPlugin for AutoTab {
    fn load(&mut self, _cfg: BTreeMap<String, String>) {
        // Request permissions required for dynamic tab naming
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        subscribe(&[EventType::PaneUpdate]);
        
        // Print helpful message for first-time users
        eprintln!("🚀 Auto Tab Name plugin loaded!");
        eprintln!("📝 If prompted, please grant permissions to enable dynamic tab naming");
    }

    fn update(&mut self, ev: Event) -> bool {
        if let Event::PaneUpdate(m) = ev {
            for (tab, panes) in m.panes {
                if let Some(p) = panes.into_iter().find(|p| p.is_focused && !p.title.is_empty()) {
                    let wanted = format!("> {}", p.title);
                    rename_tab(tab as u32, &wanted);
                }
            }
        }
        true
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        print!("\u{2800}"); // invisible braille char; avoids empty-render panic
    }
}