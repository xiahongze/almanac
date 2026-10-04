import QtQuick
import QtTest
import "../contents/ui/rollover.js" as Rollover

TestCase {
    name: "Rollover"
    function test_dates_data() {
        return [
            {tag: "same day", a: new Date(2026, 9, 4, 0), b: new Date(2026, 9, 4, 23, 59), same: true},
            {tag: "midnight", a: new Date(2026, 9, 4, 23, 59), b: new Date(2026, 9, 5), same: false},
            {tag: "month", a: new Date(2026, 9, 31), b: new Date(2026, 10, 1), same: false},
            {tag: "year", a: new Date(2026, 11, 31), b: new Date(2027, 0, 1), same: false},
            {tag: "backwards", a: new Date(2026, 9, 5), b: new Date(2026, 9, 4), same: false},
            {tag: "invalid", a: new Date(NaN), b: new Date(2026, 9, 4), same: false}
        ];
    }
    function test_dates(data) {
        compare(Rollover.sameDay(data.a, data.b), data.same);
        compare(Rollover.dayChanged(data.a, data.b), !data.same);
        compare(Rollover.nextFollowState(data.a, data.b), data.same);
    }
    function test_followResumes() {
        const today = new Date(2026, 9, 4);
        verify(Rollover.nextFollowState(today, today));
        verify(!Rollover.nextFollowState(new Date(2026, 9, 3), today));
        verify(Rollover.nextFollowState(new Date(2026, 9, 4, 18), today));
    }
}
