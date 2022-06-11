# Helpers.

import gdb

def has_feature(name):
    return gdb.lookup_symbol('sysctl___kern_features_' + name)[0] is not None

def cast_thru_ptr(val, t):
    return gdb.parse_and_eval("({} *){}".format(t, val)).dereference()

# Is there a more pythonic way of doing this?
def maybe_eval(a):
    return a if isinstance(a, gdb.Value) else gdb.parse_and_eval(a)

# sys/queue.h functions.

def tailq_first(head):
    head = maybe_eval(head)
    return head['tqh_first']

def tailq_empty(head):
    return head['tqh_first'] == 0

def tailq_next(var, field):
    return var[field]['tqe_next']

def tailq_foreach(head, field):
    head = maybe_eval(head)
    var = tailq_first(head)
    while var != 0:
        yield var
        var = tailq_next(var, field)

def list_first(head):
    head = maybe_eval(head)
    return head['lh_first']

def list_empty(head):
    return head['lh_first'] == 0

def list_next(var, field):
    return var[field]['le_next']

def list_foreach(head, field):
    head = maybe_eval(head)
    var = list_first(head)
    while var != 0:
        yield var
        var = list_next(var, field)

# Process/thread iteration and lookup.

def pfind(pid):
    """Use the allproc list to find the proc with the given PID."""
    for p in list_foreach("allproc", "p_list"):
        if p['p_pid'].cast(gdb.lookup_type("int")) == pid:
            return p
    raise gdb.error("No process with pid {} exists".format(pid))

def foreach_proc_in_system():
    p = list_first("allproc")
    while p != 0:
        yield p
        p = list_next(p, "p_link")

def foreach_thread_in_proc(p):
    p = maybe_eval(p)
    td = tailq_first(p['p_threads'])
    while td != 0:
        yield td
        td = tailq_next(td, "td_plist")

# VM object page traversal and lookup.

def vm_page_foreach(obj):
    obj = maybe_eval(obj)
    m = tailq_first(obj['memq'])
    while m != 0:
        yield m
        m = tailq_next(m, "listq")

#def vm_page_lookup(obj, pindex):
#    obj = maybe_eval(obj)
#
#    node = obj['rtree']['rt_root']
#    while node != 0:
#        if node & 0x1 != 0:
#            m = cast_thru_ptr(node, "struct vm_page")
#            return m if m['pindex'] == pindex else 0
#        node = cast_thru_ptr(node, "struct vm_radix_node")
#        if node['rn_clev'] < 15:
