define inodedeps
    set $_ump = (struct ufsmount *)((struct mount *)$arg0)->mnt_data

    set $_i = 0
    while ($_i < $_ump->um_softdep->sd_idhashsize)
        set $_dep = $_ump->um_softdep->sd_idhash[$_i].lh_first
        if ($_dep != 0x0)
            printf "deps found at index %d\n", $_i
        end
        set $_i = $_i + 1
    end
end
