/*
* Copyright (c) 2009 the original author or authors
*
* Permission is hereby granted to use, modify, and distribute this file
* in accordance with the terms of the license agreement accompanying it.
*/

package robothaxe.base;

import massive.munit.Assert;
import robothaxe.injector.Injector;
import robothaxe.injector.Reflector;
import robothaxe.base.support.TestView;
import robothaxe.base.support.ITestView;
import robothaxe.base.support.TestContextView;
import robothaxe.core.IReflector;
import robothaxe.core.IViewMap;

class ViewMapTest
 {
	public function new(){}
	
	static var INJECTION_NAME = "injectionName";
	static var INJECTION_STRING = "injectionString";
	
	var contextView:TestContextView;
	var testView:TestView;
	var injector:Injector;
	var reflector:IReflector;
	var viewMap:IViewMap;
	
	@Before
	public function runBeforeEachTest():Void
	{
		contextView = new TestContextView();
		testView = new TestView();
		injector = new Injector();
		reflector = new Reflector();
		viewMap = new ViewMap(contextView, injector);
		
		injector.mapValue(String, INJECTION_STRING, INJECTION_NAME);
	}
	
	@After
	public function runAfterEachTest():Void
	{
		contextView = null;
		testView = null;
		injector = null;
		reflector = null;
		viewMap = null;
		injector = null;
	}
	
	@Test
	public function mapType():Void
	{
		viewMap.mapType(TestView);
		var mapped = viewMap.hasType(TestView);
		Assert.isTrue(mapped);//"Class should be mapped"
	}
	
	@Test
	public function unmapType():Void
	{
		viewMap.mapType(TestView);
		viewMap.unmapType(TestView);
		var mapped = viewMap.hasType(TestView);
		Assert.isFalse(mapped);//"Class should NOT be mapped"
	}
	
	@Test
	public function mapTypeAndAddToDisplay():Void
	{
		viewMap.mapType(TestView);
		contextView.addChild(testView);
		Assert.areEqual(INJECTION_STRING, testView.injectionPoint);//"Injection points should be satisfied"
	}
	
	@Test
	public function unmapTypeAndAddToDisplay():Void
	{
		viewMap.mapType(TestView);
		viewMap.unmapType(TestView);
		contextView.addChild(testView);
		Assert.isNull(testView.injectionPoint);//"Injection points should NOT be satisfied after unmapping"
	}
	
	@Test
	public function mapTypeAndAddToDisplayTwice():Void
	{
		viewMap.mapType(TestView);
		contextView.addChild(testView);
		testView.injectionPoint = null;
		contextView.removeView(testView);
		contextView.addChild(testView);
		Assert.isNull(testView.injectionPoint);//"View should NOT be injected into twice"
	}
	
	@Test
	public function mapTypeOfContextViewShouldInjectIntoIt():Void
	{
		viewMap.mapType(TestContextView);
		Assert.areEqual(INJECTION_STRING, contextView.injectionPoint);//"Injection points in contextView should be satisfied"
	}
	
	@Test
	public function mapTypeOfContextViewTwiceShouldInjectOnlyOnce():Void
	{
		viewMap.mapType(TestContextView);
		contextView.injectionPoint = null;
		viewMap.mapType(TestContextView);
		Assert.isNull(testView.injectionPoint);//"contextView should NOT be injected into twice"
	}
	
	@Test
	public function mapPackage():Void
	{
		viewMap.mapPackage('robothaxe');
		var mapped = viewMap.hasPackage('robothaxe');
		Assert.isTrue(mapped);//"Package should be mapped"
	}
	
	@Test
	public function unmapPackage():Void
	{
		viewMap.mapPackage("robothaxe");
		viewMap.unmapPackage("robothaxe");
		var mapped = viewMap.hasPackage("robothaxe");
		Assert.isFalse(mapped);//"Package should NOT be mapped"
	}
	
	@Test
	public function mappedPackageIsInjected():Void
	{
		viewMap.mapPackage("robothaxe");
		contextView.addChild(testView);
		Assert.areEqual(INJECTION_STRING, testView.injectionPoint);//"Injection points should be satisfied"
	}
	
	@Test
	public function mappedAbsolutePackageIsInjected():Void
	{
		viewMap.mapPackage("robothaxe.base.support");
		contextView.addChild(testView);
		Assert.areEqual(INJECTION_STRING, testView.injectionPoint);//"Injection points should be satisfied"
	}
	
	@Test
	public function unmappedPackageShouldNotBeInjected():Void
	{
		viewMap.mapPackage("robothaxe");
		viewMap.unmapPackage("robothaxe");
		contextView.addChild(testView);
		Assert.isNull(testView.injectionPoint);//"Injection points should NOT be satisfied after unmapping"
	}
	
	@Test
	public function mappedPackageNotInjectedTwiceWhenRemovedAndAdded():Void
	{
		viewMap.mapPackage("robothaxe");
		contextView.addChild(testView);
		testView.injectionPoint = null;
		contextView.removeView(testView);
		contextView.addChild(testView);
		
		Assert.isNull(testView.injectionPoint);//"View should NOT be injected into twice"
	}
	
	@Test
	public function mapInterface():Void
	{
		viewMap.mapType(ITestView);
		var mapped = viewMap.hasType(ITestView);
		Assert.isTrue(mapped);//"Inteface should be mapped"
	}
	
	@Test
	public function unmapInterface():Void
	{
		viewMap.mapType(ITestView);
		viewMap.unmapType(ITestView);
		var mapped = viewMap.hasType(ITestView);
		Assert.isFalse(mapped);//"Class should NOT be mapped"
	}
	
	@Test
	public function mappedInterfaceIsInjected():Void
	{
		viewMap.mapType(ITestView);
		contextView.addChild(testView);
		Assert.areEqual(INJECTION_STRING, testView.injectionPoint);//"Injection points should be satisfied"
	}
	
	@Test
	public function unmappedInterfaceShouldNotBeInjected():Void
	{
		viewMap.mapType(ITestView);
		viewMap.unmapType(ITestView);
		contextView.addChild(testView);
		Assert.isNull(testView.injectionPoint);//"Injection points should NOT be satisfied after unmapping"
	}
	
	@Test
	public function mappedInterfaceNotInjectedTwiceWhenRemovedAndAdded():Void
	{
		viewMap.mapType(ITestView);
		contextView.addChild(testView);
		testView.injectionPoint = null;
		contextView.removeView(testView);
		contextView.addChild(testView);
		Assert.isNull(testView.injectionPoint);//"View should NOT be injected into twice"
	}
}
