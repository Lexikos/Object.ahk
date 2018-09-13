 
Object_throw(extype, p*) {
    while (stdex := Exception("", -A_Index)).What != -A_Index {
        if !(stdex.File ~= "\\Object(?:\.\w+)?\.ahk")
            break
    }
    ex := extype.new(p*)
    ; The built-in error dialog requires that these be set raw.
    ObjRawSet ex, "File", stdex.File
    ObjRawSet ex, "Line", stdex.Line
    throw ex
}

class Exception extends Object
{
    class _instance
    {
        __new(msg:="", extra:="") {
            ; The built-in error dialog requires that these be set raw.
            ObjRawSet this, "Message", '(' type(this) ') ' msg
            ObjRawSet this, "Extra", Object_String(extra)
        }
    }
}

class TypeError extends Exception
{
    class _instance
    {
        __new(p*) {
            base.__new(p*)
            if ObjHasKey(p, 2) && !isObject(p[2])
                this.Extra .= ' (' type(p[2]) ')'
        }
    }
}

class MemberError extends Exception
{
}

class PropertyError extends MemberError
{
}

class MethodError extends MemberError
{
}

class ValueError extends Exception
{
}

class IndexError extends ValueError
{
}

_throw_Immutable(this) {
    Object_throw(TypeError, "This object is immutable.", this)
}
