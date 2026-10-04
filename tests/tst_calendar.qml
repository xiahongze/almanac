import QtQuick
import QtTest
import "../contents/ui" as Almanac

TestCase {
    id: testCase
    name: "CalendarIntegration"
    visible: true
    when: windowShown
    width: 900
    height: 550
    function i18n(text, arg) { return arg === undefined ? text : text.replace("%1", arg); }
    property date fakeNow: new Date(2026, 9, 4, 12)
    Almanac.CalendarView {
        id: calendar
        anchors.fill: parent
        clockSource: function() { return testCase.fakeNow; }
    }
    function test_rollover() {
        tryVerify(function() { return calendar.selectedAuxiliaryText.length > 0; });
        compare(calendar.selectedAuxiliaryText, "丙午八月廿四");
        compare(calendar.followToday, true);
        testCase.fakeNow = new Date(2026, 9, 5, 12);
        calendar.checkRollover();
        compare(calendar.today.getDate(), 5);
        compare(calendar.selectedDate.getDate(), 5);
        // selectedDate is an alias, exercising the real MonthView handler.
        wait(500);
        const month = findChild(calendar, "almanacMonthView");
        const selectedCell = findChild(calendar, "calendarCell-2026-10-3");
        verify(selectedCell !== null);
        mouseClick(selectedCell);
        compare(calendar.selectedDate.getDate(), 3);
        const visibleMonth = month.selectedMonth;
        compare(calendar.followToday, false);
        testCase.fakeNow = new Date(2026, 10, 1, 12);
        calendar.checkRollover();
        compare(calendar.today.getMonth(), 10);
        compare(calendar.selectedDate.getMonth(), 9);
        compare(month.selectedMonth, visibleMonth);
        compare(calendar.selectedDate.getDate(), 3);
        mouseClick(month.viewHeader.todayButton);
        compare(calendar.followToday, true);
        testCase.fakeNow = new Date(2027, 0, 1, 12);
        calendar.checkRollover();
        compare(calendar.selectedDate.getFullYear(), 2027);
        compare(calendar.selectedDate.getDate(), 1);
    }
}
