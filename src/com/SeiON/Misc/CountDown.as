package com.SeiON.Misc
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 * Counts down a specified time and triggers TimerEvent when it is done.
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
		 * @param	time	In Milliseconds.
		 */
		public function CountDown(time:int)
		{
			originalDelay = time;
			super(time, 1);
		}
		
		// --------------------------------- PROPERTIES ----------------------------------
		
		/** Whether the Timer is paused or not. READ-ONLY. */
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
		
		/** This property has been rendered useless. */
		override public function get repeatCount():int {	return 1;	}
		override public function set repeatCount(value:int):void {}
		
		/**
		 * The countdown this Timer was set with, in Milliseconds.
		 *
		 * If you set a new delay time while Timer is running or paused, the Timer will either
		 * reset or restart itself.
		 */
		override public function get delay():Number {	return originalDelay;	}
		override public function set delay(value:Number):void
		{
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
		 * Starts counting down. It also forces a paused timer to restart.
		 */
		override public function start():void
		{
			if (lastElapsedTime != 0) // != 0 means it's alrdy started
				return;
			
			reset(); // force a hard reset
			super.start();
			
			lastElapsedTime = getTimer();
		}
		
		/**
		 * Stops the countdown. stop() and reset() are identical.
		 */
		override public function reset():void {	stop();	}
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