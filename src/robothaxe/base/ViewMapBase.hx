/*
* Copyright (c) 2009, 2010 the original author or authors
*
* Permission is hereby granted to use, modify, and distribute this file
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.base;

import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import robothaxe.injector.Injector;

/**
 * A base ViewMap implementation
 */
class ViewMapBase
{
	public var contextView (default, set):DisplayObjectContainer;
	public var enabled (default, set):Bool;
	
	/**
	 * @private
	 */
	var injector:Injector;

	/**
	 * @private
	 */
	var useCapture:Bool;
	
	/**
	 * @private
	 */		
	var viewListenerCount:Int;

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
		viewListenerCount = 0;
		enabled = true;

		this.injector = injector;

		// change this at your peril lest ye understand the problem and have a better solution
		this.useCapture = true;

		// this must come last, see the setter
		this.contextView = contextView;
	}

	//---------------------------------------------------------------------
	// API
	//---------------------------------------------------------------------
	
	/**
	 * @inheritDoc
	 */
	public function set_contextView(value:DisplayObjectContainer):DisplayObjectContainer
	{
		if (value != contextView)
		{
			removeListeners();
			contextView = value;
			if (viewListenerCount > 0)
				addListeners();
		}
		return contextView;
	}

	/**
	 * @inheritDoc
	 */
	public function set_enabled(value:Bool):Bool
	{
		if (value != enabled)
		{
			removeListeners();
			enabled = value;
			if (viewListenerCount > 0)
				addListeners();
		}
		return enabled;
	}

	//---------------------------------------------------------------------
	// Internal
	//---------------------------------------------------------------------

	/**
	 * @private
	 */
	function addListeners():Void
	{
	}

	/**
	 * @private
	 */
	function removeListeners():Void
	{
	}

	/**
	 * @private
	 */
	function onViewAdded(e:Event):Void
	{
	}

	/**
	 * @private
	 */
	function onViewRemoved(e:Event):Void
	{
	}
}
