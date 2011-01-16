package com.SeiON.Tween
{
	import com.SeiON.Misc.Enumerable;
	
	/**
	 * The kind of tweening behaviour that ITween will follow. This choice applies only to ISoundClips.
	 */
	public class E_TweenTypes extends Enumerable
	{
		/** Repeats itself as ISoundClip repeats itself. */
		public static const CYCLIC:E_TweenTypes = new E_TweenTypes();
		/** It will only repeat if ISoundClip 'restarts', otherwise it will continue playing through
		 * all of ISoundClip's loops unaffected. */
		public static const LINEAR:E_TweenTypes = new E_TweenTypes();
		
		{
			initEnum(E_TweenTypes);
		}
		
	}

}