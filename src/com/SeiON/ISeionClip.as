package com.SeiON
{
	import flash.events.EventDispatcher;
	
	import com.SeiON.Core.SeionProperty;
	
	/**
	 * Additional playback features for SeionClip and its derivatives.
	 */
	public interface ISeionClip extends ISeionControl
	{
		/** Clears all references held. This object is now invalid. (ISeionClip) */
		function dispose():void;
		
		/** Plays the sound from the beginning again according to sndProperties. (ISeionClip) */
		function play():void;
		/** Stops the sound and resets it to Zero. (ISeionClip) */
		function stop():void;
		
		// ----------------------------------- PROPERTIES -------------------------------
		/** Is the sound active? (ISeionClip) */
		function get isPlaying():Boolean;
		
		/** The name of the clip, non-unique. */
		function get name():String;
		function set name(value:String):void;
		
		/** Returns the manager that holds this ISeionClip. (ISeionClip) */
		function get manager():SeionGroup;
		
		/** Whether this sound is auto-disposable. (ISeionClip) */
		function get autodispose():Boolean;
		
		/** Fires off Event.SOUND_COMPLETE and/or SeionClip.SOUND_REPEAT. (ISeionClip) */
		function get dispatcher():EventDispatcher;
		
		/**
		 * Returns the predefined sound properties of the sound.
		 *
		 * NOTE: You're given a cloned copy. Remember to call dispose() to facilitate GC disposal.
		 *
		 * ISeionClip
		 */
		function get soundproperty():SeionProperty;
		
		/**
		 * How many more times the ISeionClip has to repeat itself. A value of -1 means that this
		 * is not going to repeat anymore.
		 *
		 * ISeionClip
		 */
		function get repeat():int;
		function set repeat(value:int):void;
		
		/** The total length of the clip, excluding repeats. In Milliseconds. (ISeionClip) */
		function get length():Number;
		
		/** How far into the clip we are. In Milliseconds. (ISeionClip) */
		function get position():Number;
		
		/** How far into the clip we are, from 0.0 to 1.0. (ISeionClip) */
		function get progress():Number;
	}
}