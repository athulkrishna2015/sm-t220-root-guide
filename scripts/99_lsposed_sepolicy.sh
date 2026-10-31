#!/system/bin/sh
# Re-apply LSPosed/Vector SELinux rules at boot.
# Magisk 31.1 does not apply module sepolicy.rule files automatically.
# Adjust the module path if using Vector instead of LSPosed.
magiskpolicy --live --apply /data/adb/modules/zygisk_lsposed/sepolicy.rule
