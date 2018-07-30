
#Include Object.ahk
#Include <Yunit\Yunit>
#Include <Yunit\Stdout>

Yunit.Use(YunitStdout).Test(Tests)

A(p*) => Yunit.Assert(p*)

MustThrow(f, p*) {
    try f.call()
    catch
        return
    Yunit.Assert(false, p*)
}

class Tests
{
    class Object
    {
        HasProperty()
        {
            A  !Object.HasProperty('HasProperty') && Object.HasMethod('HasProperty')
            
            A  TestClass1.HasMethod('HasProperty')
            A  TestClass1.HasProperty('readonlyprop') = false
            && TestClass1.HasProperty('writeonlyprop') = false
            && TestClass1.HasProperty('readwriteprop') = false
            , "Instance property present in static context"
            A  TestClass1.HasProperty('method') = false
            A  TestClass1.HasProperty('nonextant') = false
            
            x := new TestClass1
            A  x.HasProperty('readonlyprop')
            && x.HasProperty('writeonlyprop')
            && x.HasProperty('readwriteprop'), "Instance members missing"
            
            x.adhocprop := 2
            A  x.HasProperty('initprop'), "Declared var missing"
            A  x.HasProperty('adhocprop'), "Undeclared var missing"
            
            A  x.HasProperty('nonextant') = false
            && x.HasProperty('meth') = false
            && x.HasProperty(1) = false
            , "Method seen as property"
        }
        
        HasKey()
        {
            x := new TestClass1
            A  x.HasKey('initprop')
            A  !x.HasKey('adhocprop')
            x.adhocprop := 2
            A  x.HasKey('adhocprop')
        }
        
        HasMethod()
        {
            A  TestClass1.HasMethod('HasMethod')
            A  TestClass1.HasMethod('static_method'), "Static method missing"
            A  TestClass1.HasMethod('method') = false, "Instance method present in static context"
            
            x := new TestClass1
            A  x.HasMethod('HasMethod')
            A  x.HasMethod('method'), "Instance method missing"
            A  x.HasMethod('static_method') = false, "Static method present in instance context"
            
            x.adhocprop := Func("NullFunc")
            A  x.HasMethod('readonlyprop') = false
            && x.HasMethod('initprop') = false
            && x.HasMethod('adhocprop') = false
            , "Property seen as method"
        }
        
        GetMethod()
        {
            f := TestClass1.GetMethod("static_method")
            A  type(f) = "Func"
            A  f.call(TestClass1) = "=static_method()"
            
            x := new TestClass1
            f := x.GetMethod("method")
            A  type(f) = "Func"
            A  f.call(x) = "=method()"
            
            x := new Object
            x.DefineMethod("meth1", Func("NullFunc"))
            A  x.GetMethod("meth1") = Func("NullFunc")
        }
        
        DefineProperty()
        {
            x := new TestClassDP, y := new TestClassDP
            x.DefineProperty("pg", {get: Func("Test_get").Bind("pg")})
            x.DefineProperty("pgs", {get: Func("Test_get").Bind("pgs"), set: Func("Test_set").Bind("pgs")})
            x.DefineProperty("ps", {set: Func("Test_set").Bind("ps")})
            
            A  x.pg = "pg()"
            A  (x.pg := 100) = 100  ; Default behaviour: store and return 100
            A  x.pg = "pg(100)", "Property-get broken by assignment"
            A  x.pgs = "pgs()"
            A  (x.pgs := 200) = "pgs := 200"
            A  x.pgs = "pgs(200)"
            A  x.ps = ""
            A  (x.ps := 300) = "ps := 300"
            A  x.ps = 300
            A  y.pg = ""
            
            A  x.HasProperty("pg")
            A  y.HasProperty("pg") = false
            A  TestClassDP.HasProperty("pg") = false
            
            TestClassDP.DefineProperty("static1", {get: Func("Test_get").Bind("static1")})
            A  TestClassDP.HasProperty("static1")
            A  TestClassDP.static1 = "static1()"
            A  x.HasProperty("static1") = false
            A  (x.static1 = "static1()") = false
            
            TestClassDP.prototype.DefineProperty("inst1", {get: Func("Test_get").Bind("inst1")})
            A  x.HasProperty("inst1")
            A  (x.inst1 = "inst1()")
            A  TestClassDP.HasProperty("inst1") = false
            A  (TestClassDP.inst1 = "inst1()") = false
            
            Test_get(arg1, this) {
                ; FIXME: Create a "public" method to retrieve property data;
                ;        or should property data and accessors be mutually exclusive?
                return arg1 "(" this.←[arg1] ")"
            }
            Test_set(arg1, this, value) {
                ; FIXME: As above.
                this.←[arg1] := value
                return arg1 " := " value
            }
        }
        
