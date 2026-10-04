pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    readonly property bool isDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    property date today: new Date()

    Plasmoid.icon: "view-calendar"
    Plasmoid.title: i18n("Almanac")
    Plasmoid.backgroundHints: isDesktop ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground
    preferredRepresentation: isDesktop ? fullRepresentation : null
    switchWidth: isDesktop ? -1 : Kirigami.Units.gridUnit * 28
    switchHeight: isDesktop ? -1 : Kirigami.Units.gridUnit * 20
    hideOnWindowDeactivate: !Plasmoid.configuration.pin
    toolTipMainText: i18n("Almanac")
    toolTipSubText: Qt.formatDate(today, Locale.LongFormat)

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: implicitWidth
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.85
            height: width
            radius: 3
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.textColor
            Rectangle {
                width: parent.width
                height: parent.height * 0.24
                color: Kirigami.Theme.highlightColor
            }
            Controls.Label {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.height * 0.12
                text: root.today.getDate()
                font.bold: true
                font.pixelSize: parent.height * 0.5
            }
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }
    fullRepresentation: CalendarView {
        desktop: root.isDesktop
        themeMode: Plasmoid.configuration.themeMode
        desktopOpacity: Plasmoid.configuration.desktopOpacity
        showWeekNumbers: Plasmoid.configuration.showWeekNumbers
        pinned: Plasmoid.configuration.pin
        onPinToggled: Plasmoid.configuration.pin = !Plasmoid.configuration.pin
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.today = new Date() }
    Connections {
        target: Qt.application
        function onStateChanged() { root.today = new Date(); }
    }
}
