/*
 * Copyright (c) 2009 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package robothaxe.base;

/**
 * A framework Error implementation
 */
class ContextError
{
	public static inline var E_COMMANDMAP_NOIMPL:String = 'Command Class does not implement an execute() method';
	public static inline var E_COMMANDMAP_OVR:String = 'Cannot overwrite map';
	
	public static inline var E_MEDIATORMAP_NOIMPL:String = 'Mediator Class does not implement IMediator';
	public static inline var E_MEDIATORMAP_OVR:String = 'Mediator Class has already been mapped to a View Class in this context';
	
	public static inline var E_EVENTMAP_NOSNOOPING:String = 'Listening to the context eventDispatcher is not enabled for this EventMap';
	
	public static inline var E_CONTEXT_INJECTOR:String = 'The ContextBase does not specify a concrete Injector. Please override the injector getter in your concrete or abstract Context.';
	public static inline var E_CONTEXT_REFLECTOR:String = 'The ContextBase does not specify a concrete IReflector. Please override the reflector getter in your concrete or abstract Context.';
	public static inline var E_CONTEXT_VIEW_OVR:String = 'Context contextView must only be set once';

	public var message:String;
	public var id:Int;

	public function new(message:String = "", id:Int = 0)
	{
		this.message = message;
		this.id = id;
	}
}
