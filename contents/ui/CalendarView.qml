pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "rollover.js" as Rollover

Controls.Control {
    id: root
    property bool desktop: true
    property string themeMode: "system"
    property int desktopOpacity: 85
    property bool showWeekNumbers: false
    property bool pinned: false
    // Tests can advance this source without changing the machine's clock.
    property var clockSource: function() { return new Date(); }
    property date lastKnownDay: clockSource()
    property string lastKnownDayKey: Qt.formatDate(lastKnownDay, "yyyy-MM-dd")
    property bool followToday: true
    property bool resetting: false
    property alias selectedDate: monthView.currentDate
    property string selectedAuxiliaryText: ""
    readonly property alias today: monthView.today
    signal pinToggled()

    implicitWidth: Kirigami.Units.gridUnit * 30
    implicitHeight: Kirigami.Units.gridUnit * 30
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: root.desktop ? Qt.alpha(Kirigami.Theme.backgroundColor, root.desktopOpacity / 100) : "transparent"
    }
    palette.text: Kirigami.Theme.textColor
    palette.windowText: Kirigami.Theme.textColor
    palette.buttonText: Kirigami.Theme.textColor
    palette.disabled.text: Kirigami.Theme.disabledTextColor
    palette.disabled.windowText: Kirigami.Theme.disabledTextColor
    palette.disabled.buttonText: Kirigami.Theme.disabledTextColor
    Kirigami.Theme.inherit: themeMode === "system"
    Kirigami.Theme.backgroundColor: themeMode === "dark" ? "#171c24" : themeMode === "light" ? "#ffffff" : undefined
    Kirigami.Theme.disabledTextColor: themeMode === "dark" ? "#929ba6" : themeMode === "light" ? "#727b86" : undefined
    Kirigami.Theme.textColor: themeMode === "dark" ? "#eef2f6" : themeMode === "light" ? "#20252b" : undefined

    function checkRollover() {
        const now = clockSource();
        if (!Rollover.dayChanged(lastKnownDay, now) && lastKnownDayKey === Qt.formatDate(now, "yyyy-MM-dd"))
            return;
        resetting = true;
        monthView.today = now;
        if (followToday)
            monthView.resetToToday();
        resetting = false;
        Qt.callLater(refreshLabels);
        // Keep the old local date key so timezone changes are detected too.
        lastKnownDay = new Date(now.getTime());
        lastKnownDayKey = Qt.formatDate(now, "yyyy-MM-dd");
    }

    PlasmaCalendar.EventPluginsManager {
        id: plugins
        enabledPlugins: ["alternatecalendar"]
    }
    // Plasma binds its auxiliary label when delegates are first created.
    // Observe generic plugin labels so changing today also updates the header.
    function refreshLabels() {
        typographyDelay.restart();
        for (let i = 0; i < labelObserver.count; ++i) {
            const day = labelObserver.objectAt(i) as CalendarDay;
            if (!day)
                continue;
            if (Rollover.sameDay(day.date, monthView.currentDate))
                selectedAuxiliaryText = day.subLabel;
            if (Rollover.sameDay(day.date, monthView.today))
                monthView.todayAuxilliaryText = day.subLabel;
        }
    }
    Instantiator {
        id: labelObserver
        model: monthView.daysModel
        delegate: CalendarDay {}
        onObjectAdded: Qt.callLater(root.refreshLabels)
    }
    component CalendarDay: QtObject {
        required property int yearNumber
        required property int monthNumber
        required property int dayNumber
        required property string subLabel
        readonly property date date: new Date(yearNumber, monthNumber - 1, dayNumber)
        onSubLabelChanged: Qt.callLater(root.refreshLabels)
        onDateChanged: Qt.callLater(root.refreshLabels)
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.largeSpacing
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing * 2
                    Controls.Label {
                        color: Kirigami.Theme.textColor
                        Layout.minimumWidth: 0
                        Layout.fillWidth: true
                        text: Qt.formatDate(monthView.currentDate, "dddd, d MMMM yyyy")
                        font.pixelSize: textMetrics.height * 1.25
                        wrapMode: Text.Wrap
                    }
                    Controls.Label {
                        color: Kirigami.Theme.textColor
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: parent.width * 0.45
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        text: root.selectedAuxiliaryText
                        font.pixelSize: textMetrics.height * 1.25
                        wrapMode: Text.Wrap
                    }
                }
                Controls.Label {
                    color: Kirigami.Theme.textColor
                    Layout.minimumWidth: 0
                    Layout.fillWidth: true
                    visible: !Rollover.sameDay(monthView.currentDate, monthView.today)
                    text: i18n("Today: %1", Qt.formatDate(monthView.today, Locale.LongFormat))
                    wrapMode: Text.Wrap
                    opacity: 0.7
                }
            }
            Controls.ToolButton {
                visible: !root.desktop
                checkable: true
                checked: root.pinned
                icon.name: "window-pin"
                text: i18n("Keep open")
                onClicked: root.pinToggled()
            }
        }
        PlasmaCalendar.MonthView {
            id: monthView
            objectName: "almanacMonthView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            eventPluginsManager: plugins
            showDigitalClockHeader: false
            showWeekNumbers: root.showWeekNumbers
            onWidthChanged: typographyDelay.restart()
            onHeightChanged: typographyDelay.restart()
            onCurrentIndexChanged: typographyDelay.restart()
            onCurrentDateChanged: {
                root.selectedAuxiliaryText = "";
                Qt.callLater(root.refreshLabels);
                if (!root.resetting)
                    root.followToday = Rollover.nextFollowState(currentDate, today);
            }
            onTodayAuxilliaryTextChanged: {
                if (Rollover.sameDay(currentDate, today))
                    currentDateAuxilliaryText = todayAuxilliaryText;
            }
        }
    }
    FontMetrics { id: textMetrics; font: root.font }

    // MonthView exposes no delegate factory. Adjust the existing day delegates'
    // font properties, retaining Plasma's navigation, selection and plugin data.
    function updateDayTypography(item) {
        if (/^calendarCell-\d+-\d+-\d+$/.test(item.objectName)
                && "subDayLabelFontPixelSize" in item) {
            // qmllint disable missing-property
            item.mainLabelFontPixelSize = Qt.binding(function() {
                return Math.max(textMetrics.height * 1.35, item.height * 0.34);
            });
            item.subDayLabelFontPixelSize = Qt.binding(function() {
                return item.mainLabelFontPixelSize;
            });
            // Put the Gregorian number in the upper half of the cell. Plasma
            // normally centres it across the whole cell, leaving little room
            // for a full-size alternate label along the bottom.
            for (let i = 0; i < item.contentItem.children.length; ++i) {
                const label = item.contentItem.children[i];
                if ("font" in label && "text" in label) {
                    label.anchors.bottomMargin = Qt.binding(function() {
                        return item.height * 0.48;
                    });
                }
            }
            // qmllint enable missing-property
        }
        for (let i = 0; i < item.children.length; ++i)
            updateDayTypography(item.children[i]);
    }
    Timer {
        id: typographyDelay
        interval: 100
        onTriggered: root.updateDayTypography(monthView)
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.checkRollover() }
    Connections {
        target: Qt.application
        function onStateChanged() { root.checkRollover(); }
    }
    Component.onCompleted: {
        resetting = true;
        monthView.today = clockSource();
        monthView.resetToToday();
        lastKnownDay = clockSource();
        lastKnownDayKey = Qt.formatDate(lastKnownDay, "yyyy-MM-dd");
        followToday = true;
        resetting = false;
    }
}
