local main_mod = "SUPER"
local alt_mod = "ALT"

local terminal = "wezterm"
local browser = "zen-twilight"
local editor = "zeditor"
local file_explorer = "wezterm -e yazi"
local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"
local xcursor_theme = "qtile-cursors"
local cursor_size = "24"

local internal_monitor = "eDP-1"
local external_monitor = "HDMI-A-2"

local function bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts)
end

local function exec(keys, command, opts)
    bind(keys, hl.dsp.exec_cmd(command), opts)
end

local function focus(keys, direction)
    bind(keys, hl.dsp.focus({ direction = direction }))
end

local function move_window(keys, direction)
    bind(keys, hl.dsp.window.move({ direction = direction }))
end

local function resize_window(keys, x, y)
    bind(keys, hl.dsp.window.resize({ x = x, y = y, relative = true }))
end

local function workspace(key)
    local name = "name:" .. key
    bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = name }))
    bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = name }))
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

hl.monitor({
    output = internal_monitor,
    mode = "preferred",
    position = "0x0",
    scale = "1",
})

hl.monitor({
    output = external_monitor,
    mode = "preferred",
    position = "auto",
    scale = "1",
})

hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XCURSOR_THEME", xcursor_theme)
hl.env("XCURSOR_SIZE", cursor_size)

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd("hyprctl setcursor " .. xcursor_theme .. " " .. cursor_size))
    hl.dispatch(hl.dsp.exec_cmd(scripts .. "/autostart.sh"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c " .. shell_quote("sleep 1; " .. shell_quote(scripts .. "/wallpaper_control") .. " set_random")))
end)

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = "rgba(c3c3c3ff)",
            inactive_border = "rgba(2e3440ff)",
        },
        snap = {
            enabled = true,
            window_gap = 15,
            monitor_gap = 15,
            respect_gaps = false,
            border_overlap = false,
        },
        resize_on_border = false,
        no_focus_fallback = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 9,
            render_power = 3,
            color = 0x80000000,
            offset = { 2, 2 },
        },
        blur = {
            enabled = true,
            size = 1,
            passes = 1,

            vibrancy = 0.1,
            noise = 0.08,
            contrast = 1.5,

            ignore_opacity = true,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    cursor = {
        no_warps = true,
        persistent_warps = false,
        warp_on_change_workspace = 0,
        warp_on_toggle_special = 0,
        warp_back_after_non_mouse_input = false,
    },
    input = {
        kb_layout = "us,ua",
        kb_variant = "",
        kb_model = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
        },
    },
})

hl.curve("lightFade", {
    type = "bezier",
    points = { { 0.2, 0.0 }, { 0.0, 1.0 } },
})

hl.animation({ leaf = "global", enabled = true, speed = 1.5, bezier = "lightFade" })
hl.animation({ leaf = "windows", enabled = false })
hl.animation({ leaf = "windowsIn", enabled = false })
hl.animation({ leaf = "windowsOut", enabled = false })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "lightFade" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "lightFade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "lightFade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "lightFade", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1.5, bezier = "lightFade", style = "fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.5, bezier = "lightFade", style = "fade" })

for _, rule in ipairs({
    { workspace = "name:f", monitor = internal_monitor, default = true },
    { workspace = "name:d", monitor = internal_monitor },
    { workspace = "name:s", monitor = internal_monitor },
    { workspace = "name:a", monitor = internal_monitor },
    { workspace = "name:v", monitor = external_monitor, default = true },
    { workspace = "name:c", monitor = external_monitor },
    { workspace = "name:x", monitor = external_monitor },
    { workspace = "name:z", monitor = external_monitor },
}) do
    hl.workspace_rule(rule)
end

focus(main_mod .. " + h", "left")
focus(main_mod .. " + l", "right")
focus(main_mod .. " + j", "down")
focus(main_mod .. " + k", "up")

