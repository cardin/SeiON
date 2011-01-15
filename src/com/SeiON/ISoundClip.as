package com.SeiON
{
	/**
	 * Interface for sound objects that will be handling playback of the actual Sound object.
	 */
	public interface ISoundClip extends ISoundControl
	{
		/** Removes all references held by this object. */
		public function dispose();
		
		/** Stops/Plays the sound from the beginning. */
		public function play();
		public function stop();
		
		/** Whether the sound is currently playing or not. */
		public function isPlaying();
		
		// ----------------------------------- PROPERTIES -------------------------------
		
		/** Whether this SoundClip is borrowed on a loan from SoundMaster. */
		public function get spareAllocation():Boolean;
		
		/** Returns the sound properties of the sound. */
		public function get soundProperties():SoundProperties;
		
		/** How many more times to repeat itself. */
		public function get repeat():int;
		public function set repeat(value:int):void;
	}
}