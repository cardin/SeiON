package com.SeiON.Core
{
	import flash.events.Event;
	
	import com.SeiON.ISeionClip;
	
	/**
	 * Just like an original Event.
	 */
	public class SeionEvent extends Event
	{
		/** Fired by ISeionClip.dispatcher when ISeionClip restarts() */
		public static const SOUND_REPEAT:String = "SeionEvent.SOUND_REPEAT";
		
		private var _targetSndObj:ISeionClip;
		
		public function SeionEvent(type:String, target:ISeionClip)
		{
			super(type);
			_targetSndObj = target;
		}
		
		/** The Seion object that fired this event. */
		public function get targetSndObj():ISeionClip	{	return _targetSndObj;	}
	}
}