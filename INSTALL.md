# Installation steps for SoapyMuCell on RPi

## Dependencies

```zsh
sudo apt update
sudo apt install -y --no-install-recommends \
  git \
  make \
  g++ \
  cmake \
  libsoapysdr-dev \
  soapysdr-tools \
  libasound2-dev \
  python3-soapysdr \
  libssl-dev \
  clang \
  llvm-dev \
  libclang-dev
```

## Build and install Device Tree overlay

```zsh
git clone https://github.com/Jankyneering/mu-cell
cd mu-cell/software/raspberry-pi-drivers/mu-cell-bb-dts
make
make install
sudo reboot
```

## Build and install SoapyMuCell

```zsh
cd mu-cell/software/SoapyMuCell
mkdir build
cd build
cmake ..
make
sudo make install
sudo ldconfig
SoapySDRUtil --probe=driver=mucell
```

## Optional: Build and install the Tetra BlueStation

```zsh
curl https://sh.rustup.rs -sSf | sh
git clone https://github.com/MidnightBlueLabs/tetra-bluestation
cd tetra-bluestation
. "$HOME/.cargo/env"
cargo build --release
```
