#!/bin/bash
#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

# Analyse sources
ghdl -a ../rtl/spi_slave.vhd
ghdl -a ./spi_slave_tb.vhd

# Elaborate the top-level
ghdl -e SPI_SLAVE_TB

# Run the simulation
# The following command is allocated to a separate script due to CI purposes.
#ghdl -r SPI_SLAVE_TB
