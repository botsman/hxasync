package async;



@:build(async.AsyncMacro.build())
class MyClass {
  @async public static function some() {
    return "some func called";
  }

  @async public static function hiFunc() {
    return @await some();
  }
}

class Main {
  @async static public function main(): Void {
    @await MyClass.hiFunc();
  }
}

// import jsasync.IJSAsync;
// import jsasync.JSAsyncTools.jsawait;

// using jsasync.JSAsyncTools;


// class MyClass implements IJSAsync {
//   @:jsasync public static function hi() {
//     return "hi";
//   }
// }

// class Main {
//   static public function main():Void {
//     jsawait(MyClass.hi());
//   }
// }
