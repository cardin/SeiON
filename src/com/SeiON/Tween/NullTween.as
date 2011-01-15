package com.SeiON.Tween
{
	/**
	 * A placeholder null tween.
	 */
	public class NullTween implements ITween
	{
		/* INTERFACE com.SeiON.Tween.ITween */
		public function dispose():void	{}
		
		public function play():void {}
		public function stop():void {}
		
		public function restart():void {}
		
		public function pause():void {}
		public function resume():void {}
	}
}