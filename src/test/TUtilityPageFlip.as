package test 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	/**
	 * 用于同一个资源中需要改变显示值并且翻页的需求
	 * 
	 * @author zhmq
	 * @date 2016/12/9 18:42
	 */
	public class TUtilityPageFlip 
	{
		
		//---- Constants -------------------------------------------------------
		/**需要翻动的页数*/
		private static const PageBmd_Num:int = 4;
		
		private static const Book_Flag_Stop:int = 0;
		private static const Book_Flag_Fliper:int = 1;
		private static const Book_Flag_Playing:int = 2;
		
		//---- Protected Fields ------------------------------------------------
		
		private var FBookRes:MovieClip;
		
		private var book_root:MovieClip;
		private var book_width:int;
		private var book_height:int;
		
		private var book_CrossGap:Number;
		private var bookArray_layer1:Array;
		private var bookArray_layer2:Array;
		private var book_TimerArg0:Number=0;
		private var book_TimerArg1:Number=0;
		private var u:Number;
		private var book_px:Number=0;
		private var book_py:Number=0;
		private var book_toposArray:Array;
		private var book_myposArray:Array;
		
		private var book_TimerFlag:int;
		
		private var pageMC:Sprite=new Sprite();
		private var bgMC:Sprite=new Sprite();

		private var render0:Shape=new Shape();
		private var render1:Shape=new Shape();
		private var shadow0:Shape=new Shape();
		private var shadow1:Shape=new Shape();

		private var Mask0:Shape=new Shape();
		private var Mask1:Shape=new Shape();

		private var p1:Point;
		private var p2:Point;
		private var p3:Point;
		private var p4:Point;

		private var limit_point1:Point;
		private var limit_point2:Point;
		
		/**拆分成4页，需要翻动的位图*/
		private var FBmdVec:Vector.<BitmapData>;
		/**用来画右边的书页*/
		private var FPageMatrix:Matrix;
		
		
		
		public var IsAutoPlay:Boolean = true;
		public var OnPageEnd:Function;
		
		//---- Property Fields -------------------------------------------------
		
		//---- Constructor -----------------------------------------------------
		
		public function TUtilityPageFlip() 
		{
			FBmdVec = new Vector.<BitmapData>(PageBmd_Num);
		}
		
		//---- Protected Methods -----------------------------------------------
		
		private function SetFilter(obj:Object):void {
			var filter:DropShadowFilter = new DropShadowFilter();
			filter.blurX = filter.blurY = 10;
			filter.alpha = 0.5;
			filter.distance = 0;
			filter.angle = 0;
			obj.filters = [filter];
		}
		
		private function MouseFindArea(point:Point):Number {
			/* 取下面的四个区域,返回数值:
			*   --------------------
			*  | -1|     |     | -3 |
			*  |---      |      ----|
			*  |     1   |   3      |
			*  |---------|----------| 
			*  |     2   |   4      |
			*  |----     |      ----|
			*  | -2 |    |     | -4 |
			*   --------------------
			*/
			var tmpn:Number;
			var minx:Number=0;
			var maxx:Number=book_width+book_width;
			var miny:Number=0;
			var maxy:Number=book_height;
			var areaNum:Number=50;

			if (point.x > minx && point.x <= maxx * 0.5) 
			{
				tmpn = (point.y > miny && point.y <= (maxy * 0.5))?1:(point.y > (maxy * 0.5) && point.y < maxy)?2:0;
				if (point.x <= (minx + areaNum))
				{
					tmpn = (point.y > miny && point.y <= (miny + areaNum))? -1:(point.y > (maxy - areaNum) && point.y < maxy)? -2:tmpn;
				}
				return tmpn;
			} else if (point.x > (maxx * 0.5) && point.x < maxx)
			{
				tmpn = (point.y > miny && point.y <= (maxy * 0.5))?3:(point.y > (maxy * 0.5) && point.y < maxy)?4:0;
				if (point.x >= (maxx - areaNum)) 
				{
					tmpn = (point.y > miny && point.y <= (miny + areaNum))? -3:(point.y > (maxy - areaNum) && point.y < maxy)? -4:tmpn;
				}
				return tmpn;
			}
			return 0;
		}
		
		private function PageUp():void
		{			
			var point_mypos:Point=book_myposArray[book_TimerArg0-1];
			var b0:Bitmap;
			var b1:Bitmap;
			
			book_px=point_mypos.x;
			book_py=point_mypos.y;
			
			b0 = new Bitmap(FBmdVec[2]);
			b1 = new Bitmap(FBmdVec[3]);
			b1.x=book_width;
			bgMC.addChild(b0);
			bgMC.addChild(b1);
			bgMC.visible=false;
			
		}
		
		private function DrawShape(shape:Shape, point_array:Array, myBmp:BitmapData, matr:Matrix):void
		{
			var num:int = point_array.length;
			shape.graphics.clear();
			shape.graphics.beginBitmapFill(myBmp, matr, false, true);
			
			shape.graphics.moveTo(point_array[0].x, point_array[0].y);
			for (var i:int = 1; i < num; i++) 
			{
				shape.graphics.lineTo(point_array[i].x, point_array[i].y);
			}
			
			shape.graphics.endFill();
		}
		
		private function DrawShadowShap(
			shape:Shape, 
			maskShape:Shape, 
			g_width:Number, 
			g_height:Number, 
			$point1:Point, 
			$point2:Point, 
			$maskArray:Array, 
			$arg:Number):void 
		{
			var fillType:String = GradientType.LINEAR;
			var colors:Array = [0x0, 0x0];
			var alphas1:Array = [0,0.5];
			var alphas2:Array = [0.5,0];
			var ratios:Array = [0, 255];
			var matr:Matrix = new Matrix();
			var spreadMethod:String = SpreadMethod.PAD;
			var myscale:Number;
			var myalpha:Number;
			
			shape.graphics.clear();
			matr.createGradientBox(g_width, g_height, (0 / 180) * Math.PI, -g_width * 0.5, -g_height * 0.5);
			
			shape.graphics.beginGradientFill(fillType, colors, alphas1, ratios, matr, spreadMethod);
			shape.graphics.drawRect( -g_width * 0.5, -g_height * 0.5, g_width * 0.5, g_height);
			shape.graphics.beginGradientFill(fillType, colors, alphas2, ratios, matr, spreadMethod);
			shape.graphics.drawRect(0, -g_height * 0.5, g_width * 0.5, g_height);
			
			shape.x = $point2.x + ($point1.x - $point2.x) * $arg;
			shape.y = $point2.y + ($point1.y - $point2.y) * $arg;
			shape.rotation = angle($point1, $point2);
			myscale = Math.abs($point1.x - $point2.x) * 0.5 / book_width;
			myalpha = 1 - myscale * myscale;
			
			shape.scaleX = myscale+0.1;
			shape.alpha = myalpha + 0.1;			
			
			var tmp_Bmp:BitmapData = new BitmapData(book_width * 2, book_height, true, 0x0);
			DrawShape(maskShape, $maskArray, tmp_Bmp, new Matrix());
			shape.mask = maskShape;			
		}
		
		private function DrawPage(
			num:Number, 
			_movePoint:Point, 
			bmp1:BitmapData, 
			bmp2:BitmapData):void 
		{			
			//var _movePoint:Point = new Point(FBookRes.mouseX, FBookRes.mouseY);
			var _actionPoint:Point;
			
			var book_array:Array;
			var book_Matrix1:Matrix=new Matrix();
			var book_Matrix2:Matrix=new Matrix();
			var Matrix_angle:Number;
			
			
			if (num == 1) 
			{			
				_movePoint=CheckLimit(_movePoint,limit_point1,book_width);
				_movePoint=CheckLimit(_movePoint,limit_point2,book_CrossGap);
				
				book_array=GetBook_array(_movePoint,p1,p2);
				_actionPoint=book_array[1];
				GetLayer_array(_movePoint,_actionPoint,p1,p2,limit_point1,limit_point2);
				
				DrawShadowShap(shadow0,Mask0,book_width*1.5,book_height*4,p1,_movePoint,new Array(p1,p3,p4,p2),0.5);
				DrawShadowShap(shadow1, Mask1, book_width * 1.5, book_height * 4, p1, _movePoint, bookArray_layer1, 0.45);
				
				Matrix_angle=angle(_movePoint,_actionPoint)+90;
				book_Matrix1.rotate((Matrix_angle/180)*Math.PI);
				book_Matrix1.tx=book_array[3].x;
				book_Matrix1.ty = book_array[3].y;
				
				book_Matrix2.tx=p1.x;
				book_Matrix2.ty = p1.y;
				
			} else if (num == 2) 
			{
				
				_movePoint=CheckLimit(_movePoint,limit_point2,book_width);
				_movePoint = CheckLimit(_movePoint, limit_point1, book_CrossGap);
				
				book_array=GetBook_array(_movePoint,p2,p1);
				_actionPoint=book_array[1];
				GetLayer_array(_movePoint, _actionPoint, p2, p1, limit_point2, limit_point1);
				
				DrawShadowShap(shadow0,Mask0,book_width*1.5,book_height*4,p2,_movePoint,new Array(p1,p3,p4,p2),0.5);
				DrawShadowShap(shadow1, Mask1, book_width * 1.5, book_height * 4, p2, _movePoint, bookArray_layer1, 0.45);
				
				Matrix_angle=angle(_movePoint,_actionPoint)-90;
				book_Matrix1.rotate((Matrix_angle/180)*Math.PI);
				book_Matrix1.tx=book_array[2].x;
				book_Matrix1.ty = book_array[2].y;
				
				book_Matrix2.tx=p1.x;
				book_Matrix2.ty=p1.y;
			} else if (num == 3) 
			{
				_movePoint=CheckLimit(_movePoint,limit_point1,book_width);
				_movePoint = CheckLimit(_movePoint, limit_point2, book_CrossGap);
				
				book_array=GetBook_array(_movePoint,p3,p4);
				_actionPoint=book_array[1];
				GetLayer_array(_movePoint, _actionPoint, p3, p4, limit_point1, limit_point2);
				
				DrawShadowShap(shadow0,Mask0,book_width*1.5,book_height*4,p3,_movePoint,new Array(p1,p3,p4,p2),0.5);
				DrawShadowShap(shadow1, Mask1, book_width * 1.5, book_height * 4, p3, _movePoint, bookArray_layer1, 0.4);
				
				Matrix_angle=angle(_movePoint,_actionPoint)+90;
				book_Matrix1.rotate((Matrix_angle/180)*Math.PI);
				book_Matrix1.tx=_movePoint.x;
				book_Matrix1.ty = _movePoint.y;
				
				book_Matrix2.tx=limit_point1.x;
				book_Matrix2.ty=limit_point1.y;
			} else 
			{
				_movePoint=CheckLimit(_movePoint,limit_point2,book_width);
				_movePoint = CheckLimit(_movePoint, limit_point1, book_CrossGap);
				
				book_array=GetBook_array(_movePoint,p4,p3);
				_actionPoint=book_array[1];
				GetLayer_array(_movePoint, _actionPoint, p4, p3, limit_point2, limit_point1);
				
				DrawShadowShap(shadow0,Mask0,book_width*1.5,book_height*4,p4,_movePoint,new Array(p1,p3,p4,p2),0.5);
				DrawShadowShap(shadow1, Mask1, book_width * 1.5, book_height * 4, p4, _movePoint, bookArray_layer1, 0.4);
				
				Matrix_angle=angle(_movePoint,_actionPoint)-90;
				book_Matrix1.rotate((Matrix_angle/180)*Math.PI);
				book_Matrix1.tx=_actionPoint.x;
				book_Matrix1.ty=_actionPoint.y;
				
				book_Matrix2.tx=limit_point1.x;
				book_Matrix2.ty=limit_point1.y;
			}
			
			DrawShape(render1,bookArray_layer1,bmp1,book_Matrix1);
			DrawShape(render0,bookArray_layer2,bmp2,book_Matrix2);
		}
		private function GetBook_array($point:Point,$actionPoint1:Point,$actionPoint2:Point):Array {

			var array_return:Array=new Array();
			var $Gap1:Number=Math.abs(pos($actionPoint1,$point)*0.5);
			var $Angle1:Number=angle($actionPoint1,$point);
			var $tmp1_2:Number=$Gap1/Math.cos(($Angle1/180)*Math.PI);
			var $tmp_point1:Point=new Point($actionPoint1.x-$tmp1_2,$actionPoint1.y);

			var $Angle2:Number=angle($point,$tmp_point1)-angle($point,$actionPoint2);
			var $Gap2:Number=pos($point,$actionPoint2);
			var $tmp2_1:Number=$Gap2*Math.sin(($Angle2/180)*Math.PI);
			var $tmp2_2:Number=$Gap2*Math.cos(($Angle2/180)*Math.PI);
			var $tmp_point2:Point=new Point($actionPoint1.x+$tmp2_2,$actionPoint1.y+$tmp2_1);

			var $Angle3:Number=angle($tmp_point1,$point);
			var $tmp3_1:Number=book_width*Math.sin(($Angle3/180)*Math.PI);
			var $tmp3_2:Number=book_width*Math.cos(($Angle3/180)*Math.PI);

			var $tmp_point3:Point=new Point($tmp_point2.x+$tmp3_2,$tmp_point2.y+$tmp3_1);
			var $tmp_point4:Point=new Point($point.x+$tmp3_2,$point.y+$tmp3_1);

			array_return.push($point);
			array_return.push($tmp_point2);
			array_return.push($tmp_point3);
			array_return.push($tmp_point4);

			return array_return;

		}
		private function GetLayer_array($point1:Point,$point2:Point,$actionPoint1:Point,$actionPoint2:Point,$limitPoint1:Point,$limitPoint2:Point):void {

			var array_layer1:Array=new Array();
			var array_layer2:Array=new Array();
			var $Gap1:Number=Math.abs(pos($actionPoint1,$point1)*0.5);
			var $Angle1:Number=angle($actionPoint1,$point1);

			var $tmp1_1:Number=$Gap1/Math.sin(($Angle1/180)*Math.PI);
			var $tmp1_2:Number=$Gap1/Math.cos(($Angle1/180)*Math.PI);

			var $tmp_point1:Point=new Point($actionPoint1.x-$tmp1_2,$actionPoint1.y);
			var $tmp_point2:Point=new Point($actionPoint1.x,$actionPoint1.y-$tmp1_1);

			var $tmp_point3:Point=$point2;

			var $Gap2:Number=Math.abs(pos($point1,$actionPoint2));
			//---------------------------------------------
			if ($Gap2>book_height) {
				array_layer1.push($tmp_point3);
				//
				var $pos:Number=Math.abs(pos($tmp_point3,$actionPoint2)*0.5);
				var $tmp3:Number=$pos/Math.cos(($Angle1/180)*Math.PI);
				$tmp_point2=new Point($actionPoint2.x-$tmp3,$actionPoint2.y);

			} else {
				array_layer2.push($actionPoint2);
			}
			array_layer1.push($tmp_point2);
			array_layer1.push($tmp_point1);
			array_layer1.push($point1);
			bookArray_layer1=array_layer1;

			array_layer2.push($limitPoint2);
			array_layer2.push($limitPoint1);
			array_layer2.push($tmp_point1);
			array_layer2.push($tmp_point2);
			bookArray_layer2=array_layer2;

		}
		private function CheckLimit($point:Point,$limitPoint:Point,$limitGap:Number):Point {

			var $Gap:Number=Math.abs(pos($limitPoint,$point));
			var $Angle:Number=angle($limitPoint,$point);
			if ($Gap>$limitGap) {
				var $tmp1:Number=$limitGap*Math.sin(($Angle/180)*Math.PI);
				var $tmp2:Number=$limitGap*Math.cos(($Angle/180)*Math.PI);
				$point=new Point($limitPoint.x-$tmp2,$limitPoint.y-$tmp1);
			}
			return $point;

		}
		
		//**Tools Parts------------------------------------------------------------------------
		private function Arc(arg_R:Number, arg_N1:Number, arg_N2:Number):Number 
		{
			//------圆弧算法-----------------------
			var arg:Number = arg_R * 2;
			var r:Number = arg_R * arg_R + arg * arg;
			var a:Number = Math.abs(arg_N1) - arg_R;
			var R_arg:Number = arg_N2 - (Math.sqrt(r - a * a) - arg);
			return R_arg;
		}
		
		private function angle(target1:Point, target2:Point):Number
		{
			var tmp_x:Number = target1.x - target2.x;
			var tmp_y:Number = target1.y - target2.y;
			var tmp_angle:Number = Math.atan2(tmp_y, tmp_x) * 180 / Math.PI;
			tmp_angle = tmp_angle < 0 ? tmp_angle+360 : tmp_angle;
			return tmp_angle;
		}
		
		private function pos(target1:Point, target2:Point):Number
		{		
			var tmp_x:Number = target1.x - target2.x;
			var tmp_y:Number = target1.y - target2.y;
			var tmp_s:Number = Math.sqrt(tmp_x * tmp_x + tmp_y * tmp_y);
			return target1.x > target2.x?tmp_s: - tmp_s;
		}
		
		//---- Event Handling Methods ------------------------------------------
		
		//---- Property Accessing Methods --------------------------------------
		
		//---- Public Methods ----------------------------------------------------
		
		/**
		 * Res  透明元件，用于获取鼠标坐标*/
		public function Setup(
			Res:MovieClip,
			PageWidth:int,
			PageHeight:int):void
		{
			var Index:int;
			
			FBookRes = Res;
			book_root = new MovieClip();
			FBookRes.addChild(book_root);
			
			book_width = PageWidth;
			book_height = PageHeight;
			
			book_CrossGap = Math.sqrt(book_width * book_width + PageHeight * PageHeight);
			
			for (Index = 0; Index < PageBmd_Num; Index++) 
			{
				FBmdVec[Index] = new BitmapData(book_width, book_height);
			}
			
			//往左位移一个页的宽度，用来画右边的书页
			FPageMatrix = new Matrix(1, 0, 0, 1, -book_width, 0);
			
			p1=new Point(0,0);
			p2=new Point(0,book_height);
			p3=new Point(book_width+book_width,0);
			p4=new Point(book_width+book_width,book_height);
			
			limit_point1=new Point(book_width,0);
			limit_point2=new Point(book_width,book_height);
			
			book_toposArray=[p3,p4,p1,p2];
			book_myposArray = [p1, p2, p3, p4];
			
			book_root.addChild(pageMC);
			book_root.addChild(bgMC);
			SetFilter(pageMC);
			SetFilter(bgMC);
			
			book_root.addChild(Mask0);
			book_root.addChild(Mask1);
			
			book_root.addChild(render0);
			book_root.addChild(shadow0);			
			book_root.addChild(render1);
			book_root.addChild(shadow1); 
			
			
		}
		
		/**
		 * 以从左往右的逻辑
		 * Page0 第1、2页
		 * Page1 第3、4页，
		 * IsLeft 是否向左翻*/
		public function SetupPage(
			Page0:BitmapData,
			Page1:BitmapData,
			IsLeft:Boolean):void
		{
			if (IsLeft)
			{
				FBmdVec[0].draw(Page0, FPageMatrix);
				FBmdVec[1].draw(Page1);
			}
			else
			{
				FBmdVec[0].draw(Page1);
				FBmdVec[1].draw(Page0, FPageMatrix);
			}
			
			FBmdVec[2].draw(Page0);
			FBmdVec[3].draw(Page1, FPageMatrix);
			
		}
		
		public function Fliper():void
		{
			book_TimerArg0 = MouseFindArea(new Point(book_root.mouseX, book_root.mouseY));
			book_TimerArg0 = book_TimerArg0 < 0? -book_TimerArg0:book_TimerArg0;
			if (book_TimerArg0 == 0) return;
			book_TimerFlag = Book_Flag_Fliper;
			PageUp();
		}
		
		public function Turn():void
		{
			book_TimerFlag = Book_Flag_Playing;
		}
		
		public function LogicsPerform():void
		{
			var point_topos:Point = book_toposArray[book_TimerArg0 - 1];
			var point_mypos:Point = book_myposArray[book_TimerArg0 - 1];
			
			var array_point1:Array;
			var array_point2:Array;
			var numpoint1:Number;
			var numpoint2:Number;
			
			var tox:Number;
			var toy:Number;
			var toflag:Number;
			var tmpx:Number;
			var tmpy:Number;
			
			var arg:Number;
			var r:Number;
			var a:Number;
			
			var b0:Bitmap;
			var b1:Bitmap;
			
			bgMC.visible=true;
			
			while (pageMC.numChildren > 0)
			{
				pageMC.removeChildAt(0);
			}
			
			if (book_TimerFlag == Book_Flag_Fliper) 
			{
				u=0.4;
				render0.graphics.clear();
				render1.graphics.clear();
				book_px = ((render0.mouseX - book_px) * u + book_px) >> 0;
				book_py = ((render0.mouseY - book_py) * u + book_py) >> 0;
				
				DrawPage(book_TimerArg0, new Point(book_px, book_py), FBmdVec[1], FBmdVec[0]);
				
			} else if (book_TimerFlag == Book_Flag_Playing) 
			{
				render0.graphics.clear();
				render1.graphics.clear();
				if (Math.abs(point_topos.x - book_px) > book_width && book_TimerArg1 > 0)
				{
					//不处于点翻区域并且翻页不过中线时
					tox = point_mypos.x;
					toy = point_mypos.y;
					toflag = 0;
				} else {
					tox = point_topos.x;
					toy = point_topos.y;
					toflag = 1;
				}
				tmpx = (tox - book_px) >> 0;
				tmpy = (toy - book_py) >> 0;

				if (book_TimerArg1<0) {
					//处于点翻区域时
					u = 0.3;//降低加速度
					book_py = Arc(book_width, tmpx, point_topos.y);
				} else {
					u = 0.4;//原始加速度
					book_py = tmpy * u + book_py;
				}
				book_px = tmpx * u + book_px;
				
				DrawPage(book_TimerArg0, new Point(book_px, book_py), FBmdVec[1], FBmdVec[0]);
				
				/*if (tmpx == 0 && tmpy == 0) 
				{					
					render0.graphics.clear();
					render1.graphics.clear();
					shadow0.graphics.clear();
					shadow1.graphics.clear();
					
					
					for (var i:int = 0; i < PageBmd_Num; i++ )
					{
						FBmdVec[i].dispose();
					}
					
					while (bgMC.numChildren > 0) 
					{
						bgMC.removeChildAt(0);
					}
					
					b0 = new Bitmap(FBmdVec[0]);
					b1 = new Bitmap(FBmdVec[1]);
					b0.x=b0.y=0;
					b1.x=book_width;
					pageMC.addChild(b0);
					pageMC.addChild(b1);
					
					book_TimerFlag = Book_Flag_Stop;//恢得静止状态
					
					if (OnPageEnd != null)
					{
						OnPageEnd();
					}
					
					bgMC.visible = false;
					
				}*/
			}
		}
	}

}