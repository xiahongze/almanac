import QtQuick
import QtTest
import "../contents/ui" as Almanac

TestCase {
    id: testCase
    name: "CalendarIntegration"
    visible: true
    when: windowShown
    width: 640
    height: 520
    function i18n(text, arg) { return arg === undefined ? text : text.replace("%1", arg); }
    property date fakeNow: new Date(2026, 9, 4, 12)
    Almanac.CalendarView {
        id: calendar
        anchors.fill: parent
        clockSource: function() { return testCase.fakeNow; }
    }

    function cell(y, m, d) {
        return findChild(calendar, "almanacCell-" + y + "-" + m + "-" + d);
    }

    // Click once the grid has positioned freshly created cells.
    function clickCell(y, m, d) {
        tryVerify(function() { return cell(y, m, d) !== null; });
        waitForRendering(calendar);
        mouseClick(cell(y, m, d));
    }

    // The alternatecalendar plugin formats dates on a pooled thread; let those
    // jobs finish before the runner tears the plugin down.
    function cleanupTestCase() {
        wait(1000);
    }

    function init() {
        testCase.fakeNow = new Date(2026, 9, 4, 12);
        calendar.today = testCase.fakeNow;
        calendar.goToToday();
    }

    function test_footerShowsAlternateDate() {
        tryCompare(calendar, "selectedSubLabel", "丙午八月廿四");
        compare(findChild(calendar, "selectedDateLabel").text, "Sunday, 4 October 2026");
        // The footer sits below the grid, not above it.
        const footer = findChild(calendar, "selectedDateLabel");
        const lastCell = cell(2026, 11, 8);
        verify(lastCell !== null);
        verify(footer.mapToItem(calendar, 0, 0).y > lastCell.mapToItem(calendar, 0, 0).y);
    }

    function test_rollover() {
        compare(calendar.followToday, true);

        // Following today: both the today mark and the selection move.
        testCase.fakeNow = new Date(2026, 9, 5, 0, 1);
        calendar.checkRollover();
        compare(calendar.today.getDate(), 5);
        compare(calendar.selectedDate.getDate(), 5);
        tryCompare(calendar, "selectedSubLabel", "丙午八月廿五");

        // A manual pick sticks across midnight, but today still moves.
        clickCell(2026, 10, 3);
        compare(calendar.selectedDate.getDate(), 3);
        compare(calendar.followToday, false);
        testCase.fakeNow = new Date(2026, 10, 1, 12);
        calendar.checkRollover();
        compare(calendar.today.getMonth(), 10);
        compare(calendar.selectedDate.getMonth(), 9);
        compare(calendar.selectedDate.getDate(), 3);
        compare(calendar.displayedDate.getMonth(), 9);

        // Today resumes following.
        mouseClick(findChild(calendar, "todayButton"));
        compare(calendar.followToday, true);
        compare(calendar.displayedDate.getMonth(), 10);
        testCase.fakeNow = new Date(2027, 0, 1, 12);
        calendar.checkRollover();
        compare(calendar.selectedDate.getFullYear(), 2027);
        compare(calendar.selectedDate.getDate(), 1);
        compare(calendar.displayedDate.getFullYear(), 2027);
    }

    function test_clickOtherMonthNavigates() {
        clickCell(2026, 11, 2);
        compare(calendar.displayedDate.getMonth(), 10);
        compare(calendar.followToday, false);
    }

    function test_monthPickerJumps() {
        const title = findChild(calendar, "titleButton");
        mouseClick(title);
        compare(calendar.pickerMode, "months");
        compare(calendar.pickerYear, 2026);
        calendar.next();
        compare(calendar.pickerYear, 2027);
        waitForRendering(calendar);
        mouseClick(findChild(calendar, "pickMonth-3"));
        compare(calendar.pickerMode, "");
        compare(calendar.displayedDate.getFullYear(), 2027);
        compare(calendar.displayedDate.getMonth(), 2);
        // Browsing is not a selection, so today keeps being followed.
        compare(calendar.followToday, true);
        compare(calendar.selectedDate.getMonth(), 9);
    }

    function test_yearPickerJumps() {
        const title = findChild(calendar, "titleButton");
        mouseClick(title);
        mouseClick(title);
        compare(calendar.pickerMode, "years");
        compare(calendar.decadeStart, 2020);
        calendar.previous();
        compare(calendar.decadeStart, 2010);
        waitForRendering(calendar);
        mouseClick(findChild(calendar, "pickYear-2015"));
        compare(calendar.pickerMode, "months");
        compare(calendar.pickerYear, 2015);
        waitForRendering(calendar);
        mouseClick(findChild(calendar, "pickMonth-6"));
        compare(calendar.displayedDate.getFullYear(), 2015);
        compare(calendar.displayedDate.getMonth(), 5);
        mouseClick(findChild(calendar, "todayButton"));
        compare(calendar.pickerMode, "");
        compare(calendar.displayedDate.getFullYear(), 2026);
    }
}
