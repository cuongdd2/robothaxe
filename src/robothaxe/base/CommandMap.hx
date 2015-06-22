/*
 * Copyright (c) 2009 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package robothaxe.base;

import robothaxe.injector.Injector;
import openfl.events.Event;
import openfl.events.IEventDispatcher;
import robothaxe.core.ICommandMap;
import robothaxe.core.IReflector;

/**
 * An abstract <code>ICommandMap</code> implementation
 */
class CommandMap implements ICommandMap
{
	/**
	 * The <code>IEventDispatcher</code> to listen to
	 */
	var eventDispatcher:IEventDispatcher;
	
	/**
	 * The <code>Injector</code> to inject with
	 */
	var injector:Injector;
	
	/**
	 * The <code>IReflector</code> to reflect with
	 */
	var reflector:IReflector;
	
	/**
	 * Internal
	 *
	 * TODO: This needs to be documented
	 */
	var eventTypeMap:Map<String, Map<Class<Dynamic>, Map<Class<Dynamic>, Dynamic>>>;
	
	/**
	 * Internal
	 *
	 * Collection of command classes that have been verified to implement an <code>execute</code> method
	 */
	var verifiedCommandClasses:Array<Class<Dynamic>>;
	
	var detainedCommands:Array<Dynamic>;
	
	//---------------------------------------------------------------------
	//  Constructor
	//---------------------------------------------------------------------
	
	/**
	 * Creates a new <code>CommandMap</code> object
	 *
	 * @param eventDispatcher The <code>IEventDispatcher</code> to listen to
	 * @param injector An <code>Injector</code> to use for this context
	 * @param reflector An <code>IReflector</code> to use for this context
	 */
	public function new(eventDispatcher:IEventDispatcher, injector:Injector, reflector:IReflector)
	{
		this.eventDispatcher = eventDispatcher;
		this.injector = injector;
		this.reflector = reflector;
		this.eventTypeMap = new Map<String, Map<Class<Dynamic>, Map<Class<Dynamic>, Dynamic>>>();
		this.verifiedCommandClasses = new Array<Class<Dynamic>>();
		this.detainedCommands = new Array<Dynamic>();
	}
	
	//---------------------------------------------------------------------
	//  API
	//---------------------------------------------------------------------
	
	/**
	 * @inheritDoc
	 */
	public function mapEvent(eventType:String, commandClass:Class<Dynamic>, eventClass:Class<Dynamic>=null, oneshot:Bool=false):Void
	{
		verifyCommandClass(commandClass);
		if (eventClass == null) eventClass = Event;
		
		var eventClassMap = eventTypeMap.get(eventType);
		if (eventClassMap == null)
		{
			eventClassMap = new Map<Class<Dynamic>, Map<Class<Dynamic>, Dynamic>>();
			eventTypeMap.set(eventType, eventClassMap);
		}

		var callbacksByCommandClass = eventClassMap.get(eventClass);
		if (callbacksByCommandClass == null)
		{
			callbacksByCommandClass = new Map<Class<Dynamic>, Dynamic>();
			eventClassMap.set(eventClass, callbacksByCommandClass);
		}
			
		if (callbacksByCommandClass.get(commandClass) != null)
		{
			throw new ContextError(ContextError.E_COMMANDMAP_OVR + ' - eventType (' + eventType + ') and Command (' + commandClass + ')');
		}
		
		var me = this;
		var callback = function(event:Event)
		{
			me.routeEventToCommand(event, commandClass, oneshot, eventClass);
		};

		eventDispatcher.addEventListener(eventType, callback, false, 0, true);
		callbacksByCommandClass.set(commandClass, callback);
	}
	