        DefineMethod()
        {
            x := new TestClassDM, y := new TestClassDM
            x.name := "x", y.name := "y"
            x.DefineMethod("meth", Func("Test_call"))
            A  x.HasMethod("meth")
            A  x.HasProperty("meth") = false && x.meth = ""
            A  y.HasMethod("meth") = false && TestClassDM.HasMethod("meth") = false
            A  x.meth(1) = "x.called(1)"
            
            TestClassDM.DefineMethod("me2", Func("Test_call"))
            A  TestClassDM.HasMethod("me2")
            A  x.HasMethod("me2") = false && y.HasMethod("me2") = false
            A  TestClassDM.me2(2) = ".called(2)"
            
            TestClassDM.Prototype.DefineMethod("me3", Func("Test_call"))
            A  x.HasMethod("me3") && y.HasMethod("me3")
            A  TestClassDM.HasMethod("me3") = false
            A  x.me3(3) = "x.called(3)" && y.me3(4) = "y.called(4)"
            
            Test_call(this, arg:="") {
                return this.name ".called(" arg ")"
            }
        }
        
        BaseProperty()
        {
            A  ({}.base = Object)
            A  ([].base = Array)
            A  (new Object).base = Object
            A  (new TestClass1).base = TestClass1
            A  TestClass1.base = Object
            
            MustThrow(() => TestClass1.base := 1, "Class.base assignment did not throw")
        }
        
        Is()
        {
            x := new Object, y := new Object
            A  x.is(Object)
            A  Object.is(Object)
            A  x.is('object')
            A  x.is(y) = false
            A  (new TestClass2).is(TestClass2)
            A  (new TestClass2).is(Object)
            A  TestClass2.is(Object)
            A  TestSubClass.is(TestClass2) = false  ; Not an instance of.
            A  TestClass2.is(Class) && not (new TestClass2).is(Class)
            A  (1).is('integer') && (0.1).is('float') && 'abc'.is('alnum')
            A  'xyz'.is('xdigit') = false
        }
    }
    
    class Classes
    {
        Subclass()
        {
            A  TestClass2.meth() = "static method"
            A  TestClass2.prop = "static property"
            
            ; No "static x" because static members are not inherited:
            A  TestSubClass.meth() = " (subclassed)"
            A  TestSubClass.prop = " (subclassed)"
            A  TestSubSubClass.meth() = " (subsubclassed)"
            A  TestSubSubClass.prop = " (subsubclassed)"
            
            A  (new TestClass2).meth() = "instance method"
            A  (new TestClass2).prop = "instance property"
            A  (new TestSubClass).meth() = "instance method (subclassed)"
            A  (new TestSubClass).prop = "instance property (subclassed)"
            A  (new TestSubSubClass).meth() = "instance method (subsubclassed)"
            A  (new TestSubSubClass).prop = "instance property (subsubclassed)"
        }
        
        StaticVar()
        {
            A  TestInit.one = 1
            A  TestInit.two = 2
            A  TestInit.three = 3
            A  TestInit.HasProperty("one")
            A  ObjHasKey(TestInit, "one") = false
        }
        
