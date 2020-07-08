using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Timer as Timer;
using Toybox.Application as App;
using Toybox.System as Sys;

class iKitesurfDelegate extends Ui.BehaviorDelegate {
    var parentView;
    var timer;
    var spotList = "";    
    
    var requestIntervalShort = 59; // Once per minute
    var requestIntervalMedium = 299; // Every 5 minutes
    var requestIntervalLong = 899; // Every 15 minutes
    
    var secondsOfUserInactivityToTriggerMediumRequestInterval = 3600;
    var secondsOfUserInactivityToTriggerLongRequestInterval = 7200;
    
    var requestIntervalCurrent = requestIntervalShort; // Get new wind data every X seconds
    
    var lastRequestTime;
    var lastLastUserInteractionTime;
    
    var validDataHasBeenReceived = false;
    
        // Set up the callback to the view
    function initialize(view) {
        Ui.BehaviorDelegate.initialize();
        parentView = view;
        
        lastLastUserInteractionTime = Sys.getTimer();
        
        // Manually set username and password from config file when testing on the simulator

        if(App.getApp().getProperty("username").length()==0 && testUsername.length()>0) {
        	App.getApp().setProperty("username",testUsername);
        }
        if(App.getApp().getProperty("password").length()==0 && testPassword.length()>0) {
        	App.getApp().setProperty("password",testPassword);
        } 
 		
 		//System.println("Auth successful: "+App.getApp().getProperty("authSuccessful").toString());
 		System.println("wf_token: "+App.getApp().getProperty("apiToken"));
 		if(App.getApp().getProperty("username").length()>0 && App.getApp().getProperty("password").length()>0) {
 			if(App.getApp().getProperty("authSuccessful")==true&&App.getApp().getProperty("apiToken").length()>0) {
 				System.println("Requesting profile, since authSuccessful flag == true and wf_token is available");
 				makeRequestForProfile();
 			} else {
 				System.println("test: " + App.getApp().getProperty("apiToken"));
 				if(App.getApp().getProperty("apiToken")!=null && App.getApp().getProperty("apiToken").length()>0) {
 					System.println("apiToken exists, but authSuccessful=="+App.getApp().getProperty("authSuccessful").toString());
 					makeRequestForAuthUser();
 				} else {
 					System.println("No apiToken stored, requesting token.");
 					makeRequestForGetToken();
 				}
 				
 			}
 			
 			// Set up timer for updating the clock once a minute and firing off requests to uddate wind data
 			timer = new Timer.Timer();
 			timer.start(method(:timerFired), 60000, true);
 		} else {
 			parentView.renderUiWithData("Please enter your iKitesurf\naccount info in \nGarmin Connect App");
 		}
 		
 		
        
    }

    // Handle menu button press
    function onMenu() {
    	System.println("On Menu");
        //makeRequestForSpotList();
        return true;
    }

    function onSelect() {
    	System.println("On Select");
    	userInteractionHappened();
    	parentView.renderUiWithData("Loading data");
    	makeRequestForSpotList();
        return true;
    }
    
    
    function onNextPage() {
    	System.println("onNextPage");
    	userInteractionHappened();
    	parentView.onNextPage();
 
        return true;
    }
    
    function onPreviousPage() {
    	System.println("onPreviousPage");
    	userInteractionHappened();
    	parentView.onPreviousPage();
 
        return true;
    }
    
    function userInteractionHappened() {
    	lastLastUserInteractionTime = Sys.getTimer();
    }
    
