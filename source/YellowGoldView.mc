import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.SensorHistory;

// Clean, centered watch face:
//   - large HH:MM in the upper-center
//   - date line just below
//   - a bottom row of enabled data fields (steps / heart rate / body battery)
// Solid black background, configurable bright accent (default yellow-gold).
class YellowGoldView extends WatchUi.WatchFace {

    private var _isSleeping as Boolean = false;
    private var _w as Number = 454;
    private var _h as Number = 454;

    // Position cache for the small seconds text, so onPartialUpdate can
    // redraw just that region without recomputing the whole face.
    private var _secX as Number = 0;
    private var _secY as Number = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
    }

    // Full redraw (once per minute, plus on settings/show).
    function onUpdate(dc as Graphics.Dc) as Void {
        var cfg = Settings.load();
        var accent = Theme.accentColor(cfg[:accent] as Number);

        dc.setColor(Theme.BACKGROUND, Theme.BACKGROUND);
        dc.clear();

        drawTime(dc, cfg, accent);
        drawDate(dc, cfg, accent);
        drawDataRow(dc, cfg, accent);

        // Draw seconds inline on the full refresh too (kept live by
        // onPartialUpdate between minutes).
        if ((cfg[:showSeconds] as Boolean) && !_isSleeping) {
            drawSeconds(dc, accent, false);
        }
    }

    // Per-second redraw of only the seconds region while awake.
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        var cfg = Settings.load();
        if ((cfg[:showSeconds] as Boolean) && !_isSleeping) {
            var accent = Theme.accentColor(cfg[:accent] as Number);
            drawSeconds(dc, accent, true);
        }
    }

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    // ---- Drawing helpers ---------------------------------------------------

    private function drawTime(dc as Graphics.Dc, cfg as Dictionary, accent as Number) as Void {
        var clock = System.getClockTime();
        var hour = clock.hour;
        var min = clock.min;
        var fmt = cfg[:timeFormat] as Number;

        var timeStr;
        var ampm = null;
        if (fmt == Settings.TIME_12H) {
            var h12 = hour % 12;
            if (h12 == 0) { h12 = 12; }
            timeStr = h12.format("%d") + ":" + min.format("%02d");
            ampm = (hour >= 12) ? "PM" : "AM";
        } else if (fmt == Settings.TIME_MILITARY) {
            timeStr = hour.format("%02d") + min.format("%02d");
        } else {
            timeStr = hour.format("%02d") + ":" + min.format("%02d");
        }

        var font = Graphics.FONT_NUMBER_HOT;
        var cx = _w / 2;
        var cy = (_h * 0.40).toNumber();

        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, font, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Compute the right edge of the time block for AM/PM + seconds.
        var tw = dc.getTextWidthInPixels(timeStr, font);
        var fh = Graphics.getFontHeight(font);
        var rightX = cx + (tw / 2) + 8;

        if (ampm != null) {
            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightX, cy - (fh / 2) + 6, Graphics.FONT_TINY, ampm,
                Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Cache the seconds slot at the bottom-right of the time block.
        var secFh = Graphics.getFontHeight(Graphics.FONT_SMALL);
        _secX = rightX;
        _secY = cy + (fh / 2) - secFh - 4;
    }

    private function drawSeconds(dc as Graphics.Dc, accent as Number, doClip as Boolean) as Void {
        var secStr = System.getClockTime().sec.format("%02d");
        var font = Graphics.FONT_SMALL;
        var w = dc.getTextWidthInPixels(secStr, font);
        var h = Graphics.getFontHeight(font);

        if (doClip) {
            dc.setClip(_secX, _secY, w + 6, h + 2);
            dc.setColor(Theme.BACKGROUND, Theme.BACKGROUND);
            dc.clear();
        }
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_secX, _secY, font, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        if (doClip) {
            dc.clearClip();
        }
    }

    private function drawDate(dc as Graphics.Dc, cfg as Dictionary, accent as Number) as Void {
        var now = Time.now();
        var fmt = cfg[:dateFormat] as Number;
        var dateStr;

        if (fmt == Settings.DATE_NUMERIC) {
            var s = Gregorian.info(now, Time.FORMAT_SHORT);
            dateStr = (s.month as Number).format("%02d") + "/" + s.day.format("%02d");
        } else {
            var m = Gregorian.info(now, Time.FORMAT_MEDIUM);
            if (fmt == Settings.DATE_DAY_MONTH) {
                dateStr = m.day.format("%d") + " " + (m.month as String);
            } else { // DATE_WEEKDAY
                dateStr = (m.day_of_week as String) + " " + (m.month as String) + " " + m.day.format("%d");
            }
            dateStr = dateStr.toUpper();
        }

        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w / 2, (_h * 0.60).toNumber(), Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDataRow(dc as Graphics.Dc, cfg as Dictionary, accent as Number) as Void {
        var fields = [] as Array;
        if (cfg[:showSteps] as Boolean) {
            fields.add(["STEPS", getSteps()]);
        }
        if (cfg[:showHr] as Boolean) {
            fields.add(["HR", getHeartRate()]);
        }
        if (cfg[:showBb] as Boolean) {
            fields.add(["BODY", getBodyBattery()]);
        }

        var n = fields.size();
        if (n == 0) {
            return;
        }

        var rowY = (_h * 0.80).toNumber();
        var labelFont = Graphics.FONT_XTINY;
        var valueFont = Graphics.FONT_TINY;
        var labelH = Graphics.getFontHeight(labelFont);

        for (var i = 0; i < n; i += 1) {
            var fx = (_w * (i + 1)) / (n + 1);
            var label = fields[i][0] as String;
            var value = fields[i][1] as String;

            dc.setColor(Theme.LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(fx, rowY, labelFont, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            dc.drawText(fx, rowY + labelH, valueFont, value,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ---- Data sources ------------------------------------------------------

    private function getSteps() as String {
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            return (info.steps as Number).format("%d");
        }
        return "0";
    }

    private function getHeartRate() as String {
        // Prefer the live reading from the current activity info.
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return (act.currentHeartRate as Number).format("%d");
        }
        // Fall back to the most recent sample from sensor history.
        if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            var it = SensorHistory.getHeartRateHistory({:period => 1});
            if (it != null) {
                var sample = it.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Number).format("%d");
                }
            }
        }
        return "--";
    }

    private function getBodyBattery() as String {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var it = SensorHistory.getBodyBatteryHistory({:period => 1});
            if (it != null) {
                var sample = it.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Number).format("%d");
                }
            }
        }
        return "--";
    }
}
