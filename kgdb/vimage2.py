import gdb

class vimage(gdb.Function):
    def __init__(self):
        super(vimage, self).__init__("vimage")

    def invoke(self, name, vnet=gdb.parse_and_eval('prison0.pr_vnet')):
        name = name.string()
        if name.startswith("V_"):
            name = name[len("V_"):]
        base = vnet['vnet_data_base']
        entry = gdb.lookup_global_symbol('vnet_entry_' + name).value()
        entry_addr = entry.address.cast(gdb.lookup_type('uintptr_t'))
        return gdb.Value(base + entry_addr).cast(entry.type.pointer())

vimage()
