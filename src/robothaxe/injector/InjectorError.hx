/*
* Copyright (c) 2009 the original author or authors
* 
* Permission is hereby granted to use, modify, and distribute this file 
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.injector;

import openfl.errors.Error;
class InjectorError extends Error
{
	public function new(message:String = "", id:Int = 0)
	{
		super(message, id);
	}
}
