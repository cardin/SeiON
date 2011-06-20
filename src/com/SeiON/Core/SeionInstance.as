package com.SeiON.Core
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.Core.Interface.ISeionInstance;
	import com.SeiON.SeionGroup;
	
	/** Defines the value when a SeionInstance finishes playback and does not repeat. */
	[Event(name = "soundComplete", type = "flash.events.Event")]
	/** Defines the value when a SeionInstance loops itself. */
	[Event(name = "soundRepeat", type = "com.SeiON.Event.SeionEvent")]
	/**
	 * The base class that all sound-playing Seion classes must inherit. Treat this like an Abstract
	 * class. Cannot be instantiated. Instead, use the respective subclasses'
	 * SeionInstance.create(). <p></p>
	 *
	 * SeionInstance adds control capabilities and is managed by SeionGroup as part of SeiON's
	 * effort to control the no. of SoundChannels playing simultaneously. Extend this class to
	 * create custom playback functionality that makes use of SeiON's allocation infrastructure.
	 */
	public class SeionInstance implements ISeionInstance
	{
		/**
		 * _name:		Name of this object
		 * _volume, _pan:	The adjustable property of the sound. Different from the sndTransform
		 * 					that's passed in the constructor
		 *
		 * _repeatLeft:			Times to repeat
		 * _repeat:	The fixed repeat count of the sound
		 *
		 * _sndTransform:		Holds the modded properties, after manager's properties are applied
		 * _fixedSndTransform:	The fixed property of the sound
		 *
		 * _manager:	The SeionGroup that manages this SeionInstance
		 * _snd:		The native Flash Sound() object
		 * _sndChannel:		SoundChannel created when Sound.play() is called
		 * _autodispose:	Whether this object will be automatically marked for GC
		 * _dispatcher:		Wrapper over EventDispatcher to support this obj's IEventDispatcher
		 */
		
		private var _name:String;
		private var _volume:Number = 1.0;
		private var _pan:Number = 0; /** @private */
		
		/** @private */
		protected var _repeatLeft:int;
		private var _repeat:int;
		
		/** @private */
		protected var _sndTransform:SoundTransform;
		private var _fixedSndTransform:SoundTransform;
		
		/** @private */
		protected var _manager:SeionGroup; /** @private */
		protected var _snd:Sound; /** @private */
		protected var _sndChannel:SoundChannel;
		private var _autodispose:Boolean;
		private var _dispatcher:EventDispatcher;
		
		/** A secret code passed in the constructor to ensure the constructor remains private. @private */
		protected static const _secretKey:Number = Math.random();
		
		/**
		 * Do not instantiate. Use the respective SeionInstance.create() instead.
		 *
		 * @throws	IllegalOperationError	When you try to directly instantiate ISeionInstance without
		 * using SeionGroup.createSound().
		 */
		public function SeionInstance(secretKey:*)
		{
			if (secretKey != _secretKey)
				throw new IllegalOperationError("SeionInstance's constructor not allowed for direct "
				+ "access! Please use SeionInstance.create() instead.");
		}
		
		/** The initialisation function. Auto-plays. @private */
		protected static function init(si:SeionInstance, name:String, manager:SeionGroup, snd:Sound,
							repeat:int,	autodispose:Boolean, sndTransform:SoundTransform):void
		{
			if (manager == null || snd == null)
				throw new ArgumentError("'manager' and 'snd' arguments cannot be null!");
			if (repeat == -1 && autodispose)
				throw new ArgumentError("You cannot have an infinitely repeating sound that is autodisposable!");
			
			if (sndTransform == null)
				sndTransform = new SoundTransform();
			
			si._name = name;
			si._manager = manager;
			si._snd = snd;
			si._repeat = si._repeatLeft = repeat;
			
			si._autodispose = autodispose;
			si._sndTransform = new SoundTransform(sndTransform.volume, sndTransform.pan);
			si._fixedSndTransform = new SoundTransform(sndTransform.volume, sndTransform.pan);
			
			si._dispatcher = new EventDispatcher(si);
			
			// pre-setting
			si.volume = 1;
			si.pan = 0;
			
			if (autodispose)
				si.play();
		}
		
		/***********************************************************************************
		 * 									IMPLEMENTED INTERFACE
		 ***********************************************************************************/
		
		/** Is the SeionInstance already disposed of? (ISeionInstance)
		 * @param	output	If true, a trace() message is given as well. */
		public function isDisposed(output:Boolean = true):Boolean
		{
			if (_manager == null)
			{
				if (output)	trace("This SeionInstance is already disposed, stop using this null reference!");
				return true;
			}
			return false;
		}
		
		// ----------------------------------- IEventDispatcher -----------------------------
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {	if (!isDisposed()) _dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);	}
		public function dispatchEvent(event:Event):Boolean	{	if (isDisposed()) return false; return _dispatcher.dispatchEvent(event); }
		public function hasEventListener(type:String):Boolean	{	if (isDisposed()) return false; return _dispatcher.hasEventListener(type);	}
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void	{	if (!isDisposed()) _dispatcher.removeEventListener(type, listener, useCapture);	}
		public function willTrigger(type:String):Boolean	{	if (isDisposed()) return false; return _dispatcher.willTrigger(type);	}
		
		// -------------------------------------- PROPERTIES --------------------------------
		
		/** The name of the clip, non-unique. (ISeionInstance) */
		public function get name():String {		return _name;	}
		public function set name(value:String):void	{	_name = value;	}
		
		/** Returns the manager that holds this ISeionInstance. (ISeionInstance) */
		public function get manager():SeionGroup	{	return _manager;	}
		
		/** Whether this sound is auto-disposable. (ISeionInstance) */
		public function get autodispose():Boolean	{	return _autodispose;	}
		
		/** Returns the predefined sound properties of the sound. (ISeionInstance) */
		public function get soundtransform():SoundTransform	{	return _fixedSndTransform;	}
		
		/**
		 *  How many times the SeionInstance is programmed to repeat itself. <br />
		 * 0 means no repeats.<br />
		 * -1 means infinite repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		public function get repeat():int	{	return _repeat;	}
		public function set repeat(value:int):void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			_repeatLeft = _repeat = Math.max( -1, value);
		}
		
		/**
		 * How many more times the SeionInstance has to repeat itself. To reset repeatLeft, set
		 * repeat. <br />
		 * 0 means no repeats.<br />
		 * -1 means infinite repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		public function get repeatLeft():int	{	return _repeatLeft;	}
		
		/**
		 * Get: The volume as affected by its parent. <p></p>
		 * Set: The personal adjustable volume unaffected by anything. <p></p>
		 *
		 * ISeionControl
		 */
		public function get volume():Number {	return _volume;	}
		public function set volume(value:Number):void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			_volume = value;
			
			// final Volume = native Volume * current Volume * parent's volume
			_sndTransform.volume = _fixedSndTransform.volume * _volume * _manager.volume;
			
			//assigning value back to soundChannel
			if (isPlaying)
				_sndChannel.soundTransform = _sndTransform;
		}
		
		/**
		 * Get: The panning as affected by its parent. <p></p>
		 * Set: The personal adjustable panning unaffected by anything. <p></p>
		 *
		 * ISeionControl
		 */
		public function get pan():Number {	return _pan;	}
		public function set pan(value:Number):void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			_pan = value;
			
			// Calculating Pan
			var panValue:Number; //local <- faster access
			
			var desiredDir:int = (_pan > 0) ? 1 : -1;
			var amtToMove:Number = (desiredDir - _fixedSndTransform.pan) * Math.abs(_pan);
			panValue = amtToMove + _fixedSndTransform.pan;
			
			//adding on the parent's panning
			desiredDir = (_manager.pan > 0) ? 1 : -1;
			amtToMove = (desiredDir - panValue) * Math.abs(_manager.pan);
			_sndTransform.pan = amtToMove + panValue;
			
			//assigning value back to soundChannel
			if (isPlaying)
				_sndChannel.soundTransform = _sndTransform;
		}
		
		/*****************************************************************************
		 * 									ABSTRACT
		 *****************************************************************************/
		
		public function dispose():void
		{
			_fixedSndTransform = null;
			_manager = null;
			_snd = null;
			_dispatcher = null;
		}
		
		public function play():void {}
		public function stop():void {}
		
		public function resume():void{}
		public function pause():void {}
		
		public function get isPaused():Boolean { return false; }
		public function get isPlaying():Boolean { return false; }
		
		public function get length():Number { return 0; }
		public function get position():Number { return 0; }
		public function get progress():Number { return 0; }
	}
}