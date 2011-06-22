package com.SeiON.Extras
{
	import flash.media.SoundTransform;
	import flash.media.Sound;
	
	import com.SeiON.Core.SeionInstance;
	import com.SeiON.Core.seion_ns;
	import com.SeiON.SeionGroup;
	
	use namespace seion_ns;
	
	/**
	 * An example class that demarcates how to create custom seion sound objects.
	 */
    public final class SeionExample extends SeionInstance
    {
		/**
		 * Please do not call this constructor directly; it will throw an error. Call it through
		 * SeionPitch.create().
		 *
		 * @see SeionExample#create()
		 */
        public function SeionExample(secretKey:*)	{	super(secretKey);	}
		
		/** The initialisation function. */
		private static function init(se:SeionExample, name:String, manager:SeionGroup, snd:Sound,
										manyOfYourOwnParameters:*, repeat:int,
										autodispose:Boolean, sndTransform:SoundTransform):void
		{
			// ...
			// ...
			// assigning your properties and variables here
			// ...
			// ...
			
			SeionInstance.init(se, name, manager, snd, repeat, autodispose, sndTransform);
		}
		
		/**
		 * @param	name	Any name, even a non-unique one.
		 * @param	manager	The SeionGroup that manages this SeionSample. Immutable.
		 * @param	snd 	The sound data. Immutable.
		 * @param	repeat			How many times to repeat the clip.
		 * @param	autodispose		Whether the clip will auto-mark for GC. Immutable.
		 * @param	sndTransform	The fixed internal property for the sound.
		 *
		 * @return	A SeionExample if allocation was successful. Null if allocation failed, or
		 * autodispose is true.
		 *
		 * @see	SeionInstance#name
		 * @see SeionInstance#manager
		 * @see SeionInstance#repeat
		 * @see SeionInstance#autodispose
		 * @see SeionInstance#soundTransform
		 */
		public static function createExcerpt(name:String, manager:SeionGroup, snd:Sound,
						manyOfYourOwnParameters:*, repeat:int,
						autodispose:Boolean = true, sndTransform:SoundTransform = null):SeionExample
		{
			var a:SeionExample = new SeionExample(SeionInstance._secretKey);
			if (manager.alloc(a, autodispose))
			{
				SeionExample.init(a, name, manager, snd, manyOfYourOwnParameters, repeat,
								autodispose, sndTransform);
				if (autodispose)	a = null;
			}
			else
				a = null;
			
			return a;
		}
		
		/*****************************************************************************
		 * 										ABSTRACT
		 *****************************************************************************/
		
		/** Clears all references held. This object is now invalid. (ISeionInstance) */
		override public function dispose():void
		{
			// Checking for dispose
			if (isDisposed())	return;
			
			// ...
			// ...
			// Disposing your own variables here
			// ...
			// ...
			
			_manager.killSound(this);
			super.dispose();
		}
		
		/*
		public function play():void {}
		public function stop():void {}
		
		public function resume():void{}
		public function pause():void {}
		
		public function get isPaused():Boolean { return false; }
		public function get isPlaying():Boolean { return false; }
		
		public function get length():Number { return 0; }
		public function get position():Number { return 0; }
		public function get progress():Number { return 0; } */
	}
}