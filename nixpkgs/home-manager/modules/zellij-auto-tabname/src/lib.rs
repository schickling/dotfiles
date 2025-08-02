use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct AutoTabName {
    prefix: String,
    last_tab_names: BTreeMap<u32, String>,
}

register_plugin!(AutoTabName);

impl ZellijPlugin for AutoTabName {
    fn load(&mut self, config: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        
        subscribe(&[EventType::PaneUpdate]);
        
        self.prefix = config.get("prefix").unwrap_or(&"> ".to_string()).clone();
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::PaneUpdate(panes_manifest) = event {
            for (&tab_index, pane_infos) in &panes_manifest.panes {
                if let Some(focused_pane) = pane_infos.iter().find(|p| p.is_focused) {
                    if !focused_pane.title.is_empty() {
                        let new_name = format!("{}{}", self.prefix, focused_pane.title);
                        
                        let tab_id = tab_index as u32;
                        if self.last_tab_names.get(&tab_id) != Some(&new_name) {
                            rename_tab(tab_id, &new_name);
                            self.last_tab_names.insert(tab_id, new_name);
                        }
                    }
                }
            }
        }
        true
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        print!("\u{2800}");
    }
}