move_window(main_mod .. " + SHIFT + h", "left")
move_window(main_mod .. " + SHIFT + l", "right")
move_window(main_mod .. " + SHIFT + j", "down")
move_window(main_mod .. " + SHIFT + k", "up")

resize_window(main_mod .. " + " .. alt_mod .. " + h", -40, 0)
resize_window(main_mod .. " + " .. alt_mod .. " + l", 40, 0)
resize_window(main_mod .. " + " .. alt_mod .. " + j", 0, 40)
resize_window(main_mod .. " + " .. alt_mod .. " + k", 0, -40)

bind(main_mod .. " + m", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind(main_mod .. " + u", hl.dsp.window.close())
exec(main_mod .. " + " .. alt_mod .. " + r", "hyprctl reload")

exec(main_mod .. " + return", terminal)
exec(main_mod .. " + " .. alt_mod .. " + f", browser)
exec(main_mod .. " + " .. alt_mod .. " + c", editor)
exec(main_mod .. " + " .. alt_mod .. " + e", file_explorer)
exec(main_mod .. " + " .. alt_mod .. " + t", "Telegram")
exec(main_mod .. " + " .. alt_mod .. " + w", scripts .. "/video_wallpaper start")
exec(main_mod .. " + " .. alt_mod .. " + s", scripts .. "/multi_monitor menu")
exec(main_mod .. " + t", scripts .. "/device_manager touchpad")
exec(main_mod .. " + SHIFT + t", scripts .. "/device_manager touchscreen")
exec(main_mod .. " + " .. alt_mod .. " + p", scripts .. "/pick_color")
exec(main_mod .. " + " .. alt_mod .. " + v", "qs ipc call launcher openWithMode clipboard")
bind(main_mod .. " + o", hl.dsp.window.pin({ action = "toggle" }))
exec(main_mod .. " + space", "qs ipc call launcher open")
exec(main_mod .. " + home", "qs ipc call lock open")
exec("Print", scripts .. "/screenshot")

bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/volume_control down"), { locked = true, repeating = true })
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/volume_control up"), { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/volume_control mute"), { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "/volume_control mic_mute"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/brightness_control down"), { locked = true, repeating = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/brightness_control up"), { locked = true, repeating = true })

for _, key in ipairs({ "f", "d", "s", "a", "v", "c", "x", "z" }) do
    workspace(key)
end

bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
bind(main_mod .. " + mouse:274", hl.dsp.window.alter_zorder({ mode = "top" }))
bind(main_mod .. " + " .. alt_mod .. " + mouse:272", hl.dsp.window.float({ action = "toggle" }))

hl.window_rule({
    name = "browser-workspace",
    match = { class = "^(firefox|floorp|zen|zen-twilight)$" },
    workspace = "name:f",
})

hl.window_rule({
    name = "planning-workspace",
    match = { class = "^(Logseq|superproductivity)$" },
    workspace = "name:v",
})

hl.window_rule({
    name = "media-workspace",
    match = { class = "^(discord|YouTube Music|youtube music desktop app)$" },
    workspace = "name:x",
})

hl.window_rule({
    name = "telegram-workspace",
    match = { class = "^(Telegram|org.telegram.desktop)$" },
    workspace = "name:z",
})

hl.window_rule({
    name = "floating-classes",
    match = { class = "^(confirmreset|makebranch|maketag|ssh-askpass|imv|mpv|viewnior)$" },
    float = true,
})

hl.window_rule({
    name = "floating-titles",
    match = { title = "^(branchdialog|pinentry|Picture-in-Picture|Kolo-Face)$" },
    float = true,
})

hl.window_rule({
    name = "browser-pip",
    match = {
        class = "^(firefox|floorp|zen|zen-twilight)$",
        title = "^Picture-in-Picture$",
    },
    float = true,
    pin = true,
})

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.layer_rule({
    match = {
        namespace = "^quickshell-overlay-.*$",
    },

    blur = true,
    ignore_alpha = 0.05,
})
