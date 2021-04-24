#!/bin/bash
#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: LGPL-3.0, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

# Setup simulation
sh ./spi_slave_tb_ghdl_setup.sh

# Run the simulation
ghdl -r SPI_SLAVE_TB
