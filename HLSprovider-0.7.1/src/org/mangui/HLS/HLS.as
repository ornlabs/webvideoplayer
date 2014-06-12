package org.mangui.HLS {
    import flash.display.Stage;

    import org.mangui.HLS.parsing.AltAudioTrack;

    import flash.net.URLStream;

    import org.mangui.HLS.parsing.Level;
    import org.mangui.HLS.streaming.*;
    import org.mangui.HLS.utils.*;

    import flash.events.*;
    import flash.net.NetStream;
    import flash.net.NetConnection;

    /** Class that manages the streaming process. **/
    public class HLS extends EventDispatcher {
        /** The quality monitor. **/
        private var _fragmentLoader : FragmentLoader;
        /** The manifest parser. **/
        private var _manifestLoader : ManifestLoader;
        /** HLS NetStream **/
        private var _hlsNetStream : HLSNetStream;
        /** HLS URLStream **/
        private var _hlsURLStream : Class;
        private var _client : Object = {};
        private var _stage : Stage;

        /** Create and connect all components. **/
        public function HLS() {
            var connection : NetConnection = new NetConnection();
            connection.connect(null);
            _manifestLoader = new ManifestLoader(this);
            _hlsURLStream = URLStream as Class;
            // default loader
            _fragmentLoader = new FragmentLoader(this);
            _hlsNetStream = new HLSNetStream(connection, this, _fragmentLoader);
        };

        /** Forward internal errors. **/
        override public function dispatchEvent(event : Event) : Boolean {
            if (event.type == HLSEvent.ERROR) {
                Log.error((event as HLSEvent).error);
                _hlsNetStream.close();
            }
            return super.dispatchEvent(event);
        };

        public function dispose() : void {
            _fragmentLoader.dispose();
            _manifestLoader.dispose();
            _hlsNetStream.dispose_();
            _fragmentLoader = null;
            _manifestLoader = null;
            _hlsNetStream = null;
            _client = null;
            _stage = null;
            _hlsNetStream = null;
        }

        /** Return the playback quality start level **/
        public function get startlevel() : Number {
            return _manifestLoader.startlevel;
        };

        /** Return the playback quality seek level **/
        public function get seeklevel() : Number {
            return _manifestLoader.seeklevel;
        };

        /** Return the playback quality level of last loaded fragment **/
        public function get level() : Number {
            return _fragmentLoader.level;
        };

        /*  set playback quality level (-1 for automatic level selection) */
        public function set level(level : Number) : void {
            _fragmentLoader.level = level;
        };

        /* check if we are in autolevel mode */
        public function get autolevel() : Boolean {
            return _fragmentLoader.autolevel;
        };

        /** Return bitrate level lists. **/
        public function get levels() : Vector.<Level> {
            return _manifestLoader.levels;
        };

        /** Return metrics info **/
        public function get metrics() : HLSMetrics {
            return _fragmentLoader.metrics;
        };

        /** Return the current playback position. **/
        public function get position() : Number {
            return _hlsNetStream.position;
        };

        /** Return the current playback state. **/
        public function get playbackState() : String {
            return _hlsNetStream.playbackState;
        };

        /** Return the current seek state. **/
        public function get seekState() : String {
            return _hlsNetStream.seekState;
        };

        /** Return the type of stream (VOD/LIVE). **/
        public function get type() : String {
            return _manifestLoader.type;
        };

        /** Load and parse a new HLS URL **/
        public function load(url : String) : void {
            _hlsNetStream.close();
            _manifestLoader.load(url);
        };

        /** return HLS NetStream **/
        public function get stream() : NetStream {
            return _hlsNetStream;
        }

        public function get client() : Object {
            return _client;
        }

        public function set client(value : Object) : void {
            _client = value;
        }

        /** get current Buffer Length  **/
        public function get bufferLength() : Number {
            return _hlsNetStream.bufferLength;
        };

        /** get audio tracks list**/
        public function get audioTracks() : Vector.<HLSAudioTrack> {
            return _fragmentLoader.audioTracks;
        };

        /** get alternate audio tracks list from playlist **/
        public function get altAudioTracks() : Vector.<AltAudioTrack> {
            return _fragmentLoader.altAudioTracks;
        };

        /** get index of the selected audio track (index in audio track lists) **/
        public function get audioTrack() : Number {
            return _fragmentLoader.audioTrack;
        };

        /** select an audio track, based on its index in audio track lists**/
        public function set audioTrack(val : Number) : void {
            _fragmentLoader.audioTrack = val;
        }

        /* set stage */
        public function set stage(stage : Stage) : void {
            _stage = stage;
        }

        /* get stage */
        public function get stage() : Stage {
            return _stage;
        }

        /* set URL stream loader */
        public function set URLstream(urlstream : Class) : void {
            _hlsURLStream = urlstream;
        }

        /* retrieve URL stream loader */
        public function get URLstream() : Class {
            return _hlsURLStream;
        }
    }
    ;
}