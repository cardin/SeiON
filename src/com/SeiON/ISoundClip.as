package com.SeiON
{
	import flash.events.EventDispatcher;
	
	import com.SeiON.Types.SoundProperty;
	
	/**
	 * Interface for sound objects that will be handling playback of the actual Sound object.
	 */
	public interface ISoundClip extends ISoundControl
	{
		/** Clears all references held. This object is now invalid. (ISoundClip) */
		function dispose():void;
		
		/** Plays the sound from the beginning again according to sndProperties. (ISoundClip) */
		function play():void;
		/** Stops the sound and resets it to Zero. (ISoundClip) */
		function stop():void;
		
		/** Is the sound active? (ISoundClip) */
		function isPlaying():Boolean;
		
		// ----------------------------------- PROPERTIES -------------------------------
		
		/** Read-only. The fully qualified name of the sound class that was playing. */
		function get soundCls():String;
		
		/** Read-only. Returns the manager that holds this ISoundClip. */
		function get manager():SoundGroup;
		
		/** Read-only. Whether this sound is auto-disposable. */
		function get autodispose():Boolean;
		
		/** Read-only. Used by SoundManager to check if this clip was a borrowed spare. (ISoundClip) */
		function get spareAllocation():Boolean;
		
		/** Read-only. Fires off Event.SOUND_COMPLETE and/or SoundClip.SOUND_REPEAT. (ISoundControl) */
		function get dispatcher():EventDispatcher;
		
		/** Read-only
		 * Returns the sound properties of the sound. Eg. Full Repeat times, offset, truncate.
		 *
		 * NOTE: You're given a cloned copy. Remember to call dispose() to facilitate GC disposal.
		 *
		 * ISoundClip
		 */
		function get soundproperty():SoundProperty;
		
		/**
		 * How many more times the ISoundClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore.
		 *
		 * ISoundClip
		 */
		function get repeat():int;
		function set repeat(value:int):void;
		
		/** Read-only. The total length of the clip, excluding repeats. In Milliseconds. (ISoundClip) */
		function get length():Number;
		
		/** Read-only. How far into the clip we are. In Milliseconds. (ISoundClip) */
		function get position():Number;
	}
}