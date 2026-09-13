# Manufacturing a µCell BB

Everything needed to have a µCell BB built is in this repository. This page covers ordering the boards, the component choices that actually matter, and writing the EEPROM afterwards.

Boards sold through [store.fredcorp.cc](http://store.fredcorp.cc/) are individually tested on a radio test set to validate RF performance before they ship. If you build your own, that verification step is on you, and the section on [testing](#testing-what-you-built) is worth reading before you order a large batch.

## Contents

- [The production package](#the-production-package)
- [Board settings](#board-settings)
- [Component selection](#component-selection)
- [Testing what you built](#testing-what-you-built)
- [Writing the EEPROM](#writing-the-eeprom)
- [Signing](#signing)
- [Support for boards you built yourself](#support-for-boards-you-built-yourself)

---

## The production package

Production outputs live under `/hardware/mu-cell-bb/<version>/production`. For the current revision that is:

```
/hardware/mu-cell-bb/v1.3/production
```

| File | Purpose |
|---|---|
| Gerber zip | Copper, mask, silkscreen, and drill data. Upload as-is |
| BOM CSV | Component list with LCSC part numbers |
| Designators CSV | Reference designator list for assembly |
| Positions CSV | Component positions and rotations |
| IPC netlist | Netlist for electrical test and for verifying the gerbers match the schematic |

Upload the gerber zip in the JLCPCB order form, then attach the BOM and positions files in the assembly step. The parts list uses LCSC numbers so the matching is automatic for most lines.

The IPC netlist is worth uploading too where the fab accepts it. It lets them catch a gerber that does not match the intended connectivity before anything is etched.

---

## Board settings

These are the settings used for the boards Jankyneering manufactures.

| Setting | Value |
|---|---|
| Layers | 4 |
| Thickness | 1.6 mm |
| Outer copper weight | 1 oz |
| Inner copper weight | 0.5 oz |
| Impedance control | None specified |
| Surface finish | ENIG recommended |

No controlled impedance was ordered. The RF traces were designed against the standard 4-layer 1.6 mm stackup, and the measured performance in [hardware.md](hardware.md) was achieved without it. Changing the layer count or the overall thickness changes the trace impedance, which shows up as lost output power and degraded sensitivity, so keep the stackup as listed rather than treating these numbers as defaults.

---

## Component selection

The BOM specifies parts rather than values for a reason. Assembly houses substitute freely when a line is out of stock, and for most of this board that is fine. For the RF path it is not.

The full list is in the BOM CSV in the production folder, with an LCSC number on every line. Look those numbers up rather than reading values off the schematic: the parts chosen carry tolerance, dielectric, and Q figures that a value alone does not capture. The categories below are the ones to check before approving any substitution.

### Reference clock

Y1 is a 38.4 MHz TCXO. Frequency accuracy and stability over temperature set the carrier accuracy of the whole radio, and several of the modes the board targets have demanding requirements there. The board is built with a 0.5 ppm part.

Any TCXO meeting the same specification works. What matters is the frequency, the stability figure, the output type and level the SX1255 expects, and the supply voltage. Do not substitute on frequency alone: a plain crystal, or a TCXO an order of magnitude looser, will pass a bench test and then drift out as the board warms up.

If you need better than the onboard part gives you, an external reference can be fed in through J3 instead. See [hardware.md](hardware.md#external-clock) for how to switch the board over.

### Inductors in the matching network and filters

Q factor is the parameter that matters, not just inductance. A part with the correct value but a lower Q will widen the filter response and eat transmit power.

L2 gives the standard to work to. It is a Coilcraft 0402CS-22NXGRW, 22 nH, with Q of 53 at 900 MHz and 53 at 1.7 GHz. That is a wirewound ceramic part, and a general-purpose multilayer 22 nH inductor is not a substitute for it even though a BOM matcher will treat them as the same line.

Check Q at your operating frequency rather than the datasheet headline figure, which is usually quoted much lower down, and make sure the self-resonant frequency sits well above the band of operation.

### Capacitors in the RF path

C3, C4, and C5 set the matching network, and C1, C2, C6, and C8 sit in the RF path. Use the parts the BOM lists.

C5 shows the level of part these lines need: a Murata GCM1555C1H6R8FA16D, 6.8 pF, C0G dielectric, 50 V, in 0402. C0G is the requirement, not a preference. X7R and X5R have voltage and temperature coefficients large enough to detune a matching network, and they are microphonic. A 6.8 pF X7R part is not a substitute even though a BOM line matcher will treat them as the same value.

Tolerance matters too, since loosening it spreads your performance across a batch.

### Everything else

Decoupling capacitors, pull-up resistors, LEDs, and the transistors tolerate substitution without much consequence. The EEPROM should be a 24LC256 or compatible part, since that is what the write tooling assumes.

---

## Testing what you built

At minimum, before calling a board good:

1. Check the supply rails.
2. Write the EEPROM, then confirm the Pi sees the HAT: `ls /proc/device-tree/hat/`
3. Probe the driver: `SoapySDRUtil --probe=driver=mucell`
4. Measure transmit power and receive sensitivity against the figures in [hardware.md](hardware.md).

Step 4 is the one that needs equipment. A board can pass every digital check and still be 6 dB down because of one wrong inductor. If you do not have access to a radio test set, or a spectrum analyser with a signal generator, consider building a small first batch and having it measured before committing to a larger run.

---

## Writing the EEPROM

The EEPROM identifies the board to the Raspberry Pi as a HAT. Without it the Pi will not load the device tree overlay and the driver will not find the board.

### Prerequisites

You need `eepmake` and `eepflash` from the Raspberry Pi utilities, plus `dtc`:

```bash
git clone https://github.com/raspberrypi/utils
cd utils/eeptools
cmake .
make
sudo make install
```

Full documentation for those tools is in the [eeptools repository](https://github.com/raspberrypi/utils/tree/master/eeptools).

### Writing

With the board connected to a Pi:

```bash
cd raspberry-pi-drivers/mu-cell-bb-dts
make all
make write_eeprom
```

`make all` generates `build/eeprom_settings.txt`, turns it into `build/eeprom.bin` with `eepmake`, and compiles the device tree overlay. `make write_eeprom` writes the image over I2C and then verifies the readback.

The Makefile prints the settings it is about to use before writing. Check them:

```
=== EEPROM settings ===
HAT UUID    : ...
HAT version : 0x...
TX pin      : 22
RX pin      : 23
```

The UUID and version are read from an already-connected HAT if one is present, and fall back to zeros otherwise. For a fresh board you will want to set a real UUID rather than writing all zeros.

<!-- TODO: document how you generate and assign UUIDs and serial numbers for a production batch. The Makefile reads them from a connected HAT, which does not help on a blank board. -->

Fixed values written for every µCell BB:

| Field | Value |
|---|---|
| `product_id` | `0x1255` |
| `vendor` | `Jankyneering` |
| `product` | `µCell-BB` |
| `current_supply` | `5000` |
| `dt_blob` | `mu-cell-bb_raspberrypi` |

---

## Signing

Signing is optional. Read that sentence again before continuing, because the rest of this section is easy to misread.

### What signing does

The [eeprom-sign](https://github.com/fred-corp/eeprom-sign) tool adds an RSA-2048 / SHA-256 / PSS signature over the EEPROM contents, stored in an `RSIG` custom atom. The driver has public keys compiled in from `SoapyMuCell/public_keys/`, and checks the signature at startup.

A valid signature tells the driver, and the user, that the board came from Jankyneering and was tested before shipping. That is the entire purpose. It exists so support requests can be routed correctly, not to control who builds the hardware.

### What signing does not do

The driver will never refuse to run on an unsigned board. An unsigned EEPROM produces a log line at warning level and nothing else:

```
HAT authenticity: unsigned EEPROM (no RSIG atom)
```

The board then works normally. The same applies to a signature that matches no known key. There is no kill switch, no reduced functionality, and no plan to add one. The design is CC BY-SA 4.0 and the driver is GPLv3, and blocking unsigned hardware would be at odds with both.

### Verifying a signature

With an I2CDriver adapter, reading boards as you insert them:

```bash
eeprom-sign batch-readback \
    --public hat_public.pem \
    --eeprom 24c256 \
    --port /dev/tty.usbserial-XXXXXXXX \
    --auto-detect
```

Or from a binary image:

```bash
eeprom-sign verify eeprom_signed.bin --public hat_public.pem
```

Install the tool with `pip install eeprom-sign`, or on macOS:

```bash
brew tap fred-corp/tap
brew install eeprom-sign
```

---

## Support for boards you built yourself

Software problems, driver build failures, and installation issues are fair game for a GitHub issue regardless of where your board came from.

Hardware problems on a board you had manufactured yourself are between you and your PCBA house. Hardware support is provided only for boards sold and tested through the store. See the [FAQ](faq.md) for the full breakdown.