        InstanceVar()
        {
            x := new TestInit
            A  x.dot = "."
            A  x.ellipsis = "..."
            A  x.HasProperty("dot")
            A  ObjHasKey(x, "dot") = false
        }
    }
    
    class Operators
    {
        New()
        {
            x := new TestNew1
            A  x.x = '__init1' && x.y = '__new1'
            x := new TestNew2
            A  x.x = '__init1' && x.y = '__new1'
            A  x.a = '__init2' && x.b = '__new2'
            MustThrow(() => TestNew1.__init())
            MustThrow(() => TestNew1.__new())
            A  TestNew1.x = '' && TestNew1.y = ''
        }
        
        Is()
        {
            x := new Object, y := new Object
            A  (x is Object)
            A  (x is 'object')
            A  (x is y) = false
            A  (new TestClass2) is TestClass2
            A  (new TestClass2) is Object
            A  (TestClass2 is Object)
        }
    }
    
    class JSON
    {
        SquareBrackets()
        {
            x := [10, 20,, 40]
            A  x.is(Array) && x.is(Object)
            A  x._[1] = 10 && x._[2] = 20 && x._[3] = "" && x._[4] = 40
            A  x._[-1] = 40 && x._[-3] = 20
            A  x.HasProperty('Length')
            A  x.HasMethod('Length') = false && x.HasMethod('MaxIndex') = false
            A  x.Length = 4
            ; Array currently conflates properties and array elements:
            A  x.HasKey(1) && !x.HasKey(3)
            A  x.HasProperty(1) && !x.HasProperty(3)
        }
        
        CurlyBraces()
        {
            x := {a: 1, b: 2}
            A  x.is(Object)
            A  x.is(Array) = false
            A  x.HasProperty('a')
            A  x.a = 1 && x.b = 2
            A  x.HasProperty('c') = false && x.c = ''
        }
        
        SetBase()
        {
            x := {a: 1}
            y := {b: 2, base: x}
            A  ObjGetBase(y.←) != x
            A  ObjGetBase(y) = x
            A  y.base = x
        }
    }
    
    class Array
    {
        Indexing()
        {
            x := ['A','B','C']
            A  x[1] = 'A' && x[2] = 'B' && x[3] = 'C'
            A  x[-1] = 'C' && x[-2] = 'B' && x[-3] = 'A'
            A  x[-4] = '' && x[0] = ''
            A  (x[0] := 'D') = 'D'
            A  x[-1] = 'D' && x[4] = 'D' && x.length = 4
            A  (x[-2] := 'c') == 'c' && x[3] == 'c'
        }
        
        Length()
        {
            A  ['A','B','C'].length = 3
            A  ['A', ,'B', ,'C'].length = 5
            x := ['A','B','C']
            A  (x.Length := 2) = 2
            A  x.HasKey(3) = false && x.Length = 2 && x[3] = ""
            A  (x.Length := 4) = 4
            A  x.HasKey(4) = false && x.Length = 4 && x[4] = ""
            x.Push('D')
            A  x[4] = "" && x[5] = "D" && x.Length = 5
            A  x.RemoveAt(5) = "D" && x.Length = 4
            A  x.RemoveAt(10) = "" && x.Length = 4
            x.InsertAt(10, "X")
            A  x[10] = "X" && x.Length = 10
        }
        
        Enumeration()
        {
            x := [10, 20,, 40]
            x.prop := 42
            
            s := ''
            for v in x
                s .= ' ' A_Index ':' v
            A  s = ' 1:10 2:20 3: 4:40'
            
            s := ''
            for k, v in x
                s .= ' ' k ':' v
            A  s = ' 1:10 2:20 4:40 prop:42'
            
            x.RemoveAt(2, 2), x.length := 4
            s := ''
            for v in x
                s .= ' ' A_Index ':' v
            A  s = ' 1:10 2:40 3: 4:'
            
            s := ''
            for k, v in x
                s .= ' ' k ':' v
            A  s = ' 1:10 2:40 length:4 prop:42'
        }
    }
    
