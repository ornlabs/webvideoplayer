package org.mangui.HLS {
    /** Identifiers for the different playback states. **/
    public class HLSPlayStates {
        /** idle state. **/
        public static const IDLE : String = "IDLE";
        /** playing state. **/
        public static const PLAYING : String = "PLAYING";
        /** paused state. **/
        public static const PAUSED : String = "PAUSED";
        /** playing/buffering state (playback is paused and will restart automatically as soon as buffer will contain enough data) **/
        public static const PLAYING_BUFFERING : String = "PLAYING_BUFFERING";
        /** paused/buffering state (playback is paused, and buffer is in low condition) **/
        public static const PAUSED_BUFFERING : String = "PAUSED_BUFFERING";
    }
}