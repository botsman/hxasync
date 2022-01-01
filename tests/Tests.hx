package tests;

class Cases {
  public var some = "some variable";

  public function new() {}

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
      trace("asd");
    }

    @await nestedFunction();
  }

  @async public static function testBrackets() {
    var nestedFunction = @async function() {
      return {
        a: 10
      };
    }
    return (@await nestedFunction()).a;
  }

  @async public static function testAnonymousStructure() {
    var someAsyncFunction = @async function() {
      return 1;
    }
    return {
      a: @await someAsyncFunction()
    }
  }

  @async public static function testAnonymousStructureInArray() {
    var someAsyncFunction = @async function() {
      return 1;
    }
    var arr: Array<Dynamic> = [];
    arr.push({
      a: @await someAsyncFunction()
    });
    return arr;
  }

  @async public static function testStringInterpolation() {
    var someAsyncFunction = @async function() {
      return 1;
    }
    return 'asd ${@await someAsyncFunction()}';
  }

  @async public static function testAsyncCallAsArgument() {
    var someAsyncFunction = @async function() {
      return 1;
    }
    var anotherFunction = function(arg: Int) {
      return arg;
    }
    return anotherFunction(@await someAsyncFunction());
  }

  @async public function returnDynamic() {
    var a = 10;
    return {
      a: a,
      b: this.some
    };
  }

  @async public static function execute() {
    @await testBasic();
    @await testFuncWithCallback();
    @await testArrowFunction();
    @await testFunctionWithDefaultArgs();
    @await testNestedFunction();
    @await testBrackets();
    @await testAnonymousStructure();
    @await testAnonymousStructureInArray();
    @await testStringInterpolation();
    @await testAsyncCallAsArgument();
  }
}

@:expose
class Tests {
  static public function main() {
    var cases = new Cases();
    cases.returnDynamic();
  }
}
