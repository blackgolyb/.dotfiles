local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'custom'
-- config.color_scheme = 'Breeze (Gogh)'
config.window_background_opacity = 0.975
config.window_padding = {
    left = 15,
    right = 15,
    top = 15,
    bottom = 15,
}
config.enable_tab_bar = true


config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 16.0
config.bold_brightens_ansi_colors = false

config.colors = {
    tab_bar = {
        -- The color of the strip that goes along the top of the window
        -- (does not apply when fancy tab bar is in use)
        background = '#1d2126',

        -- The active tab is the one that has focus in the window
        active_tab = {

            -- The color of the background area for the tab
            bg_color = '#2c313a',
            -- The color of the text for the tab
            fg_color = '#fcfcfc',

            -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
            -- label shown for this tab.
            -- The default is "Normal"
            intensity = 'Normal',

            -- Specify whether you want "None", "Single" or "Double" underline for
            -- label shown for this tab.
            -- The default is "None"
            underline = 'None',

            -- Specify whether you want the text to be italic (true) or not (false)
            -- for this tab.  The default is false.
            italic = false,

            -- Specify whether you want the text to be rendered with strikethrough (true)
            -- or not for this tab.  The default is false.
            strikethrough = false,
        },

        -- Inactive tabs are the tabs that do not have focus
        inactive_tab = {
            bg_color = '#1d2126',
            fg_color = '#b3b1ab',

            -- The same options that were listed under the `active_tab` section above
            -- can also be used for `inactive_tab`.
        },

        -- You can configure some alternate styling when the mouse pointer
        -- moves over inactive tabs
        inactive_tab_hover = {
            bg_color = '#3b3052',
            fg_color = '#909090',
            italic = true,

            -- The same options that were listed under the `active_tab` section above
            -- can also be used for `inactive_tab_hover`.
        },

        -- You can configure some alternate styling when the mouse pointer
        -- moves over the new tab button
        new_tab_hover = {
            bg_color = '#3b3052',
            fg_color = '#909090',
            italic = true,

            -- The same options that were listed under the `active_tab` section above
            -- can also be used for `new_tab_hover`.
        },
    },
}
config.show_new_tab_button_in_tab_bar = false

config.keys = {
    {
        key = 't',
        mods = 'ALT',
        action = wezterm.action.SpawnTab 'CurrentPaneDomain',
    },
    {
        key = 'w',
        mods = 'ALT',
        action = wezterm.action.CloseCurrentTab { confirm = false },
    },
    {
        key = 'f',
        mods = 'ALT',
        action = wezterm.action.ActivateTab(0),
    },
    {
        key = 'd',
        mods = 'ALT',
        action = wezterm.action.ActivateTab(1),
    },
    {
        key = 's',
        mods = 'ALT',
        action = wezterm.action.ActivateTab(2),
    },
    {
        key = 'a',
        mods = 'ALT',
        action = wezterm.action.ActivateTab(3),
    },
}

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

wezterm.plugin
    .require('https://github.com/yriveiro/wezterm-tabs')
    .apply_to_config(config, {
        tabs = {
            -- Position the tab bar at the bottom of the window
            tab_bar_at_bottom = false,

            -- Controls visibility of the tab bar when only one tab exists
            hide_tab_bar_if_only_one_tab = false,

            -- Maximum width of each tab in cells
            tab_max_width = 32,

            -- Whether to restore zoom level when switching panes
            unzoom_on_switch_pane = true,
        }
    })

return config
