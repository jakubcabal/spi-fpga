#-------------------------------------------------------------------------------
# PROJECT: SPI MASTER AND SLAVE FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/spi-fpga
#-------------------------------------------------------------------------------

create_clock -name CLK50 -period 20.000 [get_ports {CLK}]
