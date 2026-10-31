# Rooting Samsung Galaxy Tab A7 Lite (SM-T220) on Linux

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Device](https://img.shields.io/badge/Device-SM--T220-green.svg)]()
[![Android](https://img.shields.io/badge/Android-14-orange.svg)]()
[![Root](https://img.shields.io/badge/Root-Magisk-red.svg)]()

> **⚠️ Disclaimer:** Rooting voids your warranty, trips the Knox counter (Samsung Pay / Secure Folder may stop working), and can brick your device if done incorrectly. Follow every step carefully and back up your data first. The author is not responsible for any damage.

A complete, Linux-native guide to unlocking the bootloader and rooting the Samsung Galaxy Tab A7 Lite (SM-T220) using **Magisk** and **heimdall**, without needing Windows or Odin.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Device Info](#device-info)
- [Warnings](#warnings)
- [Phase 0 — Download Firmware](#phase-0--download-firmware)
- [Phase 1 — Extract boot.img](#phase-1--extract-bootimg)
- [Phase 2 — Patch boot.img with Magisk](#phase-2--patch-bootimg-with-magisk)
- [Phase 3 — Unlock Bootloader](#phase-3--unlock-bootloader)
- [Phase 4 — Flash Patched Boot](#phase-4--flash-patched-boot)
- [Phase 5 — Verify Root](#phase-5--verify-root)
- [Optional — Remove Bootloader Warning](#optional--remove-bootloader-warning)
- [Optional — LSPosed / Zygisk](#optional--lsposed--zygisk)
- [Recovery — Unbrick / Restore Stock](#recovery--unbrick--restore-stock)
- [Field Notes (actual run)](#field-notes-actual-run)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

---

## Overview

This guide covers the full root flow on a Linux PC:

1. Download official Samsung firmware (via `samloader-rs`).
2. Extract and patch `boot.img` with Magisk.
3. Unlock the bootloader (wipes data).
4. Flash the patched boot image with `heimdall`.
5. Verify root and (optionally) install LSPosed.

No Windows, no Odin, no VM required.

## Quick start (TL;DR)

```text
1. Download firmware  →  samloader download -m SM-T220 -r INS ...
2. Extract boot.img    →  tar -xf AP_*.tar.md5 boot.img.lz4 && lz4 -d boot.img.lz4 boot.img
3. Patch with Magisk   →  Magisk app → Install → Select and Patch a File
4. Unlock bootloader   →  Download Mode → Device Unlock (wipes data)
5. Flash patched boot  →  heimdall flash --boot magisk_patched-*.img
6. Factory data reset  →  Android Recovery → Factory data reset
7. Verify root         →  adb shell su -c "id"  →  uid=0(root)
```

If any step fails, jump to [Troubleshooting](#troubleshooting) or [Field Notes](#field-notes-actual-run).

## Prerequisites

### Hardware
- Samsung Galaxy Tab A7 Lite **SM-T220** (Wi-Fi). Carrier-locked US variants (SM-T227U) may not be rootable via this method.
- USB cable (data-capable).
- Linux PC with internet access.

### Software (install before starting)

```bash
# Arch / Manjaro
sudo pacman -S adb fastboot heimdall lz4 p7zip unzip
# heimdall udev rules (run once):
samloader fix-usb   # or use the bundled fix-usb
```

For Debian/Ubuntu:
```bash
sudo apt install adb fastboot heimdall-flash lz4 p7zip-full unzip
```

Additional tools (download separately):
- **samloader-rs** — https://github.com/topjohnwu/samloader-rs/releases (prebuilt Linux binary)
- **Magisk APK** — https://github.com/topjohnwu/Magisk/releases

### Knowledge
- Basic terminal usage.
- Comfortable with the risk of data loss.

## Device Info

| Property | Value |
|---|---|
| Model | SM-T220 (gta7litewifi) |
| Android | 14 |
| Build / PDA | T220XXSAEYE4 |
| Region / CSC | INS (India) |
| Bootloader binary | A (10) |
| OEM Unlock | must be ON |

Check your own values:
```bash
adb shell getprop ro.product.model
adb shell getprop ro.build.display.id
adb shell getprop ro.csc.sales_code
adb shell getprop ro.boot.verifiedbootstate   # green = locked
```

## Warnings

- **Data wipe:** unlocking the bootloader erases all user data.
- **Knox:** tripped permanently; Samsung Pay, Secure Folder and warranty are affected.
- **Anti-rollback:** bootloader binary ratchet — once on binary A (10), you cannot flash older firmware.
- **Match builds:** only flash a patched boot whose build matches your device's current build.
- **Battery:** keep the tablet charged above 50% throughout.

---

## Phase 0 — Download Firmware

We use `samloader-rs` to fetch official firmware directly from Samsung's servers.

```bash
mkdir -p ~/a7lite/fw
cd ~/a7lite/fw

# Check available versions (optional):
samloader check-update -m SM-T220 -r INS -a

# Download latest stable firmware:
samloader download -m SM-T220 -r INS \
  -v "T220XXSAEYE4/T220ODMAEYE4/T220XXSAEYE4/T220XXSAEYE4" \
  -d ~/a7lite/fw -j 2
```

> Replace `INS` with your region code and the version string with your build if different. The download is ~4–6 GB.

> ⚠️ **Do NOT download into `/tmp` on RAM-backed systems.** If `/tmp` is a tmpfs, the 4–6 GB download fills RAM and the process dies with `SIGBUS`/`Killed`. Point `-d` at a real disk with ≥10 GB free.

**Verify the download before using it** (a truncated zip looks fine until you extract it):
```bash
7z t *.zip          # must end with "Everything is Ok"
```

Extract:
```bash
7z x *.zip -o fw_extracted "AP_*.tar.md5"
ls -lh fw_extracted/AP_*.tar.md5
```

## Phase 1 — Extract boot.img

```bash
cd ~/a7lite/fw/fw_extracted

# Extract boot.img.lz4 from the AP tar:
tar -xf AP_*.tar.md5 boot.img.lz4

# Decompress:
lz4 -d boot.img.lz4 boot.img
ls -lh boot.img
```

## Phase 2 — Patch boot.img with Magisk

### 2.1 Install Magisk on the tablet
```bash
adb install Magisk-v31.1.apk
```

### 2.2 Patch boot.img
```bash
# Push boot.img to tablet:
adb push boot.img /sdcard/Download/boot.img
```

On the tablet:
1. Open **Magisk** app.
2. Tap **Install** → **Select and Patch a File**.
3. Choose `/sdcard/Download/boot.img`.
4. Magisk writes `magisk_patched-<hash>.img` to `/sdcard/Download/`.

Pull it back:
```bash
adb pull /sdcard/Download/magisk_patched-*.img ~/a7lite/
ls -lh ~/a7lite/magisk_patched-*.img
```

## Phase 3 — Unlock Bootloader

> ⚠️ This wipes all data. Back up first.

Prerequisites:
- OEM Unlock toggle is ON in Developer options.
- If the toggle is missing, use the "date trick" (see XDA thread) or wait 24–48 h after a factory reset + minimal setup.

Steps:
1. Power off the tablet.
2. Hold **Vol Up + Vol Down**, then plug in the USB cable. Keep holding until the Download Mode screen appears.
3. Long-press **Vol Up** to enter **Device Unlock** mode.
4. Press **Vol Up** to confirm. Data is wiped; the tablet reboots.

After reboot, complete minimal setup, re-enable Developer options + USB debugging.

Verify the unlock:
```bash
adb shell getprop ro.boot.verifiedbootstate
# → orange   (green = still locked)
```

## Phase 4 — Flash Patched Boot

### 4.1 Boot to Download Mode
Power off → **Vol Up + Vol Down + USB** → warning screen → press **Vol Up** to continue → you land on the actual **Downloading...** screen.

> ⚠️ You must press **Vol Up** on the warning screen to *enter* Download Mode. Stopping at the warning screen is not enough.

Verify heimdall sees it:
```bash
heimdall detect
# → Device detected
```

### 4.2 Flash

> ⚠️ **Partition names are case-sensitive and device-specific.** The SM-T220 PIT partition is **`boot`** (lowercase), *not* `BOOT`. Using `--BOOT` fails with `Partition "BOOT" does not exist in the specified PIT`.

Dump and inspect the PIT first if unsure:
```bash
heimdall print-pit --no-reboot > pit.txt
grep "Partition Name" pit.txt | grep -iE "boot|recovery"
# Partition Name: boot
# Partition Name: boot_para
# Partition Name: recovery
```

Flash:
```bash
cd ~/a7lite
heimdall flash --boot magisk_patched-*.img
# ... boot upload successful → Rebooting device...
```

If the device fails to boot afterwards, also flash stock vbmeta from the firmware:
```bash
heimdall flash --vbmeta fw/fw_extracted/vbmeta.img
```

> 💡 **If the handshake fails** (`ERROR: Failed to send handshake!` / `libusb error -7`), the Download Mode session is stale. Fully power off (hold Power 10–15 s), re-enter Download Mode fresh, and flash immediately — do **not** run another `print-pit`/`download-pit` in between.

### 4.3 First boot after flashing (expected "corruption" screen)

After a successful flash, the tablet boots to **Android Recovery** with:

```
Can't load Android system. Your data may be corrupt.
...
Try again
Factory data reset
View recovery logs
```

This is **normal** — the patched boot no longer matches the old encrypted `/data`. Select **Factory data reset** → confirm → let it wipe and reboot. (Data is wiped again; your earlier backup still stands.)

First boot after the reset can take **10–15 minutes** on this MediaTek tablet. Keep it plugged in. If it is still on the Samsung logo after ~15 min, force-reboot once and wait again.

Reboot manually if needed:
```bash
heimdall reboot
```

## Phase 5 — Verify Root

```bash
adb shell su -c "id"
# Expected: uid=0(root) gid=0(root)
```

Or open the Magisk app — it should show **Installed** and a **Superuser** tab. Root persists across reboots.

### Granting root to apps (Magisk 31.1)

Magisk 31.1 does **not** show an interactive pop-up for new apps. A fresh app has a default policy of **Deny**, so `su` requests are rejected silently (`Magisk: su: request rejected (<uid>)` in logcat) until you grant it manually:

1. Open the **Magisk** app → **Superuser** tab.
2. Tap the **+** (bottom-right).
3. Find the app (or **Shell** for ADB root) and tap its row to toggle it to **granted** (green).
4. Re-run the app's root check / `adb shell su -c id`.

Verify with a root-checker app (e.g. "Root Checker") — it should report **Root Access Verified**.

> Note: `adb shell su -c id` returning `uid=0(root)` confirms ADB root as well. If it returns `Permission denied`, grant **Shell** (uid 2000) in the same Superuser screen.

---

", "path">
/mnt/0946E88701BE265B/droid/a7lite/ROOTING_GUIDE.md

## Verification checklist

Tick these off before you consider the device rooted:

- [ ] `adb shell getprop ro.boot.verifiedbootstate` → `orange`
- [ ] Magisk app shows **Installed 31.1 (31100)** and **Ramdisk: Yes**
- [ ] `adb shell su -c "id"` → `uid=0(root) gid=0(root)`
- [ ] Root-checker app reports **Root Access Verified**
- [ ] Root survives a reboot (`adb shell su -c id` still works after reboot)
- [ ] (Optional) `magisk -v` from a root shell returns `31.1:MAGISK:R`

## Optional — Remove Bootloader Warning

Removes the red "custom OS / unlocked bootloader" screen on boot.

1. Install Termux on the tablet.
2. Download `up_param.tar` (from the XDA thread attachments) to `/sdcard/Download/up_param.tar`.
3. In Termux:
   ```bash
   su
   cd /
   dd if=/storage/emulated/0/Download/up_param.tar of=/dev/block/platform/bootdevice/by-name/up_param
   ```
4. Reboot.

## Optional — LSPosed / Zygisk

1. Magisk settings → enable **Zygisk** and **Enforce DenyList** → configure DenyList (add Google Play Services if needed). Reboot to apply.
2. Download LSPosed (zygisk build) from GitHub.
   - LSPosed (original): https://github.com/LSPosed/LSPosed/releases (supports Android 8.1 ~ 14)
   - **Vector (JingMatrix fork, recommended for Magisk 31.1+):** https://github.com/JingMatrix/LSPosed/releases (supports Android 8.1 ~ 16, handles SEPolicy correctly on newer Magisk)
3. Copy the zip to the tablet.
4. Magisk → **Modules** → **Install from storage** → select the zip → **Reboot**.
5. Reboot; LSPosed adds a home-screen shortcut (package `org.lsposed.manager`).

> Note: if the LSPosed Manager app does not appear after reboot, install it manually:
> ```bash
> adb shell 'su -c "cat /data/adb/modules/zygisk_lsposed/manager.apk"' > manager.apk
> adb install manager.apk
> ```
> (Package name: `org.lsposed.manager`.)

> ⚠️ **Magisk 31.1 SEPolicy issue:** LSPosed/Vector may show "Partially activated" + "SEPolicy is not loaded properly" because Magisk 31.1 does not apply module `sepolicy.rule` files at boot. Fix without reboot:
> ```bash
> adb shell 'su -c "magiskpolicy --live --apply /data/adb/modules/zygisk_lsposed/sepolicy.rule"'
> # Persist across reboots:
> adb shell 'su -c "cat > /data/adb/service.d/99_lsposed_sepolicy.sh <<EOF
> #!/system/bin/sh
> magiskpolicy --live --apply /data/adb/modules/zygisk_lsposed/sepolicy.rule
> EOF
> chmod 755 /data/adb/service.d/99_lsposed_sepolicy.sh"'
> ```
> Remove the service.d script if you uninstall the module.

---

## Recovery — Unbrick / Restore Stock

If the device bootloops or won't boot, flash full stock firmware:

```bash
cd ~/a7lite/fw/fw_extracted

# heimdall (case-sensitive partition names from the PIT):
heimdall flash \
  --bl   BL_*.tar.md5 \
  --ap   AP_*.tar.md5 \
  --csc  CSC_*.tar.md5

# or, simpler — samloader can flash full packages in one shot:
samloader flash -b BL_*.tar.md5 -a AP_*.tar.md5 -s CSC_*.tar.md5
```

> The SM-T220 has no separate `CP`/modem partition, so `--cp` is unnecessary.

Alternatively, use Odin on a Windows PC with the same firmware.

---

## Field Notes (actual run)

Real issues hit while doing this on SM-T220 / Android 14 / `T220XXSAEYE4` (INS), and how they were resolved. Useful when something doesn't match the "happy path" above.

1. **`/tmp` was a 3.7 GB tmpfs.** Downloading ~4.5 GB there filled RAM → `SIGBUS` / `Killed by SIGBUS`. Fix: download to a real disk (`/mnt/...`) with plenty of free space.
2. **First download truncated** at 4.75 GB (`7z t` → "Unexpected end of archive"). Fix: `--force` re-download; always `7z t` before extracting.
3. **`heimdall flash --BOOT` failed** — PIT uses lowercase `boot`. Fix: `heimdall flash --boot ...`.
4. **`Failed to send handshake` / `libusb error -7`** — stale download-mode session after running `download-pit`. Fix: force power-off, re-enter Download Mode, flash immediately.
5. **After flashing, device booted to Android Recovery** ("Can't load Android system"). This is expected on Samsung after a patched boot; **Factory data reset** was required.
6. **First boot after reset is slow** (10–15 min on this SoC). Keep it plugged in.
7. **`adb` showed `unauthorized`** after each unlock/setup — accept the RSA "Allow USB debugging" prompt (tick "Always allow").

8. **`su` requests rejected / root checker shows "no root"** — Magisk 31.1 defaults new apps to **Deny** and does not pop up a prompt. Open Magisk → **Superuser** → **+** → tap the app (and **Shell** for ADB) to grant. After granting, `adb shell su -c id` returns `uid=0(root)` and the root checker reports "Root Access Verified".
9. **Magisk logs** are saved to `/sdcard/Download/magisk_log_*.log` when you tap "Save log" in the app; pull them with `adb pull /sdcard/Download/magisk_log_*.log`.

### Files used in this run", "path">
/mnt/0946E88701BE265B/droid/a7lite/ROOTING_GUIDE.md

| File | Purpose |
|---|---|
| `fw/SM-T220_4_..._fac.zip` | Official firmware (4.5 GB) |
| `fw/extracted/AP_T220XXSAEYE4_...tar.md5` | Contains `boot.img` |
| `fw/extracted/boot.img` | Stock boot (32 MB) |
| `fw/extracted/vbmeta.img` | Stock vbmeta (7.3 KB) |
| `magisk_patched-31100_Uuo1o.img` | Patched boot flashed to `boot` |

---

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `heimdall detect` fails | Device not in Download Mode, or missing udev rules. Run `samloader fix-usb` / install rules, replug. |
| `Failed to send handshake` / `libusb error -7` | Stale Download Mode session. Force power-off (hold Power 10–15 s), re-enter Download Mode fresh, flash immediately. |
| `Partition "BOOT" does not exist in PIT` | Partition names are lowercase on this device — use `--boot`, not `--BOOT`. Dump PIT with `heimdall print-pit`. |
| `adb devices` empty | USB debugging off, or unauthorized. Re-enable in Developer options; accept RSA prompt. |
| OEM Unlock toggle missing | Use the date trick (XDA Part I) or wait 24–48 h after factory reset + minimal setup + Wi-Fi registration. |
| Download dies with `SIGBUS` / `Killed` | Output dir is on a full tmpfs/RAM disk. Download to a real disk with ≥10 GB free. |
| Zip extract fails with "Unexpected end of archive" | Truncated download. Re-download with `--force` and verify with `7z t`. |
| Recovery: "Can't load Android system" | **Expected** after flashing patched boot. Select **Factory data reset**, let it wipe and boot. |
| Stuck on Samsung logo > 15 min | First boot is slow; force-reboot once. If it repeats, flash stock `vbmeta` or full stock firmware. |
| Root checker says "no root" / `su: request rejected (<uid>)` | New apps default to Deny in Magisk 31.1. Open Magisk → Superuser → **+** → tap the app row to grant. Grant **Shell** too for ADB root. |
| `adb shell su -c id` → "Permission denied" | Shell (uid 2000) not granted. Magisk → Superuser → **+** → grant **Shell** (search "adb"). |
| `fastboot devices` empty | Expected on Samsung; use Download Mode + heimdall/Odin, not fastboot. |
| Download Mode stuck at "SetupConnection" | Run Odin/heimdall only while device is in Download Mode, not while booted. |

## FAQ

**Q: Do I need to update to the latest firmware first?**
A: No. Root on your current build if a matching patched boot exists (or make your own). Updating first risks losing OEM Unlock and the binary ratchet.

**Q: Should I log into Google/Samsung before rooting?**
A: No. Bootloader unlock wipes data; signing in first triggers FRP and can lock you out. Set up accounts after rooting.

**Q: Can I re-lock the bootloader later?**
A: Not recommended — re-locking a rooted/modified device can brick it.

**Q: Does this work on SM-T225 (LTE)?**
A: Yes, same process but use T225 firmware and a T225-matched patched boot.

**Q: Is root persistent?**
A: Yes, root survives reboots. Magisk re-patches on OTA? OTAs will break root — re-root after updating.

## Credits

### Guides & tutorials
- XDA thread: [TUTORIAL] How To Unlock & Root Tab A7 Lite T220/T225 — https://xdaforums.com/t/tutorial-how-to-unlock-root-tab-a7-lite-t220-t225-install-lsposed-magisk-mods.4406933/
- XDA thread: [GUIDE] How to remove unlocked bootloader warning in Galaxy Tab A7 Lite — https://xdaforums.com/t/guide-how-to-remove-unlocked-bootloader-warning-in-galaxy-tab-a7-lite.4400927/
- Andrew Metzger's blog — https://andrew.mtz.gr/posts/rooting-galaxy-tab-a7-lite
- Magisk Guide (unofficial) — https://magiskguide.com
- DroidWin: remove bootloader warning on Samsung — https://droidwin.com/remove-unlock-bootloader-warning-on-samsung-galaxy-s20-s20-ultra-fe/

### Tools
- Magisk — https://github.com/topjohnwu/Magisk
- samloader-rs — https://github.com/topjohnwu/samloader-rs
- heimdall (grimler fork) — https://git.sr.ht/~grimler/Heimdall
- lz4 — https://github.com/lz4/lz4
- 7-Zip — https://www.7-zip.org/

### Frameworks & modules
- LSPosed — https://github.com/LSPosed/LSPosed
- ZygiskNext — https://github.com/LSPosed/ZygiskNext
- samsung-mediatek/mediatek-clean-boot — https://github.com/samsung-mediatek/mediatek-clean-boot

### Firmware sources
- SamFw — https://samfw.com/firmware/SM-T220
- SamSony — https://samsony.net/en/firmwares/samsung/SM-T220
- Samsung official (via samloader-rs)

### up_param.tar (bootloader warning removal)
- XDA attachment `up_param-tar.5710083` — https://xdaforums.com/attachments/up_param-tar.5710083/

## Contributing

Found an error, a new firmware build, or a device variant that needs different steps? Open an issue or PR. Please include:
- Device model + region (CSC) + build number (`ro.build.display.id`)
- Magisk version
- The full error message / logcat snippet
- Steps to reproduce

## License

MIT — see [LICENSE](LICENSE).

---

> **Note:** This guide is provided as-is. Rooting is risky; proceed at your own risk.
path: /mnt/0946E88701BE265B/droid/a7lite/ROOTING_GUIDE.md