using Toybox.Application as App;

class iKitesurfApp extends App.AppBase {
    hidden var mView;

    function initialize() {
        App.AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        mView = new iKitesurfView();
        return [mView, new iKitesurfDelegate(mView)];
    }
    
    function onSettingsChanged() {
    	System.println("Settings changed");
    	// Invalidate the API token so App has to reauthenticate with possibly new username/password
    	App.getApp().setProperty("apiToken","");
    }
}