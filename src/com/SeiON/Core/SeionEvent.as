package com.SeiON.Core
{
	import flash.events.Event;
	
	import com.SeiON.ISeionInstance;
	
	/**
	 * Just like an original Event.
	 */
	public class SeionEvent extends Event
	{
		/** Fired by ISeionInstance.dispatcher when ISeionInstance restarts() */
		public static const SOUND_REPEAT:String = "SeionEvent.SOUND_REPEAT";
		
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