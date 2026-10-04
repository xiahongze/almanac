pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "rollover.js" as Rollover

// Month grid drawn by Almanac itself on top of Plasma's calendar backend, so
// cell typography and layout are ours while the alternate calendar labels
// still come from the system "alternatecalendar" plugin.
Item {
    id: root
    property bool desktop: true
    property string themeMode: "system"
    property int desktopOpacity: 85
    property bool showWeekNumbers: false
    property int alternateTextScale: 80
    property bool pinned: false
    // Tests can advance this source without changing the machine's clock.
    property var clockSource: function() { return new Date(); }
    property date today: clockSource()
    property date selectedDate: today
    property string selectedSubLabel: ""
    property bool followToday: true
    readonly property alias displayedDate: backend.displayedDate
    signal pinToggled()

    readonly property bool forcedDark: themeMode === "dark"
    readonly property bool forcedLight: themeMode === "light"
    readonly property var colors: ({
        surface: forcedDark ? "#171c24" : forcedLight ? "#ffffff" : Kirigami.Theme.backgroundColor,
        ink: forcedDark ? "#eef2f6" : forcedLight ? "#20252b" : Kirigami.Theme.textColor,
        muted: forcedDark ? "#929ba6" : forcedLight ? "#66707b" : Qt.alpha(Kirigami.Theme.textColor, 0.6),
        accent: forcedDark ? "#4ea1f3" : forcedLight ? "#2a76c6" : Kirigami.Theme.highlightColor,
        rule: forcedDark ? "#2c3440" : forcedLight ? "#dde2e8" : Qt.alpha(Kirigami.Theme.textColor, 0.15)
    })

    implicitWidth: Kirigami.Units.gridUnit * 28
    implicitHeight: Kirigami.Units.gridUnit * 24
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    function selectDate(date) {
        if (!Rollover.sameDay(date, selectedDate))
            selectedSubLabel = "";
        selectedDate = date;
        followToday = Rollover.nextFollowState(date, today);
        if (date.getMonth() !== backend.displayedDate.getMonth()
                || date.getFullYear() !== backend.displayedDate.getFullYear())
            backend.goToYearAndMonth(date.getFullYear(), date.getMonth() + 1);
    }

    function goToToday() {
        backend.resetToToday();
        selectDate(today);
    }

    function checkRollover() {
        const now = clockSource();
        if (!Rollover.dayChanged(today, now))
            return;
        today = now;
        if (followToday)
            goToToday();
    }

    PlasmaCalendar.EventPluginsManager {
        id: plugins
        enabledPlugins: ["alternatecalendar"]
    }
    PlasmaCalendar.Calendar {
        id: backend
        days: 7
        weeks: 6
        firstDayOfWeek: Qt.locale().firstDayOfWeek
        today: root.today
        Component.onCompleted: daysModel.setPluginsManager(plugins)
    }

    Rectangle {
        anchors.fill: parent
        visible: root.desktop
        radius: Kirigami.Units.cornerRadius * 2
        color: Qt.alpha(root.colors.surface, root.desktopOpacity / 100)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * (root.desktop ? 2 : 1)
        spacing: Kirigami.Units.smallSpacing

        // Month title and navigation.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(backend.displayedDate, "MMMM yyyy")
                color: root.colors.ink
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                elide: Text.ElideRight
            }
            NavButton {
                text: "‹"
                accessibleName: i18n("Previous month")
                onClicked: backend.previousMonth()
            }
            NavButton {
                objectName: "todayButton"
                text: i18n("Today")
                onClicked: root.goToToday()
            }
            NavButton {
                text: "›"
                accessibleName: i18n("Next month")
                onClicked: backend.nextMonth()
            }
            Controls.ToolButton {
                visible: !root.desktop
                checkable: true
                checked: root.pinned
                icon.name: "window-pin"
                display: Controls.AbstractButton.IconOnly
                text: i18n("Keep open")
                onClicked: root.pinToggled()
            }
        }

        // Weekday names.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Item { visible: root.showWeekNumbers; Layout.preferredWidth: grid.weekColumnWidth }
            Repeater {
                model: 7
                Text {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignHCenter
                    // Qt weekdays run 1 (Monday) to 7 (Sunday).
                    text: backend.dayName((backend.firstDayOfWeek - 1 + index) % 7 + 1)
                    color: root.colors.muted
                    elide: Text.ElideRight
                }
            }
        }

        // Day grid.
        Item {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property real weekColumnWidth: root.showWeekNumbers ? Kirigami.Units.gridUnit * 1.6 : 0
            readonly property real cellWidth: (width - weekColumnWidth) / 7
            readonly property real cellHeight: height / 6
            readonly property real numberPixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize,
                Math.min(cellHeight * 0.32, cellWidth * 0.32))
            readonly property real subPixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize,
                Math.min(numberPixelSize * root.alternateTextScale / 100, cellHeight * 0.32))

            Column {
                visible: root.showWeekNumbers
                Repeater {
                    model: root.showWeekNumbers ? backend.weeksModel : []
                    Text {
                        required property var modelData
                        width: grid.weekColumnWidth
                        height: grid.cellHeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: root.colors.muted
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }

            Grid {
                x: grid.weekColumnWidth
                columns: 7
                Repeater {
                    model: backend.daysModel
                    delegate: DayCell {}
                }
            }

            // Scroll through months like Plasma's own calendar.
            WheelHandler {
                property real accumulated: 0
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    accumulated += event.angleDelta.y;
                    while (accumulated >= 120) { accumulated -= 120; backend.previousMonth(); }
                    while (accumulated <= -120) { accumulated += 120; backend.nextMonth(); }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.colors.rule
        }

        // Selected date, Gregorian and alternate calendar, below the grid.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            Text {
                objectName: "selectedDateLabel"
                Layout.fillWidth: true
                text: Qt.formatDate(root.selectedDate, "dddd, d MMMM yyyy")
                color: root.colors.ink
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
                elide: Text.ElideRight
            }
            Text {
                objectName: "selectedSubLabel"
                text: root.selectedSubLabel
                color: root.colors.ink
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
            }
        }
    }

    // Drawn with the widget palette so forced light/dark themes stay legible.
    component NavButton: Rectangle {
        id: nav
        property string text
        property string accessibleName: text
        signal clicked()
        implicitWidth: Math.max(label.implicitWidth + Kirigami.Units.largeSpacing * 2, implicitHeight)
        implicitHeight: label.implicitHeight + Kirigami.Units.smallSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: navMouse.containsMouse ? Qt.alpha(root.colors.ink, 0.1) : "transparent"
        Accessible.role: Accessible.Button
        Accessible.name: accessibleName
        Accessible.onPressAction: clicked()
        Text {
            id: label
            anchors.centerIn: parent
            text: nav.text
            color: root.colors.ink
            font.pixelSize: nav.text.length === 1 ? Kirigami.Theme.defaultFont.pixelSize * 1.6 : Kirigami.Theme.defaultFont.pixelSize
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    component DayCell: Item {
        id: cell
        required property int yearNumber
        required property int monthNumber
        required property int dayNumber
        required property bool isCurrent
        required property string subDayLabel
        required property string subLabel
        readonly property date date: new Date(yearNumber, monthNumber - 1, dayNumber)
        readonly property bool isToday: Rollover.sameDay(date, root.today)
        readonly property bool isSelected: Rollover.sameDay(date, root.selectedDate)

        objectName: "almanacCell-" + yearNumber + "-" + monthNumber + "-" + dayNumber
        width: grid.cellWidth
        height: grid.cellHeight

        function publishSubLabel() {
            if (isSelected && subLabel)
                root.selectedSubLabel = subLabel;
        }
        onIsSelectedChanged: publishSubLabel()
        onSubLabelChanged: publishSubLabel()
        Component.onCompleted: publishSubLabel()

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Kirigami.Units.cornerRadius
            color: cell.isSelected ? Qt.alpha(root.colors.accent, 0.3)
                 : mouse.containsMouse ? Qt.alpha(root.colors.ink, 0.08) : "transparent"
            border.width: cell.isToday ? 2 : cell.isSelected ? 1 : 0
            border.color: root.colors.accent
        }
        Column {
            anchors.centerIn: parent
            width: parent.width
            opacity: cell.isCurrent ? 1 : 0.4
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: cell.dayNumber
                color: root.colors.ink
                font.pixelSize: grid.numberPixelSize
                font.bold: cell.isToday
            }
            Text {
                width: parent.width
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: cell.subDayLabel
                color: root.colors.ink
                font.pixelSize: grid.subPixelSize
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.selectDate(cell.date)
        }
        Controls.ToolTip.visible: mouse.containsMouse && cell.subLabel !== ""
        Controls.ToolTip.text: cell.subLabel
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.checkRollover() }
    Connections {
        target: Qt.application
        function onStateChanged() { root.checkRollover(); }
    }
}
