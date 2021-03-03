package hxasync;

import hxasync.Abstracts.Awaitable;

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

  #if macro
  public static inline function count(text: String, char: String): Int {
    var counter = 0;
    for (ch in text.split("")) {
      if (ch == char) {
        counter++;
      }
    }
    return counter;
  }
  #end
}
