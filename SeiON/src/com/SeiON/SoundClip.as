package com.SeiON
{
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.greensock.TimelineMax;
	import com.greensock.TweenLite;
	
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
		protected var _tween:TimelineMax;
		private var truncation:TweenLite;
		
		/** -- Manager vars --
		 * manager: the SoundGroup that this SoundClip belongs to
		 * autodispose: If true, this SoundGroup shall be auto-disposed
		 * spareAllocation: Used by SoundManager to check if this clip was borrowed from SoundMaster
		 */
		protected var manager:SoundGroup;
		protected var autodispose:Boolean;
		internal var spareAllocation:Boolean = false;
		
		public function SoundClip(manager:SoundGroup, snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean = true)
		{
			// Flash Sound characteristics
			this.sound = snd;
			this.sndProperties = sndProperties;
			this._repeat = sndProperties.repeat;
			
			// Parent control
			this.manager = manager;
			this.autodispose = autodispose;
			
			_tween = new TimelineMax();
			_tween.stop();
			
			if (autodispose) //autodispose sounds will autoplay
				play();
		}
		
		/**
		 * Disposes.
		 */
		public function dispose():void
		{
			stop();
			
			_tween = null;
			
			// truncation.kill() alrdy done in super().dispose's stop() above
			truncation = null;
			
			sound = null;
			sndProperties.dispose();
			sndProperties = null;
			manager.killSound(this);
			manager = null;
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ----------------------------
		
		/**
		 * Plays the sound from the beginning again.
		 */
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
			truncation = TweenLite.delayedCall(playtime / 1000, onSoundComplete);
			
			// start tween animation
			_tween.restart();
			
			// We won't play if our manager is paused
			if (manager.isPaused())
				pause();
		}
		
		/**
		 * Stops the sound and resets it to Zero.
		 */
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
				if (truncation) // 'cos we call stop() before play(), so truncation == null @ this point
					truncation.kill();
				pausedLocation = -1;
				_repeat = sndProperties.repeat;
			}
		}
		
		// ISoundControl
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
		
		// ISoundControl
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
		
		// ------------------------------- CHECKING METHODS -------------------------------
		
		/**
		 * Whether the sound is playing right now.
		 */
		public function isPlaying():Boolean
		{
			if (soundChannel)
				return true;
			return false;
		}
		
		// ISoundControl
		public function isPaused():Boolean
		{
			if (pausedLocation == -1)
				return false;
			return true;
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		
		// ISoundControl
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
		
		// ISoundControl
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
		
		/**
		 * A tween that is tied into the controls. It might not be very accurate, if the sound
		 * is an external non-looping track.
		 * Use this as you would filters = []. (eg. reassign the whole TimelineMax back)
		 *
		 * NOTE: If you need to pause the tween at the specific instance, please do. The Tween
		 * will resume() instantly after you give it to SoundClip.
		 *
		 * ISoundControl
		 */
		public function get tween():TimelineMax {	return _tween; }
		public function set tween(value:TimelineMax):void
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
		 * NOTE: This is a cloned copy. Remember to call dispose() to facilitate GC disposal.
		 */
		public function get soundProperties():SoundProperties	{	return sndProperties.clone();	}
		
		/**
		 * How many more times the SoundClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore.
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