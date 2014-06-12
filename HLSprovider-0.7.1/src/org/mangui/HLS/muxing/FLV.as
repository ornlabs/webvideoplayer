package org.mangui.HLS.muxing {
    import flash.utils.ByteArray;

    /** Helpers for the FLV file format. **/
    public class FLV {
        public static var TAG_TYPE_AUDIO : Number = 8;
        public static var TAG_TYPE_VIDEO : Number = 9;
        //public static var TAG_TYPE_SCRIPT : Number = 18;

        /** Get the FLV file header. **/
        public static function getHeader() : ByteArray {
            var flv : ByteArray = new ByteArray();
            flv.length = 13;
            // "F" + "L" + "V".
            flv.writeByte(0x46);
            flv.writeByte(0x4C);
            flv.writeByte(0x56);
            // File version (1)
            flv.writeByte(1);
            // Audio + Video tags.
            flv.writeByte(1);
            // Length of the header.
            flv.writeUnsignedInt(9);
            // PreviousTagSize0
            flv.writeUnsignedInt(0);
            return flv;
        };

        /** Get an FLV Tag header (11 bytes). **/
        public static function getTagHeader(type : Number, length : Number, stamp : Number) : ByteArray {
            var tag : ByteArray = new ByteArray();
            tag.length = 11;
            tag.writeByte(type);

            // Size of the tag in bytes after StreamID.
            tag.writeByte(length >> 16);
            tag.writeByte(length >> 8);
            tag.writeByte(length);
            // Timestamp (lower 24 plus upper 8)
            tag.writeByte(stamp >> 16);
            tag.writeByte(stamp >> 8);
            tag.writeByte(stamp);
            tag.writeByte(stamp >> 24);
            // StreamID (3 empty bytes)
            tag.writeByte(0);
            tag.writeByte(0);
            tag.writeByte(0);
            // All done
            return tag;
        };
    }
}