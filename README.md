# Nexys A7 100T Random Number Generator

A random number generator implemented in VHDL for Nexys A7 100T board. It uses the onboard ADXL362 accelerometer for generating the random numbers.

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
  - Data:
      - 0x0E: XDATA_L[7:0]
      - 0x0F: SX + XDATA_H[3:0]
      - 0x10: YDATA_L[7:0]
      - 0x11: SX + YDATA_H[3:0]
      - 0x12: ZDATA_L[7:0]
      - 0x13: SX + ZDATA_H[3:0]
      - The _L registers contains the eight least significant bits.
      - The _H registers contains the Sign Extended bits and four most significant bits of the 12-bit value.
      - The SX bits have the same value as The most significant bit.
      - As such the 12-bit value can be rebuilt as : _H[3:3] _H[2:0] _L[7:0]
  - 0x2D: Power Control Register B1B0 is used to set-up measurement.
    - 10 -> Measurement Mode.
    - Command: 0x02 -> Measurement mode.
  - 0x08 to 0x0A are the 8bit data registers.
## Usage

- SPI data is set in MSB first.

3. Reading data:
  - CS down.
  - Read command.
  - Data start address.
  - Read 6 bytes.
  - CS up.
  - Wait.
