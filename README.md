Project is at very beginning. Probably a lot of bugs.

TODO:  
0. Tests (when I have at least some logic to test)
1. Add typing logic (probably it should be abstarct to be used only at compile time and not at runtime):  
1.1. When functon returinng `T` is marked with `@async` its return type converts to `Awaitable<T>`.  
1.2. When `@await` is applied to expression of type `Awaitable<T>`, its type becomes `T`.  
1.3. Forbid to use `@await` inside syncronous functions (for the beggining it would be enough to ignore that meta tag).  
1.4. Forbid to await non Awaitables
2. Add linter (+ to CI with tests)

Project is inspired by [hx-jsasync](https://github.com/basro/hx-jsasync) library.  