    Map()
    {
        m := new Map
        A  m.set('abc', 11) = 11
        A  m.get('abc') = 11
        A  m.Count = 1
        A  m.set('ABC', 33) = 33
        A  m.get('ABC') = 33
        A  m.get('abc') = 11
        A  m.Count = 2
        m.set('xyz', 'str')
        A  m.Count = 3
    }
    
    class Limitations
    {
        ; These test the expected results rather than the desired ones.
        IsOperator()
        {
            ; Object not derived from self.
            A  (Object is Object) = false
            ; Must be true for `(new TestSubClass) is TestClass2` to work:
            A  (TestSubClass is TestClass2)
            ; `TestClass2 is Class` and `(new TestClass2) is TestClass2` cannot both be
            ; true unless `(new TestClass2) is Class` is also true, making it pointless.
            A  (TestClass2 is Class) = false
            A  ((new TestClass2) is Class) = false
        }
        
        StaticVar()
        {
            ; `this` in __init context refers to property data, not the class.
            A  TestInit.four != "Class"
        }
        
        InstanceVar()
        {
            x := new TestInit
            ; `this` in __init context refers to property data, not the instance.
            A  x.typename != "TestInit"
        }
    }
    
    class Internal
    {
        Object_v()
        {
            x := Object_v()
            A  Type(x) = "Object"
            A  ObjGetCapacity(x) = 0
        }
        
        ObjCount()
        {
            x := Object_v()
            A  ObjCount(x) = 0
            x.a := 1, x.b := 2
            A  ObjCount(x) = 2
            ObjDelete(x, 'a')
            A  ObjCount(x) = 1
        }
        
        ObjectFromPtr()
        {
            x := Object_v()
            A  Object(&x) = x
        }
    }
}

; =====================================================================

class TestClass1 extends Object {
    class _instance {
        initprop := "xx"
        readonlyprop {
            get {
                return 10
            }
        }
        writeonlyprop {
            set {
                return "=write1(" value ")"
            }
        }
        readwriteprop {
            get {
                return 20
            }
            set {
                return "=write2(" value ")"
            }
        }
        method() {
            return "=method()"
        }
    }
    class _static {
        static_method() {
            return "=static_method()"
        }
    }
}

class TestClassDP extends Object {
}

class TestClassDM extends Object {
}

class TestClass2 extends Object {
    class _static {
        meth() {
            return "static method"
        }
        prop {
            get {
                return "static property"
            }
        }
    }
    class _instance {
        meth() {
            return "instance method"
        }
        prop {
            get {
                return "instance property"
            }
        }
    }
}
class TestSubClass extends TestClass2 {
    class _static {
        meth() {
            return base.meth() " (subclassed)"
        }
        prop {
            get {
                return base.prop " (subclassed)"
            }
        }
    }
    class _instance {
        meth() {
            return base.meth() " (subclassed)"
        }
        prop {
            get {
                return base.prop " (subclassed)"
            }
        }
    }
}
class TestSubClass2 extends TestClass2 {
    ; Intentionally empty (no _static/_instance).
}
class TestSubSubClass extends TestSubClass2 {
    class _static {
        meth() {
            return base.meth() " (subsubclassed)"
        }
        prop {
            get {
                return base.prop " (subsubclassed)"
            }
        }
    }
    class _instance {
        meth() {
            return base.meth() " (subsubclassed)"
        }
        prop {
            get {
                return base.prop " (subsubclassed)"
            }
        }
    }
}

class TestNew1 extends Object {
    class _instance {
        x := "__init1"
        __new() {
            this.y := "__new1"
        }
    }
}
class TestNew2 extends TestNew1 {
    class _instance {
        a := "__init2"
        __new() {
            base.__new()
            this.b := "__new2"
        }
    }
}

class TestInit extends Object {
    class _static {
        one := 1
        two := this.one + 1
        three := TestInit.two + 1
        four := type(this)
    }
    class _instance {
        dot := "."
        ellipsis := this.dot this.dot this.dot
        typename := type(this)
    }
}

NullFunc(p*) {
}