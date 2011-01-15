package com.SeiON
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.Misc.CountDown;
	import com.SeiON.Tween.ITween;
	
	/**
	 * Our Audio Library's fundamental concept of a playable sound object. Contains internal
	 * reference to a flash Sound object.
	 *
	 * Can be created with a specific delay or offset.
	 */
	public class SoundClip implements ISoundControl
	{
		/** -- Sound Assets --
		 * sound: Flash Native sound object, is a memory link to a specific audio waveform
		 * soundChannel: Flash Native sound playback control, created when playing Sound objects
		 * sndProperties: The properties of the sound that we are holding
		 * _volume: Values between 0.0 - 1.0, they represent the adjustable range of the sound
		 * _pan: Values between -1.0 - 0.0, they represent the adjustable panning of the sound
		 *
		 * _repeat: How many more times the sound has to repeat itself.
		 * pausedLocation: Where the sound was paused, so you can pause()/resume()
		 * _tween: For animation of sound properties
		 * truncation: Keeps track of where the sound will end.
		 */
		protected var sound:Sound;
		protected var soundChannel:SoundChannel;
		private var sndProperties:SoundProperties;
		protected var _volume:Number = 1.0;
		protected var _pan:Number = 0;
		
		private var _repeat:int;
		private var pausedLocation:Number = -1;
		protected var _tween:ITween;
		private var truncation:CountDown;
		
		/** -- Manager vars --
		 * manager: the SoundGroup that this SoundClip belongs to
		 * autodispose: If true, this SoundGroup shall be auto-disposed
		 * spareAllocation: Used by SoundManager to check if this clip was borrowed from SoundMaster
		 */
		protected var manager:SoundGroup;
		protected var autodispose:Boolean;
		private var _spareAllocation:Boolean;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SoundMaster.createSoundGroup().
		 *
		 * @param 	secretKey		Does nothing, just forces a reminder not to use constructor...
		 *
		 * @throws	IllegalOperationError	When you try to directly instantiate ISoundClip without
		 * using SoundGroup.createSound().
		 *
		 * @see SoundGroup.createSound()
		 */
		public function SoundClip(manager:SoundGroup, snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean, spareAllocation:Boolean, secretKey:*)
		{
			if (secretKey != manager.killSound)
				throw new IllegalOperationError("ISoundClip's constructor not allowed for direct "
				+ "access! Please use SoundGroup.createSound() instead."
			
			// Flash Sound characteristics
			this.sound = snd;
			this.sndProperties = sndProperties;
			this._repeat = sndProperties.repeat;
			
			// Parent control
			this.manager = manager;
			this.autodispose = autodispose;
			this._spareAllocation = spareAllocation;
			
			_tween = new SoundMaster.tweenCls() as ITween;
			_tween.play();
			
			if (autodispose) //autodispose sounds will autoplay
				play();
		}
		
		/** Clears all references held. This object is now invalid. (ISoundClip) */
		public function dispose():void
		{
			stop();
			
			_tween.dispose();
			_tween = null;
			
			// truncation.stop() alrdy done in super().dispose's stop() above
			truncation = null;
			
			sound = null;
			sndProperties.dispose();
			sndProperties = null;
			manager.killSound(this);
			manager = null;
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ----------------------------
		
		/** Plays the sound from the beginning again. (ISoundClip) */
		public function play():void
		{
			stop(); // for safety's sake
			// starting up the sound
			soundChannel = sound.play(sndProperties.offset, 0);
			soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			
			// setting volume and panning - triggering properties to set for us
			volume = _volume;
			pan = _pan;
			
			// setting up truncation
			var playtime:Number = sound.length - sndProperties.offset - sndProperties.truncate;
			truncation = new CountDown(playtime);
			truncation.addEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
			
			// start tween animation
			_tween.restart();
			
			// We won't play if our manager is paused
			if (manager.isPaused())
				pause();
		}
		
		/** Stops the sound and resets it to Zero. (ISoundClip) */
		public function stop():void
		{
			if (isPlaying() || isPaused())
			{
				if (soundChannel)
				{
					soundChannel.stop();
					soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					soundChannel = null;
				}
				// reset variables
				if (truncation) // 'cos we call stop() before play(), so possibly truncation == null @ this point
				{
					truncation.stop();
					truncation.removeEventListener(TimerEvent.TIMER_COMPLETE, onSoundComplete);
				}
				_tween.stop();
				
				pausedLocation = -1;
				_repeat = sndProperties.repeat;
			}
		}
		
		/** Resumes playback of sound. (ISoundControl) */
		public function resume():void
		{
			// ----- Code is adapated from play()
			
			// if manager is paused, no resuming allowed!
			if (manager.isPaused())	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused())
			{
				// starting up the sound
				soundChannel = sound.play(pausedLocation, 0);
				soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				pausedLocation = -1;
				
				// setting volume and panning - triggering properties to set for us
				volume = _volume;
				pan = _pan;
				
				// resuming truncation
				truncation.resume();
				
				// start tween animation
				_tween.resume();
			}
		}
		
		/** Pauses playback of sound. (ISoundControl) */
		public function pause():void
		{
			if (isPlaying())
			{
				pausedLocation = soundChannel.position;
				soundChannel.stop();
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				soundChannel = null;
				
				truncation.pause();
				_tween.pause();
			}
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		
		/**
		 * Used by SoundManager to check if this clip was borrowed from SoundMaster.
		 *
		 * ISoundClip
		 */
		public function get spareAllocation():Boolean
		{
			return _spareAllocation;
		}
		
		/** Is the sound active? (ISoundControl) */
		public function isPlaying():Boolean
		{
			if (soundChannel)
				return true;
			return false;
		}
		
		/** Is the playback paused? (ISoundControl) */
		public function isPaused():Boolean
		{
			if (pausedLocation == -1)
				return false;
			return true;
		}
		
		/**
		 * Get: The volume as affected by SoundGroup (parent).
		 * Set: The personal adjustable volume unaffected by anything.
		 *
		 * ISoundControl
		 */
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void
		{
			_volume = value;
			if (isPlaying())
			{
				var st:SoundTransform = soundChannel.soundTransform;
				
				// final Volume = native Volume * current Volume * parent's volume
				st.volume = sndProperties.sndTransform.volume * _volume * manager.volume;
				soundChannel.soundTransform = st;
			}
		}
		
		/**
		 * Get: The panning as affected by SoundGroup (parent).
		 * Set: The personal adjustable panning unaffected by anything.
		 *
		 * ISoundControl
		 */
		public function get pan():Number {	return _pan; }
		public function set pan(value:Number):void
		{
			_pan = value;
			
			if (isPlaying())
			{
				var st:SoundTransform = soundChannel.soundTransform;
				
				var desiredDir:int = (_pan > 0) ? 1 : -1;
				var amtToMove:Number = (desiredDir - sndProperties.sndTransform.pan) * Math.abs(_pan);
				st.pan = amtToMove + sndProperties.sndTransform.pan;
				
				//adding on the parent's panning
				desiredDir = (manager.pan > 0) ? 1 : -1;
				amtToMove = (desiredDir - st.pan) * Math.abs(manager.pan);
				st.pan = amtToMove + st.pan;
				
				soundChannel.soundTransform = st;
			}
		}
		
		/** The animation pegged to playback. (ISoundControl) */
		public function get tween():ITween {	return _tween; }
		public function set tween(value:ITween):void
		{
			_tween = value;
			if (isPaused())
				_tween.pause();
			else
				_tween.resume();
		}
		
		/**
		 * Returns the sound properties of the sound. Eg. Full Repeat times, offset, truncate.
		 *
		 * NOTE: You're given a cloned copy. Remember to call dispose() to facilitate GC disposal.
		 *
		 * ISoundClip
		 */
		public function get soundProperties():SoundProperties	{	return sndProperties.clone();	}
		
		/**
		 * How many more times the SoundClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore.
		 *
		 * ISoundClip
		 */
		public function get repeat():int	{	return _repeat;	}
		public function set repeat(value:int):void
		{
			if (value > sndProperties.repeat)
				value = sndProperties.repeat;
			
			_repeat = value;
		}
		
		// -------------------------------- PRIVATE HELPER METHODS --------------------------
		/**
		 * Called when a sound completes. As for autodispose sounds, they self-dispose.
		 *
		 * @param	e	Not important. e == null when truncation cuts it short, else this function
		 * 				was called by Event.SOUND_COMPLETE.
		 */
		protected function onSoundComplete(e:Event = null):void
		{
			if (repeat > 0) // repeating
			{
				var tempRepeatTrack:int = -- repeat;
				if (tempRepeatTrack == 0)	tempRepeatTrack = -1; // the last time
				
				play();
				repeat = tempRepeatTrack; // 'cos play() resets the repeat variable
			}
			else if (repeat == 0) // infinite loop
				play();
			else // disposing
			{
				stop();
				if (autodispose)
					dispose();
			}
		}
	}
}