package Components
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	/**
	 * A panning control with 5 segments.
	 */
	public class PanningBar extends Sprite
	{
		private var bar0:Sprite, bar1:Sprite, bar2:Sprite, bar3:Sprite, bar4:Sprite;
		
		public var target:String;
		private var callback:Function;
		private var _value:int = 0;
		
		private static const dropFilt:DropShadowFilter = new DropShadowFilter(2, 45, 0, 0.7);
		private static const glowFilt:GlowFilter = new GlowFilter(0xFFFFFF, 0.5);
		
		public function PanningBar(x:Number, y:Number, callback:Function, target:String)
		{
			this.x = x;
			this.y = y;
			this.callback = callback;
			this.target = target;
			
			init();
			render();
		}
		
		public function get value():Number	{	return _value / 2;	}
		
		public function reset():void	{	_value = 0;	render();	}
		
		private function init():void
		{
			filters = [dropFilt];
			
			bar0 = new Sprite();
			bar1 = new Sprite();
			bar2 = new Sprite();
			bar3 = new Sprite();
			bar4 = new Sprite();
			
			bar0.name = "-2";
			bar1.name = "-1";
			bar2.name = "0";
			bar3.name = "1";
			bar4.name = "2";
			bar0.buttonMode = bar1.buttonMode = bar2.buttonMode = bar3.buttonMode = bar4.buttonMode = true;
			
			addChild(bar0);
			addChild(bar1);
			addChild(bar2);
			addChild(bar3);
			addChild(bar4);
			
			bar0.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar0.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar0.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar1.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar1.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar1.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar2.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar2.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar2.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar3.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar3.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar3.addEventListener(MouseEvent.CLICK, mouseHandler);
			bar4.addEventListener(MouseEvent.ROLL_OVER, mouseHandler);
			bar4.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			bar4.addEventListener(MouseEvent.CLICK, mouseHandler);
		}
		
		private function render():void
		{
			bar0.graphics.clear();
			bar0.graphics.beginFill((_value == -2) ? 0xC0C0C0: 0xFFFF80); //graying active selection
			bar0.graphics.drawRect(0, 0, 4, 15);
			bar0.graphics.endFill();
			
			bar1.graphics.clear();
			bar1.graphics.beginFill((_value == -1) ? 0xC0C0C0: 0xFFFF80);
			bar1.graphics.drawRect(6, 2.5, 4, 10);
			bar1.graphics.endFill();
			
			bar2.graphics.clear();
			bar2.graphics.beginFill((_value == 0) ? 0xC0C0C0: 0xFF8000);
			bar2.graphics.drawCircle(15, 7.5, 3);
			bar2.graphics.endFill();
			
			bar3.graphics.clear();
			bar3.graphics.beginFill((_value == 1) ? 0xC0C0C0: 0xFFFF80);
			bar3.graphics.drawRect(20, 2.5, 4, 10);
			bar3.graphics.endFill();
			
			bar4.graphics.clear();
			bar4.graphics.beginFill((_value == 2) ? 0xC0C0C0: 0xFFFF80);
			bar4.graphics.drawRect(26, 0, 4, 15);
			bar4.graphics.endFill();
		}
		
		private function mouseHandler(e:Event):void
		{
			if (e.type == MouseEvent.ROLL_OVER)
				e.target.filters = [glowFilt];
			else if (e.type == MouseEvent.ROLL_OUT)
				e.target.filters = [];
			else
			{
				_value = new int(e.target.name);
				render();
				callback(this);
			}
		}
	}
}