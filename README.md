# SPI MASTER AND SLAVE FOR FPGA

The SPI master and SPI slave ale simple controllers for communication between FPGA and various peripherals via the SPI interface. TThe SPI master and SPI slave have been implemented using VHDL 93 and are applicable to any FPGA.

**The SPI master and SPI slave controllers support only SPI mode 0 (CPOL=0, CPHA=0)!**

The SPI master and SPI slave controllers have been simulated.

## Table of resource usage summary:

CONTROLLER | LE (LUT) | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:
SPI master | 39 | 26 | 0 | 264.7 MHz
SPI slave | 23 | 16 | 0 | 359.7 MHz

*Synthesis have been performed using Quartus Prime 16.1 Lite Edition for FPGA Altera Cyclone IV with these settings: CLK_FREQ = 50 MHz, SCLK_FREQ = 5 MHz, SLAVE_COUNT = 1.*

## License:

The SPI master and SPI slave controllers are available under the GNU LESSER GENERAL PUBLIC LICENSE Version 3.

Please read [LICENSE file](LICENSE).

# SPI master

## Table of generics:

Generic name | Type | Default value | Generic description
---|:---:|:---:|:---
CLK_FREQ | natural | 50 | System clock frequency in Hz.
SCLK_FREQ | natural | 5 | Set SPI clock frequency in Hz (condition: SCLK_FREQ <= CLK_FREQ/10).
SLAVE_COUNT | natural | 1 | Count of SPI slave controllers.

## Table of inputs and outputs ports:

Port name | IN/OUT | Width [b]| Port description
---|:---:|:---:|---
CLK | IN | 1 | System clock.
RST | IN | 1 | High active synchronous reset.
--- | --- | --- | ---
SCLK | OUT | 1 | SPI clock.
CS_N | OUT | SLAVE_COUNT | SPI chip select active in low.
MOSI | OUT | 1 | SPI serial data signal from master to slave.
MISO | IN | 1 | SPI serial data signal from slave to master.
--- | --- | --- | ---
ADDR | IN | log2(SLAVE_COUNT) | Slave controller address.
READY | OUT | 1 | When READY = 1, master is ready to accept input data.
DIN | IN | 8 | Input data for slave.
DIN_VLD | IN | 1 | When DIN_VLD = 1, input data are valid and can be accept.
DOUT | OUT | 8 | Output data from slave.
DOUT_VLD | OUT | 1 | When DOUT_VLD = 1, output data are valid.

# SPI slave

## Table of inputs and outputs ports:

Port name | IN/OUT | Width [b]| Port description
---|:---:|:---:|---
CLK | IN | 1 | System clock.
RST | IN | 1 | High active synchronous reset.
--- | --- | --- | ---
SCLK | IN | 1 | SPI clock.
CS_N | IN | 1 | SPI chip select active in low.
MOSI | IN | 1 | SPI serial data signal from master to slave.
MISO | OUT | 1 | SPI serial data signal from slave to master.
--- | --- | --- | ---
READY | OUT | 1 | When READY = 1, slave is ready to accept input data.
DIN | IN | 8 | Input data for master.
DIN_VLD | IN | 1 | When DIN_VLD = 1, input data are valid and can be accept.
DOUT | OUT | 8 | Output data from master.
DOUT_VLD | OUT | 1 | When DOUT_VLD = 1, output data are valid.
