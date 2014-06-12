package org.mangui.HLS.utils {
    import org.mangui.HLS.HLSSettings;

    import flash.utils.getQualifiedClassName;
    import flash.utils.getDefinitionByName;
    import flash.utils.Dictionary;

    /**
     * Params2Settings is an helper class that holds every legal external params names 
     * which can be used to customize HLSSettings and maps them to the relevant HLSSettings values
     */
    public class Params2Settings {
        /**
         * HLSSettings <-> params maping
         */
        private static var _paramMap : Dictionary = new Dictionary();
        _paramMap["minbufferlength"] = "minBufferLength";
        _paramMap["maxbufferlength"] = "maxBufferLength";
        _paramMap["lowbufferlength"] = "lowBufferLength";
        _paramMap["seekmode"] = "seekMode";
        _paramMap["startfromlevel"] = "startFromLevel";
        _paramMap["seekfromlevel"] = "seekFromLevel";
        _paramMap["live_flushurlcache"] = "flushLiveURLCache";
        _paramMap["manifestloadmaxretry"] = "manifestLoadMaxRetry";
        _paramMap["segmentloadmaxretry"] = "segmentLoadMaxRetry";
        _paramMap["capleveltostage"] = "capLeveltoStage";
        _paramMap["info"] = "logInfo";
        _paramMap["debug"] = "logDebug";
        _paramMap["debug2"] = "logDebug2";
        _paramMap["warn"] = "logWarn";
        _paramMap["error"] = "logError";
        public static function set(key : String, value : Object) : void {
            var param : String = _paramMap[key];
            if (param) {
                // try to assign value with proper object type
                try {
                    var c : Class = getDefinitionByName(getQualifiedClassName(HLSSettings[param])) as Class;
                    // get HLSSetting type
                    HLSSettings[param] = c(value);
                    Log.info("HLSSettings." + param + " = " + HLSSettings[param]);
                } catch(error : Error) {
                    Log.warn("Can't set HLSSettings." + param);
                }
            }
        }
    }
}