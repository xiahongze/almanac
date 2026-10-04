import QtQuick
import QtTest

TestCase {
    name: "Configuration"
    width: 700
    height: 600
    visible: true
    when: windowShown
    function i18n(text) { return text; }
    function i18ndc(domain, context, text) { return text; }
    function i18ndp(domain, singular, plural, count) { return (count === 1 ? singular : plural).replace("%1", count); }
    Loader { id: settings; anchors.fill: parent; source: "../contents/ui/configGeneral.qml" }
    function test_pluginConfigLoads() { compare(settings.status, Loader.Ready);
        verify(settings.item !== null);
        tryCompare(settings.item, "calendarConfigReady", true);
        settings.item.saveConfig(); }
}
