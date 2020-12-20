package async;


@:build(async.AsyncMacro.build())
class MyClass {
  @async public static function some() {
    return "some func called";
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
    return @await some();
  }
}

class Main {
  @async static public function main(): Void {
    @await MyClass.hiFunc();
  }
}
