package com.SeiON
{
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	
	import com.SeiON.Core.SeionEvent;
	import com.SeiON.Core.SeionProperty;
	
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
	 * An ISeionClip that plays gap-less looping MP3 sounds.
	 *
	 * @see https://github.com/cardin/SeiON/wiki/Gapless-MP3-Looping
	 */
	public final class SeionSample extends SeionClip
	{
		// -- Special Constants --
		private const MAGIC_DELAY:Number = 2257.0; // LAME 3.98.2 + flash.media.Sound Delay
		private const bufferSize: int = 4096; // Stable playback
		
		/** -- Sampling Variables --
		 * out: Use for output stream
		 * samplesTotal: The final position of sampling.
		 * samplesPosition: The read-head position.
		 * latency: Latency of playback.
		 */
		private var out:Sound = new Sound(); // Use for output stream
		private var samplesTotal:uint = 0;
		private var samplesPosition:int = 0;
		private var _latency:Number = 0;
		
		/** -- Playback Variables --
		 * _paused: The sound is paused.
		 */
		private var _paused:Boolean = false;
		
		/**.
		 * @inheritDoc
		 */
		public function SeionSample(name:String, manager:SeionGroup, snd:Sound,
								sndProperties:SeionProperty, autodispose:Boolean, secretKey:*)
		{
			super(name, manager, snd, sndProperties, autodispose, secretKey);
			// make local, for faster access
			samplesTotal = sndProperties.duration;
		}
		
		/** Clears all references held. This object is now invalid. (ISeionClip) */
		override public function dispose():void
		{
			super.dispose();
			out = null;
		}
		
		// ---------------------------------- PROPERTIES ---------------------------------
		/** The total <u>sample</u> length of the clip, excluding repeats. <b>NOT</b> in
		 * milliseconds, but in samples. (ISeionClip) */
		override public function get length():Number
		{
			return samplesTotal;
		}
		
		/**
		 * How far into the clip we are. In Milliseconds. (ISeionClip) <p></p>
		 * Includes offsets or truncations, eg. a 10 second sound with 5 seconds offset at
		 * starting position would report a position of 0, not 5.
		 */
		override public function get position():Number
		{
			return progress * sound.length;
		}
		
		/**
		 * How far into the clip we are, from 0.0 - 1.0. (ISeionClip) <p></p>
		 * <b>Warning</b>:
		 * The value may jerk around initially when sound is first played.
		 */
		override public function get progress():Number
		{
			if (soundChannel == null && !isPaused)
				return 0;
			
			// fixing the latency caused by sampling
			var temp:Number = (samplesPosition - (_latency * 44.1));
			if (temp < 0)
				temp += samplesTotal;
			return temp / samplesTotal;
		}
		
		/** The playback and decode latency. */
		public function get latency():Number
		{
			return _latency;
		}
		
		/** Is the sound active? (ISeionClip) */
		override public function get isPlaying():Boolean
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return false;
			}
			
			return out.hasEventListener(SampleDataEvent.SAMPLE_DATA);
		}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean
		{
			return _paused;
		}
		
		// ---------------------------------- PLAYBACK CONTROLS ---------------------------
		
		/** Plays the sound from the beginning again according to sndProperties. (ISeionClip) */
		override public function play():void
		{
			/*
			 * Adapted from SeionClip.play(), changelog:
			 *  1. Removed onRepeatPhase conditions. SeionSample repeats internally in
			 * 		sampleData(), so no tweaking of play() is necessary for repeat conditions.
			 *  2. Changed "starting up the sound" to reflect "out" variable
			 *  3. Added _paused initialisation to force isPaused() to return true.
			 * 	4. See @@ markers
			 */
			
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			stop(); // for safety's sake
			
			// @@ Removed truncation code
			
			_paused = true;
			resume();
		}
		
		/** Stops the sound and resets it to Zero. (ISeionClip) */
		override public function stop():void
		{
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			super.stop();
			_paused = false;
			
			samplesPosition = 0;
			//if (out) 'cos out will nv be null, unless dispose() has been called
				out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
		}
		
		/** Resumes playback of sound. (ISeionControl) */
		override public function resume():void
		{
			/*
			 * Adapted from SeionClip.resume(), changelog:
			 *  1. Added _paused initialisation.
			 *  2. Changed "starting up the sound" to reflect "out" variable
			 *  3. See @@
			 */
			
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			// if manager is paused, no resuming allowed!
			if (manager.isPaused)	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused)
			{
				// setting volume and panning - triggering properties to set for us
				volume = _volume;
				pan = _pan;
				
				// @@ removed truncation code
				// starting up the sound
				samplesPosition -= _latency * 44.1 * 0.8;
				if (samplesPosition < 0)
					samplesPosition = 0;
				
				out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				soundChannel = out.play(0, 0, sndTransform);
				
				_paused = false;
			}
		}
		
		/** Pauses playback of sound. (ISeionControl) */
		override public function pause():void
		{
			/*
			 * Adapted from SeionClip.pause(), changelog:
			 *  1. Removed pausedLocation stuff
			 *  2. Removed soundChannel's unnecessary EventListener
			 *  3. Removed truncation stuff
			 *  4. Added _paused initialisation.
			 *  5. Added latency sampling issues
			 */
			
			// Checking for dispose
			if (manager == null)
			{
				trace("This SeionClip is already disposed, stop using this null reference!");
				return;
			}
			
			if (isPlaying)
			{
				_paused = true;
				
				samplesPosition -= _latency * 44.1 * 0.07; //0.07 + 0.8 = 0.87
				soundChannel.stop();
				soundChannel = null;
				out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
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
			
			// calc [and avg-ing] the latency
			if (soundChannel)
				_latency = _latency * 19/20 + ((event.position / 44.1) - soundChannel.position) * 1/20;
			
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
					if (isPlaying) // Wrap
						samplesPosition = 0;
					else // Finish repeating, END
						return;
				}
			}
		}
		
		/**
		 * To be called whenever we play finish one loop
		 * @param	e	Useless
		 *
		 * @private
		 */
		override protected function onSoundComplete(e:Event = null):void
		{
			/*
			 * NOTE: This is adapted from super.onSoundComplete(), with the following changes:
			 * 	1. play() & associated code removed.
			 *
			 * After all, we only interfere if we want to end the loop. Else continue.
			 */
			if (e)	e.stopImmediatePropagation();
			if (repeat >= 0) // repeating
			{
				if (repeat == 0) // infinite loop
				{}
				else if (repeat == 1) // the last time
					repeat = -1;
				
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
	}
}