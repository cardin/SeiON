package com.SeiON.Misc
{
	/**
	 * Enumerable.as
	 * @version Dated 6 Jan 2011
	 * ---------------
	 * Faux enumerations in Actionscript. Done through code reflection and static initializers.
	 *
	 * Adapted from:
	 * http://scottbilas.com/2008/06/01/faking-enums-in-as3/
	 * Scott Bilas - For his wonderful enumeration function.
	 * Hadrien - For the idea for type-checking the constants.
	 *
	 * @author Cardin Lee
	 * http://cardinal4.co.cc/
	 *
		Copyright (C) 2011 by Cardin Lee

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:
		
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
		THE SOFTWARE.
	 *
	 * @usage
	 * ----------------------------- USAGE ------------------------------
	 * To use this, you need to call initEnum in a static initializer within the constructor of
	 * the class you want to make into an Enumerator.
	 *
	 * For instance, for an Enumeration called DaysInWeek, it will look like this:
		
		public class DaysInWeek extends Enumerable
		{
			public static const MONDAY:DaysInWeek = new DaysInWeek();
			public static const TUESDAY:DaysInWeek = new DaysInWeek();
			public static const WEDNESDAY:DaysInWeek = new DaysInWeek();
			public static const THURSDAY:DaysInWeek = new DaysInWeek();
			public static const FRIDAY:DaysInWeek = new DaysInWeek();
			public static const SATURDAY:DaysInWeek = new DaysInWeek();
			public static const SUNDAY:DaysInWeek = new DaysInWeek();
			
			// this segment in brackets must be exist to work
			{
				initEnum(DaysInWeek);
			}
		}
		
	 * Usage-wise, you can refer to it using its value or its string value:
		trace(DaysInWeek.MONDAY.valueOf()); // 3
		trace(DaysInWeek.MONDAY.toString()); // Monday
	
	 * You can also retrieve the Enum constant using its value:
		var theDay:DaysInWeek = Enumerable.retrieveValue(1, DaysInWeek) as DaysInWeek;
		trace(theDay.toString()); // Friday
		
	 * Notice how the value of the Enumerable does not match the sequence at which it is written.
	 * That is typical of the Flash environment, as it does not instantiate sequentially. If you
	 * want to set your own index so the index value has a sort of sequence, you can. But it can
	 * be tedious, and very nearly defeats the purpose of an automated enumerated class:
		public class DaysInWeek extends Enumerable
		{
			public static const MONDAY:DaysInWeek = new DaysInWeek();
			public static const TUESDAY:DaysInWeek = new DaysInWeek();
			public static const WEDNESDAY:DaysInWeek = new DaysInWeek();
			public static const THURSDAY:DaysInWeek = new DaysInWeek();
			public static const FRIDAY:DaysInWeek = new DaysInWeek();
			public static const SATURDAY:DaysInWeek = new DaysInWeek();
			public static const SUNDAY:DaysInWeek = new DaysInWeek();
			
			public static const SPECIAL_DAY:DaysInWeek = new DaysInWeek();
			
			{
				initEnum(DaysInWeek);
				
				MONDAY.index = 0;
				TUESDAY.index = 1;
				WEDNESDAY.index = 2;
				THURSDAY.index = 3;
				FRIDAY.index = 4;
				SATURDAY.index = 5;
				SUNDAY.index = 6;
				
				SPECIAL_DAY.index = 99999;
			}
		}
	 * Notes for the above method:
	 * 	- The index does not have to be sequential.
	 *  - You must NOT repeat indexes. If there are repeat indexes, no error will be thrown, but
	 * 	  your index will keep returning weird values.
	 */
	
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Assists in the creation of faux enumeration datatypes.
	 */
	public class Enumerable
	{
		private var constName:String;
		protected var index:uint;
		
		/**
		 * Initializes the specified class object into a faux enumeration datatype.
		 *
		 * @param inType The class object that you wish to initialize.
		 */
		protected static function initEnum(classObj:*):void
		{
			var type:XML = describeType(classObj);
			var className:String = getQualifiedClassName(classObj);
			
			// sort ALPHABETICALLY into an array
			var tempList:Array = new Array();
			for each (var tempConst:XML in type.constant)
			{
				// Verify that we don't anyhow change any constant.
				if (tempConst.@type == className)
				{
					tempList.push(tempConst.@name);
				}
			}
			tempList = tempList.sort();
			
			var i:int = 0;
			for each (var constant:String in tempList)
			{
				classObj[constant].constName = constant;
				classObj[constant].index = i;
				i++;
			}
		}
		
		
		/**
		 * Retrieves a constant from an constant class based on its string value.
		 *
		 * @param	value	The string value of the constant.
		 * @param	classObj	The constant class to which the constant belongs to.
		 * @return	The constant itself.
		 * @see #retriveValue()
		 */
		public static function stringRetrieveValue(strValue:String, classObj:Class):Enumerable
		{
			strValue = StringUtils.trim(strValue);
			strValue = StringUtils.capitalize(strValue, true);
			
			var type:XML = describeType(classObj);
			var className:String = getQualifiedClassName(classObj);
			
			for each (var constant:XML in type.constant)
			{
				if (constant.@type == className)
				{
					if (classObj[constant.@name].toString() == strValue)
						return classObj[constant.@name];
				}
			}
			return null;
		}
		
		/**
		 * Retrieves a constant from an constant class based on its numerical value.
		 *
		 * @param	value	The numerical value of the constant.
		 * @param	classObj	The constant class to which the constant belongs to.
		 * @return	The constant itself.
		 * @see #stringRetrieveValue()
		 */
		public static function retrieveValue(value:uint, classObj:Class):Enumerable
		{
			var type:XML = describeType(classObj);
			var className:String = getQualifiedClassName(classObj);
			
			for each (var constant:XML in type.constant)
			{
				if (constant.@type == className)
				{
					if (classObj[constant.@name].index == value)
						return classObj[constant.@name];
				}
			}
			return null;
		}
		
		/**
		 * Name of the constant.
		 *
		 * @return The string representation of the specified constant.
		 * @see #valueOf()
		 */
		public function toString():String
		{
			var tempName:String = constName.toLowerCase();
			var tempArray:Array = tempName.split("_");
			tempName = tempArray.join(" ");
			tempName = StringUtils.trim(tempName);
			tempName = StringUtils.capitalize(tempName, true);
			
			return tempName;
		}
		
		/**
		 * Value of the constant.
		 *
		 * @return The numerical representation of the specified constant.
		 * @see	#toString()
		 */
		public function valueOf():uint
		{
			return index;
		}
	}
}

	/**
	* 	String Utilities class by Ryan Matsikas, Feb 10 2006
	*
	*	Visit www.gskinner.com for documentation, updates and more free code.
	* 	You may distribute this code freely, as long as this comment block remains intact.
	*/
	internal class StringUtils {
	
	/**
	*	Capitalizes the first word in a string or all words..
	*
	*	@param p_string The string.
	*	@param p_all (optional) Boolean value indicating if we should
	*	capitalize all words or only the first.
	*
	*	@returns String
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 9.0
	*	@tiptext
	*/
	internal static function capitalize(p_string:String, ...args):String {
		var str:String = trimLeft(p_string);
		if (args[0] === true) { return str.replace(/^.|\b./g, _upperCase);}
		else { return str.replace(/(^\w)/, _upperCase); }
	}
	
	/**
	*	Removes whitespace from the front and the end of the specified
	*	string.
	*
	*	@param p_string The String whose beginning and ending whitespace will
	*	will be removed.
	*
	*	@returns String
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 9.0
	*	@tiptext
	*/
	internal static function trim(p_string:String):String {
		if (p_string == null) { return ''; }
		return p_string.replace(/^\s+|\s+$/g, '');
	}
	
	/**
	*	Removes whitespace from the front (left-side) of the specified string.
	*
	*	@param p_string The String whose beginning whitespace will be removed.
	*
	*	@returns String
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 9.0
	*	@tiptext
	*/
	private static function trimLeft(p_string:String):String {
		if (p_string == null) { return ''; }
		return p_string.replace(/^\s+/, '');
	}
	
	private static function _upperCase(p_char:String, ...args):String {
		return p_char.toUpperCase();
	}
}