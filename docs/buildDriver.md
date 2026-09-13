# Building the Drivers Manually

The [install script](quickStartGuide.md) does everything on this page for you. This is the same procedure done by hand, for anyone who would rather not pipe a script into bash, or who is porting the driver somewhere the script does not cover.

This page covers the device tree overlay and the SoapySDR driver, which is all µCell maintains. The radio software that sits on top is maintained by other projects, and their own documentation is the right place for build instructions. Once the driver is installed, any of them can reach the board through `driver=mucell`.

Every step below corresponds to a function in `install-mu-cell-sw.sh`, so you can read the script alongside this page.

## Contents

- [1. System dependencies](#1-system-dependencies)
- [2. Clone the driver repository](#2-clone-the-driver-repository)
- [3. Build and install the device tree overlay](#3-build-and-install-the-device-tree-overlay)
- [4. Build and install SoapyMuCell](#4-build-and-install-soapymucell)
- [5. Verify](#5-verify)
- [Next steps](#next-steps)

---

## 1. System dependencies

```bash
sudo apt update
sudo apt install -y --no-install-recommends \
  git make g++ cmake \
  libsoapysdr-dev soapysdr-tools libasound2-dev python3-soapysdr \
  libssl-dev clang llvm-dev libclang-dev
```

What these are for:

| Package group | Why |
|---|---|
| `git make g++ cmake` | Build toolchain |
| `libsoapysdr-dev soapysdr-tools python3-soapysdr` | SoapySDR headers, the `SoapySDRUtil` probe tool, and Python bindings |
| `libasound2-dev` | ALSA, used for the sample interface |
| `libssl-dev` | OpenSSL, required for EEPROM signature verification |
| `clang llvm-dev libclang-dev` | Needed by the build |

---

## 2. Clone the driver repository

```bash
git clone https://github.com/Jankyneering/mu-cell-bb-drivers ~/mu-cell-bb-drivers
```

The install script clones into `$HOME/mu-cell-bb-drivers`. The paths below assume the same.

To update an existing clone instead:

```bash
cd ~/mu-cell-bb-drivers
git fetch origin
git pull --ff-only
```

If the pull brings in changes, rebuild both the overlay and the driver before using the board again.

---

## 3. Build and install the device tree overlay

The overlay tells the Pi how to talk to the board. Without it, the driver has nothing to attach to.

Fit the µCell to the GPIO header before you go any further. The overlay is loaded from the HAT EEPROM at boot, so it will not load at all on a Pi with no board attached.

```bash
cd ~/mu-cell-bb-drivers/raspberry-pi-drivers/mu-cell-bb-dts
make overlay
sudo make install
```

`make overlay` compiles `mu-cell-bb_raspberrypi.dts` into a `.dtbo` in `build/`. `make install` copies it to the overlays directory, which is `/boot/firmware/overlays` on current Raspberry Pi OS and `/boot/overlays` on older releases. The Makefile detects which one you have.

Reboot now:

```bash
sudo reboot
```

The overlay is only read at boot, so nothing below will work until you have done this.

---

## 4. Build and install SoapyMuCell

```bash
cd ~/mu-cell-bb-drivers/SoapyMuCell
mkdir -p build
cd build
cmake ..
make
sudo make install
sudo ldconfig
```

During configuration, CMake scans `public_keys/` and embeds every `.pem` file it finds into `generated_keys.hpp`. Each key is named after its filename, so batch keys show up by name in the driver log. If the directory is empty, CMake prints a warning and the driver reports `NO_KEYS_COMPILED_IN` at runtime. That is not fatal, it just means signature checking is off.

---

## 5. Verify

```bash
SoapySDRUtil --probe=driver=mucell
```

On success the driver logs a line summarising the EEPROM, for example:

```
HAT EEPROM: Vendor="Jankyneering" Product="µCell-BB" UUID=... HW=1.0 Serial=... Auth=GENUINE (key: batch_001)
```

Possible `Auth` values and what they mean:

| Value | Meaning |
|---|---|
| `GENUINE` | Signature matched one of the compiled-in keys |
| `NO_SIGNATURE` | The EEPROM has no signature atom. Normal for boards you wrote yourself |
| `SIGNATURE_MISMATCH` | A signature is present but matches no known key. Often an out-of-date driver |
| `NO_KEYS_COMPILED_IN` | Built without any `.pem` files in `public_keys/` |
| `EEPROM_NOT_FOUND` | The Pi is not seeing the HAT EEPROM at all. Check the board is seated |

None of these block operation. The driver warns and carries on.

---

## Next steps

The driver is now installed and the board is a standard SoapySDR device. Install whichever radio software you want according to its own documentation, and point it at `driver=mucell`.

[quickStartGuide.md](quickStartGuide.md#part-2-configure-your-software) has a short configuration section for each stack we have tested, with links upstream.
