package com.SeiON
{
	import com.greensock.TimelineMax;
	/**
	 * 1. Controls all sounds in the program.
	 * 2. Tracks and rations sound instances allocation in the Flash Player.
	 *
	 * SoundMaster is pretty much THE Flash Player's sound control. Rely on SoundGroup for
	 * more intricate control; do not abuse SoundMaster by creating a secondary external control
	 * system.
	 *
	 * In other words, beyond the Document Class, there should be little need to touch SoundMaster.
	 *
	 * @see	SoundGroup
	 */
	public final class SoundMaster implements ISoundControl
	{
		public static const _this:SoundMaster = new SoundMaster();
		
		/** -- Collection --
		 * soundGroup: The collection of all SoundGroups that exist
		 * fullAllocation: The complete available number of instances possible
		 * allocation: Remaining number of Sound instances that can ever be created
		 */
		private static const soundGroup:Vector.<SoundGroup> = new Vector.<SoundGroup>();
		public static const fullAllocation:uint = 32;
		private static var allocation:uint = 32;
		
		/** -- Standard ISoundControl Variables --
		 * _pause: Whether the sound object is paused or not. We need its own variable since
		 * 			SoundMaster does not have any indication of it is paused or not.
		 * _volume: The adjustable volume level of the sound object
		 * _pan: The adjustable panning of the sound object
		 * _tween: An animation for SoundMaster's properties
		 */
		private static var _pause:Boolean = false;
		private static var _volume:Number = 1.0;
		private static var _pan:Number = 0;
		private static var _tween:TimelineMax = new TimelineMax();
		
		// ISoundControl
		public function resume():void
		{
			_pause = false;
			_tween.resume();
			
			for each (var sg:SoundGroup in soundGroup)
				sg.resume();
		}
		
		// ISoundControl
		public function pause():void
		{
			_pause = true;
			_tween.pause();
			
			for each (var sg:SoundGroup in soundGroup)
				sg.pause();
		}
		
		// ISoundControl
		public function isPaused():Boolean {	return _pause;	}
		
		// --------------------------------- PROPERTIES ---------------------------------
		// ISoundControl
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		// ISoundControl
		public function get pan():Number {	return _pan;	}
		public function set pan(value:Number):void {	_pan = value;	}
		
		// ISoundControl
		public function get tween():TimelineMax {	return _tween;	}
		public function set tween(value:TimelineMax):void
		{
			_tween = value;
			if (this.isPaused())
				_tween.pause();
			else
				_tween.resume();
		}
		
		/**
		 * Discovers the available allocation.
		 */
		public static function get availAllocation():uint		{	return allocation; }
		public static function get completeAllocation():uint	{	return fullAllocation;	}
		
		// ----------------------------- COLLECTION MANAGEMENT --------------------------
		
		/**
		 * Allocates for a SoundGroup and keeps track of it internally.
		 *
		 * @param	allocatedAmt	The number sound instances the SoundGroup is permitted. If
		 * 							there isn't enough allocation available in SoundMaster, we
		 * 							will not create any SoundGroup at all.
		 *
		 * @return	Returns null if we do not have that many allocations.
		 *
		 * NOTES: Drastic approach of not giving any SoundGroup at all is warranted, because
		 * 		SoundGroups are meant to be permanent long-term objects. We will not settle for
		 * 		less when creating such a long-term object.
		 */
		public static function createSoundGroup(allocatedAmt:uint):SoundGroup
		{
			// ensure we have enough sound instances to give out
			if (allocation >= allocatedAmt)
				allocation -= allocatedAmt;
			else
				return null;
			
			// aligning SoundGroup to our orientations
			var sg:SoundGroup = new SoundGroup(allocatedAmt, null);
			if (_this.isPaused())
				sg.pause();
			sg.volume = _volume;
			
			// insert into collection
			soundGroup.push(sg);
			return sg;
		}
		
		/**
		 * Called by a SoundGroup.dispose() to rid itself of SoundMaster's tracking.
		 */
		internal static function killSoundGroup(sg:SoundGroup):void
		{
			soundGroup.splice(soundGroup.indexOf(sg), 1);
		}
		
		/**
		 * Performs 2 functions:
		 * * Checks to see if we can get additional allocations from SoundMaster.
		 * * Returns allocations that we've gotten from SoundMaster.
		 * What it does depends on the param "returnAllocation".
		 *
		 * @param	returnAllocation	True is to return back a borrowed allocation.
		 */
		public static function getSpareAllocation(returnAllocation:Boolean = false):Boolean
		{
			// return allocation
			if (returnAllocation)
			{
				allocation ++;
				return false;
			}
			
			// get allocation
			if (allocation > 0)
			{
				allocation --;
				return true;
			}
			else
				return false;
		}
	}
}