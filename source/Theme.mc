import Toybox.Lang;
import Toybox.Graphics;

// Color theme: solid black background with a configurable bright accent.
// Default accent is a yellow-gold tuned to match the watch strap.
module Theme {

    const BACKGROUND = Graphics.COLOR_BLACK;

    // Dim tone used for small field labels so values stay the focus.
    const LABEL = 0x555555;

    // Accent palette, indexed by the AccentColor property (0 = yellow-gold).
    const ACCENTS = [
        0xFFCC00, // 0 yellow-gold
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
