package org.mangui.HLS.streaming {
    import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.net.*;
    import flash.utils.*;

    import org.mangui.HLS.*;
    import org.mangui.HLS.muxing.*;
    import org.mangui.HLS.streaming.*;
    import org.mangui.HLS.utils.*;

    /** Class that keeps the buffer filled. **/
    public class HLSNetStream extends NetStream {
        /** Reference to the framework controller. **/
        private var _hls : HLS;
        /** reference to auto buffer manager */
        private var _autoBufferManager : AutoBufferManager;
        /** FLV tags buffer vector **/
        private var _flvTagBuffer : Vector.<Tag>;
        /** FLV tags buffer duration **/
        private var _flvTagBufferDuration : Number;
        /** The fragment loader. **/
        private var _fragmentLoader : FragmentLoader;
        /** means that last fragment of a VOD playlist has been loaded */
        private var _reached_vod_end : Boolean;
        /** Timer used to check buffer and position. **/
        private var _timer : Timer;
        /** requested start position **/
        private var _seek_position_requested : Number;
        /** real start position , retrieved from first fragment **/
        private var _seek_position_real : Number;
        /** is a seek operation in progress ? **/
        private var _seek_in_progress : Boolean;
        /** Current play position (relative position from beginning of sliding window) **/
        private var _playback_current_position : Number;
        /** playlist sliding (non null for live playlist) **/
        private var _playlist_sliding_duration : Number;
        /** total duration of buffered data before last discontinuity */
        private var _buffered_before_last_continuity : Number;
        /** buffer min PTS since last discontinuity  */
        private var _buffer_cur_min_pts : Number;
        /** buffer max PTS since last discontinuity  */
        private var _buffer_cur_max_pts : Number;
        /** previous buffer time. **/
        private var _last_buffer : Number;
        /** Current playback state. **/
        private var _playbackState : String;
        /** Current seek state. **/
        private var _seekState : String;
        /** threshold to get out of buffering state
         * by default it is set to _buffer_low_len
         * however if buffer gets empty, its value is moved to _buffer_min_len
         */
        private var _buffer_threshold : Number;
        /** playlist duration **/
        private var _playlist_duration : Number = 0;

        /** Create the buffer. **/
        public function HLSNetStream(connection : NetConnection, hls : HLS, fragmentLoader : FragmentLoader) : void {
            super(connection);
            super.bufferTime = 0.1;
            _hls = hls;
            _autoBufferManager = new AutoBufferManager(hls);
            _fragmentLoader = fragmentLoader;
            _hls.addEventListener(HLSEvent.LAST_VOD_FRAGMENT_LOADED, _lastVODFragmentLoadedHandler);
            _hls.addEventListener(HLSEvent.PLAYLIST_DURATION_UPDATED, _playlistDurationUpdated);
            _playbackState = HLSPlayStates.IDLE;
            _seekState = HLSSeekStates.IDLE;
            _timer = new Timer(100, 0);
            _timer.addEventListener(TimerEvent.TIMER, _checkBuffer);
        };

        /** Check the bufferlength. **/
        private function _checkBuffer(e : Event) : void {
            var playback_absolute_position : Number;
            var playback_relative_position : Number;
            var buffer : Number = this.bufferLength;
            // Calculate the buffer and position.
            if (_seek_in_progress) {
                playback_relative_position = playback_absolute_position = _seek_position_requested;
            } else {
                /** Absolute playback position (start position + play time) **/
                playback_absolute_position = super.time + _seek_position_real;
                /** Relative playback position (Absolute Position - playlist sliding, non null for Live Playlist) **/
                playback_relative_position = playback_absolute_position - _playlist_sliding_duration;
            }
            // only send media time event if data has changed
            if (playback_relative_position != _playback_current_position || buffer != _last_buffer) {
                _playback_current_position = playback_relative_position;
                _last_buffer = buffer;
                _hls.dispatchEvent(new HLSEvent(HLSEvent.MEDIA_TIME, new HLSMediatime(_playback_current_position, _playlist_duration, buffer, _playlist_sliding_duration)));
            }

            // Set playback state. no need to check buffer status if first fragment not yet received
            if (!_seek_in_progress) {
                // check low buffer condition
                if (buffer < HLSSettings.lowBufferLength) {
                    if (buffer <= 0.1) {
                        if (_reached_vod_end) {
                            // reach end of playlist + playback complete (as buffer is empty).
                            // stop timer, report event and switch to IDLE mode.
                            _timer.stop();
                            Log.debug("reached end of VOD playlist, notify playback complete");
                            _hls.dispatchEvent(new HLSEvent(HLSEvent.PLAYBACK_COMPLETE));
                            _setPlaybackState(HLSPlayStates.IDLE);
                            _setSeekState(HLSSeekStates.IDLE);
                            return;
                        } else {
                            // pause Netstream in really low buffer condition
                            super.pause();
                            if (HLSSettings.minBufferLength == -1) {
                                _buffer_threshold = _autoBufferManager.minBufferLength;
                            } else {
                                _buffer_threshold = HLSSettings.minBufferLength;
                            }
                        }
                    }
                    // dont switch to buffering state in case we reached end of a VOD playlist
                    if (!_reached_vod_end) {
                        if (_playbackState == HLSPlayStates.PLAYING) {
                            // low buffer condition and play state. switch to play buffering state
                            _setPlaybackState(HLSPlayStates.PLAYING_BUFFERING);
                        } else if (_playbackState == HLSPlayStates.PAUSED) {
                            // low buffer condition and pause state. switch to paused buffering state
                            _setPlaybackState(HLSPlayStates.PAUSED_BUFFERING);
                        }
                    }
                }
                // in case buffer is full enough or if we have reached end of VOD playlist
                if (buffer >= _buffer_threshold || _reached_vod_end) {
                    /* after we reach back threshold value, set it buffer low value to avoid
                     * reporting buffering state to often. using different values for low buffer / min buffer
                     * allow to fine tune this 
                     */
                    if (HLSSettings.minBufferLength == -1) {
                        // in automode, low buffer threshold should be less than min auto buffer
                        _buffer_threshold = Math.min(_autoBufferManager.minBufferLength / 2, HLSSettings.lowBufferLength);
                    } else {
                        _buffer_threshold = HLSSettings.lowBufferLength;
                    }

                    // no more in low buffer state
                    if (_playbackState == HLSPlayStates.PLAYING_BUFFERING) {
                        Log.debug("resume playback");
                        super.resume();
                        _setPlaybackState(HLSPlayStates.PLAYING);
                    } else if (_playbackState == HLSPlayStates.PAUSED_BUFFERING) {
                        _setPlaybackState(HLSPlayStates.PAUSED);
                    }
                }
            }
            // in case any data available in our FLV buffer, append into NetStream
            if (_flvTagBuffer.length) {
                if (_seek_in_progress) {
                    /* this is our first injection after seek(),
                    let's flush netstream now
                    this is to avoid black screen during seek command */
                    super.close();
                    super.play(null);
                    super.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
                    // immediatly pause NetStream, it will be resumed when enough data will be buffered in the NetStream
                    super.pause();
                    _seek_in_progress = false;
                    // dispatch event to mimic NetStream behaviour
                    dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, {code:"NetStream.Seek.Notify", level:"status"}));
                    _setSeekState(HLSSeekStates.SEEKED);
                }
                // Log.debug("appending data into NetStream");
                while (0 < _flvTagBuffer.length) {
                    var tagBuffer : Tag = _flvTagBuffer.shift();
                    // append data until we drain our _buffer
                    try {
                        if (tagBuffer.type == Tag.DISCONTINUITY) {
                            super.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
                            super.appendBytes(FLV.getHeader());
                        } else {
                            super.appendBytes(tagBuffer.data);
                        }
                    } catch (error : Error) {
                        var hlsError : HLSError = new HLSError(HLSError.TAG_APPENDING_ERROR, null, tagBuffer.type + ": " + error.message);
                        _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR, hlsError));
                    }
                    // Last tag done? Then append sequence end.
                    if (_reached_vod_end && _flvTagBuffer.length == 0) {
                        super.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
                        super.appendBytes(new ByteArray());
                    }
                }
                // FLV tag buffer drained, reset its duration
                _flvTagBufferDuration = 0;
            }
            // update buffer threshold here if needed
            if (HLSSettings.minBufferLength == -1) {
                _buffer_threshold = _autoBufferManager.minBufferLength;
            }
        };

        /** Return the current playback state. **/
        public function get position() : Number {
            return _playback_current_position;
        };

        /** Return the current playback state. **/
        public function get playbackState() : String {
            return _playbackState;
        };

        /** Return the current seek state. **/
        public function get seekState() : String {
            return _seekState;
        };

        /** Add a fragment to the buffer. **/
        private function _loaderCallback(tags : Vector.<Tag>, min_pts : Number, max_pts : Number, hasDiscontinuity : Boolean, start_position : Number) : void {
            var tag : Tag;
            /* PTS of first tag that will be pushed into FLV tag buffer */
            var first_pts : Number;
            /* PTS of last video keyframe before requested seek position */
            var keyframe_pts : Number;
            if (_seek_position_real == Number.NEGATIVE_INFINITY) {
                /* 
                 * 
                 *    real seek       requested seek                 Frag 
                 *     position           position                    End
                 *        *------------------*-------------------------
                 *        <------------------>
                 *             seek_offset
                 *
                 * real seek position is the start offset of the first received fragment after seek command. (= fragment start offset).
                 * seek offset is the diff between the requested seek position and the real seek position
                 */

                /* if requested seek position is out of this segment bounds
                 * all the segments will be pushed, first pts should be thus be min_pts
                 */
                if (_seek_position_requested < start_position || _seek_position_requested >= start_position + ((max_pts - min_pts) / 1000)) {
                    _seek_position_real = start_position;
                    first_pts = min_pts;
                } else {
                    /* if requested position is within segment bounds, determine real seek position depending on seek mode setting */
                    if (HLSSettings.seekMode == HLSSeekmode.SEGMENT_SEEK) {
                        _seek_position_real = start_position;
                        first_pts = min_pts;
                    } else {
                        /* accurate or keyframe seeking */
                        /* seek_pts is the requested PTS seek position */
                        var seek_pts : Number = min_pts + 1000 * (_seek_position_requested - start_position);
                        /* analyze fragment tags and look for PTS of last keyframe before seek position.*/
                        keyframe_pts = tags[0].pts;
                        for each (tag in tags) {
                            // look for last keyframe with pts <= seek_pts
                            if (tag.keyframe == true && tag.pts <= seek_pts && tag.type.indexOf("AVC") != -1) {
                                keyframe_pts = tag.pts;
                            }
                        }
                        if (HLSSettings.seekMode == HLSSeekmode.KEYFRAME_SEEK) {
                            _seek_position_real = start_position + (keyframe_pts - min_pts) / 1000;
                            first_pts = keyframe_pts;
                        } else {
                            // accurate seek, to exact requested position
                            _seek_position_real = _seek_position_requested;
                            first_pts = seek_pts;
                        }
                    }
                }
            } else {
                /* no seek in progress operation, whole fragment will be injected */
                first_pts = min_pts;
                /* check live playlist sliding here :
                _seek_position_real + getTotalBufferedDuration()  should be the start_position
                 * /of the new fragment if the playlist was not sliding
                => live playlist sliding is the difference between the new start position  and this previous value */
                _playlist_sliding_duration = (_seek_position_real + getTotalBufferedDuration()) - start_position;
            }
            /* if first fragment loaded, or if discontinuity, record discontinuity start PTS, and insert discontinuity TAG */
            if (hasDiscontinuity) {
                _buffered_before_last_continuity += (_buffer_cur_max_pts - _buffer_cur_min_pts);
                _buffer_cur_min_pts = first_pts;
                _buffer_cur_max_pts = max_pts;
                _flvTagBuffer.push(new Tag(Tag.DISCONTINUITY, first_pts, first_pts, false));
            } else {
                // same continuity than previously, update its max PTS
                _buffer_cur_max_pts = max_pts;
            }

            tags.sort(_sortTagsbyDTS);

            /* if no seek in progress or if in segment seeking mode : push all FLV tags */
            if (!_seek_in_progress || HLSSettings.seekMode == HLSSeekmode.SEGMENT_SEEK) {
                for each (tag in tags) {
                    _flvTagBuffer.push(tag);
                }
            } else {
                /* keyframe / accurate seeking, we need to filter out some FLV tags */
                for each (tag in tags) {
                    if (tag.pts >= first_pts) {
                        _flvTagBuffer.push(tag);
                    } else {
                        switch(tag.type) {
                            case Tag.AAC_HEADER:
                            case Tag.AVC_HEADER:
                                tag.pts = tag.dts = first_pts;
                                _flvTagBuffer.push(tag);
                                break;
                            case Tag.AVC_NALU:
                                /* only append video tags starting from last keyframe before seek position to avoid playback artifacts
                                 *  rationale of this is that there can be multiple keyframes per segment. if we append all keyframes
                                 *  in NetStream, all of them will be displayed in a row and this will introduce some playback artifacts
                                 *  */
                                if (tag.pts >= keyframe_pts) {
                                    tag.pts = tag.dts = first_pts;
                                    _flvTagBuffer.push(tag);
                                }
                                break;
                            default:
                                break;
                        }
                    }
                }
            }
            _flvTagBufferDuration += (max_pts - first_pts) / 1000;
            Log.debug("Loaded position/duration/sliding/discontinuity:" + start_position.toFixed(2) + "/" + ((max_pts - min_pts) / 1000).toFixed(2) + "/" + _playlist_sliding_duration.toFixed(2) + "/" + hasDiscontinuity);
        };

        /** return total buffered duration since seek() call, needed to compute live playlist sliding  */
        private function getTotalBufferedDuration() : Number {
            return (_buffered_before_last_continuity + _buffer_cur_max_pts - _buffer_cur_min_pts) / 1000;
        }

        private function _lastVODFragmentLoadedHandler(event : HLSEvent) : void {
            Log.debug("last fragment loaded");
            _reached_vod_end = true;
        }

        private function _playlistDurationUpdated(event : HLSEvent) : void {
            _playlist_duration = event.duration;
        }

        /** Change playback state. **/
        private function _setPlaybackState(state : String) : void {
            if (state != _playbackState) {
                Log.debug('[PLAYBACK_STATE] from ' + _playbackState + ' to ' + state);
                _playbackState = state;
                _hls.dispatchEvent(new HLSEvent(HLSEvent.PLAYBACK_STATE, _playbackState));
            }
        };

        /** Change seeking state. **/
        private function _setSeekState(state : String) : void {
            if (state != _seekState) {
                Log.debug('[SEEK_STATE] from ' + _seekState + ' to ' + state);
                _seekState = state;
                _hls.dispatchEvent(new HLSEvent(HLSEvent.SEEK_STATE, _seekState));
            }
        };

        /** Sort the buffer by tag. **/
        private function _sortTagsbyDTS(x : Tag, y : Tag) : Number {
            if (x.dts < y.dts) {
                return -1;
            } else if (x.dts > y.dts) {
                return 1;
            } else {
                if (x.type == Tag.AVC_HEADER || x.type == Tag.AAC_HEADER) {
                    return -1;
                } else if (y.type == Tag.AVC_HEADER || y.type == Tag.AAC_HEADER) {
                    return 1;
                } else {
                    if (x.type == Tag.AVC_NALU) {
                        return -1;
                    } else if (y.type == Tag.AVC_NALU) {
                        return 1;
                    } else {
                        return 0;
                    }
                }
            }
        };

        override public function play(...args) : void {
            var _playStart : Number;
            if (args.length >= 2) {
                _playStart = Number(args[1]);
            } else {
                _playStart = -1;
            }
            Log.info("HLSNetStream:play(" + _playStart + ")");
            seek(_playStart);
            _setPlaybackState(HLSPlayStates.PLAYING_BUFFERING);
        }

        override public function play2(param : NetStreamPlayOptions) : void {
            Log.info("HLSNetStream:play2(" + param.start + ")");
            seek(param.start);
            _setPlaybackState(HLSPlayStates.PLAYING_BUFFERING);
        }

        /** Pause playback. **/
        override public function pause() : void {
            Log.info("HLSNetStream:pause");
            if (_playbackState == HLSPlayStates.PLAYING) {
                super.pause();
                _setPlaybackState(HLSPlayStates.PAUSED);
            } else if (_playbackState == HLSPlayStates.PLAYING_BUFFERING) {
                super.pause();
                _setPlaybackState(HLSPlayStates.PAUSED_BUFFERING);
            }
        };

        /** Resume playback. **/
        override public function resume() : void {
            Log.info("HLSNetStream:resume");
            if (_playbackState == HLSPlayStates.PAUSED) {
                super.resume();
                _setPlaybackState(HLSPlayStates.PLAYING);
            } else if (_playbackState == HLSPlayStates.PAUSED_BUFFERING) {
                // dont resume NetStream here, it will be resumed by Timer. this avoids resuming playback while seeking is in progress
                _setPlaybackState(HLSPlayStates.PLAYING_BUFFERING);
            }
        };

        /** get Buffer Length  **/
        override public function get bufferLength() : Number {
            /* remaining buffer is total duration buffered since beginning minus playback time */
            if (_seek_in_progress) {
                return _flvTagBufferDuration;
            } else {
                return super.bufferLength + _flvTagBufferDuration;
            }
        };

        /** Start playing data in the buffer. **/
        override public function seek(position : Number) : void {
            Log.info("HLSNetStream:seek(" + position + ")");
            _fragmentLoader.stop();
            _fragmentLoader.seek(position, _loaderCallback);
            _flvTagBuffer = new Vector.<Tag>();
            _flvTagBufferDuration = _buffered_before_last_continuity = _buffer_cur_min_pts = _buffer_cur_max_pts = _playlist_sliding_duration = 0;
            _seek_position_requested = Math.max(position, 0);
            _seek_position_real = Number.NEGATIVE_INFINITY;
            _seek_in_progress = true;
            _reached_vod_end = false;
            if (HLSSettings.minBufferLength == -1) {
                _buffer_threshold = _autoBufferManager.minBufferLength;
            } else {
                _buffer_threshold = HLSSettings.minBufferLength;
            }
            /* if HLS was in paused state before seeking, 
             * switch to paused buffering state
             * otherwise, switch to playing buffering state
             */
            switch(_playbackState) {
                case HLSPlayStates.PAUSED:
                case HLSPlayStates.PAUSED_BUFFERING:
                    _setPlaybackState(HLSPlayStates.PAUSED_BUFFERING);
                    break;
                case HLSPlayStates.PLAYING:
                case HLSPlayStates.PLAYING_BUFFERING:
                    _setPlaybackState(HLSPlayStates.PLAYING_BUFFERING);
                    break;
                default:
                    break;
            }
            _setSeekState(HLSSeekStates.SEEKING);
            /* always pause NetStream while seeking, even if we are in play state
             * in that case, NetStream will be resumed after first fragment loading
             */
            super.pause();
            _timer.start();
        };

        /** Stop playback. **/
        override public function close() : void {
            Log.info("HLSNetStream:close");
            super.close();
            _timer.stop();
            _fragmentLoader.stop();
            _setPlaybackState(HLSPlayStates.IDLE);
            _setSeekState(HLSSeekStates.IDLE);
        };

        public function dispose_() : void {
            close();
            _autoBufferManager.dispose();
            _hls.removeEventListener(HLSEvent.LAST_VOD_FRAGMENT_LOADED, _lastVODFragmentLoadedHandler);
            _hls.removeEventListener(HLSEvent.PLAYLIST_DURATION_UPDATED, _playlistDurationUpdated);
        }
    }
}
