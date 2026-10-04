import QtQuick
import QtTest
import "../contents/ui" as Almanac

TestCase {
    id: preview
    name: "Screenshots"
    width: 640
    height: 520
    visible: true
    when: windowShown
    function i18n(text, arg) { return arg === undefined ? text : text.replace("%1", arg); }
    Almanac.CalendarView {
        id: calendar
        anchors.fill: parent
        desktopOpacity: 100
        clockSource: function() { return new Date(2026, 9, 4, 12); }
    }
    function cleanupTestCase() { wait(1000); }
    function test_capture() {
        tryVerify(function() { return calendar.selectedSubLabel.length > 0; });
        for (const theme of ["dark", "light"]) {
            calendar.themeMode = theme;
            wait(300);
            const image = grabImage(calendar);
            image.save(Qt.resolvedUrl("../docs/screenshots/almanac-" + theme + ".png").toString().replace("file://", ""));
        }
    }
}
