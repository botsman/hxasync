package async;

import async.AsyncMacro;


@:build(async.AsyncMacro.build())
class MyClass {
  @async public static function some() {
    return "some func called";
  }

  @async public static function hiFunc() {
    // return @await some();
    // return AsyncMacroUtils.await(some());
    return @await some();
  }
}

class Main {
  @async static public function main(): Void {
    @await MyClass.hiFunc();
  }
}
