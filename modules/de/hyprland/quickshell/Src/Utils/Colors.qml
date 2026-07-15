pragma Singleton

import QtQuick

QtObject {
    function clamp(value: real, min: real, max: real): real {
        return Math.max(min, Math.min(max, value));
    }

    function channel(value: int): real {
        return clamp(value / 255, 0, 1);
    }

    function parseHex(value: string): var {
        const hex = value.trim().replace(/^#/, "");
        if (hex.length === 3) {
            return Qt.rgba(channel(parseInt(hex[0] + hex[0], 16)), channel(parseInt(hex[1] + hex[1], 16)), channel(parseInt(hex[2] + hex[2], 16)), 1);
        }

        if (hex.length === 6 || hex.length === 8) {
            return Qt.rgba(channel(parseInt(hex.slice(0, 2), 16)), channel(parseInt(hex.slice(2, 4), 16)), channel(parseInt(hex.slice(4, 6), 16)), hex.length === 8 ? channel(parseInt(hex.slice(6, 8), 16)) : 1);
        }

        return Qt.rgba(0, 0, 0, 0);
    }

    function normalized(value): var {
        if (typeof value === "string")
            return parseHex(value);
        return value;
    }

    function mix(color1, color2, mixRate: real): color {
        const first = normalized(color1);
        const second = normalized(color2);
        const rate = clamp(mixRate, 0, 1);
        const inverse = 1 - rate;

        return Qt.rgba(first.r * inverse + second.r * rate, first.g * inverse + second.g * rate, first.b * inverse + second.b * rate, first.a * inverse + second.a * rate);
    }
}
