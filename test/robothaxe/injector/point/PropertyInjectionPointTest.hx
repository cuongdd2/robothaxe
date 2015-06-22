package robothaxe.injector.injectionpoints;

import massive.munit.Assert;
import robothaxe.injector.Injector;
import robothaxe.injector.support.injectees.ClassInjectee;
import robothaxe.injector.support.types.Class1;

class PropertyInjectionPointTest
 {
	public function new(){}
	
	var injector:Injector;

	@Before
	public function runBeforeEachTest():Void
	{
		injector = new Injector();
	}

	@After
	public function teardown():Void
	{
		injector = null;
	}
	
	@Test
	public function injectionOfSinglePropertyIsApplied():Void
	{
		injector.mapSingleton(Class1);

		var injectee = new ClassInjectee();
		var meta = {inject:null, name:["property"], type:["robothaxe.injector.support.types.Class1"]};
		var injectionPoint = new PropertyInjectionPoint(meta);
		injectionPoint.applyInjection(injectee, injector);
		
		Assert.isTrue(Std.is( injectee.property, Class1));
		//"injectee should contain Class1 instance"
	}
}
