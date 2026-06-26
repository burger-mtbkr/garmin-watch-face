import Toybox.Lang;
import Toybox.Graphics;

// Color theme: solid black background with a configurable bright accent.
// Default accent is a yellow-gold tuned to match the watch strap.
module Theme {

    const BACKGROUND = Graphics.COLOR_BLACK;

    // Low-battery warning tint (only used when charge drops to <= 15%).
    const LOW = 0xFF3344;

    // Red highlight used for the day number in the date.
    const HILITE = 0xFF3333;

    // Scales a packed RGB color's brightness by num/den (per channel).
    // Used to derive a tonal hierarchy (dim date, bronze labels, faint ring
    // tracks) from a single accent color so the whole face stays monochromatic.
    function scaled(color as Number, num as Number, den as Number) as Number {
        var r = (((color >> 16) & 0xFF) * num) / den;
        var g = (((color >> 8) & 0xFF) * num) / den;
        var b = ((color & 0xFF) * num) / den;
        return (r << 16) | (g << 8) | b;
    }

    // Accent palette, indexed by the AccentColor property (0 = yellow-gold).
    const ACCENTS = [
        0xF2941A, // 0 amber-gold (matches the Spark Orange strap)
        0xFFFFFF, // 1 white
        0xFF3333, // 2 red
        0xFF8800, // 3 orange
        0x00E5FF, // 4 cyan
        0x33FF66  // 5 green
    ] as Array<Number>;

    function accentColor(index as Number) as Number {
        if (index < 0 || index >= ACCENTS.size()) {
            return ACCENTS[0];
        }
        return ACCENTS[index];
    }
}
