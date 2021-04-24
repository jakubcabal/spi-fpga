# Changelog of SPI master and SPI slave for FPGA

**Version 1.1 - released on 24 April 2021**
- Changed license to The MIT License.
- Added better simulations and enabled GitHub CI.
- Added Spirit Level example design for CYC1000 board.
- Added sync FFs to SPI slave for elimination metastability.
- Added WORD_SIZE generic.
- Many minor changes, fixes and optimizations.

**Version 1.0 - released on 28 September 2017**
- First non-beta release.
- Added new version of master module with many optimizations.
- Added DIN_LAST input to master module, for CS_N signal control.
- Added simulation tcl script for ModelSim.
- Updated simulation testbench.
- Updated example design.
- Optimized and cleaned slave module.
