# Errors

`Object.Errors.ahk` (which is automatically included by Object.ahk) defines a rudimentary Exception type hierarchy. All exceptions thrown by the script are instances of `Exception` or a subclass. Currently the following subclasses are defined:

  - `TypeError`: a value, parameter or index was in incorrect type, or an operation was attempted that is never supported for the given type of object.
  - `ValueError`: a parameter or assigned value was incorrect (but not an incorrect type).
    - `IndexError`: index out of range (currently only thrown when indexing a string).
  - `MemberError`
    - `PropertyError`: property is read-only or non-existent (currently only primitive values throw the latter).
    - `MethodError`: call to non-existent method.

These are mostly based on Python.


## Usage

An exception is constructed as follows, but replacing `Exception` with the appropriate subclass:

    new Exception(message, extra, skip_frames)

The parameters are used to construct the pseudo-properties `Message`, `Extra`, `File` and `Line`, which are used by the default error dialog (and `ErrorDialog.ahk`). The default error dialog requires that these be direct key-value pairs of the exception object, so they are subject to the same limitations as normal AutoHotkey objects.

All parameters are optional; however, `Message` will be empty if omitted as there are currently no default messages.

`Extra` is converted to a string by calling `String(extra)` or providing some default formatting if that fails (e.g. when a non-Object.ahk object is passed). This string is displayed in the error dialog, with the prefix "Specifically: ".

Error dialogs use `File` and `Line` to determine which line to point at as the likely cause of the error. For example, if invalid parameters were given, these should point at the function call which provided the parameters. This is achieved by specifying a positive integer for `skip_frames` - the number of stack frames to skip. It is equivalent to passing a negative value to the standard Exception function's second parameter, except that all stack frames in files named `Object.ahk` or `Object.*.ahk` are excluded (skipped automatically).  For example:

    ding(times) {
        if !(times is 'integer')
            throw new TypeError("Invalid parameter #1", times, 1)
        Loop times {
            SoundPlay "*-1"
            Sleep 500
        }
    }
    ding("twice")  ; Error dialog points here


## Stack Traces

The default `Exception` constructor sets a property `StackTrace` which contains the result of calling `Exception.StackTrace()`. This static method returns a stack trace from the current point of execution, where each entry is a line in the following form, terminated with `` `n ``:

    Path\Name.ahk (Line) : Context

*Line* is just the line number, in decimal. *Context* is typically the function or subroutine which contains the line. The last line has context "(main)".

All stack frames in `Object.ahk` or `Object.*.ahk` are excluded.


## ErrorDialog.ahk

This file defines a replacement for the standard error dialog which is shown each time an exception or runtime error is thrown but not caught. The differences to the standard dialog are:
  - If an exception with a type name other than "Object" or "Exception" is thrown, the type name is used in place of the word "Error".
  - The dialog shows only 5 lines of code (2 lines above and 2 lines below the reference line) instead of 15. The code is read from the script file, so is generally more readable than on the built-in dialog but may be incorrect if the file has been modified since the script started.
  - A stack trace is shown (up to 5 frames followed by "... n more"). This has the same format as [Exception.StackTrace()](#stack-traces) except that only the filename is shown, not the full path, and it is indented. If the exception lacks a `StackTrace` property, the trace starts from the current point of execution (so if an exception without `StackTrace` is caught and re-thrown, the trace is incomplete).
  - The dialog has buttons "Reload", "ExitApp", "Close" and "Help". "Help" shows a menu with options for searching the online documentation and forums, and a ListLines option. Access to ListVars is not provided since it would show the local variables of ErrorDialog().
  - The title is `"Error - " A_ScriptName`.

### Ideas

Originally (long before Object.ahk was started) it was going to be a custom dialog (inspired by [PR11](https://github.com/Lexikos/AutoHotkey_L/pull/11)), which would allow for a lot more flexibility and better presentation of the information. Having not yet found the motivation to develop the full idea, I built the MsgBox-based implementation to assist with debugging of Object.ahk.

Displaying the context code with a monospace font might improve readability. A RichEdit or Link control could be used to make the line numbers links (to edit the script and navigate to that line, if possible).

Displaying the stack trace in a ListView would probably make it more readable when each frame is from a different file than the last.

The default "---> line" is the one that threw the exception, which isn't always useful. The dialog could provide some way for the user to select which stack frame to display the code of.

More stack frames could be accessible to the user without showing them all by default.

The dialog could provide access to external tools, such as DebugVars.ahk, which can inspect the variables from any stack frame (until the dialog is closed).