#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: LGPL-3.0, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

# Create work library
vlib work

# Compile VHDL files
vcom -93 ../rtl/spi_slave.vhd
vcom -93 ./spi_slave_tb.vhd

# Load testbench
vsim work.spi_slave_tb

# Setup and start simulation
add wave sim:/spi_slave_tb/dut/*
run -All
