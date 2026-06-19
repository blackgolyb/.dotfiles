import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias text: input.text
    property alias cursorPosition: input.cursorPosition
    readonly property alias inputActiveFocus: input.activeFocus
    property string iconText: ""
    property string placeholderText: ""
    property bool inputEnabled: true
    property int echoMode: TextInput.Normal
    property string passwordCharacter: "*"
    property int textPixelSize: Theme.textXl
    property int iconPixelSize: Theme.textXl
    property color selectionTextColor: Theme.textInverse
    signal accepted
    signal escaped
    signal moveRequested(int delta)
    signal pageMoveRequested(int delta)

    implicitHeight: 46
    radius: Theme.radiusMd
    color: Theme.surfaceSunken
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent

    function forceInputFocus(): void {
        input.forceActiveFocus();
    }

    function deletePreviousWord(): void {
        const currentText = input.text;
        let start = input.cursorPosition;
        const end = start;

        while (start > 0 && /\s/.test(currentText.charAt(start - 1)))
            start--;
        while (start > 0 && !/\s/.test(currentText.charAt(start - 1)))
            start--;

        input.text = currentText.slice(0, start) + currentText.slice(end);
        input.cursorPosition = start;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: Theme.spacingSm

        UiText {
            visible: root.iconText.length > 0
            text: root.iconText
            color: Theme.accent
            font.pixelSize: root.iconPixelSize
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            enabled: root.inputEnabled
            echoMode: root.echoMode
            passwordCharacter: root.passwordCharacter
            color: Theme.textPrimary
            selectedTextColor: root.selectionTextColor
            selectionColor: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: root.textPixelSize
            clip: true
            verticalAlignment: TextInput.AlignVCenter

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: root.placeholderText
                visible: input.text.length === 0 && root.placeholderText.length > 0
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: root.textPixelSize
            }

            Keys.onPressed: event => {
                if ((event.key === Qt.Key_W || event.key === Qt.Key_Backspace) && event.modifiers & Qt.ControlModifier) {
                    root.deletePreviousWord();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.escaped();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.accepted();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    root.moveRequested(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    root.moveRequested(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    root.pageMoveRequested(8);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    root.pageMoveRequested(-8);
                    event.accepted = true;
                }
            }
        }
    }
}
