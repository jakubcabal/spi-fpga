#!/bin/bash
#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

# Analyse sources
ghdl -a ../rtl/spi_master.vhd
ghdl -a ./spi_master_tb.vhd

# Elaborate the top-level
ghdl -e SPI_MASTER_TB

# Run the simulation
# The following command is allocated to a separate script due to CI purposes.
#ghdl -r SPI_MASTER_TB
