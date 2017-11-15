import inspect

def test(condition):
    if not condition:
        frame = inspect.currentframe()
        caller = frame.f_back
        lineno = caller.f_lineno
        code = inspect.getsourcelines(inspect.getmodule(caller.f_code))[0]
        print("---------------------------------------------------------------")
        print("Test failed:")
        print("\t" + code[lineno-1])
        print("in")
        print("  File \"" + caller.f_code.co_filename + \
              "\", line " + repr(lineno))
        exit(-1)

