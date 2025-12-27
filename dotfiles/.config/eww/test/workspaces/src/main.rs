use std::time::Duration;

mod app;
mod backend;
mod base;
mod serializer;

use app::App;
// use backend::{X11wmctrl, X11, Hyprland};
use backend::Hyprland;
use base::{SerializeWorkspaces, WorkspaceQuery};
use serializer::JSONWorkspaceSerializer;

fn main() {
    // let is_x11 = true;
    let update_time = 100;

    let serializer: Box<dyn SerializeWorkspaces> = Box::new(JSONWorkspaceSerializer);

    // let backend: Box<dyn WorkspaceQuery> = if is_x11 {
    //     Box::new(X11::new())
    // } else {
    //     Box::new(X11wmctrl::new())
    // };

    let backend: Box<dyn WorkspaceQuery> = Box::new(Hyprland::new());

    let mut app = App::new(Duration::from_millis(update_time), backend, serializer);
    app.init();
    app.run();
}
