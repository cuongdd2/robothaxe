/*
* Copyright (c) 2009, 2010 the original author or authors
*
* Permission is hereby granted to use, modify, and distribute this file
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.base;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import robothaxe.injector.Injector;
import robothaxe.core.IViewMap;

using robothaxe.util.Helper;

/**
 * An abstract <code>IViewMap</code> implementation
 */
class ViewMap extends ViewMapBase implements IViewMap
{
	/**
	 * @private
	 */
	var mappedPackages:Array<String>;

	/**
	 * @private
	 */
	var mappedTypes:Map<Class<Dynamic>, Class<Dynamic>>;

	/**
	 * @private
	 */
	var injectedViews:Map<DisplayObject, Bool>;

	//---------------------------------------------------------------------
	// Constructor
	//---------------------------------------------------------------------

	/**
	 * Creates a new <code>ViewMap</code> object
	 *
	 * @param contextView The root view node of the context. The map will listen for ADDED_TO_STAGE events on this node
	 * @param injector An <code>IInjector</code> to use for this context
	 */
	public function new(contextView:DisplayObjectContainer, injector:Injector)
	{
		super(contextView, injector);

		// mappings - if you can do it with fewer dictionaries you get a prize
		this.mappedPackages = new Array<String>();
		this.mappedTypes = new Map<Class<Dynamic>, Class<Dynamic>>();
		this.injectedViews = new Map<DisplayObject, Bool>();
	}

	//---------------------------------------------------------------------
	// API
	//---------------------------------------------------------------------

	/**
	 * @inheritDoc
	 */
	public function mapPackage(packageName:String):Void
	{
		if (!Lambda.has(mappedPackages, packageName))
		{
			mappedPackages.push(packageName);
			viewListenerCount++;
			if (viewListenerCount == 1)
				addListeners();
		}
	}

	/**
	 * @inheritDoc
	 */
	public function unmapPackage(packageName:String):Void
	{
		if (Lambda.has(mappedPackages, packageName))
		{
			mappedPackages.remove(packageName);
			viewListenerCount--;
			if (viewListenerCount == 0)
				removeListeners();
		}
	}

	/**
	 * @inheritDoc
	 */
	public function mapType(type:Class<Dynamic>):Void
	{
		if (mappedTypes.get(type) != null) return;

		mappedTypes.set(type, type);

		viewListenerCount++;
		if (viewListenerCount == 1)
			addListeners();

		// This was a bad idea - causes unexpected eager instantiation of object graph
		if (contextView != null && Std.is(contextView, type))
			injectInto(contextView);
	}

	/**
	 * @inheritDoc
	 */
	public function unmapType(type:Class<Dynamic>):Void
	{
		var mapping:Class<Dynamic> = mappedTypes.get(type);
		mappedTypes.remove(type);
		if (mapping != null)
		{
			viewListenerCount--;
			if (viewListenerCount == 0)
				removeListeners();
		}
	}

	/**
	 * @inheritDoc
	 */
	public function hasType(type:Class<Dynamic>):Bool
	{
		return mappedTypes.exists(type);
	}

	/**
	 * @inheritDoc
	 */
	public function hasPackage(packageName:String):Bool
	{
		return Lambda.has(mappedPackages, packageName);
	}

	//---------------------------------------------------------------------
	// Internal
	//---------------------------------------------------------------------

	/**
	 * @private
	 */
	override function addListeners():Void
	{
		if (contextView != null && enabled)
			contextView.addEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture, 0, true);
	}

	/**
	 * @private
	 */
	override function removeListeners():Void
	{
		if (contextView != null)
			contextView.removeEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture);
	}

	/**
	 * @private
	 */
	override function onViewAdded(e:Event):Void
	{
		var view:DisplayObject = cast(e.target, DisplayObject);
		if (injectedViews.get(view) != null)
			return;

		for (type in mappedTypes)
		{
			if (Std.is(view, type))
			{
				injectInto(view);
				return;
			}
		}

		var len = mappedPackages.length;
		if (len > 0)
		{
			var className:String = view.getQualifiedClassName();
			for (i in 0...len)
			{
				var packageName:String = mappedPackages[i];
				if (className.indexOf(packageName) == 0)
				{
					injectInto(view);
					return;
				}
			}
		}
	}

	override function onViewRemoved(view:Dynamic):Void
	{
		trace("TODO");
	}

	function injectInto(view:DisplayObject):Void
	{
		injector.injectInto(view);
		injectedViews.set(view, true);
	}
}
