package com.SeiON.Misc
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 * A countdown timer that will trigger TimerEvent when it is done. Used by SeiON to prematurely
	 * end sounds (aka truncate).
	 */
	public final class CountDown extends Timer
	{
		/**
		 * originalDelay: The original amount of delay that is timer is supposed to have.
		 * timeLeft: Tracks the amount of time left, when CountDown has been paused.
		 * lastElapsedTime: Records the time during resume() or start(), so that the time between
		 * 					playing and pausing can be calculated properly.
		 * _paused: Internal tracker whether Timer is paused or not.
		 */
		private var originalDelay:int;
		private var timeLeft:int;
		private var lastElapsedTime:int = 0;
		private var _paused:Boolean = false;
		
		/**
		 * @param	time	The countdown timing. (Milliseconds)
		 */
		public function CountDown(time:int)
		{
			originalDelay = time;
			super(time, 1);
		}
		
		// --------------------------------- PROPERTIES ----------------------------------
		
		/** Whether the Timer is paused or not. */
		public function get paused():Boolean {	return _paused;	}
		
		/** The amount of time remaining in the countdown, in milliseconds. */
		public function get timeRemaining():int
		{
			if (paused) // paused
				return timeLeft;
			else if (!running) // not started yet
				return 0;
			else // in the midst of running
			{
				var timePast:int = getTimer() - lastElapsedTime;
				return timeLeft - timePast;
			}
		}
		
		/** @private */
		override public function get repeatCount():int {	return 1;	}
		override public function set repeatCount(value:int):void {}
		
		/**
		 * The countdown this Timer was set with, in Milliseconds. Setting a negative value will
		 * default to 0. If delay = 0, CountDown will refuse to start.
		 *
		 * If you set a new delay time while Timer is running or paused, the Timer will either
		 * reset or restart itself respectively.
		 */
		override public function get delay():Number {	return originalDelay;	}
		override public function set delay(value:Number):void
		{
			if (value < 0)	value = 0;
			
			originalDelay = value;
			if (running)
			{
				reset();
				start();
			}
			else if (paused)
				reset();
		}
		
		// ------------------------------------ METHODS -----------------------------------
		
		/**
		 * Starts counting down. If there was any playback originally, this will force CountDown to
		 * restart from the beginning.
		 */
		override public function start():void
		{
			reset(); // force a hard reset
			
			// don't bother counting if 0
			if (originalDelay == 0)
				return;
			
			super.start();
			lastElapsedTime = getTimer();
		}
		
		/** Stops the countdown. stop() and reset() are identical. */
		override public function reset():void {	stop();	}
		/** Stops the countdown. stop() and reset() are identical. */
		override public function stop():void
		{
			super.stop();
			super.delay = originalDelay;
			
			lastElapsedTime = 0;
			timeLeft = originalDelay;
			_paused = false;
		}
		
		/**
		 * Resumes counting down if Timer had been paused. Does nothing otherwise.
		 */
		public function resume():void
		{
			if (!paused) // it wasn't paused in the first place
				return;
			_paused = false;
			
			super.delay = timeLeft;
			super.start();
			
			lastElapsedTime = getTimer();
		}
		
		/**
		 * Pauses the countdown.
		 */
		public function pause():void
		{
			if (!running) // proceed only if it's running
				return;
			_paused = true;
			
			// deduct the time passed from timeLeft
			var timePast:int = getTimer() - lastElapsedTime;
			timeLeft -= timePast;
			
			if (timeLeft <= 20) // 1/5th of human reaction time
			{ // count as completed
				super.reset();
				dispatchEvent(new TimerEvent(TimerEvent.TIMER));
				dispatchEvent(new TimerEvent(TimerEvent.TIMER_COMPLETE));
				return;
			}
			else
			{
				lastElapsedTime = 0;
				super.stop();
			}
		}
	}
}