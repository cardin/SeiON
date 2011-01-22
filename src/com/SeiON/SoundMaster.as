package com.SeiON
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import com.SeiON.Tween.ITween;
	import com.SeiON.Tween.NullTween;
	
	/**
	 * 1. Controls all sounds in the program.
	 * 2. Tracks and rations sound allocation in the Flash Player.
	 *
	 * SoundMaster is pretty much THE Flash Player's sound control. Remember to instantiate the
	 * tweening library you want as early as possible to avoid problems switching later.
	 *
	 * @see	SoundGroup
	 */
	public final class SoundMaster implements ISoundControl
	{
		/** Static handler to itself */
		public static const _this:SoundMaster = new SoundMaster();
		/* Specifies the tweening class that will be used */
		internal static var tweenCls:Class;
		
		/** -- Collection --
		 * soundGroup: The collection of all SoundGroups that exist
		 * allocation: Remaining number of Sound instances that can ever be created
		 */
		private static const soundGroup:Vector.<SoundGroup> = new Vector.<SoundGroup>();
		private static var allocation:uint = 32;
		/** The complete available number of instances possible */
		public static const fullAllocation:uint = 32;
		
		/** -- Standard ISoundControl Variables --
		 * _pause: Whether the sound object is paused or not.
		 * _volume: The adjustable volume level of the sound object
		 * _pan: The adjustable panning of the sound object
		 * _tween: An animation for SoundMaster's properties
		 */
		private static var _pause:Boolean = false;
		private static var _volume:Number = 1.0;
		private static var _pan:Number = 0;
		private static var _tween:ITween;
		
		// Static Initialiser
		{
			// Sets up the default tweening library first
			setTweenLib(NullTween);
			_tween = new NullTween();
		}
		
		// ---------------------------- GLOBAL SOUND FUNCTIONS -----------------------------
		
		/**
		 * Sets the tweening library that we will use for the sound system. For best effect, call
		 * this function as early as possible before any sound objects are created.
		 *
		 * Note:
		 *  - It will erase SoundMaster's current tween and replace with new tween class.
		 *  - It will not affect existing SoundGroups and SoundLibraries. New instances of those
		 * 		classes will use the new tween class though.
		 *
		 * @param	tweenLib	Of type ITween.
		 */
		public static function setTweenLib(tweenLib:Class):void
		{
			// type checking, IMHO way too long for comfort
			var xml:XML = describeType(tweenLib);
			for each (var inter:XML in xml..implementsInterface)
			{
				if (inter.@type == getQualifiedClassName(ITween))
				{
					tweenCls = tweenLib;
					_tween = new tweenLib() as ITween;
					return;
				}
			}
		}
		
		/** Gives a formatted text string showing the internal progress of SeiON. */
		public static function statReport():String
		{
			var arr:Array;
			var output:String = "";
			var spareAlloc:uint = fullAllocation;
			
			for each (var sg:SoundGroup in soundGroup)
			{
				arr = sg.stats();
				
				// <name> <avail/allocation> <isPlaying>
				output += sg.name + " (" + sg.availAllocation + " / " + sg.completeAllocation + ")";
				output += (sg.isPaused() ? "\n" : " (p)\n");
				
				// for each ISoundClip in SoundGroup
				for each (var obj:Object in arr)
				{
					output += "     ";
					// <name> <autoDisposable> <isPlaying> <property name>
					output += obj.name + " ";
					output += (obj.ad ? "(ad)" : "   ");
					output += (obj.playing ? "(p)" : "   ");
					output += " " + obj.propname + "\n";
				}
				spareAlloc -= sg.completeAllocation;
			}
			
			output += "Spare (" + spareAlloc + ")";
			output = "-------------------/n" + output + "/n-------------------";
			return output;
		}
		
		// ------------------------------- PLAYBACK CONTROLS ---------------------------
		
		/** Resumes playback of all sounds. (ISoundControl) */
		public function resume():void
		{
			_pause = false;
			_tween.resume();
			
			for each (var sg:SoundGroup in soundGroup)
				sg.resume();
		}
		
		/** Pauses playback of all sounds. (ISoundControl) */
		public function pause():void
		{
			_pause = true;
			_tween.pause();
			
			for each (var sg:SoundGroup in soundGroup)
				sg.pause();
		}
		
		// --------------------------------- PROPERTIES ---------------------------------
		/** Is playback paused? (ISoundControl) */
		public function isPaused():Boolean {	return _pause;	}
		
		/** The adjustable volume of playback (ISoundControl) */
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		/** The adjustable panning of playback (ISoundControl) */
		public function get pan():Number {	return _pan;	}
		public function set pan(value:Number):void {	_pan = value;	}
		
		/** The animation pegged to playback (ISoundControl) */
		public function get tween():ITween	{	return _tween;	}
		public function set tween(value:ITween):void
		{
			_tween = value;
			if (this.isPaused())
				_tween.pause();
			else
				_tween.resume();
		}
		
		/** Read-only. Discovers how many allocations are left available. */
		public static function get availAllocation():uint		{	return allocation; }
		/** Read-only. Discovers the total allocation for sounds in the Flash Player. */
		public static function get completeAllocation():uint	{	return fullAllocation;	}
		
		// ----------------------------- COLLECTION MANAGEMENT --------------------------
		
		/**
		 * Allocates for a SoundGroup and keeps track of it internally.
		 *
		 * @param	name			Name of the SoundGroup. Doesn't have to be unique; for your
		 * own convenience only.
		 * @param	allocatedAmt	The number sound instances the SoundGroup is permitted. If
		 * there isn't enough allocation available in SoundMaster, we will not create any
		 * SoundGroup at all.
		 *
		 * @return	Returns null if we do not have that many allocations.
		 *
		 * NOTES: Drastic approach of not giving any SoundGroup at all is warranted, because
		 * 		SoundGroups are meant to be permanent long-term objects. We will not settle for
		 * 		less when creating such a long-term object.
		 */
		public static function createSoundGroup(name:String, allocatedAmt:uint):SoundGroup
		{
			// ensure we have enough sound instances to give out
			if (allocation >= allocatedAmt)
				allocation -= allocatedAmt;
			else
				return null;
			
			// aligning SoundGroup to our orientations
			var sg:SoundGroup = new SoundGroup(name, allocatedAmt, killSoundGroup);
			if (_this.isPaused())
				sg.pause();
			sg.volume = 1;
			
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
			allocation += sg.completeAllocation;
		}
		
		/**
		 * Performs 2 functions:
		 * * Checks to see if we can get additional allocations from SoundMaster.
		 * * Returns allocations that we've gotten from SoundMaster.
		 * What it does depends on the param "returnAllocation".
		 *
		 * @param	returnAllocation	True is to return back a borrowed allocation.
		 *
		 * @return	If we're trying to borrow allocation, returns true if borrowing is successful.
		 */
		internal static function getSpareAllocation(returnAllocation:Boolean = false):Boolean
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