package
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.text.*;
	
	import Components.*;
	
	import com.SeiON.Core.Interface.ISeionInstance
	import com.SeiON.Seion;
	import com.SeiON.SeionClip;
	import com.SeiON.SeionGroup;
	import com.SeiON.SeionSample;
	
	/**
	 * A simple test to show how gapless MP3 looping can be coded in SeiON, and
	 * the differences between gapless and a typical "gap"-ed MP3 looping.
	 */
	public class MP3GaplessTest
	{
		private const STOPPED:uint = 0;
		private const PAUSED:uint = 1;
		private const PLAYING:uint = 2;
		
		private const GAP:uint = 0;
		private const GAPLESS:uint = 1;
		
		// Retrieved from http://soundcloud.com/andremichelle/void-panic
		[Embed(source='../lib/void panic.mp3')]
		private var _snd_class:Class;
		private var _snd:Sound = new _snd_class as Sound;
		
		/**
		 * _testGrp: The SeionGroup that will play our sounds.
		 * _sndClip: The ISeionInstance that will hold either a SeionSample or SeionClip.
		 *
		 * _playStatus: The flag that indicates playing status.
		 * _mode: The flag that indicates mode.
		 */
		private var _testGrp:SeionGroup;
		private var _sndClip:ISeionInstance;
		
		private var _playStatus:uint = STOPPED;
		private var _mode:uint = GAP;
		
		/**
		 * Prepares for the test but does not run it.
		 * @see #startTest()
		 */
		public function MP3GaplessTest(container:DisplayObjectContainer)
		{
			_testGrp = Seion.createSeionGroup("MP3 Test Group", 2);
			init_render(container);
		}
		
		/** Plays the sound. If already playing, it will restart.
		 * @see SeionClip#create()
		 * @see SeionSample#createGaplessMP3() */
		public function startTest():void
		{
			stopTest();
			
			if (mode == GAP)	_sndClip = SeionClip.create("", _testGrp, _snd, -1, false);
			else				_sndClip = SeionSample.createGaplessMP3("", _testGrp, _snd, 124510, -1, false);
			
			_sndClip.play();
			
			_playStatus = PLAYING;
		}
		
		/** Pauses or resumes the music in the test. */
		public function pauseTest():void
		{
			if (_playStatus == PAUSED)
			{
				_sndClip.resume();
				_playStatus = PLAYING;
			}
			else if (_playStatus == PLAYING)
			{
				_sndClip.pause();
				_playStatus = PAUSED;
			}
		}
		
		/** Stops the music in the test. */
		public function stopTest():void
		{
			if (_playStatus != STOPPED) //either paused or playing
			{
				//_sndClip.stop(); //dispose() autocalls stop()
				_sndClip.dispose();
				_sndClip = null;
				
				_playStatus = STOPPED;
				bar.progress = 0;
			}
		}
		
		/**
		 * Whether gapless/gap mode is on.
		 *
		 * If test was playing/paused, the test will restart.
		 */
		public function get mode():uint	{	return _mode;	}
		public function set mode(value:uint):void
		{
			_mode = value;
			if (_playStatus != STOPPED)
				startTest();
		}
		
		/********************************************************************************
		 * 									RENDERING STUFF
		 ********************************************************************************/
		
		private var play_but: Button, stop_but: Button, mode_but: Button;
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
				+ "However, you'll have to self discover the proper sample length for the MP3. In "
				+ "addition, SeionSample is slightly more CPU intensive than SeionClip.</p>";
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
				case STOPPED: 	play_but.text = "Click to play"; break;
				case PAUSED: 	play_but.text = "Click to resume"; break;
				case PLAYING: 	play_but.text = "Click to pause"; break;
			}
			play_but.x = (play_but.stage.stageWidth / 2 - play_but.width) / 2;
			
			// Updating the MODE button
			switch (mode) {
				case GAP:		mode_but.text = "Normal Playback Behaviour"; break;
				case GAPLESS: 	mode_but.text = "Gapless MP3 Behaviour"; break;
			}
			mode_but.x = (play_but.stage.stageWidth - mode_but.width) / 2;
			
			// Updating the Progress bar
			if (_sndClip != null)
				bar.progress = _sndClip.progress;
		}
		
		/** Button handler for the 3 buttons */
		private function buttonHandler(e:Event):void
		{
			switch (e.target) {
				case play_but:
					if (_playStatus == STOPPED)	startTest();
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