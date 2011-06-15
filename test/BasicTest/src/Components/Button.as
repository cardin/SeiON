package Components
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	/**
	 * ...
	 * @author
	 */
	public class Button extends Sprite
	{
		private static const dropFilt:DropShadowFilter = new DropShadowFilter(2, 45, 0, 0.7);
		private static const glowFilt:GlowFilter = new GlowFilter(0xFFFFF, 0.5);
		
		private var _color:uint;
		
		private var txtFld:TextField = new TextField();
		
		public function Button(x:Number, y:Number, text:String, color:uint = 0xFF0000)
		{
			txtFld.autoSize = TextFieldAutoSize.LEFT;
			txtFld.mouseEnabled = false;
			addChild(txtFld);
			
			this.x = x;
			this.y = y;
			this.text = text;
			this._color = color;
			
			this.buttonMode = true;
			this.filters = [dropFilt];
			this.addEventListener(MouseEvent.ROLL_OUT, rollHandler);
			this.addEventListener(MouseEvent.ROLL_OVER, rollHandler);
			render();
		}
		
		public function get text():String	{	return txtFld.text;		}
		public function set text(value:String):void
		{
			txtFld.text = value;
			render();
		}
		
		public function get color():uint	{	return _color;	}
		public function set color(value:uint):void
		{
			_color = value;
			render();
		}
		
		private function render():void
		{
			var _width:Number = txtFld.width + 10 * 2;
			
			graphics.clear();
			graphics.beginFill(_color);
			graphics.drawRoundRect(0, 0, _width, 20, 10, 10);
			graphics.endFill();
			
			txtFld.x = (_width - txtFld.width) / 2;
			txtFld.y = ((height - txtFld.height) / 2) - 1;
		}
		
		protected function rollHandler(e:Event):void
		{
			if (e.type == MouseEvent.ROLL_OUT)
				filters = [dropFilt];
			else
				filters = [dropFilt, glowFilt];
			
			txtFld.filters = [];
		}
	}
}