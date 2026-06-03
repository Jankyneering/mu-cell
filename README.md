<h1 align="center">µCell</h1>

<p align="center">
	<img width="200" height="200" src="/docs/logos/mu-cell_logo.svg" alt="µCell logo">
</p>

<p align="center">An open-source SDR base station platform for TETRA and other digital radio modes.</p>

---

## Contents

- [Getting Started](#getting-started)
- [Hardware](#hardware)
- [Software](#software)
- [How to Contribute](#how-to-contribute)
- [Acknowledgements & License](#acknowledgements--license)

---

## Getting Started

These steps get a µCell base station running on a Raspberry Pi.

### What you need

- A Raspberry Pi 3, 4, 5, or Zero 2W
- A µCell BB board connected to the Pi
- A microSD card with **Raspberry Pi OS Lite (64-bit)**

### 1. Flash and boot

Flash Raspberry Pi OS Lite (64-bit) to your microSD card using the [Raspberry Pi Imager](https://www.raspberrypi.com/software/). Enable SSH in the imager settings before writing, then boot the Pi and connect via SSH.

### 2. Run the install script

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jankyneering/mu-cell/main/install-mu-cell-sw.sh)"
```

The script will:
- Install all required system dependencies
- Clone and build the µCell baseband drivers
- Ask which software stack to install: **bluestation** (stable TETRA), **flowstation** (more features, less stable), or **MMDVM-IQ** (multi-mode digital radio)
- Download the correct binary for your Pi model and place it in your home directory

> A reboot is required after the first install to load the DTS overlay. The script will prompt you. Run it again after rebooting to verify the driver.

### 3. Configure the base station

Use the configuration tool at **https://bluestation.russel053.com/** to generate a `config.toml` for your base station. Copy it to your Pi's home directory.

### 4. Start the base station

```bash
./bluestation-bs ./config.toml
```

---

## Hardware

The `hardware` directory contains the open hardware designs for the µCell ecosystem. Each board is a modular building block, so systems can range from a minimal hotspot to a more complete base station.

The platform uses an SDR-based architecture built primarily around the SX1255 transceiver. The µCell driver is supported by Bluestation, Flowstation, and MMDVM-IQ, covering TETRA infrastructure as well as other analog and digital radio modes such as DMR, D-Star, YSF, and P25.

Design files include schematics, PCB layouts, fabrication outputs, and documentation required for assembly and integration.

### Design goals

- Modular architecture that scales from small hotspot deployments to higher power base stations
- SDR-based design supporting multiple digital radio modes
- Compatibility with Bluestation, Flowstation, and MMDVM-IQ software stacks
- Use of readily available components where possible
- Reproducible designs suitable for small-scale manufacturing

### Boards

#### µCell BB (Baseband)

Baseband and RF transceiver board based on the SX1255.

- SX1255 transceiver with RF filtering and matching network
- Stable reference clock
- EEPROM for HAT identification
- Operates standalone as a compact hotspot, or as the RF/baseband front-end when paired with a PA board

Measured specifications (v1.0):

| Parameter | Value |
|---|---|
| Tx Power (Pi/4 DQPSK) | 3–5 dBm |
| Rx Sensitivity (TETRA T1) | -117 dBm |

#### µCell PA Mini

Low power RF front-end designed to extend the µCell BB.

- ~1 W RF power amplifier
- Receive path conditioning with LNA
- Preselector filtering
- RF measurement and monitoring points

#### µCell PA 10W *(planned)*

Higher power RF front-end under investigation.

- ~10 W transmit output
- Improved filtering and thermal design
- Compatible with µCell BB control and RF interfaces

#### µCell Display *(planned)*

Optional front panel module for integrated deployments.

- Local system status display
- Control interface
- Integration with the BlueStation/µCell software stack

---

## Software

The `software` directory contains the components required to operate µCell hardware. It primarily aggregates upstream projects as git submodules, along with companion utilities specific to the µCell platform.

### Components

#### [µCell BB Drivers](https://github.com/Jankyneering/mu-cell-bb-drivers)

SoapySDR driver for the µCell baseband board. Provides the hardware abstraction layer used by Bluestation and other SDR software. Includes the DTS overlay for Raspberry Pi and the SoapyMuCell plugin.

#### [Tetra-Bluestation](https://github.com/MidnightBlueLabs/tetra-bluestation)

TETRA base station software implementing the TETRA protocol stack and base station behavior.

#### [Flowstation](https://github.com/razvanzeces/flowstation)

Alternative TETRA base station software with more features. Less stable than Bluestation but implements many more features.

#### [MMDVM-IQ](https://github.com/g4klx/MMDVM-IQ)

Multi-mode digital voice modem software supporting FM, DMR, D-Star, YSF, P25, and other modes. Uses the µCell driver via SoapySDR as its radio back-end.

#### µCell utilities

Supporting software for platform integration, including display and OLED drivers, system monitoring, hardware control helpers, and deployment scripts.

---

## How to Contribute

Contributions are welcome. For small fixes or documentation updates, feel free to open a pull request directly. For larger changes, open an issue first so the approach can be discussed. Keep pull requests focused and include a clear description of what changed and why.

---

## Acknowledgements & License

µCell builds on the work of several open-source projects:

- **Tatu Peltola ([tejeez](https://github.com/tejeez/))** — designer of the [SXCeiver](https://github.com/tejeez/sxxcvr), which provided early inspiration for compact SX1255-based SDR hardware.
- **Wouter Bokslag ([Midnight Blue](https://github.com/MidnightBlueLabs/)) and contributors** — authors of [TETRA-bluestation](https://github.com/MidnightBlueLabs/tetra-bluestation), which implements an open TETRA base station stack.

We also acknowledge the broader SDR and SoapySDR communities whose work enables hardware experimentation with modern radio systems.

Made with ❤️, lots of ☕️, and lack of 🛌

Hardware & Documentation published under **CreativeCommons BY-SA 4.0**

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/)

Software published under **GNU GPLv3**

[![License: GPL v3](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)