    function timerFired() {
    	System.println("In timerFired");
    	
    	// Adjust request interval dynamically depending on last user interaction with select button
    	if(secondsSince(lastLastUserInteractionTime)>secondsOfUserInactivityToTriggerLongRequestInterval) { // No user action for 2 hours
    		System.println("Switching to long polling interval");
    		requestIntervalCurrent = requestIntervalLong;
    	} else if(secondsSince(lastLastUserInteractionTime)>secondsOfUserInactivityToTriggerMediumRequestInterval) { // No user action for an hour
    		System.println("Switching to medium polling interval");
    		requestIntervalCurrent = requestIntervalMedium;
    	} else {
    		System.println("Switching to short polling interval");
    		requestIntervalCurrent = requestIntervalShort;
    	}
    	
    	if(spotList.length()>0) {
    		// If spotList doesn't exist don't do anything since we want the "You don't have any favorites" message to stay on the display
    		if(lastRequestTime == null || (secondsSince(lastRequestTime)>requestIntervalCurrent)) {
    			makeRequestForSpotList();
    		} else {
    			System.println("Not making a request since last request was: "+(Sys.getTimer()-lastRequestTime).toString()+" and request interval is "+requestIntervalCurrent.toString());
    			parentView.renderUiWithData(null);
    		}
    	}
 
    }

    function makeRequestForSpotList() {
    	lastRequestTime = Sys.getTimer();
    	
    	System.println("Executing request for spots");
    	
    	if(!validDataHasBeenReceived) {
    		// Only show requesting wind data message initially, we don't want it to show up on periodic polling
    		parentView.renderUiWithData("Requesting wind data");
    	}
        
        var apiToken = App.getApp().getProperty("apiToken");
        var url = "https://api.weatherflow.com/wxengine/rest/spot/getSpotSetByList?format=json&v=1.3&wf_apikey="+apiKey+"&wf_token="+apiToken+"&uid=356696656686243&profile_id=278808&spot_list="+spotList+"&page=1&units_wind=kts&units_temp=C&units_distance=km&device_id=356696656686243&device_type=Android&device_os=6.0.1&wa_ver=2.5&activity=Kite&spot_types=1,100,101&";
		System.println("URL: " + url);
        Comm.makeWebRequest(
           url,
            {
                
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceiveSpotList)
        );
    }
    
    function makeRequestForProfile() {
    	System.println("Executing request for profile");
    	parentView.renderUiWithData("Getting favorite spots");
        
        var apiToken = App.getApp().getProperty("apiToken");
        var profileId = App.getApp().getProperty("profileId");
        var url = "https://api.weatherflow.com/wxengine/rest/profile/getProfiles?profile_id="+profileId+"&format=json&wf_apikey="+apiKey+"&v=1.3&wf_token="+apiToken+"&";
		System.println("URL: " + url);
        Comm.makeWebRequest(
           url,
            {
                
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceiveProfileResponse)
        );
    }
    
    function makeRequestForAuthUser() {
    	System.println("Authenticating User");
        parentView.renderUiWithData("Authenticating User");
                
        var username = Application.getApp().getProperty("username");
        var password = Application.getApp().getProperty("password");
        var apiToken = App.getApp().getProperty("apiToken");
        
        var url = "https://api.weatherflow.com/wxengine/rest/session/authUser?format=json&v=1.3&wf_apikey="+apiKey+"&wf_token="+apiToken+"&uid=356696656686243&wf_user="+username+"&wf_pass="+password+"&";
		System.println("URL: " + url);
        Comm.makeWebRequest(
           url,
            {
                
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceiveAuthUser)
        );
    }    
    
    function makeRequestForGetToken() {
    	System.println("Requesting new token");
        parentView.renderUiWithData("Requesting new token");
        
        var url = "https://api.weatherflow.com/wxengine/rest/session/getToken?format=json&v=1.3&wf_apikey="+apiKey+"&";
		System.println("URL: " + url);
        Comm.makeWebRequest(
           url,
            {
                
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceiveGetToken)
        );
    }  

    // Receive the data from the web request
    function onReceiveSpotList(responseCode, data) {
    	if(responseCode == 200) {
    		//System.println("Received spotlist data: " + data);
    		if(data["status"]["status_code"]==0) {
    			// Success
    			validDataHasBeenReceived = true;
    			parentView.renderUiWithData(data);
    		} else if(data["status"]["status_code"]==2) {
    			// Invalid token
    			//parentView.renderUiWithData("API auth failed");
    			App.getApp().getProperty("authSuccessful",false);
    			parentView.renderUiWithData("Authentication issue when getting spotlist, trying to re-authenticate.");
    			makeRequestForAuthUser();
    		}
    		
    	} else {
    		//parentView.renderUiWithData("Failed to load\nError: " + responseCode.toString());
    		parentView.renderUiWithData("Unable to load data.\nInternet connection required.");
    	}
        
    }
    
