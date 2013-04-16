define em-dump-descrs
    set $_txr = (struct tx_ring *)$arg0
    set $_adp = $_txr->adapter

    set $_i = 0
    while ($_i < $_adp->num_tx_desc)
        set $_desc = &$_txr->tx_base[$_i]
        printf "desc %04d: status 0x%x, addr 0x016%x, upper data 0x%08x, lower data 0x%08x\n", \
                $_i, $_desc->upper.fields.status, $_desc->buffer_addr, $_desc->upper.data, \
                $_desc->lower.data
        set $_i = $_i + 1
    end
end

define em-dump-buffers
    set $_txr = (struct tx_ring *)$arg0
    set $_adp = $_txr->adapter

    set $_i = 0
    while ($_i < $_adp->num_tx_desc)
        set $_buf = &$_txr->tx_buffers[$_i]
        printf "buf %04d: EOP %04d\n", $_i, $_buf->next_eop
        set $_i = $_i + 1
    end
end
