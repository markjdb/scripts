import gdb

def symval(name):
    return gdb.lookup_static_symbol(name).value()


def linker_files():
    l = symval("linker_files")['tqh_first']
    while l:
        yield l
        l = l['link']['tqe_next']
    

class kldstat(gdb.Command):
    def __init__(self):
        super(kldstat, self).__init__("kldstat", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        for kld in linker_files():
            print(kld['filename'])

# Register the command with gdb.
kldstat()
