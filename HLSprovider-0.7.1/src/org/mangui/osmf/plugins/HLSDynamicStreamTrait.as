package org.mangui.osmf.plugins {
    import org.osmf.traits.DynamicStreamTrait;
    import org.osmf.utils.OSMFStrings;
    import org.mangui.HLS.HLS;
    import org.mangui.HLS.HLSEvent;
    import org.mangui.HLS.utils.*;

    public class HLSDynamicStreamTrait extends DynamicStreamTrait {
        private var _hls : HLS;

        public function HLSDynamicStreamTrait(hls : HLS) {
            Log.debug("HLSDynamicStreamTrait()");
            _hls = hls;
            _hls.addEventListener(HLSEvent.QUALITY_SWITCH, _qualitySwitchHandler);
            super(true, 0, hls.levels.length);
        }

        override public function dispose() : void {
            Log.debug("HLSDynamicStreamTrait:dispose");
            _hls.removeEventListener(HLSEvent.QUALITY_SWITCH, _qualitySwitchHandler);
            super.dispose();
        }

        override public function getBitrateForIndex(index : int) : Number {
            if (index > numDynamicStreams - 1 || index < 0) {
                throw new RangeError(OSMFStrings.getString(OSMFStrings.STREAMSWITCH_INVALID_INDEX));
            }
            var bitrate : Number = _hls.levels[index].bitrate / 1024;
            Log.debug("HLSDynamicStreamTrait:getBitrateForIndex(" + index + ")=" + bitrate);
            return bitrate;
        }

        override public function switchTo(index : int) : void {
            Log.debug("HLSDynamicStreamTrait:switchTo(" + index + ")/max:" + maxAllowedIndex);
            if (index < 0 || index > maxAllowedIndex) {
                throw new RangeError(OSMFStrings.getString(OSMFStrings.STREAMSWITCH_INVALID_INDEX));
            }
            autoSwitch = false;
            if (!switching) {
                setSwitching(true, index);
            }
        }

        override protected function autoSwitchChangeStart(value : Boolean) : void {
            Log.debug("HLSDynamicStreamTrait:autoSwitchChangeStart:" + value);
            if (value == true && _hls.autolevel == false) {
                _hls.level = -1;
                // only seek if position is set
                if (!isNaN(_hls.position)) {
                    _hls.stream.seek(_hls.position);
                }
            }
        }

        override protected function switchingChangeStart(newSwitching : Boolean, index : int) : void {
            Log.debug("HLSDynamicStreamTrait:switchingChangeStart(newSwitching/index):" + newSwitching + "/" + index);
            if (newSwitching) {
                _hls.level = index;
            }
        }

        /** Update playback position/duration **/
        private function _qualitySwitchHandler(event : HLSEvent) : void {
            var newLevel : Number = event.level;
            Log.debug("HLSDynamicStreamTrait:_qualitySwitchHandler:" + newLevel);
            setCurrentIndex(newLevel);
            setSwitching(false, newLevel);
        };
    }
}