package Components
{
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * A small volume bar display with 3 segments.
	 */
	public class VolBar extends Sprite
	{
		private var bar1:Sprite, bar2:Sprite, bar3:Sprite;
		private var _value:uint = 3;
		
		private var callback:Function;
		public var target:String;
		
		private static const dropFilt:DropShadowFilter = new DropShadowFilter(2, 45, 0, 0.7);
		private static const glowFilt:GlowFilter = new GlowFilter(0xFFFFFF, 0.5);
		
		public function VolBar(x:Number, y:Number, callback:Function, target:String)
		{
			this.x = x;
			this.y = y;
			this.callback = callback;
			this.target = target;
			
			init();
			render();
		}
		
		public function get value():Number	{	return _value / 3;	}
		
		public function reset():void	{	_value = 3; render();	}
		
		private function init():void
		{
			this.filters = [dropFilt];
			
			bar1 = new Sprite();
			bar2 = new Sprite();
			bar3 = new Sprite();
			
			bar1.name = "1";
			bar2.name = "2";
			bar3.name = "3";
			bar1.buttonMode = true;
			bar2.buttonMode = true;
			bar3.buttonMode = true;
			
			addChild(bar1);
			addChild(bar2);
			addChild(bar3);
			
			bar1.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar1.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar1.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar2.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar2.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar2.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar3.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar3.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar3.addEventListener(MouseEvent.CLICK, mouseHandler);
		}
		
		private function render():void
		{
			bar1.graphics.clear();
			bar1.graphics.beginFill((_value < 1)? 0xC0C0C0: 0x80FF80); //graying out the bar
			bar1.graphics.drawRect(0, 0, 4, -8);
			bar1.graphics.endFill();
			
			bar2.graphics.clear();
			bar2.graphics.beginFill((_value < 2)? 0xC0C0C0: 0x80FF80);
			bar2.graphics.drawRect(6, 0, 4, -13);
			bar2.graphics.endFill();
			
			bar3.graphics.clear();
			bar3.graphics.beginFill((_value < 3)? 0xC0C0C0: 0x80FF80);
			bar3.graphics.drawRect(12, 0, 4, -18);
			bar3.graphics.endFill();
		}
		
		private function mouseHandler(e:Event):void
		{
			if (e.type == MouseEvent.ROLL_OVER)
				e.target.filters = [glowFilt];
			else if (e.type == MouseEvent.ROLL_OUT)
				e.target.filters = [];
			else
			{
				_value = new uint(e.target.name);
				render();
				callback(this);
			}
		}
	}
}