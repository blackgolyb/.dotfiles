import QtQuick

MouseArea {
    id: root

    property bool focusOnPress: true

    onPressed: {
        if (focusOnPress)
            forceActiveFocus();
    }
}
