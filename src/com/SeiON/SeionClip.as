package com.SeiON
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.Core.SeionEvent;
	import com.SeiON.Core.SeionProperty;
	import com.SeiON.Misc.CountDown;
	
	/**
	 * An ISeionClip that plays sounds. SeiON's fundamental concept of a playable sound object. <p></p>
	 *
	 * It's a wrapper over both the native Sound and the SoundChannel object in Flash. It adds
	 * animation, loop and control to sound in Flash. It is managed by SeionGroup as part of
	 * SeiON's effort to control the no. of SoundChannels playing simultaneously. <p></p>
	 *
	 * Use SeionGroup's factory method createSound() to create SeionClips.
	 *
	 * @see SeionGroup
	 * @see SeionGroup#createSound()
	 * @see Seion
	 */
	public class SeionClip implements ISeionClip
	{
		/** -- Sound Assets --
		 * _name: Name of this clip, non-unique.
		 *
		 * sound: Flash Native sound object, is a memory link to a specific audio waveform
		 * soundChannel: Flash Native sound playback control, created when playing Sound objects
		 * sndProperties: The properties of the sound that we are holding
		 * _volume: Values between 0.0 - 1.0, they represent the adjustable range of the sound
		 * _pan: Values between -1.0 - 0.0, they represent the adjustable panning of the sound
		 *
		 * _dispatcher: The place to listen for events from SeionClip.
		 * _repeat: How many more times the sound has to repeat itself.
		 * pausedLocation: Where the sound was paused, so you can pause()/resume()
		 * truncation: Keeps track of where the sound will end.
		 */
		private var _name:String = "";
		/** @private */
		protected var sound:Sound; /** @private */
		protected var soundChannel:SoundChannel;
		private var sndProperties:SeionProperty; /** @private */
		protected var sndTransform:SoundTransform; /** @private */
		protected var _volume:Number = 1.0; /** @private */
		protected var _pan:Number = 0;
		
		private var _dispatcher:EventDispatcher;
		private var _repeat:int;
		private var pausedLocation:Number = -1;
		public var truncation:CountDown;
		
		/** -- Manager vars --
		 * _manager: the SeionGroup that this SeionClip belongs to
		 * _autodispose: If true, this SeionGroup shall be auto-disposed
		 */
		private var _manager:SeionGroup; /** @private */
		protected var _autodispose:Boolean; /** @private */
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionGroup.createSound().
		 *
		 * @param 	secretKey		Does nothing, just forces a reminder not to use constructor...
		 *
		 * @throws	IllegalOperationError	When you try to directly instantiate ISeionClip without
		 * using SeionGroup.createSound().
		 *
		 * @see SeionGroup#createSound()
		 */
		public function SeionClip(name:String, manager:SeionGroup, snd:Sound,
								sndProperties:SeionProperty, autodispose:Boolean, secretKey:*)
		{
			if (secretKey != manager.killSound)
				throw new IllegalOperationError("ISeionClip's constructor not allowed for direct "
				+ "access! Please use SeionClip.create() instead.");
			
			// Flash Sound characteristics
			this._name = name;
			this.sound = snd;
			this.sndProperties = sndProperties.clone();
			this.sndTransform = new SoundTransform(sndProperties.sndTransform.volume,
													sndProperties.sndTransform.pan);
			this._repeat = sndProperties.repeat;
			
			// Parent control
			this._manager = manager;
			this._autodispose = autodispose;
			
			_dispatcher = new EventDispatcher();
		}
		
		/** Clears all references held. This object is now invalid. (ISeionClip) */
		public function dispose():void
		{
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			stop();
			
			_dispatcher = null;
			
			// truncation.stop() alrdy done in dispose's stop() above
			truncation = null;
			
			sound = null;
			sndTransform = null;
			sndProperties.dispose();
			sndProperties = null;
			_manager.killSound(this);
			_manager = null;
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ----------------------------
		
		/** Plays the sound from the beginning again according to sndProperties. (ISeionClip) */
		public function play():void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
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
		
		/** Stops the sound and resets it to Zero. (ISeionClip) */
		public function stop():void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			if (isPlaying || isPaused)
			{
				if (soundChannel)
				{
					soundChannel.stop();
					soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					soundChannel = null;
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
		
		/** Resumes playback of sound. (ISeionControl) */
		public function resume():void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
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
				
				// starting up the sound
				soundChannel = sound.play(pausedLocation, 0, sndTransform);
				//if (soundChannel)
				//{
					soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					pausedLocation = -1;
				//}
				//else // the sound might be so short that it finishes before the code executes
				//	onSoundComplete();
			}
		}
		
		/** Pauses playback of sound. (ISeionControl) */
		public function pause():void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			// pause is only valid if it were playing in the 1st place
			if (isPlaying)
			{
				pausedLocation = soundChannel.position;
				soundChannel.stop();
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				soundChannel = null;
				
				truncation.pause();
			}
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		/** Name of this clip, non-unique. (ISeionClip) */
		public function get name():String	{	return _name;	}
		public function set name(value:String):void	{	_name = value;	}
		
		/** Returns the manager that holds this ISeionClip. (ISeionClip) */
		public function get manager():SeionGroup {	return _manager;	}
		
		/** Whether this sound is auto-disposable. (ISeionClip) */
		public function get autodispose():Boolean {	return _autodispose;	}
		
		/** The EventListener for listening to Event.SOUND_COMPLETE and/or SeionClip.SOUND_REPEAT.
		 * (ISeionClip) */
		public function get dispatcher():EventDispatcher {	return _dispatcher;	}
		
		/** Is the sound active? (ISeionClip) */
		public function get isPlaying():Boolean
		{
			if (soundChannel)
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
		
		/**
		 * Get: The volume as affected by its parent. <p></p>
		 * Set: The personal adjustable volume unaffected by anything. <p></p>
		 *
		 * ISeionControl
		 */
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			_volume = value;
			
			// final Volume = native Volume * current Volume * parent's volume
			sndTransform.volume = sndProperties.sndTransform.volume * _volume * _manager.volume;
			
			if (isPlaying)
				soundChannel.soundTransform = sndTransform;
		}
		
		/**
		 * Get: The panning as affected by its parent. <p></p>
		 * Set: The personal adjustable panning unaffected by anything. <p></p>
		 *
		 * ISeionControl
		 */
		public function get pan():Number {	return _pan; }
		public function set pan(value:Number):void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			_pan = value;
			
			var desiredDir:int = (_pan > 0) ? 1 : -1;
			var amtToMove:Number = (desiredDir - sndProperties.sndTransform.pan) * Math.abs(_pan);
			sndTransform.pan = amtToMove + sndProperties.sndTransform.pan;
			
			//adding on the parent's panning
			desiredDir = (_manager.pan > 0) ? 1 : -1;
			amtToMove = (desiredDir - sndTransform.pan) * Math.abs(_manager.pan);
			sndTransform.pan = amtToMove + sndTransform.pan;
			
			if (isPlaying)
				soundChannel.soundTransform = sndTransform;
		}
		
		/**
		 * Returns the predefined sound properties of the sound. <p></p>
		 *
		 * <b>NOTE:</b> You're given a cloned copy. Remember to call dispose() to facilitate GC
		 * disposal. <p></p>
		 *
		 * ISeionClip
		 */
		public function get soundproperty():SeionProperty	{	return sndProperties.clone();	}
		
		/**
		 * How many more times the ISeionClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore. <p></p>
		 *
		 * You are only allowed to set repeat values lower than or equals to the native repeat
		 * count specified in soundproperty.repeat. <p></p>
		 *
		 * ISeionClip
		 *
		 * @see	#soundproperty
		 */
		public function get repeat():int	{	return _repeat;	}
		public function set repeat(value:int):void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			if (value > sndProperties.repeat)
				value = sndProperties.repeat;
			
			_repeat = value;
		}
		
		/** The total length of the clip, excluding repeats. In Milliseconds. (ISeionClip) */
		public function get length():Number
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return 0;
			}
			
			return (sndProperties.duration == 0) ? sound.length : sndProperties.duration;
		}
		
		/** How far into the clip we are. In Milliseconds. (ISeionClip) <p></p>
		 * Includes offsets or truncated durations, eg. a 10 second sound with 5 seconds offset at
		 * starting position would report a position of 0, not 5. */
		public function get position():Number
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return 0;
			}
			
			if (isPaused)
				return pausedLocation - sndProperties.offset;
			else if (soundChannel == null) //clip not started yet
				return 0;
			return soundChannel.position - sndProperties.offset;
		}
		
		/** How far into the clip we are, from 0.0 - 1.0. (ISeionClip) <p></p>
		 * Includes offsets or truncations, eg. a 100 second sound with 5 seconds offset at
		 * starting position would report a position of 0.0, not 0.95. */
		public function get progress():Number
		{
			return position / length;
		}
		
		// -------------------------------- PRIVATE HELPER METHODS --------------------------
		/**
		 * Called when a sound completes. As for autodispose sounds, they self-dispose.
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
				_dispatcher.dispatchEvent(new SeionEvent(SeionEvent.SOUND_REPEAT, this));
			}
			else // disposing
			{
				_dispatcher.dispatchEvent(new SeionEvent(Event.SOUND_COMPLETE, this));
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