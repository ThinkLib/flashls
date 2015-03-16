/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.mangui.dash {

    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLStream;
    import org.mangui.adaptive.Adaptive;
    import org.mangui.adaptive.controller.LevelController;
    import org.mangui.adaptive.event.AdaptiveEvent;
    import org.mangui.adaptive.model.AltAudioTrack;
    import org.mangui.adaptive.model.AudioTrack;
    import org.mangui.adaptive.model.Level;
    import org.mangui.adaptive.stream.AdaptiveNetStream;
    import org.mangui.adaptive.stream.StreamBuffer;
    import org.mangui.dash.controller.AudioTrackController;
    import org.mangui.dash.loader.AudioFragmentLoader;
    import org.mangui.dash.loader.FragmentLoader;
    import org.mangui.dash.loader.LevelLoader;

    CONFIG::LOGGING {
        import org.mangui.adaptive.utils.Log;
    }
    /** Class that manages the streaming process. **/
    public class Dash extends EventDispatcher implements Adaptive {
        private var _levelLoader : LevelLoader;
        private var _audioTrackController : AudioTrackController;
        private var _levelController : LevelController;
        private var _fragmentLoader : FragmentLoader;
        private var _audiofragmentLoader : AudioFragmentLoader;
        private var _streamBuffer : StreamBuffer;
        /** Adaptive NetStream **/
        private var _AdaptiveNetStream : AdaptiveNetStream;
        /** Adaptive URLStream **/
        private var _dashURLStream : Class;
        private var _client : Object = {};
        private var _stage : Stage;
        /* level handling */
        private var _level : int;
        /* overrided quality_manual_level level */
        private var _manual_level : int = -1;

        /** Create and connect all components. **/
        public function Dash() {
            var connection : NetConnection = new NetConnection();
            connection.connect(null);
            _levelLoader = new LevelLoader(this);
            _audioTrackController = new AudioTrackController(this);
            _levelController = new LevelController(this);
            _fragmentLoader = new FragmentLoader(this, _audioTrackController, _levelController);
            _audiofragmentLoader = new AudioFragmentLoader(this);
            _streamBuffer = new StreamBuffer(this, _fragmentLoader, _audiofragmentLoader);
            _fragmentLoader.attachStreamBuffer(_streamBuffer);
            _audiofragmentLoader.attachStreamBuffer(_streamBuffer);
            _dashURLStream = URLStream as Class;
            // default loader
            _AdaptiveNetStream = new AdaptiveNetStream(connection, this, _streamBuffer);
            this.addEventListener(AdaptiveEvent.LEVEL_SWITCH, _levelSwitchHandler);
        };

        /** Forward internal errors. **/
        override public function dispatchEvent(event : Event) : Boolean {
            if (event.type == AdaptiveEvent.ERROR) {
                CONFIG::LOGGING {
                    Log.error((event as AdaptiveEvent).error);
                }
                _AdaptiveNetStream.close();
            }
            return super.dispatchEvent(event);
        };

        private function _levelSwitchHandler(event : AdaptiveEvent) : void {
            _level = event.level;
        };

        public function dispose() : void {
            this.removeEventListener(AdaptiveEvent.LEVEL_SWITCH, _levelSwitchHandler);
            _levelLoader.dispose();
            _audioTrackController.dispose();
            _levelController.dispose();
            _streamBuffer.dispose();
            _fragmentLoader.dispose();
            _audiofragmentLoader.dispose();
            _AdaptiveNetStream.dispose_();
            _levelLoader = null;
            _audioTrackController = null;
            _levelController = null;
            _fragmentLoader = null;
            _audiofragmentLoader = null;
            _streamBuffer = null;
            _AdaptiveNetStream = null;
            _client = null;
            _stage = null;
            _AdaptiveNetStream = null;
        }

        /** Return the quality level used when starting a fresh playback **/
        public function get startlevel() : int {
            return _levelController.startlevel;
        };

        /** Return the quality level used after a seek operation **/
        public function get seeklevel() : int {
            return _levelController.seeklevel;
        };

        /** Return the quality level of the currently played fragment **/
        public function get playbacklevel() : int {
            return _AdaptiveNetStream.playbackLevel;
        };

        /** Return the quality level of last loaded fragment **/
        public function get level() : int {
            return _level;
        };

        /*  set quality level for next loaded fragment (-1 for automatic level selection) */
        public function set level(level : int) : void {
            _manual_level = level;
        };

        /* check if we are in automatic level selection mode */
        public function get autolevel() : Boolean {
            return (_manual_level == -1);
        };

        /* return manual level */
        public function get manuallevel() : int {
            return _manual_level;
        };

        /** Return a Vector of quality level **/
        public function get levels() : Vector.<Level> {
            return _levelLoader.levels;
        };

        /** Return the current playback position. **/
        public function get position() : Number {
            return _streamBuffer.position;
        };

        /** Return the current playback state. **/
        public function get playbackState() : String {
            return _AdaptiveNetStream.playbackState;
        };

        /** Return the current seek state. **/
        public function get seekState() : String {
            return _AdaptiveNetStream.seekState;
        };

        /** Return the type of stream (VOD/LIVE). **/
        public function get type() : String {
            return _levelLoader.type;
        };

        /** Load and parse a new Adaptive URL **/
        public function load(url : String) : void {
            _AdaptiveNetStream.close();
            _levelLoader.load(url);
        };

        /** return Adaptive NetStream **/
        public function get stream() : NetStream {
            return _AdaptiveNetStream;
        }

        public function get client() : Object {
            return _client;
        }

        public function set client(value : Object) : void {
            _client = value;
        }

        /** get current Buffer Length  **/
        public function get bufferLength() : Number {
            return _AdaptiveNetStream.bufferLength;
        };

        /** get audio tracks list**/
        public function get audioTracks() : Vector.<AudioTrack> {
            return _audioTrackController.audioTracks;
        };

        /** get alternate audio tracks list from playlist **/
        public function get altAudioTracks() : Vector.<AltAudioTrack> {
            return _levelLoader.altAudioTracks;
        };

        /** get index of the selected audio track (index in audio track lists) **/
        public function get audioTrack() : int {
            return _audioTrackController.audioTrack;
        };

        /** select an audio track, based on its index in audio track lists**/
        public function set audioTrack(val : int) : void {
            _audioTrackController.audioTrack = val;
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
            _dashURLStream = urlstream;
        }

        /* retrieve URL stream loader */
        public function get URLstream() : Class {
            return _dashURLStream;
        }
    }
}