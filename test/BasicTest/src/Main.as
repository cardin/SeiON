package
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import Extras.*;
	
	/**
	 * To test the various demos, substitute variable 'test' with either type:
	 * 	- AllocationTest
	 * 	- MP3GaplessTest
	 *  - TruncationTest
	 *
	 *  - PitchShiftTest
	 */
	[SWF(width = "400", height = "500", frameRate = "30", backgroundColor = "#808080")]
	//[SWF(width = "400", height = "300", frameRate = "30", backgroundColor = "#808080")]
	public class Main extends Sprite
	{
		private var test:AllocationTest;
		
		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			test = new AllocationTest(this);
		}
	}
}