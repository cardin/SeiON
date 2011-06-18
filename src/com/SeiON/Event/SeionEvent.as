package com.SeiON.Event
{
	import flash.events.Event;
	
	import com.SeiON.Core.Interface.ISeionInstance;
	
	/**
	 * Just like an original Event.
	 */
	public class SeionEvent extends Event
	{
		/** Defines the value for when a SeionInstance loops playback. */
		public static const SOUND_REPEAT:String = "soundRepeat";
		
		private var _targetSndObj:ISeionInstance;
		
		public function SeionEvent(type:String, target:ISeionInstance)
		{
			super(type);
			_targetSndObj = target;
		}
		
		/** The Seion object that fired this event. */
		public function get targetSndObj():ISeionInstance	{	return _targetSndObj;	}
	}
}