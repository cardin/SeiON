package com.SeiON
{
	import flash.errors.IllegalOperationError;
	
	import com.SeiON.Core.Interface.ISeionControl;
	
	/**
	 * Global sound control over whole of SeiON.
	 * <ol>
	 * <li>Controls all sounds in the program.</li>
	 * <li>Tracks and rations sound allocation in the Flash Player.</li></ol>
	 */
	public final class Seion implements ISeionControl
	{
		/** Static handler to itself */
		public static const _this:Seion = new Seion();
		
		/** The amount of spare allocation. Do not use. @private */
		internal static var allocation:uint = 32;
		/** The complete available number of instances possible */
		public static const fullAllocation:uint = 32;
		
		/* sndGroup: The collection of all SeionGroups that exist */
		private static const sndGroup:Vector.<SeionGroup> = new Vector.<SeionGroup>();
		
		/** -- Standard ISeionControl Variables --
		 * _pause: Whether the sound object is paused or not.
		 * _volume: The adjustable volume level of the sound object
		 * _pan: The adjustable panning of the sound object
		 */
		private static var _pause:Boolean = false;
		private static var _volume:Number = 1.0;
		private static var _pan:Number = 0;
		
		/**
		 * Seion is a static singleton, do not instantiate it!
		 */
		public function Seion() {}
		
		// ---------------------------- GLOBAL SOUND FUNCTIONS -----------------------------
		/** Gives a formatted text string showing the internal progress of SeiON. */
		public static function statReport():String
		{
			var arr:Array;
			var output:String = "";
			
			for each (var sg:SeionGroup in sndGroup)
			{
				arr = sg.stats();
				
				// <name> <avail/allocation> <isPlaying>
				output += sg.name + " (" + sg.availAllocation + " / " + sg.fullAllocation + ") ";
				output += "[" + sg.borrowedAllocation + "]";
				output += (sg.isPaused ? "\n" : " (p)\n");
				
				// for each ISeionInstance in SeionGroup
				for each (var obj:Object in arr)
				{
					output += "     ";
					// <name> <autoDisposable> <isPlaying> <property name>
					output += obj.name + " ";
					output += (obj.ad ? "(ad)" : "   ");
					output += (obj.playing ? "(p)" : "   ");
					output += " " + obj.propname + "\n";
				}
			}
			
			output += "Spare (" + allocation + ")";
			output = "-------------------/n" + output + "/n-------------------";
			return output;
		}
		
		// ------------------------------- PLAYBACK CONTROLS ---------------------------
		
		/** Resumes playback of all sounds. (ISeionControl) */
		public function resume():void
		{
			_pause = false;
			
			for each (var sg:SeionGroup in sndGroup)
				sg.resume();
		}
		
		/** Pauses playback of all sounds. (ISeionControl) */
		public function pause():void
		{
			_pause = true;
			
			for each (var sg:SeionGroup in sndGroup)
				sg.pause();
		}
		
		// --------------------------------- PROPERTIES ---------------------------------
		/** Is playback paused? (ISeionControl) */
		public function get isPaused():Boolean {	return _pause;	}
		
		/** The adjustable volume of playback (ISeionControl) */
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		/** The adjustable panning of playback (ISeionControl) */
		public function get pan():Number {	return _pan;	}
		public function set pan(value:Number):void {	_pan = value;	}
		
		/** Discovers how many allocations are left available. */
		public static function get availAllocation():uint		{	return allocation; }
		/** Discovers the total allocation for sounds in the Flash Player. */
		public static function get completeAllocation():uint	{	return fullAllocation;	}
		
		// ----------------------------- COLLECTION MANAGEMENT --------------------------
		
		/**
		 * Allocates for a SeionGroup and keeps track of it internally.
		 *
		 * @param	name			Name of the SeionGroup. Doesn't have to be unique; for your
		 * own convenience only.
		 * @param	allocatedAmt	The number sound instances the SeionGroup is permitted. If
		 * there isn't enough allocation available in Seion, we will not create any
		 * SeionGroup at all.
		 *
		 * @return	Returns null if we do not have that many allocations.
		 *
		 * NOTES: Drastic approach of not giving any SeionGroup at all is warranted, because
		 * 		SeionGroups are meant to be permanent long-term objects. We will not settle for
		 * 		less when creating such a long-term object.
		 */
		public static function createSeionGroup(name:String, allocatedAmt:uint):SeionGroup
		{
			// ensure we have enough sound instances to give out
			if (allocation >= allocatedAmt)
				allocation -= allocatedAmt;
			else
				return null;
			
			// aligning SeionGroup to our orientations
			var sg:SeionGroup = new SeionGroup(name, allocatedAmt, killSeionGroup);
			if (_this.isPaused)
				sg.pause();
			sg.volume = 1;
			
			// insert into collection
			sndGroup.push(sg);
			return sg;
		}
		
		/**
		 * Called by a SeionGroup.dispose() to rid itself of Seion's tracking.
		 * @private
		 */
		internal static function killSeionGroup(sg:SeionGroup):void
		{
			sndGroup.splice(sndGroup.indexOf(sg), 1);
			allocation += sg.fullAllocation + sg.borrowedAllocation;
		}
	}
}