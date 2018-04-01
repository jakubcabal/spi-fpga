# SPI MASTER AND SLAVE FOR FPGA

The SPI master and SPI slave are simple controllers for communication between FPGA and various peripherals via the SPI interface. The SPI master and SPI slave have been implemented using VHDL 93 and are applicable to any FPGA.

**The SPI master and SPI slave controllers support only SPI mode 0 (CPOL=0, CPHA=0)!**

The SPI master and SPI slave controllers were simulated and tested in hardware. If you have a question or you have a tip for improvement, send me an e-mail or create a issue.

## Table of resource usage summary:

CONTROLLER | LE (LUT) | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:
SPI MASTER | 34 | 23 | 0 | 327.3 MHz
SPI SLAVE | 24 | 15 | 0 | 318.0 MHz

*Synthesis have been performed using Quartus Prime 17 Lite Edition for FPGA Altera Cyclone IV with these settings: CLK_FREQ = 50 MHz, SCLK_FREQ = 2 MHz, SLAVE_COUNT = 1.*

## The SPI loopback example design:

The SPI loopback example design is for testing data transfer between SPI master and SPI slave over external wires.

Please read [README file of SPI loopback example design](example/README.md).

[![Video of SPI loopback example design](https://img.youtube.com/vi/-TbtB6Sm2Xk/0.jpg)](https://youtu.be/-TbtB6Sm2Xk)

## License:

The SPI master and SPI slave controllers are available under the GNU LESSER GENERAL PUBLIC LICENSE Version 3.

Please read [LICENSE file](LICENSE).

# SPI master

## Table of generics:

Generic name | Type | Default value | Generic description
---|:---:|:---:|:---
CLK_FREQ | natural | 50e6 | System clock frequency in Hz.
SCLK_FREQ | natural | 2e6 | Set SPI clock frequency in Hz (condition: SCLK_FREQ <= CLK_FREQ/10).
SLAVE_COUNT | natural | 1 | Count of SPI slave controllers.

## Table of inputs and outputs ports:

Port name | IN/OUT | Width [b]| Port description
---|:---:|:---:|---
CLK | IN | 1 | System clock.
RST | IN | 1 | High active synchronous reset.
--- | --- | --- | ---
SCLK | OUT | 1 | SPI clock.
CS_N | OUT | SLAVE_COUNT | SPI chip select, active in low.
MOSI | OUT | 1 | SPI serial data from master to slave.
MISO | IN | 1 | SPI serial data from slave to master.
--- | --- | --- | ---
ADDR | IN | log2(SLAVE_COUNT) | SPI slave address.
DIN | IN | 8 | Input data for SPI slave.
DIN_LAST | IN | 1 | When DIN_LAST = 1, after transmit these input data is asserted CS_N.
DIN_VLD | IN | 1 | When DIN_VLD = 1, input data are valid.
READY | OUT | 1 | When READY = 1, valid input data are accept.
DOUT | OUT | 8 | Output data from SPI slave.
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
MOSI | IN | 1 | SPI serial data from master to slave.
MISO | OUT | 1 | SPI serial data from slave to master.
--- | --- | --- | ---
DIN | IN | 8 | Input data for SPI master.
DIN_VLD | IN | 1 | When DIN_VLD = 1, input data are valid.
READY | OUT | 1 | When READY = 1, valid input data are accept.
DOUT | OUT | 8 | Output data from SPI master.
DOUT_VLD | OUT | 1 | When DOUT_VLD = 1, output data are valid.