	/**
	 * @inheritDoc
	 */
	public function unmapEvent(eventType:String, commandClass:Class<Dynamic>, eventClass:Class<Dynamic> = null):Void
	{
		var eventClassMap = eventTypeMap.get(eventType);
		if (eventClassMap == null) return;

		if (eventClass == null) eventClass = Event;
		var callbacksByCommandClass = eventClassMap.get(eventClass);
		if (callbacksByCommandClass == null) return;
		
		var commandCallback = callbacksByCommandClass.get(commandClass);
		if (commandCallback == null) return;
		
		eventDispatcher.removeEventListener(eventType, commandCallback, false);
		callbacksByCommandClass.remove(commandClass);
	}
	
	/**
	 * @inheritDoc
	 */
	public function unmapEvents():Void
	{
		for (eventType in eventTypeMap.keys())
		{
			var eventClassMap = eventTypeMap.get(eventType);
			for (callbacksByCommandClass in eventClassMap)
			{
				for (callback in callbacksByCommandClass)
				{
					eventDispatcher.removeEventListener(eventType, callback, false);
				}
			}
		}

		eventTypeMap = new Map<String, Map<Class<Dynamic>, Map<Class<Dynamic>, Dynamic>>>();
	}
	
	/**
	 * @inheritDoc
	 */
	public function hasEventCommand(eventType:String, commandClass:Class<Dynamic>, eventClass:Class<Dynamic> = null):Bool
	{

		var eventClassMap = eventTypeMap.get(eventType);
		if (eventClassMap == null) return false;

		if (eventClass == null) eventClass = Event;
		var callbacksByCommandClass = eventClassMap.get(eventClass);
		if (callbacksByCommandClass == null) return false;
		
		return callbacksByCommandClass.exists(commandClass);
	}
	
	/**
	 * @inheritDoc
	 */
	public function execute(commandClass:Class<Dynamic>, payload:Dynamic = null, payloadClass:Class<Dynamic> = null, named:String = ""):Void
	{
		verifyCommandClass(commandClass);

		if (payload != null || payloadClass != null)
		{
			payloadClass = (payloadClass != null) ? payloadClass : reflector.getClass(payload);

			if (Std.is(payload, Event) && payloadClass != Event)
				injector.mapValue(Event, payload);

			injector.mapValue(payloadClass, payload, named);
		}
		
		var command:Dynamic = injector.instantiate(commandClass);
		
		if (payload != null || payloadClass != null)
		{
			if (Std.is(payload, Event) && payloadClass != Event)
				injector.unmap(Event);

			injector.unmap(payloadClass, named);
		}
		
		command.execute();
	}
	
	/**
	 * @inheritDoc
	 */
	public function detain(command:Dynamic):Void
	{
		detainedCommands.push(command);
	}
	
	/**
	 * @inheritDoc
	 */
	public function release(command:Dynamic):Void
	{
		detainedCommands.remove(command);
	}
	
	/**
	 * @throws robothaxe.base::ContextError 
	 */
	function verifyCommandClass(commandClass:Class<Dynamic>):Void
	{
		if (Lambda.has(verifiedCommandClasses, commandClass))
		{
			var fields = Type.getInstanceFields(commandClass);
			var verified = Lambda.has(fields, "execute");
			
			if (verified)
			{
				verifiedCommandClasses.push(commandClass);
			}
			else
			{
				throw new ContextError(ContextError.E_COMMANDMAP_NOIMPL + ' - ' + Type.getClassName(commandClass));
			}
		}
	}
	
	/**
	 * Event Handler
	 *
	 * @param event The <code>Event</code>
	 * @param commandClass The Class to construct and execute
	 * @param oneshot Should this command mapping be removed after execution?
     * @return <code>true</code> if the event was routed to a Command and the Command was executed,
     *         <code>false</code> otherwise
	 */
	function routeEventToCommand(event:Event, commandClass:Class<Dynamic>, oneshot:Bool, originalEventClass:Class<Dynamic>):Bool
	{
		if (!(Std.is(event, originalEventClass))) return false;
		
		execute(commandClass, event);
		
		if (oneshot) unmapEvent(event.type, commandClass, originalEventClass);
		
		return true;
	}
}
