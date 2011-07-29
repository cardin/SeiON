package com.SeiON
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	import com.SeiON.Core.CountDown;
	import com.SeiON.Core.SeionInstance
	import com.SeiON.Core.seion_ns;
	import com.SeiON.Event.SeionEvent;
	import com.SeiON.SeionGroup;
	
	use namespace seion_ns;
	
	/**
	 * The simplest way to play a sound. <p></p>
	 *
	 * SeionClip is a simple wrapper over both the native Sound and the _sndChannel object in
	 * Flash. Use SeionClip.create() to instantiate this class.
	 *
	 * @see #create()
	 */
	public final class SeionClip extends SeionInstance
	{
		/**
		 * _offset:		The delayed starting position.
		 * _truncate:	The truncation from the ending position.
		 *
		 * _pausedLocation:	Where the _snd was paused, so you can pause()/resume()
		 * _truncation:		Keeps track of where the _snd will end.
		 */
		private var _offset:uint;
		private var _truncate:uint;
		
		private var _pausedLocation:Number = -1;
		private var _truncation:CountDown;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionClip.create().
		 *
		 * @see SeionClip#create()
		 */
		public function SeionClip(secretKey:*) {	super(secretKey);	}
		
		/** The initialisation function. @private */
		private static function init(sc:SeionClip, name:String, manager:SeionGroup, snd:Sound,
									repeat:int,	autodispose:Boolean, sndTransform:SoundTransform,
									offset:uint, truncate:uint):void
		{
			sc._offset = offset;
			sc._truncate = truncate;
			
			SeionInstance.init(sc, name, manager, snd, repeat, autodispose, sndTransform);
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
		 * @see	SeionInstance#name
		 * @see	SeionInstance#repeat
		 * @see	SeionInstance#soundtransform
		 * @see	SeionInstance#autodispose
		 */
		public static function create(name:String, manager:SeionGroup, snd:Sound, repeat:int = 0,
					autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionClip
		{
			return createExcerpt(name, manager, snd, repeat, 0, 0, autodispose, sndTransform);
		}
		
		/**
		 * Creates a sound clip that can be shortened.
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
		 * @see	SeionInstance#name
		 * @see	SeionInstance#repeat
		 * @see	SeionInstance#soundtransform
		 * @see	SeionInstance#autodispose
		 * @see	#offset
		 * @see	#truncate
		 */
		public static function createExcerpt(name:String, manager:SeionGroup, snd:Sound, repeat:int,
						offset:uint, truncate:uint,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionClip
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
			if (manager.alloc(a, autodispose))
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
			
			_manager.killSound(this);
			super.dispose();
		}
		
		/*******************************************************************************
		 * 									PLAYBACK CONTROLS
		 *******************************************************************************/
		//  ----------------------------------- Abstract -------------------------------
		
		/** Plays the sound from the beginning again. (ISeionInstance) */
		override public function play():void
		{
			stop(); // to go to the beginning
			
			// if there is no offset/truncate, set countdown(0)
			_truncation = new CountDown((this.length == _snd.length) ? 0 : this.length);
			_pausedLocation = _offset;
			resume(); // 'cos play() is essentially resume() from 0
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
				
				_pausedLocation = -1;
				repeat = repeat;
			}
		}
		
		/** Resumes playback of sound. (ISeionControl) */
		override public function resume():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// Resume only if Manager not paused && this clip was paused
			if (!manager.isPaused && isPaused)
			{
				// resuming _truncation
				_truncation.addEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
				if (_truncation.paused)
					_truncation.resume();
				else
					_truncation.start(); // for when resume() was called by play()
				
				_sndChannel = _snd.play(_pausedLocation, 0, _sndTransform);
				_sndChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				_pausedLocation = -1;
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
				_pausedLocation = _sndChannel.position % _snd.length;
				_sndChannel.stop();
				_sndChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				_sndChannel = null;
				
				_truncation.pause();
				_truncation.removeEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
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
		override public function get isPlaying():Boolean	{	return _sndChannel != null;	}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean	{	return _pausedLocation != -1;	}
		
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
			
			if (isPlaying)
				return _sndChannel.position - _offset;
			else if (isPaused)
				return _pausedLocation - _offset;
			else
				return 0;
		}
		
		/** How far into the clip we are, from 0.0 - 1.0. (ISeionInstance) <p></p>
		 *
		 * Includes offsets or truncations, eg. a 100 second _snd with 5 seconds offset at
		 * starting position would report a position of 0.0, not 0.95. */
		override public function get progress():Number	{	return position / length;	}
		
		/***********************************************************************************
		 *	 								PRIVATE HELPER METHODS
		 ***********************************************************************************/
		
		/**
		 * Called when a Sound completes. As for autodispose _snds, they self-dispose.
		 *
		 * @param	e	Called by either _truncation's TIMER_COMPLETE or soundChannel's
		 * SOUND_COMPLETE.
		 */
		private function onSoundComplete(e:Event):void
		{
			e.stopImmediatePropagation();
			
			if (repeatLeft > 0 || repeatLeft == -1) // repeating
			{
				if (repeatLeft != -1)
					_repeatLeft --;
				
				// resetting variables back to beginning
				_sndChannel.stop();
				_pausedLocation = _offset;
				_truncation.stop();
				resume();
				
				dispatchEvent(new SeionEvent(SeionEvent.SOUND_REPEAT, this));
			}
			else // disposing
			{
				if (autodispose)
					dispose();
				else
				{
					stop();
					dispatchEvent(new SeionEvent(Event.SOUND_COMPLETE, this));
				}
			}
		}
	}
}