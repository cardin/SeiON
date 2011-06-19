package com.SeiON.Event
{
	import flash.events.Event;
	
	import com.SeiON.Core.Interface.ISeionControl;
	
	/**
	 * An event fired by SeiON.
	 */
	public final class SeionEvent extends Event
	{
		/** Defines the value for when a SeionInstance loops playback. */
		public static const SOUND_REPEAT:String = "soundRepeat";
		
		private var _targetSndObj:ISeionControl;
		
		/**
		 * Creates an event.
		 * @param	type	The type of Event.
		 * @param	target	The SeiON obj that triggered the event.
		 */
		public function SeionEvent(type:String, target:ISeionControl)
		{
			super(type);
			_targetSndObj = target;
		}
		
		/** The Seion object that fired this event. */
		public function get targetSndObj():ISeionControl	{	return _targetSndObj;	}
	}
}