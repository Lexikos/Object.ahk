
#Include Object.ahk
#Include Object.Override.ahk
#Include <Yunit\Yunit>

Yunit.Use(SciTEStdout).Test(Tests)

A(p*) => Yunit.Assert(p*)

MustThrow(f, p*) {
    try f.call()
    catch
        return
    Yunit.Assert(false, p*)
}

class SciTEStdOut
{
    Update(Category, Test, Result) {
        if IsObject(Result) {
            ; Print error on a separate line in a format the SciTE error
            ; list recognizes (for highlight and double-click navigation).
            Details := "`n" StrReplace(Result.File, A_InitialWorkingDir "\")
                . " (" Result.Line ") : " Result.Message
            Status := "FAIL"
        } else {
            Details := ""
            Status := "PASS"
        }
        FileAppend Status ": " Category "." Test " " Details "`n", "*"
    }
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
        
        HasOwnProperty()
        {
            x := new TestClass1
            A  x.HasOwnProperty('initprop')
            A  x.HasOwnProperty('adhocprop') = false
            x.adhocprop := 2
            A  x.HasOwnProperty('adhocprop')
            y := new x
            y.DefineProperty('xxx', {get: () => 10})
            A  y.xxx = 10 && y.HasOwnProperty('xxx')
            A  y.HasProperty('adhocprop') = true
            A  y.HasOwnProperty('adhocprop') = false
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
            MustThrow(() => x.pg := 100)
            A  x.pg = "pg()"
            A  x.pgs = "pgs()"
            A  (x.pgs := 200) = "pgs := 200"
            A  x.pgs = "pgs(200)"
            A  x.ps = ""
            A  (x.ps := 300) = "ps := 300"
            A  x.ps = ""
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
            
            x := new Object
            x.DefineProperty("p", {get: Func("Test_get").Bind("p")})
            x.DefineProperty("p", {set: Func("Test_set").Bind("p")})
            A  x.p = "p()"
            A  (x.p := 123) = "p := 123"
            
            Test_get(arg1, this) {
                return arg1 "(" this["_" arg1] ")"
            }
            Test_set(arg1, this, value) {
                this["_" arg1] := value
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
            A  ({}.base = Object.prototype)
            A  ([].base = Array.prototype)
            A  (new Object).base = Object.prototype
            A  (new TestClass1).base = TestClass1.prototype
            A  TestClass1.base = Class.prototype
            
            MustThrow(() => TestClass1.base := 1, "Class.base assignment did not throw")
        }
        
        Enumeration()
        {
            EnumPropPairs(x) {
                s := ''
                e := x.Properties()
                while %e%(k, v)
                    s .= ' ' k ':' v
                return s
            }
            
            EnumPropKeys(x) {
                s := ''
                e := x.Properties()
                while %e%(k)
                    s .= ' ' k
                return s
            }
            
            x := {one: 1, two: 2, three: 3}
            s := EnumPropPairs(x)
            A  s = ' one:1 three:3 two:2'
            
            x.DefineProperty('four', {get: () => 4})
            s := EnumPropPairs(x)
            A  s = ' four:4 one:1 three:3 two:2'
            
            x := {}
            called := false
            x.DefineProperty('five', {get: () => called := true})
            ; Properties are not called if enumerator receives only one parameter.
            s := EnumPropKeys(x)
            A  s = ' five' && not called
            s := EnumPropPairs(x)
            A  s = ' five:1' && called
        }
    }
    
    class Prototype
    {
        BaseProperty()
        {
            x := {a: 1}
            y := {}
            y.base := x
            A  y.base = x
            A  y.a = 1
            A  y is x
            y.base := {b: 2}
            A  y.base != x
            A  y.b = 2
            A  y.a = ""
        }
        
        InheritDataProp()
        {
            x := {a: 1}
            y := new x
            A  y.a = 1
            A  y.HasProperty('a')
            A  y.HasOwnProperty('a') = false
        }
        
        DataOverrideProp()
        {
            x := new Object
            x.DefineProperty('p', {get: () => 'fail'})
            y := new Object
            y.p := 'pass'
            y.base := x
            A  y is x
            A  y.p = 'pass'
        }
        
        OverrideDataProp()
        {
            x := new Object
            x.p := 'fail'
            y := new Object
            y.DefineProperty('p', {get: () => 'pass'})
            y.base := x
            A  y is x
            A  y.p = 'pass'
        }
        
        Meta()
        {
            x := new Object
            y := new Object
            x.DefineMethod('__getprop', (this, name) => y[name])
            x.DefineMethod('__setprop', (this, name, value) => y[name] := value)
            x.DefineMethod('__call', (this, name, args) => name '(' ObjLength(args) ')')
            y.one := 1
            A  x.one = 1
            x.foo := 'bar'
            A  x.foo = 'bar'
            A  y.foo = 'bar'
            A  x.hello() = 'hello(0)'
            
            ; Unlike v1, inherited property takes precedence.
            x := new Object
            y := new x
            y.DefineMethod('__getprop', () => 'called')
            A  y.foo = 'called'
            A  x.foo := 'bar'
            A  y.foo = 'bar'
        }
        
        PropIndex()
        {
            ; Test handling of index args with variadic property.
            x := new Object
            x.DefineProperty('pv', {
                get: (this, args*) => 'get ' ObjLength(args),
                set: (this, value, args*) => 'set ' ObjLength(args) ' = ' value})
            A  (x.pv) = 'get 0'
            A  (x.pv['a']) = 'get 1'
            A  (x.pv['a','b']) = 'get 2'
            A  (x.pv := 'x') = 'set 0 = x'
            A  (x.pv['a'] := 'y') = 'set 1 = y'
            A  (x.pv['a','b'] := 'z') = 'set 2 = z'
            
            ; Test handling of index with single standard arg.
            x.DefineProperty('p1', {
                get: (this, arg) => 'get ' arg,
                set: (this, value, arg) => 'set ' arg ' = ' value})
            MustThrow(() => x.p1)
            A  (x.p1['a']) = 'get a'
            A  (x.p1['a','b']) = 'get a'
            A  (x.p1['a'] := 'x') = 'set a = x'
            A  (x.p1['a','b'] := 'y') = 'set a = y'
            
            ; Test automatic application of [index] to the result of a
            ; property when the property does not accept index args.
            y := ''
            x.DefineProperty('p0', {
                get: (this) => y,
                set: (this, value) => y := value})
            A  (x.p0) = ''
            MustThrow(() => x.p0[1])
            A  (x.p0 := []) is Array.prototype
            A  (x.p0) is Array.prototype
            A  (x.p0[1] := 'x') = 'x'
            A  (x.p0[1]) = 'x'
            A  y[1] = 'x' && y.Length = 1 && x.p0 = y
        }
        
        PropIndexMeta()
        {
            ; Test handling of index args.
            x := new Object
            x.DefineMethod('__getprop'
                , (this, name, args) => 'get ' name ' ' ObjLength(args))
            x.DefineMethod('__setprop'
                , (this, name, value, args) => 'set ' name ' ' ObjLength(args) ' = ' value)
            A  (x.pv) = 'get pv 0'
            A  (x.pv['a']) = 'get pv 1'
            A  (x.pv['a','b']) = 'get pv 2'
            A  (x.pv := 'x') = 'set pv 0 = x'
            A  (x.pv['a'] := 'y') = 'set pv 1 = y'
            A  (x.pv['a','b'] := 'z') = 'set pv 2 = z'
            
            ; Test automatic application of [index] to the result of a
            ; property when the meta-method does not accept index args.
            y := {}
            x.DefineMethod('__getprop'
                , (this, name) => y['real' name])
            x.DefineMethod('__setprop'
                , (this, name, value) => y['real' name] := value)
            A  (x.p0) = ''
            MustThrow(() => x.p0[1])
            A  (x.p0 := []) is Array.prototype
            A  (x.p0) is Array.prototype
            A  (x.p0[1] := 'x') = 'x'
            A  (x.p0[1]) = 'x'
            A  (y.realp0) is Array.prototype
            A  (y.realp0)[1] = 'x' && y.realp0.Length = 1 && x.p0 = y.realp0
            
            ; Test error handling.
            b := {}
            MustThrow(() => (b.no)[1]) ; Baseline (separate indexing)
            MustThrow(() =>  b.no [1]) ; No __getprop
            MustThrow(() =>  x.no [1]) ; __getprop without args
            MustThrow(() => (b.no)[1] := 2)
            MustThrow(() =>  b.no [1] := 2)
            MustThrow(() =>  x.no [1] := 2)
        }
        
        _Delete()
        {
            x := {}
            d := 0
            x.DefineMethod('__delete', () => ++d)
            y := new x
            A  d = 0
            y := ''
            A  d = 1
            x := ''
            A  d = 2
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
        
        ClassRoot()
        {
            Class.prototype.isAClass := true
            A  Object.isAClass
            A  TestClass1.isAClass
            A  Object.HasProperty('isAClass')
            
            Class.prototype.DefineMethod('ClassM', () => "yes, ClassM")
            A  Object.HasMethod('ClassM')
            A  Object.ClassM() = "yes, ClassM"
            Class.prototype.DeleteMethod('ClassM')
            A  Object.HasMethod('ClassM') = false
        }
        
        ObjectRoot()
        {
            Object.prototype.isAnObject := true
            x := {}
            A  x.isAnObject = true
            A  Class.isAnObject = true
            A  x.HasProperty('isAnObject')
            
            Object.prototype.DefineMethod('ObjectM', () => "yes, ObjectM")
            A  x.HasMethod('ObjectM')
            A  x.ObjectM() = "yes, ObjectM"
            Object.prototype.DeleteMethod('ObjectM')
            A  x.HasMethod('ClassM') = false
        }
        
        ArrayRoot()
        {
            Array.prototype.isAnArray := true
            x := []
            A  x.isAnArray = true
            A  Class.isAnArray = ""
            A  x.HasProperty('isAnArray')
            
            Array.prototype.DefineMethod('ArrayM', () => "yes, ArrayM")
            A  x.HasMethod('ArrayM')
            A  x.ArrayM() = "yes, ArrayM"
            Array.prototype.DeleteMethod('ArrayM')
            A  x.HasMethod('ClassM') = false
        }
        
        Meta()
        {
            A  TestMeta.Foo == 'static: Foo is undefined'
            A  (TestMeta.Foo := 'Bar') == 'Bar'
            A  TestMeta.stored_Foo == 'Bar'
            A  TestMeta.Foo == 'static: Foo is undefined'
            A  TestMeta.Callme(1,2) == 'static: Callme(2 args)'
            A  TestMeta.stored_Foo() == 'static: stored_Foo(0 args)'
            
            x := new TestMeta
            A  x.foo == 'foo is undefined'
            A  (x.foo := 'bar') == 'bar'
            A  x.stored_foo == 'bar'
            A  x.foo == 'foo is undefined'
            A  x.callme(1,2) == 'callme(2 args)'
            A  x.stored_foo() == 'stored_foo(0 args)'
        }
        
        InitClass()
        {
            A  TestInitClass.staticvar = 1
            x := new TestInitClass
            A  x.sharevar = 2
        }
        
        NewMethod()
        {
            x := TestNew1.new()
            A  x.x = '__init1' && x.y = '__new1'
            A  x is TestNew1.prototype
            x := TestNew2.new()
            A  x.x = '__init1' && x.y = '__new1'
            A  x.a = '__init2' && x.b = '__new2'
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
            A  (x is Object.prototype)
            A  (x is 'object')
            A  (x is y) = false
            A  (new TestClass2) is TestClass2.prototype
            A  (new TestClass2) is Object.prototype
            A  (TestClass2 is Object.prototype) && (TestClass2 is Class.prototype)
            A  (Object is Object.prototype) && (Object is Class.prototype)
        }
    }
    
    class JSON
    {
        SquareBrackets()
        {
            x := [10, 20,, 40]
            A  (x is Array.prototype) && (x is Object.prototype)
            A  x[1] = 10 && x[2] = 20 && x[3] = "" && x[4] = 40
            A  x[-1] = 40 && x[-3] = 20
            A  x.HasProperty('Length')
            A  x.HasMethod('Length') = false && x.HasMethod('MaxIndex') = false
            A  x.Length = 4
            A  !x.HasProperty(1)
        }
        
        CurlyBraces()
        {
            x := {a: 1, b: 2}
            A  (x is Object.prototype)
            A  (x is Array.prototype) = false
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
        Constructor()
        {
            x := new Array('A','B','C')
            A  x.Length = 3
            A  x[1] x[2] x[3] = 'ABC'
        }
        
        Indexing()
        {
            ; Explicit item indexing
            x := ['A','B','C']
            A  x.Item[1] = 'A' && x.Item[2] = 'B' && x.Item[3] = 'C'
            A  x.Item[-1] = 'C' && x.Item[-2] = 'B' && x.Item[-3] = 'A'
            A  x.Item[-4] = '' && x.Item[0] = ''
            A  (x.Item[0] := 'D') = 'D'
            A  x.Item[-1] = 'D' && x.Item[4] = 'D' && x.length = 4
            A  (x.Item[-2] := 'c') == 'c' && x.Item[3] == 'c'
            
            x.Item[1] := []
            x.Item[1,1] := 'X'
            x.Item[1,2] := 'Y'
            A  x.Item[1,1] x.Item[1,-1] == 'XY'
            
            ; Redirected properties
            x := ['A','B','C']
            A  x[1] = 'A' && x[2] = 'B' && x[3] = 'C'
            A  x[-1] = 'C' && x[-2] = 'B' && x[-3] = 'A'
            A  x[-4] = '' && x[0] = ''
            A  (x[0] := 'D') = 'D'
            A  x[-1] = 'D' && x[4] = 'D' && x.length = 4
            A  (x[-2] := 'c') == 'c' && x[3] == 'c'
            
            x[1] := []
            x[1,1] := 'X'
            x[1,2] := 'Y'
            A  x[1,1] x[1,-1] == 'XY'
        }
        
        Length()
        {
            A  ['A','B','C'].length = 3
            A  ['A', ,'B', ,'C'].length = 5
            x := ['A','B','C']
            A  x.HasProperty(1) = false
            A  (x.Length := 2) = 2
            A  x.Length = 2 && x[3] = ""
            A  (x.Length := 4) = 4
            A  x.Length = 4 && x[4] = ""
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
            
            x.RemoveAt(2, 2), x.length := 4
            s := ''
            for v in x
                s .= ' ' A_Index ':' v
            A  s = ' 1:10 2:40 3: 4:'
            
            s := ''
            for k, v in new Enumerator(x.Properties())
                s .= ' ' k ':' v
            A  s = ' prop:42'
        }
        
        VariadicCall()
        {
            fn(args*) {
                r := ''
                loop ObjLength(args)
                    r .= args[A_Index] ','
                return r
            }
            
            x := new Array
            x[1] := 'a'
            x.Push('b', 'c')
            A  fn(x*) = 'a,b,c,'
            
            x := ['d', 'e']
            A  fn(x*) = 'd,e,'
        }
    }
    
    class Map
    {
        Basics()
        {
            m := new Map
            A  (m.Item['abc'] := 11) = 11
            A  m.Item['abc'] = 11
            A  m.Count = 1
            A  (m.Item['ABC'] := 33) = 33
            A  m.Item['ABC'] = 33
            A  m.Item['abc'] = 11
            A  m.Count = 2
            m.Item['xyz'] := 'str'
            A  m.Count = 3
            A  m.Has('abc') && m.Has('ABC') && m.Has('Abc') = false
            
            MustThrow(() => m.Count := 4)
            
            s := ''
            for k, v in m
                s .= ' ' k ':' v
            A  s = ' ABC:33 abc:11 xyz:str'
            
            m2 := m.Clone()
            A  m != m2 && m2.Item['abc'] = 11 && m2.Item['ABC'] = 33
                && m2.Item['xyz'] = 'str' && m2.Count = 3
        }
        
        SubItem()
        {
            m := new Map
            m.Item['sub'] := new Map
            m.Item['sub','item1'] := -1
            m.Item['sub','item2'] := -2
            A  m.Item['sub','item1'] = -1 && m.Item['sub','item2'] := -2
            A  m.Item['sub'].Count = 2
        }
        
        Types()
        {
            m := new Map
            m.Item['s'] := 'str'
            m.Item[1] := 'int'
            m.Item[Map] := 'obj'
            A  m.Item['s'] = 'str' && m.Item[1] = 'int' && m.Item[Map] = 'obj'
            
            s := ''
            for k, v in m
                s .= ' ' type(k) ':' (IsObject(k) ? &k : k) ':' v
            A  s = ' Integer:1:int Class:' (&Map) ':obj String:s:str'
            
            m := new Map
            m.Item['1'] := 'is'
            m.Item[1] := 'i'
            A  m.Item['1'] = 'is' && m.Item[1] = 'i'
            m.Item[1.0] := 'f'
            m.Item['1.0'] := 'fs'
            A  m.Item['1.0'] = 'fs' && m.Item[1.0] = 'f'
            
            s := ''
            for k, v in m
                s .= ' ' type(k) ':' k ':' v
            A  s = ' Integer:1:i String:1:is String:1.0:fs Float:1.0:f'
            
            m := new Map
            m.Item[-.1] := '-f' ; Normally coerced to "-0.1"
            m.Item["-.1"] := '-fs'
            m.Item["-0.1"] := '-0fs'
            s := ''
            for k, v in m
                s .= ' ' type(k) ':' k ':' v
            A  s = ' String:-.1:-fs String:-0.1:-0fs Float:' (-.1) ':-f'
        }
        
        Delete()
        {
            m := new Map
            m.Item['x'] := 1
            m.Item['y'] := 2
            A  m.Has('x') && m.Has('y') && m.Count = 2
            m.Delete('x')
            A  m.Has('x') = false && m.Has('y') && m.Count = 1
            
            m := new Map
            m.Item['x'] := 1
            m.Item['y'] := 2
            A  m.Has('x') && m.Has('y') && m.Count = 2
            m.Clear()
            A  m.Has('x') = false && m.Has('y') = false && m.Count = 0
        }
    }
    
    class Limitations
    {
        ; These test the expected results rather than the desired ones.
        
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

class TestMeta extends Object {
    class _instance {
        __getprop(name, args) {
            ObjLength(args) && base.__getprop(name, args)
            return name ' is undefined'
        }
        __setprop(name, value, args) {
            return base.__setprop('stored_' name, value, args)
        }
        __call(name, args) {
            return name '(' ObjLength(args) ' args)'
        }
    }
    class _static {
        __getprop(name, args) {
            ObjLength(args) && base.__getprop(name, args)
            return 'static: ' name ' is undefined'
        }
        __setprop(name, value, args) {
            return base.__setprop('stored_' name, value, args)
        }
        __call(name, args) {
            return 'static: ' name '(' ObjLength(args) ' args)'
        }
    }
}

class TestInitClass extends Object {
    class _static {
        __initclass() {
            this.staticvar := 1
            this.prototype.sharevar := 2
        }
    }
}

NullFunc(p*) {
}