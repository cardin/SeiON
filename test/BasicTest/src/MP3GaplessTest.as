package
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import com.SeiON.ISeionInstance;
	import com.SeiON.Seion;
	import com.SeiON.SeionClip;
	import com.SeiON.SeionGroup;
	import com.SeiON.SeionSample;
	
	import Components.Button;
	import Components.ProgressBar;
	
	/**
	 * A simple test to show how gapless MP3 looping can be coded in SeiON, and
	 * the differences between gapless and a typical "gap"-ed MP3 looping.
	 */
	public class MP3GaplessTest
	{
		// Retrieved from http://soundcloud.com/andremichelle/void-panic
		[Embed(source='../lib/void panic.mp3')]
		private var snd_class:Class;
		private var snd:Sound;
		
		/**
		 * testGrp: A SeionGroup so that we can call its factory method for creating a SeionClip.
		 * sndClip: The SeionClip containing the Sound that we want to play.
		 *
		 * _playStatus: 0 = not playing, 1 = paused, 2 = playing
		 * _mode: 0 = with gap, 1 = gapless
		 */
		private var testGrp:SeionGroup;
		private var sndClip:ISeionInstance;
		
		private var _playStatus:uint = 0;
		private var _mode:uint = 0;
		
		/**
		 * Prepares for the test but does not run it.
		 *
		 * @see #startTest()
		 */
		public function MP3GaplessTest(container:DisplayObjectContainer)
		{
			snd = new snd_class() as Sound;
			testGrp = Seion.createSeionGroup("MP3 Test Group", 2);
			
			init_render(container);
		}
		
		/**
		 * Starts the playback test. If originally playing, it will restart.
		 */
		public function startTest():void
		{
			stopTest();
			
			if (mode == 0) // gap
				sndClip = SeionClip.create("", testGrp, snd, -1, false);
			else //gapless
				sndClip = SeionSample.createGaplessMP3("", testGrp, snd, 124510, false);
			
			sndClip.play();
			
			_playStatus = 2;
		}
		
		/** Pauses or resumes the music in the test. */
		public function pauseTest():void
		{
			if (_playStatus == 1) //resume
			{
				sndClip.resume();
				_playStatus = 2;
			}
			else if (_playStatus == 2) // pause
			{
				sndClip.pause();
				_playStatus = 1;
			}
		}
		
		/** Stops the music in the test. */
		public function stopTest():void
		{
			if (_playStatus != 0) //either paused or playing
			{
				sndClip.stop();
				sndClip.dispose();
				sndClip = null;
				// It's up to you whether you want to dispose() of SeionClip or not. We could have
				// simply reused it again in startTest() instead of creating another new SeionClip.
				
				_playStatus = 0;
				bar.progress = 0;
			}
		}
		
		/**
		 * Whether the test is running with gapless enabled or not. If test was originally playing,
		 * the test will restart from the beginning after mode is set. <p></p>
		 *
		 * 0 = with gap, 1 = gapless <p></p>
		 */
		public function get mode():uint	{	return _mode;	}
		public function set mode(value:uint):void
		{
			_mode = value;
			if (_playStatus != 0)
				startTest();
		}
		
		/********************************************************************************
		 * 									RENDERING STUFF
		 ********************************************************************************/
		
		private var play_but: Button;
		private var stop_but: Button;
		private var mode_but: Button;
		
		private var bar:ProgressBar;
		
		private var descript:TextField = new TextField();
		
		/** Gets the UI onstage */
		private function init_render(container:DisplayObjectContainer):void
		{
			play_but = new Button(0, 25, "", 0x80FF00);
			play_but.x = (container.stage.stageWidth / 2 - play_but.width) / 2;
			
			stop_but = new Button(0, 25, "Click to Stop", 0xFF4040);
			stop_but.x = (container.stage.stageWidth / 2 - stop_but.width) / 2 + container.stage.stageWidth / 2;
			
			mode_but = new Button(0, 210, "", 0x00FFFF);
			mode_but.x = (container.stage.stageWidth - mode_but.width) / 2;
			
			bar = new ProgressBar(100, 265, 200);
			
			// writing description text
			descript.multiline = true;
			descript.wordWrap = true;
			descript.mouseEnabled = false;
			descript.htmlText = "<p align='justify'>Normal Playback Behaviour uses SeionClip, "
				+ "which can play native Flash Sound objects. However for MP3, the Flex compiler "
				+ "cannot enable <u>gapless looping</u> playback of embedded MP3. Hence you'll "
				+ "notice a mild pause at the end of every loop.</p><br>"
				+ "<p align='justify'>Gapless MP3 Behaviour uses SeionSample to solve this problem. "
				+ "However, the MP3 has to be encoded via the LAME MP3 encoder (eg. Audacity), "
				+ "and the sample length value passed to SeiON. In addition, SeionSample is slightly "
				+ "more CPU intensive than SeionClip.</p>";
			descript.x = 25;
			descript.y = 70;
			descript.width = 400;
			descript.height = 200;
			descript.scaleX = descript.scaleY = 0.9;
			
			// Adding to stage
			container.addChild(play_but);
			container.addChild(stop_but);
			container.addChild(mode_but);
			container.addChild(bar);
			container.addChild(descript);
			
			play_but.addEventListener(MouseEvent.CLICK, buttonHandler);
			stop_but.addEventListener(MouseEvent.CLICK, buttonHandler);
			mode_but.addEventListener(MouseEvent.CLICK, buttonHandler);
			container.addEventListener(Event.ENTER_FRAME, render);
		}
		
		/** Updates buttons and UI display. */
		private function render(e:Event):void
		{
			// Updating the PLAY button
			switch (_playStatus) {
				case 0: play_but.text = "Click to play"; break;
				case 1: play_but.text = "Click to resume"; break;
				case 2: play_but.text = "Click to pause"; break;
			}
			play_but.x = (play_but.stage.stageWidth / 2 - play_but.width) / 2;
			
			// Updating the MODE button
			switch (mode) {
				case 0:	mode_but.text = "Normal Playback Behaviour"; break;
				case 1: mode_but.text = "Gapless MP3 Behaviour"; break;
			}
			mode_but.x = (play_but.stage.stageWidth - mode_but.width) / 2;
			
			// Updating the Progress bar
			if (sndClip != null)
				bar.progress = sndClip.progress;
		}
		
		/** Button handler for the 3 buttons */
		private function buttonHandler(e:Event):void
		{
			if (e.type == MouseEvent.CLICK)
			{
				switch (e.target) {
					case play_but:
						if (_playStatus == 0)	startTest();
						else	pauseTest();
						break;
					case stop_but:
						stopTest();
						break;
					case mode_but:
						mode = (mode + 1) % 2;
						break;
				}
			}
		}
	}
}