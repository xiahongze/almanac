pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar

ColumnLayout {
    id: page
    property alias cfg_themeMode: theme.currentValue
    property alias cfg_desktopOpacity: opacitySlider.value
    property alias cfg_showWeekNumbers: weeks.checked
    property alias cfg_pin: pin.checked
    property string cfg_themeModeDefault: "system"
    property int cfg_desktopOpacityDefault: 85
    property bool cfg_showWeekNumbersDefault: false
    property bool cfg_pinDefault: false
    readonly property bool calendarConfigReady: calendarConfig.status === Loader.Ready
    signal configurationChanged()

    function saveConfig() {
        const configItem = calendarConfig.item;
        if (configItem) {
            // The calendar plugin provides saveConfig dynamically.
            // qmllint disable missing-property
            configItem.saveConfig();
            // qmllint enable missing-property
        }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true
        Controls.ComboBox {
            id: theme
            Kirigami.FormData.label: i18n("Theme:")
            textRole: "text"
            valueRole: "value"
            model: [{text: i18n("System"), value: "system"}, {text: i18n("Light"), value: "light"}, {text: i18n("Dark"), value: "dark"}]
        }
        Controls.Slider {
            id: opacitySlider
            Kirigami.FormData.label: i18n("Desktop opacity:")
            from: 10
            to: 100
            stepSize: 5
        }
        Controls.CheckBox { id: weeks; text: i18n("Show week numbers") }
        Controls.CheckBox { id: pin; text: i18n("Keep panel popup open") }
    }
    Kirigami.Heading { text: i18n("Calendar system"); level: 2 }
    Controls.Label {
        Layout.fillWidth: true
        text: i18n("This setting is shared with Plasma's panel clock. Select Chinese for lunar dates.")
        wrapMode: Text.Wrap
    }
    PlasmaCalendar.EventPluginsManager { id: plugins; enabledPlugins: ["alternatecalendar"] }
    Instantiator {
        model: plugins.model
        delegate: QtObject {
            required property string pluginId
            required property url configUi
            Component.onCompleted: {
                if (pluginId === "alternatecalendar")
                    calendarConfig.source = configUi;
            }
        }
    }
    Loader {
        id: calendarConfig
        Layout.fillWidth: true
        Layout.preferredHeight: item ? (item as Item).implicitHeight : 0
    }
    Connections {
        target: calendarConfig.item
        function onUnsavedChangesChanged() { page.configurationChanged(); }
    }
    Controls.Label {
        visible: calendarConfig.status === Loader.Error || calendarConfig.source.toString() === ""
        text: i18n("Install Plasma's alternate calendar plugin to configure the calendar system.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
