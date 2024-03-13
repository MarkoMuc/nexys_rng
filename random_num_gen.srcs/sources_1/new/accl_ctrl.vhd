----------------------------------------------------------------------------------
-- Accelerometer controller.
-- Author: Marko Z. Muc
--
-- Description:
-- If Start is in, that means start to read
-- pass back done signal, to be used on the top module, for transport
-- Otherwise dont do aynthing.
-- CAm also add a signal, so start is only done after a valid transfer through uart
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accl_ctrl is
    Port(
        SYS_CLK : in STD_LOGIC;
        MISO: in STD_LOGIC; -- MISO
        SCLK : out STD_LOGIC; -- SCLK
        CSN : out STD_LOGIC; -- CSN, active low
        MOSI : out STD_LOGIC; -- MOSI
        X_DATA : out STD_LOGIC_VECTOR(0 to 11); -- X data, 12 bit resolution
        Y_DATA : out STD_LOGIC_VECTOR(0 to 11); -- Y data, 12 bit resolution
        Z_DATA : out STD_LOGIC_VECTOR(0 to 11); -- Z data, 12 bit resolution
        FIN : out STD_LOGIC -- Finished signal
    );
end accl_ctrl;

architecture Behavioral of accl_ctrl is

begin
    chip_ctrl: entity work.adxl_ctrl(Behavioral)
    port map(
        SYS_CLK => SYS_CLK,
        MISO => MISO,
        SCLK => SCLK,
        CSN => CSN,
        MOSI => MOSI,
        X_DATA => X_DATA,
        Y_DATA => Y_DATA,
        Z_DATA => Z_DATA,
        FIN => FIN
    );

end Behavioral;
