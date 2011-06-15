package
{
	import flash.display.Sprite;
	import flash.media.Sound;
	
	/**
	 * ...
	 * @author
	 */
	public class NewSampleTest extends Sprite
	{
		// Retrieved from http://soundcloud.com/andremichelle/void-panic
		[Embed(source='../lib/void panic.mp3')]
		private var snd_class:Class;
		private var snd:Sound = new snd_class() as Sound;
		
		public function NewSampleTest()
		{
			
		}
	}
}