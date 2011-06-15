package Components
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import flash.filters.GlowFilter;
	
	/**
	 * ...
	 * @author
	 */
	public class RangeProgressSlider extends ProgressBar
	{
		private var leftNode:Sprite = new Sprite();
		private var rightNode:Sprite = new Sprite();
		private var leftLabel:TextField = new TextField();
		private var rightLabel:TextField = new TextField();
		
		private var _enable:Boolean;
		
		private static const glowFilt:GlowFilter = new GlowFilter(0xFFFFF, 0.5);
		
		public function RangeProgressSlider(x:Number, y:Number, width:Number)
		{
			super(x, y, width);
			
			addChild(leftNode);
			addChild(rightNode);
			
			init_render();
		}
		
		public function get lRange():Number	{	return leftNode.x / width;	}
		public function set lRange(value:Number):void
		{
			leftNode.x = value * width;
			leftLabel.text = value.toFixed(3);
		}
		
		public function get rRange():Number	{	return rightNode.x / width;	}
		public function set rRange(value:Number):void
		{
			rightNode.x = value * width;
			rightLabel.text = value.toFixed(3);
		}
		
		override public function get progress():Number	{	return super.progress;	}
		override public function set progress(value:Number):void
		{
			// limit within range
			super.progress = lRange + (rRange - lRange) * value;
		}
		
		public function get enable():Boolean {	return _enable;	}
		public function set enable(value:Boolean):void
		{
			_enable = value;
			if (_enable)
			{
				leftNode.filters = rightNode.filters = [dropFilt];
				leftNode.buttonMode = rightNode.buttonMode = true;
				
				leftNode.addEventListener(MouseEvent.ROLL_OUT, rollHandler);
				rightNode.addEventListener(MouseEvent.ROLL_OUT, rollHandler);
				leftNode.addEventListener(MouseEvent.ROLL_OVER, rollHandler);
				rightNode.addEventListener(MouseEvent.ROLL_OVER, rollHandler);
				
				leftNode.addEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
				rightNode.addEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
			}
			else
			{
				leftNode.filters = rightNode.filters = [];
				leftNode.buttonMode = rightNode.buttonMode = false;
				
				leftNode.removeEventListener(MouseEvent.ROLL_OUT, rollHandler);
				rightNode.removeEventListener(MouseEvent.ROLL_OUT, rollHandler);
				leftNode.removeEventListener(MouseEvent.ROLL_OVER, rollHandler);
				rightNode.removeEventListener(MouseEvent.ROLL_OVER, rollHandler);
				
				leftNode.removeEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
				rightNode.removeEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
			}
		}
		
		private function init_render():void
		{
			leftNode.graphics.clear();
			leftNode.graphics.beginFill(0xFFFF00);
			leftNode.graphics.moveTo(0, -9);
			leftNode.graphics.lineTo( -5, -15);
			leftNode.graphics.lineTo(5, -15);
			leftNode.graphics.drawRoundRectComplex(-5, -15-26, 10, 26, 3.5, 3.5, 0, 0);
			leftNode.graphics.endFill();
			
			rightNode.graphics.clear();
			rightNode.graphics.copyFrom(leftNode.graphics);
			
			// setting properties
			dropFilt.distance = 2;
			rightNode.x = width;
			
			// setting node labels
			var txtFmt:TextFormat = leftLabel.getTextFormat();
			txtFmt.size = 11;
			txtFmt.align = TextFormatAlign.CENTER;
			leftLabel.defaultTextFormat = rightLabel.defaultTextFormat = txtFmt;
			leftLabel.autoSize = rightLabel.autoSize = TextFieldAutoSize.CENTER;
			leftLabel.mouseEnabled = rightLabel.mouseEnabled = false;
			leftLabel.rotationZ = rightLabel.rotationZ = -90;
			leftLabel.x = rightLabel.x = -7;
			leftLabel.y = rightLabel.y = 9;
			leftLabel.scaleX = leftLabel.scaleY = rightLabel.scaleX = rightLabel.scaleY = .75;
			
			leftNode.addChild(leftLabel);
			rightNode.addChild(rightLabel);
			
			enable = true;
		}
		
		private function dragHandler(e:MouseEvent = null):void
		{
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				leftNode.removeEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
				rightNode.removeEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
				
				e.target.stage.addEventListener(MouseEvent.MOUSE_UP, dragHandler);
				e.target.stage.addEventListener(MouseEvent.MOUSE_MOVE, dragHandler);
				if (e.target == leftNode)
					e.target.startDrag(false, new Rectangle(0, 0, rRange * width, 0));
				else
					e.target.startDrag(false, new Rectangle(lRange * width, 0, (1 - lRange) * width, 0));
			}
			else if (e.type == MouseEvent.MOUSE_MOVE)
			{
				leftLabel.text = lRange.toFixed(3);
				rightLabel.text = rRange.toFixed(3);
			}
			else
			{
				leftNode.stopDrag();
				rightNode.stopDrag();
				e.target.stage.removeEventListener(MouseEvent.MOUSE_UP, dragHandler);
				e.target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragHandler);
				
				leftNode.addEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
				rightNode.addEventListener(MouseEvent.MOUSE_DOWN, dragHandler);
			}
		}
		
		private function rollHandler(e:MouseEvent):void
		{
			if (e.type == MouseEvent.ROLL_OUT)
				(e.target).filters = [dropFilt];
			else
				(e.target).filters = [dropFilt, glowFilt];
		}
	}
}