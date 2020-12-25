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
      var isAsyncContext = false;
      if (meta != null) {
        for (data in meta) {
          if (data.name == "async") {
            isAsyncContext = true;
            switch field.kind {
              case FFun(f):
                transformToAsync(f);
                handleAny(f.expr, isAsyncContext);
              default:
                throw "async can be applied only to a function field type";
            }
          }
        }
      }
    }
    return fields;
  }

  public static function handleEMeta(expr: Expr, isAsyncContext: Bool) {
    switch expr.expr {
      case EMeta(s, e):
        if (s.name == "await") {
          if (!isAsyncContext) {
            throw "await allowed only inside async function";
          }
          transformToAwait(expr);
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
        throw "Expr is not EMeta";
    }
  }

  public static function handleAny(expr: Expr, isAsyncContext: Bool) {
    // TODO: handle more Expr types
    if (expr == null) {
      return null;
    }
    return switch expr.expr {
      case EReturn(e):
        handleAny(e, isAsyncContext);
      case EMeta(s, e):
        handleEMeta(expr, isAsyncContext);
      case EBlock(exprs):
        for (expr in exprs) {
          handleAny(expr, isAsyncContext);
        }
      case ECall(e, params):
        handleAny(e, isAsyncContext);
      case EConst(s):
        null;
      case EField(e, field):
        handleAny(e, isAsyncContext);
      case EVars(vars):
        for (variable in vars) {
          handleAny(variable.expr, isAsyncContext);
        }
      case EFunction(kind, f):
        handleEFunction(f, kind, false);
      case EObjectDecl(fields):
        for (field in fields) {
          handleAny(field.expr, isAsyncContext);
        }
      case EParenthesis(e):
        handleAny(e, isAsyncContext);
      case ECheckType(e, t):
        handleAny(e, isAsyncContext);
      case null:
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
      default:
        null;
    }
    handleAny(fun.expr, isAsyncContext);
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

  public static function makeExplicitReturn(fun: Function) {
    switch fun.expr.expr {
      case EBlock(outerExprs):
        var lastExpr = outerExprs[outerExprs.length - 1];
        switch lastExpr.expr {
          case EBlock(exprs):
            var lastFunctionExpr = exprs[exprs.length - 1];
            switch lastFunctionExpr.expr {
              case EReturn(e):
                return;
              case EMeta(s, e):
                if (s.name == "await") {
                  exprs[exprs.length - 1] = {
                    expr: EReturn({
                      pos: lastFunctionExpr.pos,
                      expr: lastFunctionExpr.expr  // return last awaited expression
                    }),
                    pos: lastFunctionExpr.pos
                  };
                }
              default:
                exprs.push({
                  expr: EReturn(macro @:pos(lastFunctionExpr.pos) return (null: Dynamic)), // return Null
                  pos: lastFunctionExpr.pos
                });
            }
          default:
            null;
        }
      default:
        null;
    }
  }

  /**
   * Modifies function body (by adding asyncPlaceholder) and (in future) changes return type from T to Promise<T>
   * @param {Function} fun -- Function to modify
   */
  public static function transformToAsync(fun: Function) {
    fun.expr = getModifiedPlatformFunctionBody(fun.expr);
    makeExplicitReturn(fun);
  }

  public static function processAwaitedFuncArgs(expr: Expr) {
    switch expr.expr {
      case ECall(e, params):
        handleAny(e, false);
        for (param in params) {
          handleAny(param, false);
        }
      default:
        null;
    }
  }

  public static function transformToAwait(e: Expr) {
    switch (e.expr) {
      case EMeta(s, metaE):
        processAwaitedFuncArgs(metaE);
        e.expr = (macro AsyncMacroUtils.await(${metaE})).expr;
      default:
        throw "Invalid expression";
    }
  }
}
#end
