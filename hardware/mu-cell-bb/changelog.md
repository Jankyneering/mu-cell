# µCell BB Changelog

## v1.3 - Batch feedback upgrades

> 2026/07

- Routing updates
  - Moved some vias that were in the middle of component pads to avoid soldering issues during production.
- Net updates
  - Changes 3.3V on accessory header to use the 3.3V rail from the Raspberry Pi instead of the µCell BB's 3.3V rail, to avoid overloading or adding noise to the µCell BB's 3.3V regulator when using high-current accessories.
- Silkscreen updates
  - Bumped version number to v1.3
  - Bumped date to 2026/07

## v1.2 - Small updates

> 2026/05

- Footprint updates
  - Changed Y1 footprint to the smaller 2016 package, as they tend to be more precise anyway (the larger 2520 package could fit both sizes, but reflow issues were observed during a mid-scale production run).
- Component updates
  - Set the RF Can to be excluded from BOM by default
- Silkscreen updates
  - Bumped version number to v1.2

## v1.1 - Minor refinements

> 2026/04

- Footprint updates
  - Reworked RF Can GND pad vias
    - Via placement is now more regular, signal routing to the SX1255 is more direct.
  - Removed SMA connector pads
    - The TX and RX connectors would have been too close together, causing potential interference and signal integrity issues. By removing the SMA connector pads, we can ensure better performance and reliability of the RF signals.
  - Put pin 6 of EEPROM programming headers to GND
    - This allows an external programmer to detect when a programming header is connected, to then automatically trigger the programming process.
- Silkscreen updates
  - Added OSHW logo to top side
  - Bumped version number to v1.1
  - Removed pad numbers next to clock selection jumpers
  - Added "Serial n°" Field to bottom side

## v1.0 - Initial release

> 2026/04

- Performance on par with [SXCeiver](https://sxceiver.com)
