package com.SeiON.Types
{
	import com.SeiON.Misc.Enumerable;
	
	public class E_SoundTypes extends Enumerable
	{
		/** A normal non-looping sound. */
		public static const NON_LOOP:E_SoundTypes = new E_SoundTypes();
		/** A non-MP3 looping sound. */
		public static const LOOP:E_SoundTypes = new E_SoundTypes();
		/** An MP3 looping sound. */
		public static const MP3_LOOP:E_SoundTypes = new E_SoundTypes();
		
		{
			initEnum(E_SoundTypes);
		}
	}
}