Project is at very beginning. Nothing probably works.

There are other (and probably better) implementations of the async/await behaviour aroud for Haxe.
My implementation is mostly intended for personal/internal needs, because I need it to be available among multiple programming languages: JavaScript, Python and Java.

My current plans are to make the tools as stupid as possible and just add keywords `async` and `await` to the source code by providing appropriate `@async` and `@await` meta tags.  
The idea is that those keywords are going to be added only far JS and Python, while for java they are going to be completely ignored.

TODO:
0. Tests (when I have at least some logic to test)
1. Add `async` and `await` keywords from meta tags.
1.1. Check all necessary types: inline functions, arrow functions (?), probably errors if meta tags are not in appropriate spot
2. Add typing logic:  
2.1. When functon returinng `T` is marked with `@async` its return type converts to `Promise<T>`.  
2.2. When `@await` is applied to expression of type `Promuse<T>`, its type becomes `T`.  
2.3. Forbid to use `@await` inside syncronous functions (for the beggining it would be enough to ignore that meta tag).
3. Add async/await keywords depending on some flag for Python (for JS it is always turned on). 
4. Add linter (+ to CI with tests)

Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
