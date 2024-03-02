----------------------------------------------------------------------------------
-- Shift register
-- PISO register
-- Author: Marko Z. Muc
--
-- Description:
--  - 8 bits of data + two control bits consist a package.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity shift_reg is
    Port(
        CLK : in STD_LOGIC; -- Clock for shifting 
        RESET : in STD_LOGIC; -- Reset the register
        WRITE_DATA : in STD_LOGIC; -- Start writing new data
        SR_EN : in STD_LOGIC; -- Enable/start shifting
        D : in STD_LOGIC_VECTOR (7 downto 0); -- Parallel in 
        S_OUT : out STD_LOGIC -- Serial out
    );
end entity;

architecture Behavioral of shift_reg is
    signal data : STD_LOGIC_VECTOR (9 downto 0);
begin

    process(CLK, RESET, WRITE_DATA, SR_EN)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                data <= (others => '1');
                S_OUT <= '1';
            else
                if WRITE_DATA = '1' then
                    data(0) <= '0';
                    data(8 downto 1) <= D;
                    data(9) <= '1';
                    S_OUT <= '1';
                elsif SR_EN = '1' then
                    S_OUT <= data(0);
                    data(8 downto 0) <= data(9 downto 1);
                    data(9) <= '1';
                    -- data <= '1' & data(9 downto 1);
                end if;
            end if;            
        end if;
    end process;

end Behavioral;