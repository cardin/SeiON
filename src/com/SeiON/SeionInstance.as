package com.SeiON
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import com.SeiON.SeionGroup;
	
	/**
	 * The base class that all sound-playing Seion classes must inherit. Treat this like an Abstract
	 * class. Cannot be instantiated. Instead, use the respective subclasses' SeionInstance.create().
	 *
	 * SeionInstance adds control capabilities and is managed by SeionGroup as part of SeiON's
	 * effort to control the no. of SoundChannels playing simultaneously.
	 */
	public class SeionInstance implements ISeionInstance
	{
		/**
		 * _name:		Name of this object
		 * _volume, _pan:	The adjustable property of the sound. Different from the sndTransform
		 * 					that's passed in the constructor
		 * _repeat:		Times to repeat
		 *
		 * _initialRepeat:	The fixed repeat count of the sound
		 * _sndTransform:	The fixed property of the sound
		 *
		 * _manager:	The SeionGroup that manages this SeionInstance
		 * _snd:		The native Flash Sound() object
		 * _sndChannel:		SoundChannel created when Sound.play() is called
		 * _autodispose:	Whether this object will be automatically marked for GC
		 * _dispatcher:		The place to listen for events from SeionClip
		 */
		
		private var _name:String;
		private var _volume:Number = 1.0;
		private var _pan:Number = 0; /** @private */
		protected var _repeat:int;
		
		private var _initialRepeat:int;
		private var _sndTransform:SoundTransform;
		
		/** @private */
		protected var _manager:SeionGroup; /** @private */
		protected var _snd:Sound;
		protected var _sndChannel:SoundChannel;
		private var _autodispose:Boolean;
		private var _dispatcher:EventDispatcher;
		
		// A secret code passed in the constructor to ensure the constructor remains private.
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
		
		/** The initialisation function. */
		protected static function init(si:SeionInstance, name:String, manager:SeionGroup, snd:Sound,
							repeat:int,	autodispose:Boolean, sndTransform:SoundTransform):void
		{
			if (manager == null || snd == null)
				throw new ArgumentError("Arguments cannot be null!");
			
			if (sndTransform == null)
				sndTransform = new SoundTransform();
			
			si._name = name;
			si._manager = manager;
			si._snd = snd;
			si._repeat = repeat;
			
			si._autodispose = autodispose;
			si._sndTransform = new SoundTransform(sndTransform.volume, sndTransform.pan);
			
			si._dispatcher = new EventDispatcher();
			
			if (autodispose)
				si.play();
		}
		
		/***********************************************************************************
		 * 									IMPLEMENTED FUNCTIONS
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
		
		/** The name of the clip, non-unique. (ISeionInstance) */
		public function get name():String {		return _name;	}
		public function set name(value:String):void	{	_name = value;	}
		
		/** Returns the manager that holds this ISeionInstance. (ISeionInstance) */
		public function get manager():SeionGroup	{	return _manager;	}
		
		/** Whether this sound is auto-disposable. (ISeionInstance) */
		public function get autodispose():Boolean	{	return _autodispose;	}
		
		/** Fires off Event.SOUND_COMPLETE and/or SeionEvent.SOUND_REPEAT. (ISeionInstance) */
		public function get dispatcher():EventDispatcher	{	return _dispatcher;	}
		
		/** Returns the predefined sound properties of the sound. (ISeionInstance) */
		public function get soundtransform():SoundTransform	{	return _sndTransform;	}
		
		/**
		 *  How many times the SeionInstance is programmed to repeat itself. <br />
		 * 0 means infinite repeats.<br />
		 * -1 means no repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		public function get repeat():int	{	return _initialRepeat;	}
		public function set repeat(value:int):void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			_repeat = _initialRepeat = Math.max( -1, value);
		}
		
		/**
		 * How many more times the SeionInstance has to repeat itself. To reset repeatLeft, set
		 * repeat. <br />
		 * 0 means infinite repeats.<br />
		 * -1 means no repeats.<p></p>
		 *
		 * ISeionInstance
		 */
		public function get repeatLeft():int	{	return _repeat;	}
		
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
			
			if (isPlaying)
			{
				var volValue:Number;
				
				// final Volume = native Volume * current Volume * parent's volume
				volValue = _sndTransform.volume * _volume * _manager.volume;
				
				//assigning value back to soundChannel
				var channelSndTransform:SoundTransform = _sndChannel.soundTransform;
				channelSndTransform.volume = volValue;
				_sndChannel.soundTransform = channelSndTransform;
			}
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
			
			if (isPlaying)
			{
				var panValue:Number;
				
				var desiredDir:int = (_pan > 0) ? 1 : -1;
				var amtToMove:Number = (desiredDir - _sndTransform.pan) * Math.abs(_pan);
				panValue = amtToMove + _sndTransform.pan;
				
				//adding on the parent's panning
				desiredDir = (_manager.pan > 0) ? 1 : -1;
				amtToMove = (desiredDir - panValue) * Math.abs(_manager.pan);
				panValue = amtToMove + panValue;
				
				//assigning value back to soundChannel
				var channelSndTransform:SoundTransform = _sndChannel.soundTransform;
				channelSndTransform.pan = panValue;
				_sndChannel.soundTransform = channelSndTransform;
			}
		}
		
		/*****************************************************************************
		 * 									ABSTRACT
		 *****************************************************************************/
		
		public function dispose():void
		{
			isDisposed();
			
			_sndTransform = null;
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