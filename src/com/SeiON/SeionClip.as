package com.SeiON
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.Core.SeionEvent;
	import com.SeiON.Misc.CountDown;
	
	/**
	 * The simplest way to play a _snd.<p></p>
	 *
	 * SeionClip is a simple wrapper over both the native Sound and the _sndChannel object in
	 * Flash.<p></p>
	 *
	 * Use SeionClip.create() to instantiate this class.
	 *
	 * @see #create()
	 */
	public class SeionClip extends SeionInstance
	{
		/**
		 * _offset:		The delayed starting position.
		 * _truncate:	The shorted ending position.
		 *
		 * pausedLocation:	Where the _snd was paused, so you can pause()/resume()
		 * truncation:		Keeps track of where the _snd will end.
		 */
		private var _offset:uint = 0;
		private var _truncate:uint = 0;
		
		private var pausedLocation:Number = -1;
		public var truncation:CountDown;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionClip.create().
		 *
		 * @see SeionClip#create()
		 */
		public function SeionClip(name:String, manager:SeionGroup, snd:Sound, repeat:int,
								sndTransform:SoundTransform, autodispose:Boolean, secretKey:*)
		{
			super(name, manager, snd, repeat, autodispose, sndTransform, secretKey);
		}
		
		public static function create(name:String, manager:SeionGroup, snd:Sound, repeat:int,
					sndTransform:SoundTransform = null, autodispose:Boolean = true):SeionClip
		{
			///TODO complete SeionClip.create()
		}
		
		/**
		 * Creates a sound clip that is shorted.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionClip. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	repeat	How many times to repeat the clip.
		 * @param	sndTransform	The fixed internal property for the sound.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	offset		The delayed starting position. Immutable.
		 * @param	truncate	The shorted ending position. Immutable.
		 *
		 * @return	A SeionClip is allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 */
		public static function createExcerpt(name:String, manager:SeionGroup, snd:Sound, repeat:int,
					sndTransform:SoundTransform, autodispose:Boolean,
					offset:Number, truncate:Number):SeionClip
		{
			var a:SeionClip = create(name, manager, snd, repeat, sndTransform, autodispose);
			if (a != null)
			{
				a._offset = offset;
				a._truncate = truncate;
			}
			return a;
		}
		
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		public function dispose():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			stop();
			
			// truncation.stop() alrdy done in dispose's stop() above
			truncation = null;
			
			_manager.killSound(this);
			super.dispose();
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ----------------------------
		
		/** Plays the _snd from the beginning again according to sndProperties. (ISeionInstance) */
		public function play():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			stop(); // for safety's sake
			
			// setting up truncation
			// CountDown does not operate if given input = 0
			var truncatedLength:Number = (sndProperties.duration == 0) ? 0 : sndProperties.duration;
			truncation = new CountDown(truncatedLength);
			truncation.start();
			truncation.pause(); //<-- start&pause cos we using resume() later
			truncation.addEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
			
			pausedLocation = sndProperties.offset;
			resume();
		}
		
		/** Stops the _snd and resets it to Zero. (ISeionInstance) */
		public function stop():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			if (isPlaying || isPaused)
			{
				if (_sndChannel)
				{
					_sndChannel.stop();
					_sndChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					_sndChannel = null;
				}
				// reset variables
				if (truncation) // 'cos play() calls stop() before truncation is even created
				{
					truncation.stop();
					truncation.removeEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
				}
				
				pausedLocation = -1;
				_repeat = sndProperties.repeat;
			}
		}
		
		/** Resumes playback of _snd. (ISeionControl) */
		public function resume():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// if manager is paused, no resuming allowed!
			if (_manager.isPaused)	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused)
			{
				// setting volume and panning - triggering properties to set for us
				volume = _volume;
				pan = _pan;
				
				// resuming truncation
				truncation.resume();
				
				// starting up the _snd
				_sndChannel = _snd.play(pausedLocation, 0, sndTransform);
				
				/* The _snd might be so short that it finishes before the code executes.
				 * Just in case.
				 * */
				if (_sndChannel)
				{
					_sndChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					pausedLocation = -1;
				}
				else
					onSoundComplete();
			}
		}
		
		/** Pauses playback of _snd. (ISeionControl) */
		public function pause():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// pause is only valid if it were playing in the 1st place
			if (isPlaying)
			{
				pausedLocation = _sndChannel.position;
				_sndChannel.stop();
				_sndChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				_sndChannel = null;
				
				truncation.pause();
			}
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		/** Is the sound active? (ISeionInstance) */
		public function get isPlaying():Boolean
		{
			if (_sndChannel)
				return true;
			return false;
		}
		
		/** Is the playback paused? (ISeionControl) */
		public function get isPaused():Boolean
		{
			if (pausedLocation == -1)
				return false;
			return true;
		}
		
		/** The total length of the clip, excluding repeats. In Milliseconds. (ISeionInstance) */
		public function get length():Number
		{
			// Checking for dispose
			if (isDisposed())	return 0.0;
			
			return (sndProperties.duration == 0) ? _snd.length : sndProperties.duration;
		}
		
		/** How far into the clip we are. In Milliseconds. (ISeionInstance) <p></p>
		 * Includes offsets or truncated durations, eg. a 10 second _snd with 5 seconds offset at
		 * starting position would report a position of 0, not 5. */
		public function get position():Number
		{
			// Checking for dispose
			if (isDisposed())	return 0.0;
			
			if (isPaused)
				return pausedLocation - sndProperties.offset;
			else if (!isPlaying) //clip not started yet
				return 0;
			return _sndChannel.position - sndProperties.offset;
		}
		
		/** How far into the clip we are, from 0.0 - 1.0. (ISeionInstance) <p></p>
		 * Includes offsets or truncations, eg. a 100 second _snd with 5 seconds offset at
		 * starting position would report a position of 0.0, not 0.95. */
		public function get progress():Number
		{
			return position / length;
		}
		
		// -------------------------------- PRIVATE HELPER METHODS --------------------------
		/**
		 * Called when a _snd completes. As for autodispose _snds, they self-dispose.
		 *
		 * @param	e	Not important. e == null when truncation cuts it short, else this function
		 * 				was called by Event.SOUND_COMPLETE.
		 *
		 * @private
		 */
		protected function onSoundComplete(e:Event = null):void
		{
			if (e)		e.stopImmediatePropagation();
			
			if (repeat >= 0) // repeating
			{
				if (repeat == 0) // infinite loop
				{}
				else if (repeat == 1) // the last time
					repeat = -1;
				
				repeatSound();
				dispatcher.dispatchEvent(new SeionEvent(SeionEvent.SOUND_REPEAT, this));
			}
			else // disposing
			{
				dispatcher.dispatchEvent(new SeionEvent(Event.SOUND_COMPLETE, this));
				stop();
				
				if (autodispose)
					dispose();
			}
		}
		
		/**
		 * Makes the sound repeat.
		 */
		private function repeatSound():void
		{
			// 'cos variables are lost in play() and play()'s stop(), we record them
			var tmpRepeat:int = _repeat;
			play();
			_repeat = tmpRepeat;
		}
	}
}