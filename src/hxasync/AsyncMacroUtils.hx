package hxasync;


class AsyncMacroUtils {
  public static extern inline function await<T>(arg: Awaitable<T>): T {
    #if js
    return std.js.Syntax.code("await {0}", arg);
    #elseif python
    return std.python.Syntax.code("await {0}", arg);
    #else
    return cast arg;
    #end
  }
}
