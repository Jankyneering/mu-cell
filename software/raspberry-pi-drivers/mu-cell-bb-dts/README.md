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
