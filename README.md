# Rooting Samsung Galaxy Tab A7 Lite (SM-T220) on Linux

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A complete, Linux-native guide to unlocking the bootloader and rooting the Samsung Galaxy Tab A7 Lite (SM-T220) using **Magisk** and **heimdall**, without needing Windows or Odin.

📖 **Full guide:** [ROOTING_GUIDE.md](ROOTING_GUIDE.md)

📋 **XDA forum post (BBCode):** [XDA_POST.txt](XDA_POST.txt)

## Contents

| File | Purpose |
|---|---|
| `ROOTING_GUIDE.md` | Full step-by-step guide |
| `XDA_POST.txt` | BBCode version ready to paste into XDA |
| `LICENSE` | MIT license |
| `magisk_patched-31100_Uuo1o.img` | Patched boot flashed to `boot` (build T220XXSAEYE4, INS) |
| `fw/extracted/boot.img` | Stock boot (32 MB) |
| `fw/extracted/vbmeta.img` | Stock vbmeta (7.3 KB) |
| `fw/extracted/up_param.bin` | Original up_param (for restoring bootloader warning) |

## Quick summary

1. Download firmware via `samloader-rs`
2. Extract & patch `boot.img` with Magisk
3. Unlock bootloader (wipes data)
4. Flash patched boot with `heimdall flash --boot ...`
5. Factory data reset → verify root

## Disclaimer

Rooting voids your warranty, trips Knox, and can brick your device. Follow carefully and back up first. The author is not responsible for any damage.

## License

MIT — see [LICENSE](LICENSE).