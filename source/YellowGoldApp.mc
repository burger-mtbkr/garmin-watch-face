import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point for the Yellow Gold watch face.
class YellowGoldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial watch-face view.
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [ new YellowGoldView() ];
    }

    // Called when the user changes a setting in Garmin Connect or on-device.
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
