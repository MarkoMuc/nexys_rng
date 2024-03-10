----------------------------------------------------------------------------------
-- Generic prescaler.
-- Prescaler to generate a different frequency.
-- Author: Marko Z. Muc
--
-- Description:
-- - Width and limit are used to configure the output frequency.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity prescaler is
    generic(
        WIDTH: INTEGER := 32 -- Max value
    );
    Port(
        SYS_CLK : in STD_LOGIC; -- System clock 100MHZ
        RESET : in STD_LOGIC; -- Resets the clock
        LIMIT : in INTEGER; -- Counter limit
        CE : out STD_LOGIC -- Clock enable
    );
end entity;

architecture Behavioral of prescaler is
    signal count : unsigned (WIDTH - 1 downto 0) := (others => '0'); 
begin
    process(SYS_CLK, RESET)
    begin
        if rising_edge(SYS_CLK) then
            if RESET = '1' then
                count <= (others => '0');
                CE <= '0';
            elsif count >= LIMIT then
                count <= (others => '0');
                CE <= '1';
            else
                count <= count + 1;
                CE <= '0';
            end if;
        end if;
    end process;
end Behavioral;
