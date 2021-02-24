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
  public static var callbackRegistered: Bool = false;
  public static var notificationSent: Bool = false;
  public static var asyncPlaceholder = "%asyncPlaceholder%";
  public static var noReturnPlaceholder = "%noReturnPlaceholder%";

  macro public static function build(): Array<Field> {
    var targetName = Context.definedValue("target.name");
    if (isSync()) {
      return null;
    }
    if (!["python", "js"].contains(targetName)) {
      return null;
    }
    registerFinishCallback();
    var fields = Context.getBuildFields();
    for (field in fields) {
      var meta = field.meta;
      var asyncContext = false;
      for (data in meta) {
        if (data.name == "async") {
          asyncContext = true;
          break;
        }
      }
      switch field.kind {
        case FFun(f):
          if (asyncContext) {
            transformToAsync(f);
          }
          handleAny(f.expr, asyncContext);
        default:
          if (asyncContext) {
            Context.error("async can be applied only to a function field type", field.pos);
          }
      }
    }
    return fields;
  }

  static function makeAsyncable(pathFilter: String) {
    Compiler.addGlobalMetadata(pathFilter, "@:build(hxasync.AsyncMacro.build())");
  }

  public static function isSync(): Bool {
    if (Context.definedValue("sync") == "1") {
      if (!notificationSent) {
        trace("\"sync\" flag is set. Ignoring async/await keywords");
      }
      notificationSent = true;
      return true;
    }
    return false;
  }

  public static inline function handleEMeta(expr: Expr, isAsyncContext: Bool) {
    switch expr.expr {
      case EMeta(s, e):
        if (s.name == "await") {
          if (!isAsyncContext) {
            Context.error("await allowed only inside async function", e.pos);
          }
          transformToAwait(expr);
        } else if (s.name == "async") {
          switch e.expr {
            case EFunction(kind, f):
              transformToAsync(f);
              handleEFunction(f, kind, true, e.pos);
            default:
              Context.error("async only allowed to be used with functions", e.pos);
          }
        } else {
          handleAny(e, isAsyncContext);
        }
      default:
        Context.error("Expr is not EMeta", expr.pos);
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
        handleEFunction(f, kind, false, expr.pos);
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
      case EUntyped(e):
        handleAny(e, isAsyncContext);
      case ETry(e, catches):
        handleAny(e, isAsyncContext);
        for (ctch in catches) {
          handleAny(ctch.expr, isAsyncContext);
        }
      case EWhile(econd, e, normalWhile):
        handleAny(econd, isAsyncContext);
        handleAny(e, isAsyncContext);
      case EBreak:
        null;
      case null:
        null;
      case other:
        Context.error('Unexpected expression ${other}', expr.pos);
        null;
    }
  }

  public static function handleEFunction(
      fun: Function,
      kind: FunctionKind,
      isAsyncContext: Bool,
      pos: Position
  ) {
    if (isAsyncContext) {
      switch kind {
        case FNamed(name, inlined):
          if (inlined) {
            if (fun.expr != null) {
              Context.error("Inline function can not be async", fun.expr.pos);
            }
            Context.error("Inline function can not be async", pos);
          }
        default:
          null;
      }
    }
    handleAny(fun.expr, isAsyncContext);
  }

  public static function makeJSAsyncFunctions(content: String): String {
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
        var line = codeSubparts[
          codeSubparts.length - subcodeIndex - 1
        ];
        counter = counter + (AsyncMacroUtils.count(line, "}") - AsyncMacroUtils.count(line, "{"));
        if (counter < 0) {
          if (functionRegex.match(line)) {
            codeSubparts[
              codeSubparts.length - subcodeIndex - 1
            ] = functionRegex.replace(line, "async $1");
            codeParts[codeIndex] = codeSubparts.join(splitPattern);
            break;
          }
        }
      }
    }
    return codeParts.join("");
  }

  public static function deleteJSEmptyReturn(content: String): String {
    var emptyReturnRegex = new EReg('\\s*return ${AsyncMacro.noReturnPlaceholder};', "gm");
    return emptyReturnRegex.replace(content, "");
  }

  public static function fixJSOutput(content: String): String {
    content = makeJSAsyncFunctions(content);
    content = deleteJSEmptyReturn(content);
    return content;
  }

  public static function makePythonAsyncFunctions(content: String): String {
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
        var line = codeSubparts[
          codeSubparts.length - subcodeIndex - 1
        ];
        if (functionRegex.match(line)) {
          codeSubparts[
            codeSubparts.length - subcodeIndex - 1
          ] = functionRegex.replace(line, "async $1");
          codeParts[codeIndex] = codeSubparts.join(splitPattern);
          break;
        }
      }
    }
    return codeParts.join("");
  }

  public static function deletePythonEmptyReturn(content: String): String {
    var emptyReturnRegex = new EReg('\\s*return ${AsyncMacro.noReturnPlaceholder}', "gm");
    return emptyReturnRegex.replace(content, "");
  }

  public static function fixPythonOutput(content: String): String {
    content = makePythonAsyncFunctions(content);
    content = deletePythonEmptyReturn(content);
    return content;
  }

  public static function onFinishCallback() {
    var sourceCodePath = Compiler.getOutput();
    var target = Context.definedValue("target.name");
    var regex: EReg;
    var sourceCode = File.getContent(sourceCodePath);
    if (target == "js") {
      sourceCode = AsyncMacro.fixJSOutput(sourceCode);
    } else if (target == "python") {
      sourceCode = AsyncMacro.fixPythonOutput(sourceCode);
    }
    File.saveContent(sourceCodePath, sourceCode);
  }

  public static function registerFinishCallback() {
    if (callbackRegistered) {
      return;
    }
    callbackRegistered = true;
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

  private static function getPythonEmptyReturn(expr: Expr): Expr {
    return {
      expr: EReturn(
        macro @:pos(expr.pos) return (std.python.Syntax.code("%noReturnPlaceholder%"))
      ),
      pos: expr.pos
    };
  }

  private static function getJSEmptyReturn(expr: Expr): Expr {
    return {
      expr: EReturn(
        macro @:pos(expr.pos) return (std.js.Syntax.code("%noReturnPlaceholder%"))
      ),
      pos: expr.pos
    };
  }

  public static function getEmptyReturn(expr: Expr): Expr {
    return switch Context.definedValue("target.name") {
      case "js":
        getJSEmptyReturn(expr);
      case "python":
        getPythonEmptyReturn(expr);
      default:
        expr;
    }
  }

  public static function makeExplicitReturn(fun: Function) {
    switch fun.expr.expr {
      case EBlock(outerExprs):
        var lastExpr = outerExprs[outerExprs.length - 1];
        switch lastExpr.expr {
          case EBlock(exprs):
            var lastFunctionExpr = exprs[exprs.length - 1];
            if (lastFunctionExpr == null) {
              exprs.push(getEmptyReturn(lastExpr));
              return;
            }
            switch lastFunctionExpr.expr {
              case EReturn(e):
                return;
              case EMeta(s, e):
                exprs.push(getEmptyReturn(lastFunctionExpr));
              default:
                exprs.push(getEmptyReturn(lastFunctionExpr));
            }
          case EMeta(s, e):
            if (s.name != ":implicitReturn") {
              return;
            }
            switch e.expr {
              case EReturn(e):
                switch e.expr {
                  case EBlock(exprs):
                    var lastFunctionExpr = exprs[exprs.length - 1];
                    exprs.push(getEmptyReturn(lastFunctionExpr));
                  default:
                    null;
                }
              default:
                null;
            }
          default:
            null;
        }
      default:
        null;
    }
  }

  public static function inferReturnType(fun: Function): Null<ComplexType> {
    if (fun.ret != null) {
      return fun.ret;
    }
    var complexType =
    try {
      var typed = Context.typeExpr({expr: EFunction(null, fun), pos:fun.expr.pos});
      typed.t.followWithAbstracts().toComplexType();
    } catch (e) {
      Context.error("Failed to infer return type", fun.expr.pos);
      throw e;
    };

    return switch complexType {
      case TFunction(args, ret):
        ret;
      default:
        null;
    }
  }

  public static function getModifiedFunctionReturnType(fun: Function) {
    var returnType = inferReturnType(fun);
    return switch returnType {
      case null:
        Context.error("Unable to identify function return type", fun.expr.pos);
      // TPath({name: StdTypes, params: [], sub: Void, pos: #pos((unknown)), pack: []})
      case TPath({name: "StdTypes", sub: "Void"}):
        // Awaitable<NoReturn>;
        trace("Void");
      // TPath({name: String, params: [], pos: #pos((unknown)), pack: []})
      case TPath(p):
        // Awaitable<T>
        trace("TPATH");
      default:
        null;
    }
  }

  /**
   * Modifies function body (by adding asyncPlaceholder) and (in future) changes return type from T to Promise<T>
   * @param {Function} fun -- Function to modify
   */
  public static function transformToAsync(fun: Function) {
    // var a = returnType;
    getModifiedFunctionReturnType(fun);
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
        e.expr = (macro hxasync.AsyncMacroUtils.await(${metaE})).expr;
      default:
        Context.error("Invalid expression", e.pos);
    }
  }
}
#end
