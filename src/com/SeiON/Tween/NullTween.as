package com.SeiON.Tween
{
	/**
	 * Empty null tween.
	 */
	public final class NullTween implements ITween
	{
		public function dispose():void {}
		
		public function get type():TweenTypes { return null; }
		public function set type(value:TweenTypes):void {}
		
		public function play():void {}
		public function stop():void {}
		
		public function pause():void {}
		public function resume():void {}
		
		public function get position():Number { return 0; }
		public function set position(value:Number):void {}
	}
}