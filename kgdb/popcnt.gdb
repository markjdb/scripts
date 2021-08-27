define popcnt32
    set $_x1 = $arg0
    set $_x1 = $_x1 - (($_x1 >> 1) & 0x55555555)
    set $_x1 = ($_x1 & 0x33333333) + (($_x1 >> 2) & 0x33333333)
    set $_x1 = ($_x1 + ($_x1 >> 4)) & 0x0F0F0F0F
    set $_x1 = $_x1 + ($_x1 >> 8)
    set $_x1 = $_x1 + ($_x1 >> 16)
    set $_rval = $_x1 & 0x3f
end

define popcnt
    set $_x = ((unsigned long long)$arg0) & 0xffffffff
    set $_y = ((unsigned long long)$arg0) >> 32
    popcnt32 $_x
    set $_v = $_rval
    popcnt32 $_y
    set $_v = $_v + $_rval
    p/d $_v
end
