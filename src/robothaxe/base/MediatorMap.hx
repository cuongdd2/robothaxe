/*
* Copyright (c) 2009, 2010 the original author or authors
* 
* Permission is hereby granted to use, modify, and distribute this file 
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.base;

import robothaxe.injector.Injector;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import robothaxe.core.IMediator;
import robothaxe.core.IMediatorMap;
import robothaxe.core.IReflector;

using robothaxe.util.Helper;

/**
 * An abstract <code>IMediatorMap</code> implementation
 */
class MediatorMap extends ViewMapBase implements IMediatorMap
{
	static var enterFrameDispatcher:Sprite = new Sprite();
	var mediatorByView:Map<Dynamic, IMediator>;
	var mappingConfigByView:Map<Dynamic, MappingConfig>;
	var mappingConfigByViewClassName:Map<String, MappingConfig>;
	var mediatorsMarkedForRemoval:Map<Dynamic, Dynamic>;
	var hasMediatorsMarkedForRemoval:Bool;
	var reflector:IReflector;
	
	/**
	 * Creates a new <code>MediatorMap</code> object
	 *
	 * @param contextView The root view node of the context. The map will listen for ADDED_TO_STAGE events on this node
	 * @param injector An <code>IInjector</code> to use for this context
	 * @param reflector An <code>IReflector</code> to use for this context
	 */
	public function new(contextView:DisplayObjectContainer, injector:Injector, reflector:IReflector)
	{
		super(contextView, injector);
		
		this.reflector = reflector;
		
		// mappings - if you can do it with fewer dictionaries you get a prize
		this.mediatorByView = new Map<Dynamic, IMediator>();
		this.mappingConfigByView = new Map<Dynamic, MappingConfig>();
		this.mappingConfigByViewClassName = new Map<String, MappingConfig>();
		this.mediatorsMarkedForRemoval = new Map<Dynamic, Dynamic>();
		this.hasMediatorsMarkedForRemoval = false;
	}
	
	//---------------------------------------------------------------------
	//  API
	//---------------------------------------------------------------------
	
	/**
	 * @inheritDoc
	 */
	public function mapView(viewClassOrName:Dynamic, mediatorClass:Class<Dynamic>, injectViewAs:Dynamic=null, autoCreate:Bool=true, autoRemove:Bool=true):Void
	{
		var viewClassName:String = reflector.getFQCN(viewClassOrName);
		
		if (mappingConfigByViewClassName.get(viewClassName) != null)
			throw new ContextError(ContextError.E_MEDIATORMAP_OVR + ' - ' + mediatorClass);

		if (reflector.classExtendsOrImplements(mediatorClass, IMediator) == false)
			throw new ContextError(ContextError.E_MEDIATORMAP_NOIMPL + ' - ' + mediatorClass);

		var config = new MappingConfig();
		config.mediatorClass = mediatorClass;
		config.autoCreate = autoCreate;
		config.autoRemove = autoRemove;

		if (injectViewAs)
		{
			if (Std.is(injectViewAs, Array))
			{
				config.typedViewClasses = cast(injectViewAs, Array<Dynamic>).copy();
			}
			else if (Std.is(injectViewAs, Class))
			{
				config.typedViewClasses = [injectViewAs];
			}
		}
		else if (Std.is(viewClassOrName, Class))
		{
			config.typedViewClasses = [viewClassOrName];
		}
		mappingConfigByViewClassName.set(viewClassName, config);
		
		if (autoCreate || autoRemove)
		{
			viewListenerCount++;
			if (viewListenerCount == 1)
				addListeners();
		}
		
		// This was a bad idea - causes unexpected eager instantiation of object graph 
		if (autoCreate && contextView != null && viewClassName == contextView.getQualifiedClassName())
		{
			createMediatorUsing(contextView, viewClassName, config);
		}
	}
	
	/**
	 * @inheritDoc
	 */
	public function unmapView(viewClassOrName:Dynamic):Void
	{
		var viewClassName = reflector.getFQCN(viewClassOrName);
		var config = mappingConfigByViewClassName.get(viewClassName);

		if (config != null && (config.autoCreate || config.autoRemove))
		{
			viewListenerCount--;
			if (viewListenerCount == 0)
				removeListeners();
		}
		mappingConfigByViewClassName.remove(viewClassName);
	}
	
	/**
	 * @inheritDoc
	 */
	public function createMediator(viewComponent:Dynamic):IMediator
	{
		return createMediatorUsing(viewComponent);
	}
	
