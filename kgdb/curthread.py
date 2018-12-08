import gdb

def _queue_foreach(head, field, headf, nextf):
    elm = head[headf]
    while elm != 0:
        yield elm
        elm = elm[field][nextf]

def list_foreach(head, field):
    return _queue_foreach(head, field, "lh_first", "le_next")

def tailq_foreach(head, field):
    return _queue_foreach(head, field, "tqh_first", "tqe_next")

def pfind(pid):
    p = pfind.cached_procs.get(pid)
    if p is not None:
        print("cached")
        return p

    allproc = gdb.lookup_global_symbol("allproc").value()
    for p in list_foreach(allproc, "p_list"):
        npid = p['p_pid']
        pfind.cached_procs[int(npid)] = p
        if npid == pid:
            return p
pfind.cached_procs = dict()

def tdfind(tid, pid=-1):
    td = tdfind.cached_threads.get(int(tid))
    if td is not None:
        return td

    allproc = gdb.lookup_global_symbol("allproc").value()
    for p in list_foreach(allproc, "p_list"):
        if pid != -1 and pid != p['p_pid']:
            continue
        for td in tailq_foreach(p['p_threads'], "td_plist"):
            ntid = td['td_tid']
            tdfind.cached_threads[int(ntid)] = td
            if ntid == tid:
                return td
tdfind.cached_threads = dict()

class curthread(gdb.Function):
    def __init__(self):
        super(curthread, self).__init__("curthread")

    def invoke(self):
        return tdfind(gdb.selected_thread().ptid[2])

curthread()
