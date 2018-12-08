import gdb

class vimage(gdb.Function):
    def __init__(self):
        super(vimage, self).__init__("V")

    def invoke(self, sym, vnet=None):
        sym = sym.string()
        if sym.startswith("V_"):
            sym = sym[len("V_"):]
        if gdb.lookup_symbol("sysctl___kern_features_vimage")[0] is None:
            return gdb.lookup_global_symbol(sym).value()

        if vnet is None:
            vnet = tdfind(gdb.selected_thread().ptid[2])['td_vnet']
            if not vnet:
                # If curthread->td_vnet == NULL, vnet0 is the current vnet.
                vnet = gdb.lookup_global_symbol("vnet0").value()
        base = vnet['vnet_data_base']
        entry = gdb.lookup_global_symbol("vnet_entry_" + sym).value()
        entry_addr = entry.address.cast(gdb.lookup_type("uintptr_t"))
        ptr = gdb.Value(base + entry_addr).cast(entry.type.pointer())
        return ptr.dereference()

vimage()
