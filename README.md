Project is at very beginning. Probably a lot of bugs.

TODO:
0. Tests (when I have at least some logic to test)
1. ~~Add `async` and `await` keywords from meta tags.~~  
2. Add typing logic:  
2.1. When functon returinng `T` is marked with `@async` its return type converts to `Promise<T>`.  
2.2. When `@await` is applied to expression of type `Promuse<T>`, its type becomes `T`.  
2.3. Forbid to use `@await` inside syncronous functions (for the beggining it would be enough to ignore that meta tag).
2.4. (?) Forbid to await non Promises
3. Add async/await keywords depending on some flag for Python (for JS it is always turned on). 
4. Add linter (+ to CI with tests)

Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
