#Include Object.ahk

; gosub TestHasProp
gosub TestHasMethod
ExitApp

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