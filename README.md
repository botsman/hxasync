# HXAsync

Project is at very beginning. Probably a lot of bugs.

This library allows you to add `async` and `await` keywords in Python and JavaScript code almost the same way you would do it in the native code.

Example:

```
@:build(hxasync.AsyncMacro.build())
class Main {
    @async public static function some() {
        return @await somePromise;
    }

    @async public static function another() {
        return @await Main.some()
    }
}
```

Instead of using bare `async` and `await` keywords, I had to use Haxe meta-tags `@async` and `@await`.  
I tried to keep the implementation as close as possible to the native target platforms implementation.


Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
