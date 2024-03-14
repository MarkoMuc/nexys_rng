# Nexys A7 100T Random Number Generator

A random number generator implemented in VHDL for Nexys A7 100T board. It uses the onboard ADXL362 accelerometer for generating the random numbers. Note this is not an actual RNG, since it needs a random actor, to move the device, since the implementations just reads and sends accelerometer values.

## ADXL362 Accelerometer

- 12-bit resolution or 8-bit formatted data.
- SPI is used for communication between the FPGA and the sensor.
- When it is in measurement mode, it continously measures and stores data in the X-data, Y-data and Z-data registers.

### The SPI Interace

- ADXL362 acts as a slave device.
- The recommended SPI clock frequency ranges from 1Mhz to 8Mhz.
- The SPI operates in SPI mode 0 with CPOL=0 and CPHA=0.
- Accelerometer data is accessed by reading the device registers.
- Four lines are used for communication:
    - MOSI Master Out Slave In.
    - MISO: Master In Slave Out.
    - SCLK: serial clock.
    - ~CS: Chip Select, Active Low.
- Command set:
  - 0x0A: Write register.
  - 0x0B: Read register.
- Read and Write command structure:
  - CS down.
  - Command byte(read or write).
  - Address byte.
  - Data byte.
  - Additional bytes for multi-byte mode.
  - CS up.
- Register read or write commands auto-increment.
- Registers:
  - 0x2D: Power Control Register B1B0 is used to set-up measurement.
    - 10 -> Measurement Mode.
    - Command: 0x02 -> Measurement mode.
  - 0x08 to 0x0A are the 8bit data registers.

## Usage

Use Vivado to synthesis, implement and generate a bit stream that can be uploaded to the device.

UART contains `uart.py`, which is a simple python script that reads from the UART, it has two modes.
1. First mode shows [X, Y, Z] values in that format as integers.
2. Second mode takes X, Y, Z values, changes them to binary and sticks them together. Saves each reading to one line.

