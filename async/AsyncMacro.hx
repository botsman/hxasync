package async;


#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import sys.io.File;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;

using async.AsyncMacroUtils;


class AsyncMacro {
  public static var asyncPlaceholder = "%asyncPlaceholder%";

  macro public static function build(): Array<Field> {
    registerFinishCallback();
    var fields = Context.getBuildFields();
    for (field in fields) {
      var meta = field.meta;
      var asyncContext = false;
      if (meta != null) {
        for (data in meta) {
          if (data.name == "async") {
            asyncContext = true;
            switch field.kind {
              case FFun(f):
                transformToAsync(f);
                switch (f.expr.expr) {
                  case EBlock(exprs):
                    handleEBlock(exprs, asyncContext);
                  default:
                    continue;
                }
              default:
                throw "async can be applied only to a function field type";
            }
          }
        }
      }
    }
    return fields;
  }

  public static function handleEBlock(eBlockExprs: Array<Expr>, isAsyncContext: Bool) {
    for (expr in eBlockExprs) {
      switch (expr.expr) {
        case EBlock(exprs):
          handleEBlock(exprs, isAsyncContext);
        case EMeta(s, e):
          handleEMeta(expr, isAsyncContext);
        case EReturn(e):
          if (e == null) {
            continue;
          }
          switch (e.expr) {
            case EMeta(s, metaE):
              handleEMeta(e, isAsyncContext);
            default:
              "";
          }
        case EVars(vars):
          handleEVars(vars, isAsyncContext);
        case ECall(e, params):
          handleECall(e, params, isAsyncContext);
        default:
          continue;
      }
    }
  }

  public static function handleECall(e: Expr, params: Array<Expr>, isAsyncContext: Bool) {
  }

  public static function handleEVars(eVars: Array<Var>, isAsyncContext: Bool) {
    for (evar in eVars) {
      var expr = evar.expr;
      if (expr == null) {
        continue;
      }
      switch expr.expr {
        case EMeta(s, e):
          handleEMeta(expr, isAsyncContext);
        default:
          continue;
      }
    }
  }

  public static function handleEMeta(expr: Expr, isAsyncContext: Bool) {
    switch expr.expr {
      case EMeta(s, e):
        if (s.name == "await") {
          if (!isAsyncContext) {
            throw "await allowed only inside async function";
          }
          expr.expr = transformToAwait(expr);
        } else if (s.name == "async") {
          switch e.expr {
            case EFunction(kind, f):
              transformToAsync(f);
              handleEFunction(f, kind, true);
            default:
              throw "async only allowed to be used with functions";
          }
        } else {
          handleAny(e, isAsyncContext);
        }
      default:
        trace(expr);
        throw "Expr is not EMeta";
    }
  }

  public static function handleAny(expr: Expr, isAsyncContext: Bool) {
    // TODO: handle more Expr types
    return switch expr.expr {
      case EReturn(e):
        handleAny(e, isAsyncContext);
      case EMeta(s, e):
        handleEMeta(expr, isAsyncContext);  // TODO: fix 1st arg
      case EBlock(exprs):
        for (expr in exprs) {
          handleAny(expr, isAsyncContext);
        }
      case ECall(e, params):
        handleAny(e, isAsyncContext);
      case EConst(s):
        null;
      case other:
        throw 'Unexpected expression ${other}';
    }
  }

  public static function handleEFunction(fun: Function, kind: FunctionKind, isAsyncContext: Bool) {
    switch kind {
      case FNamed(name, inlined):
        if (inlined) {
          throw "Inline function can not be async";
        }
      default: "";
    }
    switch fun.expr.expr {
      case EBlock(exprs):
        handleEBlock(exprs, isAsyncContext);
      default:
        return;
    };
  }


  public static function onFinishCallback() {
    var sourceCodePath = Compiler.getOutput();
    var target = Context.definedValue("target.name");
    var regex: EReg;
    if (target == "js") {
      regex = new EReg('((function|\\w*)?\\s*\\([^()]*\\)\\s*\\{\\s*?)${asyncPlaceholder};\n\\s*', "gm");
    } else if (target == "python") {
      regex = new EReg('(def .*?\\(.*?\\):\\s*)${asyncPlaceholder}\n\\s*', "gm");
    }
    var sourceCode = File.getContent(sourceCodePath);
    sourceCode = regex.replace(sourceCode, "async $1");
    File.saveContent(sourceCodePath, sourceCode);
  }

  public static function registerFinishCallback() {
    Context.onAfterGenerate(onFinishCallback);
  }

  public static function getModifiedPlatformFunctionBody(e: Expr) {
    return switch Context.definedValue("target.name") {
      case "js":
        macro @:pos(e.pos) {
          std.js.Syntax.code("%asyncPlaceholder%");
          ${e};
        };
      case "python":
        macro @:pos(e.pos) {
          std.python.Syntax.code("%asyncPlaceholder%");
          ${e};
        };
      default:
        e;
    }
  }

  /**
   * Modifies function body (by adding asyncPlaceholder) and (in future) changes return type from T to Promise<T>
   * @param {Function} fun -- Function to modify
   */
  public static function transformToAsync(fun: Function) {
    fun.expr = getModifiedPlatformFunctionBody(fun.expr);
  }

  public static function transformToAwait(e: Expr) {
    return switch (e.expr) {
      case EMeta(s, metaE):
        (macro AsyncMacroUtils.await(${metaE})).expr;
      default:
        throw "Invalid expression";
    }
  }
}
#end
