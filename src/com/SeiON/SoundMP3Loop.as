package com.SeiON
{
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	
	import com.SeiON.Tween.E_TweenTypes;
	
	/**
	 * Playback MP3-Loop (gapless)
	 *
	 * This source code enable sample exact looping of MP3.
	 *
	 * http://blog.andre-michelle.com/2010/playback-mp3-loop-gapless/
	 *
	 * Tested with samplingrate 44.1 KHz
	 *
	 * <code>MAGIC_DELAY</code> does not change on different bitrates.
	 * Value was found by comparision of encoded and original audio file.
	 *
	 * @author andre.michelle@audiotool.com (04/2010)
	 */
	
	/**
	 * A special type of SoundClip specially meant to create gap-less looping MP3 sounds.
	 */
	public final class SoundMP3Loop extends SoundClip
	{
		// -- Special Constants --
		private const MAGIC_DELAY:Number = 2257.0; // LAME 3.98.2 + flash.media.Sound Delay
		private const bufferSize: int = 4096; // Stable playback
		
		/** -- Sampling Variables --
		 * out: Use for output stream
		 * samplesTotal: Same as SoundProperties.samples. Local variable for faster access.
		 * samplePosition: The read-head position.
		 */
		private var out:Sound = new Sound(); // Use for output stream
		private var samplesTotal:uint = 0;
		private var samplesPosition:int = 0;
		
		public function SoundMP3Loop(manager:SoundGroup, snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean, spareAllocation:Boolean, secretKey:*)
		{
			super(manager, snd, sndProperties, autodispose, spareAllocation, secretKey);
			samplesTotal = sndProperties.samples; // make local, for faster access
		}
		
		/** Clears all references held. This object is now invalid. (ISoundClip) */
		override public function dispose():void
		{
			super.dispose();
			out = null;
		}
		
		// ---------------------------------- PROPERTIES ---------------------------------
		/** Read-only. The silence padding that's added in the MP3. In Milliseconds. */
		public function get silenceTime():Number
		{
			var fatTotal:int = samplesTotal + MAGIC_DELAY;
			var percentIsSilence:Number = MAGIC_DELAY / fatTotal;
			return sound.length * percentIsSilence;
		}
		
		/** Read-only. The total length of the clip, excluding repeats. In Milliseconds. (ISoundClip) */
		override public function get length():Number
		{
			// calculate % of actual Sample against padded Samples
			var fatTotal:int = samplesTotal + MAGIC_DELAY;
			return samplesTotal / fatTotal * sound.length;
		}
		
		/** Read-only. How far into the clip we are. In Milliseconds. (ISoundClip) */
		override public function get position():Number
		{
			return samplesPosition / samplesTotal * length;
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ---------------------------
		
		/** Plays the sound from the beginning again according to sndProperties. (ISoundClip) */
		override public function play():void
		{
			/*
			 * Adapted from SoundClip.play(), changelog:
			 *  1. Removed onRepeatPhase conditions. SoundMP3Loop repeats internally in
			 * 		sampleData(), so no tweaking of play() is necessary for repeat conditions.
			 *  2. Changed "starting up the sound" to reflect "out" variable
			 * 	3. See @@ markers
			 */
			
			stop(); // for safety's sake
			
			// starting up the sound
			out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
			soundChannel = out.play();
			
			// setting volume and panning - triggering properties to set for us
			volume = _volume;
			pan = _pan;
			
			// @@ Removed truncation code
			
			// (re)start tween animation
			_tween.play();
			
			// We won't play if our manager is paused
			if (manager.isPaused())
				pause();
		}
		
		/** Stops the sound and resets it to Zero. (ISoundClip) */
		override public function stop():void
		{
			super.stop();
			
			samplesPosition = 0;
			out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
		}
		
		/** Resumes playback of sound. (ISoundControl) */
		override public function resume():void
		{
			/*
			 * Adapted from SoundClip.resume(), changelog:
			 *  1. Changed "starting up the sound" to reflect "out" variable
			 *  2. See @@
			 *
			 * ----- Code is adapated from play()
			 */
			
			// if manager is paused, no resuming allowed!
			if (manager.isPaused())	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused())
			{
				// starting up the sound
				out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				soundChannel = out.play();
				
				// setting volume and panning - triggering properties to set for us
				volume = _volume;
				pan = _pan;
				
				// @@ removed truncation code
				
				// start tween animation
				_tween.resume();
			}
		}
		
		/** Pauses playback of sound. (ISoundControl) */
		override public function pause():void
		{
			/*
			 * Adapted from SoundClip.pause(), changelog:
			 *  1. Removed pausedLocation stuff
			 *  2. Removed soundChannel's unnecessary EventListener
			 *  3. Removed truncation stuff
			 */
			if (isPlaying())
			{
				soundChannel.stop();
				soundChannel = null;
				out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				
				_tween.pause();
			}
		}
		
		// ----------------------------- EXTRACTION AND LOOPING METHODS ---------------------
		/**
		 * Called with every extraction of sound data by SampleDataEvent.
		 */
		private function sampleData( event:SampleDataEvent ):void
		{
			/**
			 * target 	The ByteArray where to write the audio data
			 * length 	The amount of samples to be read
			 */
			var target:ByteArray = event.data;
			var length:int = bufferSize;
			
			// this code will keep reading till we obtain bufferSize amt of data. If overflow,
			// we loop to beginning and continue reading
			while( 0 < length )
			{
				// if we read the whole of length, we're gonna overshot EOF
				if( samplesPosition + length > samplesTotal )
				{
					// Hence, we read what little is left at the end of buffer.
					var read: int = samplesTotal - samplesPosition;
					
					sound.extract( target, read, samplesPosition + MAGIC_DELAY );
					samplesPosition += read; //advance read-head by amount read
					length -= read;
				}
				else // we will not overshot EOF
				{
					/* We read everything we have left (eg. the whole of 'length')
					 * Advance read-head by amount read
					 * And declare finished. (length == 0 will force function exit)
					 */
					sound.extract( target, length, samplesPosition + MAGIC_DELAY );
					samplesPosition += length;
					length = 0;
				}
				
				// We have read to EOF, wrap?
				if( samplesPosition == samplesTotal ) // END OF LOOP > WRAP
				{
					// Check repeat status
					onSoundComplete();
					
					if (isPlaying()) // Wrap
						samplesPosition = 0;
					else // Finish repeating, END
						return;
				}
			}
		}
		
		/**
		 * To be called whenever we play finish one loop
		 * @param	e	Useless
		 */
		override protected function onSoundComplete(e:Event = null):void
		{
			/*
			 * NOTE: This is adapted from super.onSoundComplete(), with the following changes:
			 * 	1. play() & associated code removed.
			 *  2. Added _tween handling, since play() no longer does it for us.
			 *
			 * After all, we only interfere if we want to end the loop. Else continue.
			 */
			if (e)	e.stopImmediatePropagation();
			
			if (repeat > 0) // repeating
			{
				if (repeat == 0) // infinite loop
				{}
				else if (--repeat == 0) // the last time
					repeat = -1;
				
				_dispatcher.dispatchEvent(new Event(SOUND_REPEAT));
				
				if (_tween.type == E_TweenTypes.CYCLIC) // repeat the tween
					_tween.play();
			}
			else // disposing
			{
				_dispatcher.dispatchEvent(new Event(Event.SOUND_COMPLETE));
				stop();
				if (autodispose)
					dispose();
			}
		}
	}
}