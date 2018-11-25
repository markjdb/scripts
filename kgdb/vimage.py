import gdb

def has_feature(name):
    return gdb.lookup_symbol('sysctl___kern_features_' + name)[0] is not None

def vimage_resolve(name, vnet=gdb.parse_and_eval('prison0.pr_vnet')):
    if name.startswith('V_'):
        name = name[len('V_'):]
    if not has_feature('vimage'):
        return gdb.lookup_global_symbol(name).value().address
    base = vnet['vnet_data_base']
    entry = gdb.lookup_global_symbol('vnet_entry_' + name).value()
    entry_addr = entry.address.cast(gdb.lookup_type('uintptr_t'))
    return gdb.Value(base + entry_addr).cast(entry.type.pointer())

def vimage_print_sym(name, vnet=gdb.parse_and_eval('prison0.pr_vnet')):
    print(vimage_resolve(name, vnet).dereference())
