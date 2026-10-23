PACKAGECONFIG += "fbdev gridnav"

# Use the C library allocator instead of LVGL's builtin pool. The builtin
# pool has a fixed size (64 KB by default) and running out of it ends in
# LV_ASSERT_HANDLER (while(1)): the recovery GUI hangs at 100% CPU.
do_configure:append() {
    sed -r -e "s|^([[:space:]]*#define LV_USE_STDLIB_MALLOC[[:space:]]).*|\1LV_STDLIB_CLIB|" \
        -i "${S}/lv_conf.h"
}
