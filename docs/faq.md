# FAQ

## Contents

- [What is this?](#what-is-this)
- [How do I install this quickly?](#how-do-i-install-this-quickly)
- [I don't trust your script. How can I build this manually?](#i-dont-trust-your-script-how-can-i-build-this-manually)
- [Which modes does it support?](#which-modes-does-it-support)
- [Why do you sign the EEPROM if this is open source?](#why-do-you-sign-the-eeprom-if-this-is-open-source-are-you-blocking-us-from-reusing-the-design)
- [How do I ask for support?](#how-do-i-ask-for-support)
- [Help, my driver says the board isn't genuine!](#help-my-driver-says-the-board-isnt-genuine)
- [Can I use an external reference clock?](#can-i-use-an-external-reference-clock)
- [What is the OLED header for?](#what-is-the-oled-header-for)
- [Is there a case?](#is-there-a-case)
- [Which Raspberry Pi should I use?](#which-raspberry-pi-should-i-use)
- [Do I need a licence to transmit?](#do-i-need-a-licence-to-transmit)
- [Can I put a power amplifier on it?](#can-i-put-a-power-amplifier-on-it-and-run-a-proper-base-station)
- [Can I use this with GQRX, SDR++, or GNU Radio?](#can-i-use-this-with-gqrx-sdr-or-gnu-radio)
- [Where are the production files?](#where-are-the-production-files)
- [Is there a power amplifier board?](#is-there-a-power-amplifier-board)

---

## What is this?

µCell is an open-source SDR base station platform. The µCell BB board is a Raspberry Pi HAT built around an SX1255 transceiver. Paired with a Pi and one of the supported software stacks, it runs a base station in whichever mode that software implements.

The hardware designs, the case models, the drivers, and the EEPROM tooling are all in this repository. The board is OSHWA certified under [BE000024](https://certification.oshwa.org/be000024.html).

## How do I install this quickly?

Fit the board to the Pi, flash Raspberry Pi OS Lite (64-bit), boot, and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jankyneering/mu-cell/main/install-mu-cell-sw.sh)"
```

Reboot when prompted, then run it again. That gets the driver and overlay in place. Radio software is installed separately from its own project. The [quick start guide](quickStartGuide.md) has links and configuration notes for each one.

## I don't trust your script. How can I build this manually?

Reasonable. [buildDriver.md](buildDriver.md) walks through every step the script performs for the driver and overlay. The script itself is in the repository root if you want to read it first.

## Which modes does it support?

TETRA is where the project started, through Bluestation and Flowstation, and it is the best tested path today. It is not a limit. The board is a plain SoapySDR device, so MMDVM-IQ brings DMR, D-Star, YSF, P25, and analog FM to the same hardware, and general SDR software can use it for anything else.

The intention is to support as many voice modes as we can get working. If you bring up a mode we have not documented, tell us about it.

## Why do you sign the EEPROM if this is open source? Are you blocking us from reusing the design?

No. The driver will never refuse to run on an unsigned board, and there is no plan to change that.

Signing exists to answer one question: did this specific board come from Jankyneering and get tested before shipping? That matters for support. A few concrete cases:

- Someone reports 8 dB less transmit power than the spec sheet. If the board is signed, it passed a radio test set before shipping, and the problem is probably configuration or a damaged antenna. If it is unsigned, a substituted inductor in the matching network is a likelier explanation, and the debugging goes in a completely different direction.
- Someone's board is not detected at all. A signed EEPROM proves the EEPROM was written correctly at the factory, which rules out a whole category of causes immediately.
- A clone appears with a looser reference clock. Signing keeps reports about those separate from reports about boards we can actually vouch for.

None of this restricts you. The hardware is CC BY-SA 4.0 and certified by OSHWA, and the software is GPLv3. You can build the design, modify it, and sell it.

## How do I ask for support?

It depends on what is broken.

| Problem | Where to go |
|---|---|
| Driver, overlay, install script | Open a [GitHub issue](https://github.com/Jankyneering/mu-cell/issues) |
| Radio software behaviour or configuration | That project's issue tracker |
| Hardware fault on a board bought from the store | Contact [store.fredcorp.cc](http://store.fredcorp.cc/) |
| Hardware fault on a board from another seller | Contact that seller |
| Hardware fault on a board you had manufactured | Contact your PCBA house |

<!-- TODO: add the actual support contact route for store purchases, whether that is an email, a form, or a shop account. -->

The split is not about gatekeeping. Driver problems are reproducible and benefit from being public, so issues are the right venue for everyone. Hardware faults need someone who has the board's test record, which only the seller has.

## Help, my driver says the board isn't genuine!

Not a problem, and the board will work anyway. The message is a warning, not an error.

If you built the board yourself or bought it from a third party, this is expected. Your EEPROM either has no signature or is signed with a key the driver does not know about. Nothing else changes.

If you bought it from the store and it previously reported as genuine, or it reports `SIGNATURE_MISMATCH`, your driver is probably older than your board. New production batches are signed with new keys, and those keys ship with driver updates. Re-run the install script to update:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jankyneering/mu-cell/main/install-mu-cell-sw.sh)"
```

See [updating](quickStartGuide.md#updating) for what that does.

If the message is `NO_KEYS_COMPILED_IN`, the driver was built with an empty `public_keys/` directory. Signature checking is simply off in that build.

## Can I use an external reference clock?

Yes. There is a third U.FL connector for it. The board ships using the onboard 0.5 ppm TCXO, and switching to the external input means cutting JP1 on the back and bridging the jumper across. See [hardware.md](hardware.md#external-clock).

## What is the OLED header for?

A standard 0.96 inch SSD1306 display, on the Pi's I2C bus. The forthcoming µCell Display module uses the same panel alongside a rotary encoder and status LEDs. There is no µCell software support for it yet, but nothing stops you using an existing SSD1306 library in the meantime. Pinout is in [hardware.md](hardware.md#oled-display-header).

## Is there a case?

Yes. 3D printable case designs are in the `hardware` directory, under the same CC BY-SA 4.0 licence as the boards. They print without supports on a standard FDM machine. See [hardware.md](hardware.md#cases).

If you print one and something needs adjusting, open a pull request with the change and a note on your print settings.

## Which Raspberry Pi should I use?

The Pi 3, 4, 5, and Zero 2W are all supported by the driver. Some radio software ships separate builds for the Pi 5 and for earlier models, so check which asset you need when you install it. A Zero 2W works but compiles slowly if you build from source.

## Do I need a licence to transmit?

Yes, in essentially every jurisdiction. The frequencies this board is used on are licensed, and transmitting without authorisation is illegal in most countries. This is your responsibility, not the project's. If you want to experiment without a licence, look into what your national regulator permits, whether that is an amateur allocation you hold a licence for, a test licence, or a shielded enclosure.

## Can I put a power amplifier on it and run a proper base station?

You can, but the filtering is on you, and it is not optional.

The SX1255 is a mobile device part. Its selectivity is sized for a handset transmitting a fraction of a watt into its own antenna, not for a site with a kilowatt of RF nearby. On the bench, an interfering signal at -40 dBm and 10 MHz away from the receive frequency is already enough to degrade the rated sensitivity. An amplified transmitter is orders of magnitude stronger than that and much closer in frequency.

So if you amplify, budget for proper transmit rejection on the receive path, a duplexer or cavity filtering as appropriate, and transmit filtering in the amplifier chain. Bolt a 100 W amplifier straight onto the board and you will have a transmitter that works and a receiver that goes deaf every time you key it.

See [hardware.md](hardware.md#adding-an-amplifier).

## Can I use this with GQRX, SDR++, or GNU Radio?

Yes. The board registers as a standard SoapySDR device. Use the device string `driver=mucell`. See the [quick start guide](quickStartGuide.md#other-soapysdr-software).

## Where are the production files?

Under `/hardware/mu-cell-bb/v1.3/production`, alongside the schematics and PCB layouts. [muCellBBManufacture.md](muCellBBManufacture.md) covers what is in the package, the stackup we order, and which component substitutions will quietly ruin your RF performance.

## Is there a power amplifier board?

Not yet. The µCell PA Mini, at roughly 1 W, is designed but still needs work before it is ready to manufacture. The µCell Display module is closer to done. See [hardware.md](hardware.md) for the current roadmap, and the question above before you reach for an amplifier of your own.
