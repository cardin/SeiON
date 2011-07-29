package com.SeiON
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.Core.seion_ns;
	import com.SeiON.Core.Interface.ISeionControl;
	import com.SeiON.Core.Interface.ISeionInstance;
	
	use namespace seion_ns;
	
	/**
	 * In charge of organising SeionClips, their playback and properties. On instantiation, the
	 * no. of sound channels that each SeionGroup is allowed is set individually.<p></p>
	 *
	 * Design Recommendation: SeionGroup is designed to be objects which stay long in memory. Try
	 * to create SeionGroups that encompasses large groups of sound and which represent a relevant
	 * sound category. Eg. background sounds category, menu sounds category and in-game dialog
	 * category.
	 *
	 * @see	Seion
	 */
	public final class SeionGroup implements ISeionControl
	{
		/** Name of the SeionGroup. Doesn't have to be unique. */
		public var name:String;
		
		/** -- Misc --
		 * _pause: Whether the sound object is paused or not.
		 * _volume: The adjustable volume of the SeionGroup
		 * _pan: The adjustable panning of the SeionGroup
		 */
		private var _pause:Boolean = false;
		private var _volume:Number = 1.0;
		private var _pan:Number = 0;
		
		/** -- Allocation variables --
		 * list: The list of disposable sounds.
		 * autoList: The list of auto-disposable sounds.
		 * fullAlloc: The complete available allocation from the start.
		 * availAmt: The currently available quota for SeionGroup.
		 * borrowedAmt: The allocation amount that has been borrowed from Seion.
		 *
		 * NOTE: We make a distinction for auto-disposable sounds. If we run out of quota,
		 * we will first cannibalise the autoList to get more sound instances.
		 *
		 * This distinction is necessary because some sounds have to be manually held, eg. when
		 * we fade bg music to open up a sub-menu. Auto-disposables are a must, so as to be
		 * cannibalised to free up more allocation.
		 */
		private var list:Vector.<ISeionInstance> = new Vector.<ISeionInstance>();
		private var autoList:Vector.<ISeionInstance> = new Vector.<ISeionInstance>();
		private var fullAlloc:uint;
		private var availAmt:uint;
		private var borrowedAmt:uint;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * Seion.createSeionGroup().
		 *
		 * @param	availAmt	The quota for the children this SeionGroup is allowed to have.
		 * @param 	secretKey		Does nothing, just forces a reminder not to use constructor...
		 *
		 * @throws	IllegalOperationError When you try to directly instantiate SeionGroup without
		 * using Seion.createSeionGroup().
		 *
		 * @see Seion#createSeionGroup()
		 */
		public function SeionGroup(name:String, availAmt:uint, secretKey:*)
		{
			if (secretKey != Seion.killSeionGroup)
				throw new IllegalOperationError("SeionGroup's constructor not allowed for direct "
				+ "access! Please use Seion.createSeionGroup() to instantiate SeionGroups!");
			
			this.name = name;
			this.fullAlloc = this.availAmt = availAmt;
		}
		
		/** Clears all references held. This object is now invalid. */
		public function dispose():void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			while (list.length > 0)
				list.pop().dispose();
			while (autoList.length > 0)
				autoList.pop().dispose();
			list = autoList = null;
			
			Seion.killSeionGroup(this);
		}
		
		/* We do not have play() and stop() because how can we decide for others when THEIR sound
		 * should be played? Each member should be able to govern their own sound without us
		 * interrupting their playback. We can only control volume when disabling sound.
		 */
		
		/** Resumes playback of all sounds held. (ISeionControl) */
		public function resume():void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			// If Seion is paused, we do not resume
			if (Seion._this.isPaused)	return;
			
			if (isPaused)
			{
				_pause = false;
				
				var sc:ISeionInstance;
				for each (sc in list)
					sc.resume();
				for each (sc in autoList)
					sc.resume();
			}
		}
		
		/** Pauses playback of all sounds held. (ISeionControl) */
		public function pause():void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			if (!isPaused)
			{
				_pause = true;
				
				var sc:ISeionInstance;
				for each (sc in list)
					sc.pause();
				for each (sc in autoList)
					sc.pause();
			}
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		
		/** Is the playback paused? (ISeionControl) */
		public function get isPaused():Boolean	{	return _pause;	}
		
		/**
		 * Get: The volume as affected by Seion (parent). <p></p>
		 * Set: The personal adjustable volume unaffected by anything. <p></p>
		 *
		 * ISeionControl
		 */
		public function get volume():Number	{	return _volume * Seion._this.volume;	}
		public function set volume(value:Number):void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			_volume = value;
			var sc:ISeionInstance;
			for each (sc in list)
				sc.volume = sc.volume;
			for each (sc in autoList)
				sc.volume = sc.volume;
		}
		
		/**
		 * Get: The panning as affected by Seion (parent). <p></p>
		 * Set: The personal adjustable panning unaffected by anything.
		 *
		 * ISeionControl
		 */
		public function get pan():Number
		{
			var desiredDir:int = (Seion._this.pan > 0) ? 1 : -1;
			var amtToMove:Number = (desiredDir - _pan) * Math.abs(Seion._this.pan);
			return amtToMove + _pan;
		}
		public function set pan(value:Number):void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			_pan = value;
			var sc:ISeionInstance;
			for each (sc in list)
				sc.pan = sc.pan;
			for each (sc in autoList)
				sc.pan = sc.pan;
			}
		
		/** Discovers the no. of allocations borrowed from Seion. */
		public function get borrowedAllocation():uint	{	return borrowedAmt;		}
		/** The total amount of used allocation slots, included assigned and borrowed. */
		public function get usedAllocation():uint	{	return borrowedAmt + fullAlloc - availAmt;	}
		/** Discovers how many allocations are left available. */
		public function get availAllocation():uint		{	return availAmt;	}
		/** Discovers the total allocation that had been given to it. */
		public function get fullAllocation():uint	{	return fullAlloc;	}
		
		// ---------------------------- SOUND CREATION & DESTRUCTION -------------------------
		
		/**
		 * Kills all AUTO-DISPOSABLE sounds of this SeionGroup. Useful when you want to "clean the
		 * slate".
		 */
		public function killAllAutoSounds():void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			// topping up the amounts
			availAmt += autoList.length - borrowedAmt;
			Seion.allocation += borrowedAmt;
			borrowedAmt = 0;
			
			// disposing the sounds
			while (autoList.length > 0)
				autoList.pop().dispose();
		}
		
		/**
		 * Kills all sounds of this SeionGroup. Useful when you want to "clean the slate".
		 */
		public function killAllSounds():void
		{
			// Checking for dispose
			if (isDisposed()) return;
			
			killAllAutoSounds();
			availAmt = fullAlloc;
			
			// disposing the sounds
			while (list.length > 0)
				list.pop().dispose();
		}
		
		/**
		 * Queries for additional allocation.
		 * @return	True if allocation is possible.
		 */
		seion_ns function alloc(snd:ISeionInstance, autodispose:Boolean):Boolean
		{
			// Checking for dispose
			if (isDisposed()) return false;
			
			// if not enough
			if (availAmt <= 0)
			{
				// beg clemency from Seion if it's autodisposable
				if (autodispose && Seion.allocation > 0)
				{
					// We note down the loan from Seion
					-- Seion.allocation;
					++ borrowedAmt;
				}
				// Cannibalise the autodispose list
				else if (autoList.length > 0)
				{
					autoList[0].dispose(); // dispose will autocall killSound() later
					return alloc(snd, autodispose);
				}
				// Force out an alloc
				else if (autodispose && Seion.forceAlloc(this))
					return alloc(snd, autodispose);
				else // Plea failed. the end.
					return false;
			}
			else
				-- availAmt;
			
			/* ---- Explanation for above choices
			 * We must cannibalise. Otherwise if allocations were maxed out, new sounds might not be
			 * played at all.
			 *
			 * But, we only allow auto-disposable sounds to use spareAllocation, otherwise the
			 * non-disposable sounds will hog the space and refuse to give it up.
			 */
			
			// Inserting the clip into its appropriate list
			if (autodispose)
				autoList.push(snd);
			else
				list.push(snd);
			
			return true;
		}
		
		/**
		 * Removes the sound from list. This is usually called from within ISeionInstance.dispose().
		 * @param	sc		If sc does not exist in this SeionGroup, nothing happens.
		 *
		 * @private
		 */
		seion_ns function killSound(sc:ISeionInstance = null):void
		{
			/* If null, it means Seion called this method. It wants to kill an autodisposable
			 * sound, in the hopes that enough allocation is freed to generate another SeionGroup.
			 */
			if (sc == null)
			{
				if (borrowedAmt <= 0)	return;
				sc = autoList[0];
				sc.dispose(); // which calls killSound() also
				return;
			}
			
			// proceeding to destroy the ISeionInstance
			if (autoList.indexOf(sc) > -1)
				autoList.splice(autoList.indexOf(sc), 1);
			else if (list.indexOf(sc) > -1)
				list.splice(list.indexOf(sc), 1);
			else
				return;
			
			// If sound is autodisposable, and if we are indebted to Seion, then return it.
			if (sc.autodispose && borrowedAmt > 0)
			{
				++ Seion.allocation;
				-- borrowedAmt;
			}
			else
				++ availAmt;
		}
		
		/**
		 * Returns an array of all ISeionInstances' details.
		 * name:		name of the sound class
		 * ad:			Auto diposable?
		 * playing:		Does it hold a sound channel
		 * propname:	Name of the SeionProperty.
		 *
		 * @private
		 */
		internal function stats():Array
		{
			/* This function is here and not in ISeionInstance is because:
			 * 1. ISeionInstance would've made it public access
			 * 2. SeionGroup would still need to be the one polling, since only
			 *    SeionGroup knows what it holds. (autoList/list is private)
			 */
			var arr:Array = new Array();
			
			var sc:ISeionInstance, stat:Object;
			for each (sc in list)
			{
				stat = new Object();
				stat.name = sc.name;
				stat.ad = sc.autodispose;
				stat.playing = sc.isPlaying;
				
				arr.push(stat);
			}
			for each (sc in autoList)
			{
				stat = new Object();
				stat.name = sc.name;
				stat.ad = sc.autodispose;
				stat.playing = sc.isPlaying;
				
				arr.push(stat);
			}
			return arr;
		}
		
		/**
		 * Returns true if this instance is already disposed of.
		 * @param	output	If true, a trace() is also printed.
		 */
		private function isDisposed(output:Boolean = true):Boolean
		{
			if (autoList == null)
			{
				if (output)	trace("This SeionGroup's already disposed, stop using a null reference!");
				return true;
			}
			return false;
		}
	}
}