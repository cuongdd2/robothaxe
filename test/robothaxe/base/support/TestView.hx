/*
* Copyright (c) 2009 the original author or authors
* 
* Permission is hereby granted to use, modify, and distribute this file 
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.base.support;

import flash.display.DisplayObject;
class TestView extends DisplayObject
{
	@inject("injectionName")
	public var injectionPoint:String;

}
