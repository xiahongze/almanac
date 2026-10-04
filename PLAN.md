# Almanac — Western + alternate calendar desktop widget

> **Scope update:** the design is general, so the second calendar can be any system the `alternatecalendar` plugin supports: Chinese, Islamic, Hebrew, Persian, Indian national, Japanese and so on. v1 ships with **Chinese** as the default and is tested only with Chinese.
> - None of the code assumes Chinese. Cell sub-labels and the header label come from the plugin's generic `subDayLabel` / `subLabel`.
> - The config page has a **"Calendar system"** section. It loads the plugin's own config UI (`AlternateCalendarConfig.qml`, found from the plugin's config URL in `EventPluginsManager.model`, the same way Digital Clock does it).
> - Because that setting lives in `~/.config/plasma_calendar_alternatecalendar`, it is shared with the panel clock. This is noted in the README.
> - **Name: Almanac** (one date in several calendar systems; "Lunisolar" would be too narrow). Id `io.github.xiahongze.almanac`, repo `/home/hxia/git/almanac`.
> - Later work, kept outside v1: a widget-local calendar system or more than one alternate row, which would need our own conversion code (ICU via a small C++ plugin) instead of the shared plugin.

## Context
The stock Digital Clock popup shows a Gregorian month grid with Chinese lunar sub-labels, but it can only live in the panel, and the desktop calendar widget gets stuck on the day it was loaded instead of moving to the new day. We want a Plasma 6 desktop widget that:
- shows a month grid with the Western date and Chinese lunar day under each cell
- shows the selected date and its full Chinese label, e.g. `丙午八月廿四`, in the top-left header
- moves the highlighted "today" to the new date every day, unless the user has picked another date. Clicking **Today** returns to following today.
- has no events pane

**Name:** **Almanac**: one date in several calendar systems. Id: `io.github.xiahongze.almanac`. Repo: `/home/hxia/git/almanac`, intended remote `github.com/xiahongze/almanac`.

## Approach: new widget built on Plasma's calendar QML module
The digital clock is compiled into `/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.digitalclock.so`, so there is no QML to copy from. The parts the popup is built from are public, though, so the widget can use them directly and stay small:
- `org.kde.plasma.workspace.calendar` (`/usr/lib/qt6/qml/org/kde/plasma/workspace/calendar/`)
  - `MonthView`: gives the Days/Months/Years tabs, the ‹ Today › header and the swipe grid.
  - `EventPluginsManager { enabledPlugins: ["alternatecalendar"] }`: provides the lunar sub-labels. It reads the system-wide `~/.config/plasma_calendar_alternatecalendar` file, which already has `calendarSystem=Chinese`.
  - `MonthView.todayAuxilliaryText` / `currentDateAuxilliaryText`: the full `丙午八月廿四` label for the header.
- `MonthView.today` is an alias to `Calendar.today`, which can be written (`setToday`). The stale-day bug happens because nothing ever updates it.

## Files (same layout as pr-pulse / agent-pulse)
```
metadata.json            KPackageStructure Plasma/Applet, Id io.github.xiahongze.almanac, v0.1.0,
                         Authors [{Name: "Hongze Xia"}], MIT, Category "Date and Time",
                         Icon "view-calendar", API min 6.0, MainScript ui/main.qml
LICENSE (MIT 2026 Hongze Xia)  README.md  CHANGELOG.md (## 0.1.0 — 2026-10-04)  Makefile  .gitignore
.github/workflows/ci.yml, release.yml   (copied from pr-pulse, with the Python steps swapped for Qt test/lint)
contents/config/main.xml     General: themeMode (system/light/dark), desktopOpacity, showWeekNumbers, pin
contents/config/config.qml   one General ConfigCategory → configGeneral.qml
contents/ui/main.qml         PlasmoidItem; compactRepresentation = date icon for the panel, fullRepresentation = CalendarView
contents/ui/CalendarView.qml header (left column) + MonthView (right) + day-rollover Timer
contents/ui/configGeneral.qml
contents/ui/rollover.js      .pragma library, pure functions so they can be tested
tests/tst_rollover.qml       qmltestrunner TestCase
scripts/install.sh, package.sh   copied from pr-pulse with the id and name changed; no src/*.py to bundle
docs/screenshots/almanac-dark.png, -light.png
```

## Key behaviour
**Layout** (desktop `Planar`, with a translucent surface like agent-pulse):
- Left header column:
  - large `Qt.formatDate(currentDate, "dddd, d MMMM yyyy")`
  - below it, `monthView.currentDateAuxilliaryText`, the Chinese year, month and day of the selected date
  - optionally, a smaller "Today: …" line when the selection is not today
- Right: `PlasmaCalendar.MonthView`, with `showDigitalClockHeader: false`, `eventPluginsManager` set to the alternatecalendar-only manager, and `showWeekNumbers` taken from config.

**Daily rollover** (`rollover.js` + a Timer in CalendarView):
- `followToday` starts as `true`.
- When the user clicks a date (`onCurrentDateChanged` while not inside our own reset), `followToday` is set to `!sameDay(currentDate, today)`, which is false whenever they picked another day.
- When the Today button is clicked, `MonthView.resetToToday()` runs, and `onCurrentDateChanged` sets `followToday` back to true.
- The Timer runs every 60 s and also on `Qt.application.state` changes. Polling every minute keeps it correct after suspend/resume and timezone changes. Each tick runs `dayChanged(lastKnownDay, new Date())`. When the day has changed:
  - set `monthView.today = new Date()`, which moves the highlight to the new day
  - if `followToday`, call `monthView.resetToToday()`, which also moves the selection, the visible month and the header
  - otherwise, keep the user's selected date and month
- `rollover.js` exports `sameDay(a, b)`, `dayChanged(prev, now)` and `nextFollowState(selected, today)`.

**Panel mode:**
- compact view: a small calendar icon showing the day number
- popup: the same CalendarView, with a pin button as in the other widgets
- The main target is the desktop.

## Dev workflow (matches existing repos)
- Makefile targets:
  - `test`: `qmltestrunner -input tests`, falling back to `/usr/lib/qt6/bin/qmltestrunner`, using `QT_QPA_PLATFORM=offscreen`
  - `lint`: qmllint `contents/ui/*.qml`
  - `package`
  - `install`
- `install.sh`: package, then `kpackagetool6 --upgrade` or `--install`, then `kbuildsycoca6 --noincremental`.
- Strings use `i18n()`. No translation catalog.
- Git:
  - `git init` on `main`
  - commits like `chore: scaffold Almanac project`, then `feat: …`, each with the Co-Authored-By line
  - nothing is pushed or turned into a GitHub repo without asking

## Verification
1. `make test`: the rollover unit tests pass (same day, midnight crossing, month/year crossing, follow/not-follow).
2. `make lint` reports no errors.
3. `make install`, then add Almanac to the desktop. Check:
   - lunar sub-labels show in the cells
   - the header shows `丙午八月廿四` for 4 Oct 2026
4. Rollover check without waiting for midnight: temporarily point the debug path (`plasmoidviewer -a .` with an env/config override for the clock source, or a temporary test property) at a fake "now" one day later.
   - Confirm the highlight and the selection move to the new day.
   - Select another date, repeat, and confirm the selection stays while the today highlight still moves.
   - Click Today and confirm following resumes.
5. Take dark and light screenshots into `docs/screenshots/`.
