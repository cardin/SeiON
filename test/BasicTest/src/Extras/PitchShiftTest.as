package Extras
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.text.*;
	import flash.ui.Keyboard;
	
	import Components.*;
	
	import com.SeiON.Seion;
	import com.SeiON.SeionGroup;
	import com.SeiON.Extras.SeionPitch;
	
	/**
	 * A really fun demo to test SeionPitch's pitch adjustment rate.
	 */
	public class PitchShiftTest
	{
		// Retrieved from http://soundcloud.com/andremichelle/void-panic
		[Embed(source='../../lib/void panic.mp3')]
		private var _snd_class:Class;
		private var _snd:Sound = new _snd_class as Sound;
		
		private var _testGrp:SeionGroup;
		private var _sndClip:SeionPitch;
		
		/**
		 * Prepares for the test but does not run it.
		 * @see #startTest()
		 */
		public function PitchShiftTest(container:DisplayObjectContainer)
		{
			_testGrp = Seion.createSeionGroup("MP3 Test Group", 2);
			_sndClip = SeionPitch.create("", _testGrp, _snd, 1.0, -1, false);
			init_render(container);
		}
		
		/** Starts the sound playing. But if sound is alrdy playing, then this pauses it.*/
		public function startTest():void
		{
			if (_sndClip.isPaused) // resume
				_sndClip.resume();
			else if (_sndClip.isPlaying) // pause
				changeRate(0); // _sndClip.pause() also works
			else // just play
				_sndClip.play();
		}
		
		/** Stops the sound playing. */
		public function stopTest():void
		{
			_sndClip.stop();
		}
		
		/** Changes rate of playback. */
		public function changeRate(value:Number):void
		{
			_sndClip.rate = value;
		}
		
		/********************************************************************************
		 * 									RENDERING STUFF
		 ********************************************************************************/
		
		private var play_but: Button, stop_but: Button
		private var rateMeter: TextField = new TextField();;
		private var descript: TextField = new TextField();
		
		/** Gets the UI onstage */
		private function init_render(container:DisplayObjectContainer):void
		{
			play_but = new Button(0, 25, "", 0x80FF00);
			play_but.x = (container.stage.stageWidth / 2 - play_but.width) / 2;
			
			stop_but = new Button(0, 25, "Click to Stop", 0xFF4040);
			stop_but.x = (container.stage.stageWidth / 2 - stop_but.width) / 2 + container.stage.stageWidth / 2;
			
			rateMeter.mouseEnabled = false;
			rateMeter.autoSize = TextFieldAutoSize.LEFT;
			rateMeter.y = play_but.y + 2;
			
			// writing description text
			descript.multiline = true;
			descript.wordWrap = true;
			descript.mouseEnabled = false;
			descript.htmlText = "<p align='justify'>SeionPitch allows pitch shifting of a sound. "
				+ "However due to latency, fractions of a second are cut out, so SeionPitch "
				+ "should ideally be used only for some looping sounds. To hear the cut-off point "
				+ "in this example, it's recommended that you turn up the bass of your speakers to "
				+ "hear better.</p><br>"
				+ "<p align='center'><b>Use Arrow Keys to adjust Pitch Rate.</b></p><br>"
				+ "<p align='justify'>Shifting the rate to 0.0 causes SeionPitch to pause. When a "
				+ "paused SeionPitch's rate goes above 0.0, it auto-resumes as well.</p>";
			descript.x = 25;
			descript.y = 70;
			descript.width = 350;
			descript.height = 200;
			
			// Adding to stage
			container.addChild(play_but);
			container.addChild(stop_but);
			container.addChild(rateMeter);
			container.addChild(descript);
			
			play_but.addEventListener(MouseEvent.CLICK, buttonHandler);
			stop_but.addEventListener(MouseEvent.CLICK, buttonHandler);
			container.addEventListener(Event.ENTER_FRAME, update);
			container.stage.addEventListener(KeyboardEvent.KEY_DOWN, update);
		}
		
		/** Updates the UI display, and checks the rate. */
		private function update(e:Event):void
		{
			// Updating the PLAY button
			if (_sndClip.isPlaying)
				play_but.text = "Click to pause";
			else if (_sndClip.isPaused)
				play_but.text = "Click to resume";
			else
				play_but.text = "Click to play";
			play_but.x = (play_but.stage.stageWidth / 2 - play_but.width) / 2;
			
			// KeyPress Chk
			if (e.type == KeyboardEvent.KEY_DOWN)
			{
				var ke:KeyboardEvent = e as KeyboardEvent;
				if (ke.keyCode == Keyboard.RIGHT)		changeRate(_sndClip.rate + 0.1);
				else if (ke.keyCode == Keyboard.LEFT)	changeRate(_sndClip.rate - 0.1);
			}
			rateMeter.htmlText = "<b>Rate: " + _sndClip.rate + "</b>";
			rateMeter.x = (rateMeter.stage.stageWidth - rateMeter.width) / 2;
		}
		
		/** Button handler */
		private function buttonHandler(e:Event):void
		{
			switch(e.target)
			{
				case play_but:
					startTest();
					break;
				case stop_but:
					stopTest();
					break;
			}
		}
	}
}