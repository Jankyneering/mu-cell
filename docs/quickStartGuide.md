# Quick Start Guide

This gets a µCell board running on a Raspberry Pi, from a blank SD card to working radio software.

If you would rather build the driver by hand instead of running an install script, see [buildDriver.md](buildDriver.md).

## Contents

- [What you need](#what-you-need)
- [Part 1: Install the board and driver](#part-1-install-the-board-and-driver)
  - [1. Flash and boot](#1-flash-and-boot)
  - [2. Run the install script](#2-run-the-install-script)
  - [3. Verify the driver](#3-verify-the-driver)
- [Part 2: Install and configure your radio software](#part-2-install-and-configure-your-radio-software)
  - [Flowstation](#flowstation)
  - [Tetra-Bluestation](#tetra-bluestation)
  - [MMDVM-IQ](#mmdvm-iq)
  - [Other SoapySDR software](#other-soapysdr-software)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)

---

## Equiment needed

- A Raspberry Pi 3, 4, 5, or Zero 2W
- A µCell BB board connected to the Pi
- A microSD card with Raspberry Pi OS Lite (64-bit)

Fit the board before you start. The device tree overlay only loads when the Pi detects the µCell on the GPIO header, so a Pi booted without the board will behave as though nothing is installed.

---

## Part 1: Install the board and driver

This part is the same regardless of which radio software you plan to run.

### 1. Flash and boot

Flash Raspberry Pi OS Lite (64-bit) to your microSD card using the [Raspberry Pi Imager](https://www.raspberrypi.com/software/). Enable SSH in the imager settings before writing, then boot the Pi and connect over SSH.

### 2. Run the install script

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jankyneering/mu-cell/main/install-mu-cell-sw.sh)"
```

The script will:

- Install the required system dependencies
- Clone the µCell baseband driver repository
- Build and install the device tree overlay
- Build and install the SoapyMuCell driver

> A reboot is required after the first install so the device tree overlay loads. The script will prompt you. Run it again after rebooting to verify the driver.

### 3. Verify the driver

After the reboot, the script probes the driver for you. To check it yourself at any point:

```bash
SoapySDRUtil --probe=driver=mucell
```

The driver reports the EEPROM contents during initialisation, including vendor, product, serial, and whether the signature matched a known key. A warning about an unsigned or unrecognised board does not stop it from working. See the [FAQ](faq.md) for what that means.

Once the probe succeeds, the board is ready and any SoapySDR application can use it.

---

## Part 2: Install and configure your radio software

Each of these is a separate project with its own releases and its own documentation. Pick the one you want, install it from upstream, then use the notes here for the µCell-specific parts.

### Flowstation

TETRA base station software with a wide feature set, at the cost of some stability. It publishes pre-built binaries that already work with µCell, which makes it the fastest route to a running cell.

On the Pi, fetch the binary and make it executable:

```bash
wget https://github.com/razvanzeces/flowstation/releases/download/v0.4.0/bluestation-bs
chmod +x bluestation-bs
```

Check the [releases page](https://github.com/razvanzeces/flowstation/releases) for a newer version than the one above.

Generate a `config.toml` for your cell with the configuration tool:

https://bluestation.russel053.com/

Either copy/paste the contents of the generated file via SSH (while editing config.toml for instance), or transfer the file via scp:

```bash
scp config.toml <user>@<pi-address>:~/
```

Then start the base station:

```bash
./bluestation-bs ./config.toml
```


### Tetra-Bluestation

Stable TETRA base station software with a smaller feature set.

µCell support currently lives on the testing branch and is expected to land in main. Get it from the [project repository](https://github.com/MidnightBlueLabs/tetra-bluestation), and build from source. Pi 5 and earlier Pi models use different builds, so pick the matching asset.

It uses the same binary name and the same configuration format as Flowstation, so the configuration tool above works for it too and the command to start it is identical:

```bash
./bluestation-bs ./config.toml
```

Keep them in separate directories if you want both on the same Pi.

### MMDVM-IQ

Multi-mode digital voice: FM, DMR, D-Star, YSF, P25, and others. Support is in progress.

Follow the build and configuration instructions in the [upstream repository](https://github.com/g4klx/MMDVM-IQ), and point it at the SoapySDR device `driver=mucell`.

### Other SoapySDR software

The µCell BB registers as a standard SoapySDR device, so anything that speaks SoapySDR can use it. With the board fitted and the driver from Part 1 installed, most sofware will list it in the available devices. 

| Software | Status |
|---|---|
| GQRX | Supported. The board appears in the device dropdown, select it and go. |
| CubicSDR | Tested working. Picked up at startup. |
| GNU Radio | Should work through the Soapy Source and Sink blocks. Lightly tested so far. |
| SDR++ | Needs a dedicated source module, which has not been written yet. |

If you ever do need to name the device by hand, for a GNU Radio block or a command line tool, the string is:

```
driver=mucell
```

<!-- TODO: this section is the extension point. When a new mode or stack is brought up, add a sibling heading here with a link upstream. -->
---

## Updating

Re-run the install script to update the driver and overlay:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jankyneering/mu-cell/main/install-mu-cell-sw.sh)"
```

It checks the driver repository for new commits and rebuilds only if there are any. If nothing has changed, it says so and exits.

This is also how you pick up new EEPROM signing keys. If a board bought from the store started warning that it is not genuine, a driver update is usually the fix.

Radio software is updated through its own project, following whatever process that project uses.

---

## Troubleshooting

The driver probe fails right after install
: Reboot. The overlay is only read at boot. Re-run the install script afterwards.

The probe fails after a reboot
: Check that the board is seated properly on the GPIO header. The overlay will not load without it. Look for the HAT in the device tree with `ls /proc/device-tree/hat/`. If that directory is missing, the Pi is not seeing the EEPROM.

The driver warns that no public keys are compiled in
: The driver was built without any `.pem` files in `public_keys/`. It still works. Rebuild with the keys present if you want signature checking.

The radio starts but the frequency is off
: If you cut JP1 to use an external reference, check that the external source is present and at the right level. See [hardware.md](hardware.md#external-clock). If you want to use the internal source and need better accuary, compensate it in software (most implement a ppm correction line in the configuration files). 
