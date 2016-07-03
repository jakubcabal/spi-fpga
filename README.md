# SPI master controller for FPGA

The SPI master is simple controller for communication between FPGA and various peripherals via the SPI interface. The SPI master was implemented using VHDL 93 and is applicable to any FPGA.

**The SPI master controller support only SPI mode 0 (CPOL=0, CPHA=0)!**

The SPI master controller was simulated.

# Synthesis results summary:

DATA_WIDTH | LE (LUT) | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:
8b | 28 | 22 | 0 | 307.4MHz
16b | 39 | 31 | 0 | 211.3MHz

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 for FPGA Altera Cyclone II with these settings: CLK_FREQ = 50 MHz, SCLK_FREQ = 5 MHz.*
