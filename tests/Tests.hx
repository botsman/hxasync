package tests;



class Cases {
  public static var some = "some variable";

  @async public static function testBasic() {
    return "basic func called";
  }

  @async public static function testFuncWithCallback() {
    var callback = @async function callbackFunction() {
      trace("callback is called");
    }
    var functionAcceptingCallback = @async function(callback) {
      @await callback();
    }

    @await functionAcceptingCallback(callback);
  }

  @async public static function testArrowFunction() {
    var arrowFunction = @async () -> {
      trace("arrow function called");
    }

    @await arrowFunction();
  }

  @async public static function testFunctionWithDefaultArgs() {
    var funcWithOneDefaultArg = @async function(a: String = "some") {
      trace('Default arg: ${a}');
    }
    @await funcWithOneDefaultArg();

    var funcWithTwoDefaultArgs = @async function(a: String = "some", b: String = "another") {
      trace('Default args: ${a} and ${b}');
    }
    @await funcWithTwoDefaultArgs();
  }

  @async public static function testNestedFunction() {
    var nestedFunction = @async function() {
      trace(Cases.some);
    }

    @await nestedFunction();
  }

  @async public static function execute() {
    @await testBasic();
    @await testFuncWithCallback();
    @await testArrowFunction();
    @await testFunctionWithDefaultArgs();
    @await testNestedFunction();
  }
}

@:expose
class Tests {
  static public function main() {
    Cases.execute();
  }
}
