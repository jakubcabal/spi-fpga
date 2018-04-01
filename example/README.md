# SPI LOOPBACK EXAMPLE

The SPI loopback example design is for testing data transfer between SPI master and SPI slave over external wires.
I use it on my FPGA board ([EP4CE6 Starter Board](http://www.ebay.com/itm/111975895262) with Altera FPGA Cyclone IV EP4CE6E22C8 for $45) with few buttons and a seven-segment display (four digit).

There is video of the SPI loopback example design: https://youtu.be/-TbtB6Sm2Xk

[![Video of SPI loopback example design](https://img.youtube.com/vi/-TbtB6Sm2Xk/0.jpg)](https://youtu.be/-TbtB6Sm2Xk)

## Control of SPI loopback example design:

**Display description (from right on board in video):**

* Digit0 = value on SPI slave input
* Digit1 = value on SPI slave output
* Digit2 = value on SPI master input
* Digit3 = value on SPI master output

**Buttons description (from right on board in video):**

* BTN_ACTION (in mode0) = setup value on SPI slave input
* BTN_ACTION (in mode1) = write (set valid) of SPI slave input value
* BTN_ACTION (in mode2) = setup value on SPI master input
* BTN_ACTION (in mode3) = write (set valid) of SPI slave input value and start transfer between SPI master and SPI slave
* BTN_MODE = switch between modes (mode0 = light decimal point on digit0,...)
* BTN_RESET = reset FPGA design
