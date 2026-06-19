pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property QtObject primitive: QtObject {
        readonly property color polarNight0: "#2e3440"
        readonly property color polarNight1: "#3b4252"
        readonly property color polarNight2: "#434c5e"
        readonly property color polarNight3: "#4c566a"
        readonly property color snowStorm0: "#d8dee9"
        readonly property color snowStorm1: "#e5e9f0"
        readonly property color snowStorm2: "#eceff4"
        readonly property color frost0: "#8fbcbb"
        readonly property color frost1: "#88c0d0"
        readonly property color frost2: "#81a1c1"
        readonly property color frost3: "#5e81ac"
        readonly property color red: "#bf616a"
        readonly property color orange: "#d08770"
        readonly property color yellow: "#ebcb8b"
        readonly property color green: "#a3be8c"
        readonly property color black: "#000000"
        readonly property color white: "#ffffff"
    }

    readonly property color background: primitive.polarNight0
    readonly property color surface: primitive.polarNight0
    readonly property color surfaceRaised: primitive.polarNight1
    readonly property color surfaceSunken: "#252b35"
    readonly property color surfaceHover: "#343b49"
    readonly property color surfaceActive: primitive.polarNight1
    readonly property color border: primitive.polarNight3
    readonly property color accent: primitive.frost1
    readonly property color accentHover: primitive.frost0
    readonly property color textPrimary: primitive.snowStorm2
    readonly property color textSecondary: primitive.snowStorm0
    readonly property color textMuted: "#7f889b"
    readonly property color textSubtle: "#a9b1c1"
    readonly property color textDisabled: "#8f98aa"
    readonly property color textInverse: primitive.polarNight0
    readonly property color danger: primitive.red
    readonly property color success: primitive.green
    readonly property color overlay: primitive.black
    readonly property color transparent: "transparent"

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    readonly property int textXs: 10
    readonly property int textSm: 11
    readonly property int textMd: 12
    readonly property int textLg: 14
    readonly property int textXl: 16
    readonly property int radiusSm: 9
    readonly property int radiusMd: 12
    readonly property int radiusLg: 18
    readonly property int radiusPill: 999
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
}
