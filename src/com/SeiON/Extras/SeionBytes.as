package com.SeiON.Extras
{
    import flash.events.Event;
    import flash.events.SampleDataEvent;
    import flash.media.Sound;
    import flash.utils.ByteArray;

	import com.SeiON.Core.SeionProperty;
	
    /*
    // Pitch_Shift_MP3
    // Created by McFunkypants
    // http://www.mcfunkypants.com
    // http://twitter.com/mcfunkypants
    //
    // This class can play a looped sound and dynamically pitch-shift it during runtime.
    // Useful for engine sounds in racing games when you slow down or speed up.
    // Based heavily upon music code by A. Michelle - many thanks and grateful acknowledgements.
    //
    // Linkware: If you use this, kindly tweet/blog/post a link to it! =)
    */

	/**
	 * An ISeionInstance that can adjust pitch, and change starting offset, truncation, by specifying
	 * a byte range.
	 */
    public final class SeionBytes extends SeionClip
    {
		// -- Special Constant --
        private const BLOCK_SIZE: int = 3072;
		
		
        private var _mp3: Sound;
        private var out: Sound;
		
        private var _target: ByteArray;
        private var _position: Number;
        private var _rate: Number;
        private var _skip_bytes_at_start:uint;
        private var _skip_bytes_at_end:uint;

        public function SeionBytes(name:String, manager:SeionGroup, snd:Sound,
								sndProperties:SeionProperty, autodispose:Boolean, secretKey:*)
        {
			super(name, manager, sndTransform, sndProperties, autodispose, secretKey);
			
            // to make it loop nicer you can ignore the first few and last few bytes
            _skip_bytes_at_start = sndProperties.offset;
            _skip_bytes_at_end = snd.bytesTotal - sndProperties.duration;
			
            _target = new ByteArray();
            _position = 0.0;
            _rate = 0.0;
			
            out = new Sound();
            out.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
            out.play();
        }

        public function get rate(): Number{    return _rate;    }
        public function set rate( value: Number ): void
        {
            if( value < 0.0 ) value = 0;
            _rate = value;
        }

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
            var read: int = sound.extract( _target, need, positionInt );
            var n: int = read == need ? BLOCK_SIZE : read / _rate;
            var l0: Number;
            var r0: Number;
            var l1: Number;
            var r1: Number;
            for( var i: int = 0 ; i < n ; ++i )
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
                if (_position > sound.bytesTotal - _skip_bytes_at_end)
                {
                    _position = _skip_bytes_at_start;
                }
                alpha += _rate;
                while( alpha >= 1.0 ) --alpha;
            }
            if( i < BLOCK_SIZE )
            {
                while( i < BLOCK_SIZE )
                {
                    data.writeFloat( 0.0 );
                    data.writeFloat( 0.0 );
                    ++i;
                }
            }
            _position += scaledBlockSize;
        }
    }
}