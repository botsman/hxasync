package tests;


@:build(hxasync.AsyncMacro.build())
class Cases {
  public function new() {}

  var a: String = "a";
  @async public static function some() {
    return "some func called";
  }

  @async public static function funcWithCallback(callback) {
    trace("Calling a callback");
    @await callback("result");
  }

  @async public function hiFunc() {
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

    var funcWithDefaults = @async function(a: String = "asd") {
      trace("funcWithDefaults called");
    }
    @await funcWithDefaults();

    var firstLevelFunc = @async function() {
      trace("called on first level");
      var secondLevelFunc = @async function() {
        trace("called on a second level");
        trace(this.a);
      }
      @await secondLevelFunc();
    }

    @await firstLevelFunc();
  }
}


@:build(hxasync.AsyncMacro.build())
class Tests {
  @async static public function main() {
    var cases = new Cases();
    @await cases.hiFunc();
  }
}
