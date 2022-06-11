import functools
import math
import gdb

from kgdb import *

def foreach_proc_in_system():
    allproc = gdb.lookup_global_symbol("allproc").value()
    for p in list_foreach(allproc, "p_list"):
        yield p


def _vm_map_entry_succ(entry):
    after = entry['right']
    if after['left']['start'] > entry['start']:
        while True:
            after = after['left']
            if after['left'] == entry:
                break
    return after


def foreach_vm_map_entry(map):
    entry = map['header']['right']
    while entry != map['header'].address:
        yield entry
        entry = _vm_map_entry_succ(entry)


def cpu_foreach():
    all_cpus = gdb.lookup_global_symbol("all_cpus").value()
    bitsz = gdb.lookup_type("long").sizeof * 8
    maxid = gdb.lookup_global_symbol("mp_maxid").value()

    cpu = 0
    while cpu <= maxid:
        upper = cpu >> int(math.log(bitsz, 2))
        lower = 1 << (cpu & (bitsz - 1))
        if (all_cpus['__bits'][upper] & lower) != 0:
            yield cpu
        cpu = cpu + 1


# XXX-MJ doesn't handle "struct vm_object *"
# XXX-MJ assumes there's a return value, assumes one parameter
def ctype(t):
    def thunk(f):
        @functools.wraps(f)
        def wrap(a):
            if a.type != gdb.lookup_type(t):
                raise gdb.GdbError("parameter type mismatch: expected {} have {}".format(t, a.type))
            return f(a)
        return wrap
    return thunk

@ctype("vm_object_t")
def findobj(obj):
    """Find all userspace vm_map entries referencing the specific VM object."""
    for p in foreach_proc_in_system():
        for entry in foreach_vm_map_entry(p['p_vmspace']['vm_map'].address):
            if not entry['object']['vm_object']:
                continue
            if entry['object']['vm_object'] == obj:
                gdb.add_history(p)
                gdb.add_history(entry)
                return p
