package com.SeiON
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	import com.SeiON.ISoundClip;
	import com.SeiON.Types.SoundTypes;
	import com.SeiON.Tween.ITween;
	import com.SeiON.Types.SoundProperty;
	
	/**
	 * In charge of near-global rationing of SoundClips, as well as their playback and properties.
	 * Its quota is fixed on instantiation.
	 *
	 * NOTE: SoundGroup is designed within the Audio API to be long-term. Try to create SoundGroups
	 * that encompasses large groups of sound and which represent a relevant sound category.
	 *
	 * @see	SoundMaster
	 */
	public final class SoundGroup implements ISoundControl
	{
		/** Name of the SoundGroup. */
		public var name:String;
		
		/** -- Misc --
		 * _pause: Whether the sound object is paused or not.
		 * _volume: The adjustable volume of the SoundGroup
		 * _pan: The adjustable panning of the SoundGroup
		 * _tween: Animation
		 */
		private var _pause:Boolean = false;
		private var _volume:Number = 1.0;
		private var _pan:Number = 0;
		private var _tween:ITween;
		
		/** -- Allocation variables --
		 * list: The list of disposable sounds.
		 * autoList: The list of auto-disposable sounds.
		 * fullAllocation: The complete available allocation from the start.
		 * allocatedAmt: The currently available quota for SoundGroup.
		 *
		 * NOTE: We make a distinction for auto-disposable sounds. If we run out of quota,
		 * we will first cannibalise the autoList to get more sound instances.
		 *
		 * This distinction is necessary because some sounds have to be manually held, eg. when
		 * we fade bg music to open up a sub-menu. Auto-disposables are a must, so as to be
		 * cannibalised to free up more allocation.
		 //*/
		private var list:Vector.<ISoundClip> = new Vector.<ISoundClip>();
		private var autoList:Vector.<ISoundClip> = new Vector.<ISoundClip>();
		private var fullAllocation:uint;
		private var allocatedAmt:uint;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SoundMaster.createSoundGroup().
		 *
		 * @param	allocatedAmt	The quota for the children this SoundGroup is allowed to have.
		 * @param 	secretKey		Does nothing, just forces a reminder not to use constructor...
		 *
		 * @throws	IllegalOperationError	When you try to directly instantiate SoundGroup without
		 * using SoundMaster.createSoundGroup().
		 *
		 * @see SoundMaster.createSoundGroup()
		 */
		public function SoundGroup(name:String, allocatedAmt:uint, secretKey:*)
		{
			if (secretKey != SoundMaster.killSoundGroup)
				throw new IllegalOperationError("SoundGroup's constructor not allowed for direct "
				+ "access! Please use SoundMaster.createSoundGroup() to instantiate SoundGroups!");
			
			this.name = name;
			this.fullAllocation = this.allocatedAmt = allocatedAmt;
			
			_tween = new SoundMaster.tweenCls() as ITween;
			_tween.play();
		}
		
		/** Clears all references held. This object is now invalid. */
		public function dispose():void
		{
			_tween.dispose();
			_tween = null;
			
			while (list.length > 0)
				list.pop().dispose();
			while (autoList.length > 0)
				autoList.pop().dispose();
			list = autoList = null;
			
			SoundMaster.killSoundGroup(this);
		}
		
		/* We do not have play() and stop() because how can we decide for others when THEIR sound
		 * should be played? Each member should be able to govern their own sound without us
		 * interrupting their playback. We can only control volume when disabling sound.
		 */
		
		/** Resumes playback of all sounds held. (ISoundControl) */
		public function resume():void
		{
			// If SoundMaster is paused, we do not resume
			if (SoundMaster._this.isPaused())	return;
			
			if (isPaused())
			{
				_pause = false;
				_tween.resume();
				
				var sc:ISoundClip;
				for each (sc in list)
					sc.resume();
				for each (sc in autoList)
					sc.resume();
			}
		}
		
		/** Pauses playback of all sounds held. (ISoundControl) */
		public function pause():void
		{
			if (!isPaused())
			{
				_pause = true;
				_tween.pause();
				
				var sc:ISoundClip;
				for each (sc in list)
					sc.pause();
				for each (sc in autoList)
					sc.pause();
			}
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		
		/** Is the playback paused? (ISoundControl) */
		public function isPaused():Boolean
		{
			return _pause;
		}
		
		/**
		 * Get: The volume as affected by SoundMaster (parent).
		 * Set: The personal adjustable volume unaffected by anything.
		 *
		 * ISoundControl
		 */
		public function get volume():Number	{	return _volume * SoundMaster._this.volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		/**
		 * Get: The panning as affected by SoundMaster (parent).
		 * Set: The personal adjustable panning unaffected by anything.
		 *
		 * ISoundControl
		 */
		public function get pan():Number {	return _pan * SoundMaster._this.pan;	}
		public function set pan(value:Number):void	{	_pan = value;		}
		
		/** The animation pegged to playback. (ISoundControl) */
		public function get tween():ITween {	return _tween; }
		public function set tween(value:ITween):void
		{
			if (isPaused())
				value.pause();
			else
				value.resume();
				
			_tween = value;
		}
		
		/** Read-only. Discovers how many allocations are left available. */
		public function get availAllocation():uint		{	return allocatedAmt;	}
		/** Read-only. Discovers the total allocation that had been given to it. */
		public function get completeAllocation():uint	{	return fullAllocation;	}
		
		// ---------------------------- SOUND CREATION & DESTRUCTION -------------------------
		
		/**
		 * Kills all AUTO-DISPOSABLE sounds of this SoundGroup.
		 */
		public function killAutoSounds():void
		{
			while (autoList.length > 0)
				autoList.pop().dispose();
		}
		
		/**
		 * Removes the sound from list. This is usually called from within ISoundClip.dispose().
		 * @param	sc		If sc does not exist in this SoundGroup, nothing happens.
		 */
		internal function killSound(sc:ISoundClip):void
		{
			if (autoList.indexOf(sc) > -1)
				autoList.splice(autoList.indexOf(sc), 1);
			else if (list.indexOf(sc) > -1)
				list.splice(list.indexOf(sc), 1);
			else
				return;
			
			// if we leeched from SoundMaster, then we return it too.
			if (sc.spareAllocation)
				SoundMaster.getSpareAllocation(true);
			
			allocatedAmt ++;
		}
		
		/**
		 * Creates a new ISoundClip belonging to this SoundGroup.
		 *
		 * @param	snd		Either retrieved from a sound repository, or directly instantiated.
		 * @param	autodispose		autodispose sounds have low priority and are the 1st to be
		 * overwritten when allocation is limited. They are self-disposable too.
		 *
		 * @return	null, if:
		 * 1. No allocation is available.
		 * 2. You created an autodispose sound.
		 * Else, it will return a handle to the ISoundClip you created.
		 */
		public function createSound(snd:Sound, sndProperties:SoundProperty,
								autodispose:Boolean = true):ISoundClip
		{
			var isSpareAllocated:Boolean = false;
			// if not enough
			if (allocatedAmt <= 0)
			{
				// Cannibalise the autodispose list
				if (autoList.length > 0)
					autoList[0].dispose(); // dispose will autocall killSound() later
				
				// beg clemency from SoundMaster if it's autodisposable
				else if (autodispose && SoundMaster.getSpareAllocation())
				{
					// We note down the loan from SoundMaster
					isSpareAllocated = true;
				}
				else // Plea failed. the end.
					return null;
			}
			/* ---- Explanation for above choices
			 * We must cannibalise. Otherwise if allocations were maxed out, new sounds might not be
			 * played at all.
			 *
			 * But, we only allow auto-disposable sounds to use spareAllocation, otherwise the
			 * non-disposable sounds will hog the space and refuse to give it up.
			 */
			
			allocatedAmt --;
			
			// Assigning the ISoundClip
			var cls:Class = sndProperties.type.clsRef;
			var sc:ISoundClip = new cls(this, snd, sndProperties, autodispose, isSpareAllocated,
								killSound) as ISoundClip;
			
			// Inserting the clip into its appropriate list
			if (autodispose)
			{
				autoList.push(sc);
				
				/*
				 * The auto-play (sc.play()) is place here because if a ISoundClip is short enough,
				 * it will dispose exactly after its constructor is called. Which means by the time
				 * we get here, it's already diposed!
				 */
				// auto-disposable auto-plays
				sc.play();
				return null;
			}
			else
			{
				list.push(sc);
				return sc;
			}
		}
		
		/**
		 * Returns an array of all ISoundClips' details.
		 * name:		name of the sound class
		 * ad:			Auto diposable?
		 * playing:		Does it hold a sound channel
		 * propname:	Name of the SoundProperty.
		 */
		internal function stats():Array
		{
			/* This function is here and not in ISoundClip is because:
			 * 1. ISoundClip would've made it public access
			 * 2. SoundGroup would still need to be the one polling, since only
			 *    SoundGroup knows what it holds. (autoList/list is private)
			 */
			var arr:Array = new Array();
			
			var sc:ISoundClip, stat:Object;
			for each (sc in list)
			{
				stat = new Object();
				stat.name = sc.soundCls;
				stat.ad = sc.autodispose;
				stat.playing = sc.isPlaying;
				stat.propname = sc.soundproperty.name;
				
				arr.push(stat);
			}
			for each (sc in autoList)
			{
				stat = new Object();
				stat.name = sc.soundCls;
				stat.ad = sc.autodispose;
				stat.playing = sc.isPlaying;
				stat.propname = sc.soundproperty.name;
				
				arr.push(stat);
			}
			return arr;
		}
	}
}