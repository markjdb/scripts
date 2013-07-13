#!/usr/sbin/dtrace -s

fbt::mfi_disk_strategy:entry
{
        vol = ((struct mfi_disk *)args[0]->bio_disk->d_drv1)->ld_id;
        @["count", vol] = quantize(args[0]->bio_length);
        arr[args[0]] = timestamp;
}

fbt::mfi_disk_complete:entry
/arr[args[0]] != 0/
{
        vol = ((struct mfi_disk *)args[0]->bio_disk->d_drv1)->ld_id;
        @["us", vol] = quantize((timestamp - arr[args[0]]) / 1000);
        arr[args[0]] = 0;
}
