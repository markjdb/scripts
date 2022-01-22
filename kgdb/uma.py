import gdb

def maybe_eval(exp):
    return exp if isinstance(exp, gdb.Value) else gdb.parse_and_eval(exp)

def symval(sym):
    return gdb.lookup_global_symbol(sym).value()

def bit_foreach(bs, s):
    for i in range(0, (s + 63) / 64):
        for b in range(0, min(64, s - (i * 64))):
            if (bs['__bits'][i] & (1 << b)) == 0:
                yield i * 64 + b

def list_foreach(lh, f):
    n = lh['lh_first']
    while n:
        yield n
        n = n[f]['le_next']

def uma_allocated(zone, t):
    """
    Return a list of items allocated from the zone.  Each item has type gdb.Value,
    where the value is a pointer to t, i.e., "t *".

    For example, to dump all allocated mbufs:

    (gdb) source uma.py
    (gdb) python
    > for item in uma_allocated("zone_mbuf", "struct mbuf"):
    >     print(item.dereference().format_string())
    """
    t = gdb.lookup_type(t).pointer()
    zone = maybe_eval(zone)
    keg = zone['uz_keg']

    ndomains = symval("vm_ndomains")
    slabs = set()

    d = 0
    while d < ndomains:
        uk_dom = keg['uk_domain'][d]
        slabs.update(list_foreach(uk_dom['ud_part_slab'], "us_link"))
        slabs.update(list_foreach(uk_dom['ud_full_slab'], "us_link"))
        d = d + 1

    items = set()
    for slab in slabs:
        saddr = int(slab.address) - keg['uk_pgoff']
        for off in bit_foreach(slab['us_free'], keg['uk_ipers']):
            items.add(int(saddr) + off * int(keg['uk_rsize']))

    # XXXMJ subtract elements in the cache (per-CPU buckets, cross-domain
    # bucket, full bucket list(s).

    return {gdb.Value(item).cast(t) for item in items}
