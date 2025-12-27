use crate::base::{SerializeWorkspaces, Workspace, Workspaces};

impl Workspace {
    fn serialize(&self) -> String {
        format!(
            "{{\"label\":\"{}\",\"is_active\":{},\"is_used\":{}}}",
            self.label, self.is_current, self.is_used,
        )
    }
}

pub struct JSONWorkspaceSerializer;

impl SerializeWorkspaces for JSONWorkspaceSerializer {
    fn serialize(&self, workspaces: Workspaces) -> String {
        let mut inner: String = workspaces
            .into_iter()
            .map(|w| format!("{},", w.serialize()))
            .collect();
        inner.pop();
        format!("[{}]", inner)
    }
}