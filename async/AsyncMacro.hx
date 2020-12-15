package async;


#if macro
import sys.io.File;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;


class AsyncMacro {
  macro public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    for (field in fields) {
      var meta = field.meta;
      if (meta != null) {
        for (data in meta) {
          if (data.name == "async") {
            switch field.kind {
              case FFun(f):
                f.expr = addMarker(f.expr);
                switch (f.expr.expr) {
                  case EBlock(exprs):
                    "";
                  default:
                    continue;
                }
              default:
                throw "async can be applied only to function";
            }
          }
        }
      }
    }
    return fields;
  }

  public static function getPlatformFunctionBody(e: Expr) {
    return switch Context.definedValue("target.name") {
      case "js":
        macro @:pos(e.pos) {
          std.js.Syntax.code("%%asyncPlaceholder%%");
          ${e};
        };
      case "python":
        macro @:pos(e.pos) {
          std.python.Syntax.code("%%asyncPlaceholder%%");
          ${e};
        };
      default:
        e;
    }
  }

  public static function addMarker(e: Expr) {
		return switch e.expr {
      case EBlock(exprs):
        getPlatformFunctionBody(e);
      default:
        throw "Invalid expression";
		}
  }
}
#end
