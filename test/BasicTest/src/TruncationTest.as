package
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.text.TextField;
	
	import com.SeiON.Seion;
	import com.SeiON.SeionClip;
	import com.SeiON.SeionGroup;
	
	import Components.Button;
	import Components.RangeProgressSlider;
	
	/**
	 * A simple test to show how to use the offset and duration properties of SeionProperty,
	 * to generate different sounds out of a single source.
	 */
	public class TruncationTest
	{
		// Retrieved from http://www.jazzhouseblues.com/
		[Embed(source='../lib/Muffin Man Swing.mp3')]
		private var snd_class:Class;
		private var snd:Sound;
		
		// The SeionGroup to hold our SeionClips
		private var sndGrp:SeionGroup;
		
		private var sndClip1:SeionClip;
		private var sndClip2:SeionClip;
		private var sndClip3:SeionClip;
		
		// 3 diff properties to be applied
		private var offset1:uint, truncate1:uint;
		private var offset2:uint, truncate2:uint;
		private var offset3:uint, truncate3:uint;
		
		public function TruncationTest(container: DisplayObjectContainer)
		{
			snd = new snd_class() as Sound;
			sndGrp = Seion.createSeionGroup("", 3);
			// for caution, I don't advise cutting it this close [3] for production usage.
			
			init_render(container);
		}
		
		/** Starts playing the sound using the selected property. */
		public function startTest(choice:uint):void
		{
			var sc:SeionClip = this["sndClip" + choice];
			
			if (sc == null) //not created yet
			{
				this["sndClip" + choice] = SeionClip.createExcerpt("", sndGrp, snd, 0, false, null,
												this["offset" + choice], this["truncate" + choice]);
				this["sndClip" + choice].play();
			}
			else //pause the existing sc
			{
				if (sc.isPlaying)	sc.pause();
				else 				sc.resume();
			}
		}
		
		/** Stops the sound with the selected property from playing. */
		public function stopTest(choice:uint):void
		{
			var sc:SeionClip = this["sndClip" + choice];
			if (sc == null) // if not created, then nothing to stop
				return;
			
			sc.stop();
			sc.dispose();
			this["sndClip" + choice] = null;
		}
		
		// ================================ RENDERING FUNCTIONS ===========================
		
		private var play1:Button;
		private var stop1:Button;
		private var play2:Button;
		private var stop2:Button;
		private var play3:Button;
		private var stop3:Button;
		
		private var slider1:RangeProgressSlider;
		private var slider2:RangeProgressSlider;
		private var slider3:RangeProgressSlider;
		
		private var descript:TextField = new TextField();
		
		/** Sets up the stage for UI and buttons. */
		private function init_render(container:DisplayObjectContainer):void
		{
			play1 = new Button(10, 115, "Play", 0x80FF00);
			stop1 = new Button(51, 140, "Stop", 0xFF4040);
			play2 = new Button(10, 175, "Play", 0x80FF00);
			stop2 = new Button(51, 200, "Stop", 0xFF4040);
			play3 = new Button(10, 235, "Play", 0x80FF00);
			stop3 = new Button(51, 260, "Stop", 0xFF4040);
			
			slider1 = new RangeProgressSlider(150, 140, 200);
			slider2 = new RangeProgressSlider(150, 200, 200);
			slider3 = new RangeProgressSlider(150, 260, 200);
			
			slider1.lRange = 0.03;		slider1.rRange = 0.1;
			slider2.lRange = 0.21;		slider2.rRange = 0.325;
			slider3.lRange = 0.43;		slider3.rRange = 0.68;
			
			// writing description text
			descript.multiline = true;
			descript.wordWrap = true;
			descript.mouseEnabled = false;
			descript.htmlText = "<p align='justify'>ISeionInstances are created from a sound source "
				+ "and a SeionProperty. By having different SeionProperties, one can generate "
				+ "variations using a single source. </p><br>"
				+ "<p align='justify'>Besides volume and panning, SeionClips can also vary the "
				+ "starting offset and duration. Here, shorter sounds are generated using portions "
				+ "of a longer sound. Note that this feature is not available to SeionSample.</p>";
			descript.x = 25;
			descript.y = 10;
			descript.width = 400;
			descript.height = 100;
			descript.scaleX = descript.scaleY = 0.9;
			
			container.addChild(slider1);
			container.addChild(slider2);
			container.addChild(slider3);
			container.addChild(play1);
			container.addChild(stop1);
			container.addChild(play2);
			container.addChild(stop2);
			container.addChild(play3);
			container.addChild(stop3);
			container.addChild(descript);
			
			play1.addEventListener(MouseEvent.CLICK, buttonHandler);
			stop1.addEventListener(MouseEvent.CLICK, buttonHandler);
			play2.addEventListener(MouseEvent.CLICK, buttonHandler);
			stop2.addEventListener(MouseEvent.CLICK, buttonHandler);
			play3.addEventListener(MouseEvent.CLICK, buttonHandler);
			stop3.addEventListener(MouseEvent.CLICK, buttonHandler);
			container.addEventListener(Event.ENTER_FRAME, render);
		}
		
		/** Updates the UI on the stage. */
		private function render(e:Event):void
		{
			// Updating buttons
			for (var i:int = 1; i < 4; i++)
			{
				if (this["sndClip" + i] != null)
				{
					this["slider" + i].progress = this["sndClip" + i].progress;
					
					if (this["sndClip" + i].isPlaying)		this["play" + i].text = "Pause";
					else if (this["sndClip" + i].isPaused)	this["play" + i].text = "Resume";
				}
				else
				{
					this["slider" + i].progress = 0;
					this["play" + i].text = "Play";
				}
				this["play" + i].x = (this["slider" + i].x - this["play" + i].width) / 2;
			}
		}
		
		/** Responds to button clicks. */
		private function buttonHandler(e:Event):void
		{
			switch(e.target){
				case play1:
					updateSndProp(1);
					slider1.enable = false;
					startTest(1);
					break;
				case stop1:
					stopTest(1);
					slider1.enable = true;
					break;
				case play2:
					updateSndProp(2);
					slider2.enable = false;
					startTest(2);
					break;
				case stop2:
					stopTest(2);
					slider2.enable = true;
					break;
				case play3:
					updateSndProp(3);
					slider3.enable = false;
					startTest(3);
					break;
				case stop3:
					stopTest(3);
					slider3.enable = true;
					break;
			}
		}
		
		/** Updates the SeionProperties with the slider values. */
		private function updateSndProp(choice:uint):void
		{
			this["offset" + choice] = this["slider" + choice].lRange * snd.length;
			this["truncate" + choice] = (1 - this["slider" + choice].rRange) * snd.length;
		}
	}
}