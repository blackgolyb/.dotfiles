import QtQuick

Rectangle {
    id: root

    readonly property var sizes: ({
        sm: { width: 34, height: 28 },
        md: { width: 34, height: 28 },
        lg: { width: 42, height: 32 }
    })
    readonly property var variants: ({
        default: { normal: Theme.surfaceSunken, hover: Theme.surfaceActive, text: Theme.textSecondary },
        surface: { normal: Theme.surfaceActive, hover: Theme.border, text: Theme.textPrimary },
        accent: { normal: Theme.accent, hover: Theme.accentHover, text: Theme.textPrimary }
    })

    property string text: ""
    property string size: "md"
    property string variant: "default"
    property int minWidth: 96
    property int textPixelSize: Theme.textMd
    property color normalColor: root.variantSpec().normal
    property color hoverColor: root.variantSpec().hover
    property color textColor: root.variantSpec().text
    property bool icon: false
    signal clicked

    implicitWidth: root.buttonWidth()
    implicitHeight: root.buttonHeight()
    radius: Theme.radiusSm
    opacity: root.opacityForState()
    color: root.colorForState()

    function sizeSpec(): var {
        if (root.sizes[root.size] !== undefined)
            return root.sizes[root.size];
        return root.sizes.md;
    }

    function variantSpec(): var {
        if (root.variants[root.variant] !== undefined)
            return root.variants[root.variant];
        return root.variants.default;
    }

    function buttonWidth(): int {
        if (root.icon)
            return root.sizeSpec().width;
        return Math.max(root.minWidth, label.implicitWidth + 28);
    }

    function buttonHeight(): int {
        if (root.icon)
            return root.sizeSpec().height;
        return 34;
    }

    function opacityForState(): real {
        if (root.enabled)
            return 1;
        return 0.35;
    }

    function colorForState(): color {
        if (mouseArea.containsMouse && root.enabled)
            return root.hoverColor;
        return root.normalColor;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onPressed: forceActiveFocus()
        onClicked: root.clicked()
    }

    UiText {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: root.textPixelSize
    }
}
