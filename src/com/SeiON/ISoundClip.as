package com.SeiON
{
	import flash.events.EventDispatcher;
	/**
	 * Interface for sound objects that will be handling playback of the actual Sound object.
	 */
	public interface ISoundClip extends ISoundControl
	{
		/** Clears all references held. This object is now invalid. (ISoundClip) */
		public function dispose();
		
		/** Stops the sound and resets it to Zero. (ISoundClip) */
		public function play();
		/** Plays the sound from the beginning again. (ISoundClip) */
		public function stop();
		
		/** Is the sound active? (ISoundClip) */
		public function isPlaying();
		
		// ----------------------------------- PROPERTIES -------------------------------
		
		/** Read-only. Returns the manager that holds this ISoundClip. */
		public function get manager():SoundGroup;
		
		/** Read-only. Used by SoundManager to check if this clip was borrowed from SoundMaster. (ISoundClip) */
		public function get spareAllocation():Boolean;
		
		/** Read-only. Fires off Event.SOUND_COMPLETE and/or SoundClip.SOUND_REPEAT. (ISoundControl) */
		public function get dispatcher():EventDispatcher;
		
		/** Read-only
		 * Returns the sound properties of the sound. Eg. Full Repeat times, offset, truncate.
		 *
		 * NOTE: You're given a cloned copy. Remember to call dispose() to facilitate GC disposal.
		 *
		 * ISoundClip
		 */
		public function get soundProperties():SoundProperties;
		
		/**
		 * How many more times the ISoundClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore.
		 *
		 * ISoundClip
		 */
		public function get repeat():int;
		public function set repeat(value:int):void;
		
		/** Read-only. The total length of the clip. In Milliseconds. (ISoundClip) */
		public function get length():Number;
		
		/** Read-only. The amount of time remaining in this cycle. In Milliseconds. (ISoundClip) */
		public function get remainingTime:Number;
	}
}