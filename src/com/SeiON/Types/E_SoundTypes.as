package com.SeiON.Types
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	
	import com.SeiON.SoundClip;
	import com.SeiON.SoundMP3Loop;
	import com.SeiON.Misc.Enumerable;
	
	public class E_SoundTypes extends Enumerable
	{
		/** A normal non-looping sound. */
		public static const NON_LOOP:E_SoundTypes = new E_SoundTypes();
		/** A non-MP3 looping sound. */
		public static const LOOP:E_SoundTypes = new E_SoundTypes();
		/** An MP3 looping sound. */
		public static const MP3_LOOP:E_SoundTypes = new E_SoundTypes();
		
		private var _cls:String;
		
		{
			initEnum(E_SoundTypes);
			
			NON_LOOP._cls = LOOP._cls = getQualifiedClassName(SoundClip);
			MP3_LOOP._cls = getQualifiedClassName(SoundMP3Loop);
			
		}
		
		/**
		 * Returns a reference to the ISoundClip class that best represents it.
		 */
		public function get clsRef():Class
		{
			return getDefinitionByName(_cls) as Class;
		}
	}
}