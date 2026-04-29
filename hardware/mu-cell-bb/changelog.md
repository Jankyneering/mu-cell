# µCell BB Changelog

## v1.1 - Minor refinements

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

- Performance on par with [SXCeiver](https://sxceiver.com)
