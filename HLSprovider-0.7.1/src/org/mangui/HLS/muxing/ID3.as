package org.mangui.HLS.muxing {
    import org.mangui.HLS.HLSSettings;
    import flash.utils.ByteArray;

    import org.mangui.HLS.utils.Log;

    public class ID3 {
        public var len : Number;
        public var hasTimestamp : Boolean = false;
        public var timestamp : Number;

        /* create ID3 object by parsing ByteArray, looking for ID3 tag length, and timestamp */
        public function ID3(data : ByteArray) {
            var tagSize : uint = 0;
            try {
                var pos : Number = data.position;
                var header : String;
                do {
                    header = data.readUTFBytes(3);
                    if (header == 'ID3') {
                        // skip 24 bits
                        data.position += 3;
                        // retrieve tag length
                        var byte1 : uint = data.readUnsignedByte() & 0x7f;
                        var byte2 : uint = data.readUnsignedByte() & 0x7f;
                        var byte3 : uint = data.readUnsignedByte() & 0x7f;
                        var byte4 : uint = data.readUnsignedByte() & 0x7f;
                        tagSize = (byte1 << 21) + (byte2 << 14) + (byte3 << 7) + byte4;
                        var end_pos : Number = data.position + tagSize;
                        if (HLSSettings.logDebug2) {
                            Log.debug2("ID3 tag found, size/end pos:" + tagSize + "/" + end_pos);
                        }
                        // read tag
                        _parseFrame(data, end_pos);
                        data.position = end_pos;
                    } else if (header == '3DI') {
                        // http://id3.org/id3v2.4.0-structure chapter 3.4.   ID3v2 footer
                        data.position += 7;
                        if (HLSSettings.logDebug2) {
                            Log.debug2("3DI footer found, end pos:" + data.position);
                        }
                    } else {
                        data.position -= 3;
                        len = data.position - pos;
                        if (len) {
                            Log.debug2("ID3 len:" + len);
                            if (!hasTimestamp) {
                                Log.warn("ID3 tag found, but no timestamp");
                            }
                        }
                        return;
                    }
                } while (true);
            } catch(e : Error) {
            }
            len = 0;
            return;
        };

        /*  Each Elementary Audio Stream segment MUST signal the timestamp of
        its first sample with an ID3 PRIV tag [ID3] at the beginning of
        the segment.  The ID3 PRIV owner identifier MUST be
        "com.apple.streaming.transportStreamTimestamp".  The ID3 payload
        MUST be a 33-bit MPEG-2 Program Elementary Stream timestamp
        expressed as a big-endian eight-octet number, with the upper 31
        bits set to zero.
         */
        private function _parseFrame(data : ByteArray, end_pos : Number) : void {
            if (data.readUTFBytes(4) == "PRIV") {
                while (data.position + 53 <= end_pos) {
                    // owner should be "com.apple.streaming.transportStreamTimestamp"
                    if (data.readUTFBytes(44) == 'com.apple.streaming.transportStreamTimestamp') {
                        // smelling even better ! we found the right descriptor
                        // skip null character (string end) + 3 first bytes
                        data.position += 4;
                        // timestamp is 33 bit expressed as a big-endian eight-octet number, with the upper 31 bits set to zero.
                        var pts_33_bit : Number = data.readUnsignedByte() & 0x1;
                        hasTimestamp = true;
                        timestamp = (data.readUnsignedInt() / 90) << pts_33_bit;
                        Log.debug("ID3 timestamp found:" + timestamp);
                        return;
                    } else {
                        // rewind 44 read bytes + move to next byte
                        data.position -= 43;
                    }
                }
            }
        }
    }
}
