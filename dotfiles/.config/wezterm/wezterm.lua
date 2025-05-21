local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- config.color_scheme = 'custom'
config.color_scheme = 'Breeze (Gogh)'
config.window_background_opacity = 0.85
config.window_padding = {
    left = 25,
    right = 25,
    top = 25,
    bottom = 25,
}
config.enable_tab_bar = false

config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 15.0
config.bold_brightens_ansi_colors = false


-- -- Use some simple heuristics to determine if we should open it
-- -- with a text editor in the terminal.
-- -- Take note! The code in this file runs on your local machine,
-- -- but a URI can appear for a remote, multiplexed session.
-- -- WezTerm can spawn the editor in that remote session, but doesn't
-- -- have access to the file locally, so we can't probe inside the
-- -- file itself, so we are limited to simple heuristics based on
-- -- the filename appearance.
-- function editable(filename)
--     -- "foo.bar" -> ".bar"
--     local extension = filename:match("^.+(%..+)$")
--     if extension then
--         -- ".bar" -> "bar"
--         extension = extension:sub(2)
--         wezterm.log_info(string.format("extension is [%s]", extension))
--         local binary_extensions = {
--             jpg = true,
--             jpeg = true,
--             -- and so on
--         }
--         if binary_extensions[extension] then
--             -- can't edit binary files
--             return false
--         end
--     end

--     -- if there is no, or an unknown, extension, then assume
--     -- that our trusty editor will do something reasonable

--     return true
-- end

-- function extract_filename(uri)
--     local start, match_end = uri:find("$EDITOR:");
--     if start == 1 then
--         -- skip past the colon
--         return uri:sub(match_end + 1)
--     end

--     -- `file://hostname/path/to/file`
--     local start, match_end = uri:find("file:");
--     if start == 1 then
--         -- skip "file://", -> `hostname/path/to/file`
--         local host_and_path = uri:sub(match_end + 3)
--         local start, match_end = host_and_path:find("/")
--         if start then
--             -- -> `/path/to/file`
--             return host_and_path:sub(match_end)
--         end
--     end

--     return nil
-- end

-- wezterm.on("open-uri", function(window, pane, uri)
--     local name = extract_filename(uri)
--     if name and editable(name) then
--         -- Note: if you change your VISUAL or EDITOR environment,
--         -- you will need to restart wezterm for this to take effect,
--         -- as there isn't a way for wezterm to "see into" your shell
--         -- environment and capture it.
--         -- local editor = os.getenv("VISUAL") or os.getenv("EDITOR") or "vi"
--         local editor = "zed"
--         wezterm.log_info(editor)

--         -- To open a new window:
--         -- local action = wezterm.action { SpawnCommandInNewWindow = {
--         --     args = { editor, name }
--         -- } };

--         -- To open in a pane instead
--         local action = wezterm.action { SplitHorizontal = {
--             args = { editor, name }
--         } };

--         -- and spawn it!
--         window:perform_action(action, pane);

--         -- prevent the default action from opening in a browser
--         return false
--     end
-- end)

-- config.hyperlink_rules = {
--     -- These are the default rules, but you currently need to repeat
--     -- them here when you define your own rules, as your rules override
--     -- the defaults

--     -- URL with a protocol
--     {
--         regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b",
--         format = "$0",
--     },

--     -- implicit mailto link
--     {
--         regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
--         format = "mailto:$0",
--     },

--     -- new in nightly builds; automatically highly file:// URIs.
--     {
--         regex = "\\bfile://\\S*\\b",
--         format = "$0"
--     },

--     -- Now add a new item at the bottom to match things that are
--     -- probably filenames

--     {
--         regex = "\\b\\S*\\b",
--         format = "$EDITOR:$0"
--     },
-- };

return config
