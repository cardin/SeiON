package Components
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	
	import com.SeiON.SeionClip;
	import com.SeiON.SeionGroup;
	
	/**
	 * Enhanced Button with sounds.
	 */
	public class xButton extends Button
	{
		private var snd:Sound;
		private var sg:SeionGroup;
		
		/**
		 * @param	snd	The sound it should play with rollover/rollout.
		 * @param	sg	The SeionGroup that it will use to play the sound with.
		 */
		public function xButton(x:Number, y:Number, text:String, color:uint, snd:Sound, sg:SeionGroup)
		{
			super(x, y, text, color);
			this.snd = snd;
			this.sg = sg;
		}
		
		override protected function rollHandler(e:Event):void
		{
			super.rollHandler(e);
			if (e.type == MouseEvent.ROLL_OVER)
				SeionClip.create("", sg, snd, 0, true);
		}
	}
}