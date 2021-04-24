#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

# Create work library
vlib work

# Compile VHDL files
vcom -93 ../rtl/spi_master.vhd
vcom -93 ./spi_master_tb.vhd

# Load testbench
vsim work.spi_master_tb

# Setup and start simulation
add wave sim:/spi_master_tb/*
add wave sim:/spi_master_tb/dut/*
run -All
