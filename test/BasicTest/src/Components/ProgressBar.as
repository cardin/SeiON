package Components
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	
	public class ProgressBar extends Sprite
	{
		private var _width:Number;
		private var _progress:Number = 0;
		
		private var node:Shape = new Shape();
		protected var dropFilt:DropShadowFilter = new DropShadowFilter(1, 45, 0, 0.4);
		
		public function ProgressBar(x:uint, y:uint, width:Number)
		{
			this.x = x;
			this.y = y;
			
			_width = width;
			init_render();
			
			node.filters = [dropFilt];
			addChild(node);
		}
		
		override public function get width():Number {	return _width;	}
		override public function set width(value:Number):void
		{
			_width = value;
			render();
		}
		
		/** A number from 0.0 to 1.0 */
		public function get progress():Number {		return _progress;	}
		public function set progress(value:Number):void
		{
			_progress = value % 1;
			render();
		}
		
		private function init_render():void
		{
			//drawing the progress bar
			graphics.clear();
			graphics.beginFill(0x0080C0);
			graphics.drawRect( -2, -5, 2, 10);
			graphics.drawRect(0, -0.5, _width, 1);
			graphics.drawRect(_width, -5, 2, 10);
			graphics.endFill();
			
			//drawing the node
			node.graphics.clear();
			node.graphics.beginFill(0xFF8000);
			node.graphics.drawCircle(0, 0, 3);
			node.graphics.endFill();
			
			render();
		}
		
		private function render():void
		{
			node.x = _progress * _width;
		}
	}
}