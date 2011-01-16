package com.SeiON.Tween
{
	import com.greensock.TimelineLite;
	
	/**
	 * This is an ITween of GreenSock's Animation classes.
	 */
	public class GreenSock implements ITween
	{
		private var _tween:TimelineLite;
		private var _type:E_TweenTypes;
		
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
		 * Note: Reverse playing is not supported by ISoundClip, so even though GreenSock can
		 * reverse playback, it won't work in SeiON.
		 *
		 * @param	tween	If null, a TimelineLite is created instead.
		 */
		public function GreenSock(_tween:TimelineLite = null)
		{
			if (_tween == null)
				_tween = new TimelineLite( { useFrames: false } );
			this._tween = _tween;
		}
		
		public function tween():TimelineLite {	return _tween;	}
		
		/* ----------------- INTERFACE com.SeiON.Tween.ITween ------------------------- */
		
		/** Destroys/disposes of the tween. (ITween) */
		public function dispose():void
		{
			_tween.kill();
			_tween.clear();
			_tween = null;
		}
		
		/** Sets the tweening behaviour type to be used for ISoundClip. (ITween) */
		public function get type():E_TweenTypes {	return _type;	}
		public function set type(value:E_TweenTypes):void;	{	_type = value;	}
		
		/** Plays the Tween forward from the beginning. (ITween) */
		public function play():void {	_tween.restart();	}
		/** Stops playing and returns to the beginning. (ITween) */
		public function stop():void {	_tween.restart(); _tween.stop();	}
		
		/** Pauses the Tween. (ITween) */
		public function pause():void	{	_tween.pause();	}
		/** Resumes the Tween forward. (ITween) */
		public function resume():void	{	_tween.play(); }
		
		/** The position it is at, not counting repeats. In Milliseconds. (ITween) */
		function get position():Number	{	_tween.currentTime;	}
		function set position(value:Number):void {	_tween.goto(value);	}
	}
}