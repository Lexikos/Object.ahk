
xx := {}
x := new MyFoo
D x.HasProperty("someprop") " " x.HasProperty("someotherprop")
for k, v in x
    D k "=" v

class MyFoo extends Object {
    someprop {
        get {
            return 12
        }
    }
    someotherprop := 1
}


class Array extends Object
{
    Length {
        get {
            return ObjLength(this._)
        }
        set {
            if !(value is 'integer')
                throw Exception("Invalid value", -1, value)
            n := ObjLength(this._)
            if value = n
                return n
            if value < n {
                this.Delete(value + 1, n)
                n := ObjLength(this._)
            }
            else {
                Loop value - n
                    ObjRawSet(this._, ++n, "")
            }
            return ObjLength(this._)
        }
    }
    
    _NewEnum() {
        return new Array.Enumerator(this)
    }
    
    class Enumerator
    {
        __new(arr) {
            this._ := arr._
        }
        Next(ByRef a, ByRef b:="") {
            if IsByRef(b) {
                this.e := ObjNewEnum(this._)
                this.Next := this.base.Next2
            }
            else {
                this.Next := this.base.Next1
                this.n := 0
            }
            return this.Next(a, b)
        }
        Next1(ByRef a) {
            a := this._[++this.n]
            return this.n <= this._.Length()
        }
        Next2(ByRef a, ByRef b) {
            return this.e.Next(a, b)
        }
    }
}

class Object
{
    ; Data store
    ; _ := Object_v()
    
    new(p*) {
        return new this(p*)
    }
    
    __new() {
        self := Object_v()
        self._ := this
        self.base := Class_Meta(this.base)
        this.base := ""
        return self
        ; this.base := Class_Meta(this.base)
    }
    
    HasProperty(name) {
        cm := ObjGetBase(this)
        return isObject(cm.m.get[name] || cm.m.set[name])
            || ObjHasKey(this._, name)
            ; || ObjHasKey(this, name)
    }
    HasMethod(name) {
        cm := ObjGetBase(this)
        return isObject(cm.m.call[name])
    }
    
    ; Standard object methods
    Delete(p*) {
        return ObjDelete(this._, p*)
    }
    SetCapacity(p*) {
        return ObjSetCapacity(this._, p*)
    }
    GetCapacity(p*) {
        return ObjGetCapacity(this._, p*)
    }
    GetAddress(p) {
        return ObjGetAddress(this._, p)
    }
    HasKey(p) {
        return ObjHasKey(this._, p)
    }
    Clone() {
        return {_: ObjClone(this._), base: this.base}
    }
    _NewEnum() {
        return ObjNewEnum(this._)
    }
}

Object__get_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    return this._[k, p*]
}
Object__set_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    value := p.Pop()
    return this._[k, p*] := value
}
Object__call_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    throw Exception("No such method", -2, k)
}

Class_Meta(cls) {
    static meta_key := Object_v()
    if ObjHasKey(cls, meta_key)
        return cls[meta_key]
    m := Class_Members(cls)
    if !m.get["base"]
        m.get["base"] := Func("Object_ReturnArg1").Bind(cls)
    if !m.set["base"]
        m.set["base"] := Func("Object_SetBase")
    cm := Object_v()
    cm.__get := Func("Object__get_").Bind(m.get)
    cm.__set := Func("Object__set_").Bind(m.set)
    cm.__call := Func("Object__call_").Bind(m.call)
    cm.m := m
    cm.base := cls  ; For type identity ('is').
    cls[meta_key] := cm
    return cm
}

Object_ReturnArg1(arg1) {
    return arg1
}

Object_SetBase(this, newbase) {
    if newbase is Object && ObjHasKey(newbase, "__Class") || newbase = Object
        ObjSetBase(this, Class_Meta(newbase))
    else
        ObjSetBase(this, newbase)
    return newbase
}

Class_Members(cls) {
    static m_key := Object_v()
    if ObjHasKey(cls, m_key)
        return cls[m_key]
    cls[m_key] := m := Object_v()
    m.get := Object_v()
    m.set := Object_v()
    m.call := Object_v()
    ObjRawSet(m.get, "base", "")
    ObjRawSet(m.set, "base", "")
    Class_Members_(cls, m)
    return m
}
Class_Members_(cls, m) {
    if cls.base
        Class_Members_(cls.base, m)
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) = "Func" {  ; Not isFunc() - don't want func NAMES, only true methods.
            m.call[k] := v
        }
        else if type(v) = "Property" {
            if f := v.get
                m.get[k] := f
            if f := v.set
                m.set[k] := f
        }
        else {
            ; Inherit static variables?
        }
    }
}

Array(p*) {
    a := Object_v()
    a._ := p
    a.base := Class_Meta(Array)
    return a
}

Object_v(p*) {
    return p
}


;
; Bad code! Version-dependent. Relies on undocumented stuff.
;

ObjGetBase(obj) {
    static Object_vtbl := NumGet(&Object_v())
    if !isObject(obj) || NumGet(&obj) != Object_vtbl
        throw Exception("Invalid parameter #1", -1, obj)
    if thebase := NumGet(&obj + 2*A_PtrSize)
        return Object(thebase)
}

ObjSetBase(obj, newbase) {
    static Object_vtbl := NumGet(&Object_v())
    if !isObject(obj) || NumGet(&obj) != Object_vtbl
        throw Exception("Invalid parameter #1", -1, obj)
    if newbase {
        if !isObject(newbase)
            throw Exception("Invalid parameter #2", -1, newbase)
        ObjAddRef(&newbase)
        newbase := &newbase
    }
    oldbase := NumGet(&obj, 2*A_PtrSize)
    NumPut(newbase, &obj, 2*A_PtrSize)
    if oldbase
        ObjRelease(oldbase)
}

Object(p*) {
    if p.Length() = 1 {
        return ComObject(0x4009, &(n := p[1]))[]
    }
    obj := new Object
    while p.Length() {
        value := p.Pop()
        key := p.Pop()
        obj[key] := value
    }
    return obj
}
