package com.SeiON
{
	import com.SeiON.SeionGroup;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.seion_ns;
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
		 * _truncate:	The truncation from the ending position.
		 *
		 * pausedLocation:	Where the _snd was paused, so you can pause()/resume()
		 * _truncation:		Keeps track of where the _snd will end.
		 */
		private var _offset:uint;
		private var _truncate:uint;
		
		private var pausedLocation:Number = -1;
		private var _truncation:CountDown;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionClip.create().
		 *
		 * @see SeionClip#create()
		 */
		public function SeionClip(secretKey:*)
		{
			super(secretKey);
		}
		
		/** The initialisation function. */
		protected static function init(sc:SeionClip, name:String, manager:SeionGroup, snd:Sound,
									repeat:int,	autodispose:Boolean, sndTransform:SoundTransform,
									offset:uint, truncate:uint):void
		{
			SeionInstance.init(sc, name, manager, snd, repeat, autodispose, sndTransform);
			
			sc._offset = offset;
			sc._truncate = truncate;
		}
		
		/**
		 * Creates a sound clip.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionClip. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	repeat	How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionClip is allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	#name
		 * @see	#repeat
		 * @see	#soundtransform
		 * @see	#autodispose
		 */
		public static function create(name:String, manager:SeionGroup, snd:Sound, repeat:int,
					autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionClip
		{
			var a:SeionClip = createExcerpt(name, manager, snd, repeat, autodispose, sndTransform,
											0, 0);
			return a;
		}
		
		/**
		 * Creates a sound clip that is shorted.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionClip. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	repeat	How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 * @param	offset		The delayed starting position. In Milliseconds. Immutable.
		 * @param	truncate	The truncation from the ending position. In Milliseconds. Immutable.
		 *
		 * @return	A SeionClip if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	#name
		 * @see	#repeat
		 * @see	#soundtransform
		 * @see	#autodispose
		 * @see	#offset
		 * @see	#truncate
		 */
		public static function createExcerpt(name:String, manager:SeionGroup, snd:Sound, repeat:int,
						autodispose:Boolean, sndTransform:SoundTransform,
						offset:uint, truncate:uint):SeionClip
		{
			/**
			 * Create empty hull of a SeionClip.
			 * Try to allocate the sound in manager.
			 * If successful
			 * 		Initiate the SeionClip
			 * 		Check if it's autodisposable
			 *
			 * Return the clip (if any).
			 */
			var a:SeionClip = new SeionClip(SeionInstance._secretKey);
			if (manager.seion_ns::alloc(a))
			{
				SeionClip.init(a, name, manager, snd, repeat, autodispose, sndTransform, offset,
								truncate);
				if (autodispose)	a = null;
			}
			else
				a = null;
			
			return a;
		}
		
		// --------------------------------------- Abstract ---------------------------------
		
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		override public function dispose():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			stop();
			
			// _truncation.stop() alrdy done in dispose's stop() above
			_truncation = null;
			
			_manager.seion_ns::killSound(this);
			super.dispose();
		}
		
		/*******************************************************************************
		 * 									PLAYBACK CONTROLS
		 *******************************************************************************/
		//  ----------------------------------- Abstract -------------------------------
		
		/** Plays the sound from the beginning again. (ISeionInstance) */
		override public function play():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			stop(); // for safety's sake
			
			// setting up _truncation
			// CountDown does not operate if given input = 0
			_truncation = new CountDown(this.length);
			_truncation.start();
			_truncation.pause(); //<-- start&pause cos we using resume() later
			_truncation.addEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
			
			pausedLocation = _offset;
			resume();
		}
		
		/** Stops the sound and resets it to Zero. (ISeionInstance) */
		override public function stop():void
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
				if (_truncation) // 'cos play() calls stop() before _truncation is even created
				{
					_truncation.stop();
					_truncation.removeEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
				}
				
				pausedLocation = -1;
				repeat = repeat;
			}
		}
		
		/** Resumes playback of sound. (ISeionControl) */
		override public function resume():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// if manager is paused, no resuming allowed!
			if (_manager.isPaused)	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused)
			{
				// resuming _truncation
				_truncation.resume();
				
				// starting up the _snd
				_sndChannel = _snd.play(pausedLocation, 0, soundtransform);
				
				// setting volume and panning - triggering properties to set for us
				volume = volume;
				pan = pan;
				
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
		
		/** Pauses playback of sound. (ISeionControl) */
		override public function pause():void
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
				
				_truncation.pause();
			}
		}
		
		/*****************************************************************************
		 * 									PROPERTIES
		 *****************************************************************************/
		
		/** The delayed starting position. In Milliseconds. */
		public function get offset():uint	{	return _offset;	}
		/** The truncation from the ending position. In Milliseconds. */
		public function get truncate():uint	{	return _truncate;	}
		
		// --------------------------------- ABSTRACT --------------------------------
		
		/** Is the sound active? (ISeionInstance) */
		override public function get isPlaying():Boolean
		{
			if (_sndChannel)
				return true;
			return false;
		}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean
		{
			if (pausedLocation == -1)
				return false;
			return true;
		}
		
		/** The total length of the clip, excluding repeats. In Milliseconds. (ISeionInstance) */
		override public function get length():Number
		{
			// Checking for dispose
			if (isDisposed())	return 0.0;
			return _snd.length - _truncate - _offset;
		}
		
		/** How far into the clip we are. In Milliseconds. (ISeionInstance) <p></p>
		 *
		 * Includes offsets or truncated durations, eg. a 10 second _snd with 5 seconds offset at
		 * starting position would report a position of 0, not 5. */
		override public function get position():Number
		{
			// Checking for dispose
			if (isDisposed())	return 0.0;
			
			if (isPaused)
				return pausedLocation - _offset;
			else if (!isPlaying) //clip not started yet
				return 0;
			return _sndChannel.position - _offset;
		}
		
		/** How far into the clip we are, from 0.0 - 1.0. (ISeionInstance) <p></p>
		 *
		 * Includes offsets or truncations, eg. a 100 second _snd with 5 seconds offset at
		 * starting position would report a position of 0.0, not 0.95. */
		override public function get progress():Number
		{
			return position / length;
		}
		
		/***********************************************************************************
		 *	 								PRIVATE HELPER METHODS
		 ***********************************************************************************/
		
		/**
		 * Called when a _snd completes. As for autodispose _snds, they self-dispose.
		 *
		 * @param	e	Not important. e == null when _truncation cuts it short, else this function
		 * 				was called by Event.SOUND_COMPLETE.
		 *
		 * @private
		 */
		protected function onSoundComplete(e:Event = null):void
		{
			if (e)		e.stopImmediatePropagation();
			
			if (repeatLeft >= 0) // repeating
			{
				if (repeatLeft == 0) // infinite loop
				{}
				else if (repeatLeft == 1) // the last time
					_repeat = -1;
				
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
			var tmpRepeat:int = repeatLeft; //TODO fix this hack; not supposed to expose _repeat!
			play();
			_repeat = tmpRepeat;
		}
	}
}