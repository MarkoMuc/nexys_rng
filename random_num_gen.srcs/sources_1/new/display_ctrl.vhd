----------------------------------------------------------------------------------
-- Display controller.
-- Used to display the current mode.
-- Author: Marko Z. Muc
--
-- Description:
--  - Displays the current mode on the screen.
--  - SEG_VEC controls the catodes(segments).
--  - AN_VEC controls the digit, we only need one of the digits.
--  - Both anodes and catodes are active low.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_ctrl is
    Port(
        SYS_CLK : in STD_LOGIC; -- System clk 100MHZ
        MODE : in STD_LOGIC; -- Button
        SEG_VEC : out STD_LOGIC_VECTOR (0 to 7); -- Catodes
        AN_VEC : out STD_LOGIC_VECTOR (7 downto 0) -- Anodes
    );
end display_ctrl;

architecture Behavioral of display_ctrl is
    signal digit : STD_LOGIC_VECTOR(0 to 7) := "00000011";
begin
    display : process(SYS_CLK, MODE, digit)
    begin
        if rising_edge(SYS_CLK) then
            if MODE = '0' then
                digit <= "00000011";
            elsif MODE = '1' then
                digit <= "10011111";
            end if;     
        end if;        
    end process;

    SEG_VEC <= digit;
    AN_VEC <= "11111110";
end Behavioral;