        // Receive the data from the web request
    function onReceiveAuthUser(responseCode, data) {
    	if(responseCode == 200) {
    		System.println("Response: "+data);
    		if(data["status"]["status_code"]==0) {
    			// Successfully received token
    			parentView.renderUiWithData("Success");
    			
    			var profileId = data["wf_user"]["active_profile_id"];
    			App.getApp().setProperty("profileId",profileId);
    			System.println("Received profileId: "+profileId);   
    			
    			var memberLevelName = data["wf_user"]["member_level_name"];		
    			if(memberLevelName.equals("Pro")||memberLevelName.equals("Plus")||memberLevelName.equals("Enterprise")) {
    				App.getApp().setProperty("authSuccessful",true);
    				makeRequestForProfile();
    			} else {
    				App.getApp().setProperty("authSuccessful",false);
    				parentView.renderUiWithData("iKitesurf Pro or Plus account required.\nYour account type is: "+memberLevelName);
    			}
    			
    			
    		} else if(data["status"]["status_code"]==5) {
    			// Invalid username or password
    			parentView.renderUiWithData("Wrong username/password\nEnter correct credentials in\nGarmin Connect App!");
    		} else {
    			parentView.renderUiWithData(data["status"]["status_message"]);
    		}
    		
    	} else {
    		//parentView.renderUiWithData("Failed to load\nError: " + responseCode.toString());
    		parentView.renderUiWithData("Unable to load data.\nInternet connection required.");
    	}
        
    }
    
    function onReceiveGetToken(responseCode, data) {
    	if(responseCode == 200) {
    		//System.println("Response: "+data);
    		if(data["status"]["status_code"]==0) {
    			// Successfully received token
    			parentView.renderUiWithData("Success");
 
    			var apiToken = data["wf_token"];
    			App.getApp().setProperty("apiToken",apiToken);
    			System.println("Received new token: "+apiToken);		
    			
    			makeRequestForAuthUser();
    		} else {
    			parentView.renderUiWithData(data["status"]["status_message"]);
    		}
    		
    	} else {
    		//parentView.renderUiWithData("Failed to load\nError: " + responseCode.toString());
    		parentView.renderUiWithData("Unable to load data.\nInternet connection required.");
    	}
        
    }
    
    function onReceiveProfileResponse(responseCode, data) {
    	if(responseCode == 200) {
    		if(data["status"]["status_code"]==0) {
    			// Successfully received token
    			parentView.renderUiWithData("Success");
 
    			var favoritesArr = data["profiles"][0]["favorite_spots"];
    			System.println("favorites arr: "+favoritesArr);
    			
    			System.println("Number of favorites: "+favoritesArr.size());
    			
    			if(favoritesArr.size()>0) {
    				spotList = "";
    				for(var i=0;i<favoritesArr.size();i+=1) {
    					var currSpotId = favoritesArr[i]["spot_id"];
    					spotList = spotList+currSpotId+",";
    				}
    			
    				System.println("Final spot list: "+spotList);
    			
    				// Now that we have the list of favorite spots, request the wind data for those
    				makeRequestForSpotList();
    			} else {
    				parentView.renderUiWithData("You need to set up favorite\nspots in your\niKitesurf account.");
    			}
    			
    			
    		} else if(data["status"]["status_code"]==2) {
    			// Invalid token
    			//parentView.renderUiWithData("API auth failed");
    			App.getApp().getProperty("authSuccessful",false);
    			parentView.renderUiWithData("Requesting new token");
    			makeRequestForAuthUser();
    		}
    		
    	} else {
    		//parentView.renderUiWithData("Failed to load\nError: " + responseCode.toString());
    		parentView.renderUiWithData("Unable to load data.\nInternet connection required.");
    	}
        
    }
    
    // Utils
    
    function secondsSince(time) {
    	return (Sys.getTimer()-time)/1000;
    }
}