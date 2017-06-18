#Include Object.ahk

; gosub TestHasProp
; gosub TestHasMethod
; gosub TestDefineProp
; gosub TestDefineMeth
; gosub TestClass
gosub TestSubClass
ExitApp

TestClass:
x := new TestClass
Test TestClass.smeth() "," TestClass.sprop
Test x.imeth() "," x.iprop
Test TestClass.HasMethod("smeth") TestClass.HasProperty("sprop")
Test TestClass.HasMethod("imeth") TestClass.HasProperty("iprop")
Test x.HasMethod("smeth") x.HasProperty("sprop")
Test x.HasMethod("imeth") x.HasProperty("iprop")
return
class TestClass extends Object {
    class _static {
        smeth() {
            return "static method"
        }
        sprop {
            get {
                return "static property"
            }
        }
    }
    imeth() {
        return "instance method"
    }
    iprop {
        get {
            return "instance property"
        }
    }
    static _ := MetaClass(TestClass)
}

TestSubClass:
Test TestSubClass.smeth()
x := new TestSubClass
Test x.imeth()
return
class TestSubClass extends TestClass {
    class _static {
        smeth() {
            return base.smeth() " (subclassed)"
        }
    }
    imeth() {
        return base.imeth() " (subclassed)"
    }
    static _ := MetaClass(TestSubClass)
}

TestDefineMeth:
x := new CDM, y := new CDM
x.name := "x", y.name := "y"
x.DefineMethod("meth", Func("Test_call"))
Test x.HasMethod("meth") (x.meth="") " " x.meth(1)
Test y.HasMethod("meth") CDM.HasMethod("meth")
CDM.DefineMethod("me2", Func("Test_call"))
Test x.HasMethod("me2") y.HasMethod("me2") CDM.HasMethod("me2")
Test CDM.me2(2)
CDM.Prototype.DefineMethod("me3", Func("Test_call"))
Test x.HasMethod("me3") y.HasMethod("me3") CDM.HasMethod("me3")
Test x.me3(3) " " y.me3(4)
CDM.Prototype.DefineProperty("meth", {get: Func("Test_get_method").Bind("meth")})
Test x.meth.Call(5) " " x.meth(6)
return
Test_call(this, arg:="") {
    return this.name ".called(" arg ")"
}
Test_get_method(name, this) {
    return ObjBindMethod(this, name)
}
class CDM extends Object {
    static _ := MetaClass(CDM)
}

TestDefineProp:
x := new CDP, y := new CDP
x.DefineProperty("pg", {get: Func("Test_get").Bind("pg")})
Test x.pg " " (x.pg := 100) " " x.pg
x.DefineProperty("pgs", {get: Func("Test_get").Bind("pgs"), set: Func("Test_set").Bind("pgs")})
Test x.pgs " " (x.pgs := 200) " " x.pgs
x.defineProperty("ps", {set: Func("Test_set").Bind("ps")})
Test x.ps " " (x.ps := 300) " " x.ps
Test y.pg
Test x.HasProperty("pg") y.HasProperty("pg") CDP.HasProperty("pg")
CDP.DefineProperty("sprop", {get: Func("Test_get").Bind("sprop")})
CDP.prototype.DefineProperty("iprop", {get: Func("Test_get").Bind("iprop")})
Test CDP.sprop "," CDP.HasProperty("sprop")
Test x.sprop "," x.HasProperty("sprop")
Test CDP.iprop "," CDP.HasProperty("iprop")
Test x.iprop "," y.iprop "," x.HasProperty("iprop")
return
Test_get(arg1, this) {
    return arg1 "(" this._[arg1] ")"
}
Test_set(arg1, this, value) {
    return arg1 " := " value
}
class CDP extends Object {
    static _ := MetaClass(CDP)
}

TestHasMethod:
Test Object.HasMethod('HasMethod') TestHasMethod.HasMethod('HasMethod')
x := new TestHasMethod
Test x.HasMethod('meth') TestHasMethod.HasMethod('meth')
x.adhocprop := 2
Test x.HasMethod('prop') x.HasMethod('initprop') x.HasMethod('adhocprop')
return
class TestHasMethod extends Object {
    meth() {
        MsgBox "meth"
    }
    prop {
        get {
            return 1
        }
    }
    initprop := 1
    static _ := MetaClass(TestHasMethod)
}

TestHasProp:
Test Object.HasProperty('HasProperty') Object.HasMethod('HasProperty')
Test TestHasProp.HasMethod('HasProperty')
Test TestHasProp.HasProperty('propget')
x := new TestHasProp
Test x.HasProperty('propget') x.HasProperty('propset') x.HasProperty('propgetset')
x.adhocprop := 2
Test x.HasProperty('initprop') x.HasProperty('adhocprop')
Test x.HasKey('initprop') x.HasKey('adhocprop')
Test ObjHasKey(x, 'initprop') ObjHasKey(x, 'adhocprop')
Test x.HasProperty('meth') x.HasProperty('noprop') x.HasProperty(1)
return
class TestHasProp extends Object {
    initprop := 1
    propget {
        get {
            return 10
        }
    }
    propset {
        set {
            D "propset := " value
            return 20
        }
    }
    propgetset {
        get {
            return 30
        }
        set {
            D "propgetset := " value
            return 40
        }
    }
    meth() {
        MsgBox "meth"
    }
    static _ := MetaClass(TestHasProp)
}

Test(v) {
    e := Exception('', -1)
    s := ''
    Loop Read, e.File {
        if A_Index = e.Line {
            s := A_LoopReadLine
            break
        }
    }
    D s ' => ' v
}