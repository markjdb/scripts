import gdb

class vimage(gdb.Function):
    def __init__(self):
        super(vimage, self).__init__("V")

    def invoke(self, sym, vnet=gdb.parse_and_eval("$curthread()->td_vnet")):
        sym = sym.string()
        if sym.startswith("V_"):
            sym = sym[len("V_"):]
        if gdb.lookup_symbol("sysctl___kern_features_vimage")[0] is None:
            return gdb.parse_and_eval(sym)
        if not vnet:
            vnet = gdb.lookup_global_symbol("vnet0").value()
        base = vnet['vnet_data_base']
        entry = gdb.lookup_global_symbol("vnet_entry_" + sym).value()
        entry_addr = entry.address.cast(gdb.lookup_type("uintptr_t"))
        return gdb.Value(base + entry_addr).cast(entry.type.pointer())

vimage()
