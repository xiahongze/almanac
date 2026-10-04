.pragma library

function sameDay(a, b) {
    return a instanceof Date && b instanceof Date
        && !isNaN(a.getTime()) && !isNaN(b.getTime())
        && a.getFullYear() === b.getFullYear()
        && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function dayChanged(previous, now) { return !sameDay(previous, now); }
function nextFollowState(selected, today) { return sameDay(selected, today); }
