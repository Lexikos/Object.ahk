
class _PrimitiveValue_Base {
    __item[p*] {
        get {
            return _Object_mget(%Type(this)%.prototype, this, "__Item", p, false)
        }
        set {
            p.Push(value)
            return _Object_mset(%Type(this)%.prototype, this, "__Item", p, false)
        }
    }
}

Value__call(value, k, p*) {
    static _ := (
        _ := "".base,
        _.__call := Func("Value__call"),
        _.__get := Func("Value__get"),
        _.__set := Func("Value__set"),
        _.base := _PrimitiveValue_Base,
        0)
    return _Object_mcall(%Type(value)%.prototype, value, k, p)
}

Value__get(value, k, p*) {
    return _Object_mget(%Type(value)%.prototype, value, k, p)
}

Value__set(value, k, p*) {
    return _Object_mset(%Type(value)%.prototype, value, k, p)
}

class PrimitiveValue extends Object
{
    class _instance
    {
        __getprop(name) {
            Object_throw(PropertyError, "Unknown property", name)
        }
        
        __setprop(name, value) {
            return isObject(this) ? base.__setprop(name, value) : _throw_Immutable(this)
        }
        
        base {
            get {
                return isObject(this) ? base.base : %Type(this)%.prototype
            }
            set {
                return isObject(this) ? (base.base := value) : _throw_Immutable(this)
            }
        }
        
        HasOwnProperty(name) {
            return isObject(this) ? base.HasOwnProperty(name) : false
        }
        
        HasProperty(name) {
            return Object_HasProp(isObject(this) ? this : this.base, name)
        }
        
        HasMethod(name) {
            return Object_HasMeth(isObject(this) ? this : this.base, name)
        }
        
        GetMethod(name) {
            return Object_GetMeth(isObject(this) ? this : this.base, name)
        }
        
        DefineProperty(name, prop) {
            return isObject(this) ? base.DefineProperty(name, prop) : _throw_Immutable(this)
        }
        
        DefineMethod(name, func) {
            return isObject(this) ? base.DefineMethod(name, func) : _throw_Immutable(this)
        }
        
        DeleteProperty(name) {
            return isObject(this) ? base.DeleteProperty(name) : _throw_Immutable(this)
        }
        
        DeleteMethod(name) {
            return isObject(this) ? base.DeleteMethod(name) : _throw_Immutable(this)
        }
        
        SetCapacity(p*) {
            return isObject(this) ? base.SetCapacity(p*) : _throw_Immutable(this)
        }
        
        GetCapacity(p*) {
            return isObject(this) ? base.GetCapacity(p*) : Object_throw(PropertyError, "Unknown property", p[1])
        }
        
        GetAddress(p) {
            return isObject(this) ? base.GetAddress(p) : Object_throw(PropertyError, "Unknown property", p)
        }
        
        Clone() {
            return isObject(this) ? base.Clone() : this
        }
        
        Properties() {
            return isObject(this) ? base.Properties() : (*) => false ; No own properties.
        }
    }
}

class String extends PrimitiveValue
{
    class _static
    {
        __initclass() {
            Object_DefProp(this.prototype, 'Length', {get: Func('StrLen')})
        }
    }
    
    class _instance
    {
        __getprop(index) {
            if !(index is 'integer')
                Object_throw(PropertyError, "Unknown property", index)
            return (c := SubStr(this, index, 1)) != "" ? c : Object_throw(IndexError, "Invalid index", index)
        }
        
        __Item[index, p*] {
            get {
                if !(index is 'integer') || ObjLength(p)
                    Object_throw(TypeError, "Invalid index", index)
                return (c := SubStr(this, index, 1)) != "" ? c : Object_throw(IndexError, "Invalid index", index)
            }
        }
    }
}

class Number extends PrimitiveValue
{
}
class Integer extends Number
{
}
class Float extends Number
{
}
