----------------------------------------------------------------------------------
-- SPI clock generator.
-- Used to generate the SPI clock signal.
-- Author: Marko Z. Muc
--
-- Description:
--  - CE_2X signal can be used to detect the rising and falling edge.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sclk_gen is
    generic(
        WIDTH : INTEGER := 32; -- Width of the limit integer
        SYS_CLK_FREQ : INTEGER := 1e8; -- Default is 100MHz
        SCLK_FREQ : INTEGER := 1e6 -- Default is 1Mhz
    );
    Port ( SYS_CLK : in STD_LOGIC; -- System clock
           RESET : in STD_LOGIC; -- Reset signal
           CE : out STD_LOGIC; -- Chip select signal
           CE_2X : out STD_LOGIC); -- 2x chip select signal
end sclk_gen;

architecture Behavioral of sclk_gen is
    constant LIMIT : INTEGER := (SYS_CLK_FREQ/SCLK_FREQ)/2 - 1; -- Limit used for division

    signal counter : UNSIGNED (WIDTH - 1 downto 0) := (others => '0'); -- Counter
    signal ce_int : STD_LOGIC := '0'; -- Internal chip select signal
    signal ce_int_2x : STD_LOGIC := '0'; -- Internal 2x chip select signal
begin
    CE <= ce_int;
    CE_2X <= ce_int_2x;
    
    DIVIDER_2X:process(SYS_CLK, RESET, ce_int_2x)
    begin
        if rising_edge(SYS_CLK) then
            if RESET = '1' or counter = LIMIT then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    ce_int_2x <= '1' when counter = limit else '0';

    SCLK_MAIN: process(SYS_CLK, RESET, ce_int)
    begin
        if rising_edge(SYS_CLK) then
            if RESET = '1' then
                ce_int <= '0';
            elsif ce_int_2x = '1' then
                ce_int <= not ce_int;
            end if;
        end if;
    end process;
end Behavioral;
