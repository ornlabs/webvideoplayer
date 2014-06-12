# HLSProvider

An Open-source HLS Flash plugin that allows you to play HLS streams.

The plugin is compatible with the following players:

  - [JW Player](#jw-player-6) 5 & 6 (**Free** edition only)
  - [Flowplayer](#flowplayer) 3.2.12
  - [OSMF 2.0](#strobe-media-playback-smp-and-other-osmf-based-players) based players (such as SMP and GrindPlayer)
  - video.js
  - MediaElement.js

## Features

  - VoD & Live playlists
    - Sliding window (aka DVR) support on Live playlists
  - Adaptive streaming
    - Manual & Auto switching
    - Serial segment fetching method from http://www.cs.tut.fi/~moncef/publications/rate-adaptation-IC-2011.pdf
  - Configurable seeking method on VoD & Live
    - Accurate seeking to exact requested position
    - Key frame based seeking (nearest key frame)
    - Segment based seeking (beginning of segment)
  - AES-128 decryption 
  - Buffer progress report
  - Error resilience
    - Retry mechanism on I/O errors 
    - Recovery mechanism on badly segmented TS streams

### Supported M3U8 tags

  - `#EXTM3U`
  - `#EXTINF`
  - `#EXT-X-STREAM-INF` (Multiple bitrate)
  - `#EXT-X-ENDLIST` (VoD / Live playlist)
  - `#EXT-X-MEDIA-SEQUENCE`
  - `#EXT-X-TARGETDURATION`
  - `#EXT-X-DISCONTINUITY`
  - `#EXT-X-DISCONTINUITY-SEQUENCE`
  - `#EXT-X-PROGRAM-DATE-TIME` (optional, used to synchronize time-stamps and sequence number when switching from one level to another)
  - `#EXT-X-KEY` (AES-128 method supported only)
  - `#EXT-X-BYTERANGE`

## Configuration

The plugin accepts several **optional** configuration options, such as:

  - `hls_debug` (default false) - Toggle _debug_ traces, outputted on JS console
  - `hls_debug2` (default false) - Toggle _verbose debug_ traces, outputted on JS console
  - `hls_minbufferlength` (default -1) - Minimum buffer length in _seconds_ that needs to be reached before playback can start (after seeking) or restart (in case of empty buffer)
    - If set to `-1` some heuristics based on past metrics are used to define an accurate value that should prevent buffer to stall
  - `hls_lowbufferlength` (default 3) - Low buffer threshold in _seconds_. When crossing down this threshold, HLS will switch to buffering state, usually the player will report this buffering state through a rotating icon. Playback will still continue.
  - `hls_maxbufferlength` (default 60) - Maximum buffer length in _seconds_ (0 means infinite buffering)
  - `hls_startfromlevel` (default -1) 
   - from 0 to 1 : indicates the "normalized" preferred bitrate. As such,
     - if 0, lowest non-audio bitrate is used,
     - if 1, highest bitrate is used,
     - if 0.5, the closest to the middle bitrate will be selected and used first.
   - -1 : automatic start level selection, playback will start from level matching download bandwidth (determined from download of first segment)
  - `hls_seekfromlevel` (default -1) - If set to true, playback will start from lowest non-audio level after any seek operation. If set to false, playback will start from level used before seeking
   - from 0 to 1 : indicates the "normalized" preferred bitrate. As such,
     - if 0, lowest non-audio bitrate is used,
     - if 1, highest bitrate is used,
     - if 0.5, the closest to the middle bitrate will be selected and used first.
   - -1 : automatic seek level selection, keep level before seek.   
  - `hls_live_flushurlcache` (default false) - If set to true, Live playlist will be flushed from URL cache before reloading (this is to workaround some cache issues with some combination of Flash Player / IE version)
  - `hls_seekmode`
    - "ACCURATE" - Seek to exact position
    - "KEYFRAME" - Seek to last keyframe before requested position
    - "SEGMENT" - Seek to beginning of segment containing requested position
  - `hls_manifestloadmaxretry` (default -1): max number of Manifest load retries after I/O Error.
    - if any I/O error is met during initial Manifest load, it will not be reloaded. an HLSError will be triggered immediately.
    - After initial load, any I/O error will trigger retries every 1s,2s,4s,8s (exponential, capped to 64s).  please note specific handling for these 2 values :
    	- 0, means no retry, error message will be triggered automatically
		- -1 means infinite retry
  - `hls_fragmentloadmaxretry` (default -1): max number of Fragment load retries after I/O Error.
	  * any I/O error will trigger retries every 1s,2s,4s,8s (exponential, capped to 64s).  please note specific handling for these 2 values :
		  * 0, means no retry, error message will be triggered automatically
		  * -1 means infinite retry      
  - `hls_capleveltostage` (default false) : cap levels usable in auto quality mode to the one with width smaller or equal to Stage Width.
    - true : playlist WIDTH attribute will be used and compared with Stage width. if playlist Width is greater than Stage width, this level will not be selected in auto quality mode. However it could still be manually selected.
    - false : don't cap levels, all could be used in auto-quality mode.


## Examples :

* http://www.hlsprovider.org/latest/test/chromeless
* http://www.hlsprovider.org/latest/test/jwplayer5
* http://www.hlsprovider.org/latest/test/jwplayer6
* http://www.hlsprovider.org/latest/test/osmf/GrindPlayer.html
* http://www.hlsprovider.org/latest/test/osmf/StrobeMediaPlayback.html
* http://www.hlsprovider.org/latest/test/flowplayer/index.html
* http://www.hlsprovider.org/mediaelement/demo/mediaelementplayer-hls.html
* http://www.hlsprovider.org/videojs/flash_demo.html



## Usage

  - Download HLSProvider from https://github.com/mangui/HLSprovider/releases
  - Unzip, extract and upload the appropiate version to your server
  - In the `examples` directory you will find examples for JW Player, Flowplayer, Strobe Media Playback (SMP) and GrindPlayer

### Setup
---

#### JW Player 6

Please keep in mind that HLSprovider works only with the **Free** edition of JW Player 6

```javascript
jwplayer("player").setup({
  // JW Player configuration options
  // ...
  playlist: [
    {
      file: 'http://mysite.com/stream.m3u8',
      provider: 'HLSProvider6.swf',
      type: 'hls'
    }
  ],
  // HLSProvider configuration options
  hls_debug: false,
  hls_debug2: false,
  hls_minbufferlength: -1,
  hls_lowbufferlength: 2,
  hls_maxbufferlength: 60,
  hls_startfromlowestlevel: false,
  hls_seekfromlowestlevel: false,
  hls_live_flushurlcache: false,
  hls_seekmode: 'ACCURATE'
});
```
---

#### JW Player 5

```javascript
jwplayer("player").setup({
  // JW Player configuration options
  // ...
  modes: [
    {
      type: 'flash',
      src: 'player.swf',
      config: {
        provider: 'HLSProvider5.swf',
        file: 'http://example.com/stream.m3u8'
      }
    }, {
      type: 'html5',
      config: {
        file: 'http://example.com/stream.m3u8'
      }
    }
  ],
  // HLSProvider configuration options
  hls_debug: false,
  hls_debug2: false,
  hls_minbufferlength: -1,
  hls_lowbufferlength: 2,
  hls_maxbufferlength: 60,
  hls_startfromlowestlevel: false,
  hls_seekfromlowestlevel: false,
  hls_live_flushurlcache: false,
  hls_seekmode: 'ACCURATE'
});
```
---

#### Flowplayer

```javascript
flowplayer("player", 'http://releases.flowplayer.org/swf/flowplayer-3.2.12.swf', {
  // Flowplayer configuration options
  // ...
  plugins: {
    httpstreaming: {
      // HLSProvider configuration options
      url: 'HLSProviderFlowPlayer.swf',
      hls_debug: false,
      hls_debug2: false,
      hls_lowbufferlength: 3,
      hls_minbufferlength: 8,
      hls_maxbufferlength: 60,
      hls_startfromlowestlevel: false,
      hls_seekfromlowestlevel: false,
      hls_live_flushurlcache: false,
      hls_seekmode: 'ACCURATE'
    }
  }
});
```
---

#### Strobe Media Playback (SMP) and other OSMF based players

```javascript
var playerOptions = {
  // Strobe Media Playback configuration options
  // ...
  source: 'http://example.com/stream.m3u8',
  // HLSProvider configuration options
  plugin_hls: "HLSProvider.swf",
  hls_debug: false,
  hls_debug2: false,
  hls_minbufferlength: -1,
  hls_lowbufferlength: 2,
  hls_maxbufferlength: 60,
  hls_startfromlowestlevel: false,
  hls_seekfromlowestlevel: false,
  hls_live_flushurlcache: false,
  hls_seekmode: 'ACCURATE'
};

swfobject.embedSWF('StrobeMediaPlayback.swf', 'player', 640, 360, '10.2', null, playerOptions, {
  allowFullScreen: true,
  allowScriptAccess: 'always',
  bgColor: '#000000',
  wmode: 'opaque'
}, {
  name: 'player'
});
```

## License

  - [MPL 2.0](https://github.com/mangui/HLSprovider/LICENSE)
  - JW Player files are governed by a `CC BY-NC-SA 3.0` license
  - [as3crypto.swc](https://github.com/timkurvers/as3-crypto) is governed by a `BSD` license

## Donation

If you'd like to support future development and new product features, please make a donation via PayPal. These donations are used to cover my ongoing expenses - web hosting, domain registrations, and software and hardware purchases.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=463RB2ALVXJLA)

---

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/mangui/hlsprovider/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
