import QtQuick
import QtQuick.Layouts
import Quickshell
import Src.Ui as Ui

PopupWindow {
    id: root

    required property var anchorWindow
    required property var clockDate
    property var viewDate: firstOfMonth(clockDate ?? new Date())
    property var selectedDate: startOfDay(clockDate ?? new Date())

    anchor.window: root.anchorWindow
    anchor.rect.x: root.anchorWindow.width - implicitWidth - 20
    anchor.rect.y: root.anchorWindow.height + 8
    implicitWidth: 360
    implicitHeight: calendarCard.implicitHeight
    visible: false
    grabFocus: true
    color: Ui.Theme.transparent

    Keys.onEscapePressed: root.visible = false

    readonly property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var yearOptions: buildYearOptions(viewDate.getFullYear())
    readonly property var calendarDays: buildCalendarDays(viewDate)

    onVisibleChanged: {
        if (visible) {
            viewDate = firstOfMonth(clockDate);
            selectedDate = startOfDay(clockDate);
        }
    }

    function startOfDay(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate());
    }

    function firstOfMonth(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1);
    }

    function sameDay(left, right) {
        return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    function offsetMonth(offset) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + offset, 1);
    }

    function selectDate(date) {
        selectedDate = startOfDay(date);
        viewDate = firstOfMonth(date);
    }

    function setViewMonth(month) {
        viewDate = new Date(viewDate.getFullYear(), month, 1);
    }

    function setViewYear(year) {
        viewDate = new Date(year, viewDate.getMonth(), 1);
    }

    function parseMonth(text) {
        const normalized = text.trim().toLowerCase();
        if (normalized.length === 0)
            return -1;

        const numeric = Number(normalized);
        if (Number.isInteger(numeric) && numeric >= 1 && numeric <= 12)
            return numeric - 1;

        return monthNames.findIndex(month => month.toLowerCase().startsWith(normalized));
    }

    function parseYear(text) {
        const year = Number(text.trim());
        return Number.isInteger(year) && year >= 1 && year <= 9999 ? year : viewDate.getFullYear();
    }

    function buildYearOptions(centerYear) {
        const years = new Array(101);
        for (let index = 0; index < years.length; index++)
            years[index] = centerYear - 50 + index;
        return years;
    }

    function buildCalendarDays(monthDate) {
        const first = firstOfMonth(monthDate);
        const mondayOffset = (first.getDay() + 6) % 7;
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - mondayOffset);
        const days = new Array(42);

        for (let index = 0; index < days.length; index++) {
            const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
            days[index] = {
                date: date,
                label: date.getDate().toString(),
                currentMonth: date.getMonth() === monthDate.getMonth(),
                weekend: date.getDay() === 0 || date.getDay() === 6
            };
        }

        return days;
    }

    Ui.UiCard {
        id: calendarCard

        anchors.fill: parent
        implicitWidth: 360
        implicitHeight: content.implicitHeight + 28

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: Ui.Theme.radiusSm
                    color: previousMouse.containsMouse ? Ui.Theme.surfaceHover : Ui.Theme.surfaceSunken

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.offsetMonth(-1)
                    }

                    Ui.UiText {
                        anchors.centerIn: parent
                        text: ""
                        color: Ui.Theme.textPrimary
                        font.pixelSize: Ui.Theme.textLg
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Ui.UiComboBox {
                                id: monthSelector

                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 30
                                model: root.monthNames
                                currentIndex: root.viewDate.getMonth()
                                onActivated: function(index) {
                                    root.setViewMonth(index);
                                }
                                onAccepted: {
                                    const month = root.parseMonth(editText);
                                    if (month >= 0)
                                        root.setViewMonth(month);
                                    editText = root.monthNames[root.viewDate.getMonth()];
                                }
                            }

                            Ui.UiComboBox {
                                id: yearSelector

                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 30
                                model: root.yearOptions
                                currentIndex: root.yearOptions.indexOf(root.viewDate.getFullYear())
                                validator: IntValidator {
                                    bottom: 1
                                    top: 9999
                                }
                                onActivated: function(index) {
                                    root.setViewYear(root.yearOptions[index]);
                                }
                                onAccepted: {
                                    root.setViewYear(root.parseYear(editText));
                                    editText = root.viewDate.getFullYear().toString();
                                }
                            }
                        }

                        Ui.UiText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDate(root.selectedDate, "dddd, dd MMMM yyyy")
                            color: Ui.Theme.textMuted
                            font.pixelSize: Ui.Theme.textSm
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: Ui.Theme.radiusSm
                    color: nextMouse.containsMouse ? Ui.Theme.surfaceHover : Ui.Theme.surfaceSunken

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.offsetMonth(1)
                    }

                    Ui.UiText {
                        anchors.centerIn: parent
                        text: ""
                        color: Ui.Theme.textPrimary
                        font.pixelSize: Ui.Theme.textLg
                    }
                }

            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: root.weekdays

                    Ui.UiText {
                        required property string modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: modelData === "Sat" || modelData === "Sun" ? Ui.Theme.textMuted : Ui.Theme.textSecondary
                        font.pixelSize: Ui.Theme.textSm
                    }
                }

                Repeater {
                    model: root.calendarDays

                    Rectangle {
                        required property var modelData

                        readonly property bool today: root.sameDay(modelData.date, root.clockDate)
                        readonly property bool selected: root.sameDay(modelData.date, root.selectedDate)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: Ui.Theme.radiusSm
                        color: selected ? Ui.Theme.accent : dayMouse.containsMouse ? Ui.Theme.surfaceHover : today ? Ui.Theme.surfaceActive : Ui.Theme.transparent
                        border.width: today && !selected ? 1 : 0
                        border.color: Ui.Theme.accent

                        MouseArea {
                            id: dayMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectDate(modelData.date)
                        }

                        Ui.UiText {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: selected ? Ui.Theme.textInverse : !modelData.currentMonth ? Ui.Theme.textMuted : modelData.weekend ? Ui.Theme.accentHover : Ui.Theme.textPrimary
                            font.pixelSize: Ui.Theme.textMd
                            font.bold: selected || today
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Ui.UiButton {
                    text: "Today"
                    normalColor: Ui.Theme.surfaceSunken
                    hoverColor: Ui.Theme.surfaceHover
                    textColor: Ui.Theme.textPrimary
                    onClicked: root.selectDate(root.clockDate)
                }

                Ui.UiText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: Qt.formatDateTime(root.clockDate, "hh:mm")
                    color: Ui.Theme.textMuted
                    font.pixelSize: Ui.Theme.textSm
                }
            }
        }
    }
}
