package test 
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	/**
	 * ...
	 * @author zhmq
	 * @date 2016/11/24 21:09
	 */
	public class MainFliper extends Sprite
	{
		
		//---- Constants -------------------------------------------------------
		
		private const Arr:Array = [0.45,-0.25,1.01,0.00,-13.34,0.29,1.15,-0.23,0.00,-13.34,-0.66,1.22,0.65,0.00,-13.34,0.00,0.00,0.00,1.00,0.00];
		
		//---- Protected Fields ------------------------------------------------
		
		protected var FUtilityFlip:TUtilityPageFlip;
		protected var FBmd0:BitmapData;
		protected var FBmd1:BitmapData;
		
		//---- Property Fields -------------------------------------------------
		
		//---- Constructor -----------------------------------------------------
		
		public function MainFliper(Mc:MovieClip) 
		{				
			addChild(Mc);
			FUtilityFlip = new TUtilityPageFlip();
			
			FUtilityFlip.Setup(
				Mc["MC_Touch"],
				Mc["MC_Touch"].width / 2,
				Mc["MC_Touch"].height);
			
			FBmd0 = new BitmapData(Mc["MC_Touch"].width, Mc["MC_Touch"].height);
			FBmd1 = new BitmapData(Mc["MC_Touch"].width, Mc["MC_Touch"].height);
			Mc["MC"].filters = [new ColorMatrixFilter(Arr)];
			FBmd1.draw(Mc);
			Mc["MC"].filters = [];
			FBmd0.draw(Mc);
			FUtilityFlip.SetupPage(
				FBmd0,
				FBmd1,
				true);
			//Mc["MC"].visible = false;
				
			Mc.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			Mc.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			Mc.addEventListener(Event.ENTER_FRAME, OnEnterFrame);
		}
		
		//---- Protected Methods -----------------------------------------------
		
		protected function OnMouseDown(
			E:MouseEvent):void
		{
			FUtilityFlip.Fliper();
		}
		
		protected function OnMouseUp(
			E:MouseEvent):void
		{
			FUtilityFlip.Turn();
		}
		
		protected function OnEnterFrame(
			E:Event):void
		{
			FUtilityFlip.LogicsPerform();
		}
		
		//---- Event Handling Methods ------------------------------------------
		
		//---- Property Accessing Methods --------------------------------------
		
		//---- Public Methods ----------------------------------------------------
	}

}