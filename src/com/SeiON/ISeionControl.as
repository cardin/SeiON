package com.SeiON
{
	/**
	 * Basic features that a sound manipulating object should have.
	 */
	public interface ISeionControl
	{
		/** Resumes playback of sound. (ISeionControl) */
		function resume():void;
		
		/** Pauses playback of sound. (ISeionControl) */
		function pause():void;
		
		/** Is the playback paused? (ISeionControl) */
		function get isPaused():Boolean;
		
		/**
		 * Get: The volume as affected by its parent.
		 * Set: The personal adjustable volume unaffected by anything.
		 *
		 * ISeionControl
		 */
		function get volume():Number;
		function set volume(value:Number):void;
		
		/**
		 * Get: The panning as affected by its parent.
		 * Set: The personal adjustable panning unaffected by anything.
		 *
		 * ISeionControl
		 */
		function get pan():Number;
		function set pan(value:Number):void;
	}
}