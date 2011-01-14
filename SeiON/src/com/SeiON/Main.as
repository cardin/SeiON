package com.SeiON
{
	import com.SeiON.Misc.CountDown;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	
	/**
	 * ...
	 * @author
	 */
	public class Main extends Sprite
	{
		public var a:CountDown, b:CountDown;
		
		public function Main()
		{
			a = new CountDown(3000);
			a.addEventListener(TimerEvent.TIMER_COMPLETE, trigger);
			
			b = new CountDown(2962);
			b.addEventListener(TimerEvent.TIMER_COMPLETE, pauseIt);
			
			b.start();
			a.start();
		}
		
		public function pauseIt(e:TimerEvent):void
		{
			a.pause();
			trace(a.timeRemaining);
		}
		
		public function trigger(e:TimerEvent):void
		{
			trace("hi");
		}
	}
}