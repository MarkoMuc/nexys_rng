----------------------------------------------------------------------------------
-- SPI controller.
-- SPI controller for the ADXL362 sensor.
-- Author: Marko Z. Muc
--
-- Description:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_ctrl is
    Port ( SPI1 : in STD_LOGIC;
           SPI2 : in STD_LOGIC;
           SPI3 : in STD_LOGIC;
           SPI4 : in STD_LOGIC);
end spi_ctrl;

architecture Behavioral of spi_ctrl is

begin


end Behavioral;
