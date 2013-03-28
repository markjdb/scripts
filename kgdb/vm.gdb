define show-page
    set $_page = (struct vm_page *)$arg0
    printf "%p 0x%x\n", $_page, $_page->phys_addr
end

define list-obj-pages
    set $_obj = (struct vm_object *)$arg0
    set $_page = $_obj->memq.tqh_first
    while ($_page != 0)
        show-page $_page
        set $_page = $_page->listq.tqe_next
    end
end

document list-obj-pages
Given a vm object, list info about its pages.
end
