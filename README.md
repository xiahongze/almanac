# Almanac

A Plasma 6 desktop widget that shows each Gregorian day alongside an alternate calendar. Chinese lunar dates are the default. Other systems supported by Plasma's alternate-calendar plugin (Islamic, Hebrew, Persian, Indian national, Japanese and others) work through the same code path.

| Dark | Light |
| --- | --- |
| ![Almanac in dark mode](docs/screenshots/almanac-dark.png) | ![Almanac in light mode](docs/screenshots/almanac-light.png) |

## What it shows

- **Header:** the month title, with ‹ Today › navigation. Scrolling over the grid also changes the month.
- **Grid:** six weeks, each day with its alternate date underneath. By default the alternate text is 80% of the day-number size, adjustable from 50% to 120%. Hover a day to see its full alternate date.
- **Footer:** the selected date in full, with its alternate date, e.g. `Sunday, 4 October 2026 · 丙午八月廿四`.
- **Today:** the highlight moves to the new date automatically. The widget checks every minute and whenever it becomes active again, so suspend/resume and timezone changes are covered. If you have selected a different date, your selection stays; clicking **Today** resumes following.

## Requirements

- Plasma 6 (`plasma-workspace` supplies the calendar QML module and the `alternatecalendar` plugin)
- `kpackagetool6`
- Python 3, for packaging only

## Install

Download `almanac.plasmoid` from a release and run `kpackagetool6 --type Plasma/Applet --install almanac.plasmoid`, or build it from the repo:

```sh
./scripts/install.sh
```

Then add **Almanac** from the widget picker. On the desktop it shows the full calendar. In a panel it shows a date icon that opens the calendar, and the pin button keeps that popup open.

If Plasma is already running an older copy, run `plasmashell --replace &` after upgrading so the new QML loads.

## Settings

**General:**
- theme: System, Light or Dark
- desktop opacity
- alternate date size
- week numbers
- keep the panel popup open

**Calendar system** is Plasma's own plugin page. The calendar system and date offset are stored in `~/.config/plasma_calendar_alternatecalendar`. That file is **shared with the panel clock**, so changing it there changes both.

## How it works

`contents/ui/CalendarView.qml` draws the grid itself on top of `org.kde.plasma.workspace.calendar`'s `Calendar` backend and `DaysModel`. Alternate labels come from an `EventPluginsManager` that has only `alternatecalendar` enabled. Rollover decisions live in `contents/ui/rollover.js`.

## Develop and package

```sh
make test         # qmltestrunner, offscreen, with throwaway config and cache dirs
make lint         # qmllint
make package      # dist/almanac.plasmoid
make install      # package, then install or upgrade with kpackagetool6
make screenshots  # re-render docs/screenshots offscreen
```

The integration test advances a fake clock and checks:
- the selection follows today across midnight
- a manual pick survives a month change
- **Today** resumes following
- the footer shows `丙午八月廿四` for 4 October 2026

## Uninstall

```sh
kpackagetool6 --type Plasma/Applet --remove io.github.xiahongze.almanac
```

## Credits

Calendar backend and alternate-calendar plugin by KDE. They are used from the system install and are not bundled. Licensed under MIT.
