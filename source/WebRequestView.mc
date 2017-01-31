//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class WebRequestView extends Ui.View {
    hidden var mMessage = "Press menu button";
    
    hidden var spaceFromTop = 5;
    hidden var currentSpot = 0; // Array index of current spot that is displayed
    hidden var mResponseData;
    

    function initialize() {
        Ui.View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
   
    
    function onNextPage() {
    	currentSpot = currentSpot+1;
    	System.println("spot amount:"+mResponseData["data_values"].size());
    	
    	if(currentSpot>(mResponseData["data_values"].size()-1)) {
    		currentSpot = 0;
    	}
    	
    	Ui.requestUpdate();

    }
    
    function onPreviousPage() {
    	currentSpot = currentSpot-1;
    	
    	if(currentSpot<0) {
    		currentSpot = mResponseData["data_values"].size()-1;
    	}
 
        Ui.requestUpdate();
    }

    // Update the view
    function onUpdate(dc) {
    
    	var mCurrentWind = null;
	    var mLullWind = null;
	    var mGustWind = null;
	    var mUnitWind = null;
	    var mUnitTemp = null;
	    var mSpotName = null;
	    var mCurrentWindDirection = null;
	    var mTimestamp = null;
	    var mLastUpdateTime = null;
	    var mAirTemp = null;
	    var mWaterTemp = null;
	    var mStatusMessage = null;
    
    	if(mMessage == null && mResponseData["status"]["status_code"]==0) {
    	
    		if(mResponseData["data_values"][currentSpot][19]) {
    			mCurrentWind = mResponseData["data_values"][currentSpot][19].toNumber();
    		} else {
    			System.println("Warning: Wind speed not available");
    			mCurrentWind = "--";
    		}
        	
        	mCurrentWindDirection = mResponseData["data_values"][currentSpot][23];
        	mUnitWind = mResponseData["units_wind"];
        	mUnitTemp = mResponseData["units_temp"];
        	if(mResponseData["data_values"][currentSpot][20]) {
        		mLullWind = mResponseData["data_values"][currentSpot][20].toNumber();
        	} else {
        		System.println("Warning: Lull not available");
        		mLullWind = "n/a";
        	}
        	
        	if(mResponseData["data_values"][currentSpot][21]) {
        		mGustWind = mResponseData["data_values"][currentSpot][21].toNumber();
        	} else {
        		System.println("Warning: Lull not available");
        		mGustWind = "n/a";
        	}
        	
        	mSpotName = mResponseData["data_values"][currentSpot][1];
        	mTimestamp = mResponseData["data_values"][currentSpot][18];
        	if(mTimestamp!=null && (mTimestamp.length()>17)) {
        		mLastUpdateTime = mTimestamp.substring(11,16);
        	}
        	System.println("Last update time: "+mLastUpdateTime);
        	
        	if(mResponseData["data_values"][currentSpot][24]) {
        		mAirTemp = mResponseData["data_values"][currentSpot][24].toNumber();
        	} else {
        		System.println("Warning: Air temp not available");
        		mAirTemp = null;
        	}
        	
        	if(mResponseData["data_values"][currentSpot][25]) {
        		mWaterTemp = mResponseData["data_values"][currentSpot][25].toNumber();
        	} else {
        		System.println("Warning: Water temp not available");
        		mWaterTemp = null;
        	}
        	
        	mStatusMessage = mResponseData["data_values"][currentSpot][15];
        	
        	mMessage = null;
      	} else if(mMessage==null) {
		    mMessage = "Error:"+mResponseData["status"]["status_message"];      
		}
		
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if(mMessage) {
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_TINY, mMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
        	// Current Wind
            dc.drawText(dc.getWidth()/2, 41+spaceFromTop, Graphics.FONT_NUMBER_THAI_HOT, mCurrentWind, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        	
        	
        	// Unit
        	dc.drawText(dc.getWidth()/2+35, 76+spaceFromTop, Graphics.FONT_TINY, mUnitWind + " " + mCurrentWindDirection, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        	// Spot name
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2-5+spaceFromTop, Graphics.FONT_SMALL, mSpotName, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        	
        	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        	// Gust Lull
        	if(!(mLullWind.equals("n/a")&&mGustWind.equals("n/a"))) {
        		// Only show gust and lull if at least one of the values is available
        		dc.drawText(dc.getWidth()/2+35, 56+spaceFromTop, Graphics.FONT_TINY, mLullWind + "-" + mGustWind, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        	}
        	
        	// Next 3 fields are drawn from bottom to top, if a field is not available the next one will be shown in it's place.
        	var yPosition = 76;
        	
        	// Air Temp
        	if(mAirTemp) {
        		var airString = "A: " + mAirTemp + "°" + mUnitTemp;
        		dc.drawText(73, yPosition+spaceFromTop, Graphics.FONT_TINY, airString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        		yPosition = yPosition - 20;
        	}
        	
        	// Water Temp
        	if(mWaterTemp) {
        		var waterString = "W: " + mWaterTemp + "°" + mUnitTemp;
        		dc.drawText(73, yPosition+spaceFromTop, Graphics.FONT_TINY, waterString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        		yPosition = yPosition - 20;
        	}
        	
        	// Last update timestamp
        	dc.drawText(73, yPosition+spaceFromTop, Graphics.FONT_TINY, mLastUpdateTime, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        	
        	
        	
        	

        	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        	
        	var lineYpos = dc.getHeight()/2+20;
        	
        	if(mStatusMessage) {
        		// If there's a status message, show it instead of the divider line
        		dc.drawText(dc.getWidth()/2, lineYpos, Graphics.FONT_SYSTEM_XTINY, mStatusMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        	} else {
        		dc.drawLine(0,lineYpos,dc.getWidth(),lineYpos);
        	}
        	
        	
        	var clockTime = Sys.getClockTime();
        	// Current time
        	var timeText = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");
        	dc.drawText(dc.getWidth()/2, lineYpos + 52, Graphics.FONT_NUMBER_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        	
        	// Current date
        	var now = Time.now();
        	var info = Calendar.info(now, Time.FORMAT_LONG);
        	var dateText = Lang.format("$1$, $2$ $3$", [info.day_of_week, info.month, info.day]).toUpper();
        	dc.drawText(dc.getWidth()/2, lineYpos + 17, Graphics.FONT_TINY, dateText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        
    }

    // Called when this View is removed from the screen. Save the
    // state of your app here.
    function onHide() {
    }

	// Called from delegate whenever screen should be rendered
	// If data == null, just render the screen again (e.g. time updated)
	// If data == string, show the string message
	// If data == dictionary, render the data from the dictionary
    function renderUiWithData(data) {
        if (data instanceof Lang.String) {
            mMessage = data;
            System.println("Showing message: "+mMessage);
        }
        else if (data instanceof Dictionary) {
        
            mResponseData = data;
            mMessage = null;
    
        }
        Ui.requestUpdate();
    }
}
