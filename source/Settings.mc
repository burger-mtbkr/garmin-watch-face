import Toybox.Lang;
import Toybox.Application;

// Reads user settings from Application.Properties into a plain dictionary,
// with safe fallbacks so a missing/invalid property never crashes drawing.
module Settings {

    // Time format values.
    enum {
        TIME_12H = 0,
        TIME_24H = 1,
        TIME_MILITARY = 2
    }

    // Date format values.
    enum {
        DATE_WEEKDAY = 0,
        DATE_DAY_MONTH = 1,
        DATE_NUMERIC = 2
    }

    function readNumber(key as String, def as Number) as Number {
        try {
            var v = Application.Properties.getValue(key);
            if (v instanceof Number) {
                return v;
            }
            if (v instanceof Float) {
                return v.toNumber();
            }
        } catch (e) {
            // fall through to default
        }
        return def;
    }

    function readBoolean(key as String, def as Boolean) as Boolean {
        try {
            var v = Application.Properties.getValue(key);
            if (v instanceof Boolean) {
                return v;
            }
        } catch (e) {
            // fall through to default
        }
        return def;
    }

    function load() as Dictionary {
        return {
            :timeFormat => readNumber("TimeFormat", TIME_24H),
            :showSeconds => readBoolean("ShowSeconds", false),
            :showSteps => readBoolean("ShowSteps", true),
            :showHr => readBoolean("ShowHeartRate", true),
            :showBb => readBoolean("ShowBodyBattery", true),
            :dateFormat => readNumber("DateFormat", DATE_WEEKDAY),
            :accent => readNumber("AccentColor", 0)
        };
    }
}
