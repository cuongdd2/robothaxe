/*
* Copyright (c) 2009-2010 the original author or authors
* 
* Permission is hereby granted to use, modify, and distribute this file 
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.injector;

import openfl.system.ApplicationDomain;
import Lambda;
import robothaxe.injector.point.ConstructorInjectionPoint;
import robothaxe.injector.point.InjectionPoint;
import robothaxe.injector.point.MethodInjectionPoint;
import robothaxe.injector.point.NoParamsConstructorInjectionPoint;
import robothaxe.injector.point.PostConstructInjectionPoint;
import robothaxe.injector.point.PropertyInjectionPoint;
import robothaxe.injector.result.InjectClassResult;
import robothaxe.injector.result.InjectOtherRuleResult;
import robothaxe.injector.result.InjectSingletonResult;
import robothaxe.injector.result.InjectValueResult;
import haxe.rtti.Meta;

class Injector
{
	public var attendedToInjectees (default, null):Array<Dynamic>;
	public var parentInjector (default, set):Injector;
	public var applicationDomain(get, null): ApplicationDomain;

	var m_mappings:Map<String, Dynamic>;
	var m_injecteeDescriptions:Map<Class<Dynamic>, InjecteeDescription>;
	
	public function new()
	{
		m_mappings = new Map<String, Dynamic>();
		m_injecteeDescriptions = new Map<Class<Dynamic>, InjecteeDescription>();
		attendedToInjectees = new Array<Dynamic>();
	}
	
	public function mapValue(whenAskedFor:Class<Dynamic>, useValue:Dynamic, named:String = ""):InjectionConfig
	{
		var config = getMapping(whenAskedFor, named);
		config.setResult(new InjectValueResult(useValue));
		return config;
	}
	
	public function mapClass(whenAskedFor:Class<Dynamic>, instantiateClass:Class<Dynamic>, named:String=""):InjectionConfig
	{
		var config = getMapping(whenAskedFor, named);
		config.setResult(new InjectClassResult(instantiateClass));
		return config;
	}
	
	public function mapSingleton(whenAskedFor :Class<Dynamic>, named:String="") :InjectionConfig
	{
		return mapSingletonOf(whenAskedFor, whenAskedFor, named);
	}
	
	public function mapSingletonOf(whenAskedFor:Class<Dynamic>, useSingletonOf:Class<Dynamic>, named:String=""):InjectionConfig
	{
		var config = getMapping(whenAskedFor, named);
		config.setResult(new InjectSingletonResult(useSingletonOf));
		return config;
	}
	
	public function mapRule(whenAskedFor:Class<Dynamic>, useRule:Dynamic, named:String = ""):Dynamic
	{
		var config = getMapping(whenAskedFor, named);
		config.setResult(new InjectOtherRuleResult(useRule));
		return useRule;
	}
	
	function getClassName(forClass:Class<Dynamic>):String
	{
		if (forClass == null) return "Dynamic";
		else return Type.getClassName(forClass);
	}

	public function getMapping(forClass:Class<Dynamic>, named:String=""):InjectionConfig
	{
		var requestName = getClassName(forClass) + "#" + named;
		
		if (m_mappings.exists(requestName))
		{
			return m_mappings.get(requestName);
		}
		
		var config = new InjectionConfig(forClass, named);
		m_mappings.set(requestName, config);
		return config;
	}
	
	public function injectInto(target:Dynamic):Void
	{
		if (Lambda.has(attendedToInjectees, target))
		{
			return;
		}

		attendedToInjectees.push(target);
		
		//get injection points or cache them if this target's class wasn't encountered before
		var targetClass = Type.getClass(target);

		var injecteeDescription:InjecteeDescription = null;
		injecteeDescription = m_injecteeDescriptions.exists(targetClass) ?
			m_injecteeDescriptions.get(targetClass) :
			getInjectionPoints(targetClass);

		if (injecteeDescription == null) return;

		for (injectionPoint in injecteeDescription.injectionPoints)
			injectionPoint.applyInjection(target, this);
	}
	
	public function instantiate<T>(forClass:Class<T>):T
	{
		var injecteeDescription = m_injecteeDescriptions.exists(forClass) ?
			m_injecteeDescriptions.get(forClass) :
			getInjectionPoints(forClass);
		var injectionPoint:InjectionPoint = injecteeDescription.ctor;
		var instance:Dynamic = injectionPoint.applyInjection(forClass, this);
		injectInto(instance);
		return instance;
	}
	
	public function unmap(theClass:Class<Dynamic>, named:String=""):Void
	{
		var mapping = getConfigurationForRequest(theClass, named);
		if (mapping == null)
		{
			throw new InjectorError('Error while removing an injector mapping: No mapping defined for class ' +
			getClassName(theClass) + ', named "' + named + '"');
		}
		mapping.setResult(null);
	}

	public function hasMapping(forClass:Class<Dynamic>, named :String = '') :Bool
	{
		var mapping = getConfigurationForRequest(forClass, named);
		if (mapping == null)
		{
			return false;
		}
		return mapping.hasResponse(this);
	}

	public function getInstance<T>(ofClass:Class<T>, named:String=""):T
	{
		var mapping = getConfigurationForRequest(ofClass, named);
		
		if (mapping == null || !mapping.hasResponse(this))
		{
			throw new InjectorError('Error while getting mapping response: No mapping defined for class ' +
			getClassName(ofClass) + ', named "' + named + '"');
		}
		return mapping.getResponse(this);
	}

	public function createChildInjector(applicationDomain:ApplicationDomain = null):Injector
	{
		var injector = new Injector();
		injector.applicationDomain = applicationDomain;
		injector.parentInjector = this;
		return injector;
	}

	function get_applicationDomain():ApplicationDomain
	{
		return applicationDomain != null ? applicationDomain : ApplicationDomain.currentDomain;
	}

	public function getAncestorMapping(forClass:Class<Dynamic>, named:String=null):InjectionConfig
	{
		var parent = parentInjector;

		while (parent != null)
		{
			var parentConfig = parent.getConfigurationForRequest(forClass, named, false);
			if (parentConfig != null && parentConfig.hasOwnResponse())
			{
				return parentConfig;
			}
			parent = parent.parentInjector;
		}
		return null;
	}

	function getInjectionPoints(forClass:Class<Dynamic>):InjecteeDescription
	{
		var typeMeta = Meta.getType(forClass);

		if (typeMeta != null && Reflect.hasField(typeMeta, "interface"))
		{
			throw new InjectorError("Interfaces can't be used as instantiatable classes.");
		}

		var fieldsMeta = getFields(forClass);

		var ctorInjectionPoint:InjectionPoint = null;
		var injectionPoints:Array<InjectionPoint> = [];
		var postConstructMethodPoints:Array<Dynamic> = [];
		
		for (field in Reflect.fields(fieldsMeta))
		{
			var fieldMeta:Dynamic = Reflect.field(fieldsMeta, field);

			var inject = Reflect.hasField(fieldMeta, "inject");
			var post = Reflect.hasField(fieldMeta, "post");
			var type = Reflect.field(fieldMeta, "type");
			var args = Reflect.field(fieldMeta, "args");
			
			if (field == "_") // constructor
			{
				if (args.length > 0)
				{
					ctorInjectionPoint = new ConstructorInjectionPoint(fieldMeta, forClass, this);
				}
			}
			else if (Reflect.hasField(fieldMeta, "args")) // method
			{
				if (inject) // injection
				{
					var injectionPoint = new MethodInjectionPoint(fieldMeta, this);
					injectionPoints.push(injectionPoint);
				}
				else if (post) // post construction
				{
					var injectionPoint = new PostConstructInjectionPoint(fieldMeta, this);
					postConstructMethodPoints.push(injectionPoint);
				}
			}
			else if (type != null) // property
			{
				var injectionPoint = new PropertyInjectionPoint(fieldMeta, this);
				injectionPoints.push(injectionPoint);
			}
		}

		if (postConstructMethodPoints.length > 0)
		{
			postConstructMethodPoints.sort(function(a, b) { return a.order - b.order; });
			
			for (point in postConstructMethodPoints)
			{
				injectionPoints.push(point);
			}
		}

		if (ctorInjectionPoint == null)
		{
			ctorInjectionPoint = new NoParamsConstructorInjectionPoint();
		}

		var injecteeDescription = new InjecteeDescription(ctorInjectionPoint, injectionPoints);
		m_injecteeDescriptions.set(forClass, injecteeDescription);
		return injecteeDescription;
	}

	function getConfigurationForRequest(forClass:Class<Dynamic>, named:String, traverseAncestors:Bool=true):InjectionConfig
	{
		var requestName = getClassName(forClass) + '#' + named;
		var config = m_mappings.get(requestName);
		if(config == null && traverseAncestors &&
			parentInjector != null && parentInjector.hasMapping(forClass, named))
		{
			config = getAncestorMapping(forClass, named);
		}
		return config;
	}
	/* pretty sure this is only used by xml config, which we don't use.
	function addParentInjectionPoints(description:Classdef, injectionPoints:Array<Dynamic>):Void
	{
		var parentClassName = description.superClass.path;

		if (parentClassName == null)
		{
			return;
		}

		var parentClass = Type.resolveClass(parentClassName);
		var parentDescription:InjecteeDescription = null;

		if (m_injecteeDescriptions.exists(parentClass))
		{
			parentDescription = m_injecteeDescriptions.get(parentClass);
		}
		else
		{
			parentDescription = getInjectionPoints(parentClass);
		}

		injectionPoints.push(injectionPoints);
		injectionPoints.push(parentDescription.injectionPoints);
	}
	*/
	function set_parentInjector(value:Injector):Injector
	{
		//restore own map of worked injectees if parent injector is removed
		if (parentInjector != null && value == null)
		{
			attendedToInjectees = new Array<Dynamic>();
		}
		parentInjector = value;
		//use parent's map of worked injectees
		if (parentInjector != null)
		{
			attendedToInjectees = parentInjector.attendedToInjectees;
		}
		return parentInjector;
	}


	function getFields(type:Class<Dynamic>)
	{
		var meta = {};

		while (type != null)
		{
			var typeMeta = haxe.rtti.Meta.getFields(type);

			for (field in Reflect.fields(typeMeta))
			{
				Reflect.setField(meta, field, Reflect.field(typeMeta, field));
			}

			type = Type.getSuperClass(type);
		}

		return meta;
	}
}

class ClassHash<T>
{
	var hash:Map<String,T>;

	public function new()
	{
		hash = new Map<String,T>();
	}

	public function set(key:Class<Dynamic>, value:T):Void
	{
		hash.set(Type.getClassName(key), value);
	}

	public function get(key:Class<Dynamic>):T
	{
		return hash.get(Type.getClassName(key));
	}

	public function exists(key:Class<Dynamic>):Bool
	{
		return hash.exists(Type.getClassName(key));
	}
}

class InjecteeDescription
{
	public var ctor:InjectionPoint;
	public var injectionPoints:Array<InjectionPoint>;

	public function new(ctor:InjectionPoint, injectionPoints:Array<InjectionPoint>)
	{
		this.ctor = ctor;
		this.injectionPoints = injectionPoints;
	}
}
