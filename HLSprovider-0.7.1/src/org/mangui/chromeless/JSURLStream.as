package org.mangui.chromeless {
    import flash.events.IOErrorEvent;

    import by.blooddy.crypto.Base64;

    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.external.ExternalInterface;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.utils.ByteArray;
    import flash.net.URLStream;

    import org.mangui.HLS.utils.Log;

    import flash.net.URLRequest;

    public class JSURLStream extends URLStream {
        private var _connected : Boolean;
        private var _resource : ByteArray = new ByteArray();
        /** Timer for decode packets **/
        private var _timer : Timer;
        /** read position **/
        private var _read_position : Number;
        /** read position **/
        private var _base64_resource : String;
        /** chunk size to avoid blocking **/
        private static const CHUNK_SIZE : uint = 65536;
        private static var _instance_count : Number = 0;
        private var _id : Number;

        public function JSURLStream() {
            addEventListener(Event.OPEN, onOpen);
            super();
            // Connect calls to JS.
            if (ExternalInterface.available) {
                _id = _instance_count;
                _instance_count++;
                Log.info("add callback resourceLoaded");
                ExternalInterface.addCallback("resourceLoaded" + _id, resourceLoaded);
                ExternalInterface.addCallback("resourceLoadingError" + _id, resourceLoadingError);
            }
        }

        override public function get connected() : Boolean {
            return _connected;
        }

        override public function get bytesAvailable() : uint {
            return _resource.bytesAvailable;
        }

        override public function readByte() : int {
            return _resource.readByte();
        }

        override public function readUnsignedShort() : uint {
            return _resource.readUnsignedShort();
        }

        override public function readBytes(bytes : ByteArray, offset : uint = 0, length : uint = 0) : void {
            _resource.readBytes(bytes, offset, length);
        }

        override public function close() : void {
        }

        override public function load(request : URLRequest) : void {
            Log.info("JSURLStream.load:" + request.url);
            if (ExternalInterface.available) {
                ExternalInterface.call("onRequestResource" + _id, request.url);
                this.dispatchEvent(new Event(Event.OPEN));
            } else {
                super.load(request);
            }
        }

        private function onOpen(event : Event) : void {
            _connected = true;
        }

        protected function resourceLoaded(base64Resource : String) : void {
            Log.info("resourceLoaded");
            _resource = new ByteArray();
            _read_position = 0;
            _timer = new Timer(0, 0);
            _timer.addEventListener(TimerEvent.TIMER, _decodeData);
            _timer.start();
            _base64_resource = base64Resource;
        }

        protected function resourceLoadingError() : void {
            Log.info("resourceLoadingError");
            this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
        }

        /** decrypt a small chunk of packets each time to avoid blocking **/
        private function _decodeData(e : Event) : void {
            var start_pos : Number = _read_position;
            var end_pos : Number;
            var decode_completed : Boolean;
            if (_base64_resource.length <= _read_position + CHUNK_SIZE) {
                end_pos = _base64_resource.length;
                decode_completed = true;
            } else {
                end_pos = _read_position + CHUNK_SIZE;
            }
            var tmpString : String = _base64_resource.substring(start_pos, end_pos);
            _resource.writeBytes(Base64.decode(tmpString));
            if (decode_completed) {
                _timer.stop();
                Log.info("resourceLoaded and decoded");
                _resource.position = 0;
                this.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _resource.bytesAvailable, _resource.bytesAvailable));
                this.dispatchEvent(new Event(Event.COMPLETE));
            } else {
                _read_position = end_pos;
            }
        }
    }
}
