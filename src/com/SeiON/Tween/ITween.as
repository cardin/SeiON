package com.SeiON.Tween
{
	/**
	 * Represents a unified interface for handling Tweening objects. This allows users to opt out of
	 * using the GreenSock TimelineLite classes for animation.
	 */
	public interface ITween
	{
		/** Destroys/disposes of the tween. (ITween) */
		function dispose():void;
		
		/** Sets the tweening behaviour type to be used for ISoundClip. (ITween) */
		function get type():E_TweenTypes;
		function set type(value:E_TweenTypes):void;
		
		/** Plays the Tween forward from the beginning. (ITween) */
		function play():void;
		/** Stops playing and returns to the beginning. (ITween) */
		function stop():void;
		
		/** Pauses the Tween. (ITween) */
		function pause():void;
		/** Resumes the Tween forward. (ITween) */
		function resume():void;
		
		/** The position it is at, not counting repeats. In Milliseconds. (ITween) */
		function get position():Number;
		function set position(value:Number):void;
	}
}