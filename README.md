# HXAsync

Project is at very beginning. Probably a lot of bugs.

This library allows you to add `async` and `await` keywords in Python and JavaScript code almost the same way you would do it in the native code.

Example:  

Haxe source code

```haxe
@:build(hxasync.AsyncMacro.build())
class MyExample {
  public function new() { }

  @async public function myPromise() {
    return "something";
  }

  @async public function some() {
    return @await this.myPromise();
  }
}

@:build(hxasync.AsyncMacro.build())
class Main {
  @async public static function main() {
    var example = new MyExample();
    return @await example.some();
  }
}
```

Python output (some Haxe-generated output is omitted)
```python
class MyExample:
    __slots__ = ()

    def __init__(self):
        pass

    async def myPromise(self):
        return "something"

    async def some(self):
        return await self.myPromise()



class Main:
    __slots__ = ()

    @staticmethod
    async def main():
        example = MyExample()
        return await example.some()
```

JavaScript output (some Haxe-generated output is omitted)
```js
class MyExample {
	constructor() {
	}
	async myPromise() {
		return "something";
	}
	async some() {
		return await this.myPromise();
	}
}
class Main {
	static async main() {
		let example = new MyExample();
		return await example.some();
	}
}
```

Instead of using bare `async` and `await` keywords, I had to use Haxe meta-tags `@async` and `@await`.  
I tried to keep the implementation as close as possible to the native target platforms implementation.


Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
