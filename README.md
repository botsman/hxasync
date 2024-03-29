# HXAsync

This library allows you to add `async` and `await` keywords in Python and JavaScript code almost the same way you would do it in the native code.  
Theoretically, support of C# could be added since Haxe 4.2 if there is such a demand.  

Used internally for my personal projects.  

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


## Usage

In order to start using this macros, you need to:  
1. Install the library: `haxelib install hxasync`  
2. Add the library to your project when compiling a project: `-lib hxasync`  
3. Do one of these to enable `async` and `await` feature for your class:  
   - use build or autobuild macros:  
   ```  
   @:build(hxasync.AsyncMacro.build())  
   class MyClass {}  
   ```  
   - implement `Asyncable` interface:     
   ```  
   class MyClass implements hxasync.Asyncable {}   
   ```  
   - apply AsyncMacro to all classes in a specified package:  
   `--macro hxasync.AsyncMacro.makeAsyncable("")`  

Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