	/**
	 * @inheritDoc
	 */
	public function registerMediator(viewComponent:Dynamic, mediator:IMediator):Void
	{
		var mediatorClass = reflector.getClass(mediator);
		if(injector.hasMapping(mediatorClass)) injector.unmap(mediatorClass);
		injector.mapValue(mediatorClass, mediator);
		mediatorByView.set(viewComponent, mediator);
		var mapping = mappingConfigByViewClassName.get(viewComponent.getQualifiedClassName());
		mappingConfigByView.set(viewComponent, mapping);
		mediator.setViewComponent(viewComponent);
		mediator.preRegister();
	}
	
	/**
	 * @inheritDoc
	 */
	public function removeMediator(mediator:IMediator):IMediator
	{
		if (mediator != null)
		{
			var viewComponent = mediator.getViewComponent();
			var mediatorClass = reflector.getClass(mediator);
			mediatorByView.remove(viewComponent);
			mappingConfigByView.remove(viewComponent);
			mediator.preRemove();
			mediator.setViewComponent(null);
			if(injector.hasMapping(mediatorClass)) injector.unmap(mediatorClass);
		}
		
		return mediator;
	}
	
	/**
	 * @inheritDoc
	 */
	public function removeMediatorByView(viewComponent:Dynamic):IMediator
	{
		return removeMediator(retrieveMediator(viewComponent));
	}
	
	/**
	 * @inheritDoc
	 */
	public function retrieveMediator(viewComponent:Dynamic):IMediator
	{
		return mediatorByView.get(viewComponent);
	}
	
	/**
	 * @inheritDoc
	 */
	public function hasMapping(viewClassOrName:Dynamic):Bool
	{
		var viewClassName:String = reflector.getFQCN(viewClassOrName);
		return mappingConfigByViewClassName.get(viewClassName) != null;
	}
	
	/**
	 * @inheritDoc
	 */
	public function hasMediatorForView(viewComponent:Dynamic):Bool
	{
		return mediatorByView.exists(viewComponent);
	}
	
	/**
	 * @inheritDoc
	 */
	public function hasMediator(mediator:IMediator):Bool
	{
		for (med in mediatorByView)
			if (med == mediator)
				return true;
		return false;
	}
	
	// helper
		
	override function addListeners():Void
	{
		if (contextView != null && enabled)
		{
			contextView.addEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture, 0, true);
			contextView.addEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture, 0, true);
		}
	}
		
	override function removeListeners():Void
	{
		if (contextView != null)
		{
			contextView.removeEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture);
			contextView.removeEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture);
		}
	}
	
	override function onViewAdded(e: Event):Void
	{
		var view = e.target;
		if (mediatorsMarkedForRemoval.get(view) != null)
		{
			mediatorsMarkedForRemoval.remove(view);
			return;
		}
		var viewClassName:String = view.getQualifiedClassName();
		var config = mappingConfigByViewClassName.get(viewClassName);
		if (config != null && config.autoCreate)
			createMediatorUsing(view, viewClassName, config);
	}

	function createMediatorUsing(viewComponent:Dynamic, viewClassName:String=null, config:MappingConfig=null):IMediator
	{
		var mediator = mediatorByView.get(viewComponent);
		if (mediator == null)
		{
			if (viewClassName == null) viewClassName = viewComponent.getQualifiedClassName();
			if (config == null) config = mappingConfigByViewClassName.get(viewClassName);
			if (config != null)
			{
				for (claxx in config.typedViewClasses) 
				{
					injector.mapValue(claxx, viewComponent);
				}
				mediator = injector.instantiate(config.mediatorClass);
				for (clazz in config.typedViewClasses)
				{
					injector.unmap(clazz);
				}
				registerMediator(viewComponent, mediator);
			}
		}
		return mediator;
	}

	override function onViewRemoved(e: Event):Void
	{
		var config = mappingConfigByView.get(e.target);
		if (config != null && config.autoRemove)
		{
			mediatorsMarkedForRemoval.set(e.target, e.target);
			if (!hasMediatorsMarkedForRemoval)
			{
				hasMediatorsMarkedForRemoval = true;
				enterFrameDispatcher.addEventListener(Event.ENTER_FRAME, removeMediatorLater);
			}
		}
	}

	function removeMediatorLater(e: Event):Void
	{
		enterFrameDispatcher.removeEventListener(Event.ENTER_FRAME, removeMediatorLater);
		for (view in mediatorsMarkedForRemoval.keys())
		{
			if (!view.stage)
				removeMediatorByView(view);
			mediatorsMarkedForRemoval.remove(view);
		}
		hasMediatorsMarkedForRemoval = false;
	}
}

class MappingConfig
{
	public function new(){}

	public var mediatorClass:Class<Dynamic>;
	public var typedViewClasses:Array<Dynamic>;
	public var autoCreate:Bool;
	public var autoRemove:Bool;
}