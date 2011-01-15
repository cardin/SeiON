package com.SeiON.Tween
{
	import com.greensock.TimelineLite;
	
	/**
	 * This is an ITween of GreenSock's Animation classes.
	 */
	public class GreenSock implements ITween
	{
		public var tween:TimelineLite;
		
		/**
		 * Creates a wrapper over a TimelineLite object of GreenSock, eg. TimelineMax,
		 * TimelineLite. Use the appropriate object for your needs and cast it when you are
		 * retrieving it.
		 *
		 * Eg. You might use a TimelineMax if you are planning to have yoyo animations. You would
		 * cast the object from SimpleTimeline back into TimelineLite when retrieving it from
		 * the tween property of this object.
		 *
		 * Note: DO NOT hold any external references to the internal tween object. Otherwise you
		 * might find the reference evaluates to null after SoundClip disposes of it.
		 *
		 * @param	tween	If null, a TimelineLite is created instead.
		 */
		public function GreenSock(_tween:TimelineLite = null)
		{
			if (_tween == null)
				_tween = new TimelineLite(null);
			this.tween = _tween;
		}
		
		/* INTERFACE com.SeiON.Tween.ITween */
		public function dispose():void
		{
			tween.kill();
			tween = null;
		}
		
		public function play():void {	tween.play();	}
		public function stop():void	{	tween.stop();	}
		
		public function restart():void {	tween.restart();	}
		
		public function pause():void	{	tween.pause();	}
		public function resume():void	{	tween.resume(); }
	}
}