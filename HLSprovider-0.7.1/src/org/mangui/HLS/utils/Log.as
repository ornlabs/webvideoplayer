package org.mangui.HLS.utils {
    import flash.external.ExternalInterface;
    
    import org.mangui.HLS.HLSSettings;

    /** Class that sends log messages to browser console. **/
    public class Log {
        private static const LEVEL_INFO : String = "INFO:";
        private static const LEVEL_DEBUG : String = "DEBUG:";
        private static const LEVEL_WARN : String = "WARN:";
        private static const LEVEL_ERROR : String = "ERROR:";

        public static function info(message : *) : void {
            if (HLSSettings.logInfo)
                outputlog(LEVEL_INFO, String(message));
        };

        public static function debug(message : *) : void {
            if (HLSSettings.logDebug)
                outputlog(LEVEL_DEBUG, String(message));
        };

        public static function debug2(message : *) : void {
            if (HLSSettings.logDebug2)
                outputlog(LEVEL_DEBUG, String(message));
        };

        public static function warn(message : *) : void {
            if (HLSSettings.logWarn)
                outputlog(LEVEL_WARN, String(message));
        };

        public static function error(message : *) : void {
            if (HLSSettings.logError)
                outputlog(LEVEL_ERROR, String(message));
        };

        /** Log a message to the console. **/
        private static function outputlog(level : String, message : String) : void {
            if (ExternalInterface.available)
                ExternalInterface.call('console.log', level + message);
            else trace(level + message);
        }
    };
}