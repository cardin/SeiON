package com.SeiON
{
	import flash.media.SoundTransform;
	
	import com.SeiON.Types.E_SoundTypes;
	
	/**
	 * Defines the properties of a particular sound instance.
	 * Eg:
	 * - offset, truncation
	 * - panning, volume
	 *
	 * Imagine this to be the MP3 id tags that defines the sound, without incurring the memory
	 * overhead of actually having a Sound instance (because we use Class object).
	 */
	public final class SoundProperties
	{
		private var _name:String;
		private var _repeat:int, _samples:uint;
		private var _offset:uint, _truncate:uint;
		private var _soundTransform:SoundTransform;
		
		/**
		 * Please do not call this constructor directly.
		 */
		public function SoundProperties(name:String, soundTransform:SoundTransform = null,
						repeat:int = -1, samples:uint = 0, offset:uint = 0, truncate:uint = 0)
		{
			_name = name;
			_repeat = repeat;
			_samples = samples;
			_offset = offset;
			_truncate = truncate;
			_soundTransform = (_soundTransform == null) ? new SoundTransform() : _soundTransform;
		}
		
		/**
		 * Clones another SoundProperties to use. Might be especially pertinent to SoundClip, as
		 * it disposes the SoundProperties that is passed in.
		 *
		 * @return	A deep copy of all members of SoundProperties.
		 */
		public function clone():SoundProperties
		{
			return new SoundProperties(_name, new SoundTransform(_soundTransform.volume,
								_soundTransform.volume), _repeat, _samples, _offset, _truncate);
		}
		
		/**
		 * Disposes.
		 */
		public function dispose():void
		{
			_soundTransform = null;
		}
		
		/**
		 * Creates properties for a looping sound. Looping sounds only has repeat, no offset or
		 * truncation. This should NEVER be an MP3 file.
		 *
		 * @param	repeat		Put 0 to get infinite loop
		 */
		public static function makeLoop(name:String, repeat:int = 0,
											soundTransform:SoundTransform = null):SoundProperties
		{
			var sp:SoundProperties = new SoundProperties(name, soundTransform, repeat);
			return sp;
		}
		
		/**
		 * Defines a LAME MP3 looping sound. To achieve gapless looping MP3 we need the sample
		 * number.
		 *
		 * @param	samples		The total number of samples the loop is originally composed of.
		 * Discovered in Audacity. Sound must be LAME encoded!!!!
		 * @param	repeat		Put 0 to get infinite loop
		 */
		public static function makeMP3Loop(name:String, samples:uint, repeat:int = 0,
											soundTransform:SoundTransform = null):SoundProperties
		{
			var sp:SoundProperties = new SoundProperties(name, soundTransform, repeat, samples);
			return sp;
		}
		
		/**
		 * Defines a standard non-looping sound clip. This should not be an MP3 file if you need
		 * to truncate or offset.
		 *
		 * @param	offset		The late starting point of the clip. In Milliseconds.
		 * @param	truncate	The early termination point of the clip. In Milliseconds.
		 */
		public static function makeClip(name:String, offset:uint = 0, truncate:uint = 0,
										soundTransform:SoundTransform = null):SoundProperties
		{
			var sp:SoundProperties = new SoundProperties(name, soundTransform, -1, 0, offset,
														truncate);
			return sp;
		}
		
		/** Name of the sound, for trivial identification purposes only. */
		public function get name():String	{	return _name;	}
		
		/** The number of times this sound should repeat itself. */
		public function get repeat():int	{	return _repeat;	}
		
		/** A fixed amount of time to advance before starting the sound. In Milliseconds. */
		public function get offset():uint	{	return _offset;	}
		
		/** A fixed amount of time to end the sound prematurely. In Milliseconds. */
		public function get truncate():uint	{	return _truncate;	}
		
		/** The number of samples that the sound has. */
		public function get samples():uint	{	return _samples;	}
		
		/** The additional 'natural' panning/volume of the sound. */
		public function get sndTransform():SoundTransform	{	return _soundTransform;	}
		
		/**
		 * Returns most appropriate description of this SoundProperty.
		 */
		public function get soundType():E_SoundTypes
		{
			if (repeat == -1)
				return E_SoundTypes.NON_LOOP;
			else if (samples != 0)
				return E_SoundTypes.MP3_LOOP;
			else
				return E_SoundTypes.LOOP;
		}
	}
}