package com.SeiON
{
	import com.SeiON.Tween.ITween;
	
	/**
	 * Basic features that a sound object should have.
	 *
	 * NOTE TO SELF: I doubt this interface is actually useful beyond templating. But this
	 * template is very important in defining the basic features of each level of sound control.
	 * So DO NOT delete this interface during refactoring!!
	 */
	public interface ISoundControl
	{
		/** Resumes playback of sound. (ISoundControl) */
		function resume():void;
		
		/** Pauses playback of sound. (ISoundControl) */
		function pause():void;
		
		/** Is the playback paused? (ISoundControl) */
		function isPaused():Boolean;
		
		/**
		 * Get: The volume as affected by its parent.
		 * Set: The personal adjustable volume unaffected by anything.
		 *
		 * ISoundControl
		 */
		function get volume():Number;
		function set volume(value:Number):void;
		
		/**
		 * Get: The panning as affected by its parent.
		 * Set: The personal adjustable panning unaffected by anything.
		 *
		 * ISoundControl
		 */
		function get pan():Number;
		function set pan(value:Number):void;
		
		/** The animation pegged to playback. (ISoundControl) */
		function get tween():ITween;
		function set tween(value:ITween):void;
	}
}