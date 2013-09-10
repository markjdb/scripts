define inodedeps
    set $_i = 0
    while ($_i < inodedep_hash)
        set $_dep = inodedep_hashtbl[$_i].lh_first
        if ($_dep != 0x0)
            printf "deps found at index %d\n", $_i
        end
        set $_i = $_i + 1
    end
end
