package hxasync;


#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import sys.io.File;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using hxasync.AsyncMacroUtils;



class AsyncMacro {
  public static var asyncPlaceholder = "%asyncPlaceholder%";

  macro public static function build(): Array<Field> {
    var targetName = Context.definedValue("target.name");
    if (Context.definedValue("sync") == "1") {
      trace("\"sync\" flag is set. Ignoring async/await keywords");
      return null;
    }
    if (!["python", "js", "cs"].contains(targetName)) {
      return null;
    }
    registerFinishCallback();
    var fields = Context.getBuildFields();
    for (field in fields) {
      var meta = field.meta;
      if (meta != null) {
        for (data in meta) {
          if (data.name == "async") {
            switch field.kind {
              case FFun(f):
                transformToAsync(f);
                handleAny(f.expr, true);
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
      case EIf(econd, eif, eelse):
        handleAny(econd, isAsyncContext);
        handleAny(eif, isAsyncContext);
        handleAny(eelse, isAsyncContext);
      case EBinop(op, e1, e2):
        handleAny(e1, isAsyncContext);
        handleAny(e2, isAsyncContext);
      case EThrow(e):
        handleAny(e, isAsyncContext);
      case ENew(t, params):
        for (param in params) {
          handleAny(param, isAsyncContext);
        }
      case EArrayDecl(values):
        for (val in values) {
          handleAny(val, isAsyncContext);
        }
      case EFor(it, expr):
        handleAny(it, isAsyncContext);
        handleAny(expr, isAsyncContext);
      case EArray(e1, e2):
        handleAny(e1, isAsyncContext);
        handleAny(e2, isAsyncContext);
      case EUnop(op, postFix, e):
        handleAny(e, isAsyncContext);
      case ESwitch(e, cases, edef):
        handleAny(e, isAsyncContext);
        for (cs in cases) {
          handleAny(cs.expr, isAsyncContext);
        }
        handleAny(edef, isAsyncContext);
      case ECast(e, t):
        handleAny(e, isAsyncContext);
      case EContinue:
        null;
      case ETernary(econd, eif, eelse):
        handleAny(econd, isAsyncContext);
        handleAny(eif, isAsyncContext);
        handleAny(eelse, isAsyncContext);
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

  public static function fixJavaScriptOutput(content: String): String {
    var regex = new EReg('${asyncPlaceholder};\\s*', "gm");
    // split code by placeholder first (and remove extra newline to keep a code pretty)
    var codeParts = regex.split(content);
    // -1 because we don't need to do any parsing to the last splitted result
    for (codeIndex in 0...(codeParts.length - 1)) {
      var codePart = codeParts[codeIndex];
      var splitPattern = "\n";
      var codeSubparts = (new EReg(splitPattern, "gm")).split(codePart);

      var functionRegex = new EReg("((function|\\w*)?\\s*\\([^()]*\\)\\s*\\{)", "");
      // From the regex point of view, expression
      // if(a == null) {
      // does not differ from function
      // someFunction(a == null) {
      // that's why I decided to look from the bottom-up to the first opening bracket without pair:
      // let funcWithDefaults = function(a) {
      //   if(a == null) {
      //     a = "asd";
      //   }
      // match it against function regex and add `async` keyword there
      // counter is to maintan count of open and closed brackets
      var counter = 0;
      for (subcodeIndex in 0...codeSubparts.length) {
        var line = codeSubparts[codeSubparts.length - subcodeIndex - 1];
        counter = counter + (AsyncMacroUtils.count(line, "}") - AsyncMacroUtils.count(line, "{"));
        if (counter < 0) {
          if (functionRegex.match(line)) {
            codeSubparts[codeSubparts.length - subcodeIndex - 1] = functionRegex.replace(line, "async $1");
            codeParts[codeIndex] = codeSubparts.join(splitPattern);
            break;
          }
        }
      }
    }
    return codeParts.join("");
  }

  public static function fixPythonOutput(content: String): String {
    var regex = new EReg('${asyncPlaceholder}\\s*', "gm");
    // split code by placeholder first (and remove extra newline to keep a code pretty)
    var codeParts = regex.split(content);
    // -1 because we don't need to do any parsing to the last splitted result
    for (codeIndex in 0...(codeParts.length - 1)) {
      var codePart = codeParts[codeIndex];
      // split evry part by lines and iterate from the last to first
      var splitPattern = "\n";
      var codeSubparts = (new EReg(splitPattern, "gm")).split(codePart);
      var functionRegex = new EReg("(def .*?\\(.*?\\):)", "");
      for (subcodeIndex in 0...codeSubparts.length) {
        var line = codeSubparts[codeSubparts.length - subcodeIndex - 1];
        if (functionRegex.match(line)) {
          codeSubparts[codeSubparts.length - subcodeIndex - 1] = functionRegex.replace(line, "async $1");
          codeParts[codeIndex] = codeSubparts.join(splitPattern);
          break;
        }
      }
    }
    return codeParts.join("");
  }


  public static function onFinishCallback() {
    var sourceCodePath = Compiler.getOutput();
    var target = Context.definedValue("target.name");
    var regex: EReg;
    var sourceCode = File.getContent(sourceCodePath);
    if (target == "js") {
      sourceCode = AsyncMacro.fixJavaScriptOutput(sourceCode);
    } else if (target == "python") {
      sourceCode = AsyncMacro.fixPythonOutput(sourceCode);
    }
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

  public static function getModifiedFunctionReturnType(ret: Null<ComplexType>): Null<ComplexType> {
    return null; // TODO: fix
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
                // if (s.name == "await") {
                //   exprs[exprs.length - 1] = {
                //     expr: EReturn({
                //       pos: lastFunctionExpr.pos,
                //       // expr: lastFunctionExpr.expr  // return last awaited expression
                //       expr: EReturn(macro @:pos(lastFunctionExpr.pos) return (null: hxasync.NoReturn))
                //     }),
                //     pos: lastFunctionExpr.pos
                //   };
                // }
                exprs.push({
                  expr: EReturn(macro @:pos(lastFunctionExpr.pos) return (null: hxasync.NoReturn)), // return Null
                  pos: lastFunctionExpr.pos
                });
              default:
                exprs.push({
                  expr: EReturn(macro @:pos(lastFunctionExpr.pos) return (null: hxasync.NoReturn)), // return Null
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
    fun.ret = getModifiedFunctionReturnType(fun.ret);
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
        e.expr = (macro hxasync.AsyncMacroUtils.await(${metaE})).expr;
      default:
        throw "Invalid expression";
    }
  }
}
#end
