package
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.text.*;
	
	import Components.*;
	
	import com.SeiON.Core.Interface.ISeionControl;
	import com.SeiON.Core.SeionInstance;
	import com.SeiON.Event.SeionEvent;
	import com.SeiON.Seion;
	import com.SeiON.SeionClip;
	import com.SeiON.SeionGroup;
	import com.SeiON.SeionSample;
	
	/**
	 * Showcases how Seion allocates and manages all the instances of sound that are playing.
	 */
	public class AllocationTest
	{
		/*********************************************
		 * Embedding the sounds and sound properties
		 *********************************************/
		
		// Retrieved from http://www.jazzhouseblues.com/
		[Embed(source = '../lib/Muffin Man Swing.mp3')]
		private var sndJazz_cls:Class;
		private var sndJazz:Sound = new sndJazz_cls() as Sound;
		private var sndJazz_SC:SeionClip;
		
		// Retrieved from http://ccmixter.org/files/hansatom/31743
		// Licensed under Creative Commons Attribution Noncommercial (3.0)
		[Embed(source = '../lib/hansatom_-_Inferno_is_a_place_on_earth [edit].mp3')]
		private var sndRock_cls:Class;
		private var sndRock:Sound = new sndRock_cls() as Sound;
		private var sndRock_SC:SeionClip;
		
		// Retrieved from http://ccmixter.org/files/unreal_dm/31740
		// Licensed under Creative Commons Attribution Noncommercial (3.0)
		[Embed(source='../lib/unreal_dm_-_Everything_I_Ever_Want [edit].mp3')]
		private var sndJazz2_cls:Class;
		private var sndJazz2:Sound = new sndJazz2_cls() as Sound;
		private var sndJazz2_SC:SeionClip;
		
		// Retrieved from http://soundcloud.com/andremichelle/void-panic
		[Embed(source = '../lib/void panic.mp3')]
		private var sndLoop_cls:Class;
		private var sndLoop:Sound = new sndLoop_cls() as Sound;
		private var sndLoop_SC:SeionSample;
		
		[Embed(source = '../lib/snd_ring.mp3')]
		private var sndRing_cls:Class;
		private var sndRing:Sound = new sndRing_cls() as Sound;
		
		[Embed(source='../lib/snd_rollover.mp3')]
		private var sndRoll_cls:Class;
		private var sndRoll:Sound = new sndRoll_cls() as Sound;
		
		/*************************************************
		 * The categories under which the sounds will be played
		 *************************************************/
		private var sgRing:SeionGroup;
		private var sgMisc:SeionGroup;
		private var sgBG:SeionGroup;
		
		// trigger variable for spam ringing
		private var triggerRing:Boolean = false;
		
		public function AllocationTest(container:DisplayObjectContainer)
		{
			sgRing = Seion.createSeionGroup("Ring", 10);
			sgMisc = Seion.createSeionGroup("Misc + UI", 2);
			sgBG = Seion.createSeionGroup("Background", 2);
			// spare allocations = 18
			
			init_render(container);
		}
		
		/**
		 * Starts playing the sound of the specified name.
		 */
		private function startSnd(name:String, sg:SeionGroup):void
		{
			if (this[name + "_SC"] == null) //sound not yet created
			{
				switch (name)
				{
					case "sndLoop":
						sndLoop_SC = SeionSample.createGaplessMP3(name, sg, sndLoop, 124510, -1, false);
						break;
					default:
						this[name + "_SC"] = SeionClip.create(name, sg, this[name], 0, false);
						break;
				}
				
				// if null, tt means we weren't able to create
				if (this[name + "_SC"] != null)
				{
					SeionInstance(this[name + "_SC"]).addEventListener(Event.SOUND_COMPLETE, onComplete);
					SeionInstance(this[name + "_SC"]).play();
				}
			}
			else //pause the sound
			{
				if (this[name + "_SC"].isPlaying)	SeionInstance(this[name + "_SC"]).pause();
				else								SeionInstance(this[name + "_SC"]).resume();
			}
		}
		
		/**
		 * Stops playing the sound of the specified name.
		 */
		private function stopSnd(name:String):void
		{
			if (this[name + "_SC"] != null)
			{
				SeionInstance(this[name + "_SC"]).stop();
				SeionInstance(this[name + "_SC"]).removeEventListener(Event.SOUND_COMPLETE, onComplete);
				SeionInstance(this[name + "_SC"]).dispose();
				this[name + "_SC"] = null;
			}
		}
		
		/**
		 * This function is called when a sound has completed playing. Note: This event listener
		 * is only registered for non-auto-disposed sounds.
		 */
		private function onComplete(e:SeionEvent):void
		{
			stopSnd(SeionInstance(e.targetSndObj).name);
		}
		
		/**
		 * Modifies the properties of the sound object of the specified name.
		 */
		private function setSndProp(name:String, vol:Number = -99, pan:Number = -99):void
		{
			if (this[name] != null)
			{
				if (vol != -99)				ISeionControl(this[name]).volume = vol;
				else if (pan != -99)		ISeionControl(this[name]).pan = pan;
			}
		}
		
		/***********************************************************************************
		 *	 								RENDERING FUNCTIONS
		 ***********************************************************************************/
		private var spareLabel:TextField;
		
		private var ringLabel:TextField;
		private var ring_vol:VolBar, ring_pan:PanningBar;
		private var ring_play:xButton;
		
		private var miscLabel:TextField;
		private var misc_vol:VolBar, misc_pan:PanningBar;
		private var loop_play:xButton, loop_stop:xButton;
		private var loop_vol:VolBar, loop_pan:PanningBar;
		
		private var bgLabel:TextField;
		private var bg_vol:VolBar, bg_pan:PanningBar;
		private var jazz_play:xButton, jazz_stop:xButton, jazz_bar:ProgressBar;
		private var jazz2_play:xButton, jazz2_stop:xButton, jazz2_bar:ProgressBar;
		private var rock_play:xButton, rock_stop:xButton, rock_bar:ProgressBar;
		private var jazz_vol:VolBar, jazz2_vol:VolBar, rock_vol:VolBar;
		private var jazz_pan:PanningBar, jazz2_pan:PanningBar, rock_pan:PanningBar;
		
		/** Sets up the UI and buttons on stage. */
		private function init_render(container:DisplayObjectContainer):void
		{
			var label:TextField;
			
			/* -------------------- Spare allocations left over in Seion ---------------- */
			spareLabel = new TextField();
			spareLabel.mouseEnabled = false;
			spareLabel.autoSize = TextFieldAutoSize.LEFT;
			spareLabel.textColor = 0x000040;
			spareLabel.x = 10;		spareLabel.y = 130;
			container.addChild(spareLabel);
			
			/* ------------------------------- Ringing Sounds --------------------------- */
			// Category label
			label = new TextField();
			label.mouseEnabled = false;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.textColor = 0x000040;
			label.htmlText = "<b>SeionGroup: Ring</b>";
			label.x = 10;			label.y = 160;
			
			// Category alloc label
			ringLabel = new TextField();
			ringLabel.mouseEnabled = false;
			ringLabel.multiline = true;
			ringLabel.autoSize = TextFieldAutoSize.LEFT;
			ringLabel.x = 330;			ringLabel.y = 185;
			
			// Category Pan and Volume
			ring_vol = new VolBar(label.x + label.width + 15, 177, propHandler, "sgRing");
			ring_pan = new PanningBar(ring_vol.x + 30, ring_vol.y - 15, propHandler, "sgRing");
			
			// Sound Control
			ring_play = new xButton(70, 180, "Play", 0x80FF00, sndRoll, sgMisc);
			
			container.addChild(label);
			container.addChild(ringLabel);
			container.addChild(ring_vol);
			container.addChild(ring_pan);
			container.addChild(ring_play);
			
			/* ------------------------------- UI & Misc Sounds ------------------------- */
			// Category label
			label = new TextField();
			label.mouseEnabled = false;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.textColor = 0x000040;
			label.htmlText = "<b>SeionGroup: UI + Misc Sounds</b>";
			label.x = 10;			label.y = 230;
			
			// Category alloc label
			miscLabel = new TextField();
			miscLabel.mouseEnabled = false;
			miscLabel.multiline = true;
			miscLabel.autoSize = TextFieldAutoSize.LEFT;
			miscLabel.x = 330;			miscLabel.y = 255;
			
			// Category Pan and Volume
			misc_vol = new VolBar(label.x + label.width + 15, 247, propHandler, "sgMisc");
			misc_pan = new PanningBar(misc_vol.x + 30, misc_vol.y - 15, propHandler, "sgMisc");
			
			// Sound Control
			loop_play = new xButton(0, 250, "Play", 0x80FF00, sndRoll, sgMisc);
			loop_stop = new xButton(74, 275, "Stop", 0xFF4040, sndRoll, sgMisc);
			loop_vol = new VolBar(27, 270, propHandler, "sndLoop_SC");
			loop_pan = new PanningBar(loop_vol.x - 6, loop_vol.y + 8, propHandler, "sndLoop_SC");
			
			container.addChild(label);
			container.addChild(miscLabel);
			container.addChild(misc_vol);
			container.addChild(misc_pan);
			container.addChild(loop_play);
			container.addChild(loop_stop);
			container.addChild(loop_vol);
			container.addChild(loop_pan);
			
			/* ----------------------------- Background Sounds --------------------------- */
			// Category label
			label = new TextField();
			label.mouseEnabled = false;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.textColor = 0x000040;
			label.htmlText = "<b>SeionGroup: BG Music</b>";
			label.x = 10;			label.y = 300;
			
			// Category alloc label
			bgLabel = new TextField();
			bgLabel.mouseEnabled = false;
			bgLabel.multiline = true;
			bgLabel.autoSize = TextFieldAutoSize.LEFT;
			bgLabel.x = 330;			bgLabel.y = 380;
			
			// Category Pan and Volume
			bg_vol = new VolBar(label.x + label.width + 15, 316, propHandler, "sgBG");
			bg_pan = new PanningBar(bg_vol.x + 30, bg_vol.y - 15, propHandler, "sgBG");
			
			// The 3 BG individual sounds
			jazz_play = new xButton(0, 320, "Play", 0x80FF00, sndRoll, sgMisc);
			jazz_stop = new xButton(74, 345, "Stop", 0xFF4040, sndRoll, sgMisc);
			jazz_bar = new ProgressBar(165, jazz_stop.y - 5, 150);
			
			jazz2_play = new xButton(0, 380, "Play", 0x80FF00, sndRoll, sgMisc);
			jazz2_stop = new xButton(74, 405, "Stop", 0xFF4040, sndRoll, sgMisc);
			jazz2_bar = new ProgressBar(165, jazz2_stop.y - 5, 150);
			
			rock_play = new xButton(0, 440, "Play", 0x80FF00, sndRoll, sgMisc);
			rock_stop = new xButton(74, 465, "Stop", 0xFF4040, sndRoll, sgMisc);
			rock_bar = new ProgressBar(165, rock_stop.y - 5, 150);
			
			// 3 BG Individual Pan and Volume
			jazz_vol = new VolBar(27, 340, propHandler, "sndJazz_SC");
			jazz2_vol = new VolBar(27, 400, propHandler, "sndJazz2_SC");
			rock_vol = new VolBar(27, 465, propHandler, "sndRock_SC");
			jazz_pan = new PanningBar(jazz_vol.x - 6, jazz_vol.y + 8, propHandler, "sndJazz_SC");
			jazz2_pan = new PanningBar(jazz2_vol.x - 6, jazz2_vol.y + 8, propHandler, "sndJazz2_SC");
			rock_pan = new PanningBar(rock_vol.x - 6, rock_vol.y + 8, propHandler, "sndRock_SC");
			
			container.addChild(label);
			container.addChild(bgLabel);
			container.addChild(bg_vol);
			container.addChild(bg_pan);
			
			container.addChild(jazz_play);
			container.addChild(jazz_stop);
			container.addChild(jazz_bar);
			container.addChild(jazz2_play);
			container.addChild(jazz2_stop);
			container.addChild(jazz2_bar);
			container.addChild(rock_play);
			container.addChild(rock_stop);
			container.addChild(rock_bar);
			
			container.addChild(jazz_vol);
			container.addChild(jazz2_vol);
			container.addChild(rock_vol);
			container.addChild(jazz_pan);
			container.addChild(jazz2_pan);
			container.addChild(rock_pan);
			
			/* ------------------------------------------------------------------------- */
			ring_play.addEventListener(MouseEvent.CLICK, buttonHandler);
			loop_play.addEventListener(MouseEvent.CLICK, buttonHandler);
			loop_stop.addEventListener(MouseEvent.CLICK, buttonHandler);
			jazz_play.addEventListener(MouseEvent.CLICK, buttonHandler);
			jazz_stop.addEventListener(MouseEvent.CLICK, buttonHandler);
			jazz2_play.addEventListener(MouseEvent.CLICK, buttonHandler);
			jazz2_stop.addEventListener(MouseEvent.CLICK, buttonHandler);
			rock_play.addEventListener(MouseEvent.CLICK, buttonHandler);
			rock_stop.addEventListener(MouseEvent.CLICK, buttonHandler);
			container.root.addEventListener(Event.ENTER_FRAME, update_stats);
			
			/* ------------------------------ Description Labels ----------------------- */
			label = new TextField();
			label.mouseEnabled = false;
			label.wordWrap = label.multiline = true;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.width = 350;
			label.htmlText = "<p align='justify'>As Spam Ringing uses autodispose sounds, it can "
				+ "borrow more sounds from Seion beyond its 10 allocations.</p><br>"
				+ "<p align='justify'>Both the Misc loop sound and button rollover share the same "
				+ "SeionGroup. As button rollover is disposable, it can borrow as well.</p><br />"
				+ "<p align='justify'>BG sounds are non-autodisposable. Hence it's strictly limited "
				+ "to only 2 simultaneous sounds.</p>";
			label.x = 30;		label.y = 10;
			container.addChild(label);
		}
		
		/** Updates the allocation count display + progress bar + UI buttons.
		 * Also in charge of creating the spamming ring sounds. */
		private function update_stats(e:Event):void
		{
			//------------------- Updating Allocation Count's Display
			spareLabel.htmlText = "<b>Seion Spare Alloc: " + Seion.availAllocation + "</b>";
			ringLabel.htmlText = "Ring Alloc:<br>" +
						sgRing.usedAllocation + "/" + sgRing.fullAllocation;
			miscLabel.htmlText = "Misc Alloc:<br>" +
						sgMisc.usedAllocation + "/" + sgMisc.fullAllocation;
			bgLabel.htmlText = "BG Alloc:<br>" +
						sgBG.usedAllocation + "/" + sgBG.fullAllocation;
			
				//------------------- Updating Progress Bars & Buttons
				// the ringing sound
				if (!triggerRing)
					ring_play.text = "Spam Ringing";
				else
					ring_play.text = "Stop Ringing";
				ring_play.x = (jazz_bar.x + 30 - ring_play.width) / 2;
				
				// the voidPanic loop
				if (sndLoop_SC == null)
					loop_play.text = "Play Misc";
				else
				{
					if (sndLoop_SC.isPlaying)	loop_play.text = "Pause Misc";
					else						loop_play.text = "Resume Misc";
				}
				loop_play.x = (jazz_bar.x + 30 - loop_play.width) / 2;
				
				// Jazz background sound
				if (sndJazz_SC == null)
				{
					jazz_bar.progress = 0;
					jazz_play.text = "Play";
				}
				else
				{
					jazz_bar.progress = sndJazz_SC.progress;
					if (sndJazz_SC.isPlaying)		jazz_play.text = "Pause";
					else							jazz_play.text = "Resume";
				}
				jazz_play.x = (jazz_bar.x + 30 - jazz_play.width) / 2;
				
				// Jazz 2 background sound
				if (sndJazz2_SC == null)
				{
					jazz2_bar.progress = 0;
					jazz2_play.text = "Play";
				}
				else
				{
					jazz2_bar.progress = sndJazz2_SC.progress;
					if (sndJazz2_SC.isPlaying)		jazz2_play.text = "Pause";
					else								jazz2_play.text = "Resume";
				}
				jazz2_play.x = (jazz_bar.x + 30 - jazz2_play.width) / 2;
				
				// Rock background sound
				if (sndRock_SC == null)
				{
					rock_bar.progress = 0;
					rock_play.text = "Play";
				}
				else
				{
					rock_bar.progress = sndRock_SC.progress;
					if (sndRock_SC.isPlaying)		rock_play.text = "Pause";
					else							rock_play.text = "Resume";
				}
				rock_play.x = (jazz_bar.x + 30 - rock_play.width) / 2;
			
			//------------------------- Appearance of Pan and Vol controls
			/* The Pan and Volume controls for individual sounds are originally not visible, until
			 * they are played.
			 */
			if (sndLoop_SC == null)
			{
				loop_vol.visible = loop_pan.visible = false;
				loop_vol.reset();	loop_pan.reset();
			}
			else
				loop_vol.visible = loop_pan.visible = true;
			
			// jazz
			if (sndJazz_SC == null)
			{
				jazz_vol.visible = jazz_pan.visible = false;
				jazz_vol.reset();	jazz_pan.reset();
			}
			else
				jazz_vol.visible = jazz_pan.visible = true;
			// jazz2
			if (sndJazz2_SC == null)
			{
				jazz2_vol.visible = jazz2_pan.visible = false;
				jazz2_vol.reset();	jazz2_pan.reset();
			}
			else
				jazz2_vol.visible = jazz2_pan.visible = true;
			// rock
			if (sndRock_SC == null)
			{
				rock_vol.visible = rock_pan.visible = false;
				rock_vol.reset();	rock_pan.reset();
			}
			else
				rock_vol.visible = rock_pan.visible = true;
			
				// --------------------------------- Spamming Ringing Sounds
				// 1 autodispose ring per enterFrame
				if (triggerRing)
					SeionClip.create("", sgRing, sndRing, 0, true);
		}
		
		/** Responds to button presses */
		private function buttonHandler(e:Event):void
		{
			switch(e.target) {
				case ring_play: triggerRing = !triggerRing; break;
				
				case loop_play: startSnd("sndLoop", sgMisc); break;
				case loop_stop: stopSnd("sndLoop"); break;
				
				case jazz_play: startSnd("sndJazz", sgBG);	break;
				case jazz_stop: stopSnd("sndJazz"); break;
				case jazz2_play: startSnd("sndJazz2", sgBG);	break;
				case jazz2_stop: stopSnd("sndJazz2"); break;
				case rock_play: startSnd("sndRock", sgBG);	break;
				case rock_stop: stopSnd("sndRock"); break;
			}
		}
		
		/** Responds to callback handlers on the Panning and Volume components. */
		private function propHandler(callee:Sprite):void
		{
			if (callee as VolBar)
			{
				var a:VolBar = callee as VolBar;
				setSndProp(a.target, a.value);
			}
			else if (callee as PanningBar)
			{
				var b:PanningBar = callee as PanningBar;
				setSndProp(b.target, -99, b.value);
			}
		}
	}
}