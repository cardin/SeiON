package com.SeiON.Tween
{
	/**
	 * Represents a unified interface for handling Tweening objects. This allows users to opt out of
	 * using the GreenSock TimelineLite classes for animation.
	 */
	public interface ITween
	{
		/**
		 * Destroys/disposes of the tween.
		 */
		function dispose():void;
		
		/**
		 * Plays/Stops/Restarts the Tween from the beginning.
		 */
		function play():void;
		function stop():void;
		function restart():void;
		
		/**
		 * Pauses/Resumes the Tween.
		 */
		function pause():void;
		function resume():void;
	}
}