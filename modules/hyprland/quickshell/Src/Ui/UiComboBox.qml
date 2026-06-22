import QtQuick
import QtQuick.Controls as Controls

Controls.ComboBox {
    id: root

    property int arrowWidth: 30
    property int textPixelSize: Theme.textMd
    property int textHorizontalAlignment: TextInput.AlignLeft

    editable: true
    implicitHeight: 30
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    font.family: Theme.fontFamily
    font.pixelSize: root.textPixelSize

    delegate: Controls.ItemDelegate {
        required property var modelData
        required property int index

        width: root.width
        height: 30
        highlighted: root.highlightedIndex === index

        background: Rectangle {
            color: parent.highlighted ? Theme.surfaceHover : Theme.surfaceSunken
        }

        contentItem: UiText {
            text: modelData.toString()
            color: parent.highlighted ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: root.textPixelSize
            verticalAlignment: Text.AlignVCenter
        }
    }

    indicator: Rectangle {
        x: root.width - width
        y: 0
        width: root.arrowWidth
        height: root.height
        radius: Theme.radiusSm
        color: arrowMouse.containsMouse ? Theme.surfaceHover : Theme.transparent

        MouseArea {
            id: arrowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.popup.toggle()
        }

        UiText {
            anchors.centerIn: parent
            text: ""
            color: Theme.textMuted
            font.pixelSize: root.textPixelSize
            font.bold: true
        }
    }

    contentItem: Item {
        TextInput {
            id: textInput

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: root.arrowWidth
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            leftPadding: 10
            rightPadding: 8
            text: root.editText
            color: Theme.textPrimary
            selectedTextColor: Theme.textInverse
            selectionColor: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: root.textPixelSize
            horizontalAlignment: root.textHorizontalAlignment
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            activeFocusOnPress: true
            validator: root.validator
            onTextEdited: root.editText = text
            Keys.onReturnPressed: root.accepted()
            Keys.onEnterPressed: root.accepted()

            HoverHandler {
                id: textHover
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: Theme.surfaceSunken
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.accent

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - root.arrowWidth
            radius: Theme.radiusSm
            color: textHover.hovered || textInput.activeFocus ? Theme.surfaceHover : Theme.transparent
        }
    }

    popup: Controls.Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight, 240)
        padding: 1

        function toggle() {
            if (root.popup.visible) {
                root.popup.close()
            } else {
                root.popup.open()
            }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }

        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.surfaceSunken
            border.width: 1
            border.color: Theme.border
        }
    }
}
