package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.net.Socket;
	import flash.net.URLRequest;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import mx.core.FlexSimpleButton;
	import test.MainFliper;
	
	/**
	 * ...
	 * @author zhmq
	 */
	
	public class Main extends Sprite 
	{			
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);					
			
			var Load:Loader;
			var pageRequest:URLRequest;
			
			Load = new Loader();
			pageRequest=new URLRequest("pageTurn.swf");
			Load.contentLoaderInfo.addEventListener(Event.COMPLETE, LoadEnd);
			Load.load(pageRequest);
			
		}	
		
		protected function LoadEnd(
			evtObj:Event):void
		{
			var Fliper:MainFliper;
			
			Fliper = new MainFliper(evtObj.target.loader.content as MovieClip);	
			
			stage.addChild(Fliper);
		}
	}
	
}