# SoapyMuCell

SoapyMuCell is a SoapySDR hardware support module for the mu-cell SX1255-based RF board.

It exposes the radio as a SoapySDR device with driver key `mucell`, using:

- SPI (`/dev/spidev0.0`) for SX1255 register control
- GPIO (`/dev/gpiochip0`) for reset and PA/RX/TX control
- ALSA (`hw:CARD=SX1255`) for sample streaming over I2S

## Current capabilities

- 1 RX + 1 TX channel
- Stream format: `CF32`
- RX and TX frequency control
- RX/TX gain control (`LNA`, `PGA`, `DAC`, `MIXER`)
- Antenna/loopback selection:
  - RX: `RX`, `LB`
  - TX: `TX`, `NONE`
- Hardware time support
- EEPROM parsing and authenticity verification using RSA-PSS (SHA-256)

## Platform expectations

This driver is intended for Linux on Raspberry Pi-class systems with:

- SX1255 audio interfaces available through ALSA
- SPI and GPIO character device interfaces enabled
- SoapySDR installed

## Dependencies (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install --no-install-recommends \
  git make g++ cmake \
  libsoapysdr-dev soapysdr-tools python3-soapysdr \
  libasound2-dev libssl-dev
```

## Build and install

From this directory:

```bash
mkdir -p build
cd build
cmake ..
make -j"$(nproc)"
sudo make install
sudo ldconfig
```

If `SoapySDR` development files are missing, CMake will skip building the module.

## Public key embedding for EEPROM authentication

SoapyMuCell can embed one or more public keys at build time:

1. Place PEM public keys in `public_keys/` (file extension `.pem`).
2. Rebuild the driver.

During build, CMake generates `generated_keys.hpp` from all `*.pem` files.

If no keys are present, the driver still builds, but runtime auth status reports `no_keys`.

## PipeWire/WirePlumber note

A helper config file (`60-pipewire-do-not-use-i2s.lua`) is installed by default to prevent PipeWire from claiming the SX1255 ALSA devices as normal audio endpoints.

Disable this install step if needed:

```bash
cmake -DINSTALL_PIPEWIRE_CONF=OFF ..
```

## Verify driver registration

```bash
SoapySDRUtil --probe="driver=mucell"
```

Expected probe output should include:

- `driver = mucell`
- `hardware = mucell`
- hardware metadata such as `hardware_version`
- EEPROM fields when available (`eeprom_vendor`, `eeprom_product`, `eeprom_uuid`, `eeprom_serial`, `eeprom_auth`)

## Runtime behavior notes

- Sample rates are selected from a fixed supported set derived from detected SX1255 master clock (32.0 MHz or 38.4 MHz).
- TX can be gated by per-sample magnitude threshold in stream setup.
- RX overrun and TX underrun handling follows SoapySDR stream semantics, with optional linked mode behavior.

## Stream setup arguments (advanced)

The driver supports optional stream arguments:

- `threshold` (TX only): magnitude threshold for TX gating (default `1e-3`)
- `period`: requested ALSA period size
- `link=1`: enable linked stream mode for compatibility with legacy behavior

These arguments are consumed in `setupStream()` by client applications that pass Soapy stream kwargs.

## Troubleshooting quick checks

- Confirm ALSA endpoints exist:

```bash
aplay -L | grep SX1255
arecord -L | grep SX1255
```

- Confirm SPI and GPIO device nodes:

```bash
ls -l /dev/spidev0.0 /dev/gpiochip0
```

- Re-run probe with debug logging:

```bash
SOAPY_SDR_LOG_LEVEL=DEBUG SoapySDRUtil --probe="driver=mucell"
```

## License

Source files in this directory are MIT-licensed (see SPDX headers in code). Project-level licensing terms still apply for the full repository.
