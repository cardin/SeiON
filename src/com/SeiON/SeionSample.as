package com.SeiON
{
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
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
	 * An ISeionInstance that plays gap-less looping MP3 sounds via specifying sample range.
	 *
	 * @see https://github.com/cardin/SeiON/wiki/Gapless-MP3-Looping
	 */
	public final class SeionSample extends SeionClip
	{
		// -- Special Constants --
		private const MAGIC_DELAY:Number = 2257.0; // LAME 3.98.2 + flash.media.Sound Delay
		private const BUFFER_SIZE: int = 4096; // Stable playback
		
		/** -- Sampling Variables --
		 * _out: Use for output stream
		 * _samplesTotal: The final position of sampling.
		 * _samplesPosition: The read-head position.
		 * _latency: Latency of playback.
		 */
		private var _out:Sound;
		private var _samplesTotal:uint = 0;
		private var _samplesPosition:int = 0;
		private var _latency:Number = 0;
		
		/** -- Playback Variables --
		 * _paused: The sound is paused.
		 */
		private var _paused:Boolean = false;
		
		/**.
		 * @inheritDoc
		 */
		public function SeionSample(secretKey:*)
		{
			super(secretKey);
		}
		
		/** The initialisation function. */
		protected static function init(ss:SeionSample, name:String, manager:SeionGroup, snd:Sound,
										sampleDuration:int, repeat:int,
										autodispose:Boolean, sndTransform:SoundTransform):void
		{
			SeionClip.init(ss, name, manager, snd, repeat, autodispose, sndTransform, 0, 0);
			ss._out = new Sound();
			
			ss._samplesTotal = sampleDuration;
		}
		
		/**
		 * Creates a soundclip that provides for gapless playback of MP3.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionSample. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	sampleDuration	The original sample duration.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionSample if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	#name
		 */
		public static function createGaplessMP3(name:String, manager:SeionGroup, snd:Sound,
						sampleDuration:int, repeat:int,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionSample
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
			var a:SeionSample = new SeionSample(SeionInstance._secretKey);
			if (manager.seion_ns::alloc(a))
			{
				SeionSample.init(a, name, manager, snd, sampleDuration, repeat, autodispose, sndTransform);
				if (autodispose)	a = null;
			}
			else
				a = null;
			
			return a;
		}
		
		// ------------------------------------- ABSTRACT ----------------------------------
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		override public function dispose():void
		{
			super.dispose();
			_out = null;
		}
		
		/** Plays the sound from the beginning again according to sndProperties. (ISeionInstance) */
		override public function play():void
		{
			/*
			 * Adapted from SeionClip.play(), changelog:
			 *  1. Removed onRepeatPhase conditions. SeionSample repeats internally in
			 * 		sampleData(), so no tweaking of play() is necessary for repeat conditions.
			 *  2. Changed "starting up the sound" to reflect "_out" variable
			 *  3. Added _paused initialisation to force isPaused() to return true.
			 * 	4. See @@ markers
			 */
			
			// Checking for dispose
			if (isDisposed())	return;
			
			stop(); // for safety's sake
			
			// @@ Removed truncation code
			
			_paused = true;
			resume();
		}
		
		/** Stops the sound and resets it to Zero. (ISeionInstance) */
		override public function stop():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			super.stop();
			_paused = false;
			
			_samplesPosition = 0;
			//if (_out) 'cos _out will nv be null, unless dispose() has been called
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
		}
		
		/** Resumes playback of sound. (ISeionControl) */
		override public function resume():void
		{
			/*
			 * Adapted from SeionClip.resume(), changelog:
			 *  1. Added _paused initialisation.
			 *  2. Changed "starting up the sound" to reflect "_out" variable
			 *  3. See @@
			 */
			
			// Checking for dispose
			if (isDisposed())	return;
			
			// if manager is paused, no resuming allowed!
			if (manager.isPaused)	return;
			
			// resume is only valid if it were paused in the 1st place
			if (isPaused)
			{
				// @@ removed truncation code
				// starting up the sound
				_samplesPosition -= _latency * 44.1 * 0.8;
				if (_samplesPosition < 0)
					_samplesPosition = 0;
				
				_out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				_sndChannel = _out.play(0, 0, soundtransform);
				
				// setting volume and panning - triggering properties to set for us
				volume = volume;
				pan = pan;
				
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
			if (isDisposed())	return;
			
			if (isPlaying)
			{
				_paused = true;
				
				_samplesPosition -= _latency * 44.1 * 0.07; //0.07 + 0.8 = 0.87
				_sndChannel.stop();
				_sndChannel = null;
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
			}
		}
		
		/**********************************************************************************
		 *	 									PROPERTIES
		 **********************************************************************************/
		
		/** The playback and decode latency. */
		public function get latency():Number
		{
			return _latency;
		}
		// ------------------------------------- ABSTRACT ----------------------------------
		
		/** Is the sound active? (ISeionInstance) */
		override public function get isPlaying():Boolean
		{
			// Checking for dispose
			if (isDisposed())	return false;
			
			return _out.hasEventListener(SampleDataEvent.SAMPLE_DATA);
		}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean
		{
			return _paused;
		}
		
		/** The total <u>sample</u> length of the clip, excluding repeats. <b>NOT</b> in
		 * milliseconds, but in samples. (ISeionInstance) */
		override public function get length():Number
		{
			return _samplesTotal;
		}
		
		/**
		 * How far into the clip we are. In Milliseconds. (ISeionInstance) <p></p>
		 * Includes offsets or truncations, eg. a 10 second sound with 5 seconds offset at
		 * starting position would report a position of 0, not 5.
		 */
		override public function get position():Number
		{
			return progress * _snd.length;
		}
		
		/**
		 * How far into the clip we are, from 0.0 - 1.0. (ISeionInstance) <p></p>
		 * <b>Warning</b>:
		 * The value may jerk around initially when sound is first played.
		 */
		override public function get progress():Number
		{
			if (_sndChannel == null && !isPaused)
				return 0;
			
			// fixing the latency caused by sampling
			var temp:Number = (_samplesPosition - (_latency * 44.1));
			if (temp < 0)
				temp += _samplesTotal;
			return temp / _samplesTotal;
		}
		
		/*********************************************************************************
		 * 								EXTRACTION AND LOOPING METHODS
		 *********************************************************************************/
		
		/**
		 * Called with every extraction of sound data by SampleDataEvent.
		 */
		private function sampleData( event:SampleDataEvent ):void
		{
			/**
			 * target 		The ByteArray where to write the audio data
			 * readLength 	The amount of samples to be read
			 */
			var target:ByteArray = event.data;
			var readLength:int = BUFFER_SIZE;
			
			// calc [and avg-ing] the latency
			if (_sndChannel)
				_latency = _latency * 19/20 + ((event.position / 44.1) - _sndChannel.position) * 1/20;
			
			// this code will keep reading till we obtain BUFFER_SIZE amt of data. If overflow,
			// we loop to beginning and continue reading
			while( 0 < readLength )
			{
				// if we read the whole of length, we're gonna overshot EOF
				if( _samplesPosition + readLength > _samplesTotal )
				{
					// Hence, we read what little is left at the end of buffer.
					var read: int = _samplesTotal - _samplesPosition;
					
					 _snd.extract( target, read, _samplesPosition + MAGIC_DELAY );
					_samplesPosition += read; //advance read-head by amount read
					readLength -= read;
				}
				else // we will not overshot EOF
				{
					/* We read everything we have left (eg. the whole of 'length')
					 * Advance read-head by amount read
					 * And declare finished. (length == 0 will force function exit)
					 */
					 _snd.extract( target, readLength, _samplesPosition + MAGIC_DELAY );
					_samplesPosition += readLength;
					readLength = 0;
				}
				// We have read to EOF, wrap?
				if( _samplesPosition == _samplesTotal ) // END OF LOOP > WRAP
				{
					// Check repeat status
					onSoundComplete();
					if (isPlaying) // Wrap
						_samplesPosition = 0;
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
			if (repeatLeft >= 0) // repeating
			{
				if (repeatLeft == 0) // infinite loop
				{}
				else if (repeatLeft == 1) // the last time
					_repeat = -1;
				
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