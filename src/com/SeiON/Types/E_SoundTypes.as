package com.SeiON.Types
{
<<<<<<< HEAD
	import com.SeiON.SoundClip;
	import com.SeiON.SoundMP3Loop;
=======
>>>>>>> parent of 1ae3953... Removed duplicate folders
	import com.SeiON.Misc.Enumerable;
	
	public class E_SoundTypes extends Enumerable
	{
		/** A normal non-looping sound. */
		public static const NON_LOOP:E_SoundTypes = new E_SoundTypes();
		/** A non-MP3 looping sound. */
		public static const LOOP:E_SoundTypes = new E_SoundTypes();
		/** An MP3 looping sound. */
		public static const MP3_LOOP:E_SoundTypes = new E_SoundTypes();
		
<<<<<<< HEAD
		internal static var _cls:Class;
		
		{
			initEnum(E_SoundTypes);
			
			NON_LOOP._cls = LOOP._cls = SoundClip;
			MP3_LOOP._cls = SoundMP3Loop;
		}
		
		/**
		 * Returns a reference to the ISoundClip class that best represents it.
		 */
		public function get clsRef():Class
		{
			return _cls;
=======
		{
			initEnum(E_SoundTypes);
>>>>>>> parent of 1ae3953... Removed duplicate folders
		}
	}
}