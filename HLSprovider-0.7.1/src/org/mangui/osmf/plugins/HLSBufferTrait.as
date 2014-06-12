package org.mangui.osmf.plugins {
    import org.osmf.traits.BufferTrait;
    import org.mangui.HLS.HLS;
    import org.mangui.HLS.HLSEvent;
    import org.mangui.HLS.HLSPlayStates;
    import org.mangui.HLS.utils.*;

    public class HLSBufferTrait extends BufferTrait {
        private var _hls : HLS;

        public function HLSBufferTrait(hls : HLS) {
            Log.debug("HLSBufferTrait()");
            super();
            _hls = hls;
            _hls.addEventListener(HLSEvent.PLAYBACK_STATE, _stateChangedHandler);
        }

        override public function dispose() : void {
            Log.debug("HLSBufferTrait:dispose");
            _hls.removeEventListener(HLSEvent.PLAYBACK_STATE, _stateChangedHandler);
            super.dispose();
        }

        override public function get bufferLength() : Number {
            return _hls.stream.bufferLength;
        }

        /** state changed handler **/
        private function _stateChangedHandler(event : HLSEvent) : void {
            switch(event.state) {
                case HLSPlayStates.PLAYING_BUFFERING:
                case HLSPlayStates.PAUSED_BUFFERING:
                    Log.debug("HLSBufferTrait:_stateChangedHandler:setBuffering(true)");
                    setBuffering(true);
                    break;
                default:
                    Log.debug("HLSBufferTrait:_stateChangedHandler:setBuffering(false)");
                    setBuffering(false);
                    break;
            }
        }
    }
}
