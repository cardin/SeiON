<<<<<<< HEAD
﻿package com.SeiON
{
	import flash.errors.IllegalOperationError;
=======
package com.SeiON
{
>>>>>>> parent of 1ae3953... Removed duplicate folders
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
<<<<<<< HEAD
	import com.SeiON.ISoundClip;
	import com.SeiON.Types.E_SoundTypes;
	import com.SeiON.Tween.ITween;
	
	/**
	 * In charge of near-global rationing of SoundClips, as well as their playback and properties.
	 * Its quota is fixed on instantiation.
=======
	import com.greensock.TimelineMax;
	
	import com.SeiON.Types.E_SoundTypes;
	
	/**
	 * In charge of near-global rationing of SoundClips, as well as their playback and properties.
	 * Its quota is fixed on instantiation. Use this as a top-level control element, not
	 * SoundMaster, as SoundMaster is supposed to be the Flash Player-level sound control.
>>>>>>> parent of 1ae3953... Removed duplicate folders
	 *
	 * NOTE: SoundGroup is designed within the Audio API to be long-term. Try to create SoundGroups
	 * that encompasses large groups of sound and which represent a relevant sound category.
	 *
	 * @see	SoundMaster
	 */
	public final class SoundGroup implements ISoundControl
	{
		/** -- Misc --
<<<<<<< HEAD
		 * _pause: Whether the sound object is paused or not.
=======
>>>>>>> parent of 1ae3953... Removed duplicate folders
		 * _volume: The adjustable volume of the SoundGroup
		 * _pan: The adjustable panning of the SoundGroup
		 * _tween: Animation
		 */
<<<<<<< HEAD
		private var _pause:Boolean = false;
		private var _volume:Number = 1.0;
		private var _pan:Number = 0;
		private var _tween:ITween;
=======
		private var _volume:Number = 1.0;
		private var _pan:Number = 0;
		private var _tween:TimelineMax = new TimelineMax();
>>>>>>> parent of 1ae3953... Removed duplicate folders
		
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
		 */
<<<<<<< HEAD
		private var list:Vector.<ISoundClip> = new Vector.<ISoundClip>();
		private var autoList:Vector.<ISoundClip> = new Vector.<ISoundClip>();
=======
		private var list:Vector.<SoundClip> = new Vector.<SoundClip>();
		private var autoList:Vector.<SoundClip> = new Vector.<SoundClip>();
>>>>>>> parent of 1ae3953... Removed duplicate folders
		private var fullAllocation:uint;
		private var allocatedAmt:uint;
		
		/**
<<<<<<< HEAD
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
		public function SoundGroup(allocatedAmt:uint, secretKey:*)
		{
			if (secretKey != SoundMaster.killSoundGroup)
				throw new IllegalOperationError("SoundGroup's constructor not allowed for direct "
				+ "access! Please use SoundMaster.createSoundGroup() to instantiate SoundGroups!");
			
			this.fullAllocation = this.allocatedAmt = allocatedAmt;
			
			_tween = new SoundMaster.tweenCls() as ITween;
			_tween.play();
		}
		
		/** Clears all references held. This object is now invalid. */
		public function dispose():void
		{
			_tween.dispose();
=======
		 * Please do not call this constructor directly, except through SoundMaster.createSoundGroup().
		 *
		 * @param	allocatedAmt	The quota for the children this SoundGroup is allowed to have.
		 * @param 	sm			Does nothing, just forces a reminder not to use constructor...
		 */
		public function SoundGroup(allocatedAmt:uint, sm:SoundMaster)
		{
			this.fullAllocation = this.allocatedAmt = allocatedAmt;
			_tween.resume();
		}
		
		// IDisposable
		public function dispose():void
		{
			_tween.clear();
>>>>>>> parent of 1ae3953... Removed duplicate folders
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
		
<<<<<<< HEAD
		/** Resumes playback of all sounds held. (ISoundControl) */
=======
		// ISoundControl
>>>>>>> parent of 1ae3953... Removed duplicate folders
		public function resume():void
		{
			// If SoundMaster is paused, we do not resume
			if (SoundMaster._this.isPaused())	return;
			
			if (isPaused())
			{
<<<<<<< HEAD
				_pause = false;
				_tween.resume();
				
				var sc:ISoundClip;
=======
				_tween.resume();
				
				var sc:SoundClip;
>>>>>>> parent of 1ae3953... Removed duplicate folders
				for each (sc in list)
					sc.resume();
				for each (sc in autoList)
					sc.resume();
			}
		}
		
<<<<<<< HEAD
		/** Pauses playback of all sounds held. (ISoundControl) */
=======
		// ISoundControl
>>>>>>> parent of 1ae3953... Removed duplicate folders
		public function pause():void
		{
			if (!isPaused())
			{
<<<<<<< HEAD
				_pause = true;
				_tween.pause();
				
				var sc:ISoundClip;
=======
				_tween.pause();
				
				var sc:SoundClip;
>>>>>>> parent of 1ae3953... Removed duplicate folders
				for each (sc in list)
					sc.pause();
				for each (sc in autoList)
					sc.pause();
			}
		}
		
<<<<<<< HEAD
		// ----------------------------------- PROPERTIES ---------------------------------
		
		/** Is the playback paused? (ISoundControl) */
		public function isPaused():Boolean
		{
			return _pause;
		}
		
		/**
		 * Get: The volume as affected by SoundMaster (parent).
		 * Set: The personal adjustable volume unaffected by anything.
=======
		// ------------------------------- CHECKING METHODS -------------------------------
		
		// ISoundControl
		public function isPaused():Boolean
		{
			if (_tween.paused)
				return true;
			return false;
		}
		
		// ----------------------------------- PROPERTIES ---------------------------------
		
		/**
		 * Get: The volume of this SoundGroup, as affected by SoundMaster (parent).
		 * Set: The personal adjustable volume of this SoundGroup.
		 *
		 * REASON: SoundGroup does not set its child SoundClip. Each ISoundControl should just
		 * manage its own sound. SoundClip will on-its-own factor in SoundGroup's volume settings.
>>>>>>> parent of 1ae3953... Removed duplicate folders
		 *
		 * ISoundControl
		 */
		public function get volume():Number	{	return _volume * SoundMaster._this.volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		/**
<<<<<<< HEAD
		 * Get: The panning as affected by SoundMaster (parent).
		 * Set: The personal adjustable panning unaffected by anything.
=======
		 * Same as volume.
>>>>>>> parent of 1ae3953... Removed duplicate folders
		 *
		 * ISoundControl
		 */
		public function get pan():Number {	return _pan * SoundMaster._this.pan;	}
		public function set pan(value:Number):void	{	_pan = value;		}
		
<<<<<<< HEAD
		/** The animation pegged to playback. (ISoundControl) */
		public function get tween():ITween {	return _tween; }
		public function set tween(value:ITween):void
=======
		/**
		 * A tween that is tied into the controls.
		 * Use this as you would filters = [].
		 *
		 * ISoundControl
		 */
		public function get tween():TimelineMax {	return _tween; }
		public function set tween(value:TimelineMax):void
>>>>>>> parent of 1ae3953... Removed duplicate folders
		{
			if (isPaused())
				value.pause();
			else
				value.resume();
				
			_tween = value;
		}
		
<<<<<<< HEAD
		/** Discovers how many allocations are left available. */
		public function get availAllocation():uint		{	return allocatedAmt;	}
		/** Discovers the total allocation that had been given to it. */
		public function get completeAllocation():uint	{	return fullAllocation;	}
=======
		/**
		 * Discover how many allocations are available.
		 */
		public function get completeAllocation():uint	{	return fullAllocation;	}
		public function get availAllocation():uint		{	return allocatedAmt;	}
>>>>>>> parent of 1ae3953... Removed duplicate folders
		
		// ---------------------------- SOUND CREATION & DESTRUCTION -------------------------
		
		/**
<<<<<<< HEAD
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
=======
		 * Removes the sound from list. This is usually called from within SoundClip.dispose().
		 * @param	sc		If sc does not exist in this SoundGroup, nothing happens.
		 */
		internal function killSound(sc:SoundClip):void
>>>>>>> parent of 1ae3953... Removed duplicate folders
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
<<<<<<< HEAD
		 * Creates a new ISoundClip belonging to this SoundGroup.
=======
		 * Creates a new SoundClip belonging to this SoundGroup.
>>>>>>> parent of 1ae3953... Removed duplicate folders
		 *
		 * @param	snd		Either retrieved from a sound repository, or directly instantiated.
		 * @param	autodispose		autodispose sounds have low priority and are the 1st to be
		 * overwritten when allocation is limited. They are self-disposable too.
		 *
		 * @return	null, if:
		 * 1. No allocation is available.
		 * 2. You created an autodispose sound.
<<<<<<< HEAD
		 * Else, it will return a handle to the ISoundClip you created.
		 */
		public function createSound(snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean = true):ISoundClip
		{
			var isSpareAllocated:Boolean = false;
=======
		 * Else, it will return a handle to the SoundClip you created.
		 */
		public function createSound(snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean = true):SoundClip
		{
>>>>>>> parent of 1ae3953... Removed duplicate folders
			// if not enough
			if (allocatedAmt <= 0)
			{
				// Cannibalise the autodispose list
				if (autoList.length > 0)
					autoList[0].dispose();
				// beg clemency from SoundMaster if it's autodisposable
				else if (autodispose && SoundMaster.getSpareAllocation())
<<<<<<< HEAD
				{
					// We note down the loan from SoundMaster
					isSpareAllocated = true;
				}
=======
				{}
>>>>>>> parent of 1ae3953... Removed duplicate folders
				else // Plea failed. the end.
					return null;
			}
			/* ---- Explanation for above choices
<<<<<<< HEAD
			 * We must cannibalise. Otherwise if allocations were maxed out, new sounds might not be
			 * played at all.
			 *
			 * But, we only allow auto-disposable sounds to use spareAllocation, otherwise the
			 * non-disposable sounds will hog the space and refuse to give it up.
=======
			 * We must cannibalise, otherwise without allocation, sounds might not be played, and
			 * the audio-kinesthetic connection players have will be ruined.
			 *
			 * But, we only allow auto-disposable sounds to use spareAllocation, otherwise the
			 * non-disposable sounds will hog the space and refuse to give it up.
			 *
			 * We removed an urgency flag because truly urgent sounds will NOT be autodisposable.
			 * After all, autodisposable = cannibalised.
>>>>>>> parent of 1ae3953... Removed duplicate folders
			 */
			
			allocatedAmt --;
			
<<<<<<< HEAD
			// Assigning the ISoundClip
			var cls:Class = sndProperties.type.clsRef;
			var sc:ISoundClip = new cls(this, snd, sndProperties, autodispose, isSpareAllocated,
								killSound) as ISoundClip;
=======
			// Assigning the SoundClip
			var sc:SoundClip;
			if (sndProperties.soundType == E_SoundTypes.MP3_LOOP)
				sc = new SoundMP3Loop(this, snd, sndProperties, autodispose);
			else
				sc = new SoundClip(this, snd, sndProperties, autodispose);
			
			// We note down the loan from SoundMaster
			if (allocatedAmt <= -1)
				sc.spareAllocation = true;
>>>>>>> parent of 1ae3953... Removed duplicate folders
			
			// Inserting the clip into its appropriate list
			if (autodispose)
			{
				autoList.push(sc);
				return null;
			}
			else
			{
				list.push(sc);
				return sc;
			}
		}
<<<<<<< HEAD
=======
		
		/**
		 * Kills all AUTO-DISPOSABLE sounds of this SoundGroup.
		 */
		public function killAutoSounds():void
		{
			while (autoList.length > 0)
				autoList.pop().dispose();
		}
>>>>>>> parent of 1ae3953... Removed duplicate folders
	}
}