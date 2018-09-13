
Value__call(value, k, p*) {
    static _ := (
        _ := "".base,
        _.__call := Func("Value__call"),
        _.__get := Func("Value__get"),
        _.__set := Func("Value__set"),
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
            throw Exception("Unknown property", -3, name)
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
            return isObject(this) ? base.GetCapacity(p*) : ""
        }
        
        GetAddress(p) {
            return isObject(this) ? base.GetAddress(p) : _throw("Invalid value.", -2)
        }
        
        Clone() {
            return isObject(this) ? base.Clone() : this
        }
        
        Properties() {
            return isObject(this) ? base.Properties() : () => false ; No own properties.
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
                throw Exception("Unknown property", -3, index)
            return (c := SubStr(this, index, 1)) != "" ? c : _throw("Invalid index", -3, index)
        }
        
        Item[index, p*] {
            get {
                if !(index is 'integer') || ObjLength(p)
                    throw Exception("Invalid index", -3, index)
                return (c := SubStr(this, index, 1)) != "" ? c : _throw("Invalid index", -3, index)
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
