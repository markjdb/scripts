import gdb
import math

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

class acttrace(gdb.Command):
    def __init__(self):
        super(acttrace, self).__init__("acttrace", gdb.COMMAND_USER)

    def _thread_by_tid(self, tid):
        threads = gdb.inferiors()[0].threads()
        for td in threads:
            if td.ptid[2] == tid:
                return td

    def invoke(self, arg, from_tty):
        # Save the currently selected thread.
        curthread = gdb.selected_thread()

        pcpu = gdb.lookup_global_symbol("cpuid_to_pcpu").value()
        for cpu in cpu_foreach():
            td = pcpu[cpu]['pc_curthread']
            p = td['td_proc']
            self._thread_by_tid(td['td_tid']).switch()

            print("Tracing command {} pid {} tid {} (CPU {})".format(
                p['p_comm'].string(), p['p_pid'], td['td_tid'], cpu))
            gdb.execute("bt")
            print

        # Switch back to the starting thread.
        curthread.switch()

acttrace()
