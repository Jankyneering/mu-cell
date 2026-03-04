<h1 align="center">µCell</h1>

<p align="center">
	<img width="200" height="200" margin-right="100%" src="/docs/logos/mu-cell_logo.svg" alt="µCell logo">
</p>

<p align="center">An open-source SDR base station.</p>

## Contents

- [Contents](#contents)
- [Hardware](#hardware)
- [Software](#software)
- [How to Contribute](#how-to-contribute)
- [Acknowledgements & License](#acknowledgements--license)

## Hardware

The `Hardware` directory contains the open hardware designs for the µCell ecosystem. Each board is developed as a modular building block so systems can range from a minimal hotspot to a more complete base station.

The platform is built around an SDR-based architecture. While it is primarily designed for TETRA experimentation and infrastructure using the Bluestation stack, the hardware can also support other digital radio modes depending on the software used.

Design files typically include schematics, PCB layouts, fabrication outputs, and documentation required for assembly and integration.

### Design goals

- Modular architecture allowing systems to scale from small hotspot deployments to higher power base stations  
- SDR-based design enabling experimentation with multiple digital radio modes  
- Compatibility with the TETRA-bluestation software stack  
- Potential support for other systems such as MMDVM-SDR or similar SDR-based radio frameworks  
- Use of readily available components where possible  
- Reproducible designs suitable for small-scale manufacturing  

### Boards

#### µCell BB (Baseband)

Baseband and RF transceiver board based on the SX1255.

Features:

- SX1255 transceiver  
- RF filtering and matching network  
- Stable reference clock  
- EEPROM for HAT identification  
- Designed to operate standalone as a compact hotspot  
- Acts as the RF/baseband front-end when paired with external PA boards  

#### µCell PA Mini

Low power RF front-end designed to extend the µCell BB.

Features:

- ~1 W RF power amplifier  
- Receive path conditioning including LNA  
- Preselector filtering  
- RF measurement and monitoring points  
- Intended for compact deployments where modest output power is sufficient  

#### µCell PA 10W (planned)

Higher power RF front-end under investigation.

Goals include:

- Approximately 10 W transmit output  
- Improved filtering and thermal design  
- Compatibility with µCell BB control and RF interfaces  

#### µCell Display (planned)

Optional front panel module for integrated deployments.

Intended features:

- Local system status display  
- Control interface  
- Integration with the BlueStation/µCell software stack for monitoring and configuration  

## Software

The `Software` directory contains the software components required to operate µCell hardware.

This folder primarily aggregates upstream projects as git submodules, along with additional companion utilities specific to the µCell platform.

Because µCell is built around an SDR architecture, multiple software stacks may be used depending on the desired radio mode.

### Components

#### [Tetra-Bluestation](https://github.com/MidnightBlueLabs/tetra-bluestation)

Main TETRA base station software responsible for implementing the TETRA protocol stack and base station behavior.

#### [SoapySX](https://github.com/tejeez/sxxcvr/tree/main/SoapySX)

SoapySDR driver used to interface the SX1255 transceiver with Bluestation and other SDR software.

This provides the SDR abstraction layer used by the base station software.

#### µCell utilities

Supporting software components for platform integration, which may include:

- Display/OLED drivers  
- System monitoring  
- Hardware control helpers  
- Deployment or configuration scripts  

These utilities are intended to simplify operating µCell hardware as an integrated system.

## How to contribute

Contributions to µCell are welcome. If you have improvements, fixes, documentation updates, or new ideas for either the hardware or software, feel free to open an issue to discuss it or submit a pull request directly. For larger changes, opening an issue first is recommended so the approach can be discussed.  
Please keep pull requests focused and include clear descriptions of the changes and any relevant documentation updates.

## Acknowledgements & License

µCell builds on the work of several open-source projects and contributors in the SDR and TETRA experimentation communities :

- Tatu Peltola ([tejeez](https://github.com/tejeez/))  
Designer of the [SXCeiver](https://github.com/tejeez/sxxcvr) hardware, which provided early inspiration for compact SX1255-based SDR radio hardware.

- Wouter Bokslag ([Midnight Blue](https://github.com/MidnightBlueLabs/)) and contributors  
Author of the [TETRA-bluestation](https://github.com/MidnightBlueLabs/tetra-bluestation-) project, which implements an open TETRA base station stack.

We also acknowledge the broader SDR and SoapySDR communities whose work enables hardware experimentation with modern radio systems.

Made with ❤️, lots of ☕️, and lack of 🛌  

Hardware & Documentation published under CreativeCommons BY-SA 4.0

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)  
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Software published under GNU GPLv3

[![License: GPL v3](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)  
[GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)
