package com.SeiON.Core.Interface
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher
	import flash.media.SoundTransform;
	
	import com.SeiON.SeionGroup;
	
	/**
	 * Additional playback features for SeionInstance and its derivatives.
	 */
	public interface ISeionInstance extends ISeionControl, IEventDispatcher
	{
		/** Is the SeionInstance already disposed of? (ISeionInstance)
		 * @param	output	If true, a trace() message is given as well. */
		function isDisposed(output:Boolean = true):Boolean;
		
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		function dispose():void;
		
		/** Plays the sound from the beginning again. (ISeionInstance) */
		function play():void;
		
		/** Stops the sound and resets it to Zero. (ISeionInstance) */
		function stop():void;
		
		/*****************************************************************************
		 * 									PROPERTIES
		 *****************************************************************************/
		
		/** Is the sound active? (ISeionInstance) */
		function get isPlaying():Boolean;
		
		/** The name of the SeionInstance, non-unique. (ISeionInstance) */
		function get name():String;
		function set name(value:String):void;
		
		/** Returns the manager that holds this SeionInstance. (ISeionInstance) */
		function get manager():SeionGroup;
		
		/** Whether this sound is auto-disposable. (ISeionInstance) */
		function get autodispose():Boolean;
		
		/** Returns the predefined sound properties of the sound. (ISeionInstance) */
		function get soundtransform():SoundTransform;
		
		/**
		 * How many times the SeionInstance is programmed to repeat itself. <br />
		 * 0 means no repeats.<br />
		 * -1 means infinite repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		function get repeat():int;
		function set repeat(value:int):void;
		
		/**
		 * How many more times the SeionInstance has to repeat itself. To reset repeatLeft, set
		 * repeat. <br />
		 * 0 means no repeats.<br />
		 * -1 means infinite repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		function get repeatLeft():int;
		
		/** The total length of the clip, excluding repeats. In absolute terms. (ISeionInstance) */
		function get length():Number;
		
		/** How far into the clip we are. In absolute terms. (ISeionInstance) */
		function get position():Number;
		
		/** How far into the clip we are, from 0.0 to 1.0. (ISeionInstance) */
		function get progress():Number;
	}
}