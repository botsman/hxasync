package async;

import async.AsyncMacroUtils;


@:build(async.AsyncMacro.build())
class MyClass {
  @async public static function some() {
    return "some func called";
  }

  @async public static function funcWithCallback(callback) {
    trace("Calling a callback");
    @await callback("result");
  }

  @async public static function hiFunc() {
    var arrowFunc = @async () -> {
      trace("Arrow func is executed");
      @await some();
    }

    var arrowFuncWithReturn = @async () -> {
      trace("Arrow func with explicit return executed");
      @await some();
    }

    @async function localFunction() {
      trace("Local function executed");
      @await some();
    }
    @await arrowFunc();
    @await some();

    var callback = @async function(arg: String) {
      trace(arg);
    };
    @await funcWithCallback(callback);

    @await funcWithCallback(@async function(arg: String) {
      trace(arg);
    });
    return "asd";
  }
}

class Main {
  static public function main(): Void {
    MyClass.hiFunc();
  }
}
