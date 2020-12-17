package async;


class AsyncMacroUtils {
  // TODO: make it Promise<T> -> T
  public static extern inline function await<T>(arg: T): T {
    #if js
    return std.js.Syntax.code("await {0}", arg);
    #elseif python
    return std.python.Syntax.code("await {0}", arg);
    #else
    return arg;
    #end
  }
}
