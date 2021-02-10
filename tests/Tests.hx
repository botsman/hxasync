package tests;


abstract Awaitable<T>(T) from T {}

class Cases {
  public var some = "some variable";

  public function new() {}

  @async public static function testBasic(): Awaitable<String> {
    return "basic func called";
  }

  // @async public static function testFuncWithCallback() {
  //   var callback = @async function callbackFunction() {
  //     trace("callback is called");
  //   }
  //   var functionAcceptingCallback = @async function(callback) {
  //     @await callback();
  //   }

  //   @await functionAcceptingCallback(callback);
  // }

  // @async public static function testArrowFunction() {
  //   var arrowFunction = @async () -> {
  //     trace("arrow function called");
  //   }

  //   @await arrowFunction();
  // }

  // @async public static function testFunctionWithDefaultArgs() {
  //   var funcWithOneDefaultArg = @async function(a: String = "some") {
  //     trace('Default arg: ${a}');
  //   }
  //   @await funcWithOneDefaultArg();

  //   var funcWithTwoDefaultArgs = @async function(a: String = "some", b: String = "another") {
  //     trace('Default args: ${a} and ${b}');
  //   }
  //   @await funcWithTwoDefaultArgs();
  // }

  // @async public function testNestedFunction() {
  //   var nestedFunction = @async function() {
  //     trace(this.some);
  //   }

  //   @await nestedFunction();
  // }

  @async public function execute() {
    testBasic();
    // @await testFuncWithCallback();
    // @await testArrowFunction();
    // @await testFunctionWithDefaultArgs();
    // @await testNestedFunction();
  }
}

@:expose
class Tests {
  static public function main() {
    var cases = new Cases();
    cases.execute();
  }
}
