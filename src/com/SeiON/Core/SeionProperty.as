package com.SeiON.Core
{
	import flash.media.SoundTransform;
	
	/**
	 * Defines the properties of a particular sound instance.
	 * Eg:
	 * <ul>
	 * <li>offset, truncated duration</li>
	 * <li>panning, volume</li>
	 * </ul>
	 *
	 * SeionProperty is meant to further redefine a sound source so that it plays differently.
	 * Hence a single sound source can be played differently just by attaching different
	 * SeionProperties to them.
	 */
	public final class SeionProperty
	{
		/** Name of this property. */
		public var name:String;
		/** The no. of times to repeat. -1 means no repeat, 0 means infinite repeats. */
		public var repeat:int;
		/** The late starting point of the clip. In Milliseconds or Samples. */
		public var offset:uint;
		/** The duration of the clip starting from offset. In Milliseconds or Samples. */
		public var duration:uint;
		/** The SoundTransform. */
		public var sndTransform:SoundTransform;
		private var _isMilliSeconds:Boolean;
		
		/**
		 * Please do not call this constructor directly. Use one of the SeionProperty.makeXXXX()
		 * static methods instead.
		 *
		 * @see #makeClip()
		 * @see #makeMP3Gapless()
		 */
		public function SeionProperty(name:String, soundTransform:SoundTransform = null,
									repeat:int = -1, offset:uint = 0, duration:uint = 0,
									isMS:Boolean = true)
		{
			this.name = name;
			this.repeat = repeat;
			this.offset = offset;
			this.duration = duration;
			this.sndTransform = (soundTransform == null) ? new SoundTransform() : soundTransform;
			this._isMilliSeconds = isMS;
		}
		
		/**
		 * Clones itself. Might be especially pertinent to ISeionClip, as it disposes the
		 * SeionProperty that is passed in.
		 *
		 * @return	A deep copy of all members of SeionProperty.
		 */
		public function clone():SeionProperty
		{
			return new SeionProperty(name, new SoundTransform(sndTransform.volume,
								sndTransform.pan), repeat, offset, duration, _isMilliSeconds);
		}
		
		/** Clears all references held. This object is now invalid. */
		public function dispose():void
		{
			sndTransform = null;
		}
		
		// ---------------------------------- CREATION METHODS ------------------------------
		/**
		 * Defines a standard sound clip.
		 *
		 * @param	name		A random name. It doesn't even have to be unique. :)
		 * @param	repeat		-1 means no looping. 0 means infinite loop.
		 * @param	offset		The late starting point of the clip. In Milliseconds.
		 * @param	duration	The duration of the clip starting from offset. In Milliseconds.
		 * If 0, means that the duration shall be from offset to end of the clip.
		 * @param	soundTransform	The SoundTransform you want the sound to adopt.
		 */
		public static function makeClip(name:String, repeat:int = -1, offset:uint = 0, duration:uint = 0,
										soundTransform:SoundTransform = null):SeionProperty
		{
			return new SeionProperty(name, soundTransform, repeat, offset, duration);
		}
		
		/**
		 * Defines a LAME MP3 gapless sound. Avoid using this - use makeClip instead as it is less
		 * taxing on the Flash Player, unless you really require gapless MP3 looping.
		 *
		 * @param	name		A random name. It doesn't even have to be unique. :)
		 * @param	samples		The total number of samples the loop is originally composed of.
		 * @param	repeat		-1 means no looping. 0 means infinite loop.
		 * Discovered in Audacity. Sound must be LAME encoded!!!!
		 * @param	soundTransform	The SoundTransform you want the sound to adopt.
		 *
		 * @see https://github.com/cardin/SeiON/wiki/Gapless-MP3-Looping
		 */
		public static function makeMP3Gapless(name:String, samples:uint, repeat:int = 0,
								soundTransform:SoundTransform = null):SeionProperty
		{
			if (samples == 0)
				throw new ArgumentError("samples cannot be 0");
			
			return new SeionProperty(name, soundTransform, repeat, 0, samples, false);
		}
		
		// -------------------------------- PROPERTIES -------------------------------
		/** Whether the time is measured in terms of MilliSeconds or Samples. */
		public function get isMilliseconds():Boolean
		{
			return _isMilliSeconds;
		}
	}
}