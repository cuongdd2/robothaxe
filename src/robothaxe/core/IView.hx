package robothaxe.core;

interface IView
{
	var viewAdded:Dynamic -> Void;
	var viewRemoved:Dynamic -> Void;
	
	function isAdded(view:Dynamic):Bool;
}