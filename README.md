# SPI MASTER AND SLAVE FOR FPGA

The SPI master and SPI slave are simple controllers for communication between FPGA and various peripherals via the SPI interface. The SPI master and SPI slave have been implemented using VHDL 93 and are applicable to any FPGA.

**The SPI master and SPI slave controllers support only SPI mode 0 (CPOL=0, CPHA=0)!**

The SPI master and SPI slave controllers were simulated and tested in hardware. I use the GHDL tool for CI: automated VHDL simulations in the GitHub Actions environment ([setup-ghdl-ci](https://github.com/ghdl/setup-ghdl-ci)). If you have a question or you have a tip for improvement, send me an e-mail or create a issue.

## SPI master

### Generics:

```vhdl
CLK_FREQ    : natural := 50e6; -- set system clock frequency in Hz
SCLK_FREQ   : natural := 5e6;  -- set SPI clock frequency in Hz (condition: SCLK_FREQ <= CLK_FREQ/10)
WORD_SIZE   : natural := 8;    -- size of transfer word in bits, must be power of two
SLAVE_COUNT : natural := 1     -- count of SPI slaves
```

### Ports:

```vhdl
CLK      : in  std_logic; -- system clock
RST      : in  std_logic; -- high active synchronous reset
-- SPI MASTER INTERFACE
SCLK     : out std_logic; -- SPI clock
CS_N     : out std_logic_vector(SLAVE_COUNT-1 downto 0); -- SPI chip select, active in low
MOSI     : out std_logic; -- SPI serial data from master to slave
MISO     : in  std_logic; -- SPI serial data from slave to master
-- INPUT USER INTERFACE
DIN      : in  std_logic_vector(WORD_SIZE-1 downto 0); -- data for transmission to SPI slave
DIN_ADDR : in  std_logic_vector(natural(ceil(log2(real(SLAVE_COUNT))))-1 downto 0); -- SPI slave address
DIN_LAST : in  std_logic; -- when DIN_LAST = 1, last data word, after transmit will be asserted CS_N
DIN_VLD  : in  std_logic; -- when DIN_VLD = 1, data for transmission are valid
DIN_RDY  : out std_logic; -- when DIN_RDY = 1, SPI master is ready to accept valid data for transmission
-- OUTPUT USER INTERFACE
DOUT     : out std_logic_vector(WORD_SIZE-1 downto 0); -- received data from SPI slave
DOUT_VLD : out std_logic  -- when DOUT_VLD = 1, received data are valid
```

### Simulation:

A simulation is prepared in the ```sim/``` folder. You can use the prepared TCL script to run simulation in ModelSim.
```
vsim -do spi_master_tb_msim_run.tcl
```

Or it is possible to run the simulation using the [GHDL tool](https://github.com/ghdl/ghdl). Linux users can use the prepared bash script to run the simulation in GHDL:
```
./spi_master_tb_ghdl_run.sh
```

## SPI slave

### Generics:

```vhdl
WORD_SIZE : natural := 8; -- size of transfer word in bits, must be power of two
```

### Ports:

```vhdl
CLK      : in  std_logic; -- system clock
RST      : in  std_logic; -- high active synchronous reset
-- SPI SLAVE INTERFACE
SCLK     : in  std_logic; -- SPI clock
CS_N     : in  std_logic; -- SPI chip select, active in low
MOSI     : in  std_logic; -- SPI serial data from master to slave
MISO     : out std_logic; -- SPI serial data from slave to master
-- USER INTERFACE
DIN      : in  std_logic_vector(WORD_SIZE-1 downto 0); -- data for transmission to SPI master
DIN_VLD  : in  std_logic; -- when DIN_VLD = 1, data for transmission are valid
DIN_RDY  : out std_logic; -- when DIN_RDY = 1, SPI slave is ready to accept valid data for transmission
DOUT     : out std_logic_vector(WORD_SIZE-1 downto 0); -- received data from SPI master
DOUT_VLD : out std_logic  -- when DOUT_VLD = 1, received data are valid
```

### Simulation:

A simulation is prepared in the ```sim/``` folder. You can use the prepared TCL script to run simulation in ModelSim.
```
vsim -do spi_slave_tb_msim_run.tcl
```

Or it is possible to run the simulation using the [GHDL tool](https://github.com/ghdl/ghdl). Linux users can use the prepared bash script to run the simulation in GHDL:
```
./spi_slave_tb_ghdl_run.sh
```

## Table of resource usage summary:

CONTROLLER | LE | FF | M9K | Fmax
:---:|:---:|:---:|:---:|:---:
SPI MASTER | 34 | 23 | 0 | 334.2 MHz
SPI SLAVE | 24 | 15 | 0 | 343.7 MHz

*Synthesis have been performed using Quartus Prime 20.1 Lite Edition for FPGA Altera Cyclone IV EP4CE6E22C8 with default generics*

## The SPI loopback example design:

The SPI loopback example design is for testing data transfer between SPI master and SPI slave over external wires.

Please read [README file of SPI loopback example design](examples/loopback/README.md).

[![Video of SPI loopback example design](https://img.youtube.com/vi/-TbtB6Sm2Xk/0.jpg)](https://youtu.be/-TbtB6Sm2Xk)

## License:

This UART controller is available under the MIT license. Please read [LICENSE file](LICENSE).
