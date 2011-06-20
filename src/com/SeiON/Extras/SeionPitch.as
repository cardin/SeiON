package com.SeiON.Extras
{
    import flash.events.Event;
    import flash.events.SampleDataEvent;
    import flash.media.Sound;
	import flash.media.SoundTransform;
    import flash.utils.ByteArray;

	import com.SeiON.Core.SeionInstance;
	import com.SeiON.Core.seion_ns;
	import com.SeiON.SeionGroup;
	
    /*
	 * Adapted from:
			Pitch_Shift_MP3
			Created by McFunkypants
			http://www.mcfunkypants.com
			http://twitter.com/mcfunkypants
			
			This class can play a looped sound and dynamically pitch-shift it during runtime.
			Useful for engine sounds in racing games when you slow down or speed up.
			Based heavily upon music code by A. Michelle - many thanks and grateful acknowledgements.
			
			Linkware: If you use this, kindly tweet/blog/post a link to it! =)
    */

	/**
	 * An ISeionInstance that can adjust pitch, and change starting offset, truncation, by specifying
	 * a byte range.
	 */
    public final class SeionPitch extends SeionInstance
    {
		// -- Special Constant --
        private const BLOCK_SIZE:int = 3072;
		
		/** -- Sampling Variables --
		 * _out: Use for output stream
		 * _target: Used for reading from input stream
		 *
		 * _position: The byte position of sampling
		 * _bytesOffset/Truncate: The delayed/shortened sample position
		 *
		 * _rate: Rate of playback
		 * _oldRate: Previous playback rate that is relevant
		 *
		 * _paused: Whether the clip is paused
		 */
        private var _out:Sound;
        private var _target:ByteArray;
		
        private var _position:Number;
        private var _bytesOffset:uint;
        private var _bytesTruncate:uint;
		
        private var _rate:Number;
		private var _oldRate:Number;
		
		private var _paused:Boolean = false;
		
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionPitch.create().
		 *
		 * @see SeionPitch#create()
		 */
        public function SeionPitch(secretKey:*)	{	super(secretKey);	}
		
		/** The initialisation function. */
		private static function init(sp:SeionPitch, name:String, manager:SeionGroup, snd:Sound,
										rate:Number, offset:uint, truncate:uint, repeat:int,
										autodispose:Boolean, sndTransform:SoundTransform):void
		{
			// to make it loop nicer you can ignore the first few and last few bytes
            sp._bytesOffset = offset;
            sp._bytesTruncate = truncate;
			sp._rate = sp._oldRate = rate;
			
			sp._position = 0.0;
			sp._out = new Sound();
            sp._target = new ByteArray();
			
			SeionInstance.init(sp, name, manager, snd, repeat, autodispose, sndTransform);
		}
		
		/**
		 * Creates a sound clip that can be pitch-shifted. <p></p>
		 * Note that not the full length of clip will be faithfully reproduced due to latency issues.
		 *
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionSample. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	rate		The rate of playback.
		 * @param	repeat			How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionPitch if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	SeionInstance#name
		 * @see SeionInstance#manager
		 * @see #length
		 * @see #rate
		 * @see SeionInstance#repeat
		 * @see SeionInstance#autodispose
		 * @see SeionInstance#soundTransform
		 */
		public static function create(name:String, manager:SeionGroup, snd:Sound,
						rate:Number, repeat:int,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionPitch
		{
			return createExcerpt(name, manager, snd, rate, 0, 0, repeat, autodispose, sndTransform);
		}
		
		/**
		 * Creates a sound clip that can be pitch-shifted. <p></p>
		 *
		 * Note that because of latency issues, the length of the clip, its offset and truncate
		 * values will not be meaningful.
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionSample. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	rate		The rate of playback.
		 * @param	offset		The approximate delayed starting position. In Bytes. Immutable.
		 * @param	truncate	The approximate truncation from the ending position. In Bytes. Immutable.
		 * @param	repeat			How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionPitch if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	SeionInstance#name
		 * @see SeionInstance#manager
		 * @see #length
		 * @see #rate
		 * @see SeionInstance#repeat
		 * @see SeionInstance#autodispose
		 * @see SeionInstance#soundTransform
		 */
		public static function createExcerpt(name:String, manager:SeionGroup, snd:Sound,
						rate:Number, offset:uint, truncate:uint, repeat:int,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionPitch
		{
			var a:SeionPitch = new SeionPitch(SeionInstance._secretKey);
			if (manager.seion_ns::alloc(a, autodispose))
			{
				SeionPitch.init(a, name, manager, snd, rate, offset, truncate, repeat,
								autodispose, sndTransform);
				if (autodispose)	a = null;
			}
			else
				a = null;
			
			return a;
		}
		
		// ------------------------------------- ABSTRACT ----------------------------------
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		override public function dispose():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			stop();
			_out = null;
			_target.clear();
			_target = null;
			
			_manager.seion_ns::killSound(this);
			super.dispose();
		}
		
		/** Plays the sound from the beginning again. (ISeionInstance) */
		override public function play():void
		{
			stop(); // to go to the beginning
			_paused = true; // to trigger resume
			resume(); // 'cos play() is essentially resume() from 0
		}
		
		/** Stops the sound and resets it to Zero. (ISeionInstance) */
		override public function stop():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			if (isPlaying || isPaused)
			{
				if (_sndChannel)
				{
					_sndChannel.stop();
					_sndChannel = null;
				}
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				_target.clear();
				_position = 0.0;
				_paused = false;
			}
			
			if (_rate != 0)		_oldRate = _rate; // since _oldRate must always be non-zero
		}
		
		/** Resumes playback of sound. (ISeionControl) */
		override public function resume():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// Resume only if Manager not paused && this clip was paused
			if (!manager.isPaused && isPaused)
			{
				if (_oldRate == 0)	_oldRate = 1; // safeguard
				_rate = _oldRate;
				_out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				_sndChannel = _out.play(0, 0, _sndTransform);
				_paused = false;
			}
		}
		
		/** Pauses playback of sound. (ISeionControl) */
		override public function pause():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			if (isPlaying)
			{
				_sndChannel.stop();
				_sndChannel = null;
				_out.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
				_paused = true;
				_target.clear();
				
				_oldRate = _rate;
				_rate = 0;
			}
		}
		
		/**********************************************************************************
		 *	 									PROPERTIES
		 **********************************************************************************/
		
		/** Rate of playback of the clip.<p></p>
		 *
		 * 1.0 is normal speed, 0.5 is half speed, 2.0 is twice faster.<br>
		 * Range: 0 to 50 (0.005 precision)<p></p>
		 *
		 * Rate is tied into pause and resume.<br>
		 * When rate is set at 0, the sound is paused. Setting it to a value higher than 0 will
		 * resume it. Likewise, when a sound is paused, rate is 0. Resuming it will give the last
		 * non-zero rate. */
        public function get rate():Number	{	return _rate;	}
        public function set rate(value:Number):void
		{
			value = Math.max(0, Math.min(value, 50));
			value = Math.round(value * 200) / 200;
			if (value == 0) //pause
				pause(); // which will handle _oldRate and stuff
			else if (isPaused) //resume
			{
				_oldRate = value;
				resume();
			}
			else //store value
				_rate = value;
		}
		
		/** The approximate delayed starting position. In bytes. */
		public function get offset():uint	{	return _bytesOffset;	}
		/** The approximate truncation from the ending position. In bytes. */
		public function get truncate():uint	{	return _bytesTruncate;	}
		
		// ------------------------------------- ABSTRACT ----------------------------------
		
		/** Is the sound active? (ISeionInstance) */
		override public function get isPlaying():Boolean
		{
			// Checking for dispose
			if (isDisposed())	return false;
			return _out.hasEventListener(SampleDataEvent.SAMPLE_DATA);
		}
		
		/** Is the playback paused? (ISeionControl) */
		override public function get isPaused():Boolean	{	return _paused;	}
		
		/** The total length of the clip, excluding repeats. In Milliseconds. <p></p>
		 *
		 * Because of latency issues, the length of playback is inaccurate. (ISeionInstance) */
		override public function get length():Number { return _snd.length; }
		
		/** Invalid */
		override public function get position():Number {	return 0;	}
		/** Invalid */
		override public function get progress():Number	{	return 0;	}
		
		/*********************************************************************************
		 * 								EXTRACTION AND LOOPING METHODS
		 *********************************************************************************/
		
		/**
		 * Called with every extraction of sound data by SampleDataEvent.
		 */
        private function sampleData( event: SampleDataEvent ): void
        {
            _target.position = 0;
			
            var data: ByteArray = event.data;
            var scaledBlockSize: Number = BLOCK_SIZE * _rate;
            var positionInt: int = _position;
            var alpha: Number = _position - positionInt;
            var positionTargetNum: Number = alpha;
            var positionTargetInt: int = -1;
            var need: int = Math.ceil( scaledBlockSize ) + 2;
            var read: int = _snd.extract( _target, need, positionInt );
            var n: int = read == need ? BLOCK_SIZE : read / _rate;
            var l0: Number;
            var r0: Number;
            var l1: Number;
            var r1: Number;
			
			var i:int;
            for(i = 0; i <= n; i++)
            {
                if( int( positionTargetNum ) != positionTargetInt )
                {
                    positionTargetInt = positionTargetNum;
                    _target.position = positionTargetInt << 3;
                    l0 = _target.readFloat();
                    r0 = _target.readFloat();
                    l1 = _target.readFloat();
                    r1 = _target.readFloat();
                }
                data.writeFloat( l0 + alpha * ( l1 - l0 ) );
                data.writeFloat( r0 + alpha * ( r1 - r0 ) );
                positionTargetNum += _rate;
                if (_position > _snd.bytesTotal - _bytesTruncate)
                    _position = _bytesOffset;

                alpha += _rate;
                while( alpha >= 1.0 ) --alpha;
            }
            if( i < BLOCK_SIZE )
            {
                while( i < BLOCK_SIZE )
                {
                    data.writeFloat( 0.0 );
                    data.writeFloat( 0.0 );
                    i++;
                }
            }
            _position += scaledBlockSize;
        }
    }
}