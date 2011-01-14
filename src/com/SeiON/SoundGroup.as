package com.SeiON
{
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	import com.greensock.TimelineMax;
	
	import com.SeiON.Types.E_SoundTypes;
	
	/**
	 * In charge of near-global rationing of SoundClips, as well as their playback and properties.
	 * Its quota is fixed on instantiation. Use this as a top-level control element, not
	 * SoundMaster, as SoundMaster is supposed to be the Flash Player-level sound control.
	 *
	 * NOTE: SoundGroup is designed within the Audio API to be long-term. Try to create SoundGroups
	 * that encompasses large groups of sound and which represent a relevant sound category.
	 *
	 * @see	SoundMaster
	 */
	public final class SoundGroup implements ISoundControl
	{
		/** -- Misc --
		 * _volume: The adjustable volume of the SoundGroup
		 * _pan: The adjustable panning of the SoundGroup
		 * _tween: Animation
		 */
		private var _volume:Number = 1.0;
		private var _pan:Number = 0;
		private var _tween:TimelineMax = new TimelineMax();
		
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
		private var list:Vector.<SoundClip> = new Vector.<SoundClip>();
		private var autoList:Vector.<SoundClip> = new Vector.<SoundClip>();
		private var fullAllocation:uint;
		private var allocatedAmt:uint;
		
		/**
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
		
		// ISoundControl
		public function resume():void
		{
			// If SoundMaster is paused, we do not resume
			if (SoundMaster._this.isPaused())	return;
			
			if (isPaused())
			{
				_tween.resume();
				
				var sc:SoundClip;
				for each (sc in list)
					sc.resume();
				for each (sc in autoList)
					sc.resume();
			}
		}
		
		// ISoundControl
		public function pause():void
		{
			if (!isPaused())
			{
				_tween.pause();
				
				var sc:SoundClip;
				for each (sc in list)
					sc.pause();
				for each (sc in autoList)
					sc.pause();
			}
		}
		
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
		 *
		 * ISoundControl
		 */
		public function get volume():Number	{	return _volume * SoundMaster._this.volume;	}
		public function set volume(value:Number):void {		_volume = value;	}
		
		/**
		 * Same as volume.
		 *
		 * ISoundControl
		 */
		public function get pan():Number {	return _pan * SoundMaster._this.pan;	}
		public function set pan(value:Number):void	{	_pan = value;		}
		
		/**
		 * A tween that is tied into the controls.
		 * Use this as you would filters = [].
		 *
		 * ISoundControl
		 */
		public function get tween():TimelineMax {	return _tween; }
		public function set tween(value:TimelineMax):void
		{
			if (isPaused())
				value.pause();
			else
				value.resume();
				
			_tween = value;
		}
		
		/**
		 * Discover how many allocations are available.
		 */
		public function get completeAllocation():uint	{	return fullAllocation;	}
		public function get availAllocation():uint		{	return allocatedAmt;	}
		
		// ---------------------------- SOUND CREATION & DESTRUCTION -------------------------
		
		/**
		 * Removes the sound from list. This is usually called from within SoundClip.dispose().
		 * @param	sc		If sc does not exist in this SoundGroup, nothing happens.
		 */
		internal function killSound(sc:SoundClip):void
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
		 * Creates a new SoundClip belonging to this SoundGroup.
		 *
		 * @param	snd		Either retrieved from a sound repository, or directly instantiated.
		 * @param	autodispose		autodispose sounds have low priority and are the 1st to be
		 * overwritten when allocation is limited. They are self-disposable too.
		 *
		 * @return	null, if:
		 * 1. No allocation is available.
		 * 2. You created an autodispose sound.
		 * Else, it will return a handle to the SoundClip you created.
		 */
		public function createSound(snd:Sound, sndProperties:SoundProperties,
								autodispose:Boolean = true):SoundClip
		{
			// if not enough
			if (allocatedAmt <= 0)
			{
				// Cannibalise the autodispose list
				if (autoList.length > 0)
					autoList[0].dispose();
				// beg clemency from SoundMaster if it's autodisposable
				else if (autodispose && SoundMaster.getSpareAllocation())
				{}
				else // Plea failed. the end.
					return null;
			}
			/* ---- Explanation for above choices
			 * We must cannibalise, otherwise without allocation, sounds might not be played, and
			 * the audio-kinesthetic connection players have will be ruined.
			 *
			 * But, we only allow auto-disposable sounds to use spareAllocation, otherwise the
			 * non-disposable sounds will hog the space and refuse to give it up.
			 *
			 * We removed an urgency flag because truly urgent sounds will NOT be autodisposable.
			 * After all, autodisposable = cannibalised.
			 */
			
			allocatedAmt --;
			
			// Assigning the SoundClip
			var sc:SoundClip;
			if (sndProperties.soundType == E_SoundTypes.MP3_LOOP)
				sc = new SoundMP3Loop(this, snd, sndProperties, autodispose);
			else
				sc = new SoundClip(this, snd, sndProperties, autodispose);
			
			// We note down the loan from SoundMaster
			if (allocatedAmt <= -1)
				sc.spareAllocation = true;
			
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
		
		/**
		 * Kills all AUTO-DISPOSABLE sounds of this SoundGroup.
		 */
		public function killAutoSounds():void
		{
			while (autoList.length > 0)
				autoList.pop().dispose();
		}
	}
}