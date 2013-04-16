define pci-walk-devq
    printf "Name      VID       DID\n"
    set $_dev = (struct pci_devinfo *)pci_devq.stqh_first
    while ($_dev != 0)
        if ($_dev->conf.pd_name[0] != 0)
            printf "%s%d", $_dev->conf.pd_name, $_dev->conf.pd_unit
        else
            printf "???"
        end
        printf "\t0x%04x    0x%04x\n", $_dev->conf.pc_vendor, $_dev->conf.pc_device
        set $_dev = (struct pci_devinfo *)$_dev->pci_links.stqe_next
    end
end

document pci-walk-devq
Print the device and vendor IDs of each element in the PCI device list. 
end
