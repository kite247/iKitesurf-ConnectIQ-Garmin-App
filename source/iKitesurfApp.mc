using Toybox.Application as App;

class iKitesurfApp extends App.AppBase {
    hidden var mView;

    function initialize() {
        App.AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        mView = new iKitesurfView();
        return [mView, new iKitesurfDelegate(mView)];
    }
    
    // Settings were changed by user
    function onSettingsChanged() {
    	System.println("Settings changed");
    	// Invalidate the API token so App has to reauthenticate with possibly new username/password
    	App.getApp().setProperty("apiToken","");
    }
}