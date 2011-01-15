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
		/**
		 * Plays the sound from where it was paused.
		 */
		function resume():void;
		
		/**
		 * Pauses the sound.
		 */
		function pause():void;
		
		/**
		 * Whether the sound is paused or not.
		 */
		function isPaused():Boolean;
		
		/**
		 * Volume.
		 */
		function get volume():Number;
		function set volume(value:Number):void;
		
		/**
		 * Pan.
		 */
		function get pan():Number;
		function set pan(value:Number):void;
		
		/**
		 * A tween that is tied into the controls.
		 * You can use it to generate cross-fading, delay playback etc.
		 *
		 * If you're planning to swap out the
		 */
		function get tween():ITween;
		function set tween(value:ITween):void;
	}
}