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

    // Running vertical cursor: the y just below the last element drawn, so the
    // date and data row flow under the (variable-height) stacked time without
    // ever overlapping it.
    private var _flowY as Number = 0;

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
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        drawBattery(dc, accent);
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

    // Battery: a dynamic icon (fills with charge, reddens when low) plus the
    // percentage text, centered as a group near the top of the face.
    private function drawBattery(dc as Graphics.Dc, accent as Number) as Void {
        var level = System.getSystemStats().battery;
        var pct = (level + 0.5).toNumber();
        if (pct > 100) { pct = 100; }
        var str = pct.format("%d") + "%";
        var font = Graphics.FONT_TINY;
        var color = (level <= 15) ? Theme.LOW : accent;

        var iconW = 28;
        var iconH = 15;
        var gap = 8;
        var tw = dc.getTextWidthInPixels(str, font);
        var totalW = iconW + gap + tw;
        var cy = (_h * 0.13).toNumber();
        var leftX = (_w / 2) - (totalW / 2);

        drawBatteryIcon(dc, leftX, cy - (iconH / 2), iconW, iconH, level, color);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX + iconW + gap, cy, font, str,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawBatteryIcon(dc as Graphics.Dc, x as Number, y as Number,
            w as Number, h as Number, level as Float, color as Number) as Void {
        var nubW = 2;
        var bodyW = w - nubW - 1;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(x, y, bodyW, h);
        // Positive terminal nub on the right.
        dc.fillRectangle(x + bodyW + 1, y + (h / 4), nubW, h / 2);
        // Charge fill.
        var pad = 3;
        var maxFill = bodyW - (pad * 2);
        var fillW = (maxFill * level / 100).toNumber();
        if (fillW < 0) { fillW = 0; }
        if (fillW > maxFill) { fillW = maxFill; }
        if (fillW > 0) {
            dc.fillRectangle(x + pad, y + pad, fillW, h - (pad * 2));
        }
        dc.setPenWidth(1);
    }

    // Big, stylish time on one line (HH:MM, side by side), drawn as hollow
    // outlined numerals (amber outline, black interior).
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

        var font = Graphics.FONT_NUMBER_THAI_HOT;
        var fh = Graphics.getFontHeight(font);
        var cx = _w / 2;
        var cy = (_h * 0.40).toNumber();

        drawOutlinedNumber(dc, cx, cy, font, timeStr, accent);

        var tw = dc.getTextWidthInPixels(timeStr, font);
        var rightX = cx + (tw / 2) + 10;
        if (ampm != null) {
            dc.setColor(Theme.scaled(accent, 4, 5), Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightX, cy - (fh / 4), Graphics.FONT_TINY, ampm,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Cache the seconds slot at the bottom-right of the time block.
        var secFh = Graphics.getFontHeight(Graphics.FONT_SMALL);
        _secX = rightX;
        _secY = cy + (fh / 4) - (secFh / 2);

        // Mark the bottom of the time block for the flowing layout below.
        _flowY = cy + (fh / 2);
    }

    // Draws `str` as a hollow outlined numeral: an amber halo (8 offset passes)
    // with the interior punched out in the background color.
    private function drawOutlinedNumber(dc as Graphics.Dc, x as Number, y as Number,
            font as Graphics.FontType, str as String, accent as Number) as Void {
        var o = 2;
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x - o, y,     font, str, just);
        dc.drawText(x + o, y,     font, str, just);
        dc.drawText(x,     y - o, font, str, just);
        dc.drawText(x,     y + o, font, str, just);
        dc.drawText(x - o, y - o, font, str, just);
        dc.drawText(x + o, y - o, font, str, just);
        dc.drawText(x - o, y + o, font, str, just);
        dc.drawText(x + o, y + o, font, str, just);
        dc.setColor(Theme.BACKGROUND, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, str, just);
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
        var dateFont = Graphics.FONT_XTINY;
        var dim = Theme.scaled(accent, 4, 5);

        // Build the date as colored segments so the month renders in red while
        // the rest stays gold. Each segment is [text, color].
        var segs;
        if (fmt == Settings.DATE_NUMERIC) {
            var s = Gregorian.info(now, Time.FORMAT_SHORT);
            var str = (s.month as Number).format("%02d") + "/" + s.day.format("%02d");
            segs = [[str, dim]];
        } else {
            var m = Gregorian.info(now, Time.FORMAT_MEDIUM);
            var mon = (m.month as String).toUpper();
            var day = m.day.format("%d");
            if (fmt == Settings.DATE_DAY_MONTH) {
                segs = [[day, Theme.HILITE], [" " + mon, dim]];
            } else { // DATE_WEEKDAY -> "SAT 27 JUN" (day in red)
                var wd = (m.day_of_week as String).toUpper();
                segs = [[wd + " ", dim], [day, Theme.HILITE], [" " + mon, dim]];
            }
        }

        // Smaller date tucked right under the time, drawn as a centered group.
        var dh = Graphics.getFontHeight(dateFont);
        var dy = _flowY - 20 + (dh / 2);
        var total = 0;
        for (var i = 0; i < segs.size(); i += 1) {
            total += dc.getTextWidthInPixels(segs[i][0] as String, dateFont);
        }
        var x = (_w / 2) - (total / 2);
        for (var i = 0; i < segs.size(); i += 1) {
            dc.setColor(segs[i][1] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, dy, dateFont, segs[i][0] as String,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            x += dc.getTextWidthInPixels(segs[i][0] as String, dateFont);
        }
        _flowY = dy + (dh / 2);
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

        var rowY = _flowY + 30; // gap between the date and the labels
        var labelFont = Graphics.FONT_XTINY;
        var valueFont = Graphics.FONT_TINY;
        var labelH = Graphics.getFontHeight(labelFont);
        // Dim bronze labels (derived from accent) keep the face monochromatic.
        var labelColor = Theme.scaled(accent, 1, 2);

        for (var i = 0; i < n; i += 1) {
            var fx = (_w * (i + 1)) / (n + 1);
            var label = fields[i][0] as String;
            var value = fields[i][1] as String;

            dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
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
        var v = getBodyBatteryValue();
        return (v != null) ? v.format("%d") : "--";
    }

    // Numeric body battery (0..100) or null when unavailable.
    private function getBodyBatteryValue() as Number? {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var it = SensorHistory.getBodyBatteryHistory({:period => 1});
            if (it != null) {
                var sample = it.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Number);
                }
            }
        }
        return null;
    }
}
