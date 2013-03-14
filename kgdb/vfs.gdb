define list-mountpoints
    set $_mount = mountlist.tqh_first
    while ($_mount != 0)
        printf "%p: %-20s %-20s %s\n", $_mount, $_mount->mnt_stat.f_mntfromname, \
	    $_mount->mnt_stat.f_mntonname, $_mount->mnt_stat.f_fstypename
        set $_mount = $_mount->mnt_list.tqe_next
    end
end

document list-mountpoints
Display a table of the mounted filesystems.
end

# To do:
# - function to get the path name from a vnode.
# - function to list pathnames of all vnodes.
