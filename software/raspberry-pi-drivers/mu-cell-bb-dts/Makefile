# SPDX-License-Identifier: MIT

BUILD_DIR    := build
EEPMAKE      := eepmake
EEPFLASH     := eepflash.sh
DTC          := dtc

# Use clang -E on macOS, cpp on Linux
UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
CPP := clang -E
else
CPP := cpp
endif
export EEPFLASH

# Detect boot partition location
ifeq ($(shell test -d /boot/firmware/overlays && echo y),y)
OVERLAYS_DIR := /boot/firmware/overlays
else
OVERLAYS_DIR := /boot/overlays
endif

# ---------------------------------------------------------------------------
# HAT identity — read from connected HAT if present, else use defaults
# ---------------------------------------------------------------------------

HAT_UUID    := $(shell cat /proc/device-tree/hat/uuid 2>/dev/null \
                || echo "00000000-0000-0000-0000-000000000000")
HAT_VERSION := $(shell cat /proc/device-tree/hat/product_ver 2>/dev/null \
                || echo "0x0101")

HAT_TX_PIN := 22
HAT_RX_PIN := 23

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------

.PHONY: all overlay install write_eeprom clean

all: $(BUILD_DIR)/eeprom.bin overlay 
	@echo "Build complete. Run 'make install' to install the overlay, and 'make write_eeprom' to write the EEPROM."

$(BUILD_DIR):
	mkdir -p -- "$@"

$(BUILD_DIR)/.settings_written: Makefile | $(BUILD_DIR)
	@echo ""
	@echo "=== EEPROM settings ==="
	@echo "HAT UUID    : $(HAT_UUID)"
	@echo "HAT version : $(HAT_VERSION)"
	@echo "TX pin      : $(HAT_TX_PIN)"
	@echo "RX pin      : $(HAT_RX_PIN)"
	@echo ""
	@echo "product_uuid $(HAT_UUID)"         >  $(BUILD_DIR)/eeprom_settings.txt
	@echo "product_id 0x1255"                >> $(BUILD_DIR)/eeprom_settings.txt
	@echo "product_ver $(HAT_VERSION)"       >> $(BUILD_DIR)/eeprom_settings.txt
	@echo 'vendor "Jankyneering"'            >> $(BUILD_DIR)/eeprom_settings.txt
	@echo 'product "uCell-BB"'               >> $(BUILD_DIR)/eeprom_settings.txt
	@echo "current_supply 5000"              >> $(BUILD_DIR)/eeprom_settings.txt
	@echo 'dt_blob "mu-cell-bb_raspberrypi"' >> $(BUILD_DIR)/eeprom_settings.txt
	@echo "custom_data"                      >> $(BUILD_DIR)/eeprom_settings.txt
	@echo "deadbeef c00 1c0d e"              >> $(BUILD_DIR)/eeprom_settings.txt
	@echo "end"                              >> $(BUILD_DIR)/eeprom_settings.txt
	@touch $@

$(BUILD_DIR)/eeprom_settings.txt: $(BUILD_DIR)/.settings_written
	@# Produced by .settings_written above

$(BUILD_DIR)/eeprom.bin: $(BUILD_DIR)/eeprom_settings.txt
	$(EEPMAKE) "$<" "$@"

overlay: $(BUILD_DIR)/mu-cell-bb_raspberrypi.dtbo

$(BUILD_DIR)/mu-cell-bb_raspberrypi.dtbo: mu-cell-bb_raspberrypi.dts | $(BUILD_DIR)
	$(CPP) -nostdinc -undef -x assembler-with-cpp \
	    -DHAT_TX_PIN=$(HAT_TX_PIN) \
	    -DHAT_RX_PIN=$(HAT_RX_PIN) \
	    "$<" \
	| grep -v '^#' \
	| $(DTC) -Wno-unit_address_vs_reg -I dts -O dtb -o "$@" -

install: $(BUILD_DIR)/mu-cell-bb_raspberrypi.dtbo
	@test -d "$(OVERLAYS_DIR)" || (echo "ERROR: $(OVERLAYS_DIR) not found. Are you on a Pi?" && exit 1)
	sudo cp "$<" "$(OVERLAYS_DIR)/mu-cell-bb_raspberrypi.dtbo"
	@echo "Installed to $(OVERLAYS_DIR)"

write_eeprom: $(BUILD_DIR)/eeprom.bin
	$(EEPFLASH) -y -w "-f=$<" -t=24c256
	./verify_eeprom.sh "$<"



clean:
	rm -rf -- "$(BUILD_DIR)"