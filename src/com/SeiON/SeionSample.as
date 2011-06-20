package com.SeiON
{
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	
	import com.SeiON.Event.SeionEvent;
	import com.SeiON.Core.SeionInstance;
	import com.SeiON.Core.seion_ns;
	
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
	 * An ISeionInstance that plays gap-less looping MP3 sounds via specifying sample range. It is
	 * more intensive than SeionClip, but perhaps not perceivably so.
	 *
	 * @see https://github.com/cardin/SeiON/wiki/Gapless-MP3-Looping
	 */
	public final class SeionSample extends SeionInstance
	{
		// -- Special Constants --
		private const MAGIC_DELAY:Number = 2257.0; // LAME 3.98.2 + flash.media.Sound Delay
		private const BUFFER_SIZE: int = 4096; // Stable playback
		
		/** -- Sampling Variables --
		 * _out: Use for output stream
		 * _samplesTotal: The final position of sampling.
		 * _samplePosition: The read-head position.
		 * _latency: Latency of playback.
		 */
		private var _out:Sound;
		private var _samplesTotal:uint = 0;
		private var _samplePosition:int = 0;
		private var _latency:Number = 0;
		
		/** -- Playback Variables --
		 * _paused: Whether the sound is paused.
		 */
		private var _paused:Boolean = false;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionSample.create().
		 *
		 * @see SeionSample#create()
		 */
		public function SeionSample(secretKey:*) {	super(secretKey);	}
		
		/** The initialisation function. */
		private static function init(ss:SeionSample, name:String, manager:SeionGroup, snd:Sound,
										sampleDuration:int, repeat:int,
										autodispose:Boolean, sndTransform:SoundTransform):void
		{
			ss._out = new Sound();
			ss._samplesTotal = sampleDuration;
			
			SeionInstance.init(ss, name, manager, snd, repeat, autodispose, sndTransform);
		}
		
		/**
		 * Creates a soundclip that provides for gapless playback of MP3.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionSample. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	sampleDuration	The original sample duration.
		 * @param	repeat			How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionSample if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	SeionInstance#name
		 * @see #length
		 * @see SeionInstance#autodispose
		 * @see SeionInstance#soundtransform
		 */
		public static function createGaplessMP3(name:String, manager:SeionGroup, snd:Sound,
						sampleDuration:int, repeat:int,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionSample
		{
			/**
			 * Create empty hull of a SeionSample.
			 * Try to allocate the sound in manager.
			 * If successful
			 * 		Initiate the SeionSample
			 * 		Check if it's autodisposable
			 *
			 * Return the clip (if any).
			 */
			var a:SeionSample = new SeionSample(SeionInstance._secretKey);
			if (manager.seion_ns::alloc(a, autodispose))
			{
				SeionSample.init(a, name, manager, snd, sampleDuration, repeat, autodispose,
								sndTransform);
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
			// Checking for dispose
			if (isDisposed())	return;
			
			stop();
			_out = null;
			
			_manager.seion_ns::killSound(this);
			super.dispose();
		}
		
		/** Plays the sound from the beginning again. (ISeionInstance) */
		override public function play():void
		{
			stop(); // to go to the beginning
			_paused = true; // to trigger resume
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
					_sndChannel = null;
				}
				
				repeat = repeat; // to reset repeatLeft to the full repeat value
				_paused = false;
				_samplePosition = 0;
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
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
				// ------ Starting up the sound
				// adjusting playback position for latency
				_samplePosition -= _latency * 44.1 * 0.8;
				if (_samplePosition < 0)
					_samplePosition = 0;
				
				_out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				_sndChannel = _out.play(0, 0, _sndTransform);
				_paused = false;
			}
		}
		
		/** Pauses playback of sound. (ISeionControl) */
		override public function pause():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			if (isPlaying)
			{
				_paused = true;
				
				_samplePosition -= _latency * 44.1 * 0.07; //0.07 + 0.8 = 0.87
				_sndChannel.stop();
				_sndChannel = null;
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
			}
		}
		
		/**********************************************************************************
		 *	 									PROPERTIES
		 **********************************************************************************/
		
		/** The playback and decode latency. */
		public function get latency():Number	{	return _latency;	}
		
		// ------------------------------------- ABSTRACT ----------------------------------
		
		/** Is the sound active? (ISeionInstance) */
		override public function get isPlaying():Boolean
		{
			// Checking for dispose
			if (isDisposed())	return false;
			return _out.hasEventListener(SampleDataEvent.SAMPLE_DATA);
		}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean	{	return _paused;	}
		
		/** The total <u>sample</u> length of the clip, excluding repeats. (ISeionInstance) */
		override public function get length():Number	{	return _samplesTotal;	}
		
		/** How far into the clip we are. In samples. (ISeionInstance) */
		override public function get position():Number	{	return progress * length;	}
		
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
			var temp:Number = (_samplePosition - (_latency * 44.1));
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
				if( _samplePosition + readLength > _samplesTotal )
				{
					// Hence, we read what little is left at the end of buffer.
					var read: int = _samplesTotal - _samplePosition;
					
					_snd.extract( target, read, _samplePosition + MAGIC_DELAY );
					_samplePosition += read; //advance read-head by amount read
					readLength -= read;
				}
				else // we will not overshot EOF
				{
					/* We read everything we have left (eg. the whole of 'length')
					 * Advance read-head by amount read
					 * And declare finished. (length == 0 will force function exit)
					 */
					 _snd.extract( target, readLength, _samplePosition + MAGIC_DELAY );
					_samplePosition += readLength;
					readLength = 0;
				}
				
				if( _samplePosition == _samplesTotal ) // We have read to EOF, wrap?
				{
					// Check repeat status
					if (onSoundComplete())
						_samplePosition = 0; // Wrap
					else
						return; // Finish repeating, END
				}
			}
		}
		
		/**
		 * To be called whenever we play finish one loop.
		 * @return	Whether the sound should continue looping
		 */
		private function onSoundComplete():Boolean
		{
			if (repeatLeft > 0 || repeatLeft == -1) // -1 is infinite, 0 is no repeat
			{
				if (repeatLeft != -1)
					_repeatLeft --;
				
				dispatchEvent(new SeionEvent(SeionEvent.SOUND_REPEAT, this));
				return true;
			}
			else // no more repeats
			{
				if (autodispose)
					dispose();
				else
				{
					stop();
					dispatchEvent(new SeionEvent(Event.SOUND_COMPLETE, this));
				}
			}
			return false;
		}
	}
}