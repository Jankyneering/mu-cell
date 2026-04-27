# µCell BB EEPROM and Device Tree configuration for Raspberry Pi HAT compatibility

This directory contains a Makefile and related files to build an EEPROM image and Device Tree overlay for the uCell-BB, enabling it to be recognized as a HAT on Raspberry Pi devices. The Makefile automates the process of generating the necessary files and provides targets for building, installing, and writing to the EEPROM.

## Prerequisites

- A Raspberry Pi with an I2C EEPROM connected (for writing the EEPROM).
- The `eepmake` tool for creating EEPROM images from settings files.
- The `dtc` (Device Tree Compiler) for compiling the Device Tree source into a binary overlay.
- The `eepflash` tool for writing the EEPROM image to the device.

`eepmake` and `eepflash` can be obtained from the Raspberry Pi GitHub repository as follows ([full guide](https://github.com/raspberrypi/utils/tree/master/eeptools)):

```bash
git clone https://github.com/raspberrypi/utils
cd utils/eeptools
cmake .
make
sudo make install
```

## Usage

1. **Build the EEPROM image and Device Tree overlay:**

   ```bash
   make all
   ```

    This will generate `eeprom.bin` and `mu-cell-bb_raspberrypi.dtbo` in the `build/` directory.

2. **Install the Device Tree overlay:**

    ```bash
    make install
    ```

    This will copy the `mu-cell-bb_raspberrypi.dtbo` file to the appropriate overlays directory on the Raspberry Pi (either `/boot/overlays` or `/boot/firmware/overlays`).

3. **Write the EEPROM:**

    ```bash
    make write_eeprom
    ```

    This will write the generated `eeprom.bin` to the connected EEPROM device and verify the write operation.
4. **Clean the build artifacts:**

    ```bash
    make clean
    ```

    This will remove the `build/` directory and all generated files.

## Check with [`eeprom-sign`](https://github.com/fred-corp/eeprom-sign) tool

### Install tool

```zsh
pip install eeprom-sign
```

or with Homebrew :

```zsh
brew tap fred-corp/tap
brew install eeprom-sign
```

### Check the generated EEPROM image on the hat

#### With an I2CDriver

```zsh
eeprom-sign batch-readback \
    --public hat_public.pem \
    --eeprom 24c256 \
    --port /dev/tty.usbserial-DM02V7KY \
    --auto-detect
```

Wich should output something like this :

```txt
[i2c] Connected to I2CDriver on /dev/tty.usbserial-DM02V7KY

============================================================
  Auto-detect mode — insert board to trigger read.
  Ctrl+C to stop.
============================================================

[batch-rb] Board detected at 0x50 — reading…
[batch-rb/1] Reading 407 bytes…
[batch-rb/1] 5 atom(s) found
         Vendor  : Jankyneering
         Product : µCell-BB
         UUID    : <UUID>
         Serial  : <Serial>
[verify] ✓  Signature VALID — tmprfkj6g1b.bin
         RSA-2048 / SHA-256 / PSS
[batch-rb] ✓  OK — device 1  (total: 1/1)
[batch-rb] Board removed.  Waiting for next insertion…
```

#### From a `.bin` file

```zsh
eeprom-sign verify eeprom_signed.bin \
    --public hat_public.pem
```

Which should output something like this :

```txt
[verify] ✓  Signature VALID — eeprom_signed.bin
         RSA-2048 / SHA-256 / PSS
```
