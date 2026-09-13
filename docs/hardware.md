# Hardware

The `hardware` directory contains the open hardware designs for the µCell ecosystem. Each board is a modular building block, so a system can be anything from a minimal hotspot to a more complete base station.

The platform is SDR-based and built around the SX1255 transceiver. The µCell driver exposes the board through SoapySDR, which is what lets it serve TETRA, DMR, D-Star, YSF, P25, analog FM, and whatever else gets added later without hardware changes.

Design files include schematics, PCB layouts, production outputs, case models, and the documentation needed for assembly and integration.

## Contents

- [Design goals](#design-goals)
- [µCell BB (Baseband)](#µcell-bb-baseband)
  - [Connectors and headers](#connectors-and-headers)
- [µCell Display](#µcell-display)
- [µCell PA Mini](#µcell-pa-mini)
- [Adding an amplifier](#adding-an-amplifier)
- [Cases](#cases)

---

## Design goals

- Modular architecture that scales from small hotspot deployments to higher power base stations
- SDR-based design that is not tied to any single radio mode
- Compatibility with Bluestation, Flowstation, MMDVM-IQ, and general SoapySDR software
- Readily available components wherever the RF performance allows it
- Reproducible designs suitable for small-scale manufacturing

---

## µCell BB (Baseband)

This is the board the project is built around, and the only one currently in production. It works on its own as a compact hotspot, and acts as the baseband and RF front-end when a PA board is added later.

<p align="center">
  <img src="./mucell-pic.jpg" width="600" alt="µCell BB board">
</p>

Features:

- SX1255 transceiver with RF filtering and matching network
- 38.4 MHz TCXO reference, 0.5 ppm, with an external clock option
- EEPROM for HAT identification, optionally signed
- U.FL connectors for TX, RX, and external clock
- Header for a standard SSD1306 OLED
- 12-pin IDC expansion connector
- Raspberry Pi HAT form factor, compatible with the Pi 3, 4, 5, and Zero 2W

Measured specifications (v1.0):

| Parameter | Value |
|---|---|
| Frequency coverage | 400 to 510 MHz |
| Rated output guaranteed | 430 to 440 MHz |
| Sample rates | 25, 50, 75, 150, 300, 600 kHz |
| Maximum signal bandwidth | 500 kHz |
| Tx power (Pi/4 DQPSK) | 0 to 3 dBm |
| Rx sensitivity (TETRA T1) | -117 dBm |

Coverage is set by the SX1255, which is specified for 400 to 510 MHz. The matching network is tuned for the 70 cm band, rated transmit power is guaranteed over 430 to 440 MHz. The board will tune and receive across the wider range, with output falling off towards the edges.

Sample rates are the reference clock divided down, following from the 38.4 MHz TCXO. The SX1255 digitises I and Q with 1-bit delta-sigma converters and decimates to the requested rate.

The SX1255 is designed for mobile devices, and its selectivity reflects that. On the bench, an interfering signal at -40 dBm and 10 MHz offset from the receive frequency is enough to start degrading the rated sensitivity. That is fine for a board transmitting a few dBm into its own antenna. It stops being fine as soon as you put an amplifier behind it. See [adding an amplifier](#adding-an-amplifier).

<!-- TODO: add supply current, and a measured figure for a non-TETRA mode, given the project is not TETRA-only. -->

Identification values written to the EEPROM:

| Field | Value |
|---|---|
| Vendor | Jankyneering |
| Product | µCell-BB |
| Product ID | `0x1255` |
| Current supply | 5000 mA |
| Device tree blob | `mu-cell-bb_raspberrypi` |

Boards sold by Jankyneering are individually tested on a radio test set to validate RF performance before shipping. See [muCellBBManufacture.md](muCellBBManufacture.md) if you want to build your own.

### Connectors and headers

#### External clock

A third U.FL connector accepts an external reference in place of the onboard TCXO. Useful if you have a GPSDO or a house standard, or if your application needs better than 0.5 ppm.

Boards ship using the onboard TCXO. To switch to the external input, cut JP1 on the back of the board and bridge the jumper to the external clock side.

Match the part you are replacing. The onboard reference is a Seiko Epson TG2016SMN 38.4000M-MCGNNM3: 38.4 MHz, sine output, ±0.5 ppm, running from the board's 3.3 V rail. An external source should be at 38.4 MHz with a comparable output level, and there is little point switching unless it is better than 0.5 ppm. The TCXO datasheet gives the exact output amplitude to aim for.

> Make sure your external source is present and at the right level before you cut, or the board will have no reference at all.

<!-- TODO: add a photo of JP1 on the back of the board -->

#### OLED display header

A 4-pin header for a standard 0.96 inch SSD1306 OLED, wired to the Pi's I2C bus.

![SSD1306 OLED header schematic](./docs/oled-header.png)

| Pin | Signal |
|---|---|
| 1 | GND |
| 2 | VCC (+5V) |
| 3 | SCL |
| 4 | SDA |

There is no µCell software support for the display yet. It sits on the standard Pi I2C bus, so any existing SSD1306 library works in the meantime.

#### Expansion connector (J5)

A 2x6 12-position IDC connector on 2.54 mm pitch, for accessories and future modules, including the µCell Display. It breaks out power, the TX and RX lines, I2C, and two spare GPIOs. Every signal line goes through a 100R series resistor.

![J5 expansion connector schematic](./docs/io-header.png)

| Pin | Signal |
|---|---|
| 1 | +3V3 (from Pi) |
| 2 | +5V |
| 3 | RX_EN |
| 4 | TX_EN |
| 5 | TXD |
| 6 | RXD |
| 7 | SCL |
| 8 | SDA |
| 9 | GPIO04 |
| 10 | GPIO17 |
| 11 | GND |
| 12 | GND |

---

## µCell Display

A front panel module for builds that go into an enclosure, connecting through J5. The design is nearing completion.

Features:

- 0.96 inch SSD1306 OLED for status
- Rotary encoder for local control
- Status LEDs

<!-- TODO: add panel dimensions and a photo once the design is finalised -->

---

## µCell PA Mini

A low power RF front-end that extends the µCell BB. The design exists but there is still a fair amount of work left before it is ready to manufacture.

Planned features:

- Roughly 1 W RF power amplifier
- Receive path conditioning with an LNA
- Preselector filtering
- RF measurement and monitoring points

---

## Adding an amplifier

The µCell BB is a bare transceiver board. The matching network and filtering on it were designed to get the most output power and sensitivity out of the SX1255, and a board on its own has harmonics well within spec. Anything you put after it is your responsibility, and the SX1255 was designed for handheld and mobile equipment rather than for driving a power amplifier.

Two things matter once you amplify: linearity and filtering.

### Linearity

Modes with a non-constant envelope, TETRA among them, need a linear amplification chain. Constant-envelope modes such as FM and 4FSK are far more forgiving, so how much of this applies depends on what you are running.

The problem is rarely harmonic distortion. It is inter-channel interference, seen as increased adjacent channel power. As an amplifier is driven towards its P1dB point, the output level at which gain compression sets in, non-linear effects grow quickly. The carrier can still look clean while energy spreads into the channels either side of it.

A TETRA amplification stages usually follow these guidelines:

- Running far below P1dB, by oversizing the amplifier deliberately. A 10 W rated device producing 1 W of RF is a normal ratio.
- Using Class A or Class AB operation, which is one reason TETRA transmitter efficiency rarely exceeds about 20%.
- Adding a linearisation loop, often a Cartesian loop, which measures the distortion and pre-corrects the signal so the non-linear effects cancel out.

Those measures go together with tight filtering and closed loop power control. For lab, experimental, and amateur work, staying well below P1dB already gives acceptable results on its own.

The Bluestation documentation covers this in more depth and has worked examples: [Miscellaneous](https://github.com/MidnightBlueLabs/tetra-bluestation-docs/wiki/20-Miscellaneous).

### Filtering

Transmit filtering is the amplifier chain's job. 

Receive rejection matters just as much. The measured figure gives a sense of the margin available: a -40 dBm interferer 10 MHz away from the receive frequency already starts degrading rated sensitivity. Your own transmitter, amplified, is far stronger than that and far closer in frequency. Without proper rejection between the two paths, a duplexer or cavity filtering depending on what you are building, the receiver will be deaf whenever the transmitter is keyed.

None of this is exotic for anyone who has built a repeater before. It is worth saying plainly because the board is small and cheap enough to make a 100 W base station look like a matter of bolting on an amplifier, and it is not.


---

## Cases

3D printable case designs are in the `hardware` directory alongside the board files, under the same CC BY-SA 4.0 licence. They are designed to print without supports on a standard FDM machine.

<!-- TODO: give the exact path to the case models, the file formats provided (STL, STEP, source), and which Pi models each case fits -->

If you print one and find something that needs adjusting, a pull request with the change and a note on your print settings is welcome.
