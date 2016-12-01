# SPI MASTER AND SLAVE FOR FPGA

The SPI master and SPI slave ale simple controllers for communication between FPGA and various peripherals via the SPI interface. TThe SPI master and SPI slave have been implemented using VHDL 93 and are applicable to any FPGA.

**The SPI master and SPI slave controllers support only SPI mode 0 (CPOL=0, CPHA=0)!**

The SPI master and SPI slave controllers have been simulated.

# Table of resource usage summary:

CONTROLLER | LE (LUT) | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:
SPI master | 36 | 25 | 0 | 346.9 MHz
SPI slave | 26 | 19 | 0 | 438.7 MHz

*Synthesis have been performed using Quartus Prime 16.1 Lite Edition for FPGA Altera Cyclone IV with these settings: CLK_FREQ = 50 MHz, SCLK_FREQ = 5 MHz, SLAVE_COUNT = 1.*

# License:

The SPI master and SPI slave controllers are available under the GNU LESSER GENERAL PUBLIC LICENSE Version 3. Please read [LICENSE file](LICENSE).
