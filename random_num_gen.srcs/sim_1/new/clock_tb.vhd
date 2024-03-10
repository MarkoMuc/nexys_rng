
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_tb is
end clock_tb;

architecture Behavioral of clock_tb is
    constant clock_period:time := 10 ns;
    signal clock, ce_p, ce_sc : STD_LOGIC := '0';
begin

    clk: process
    begin
        wait for clock_period/2;
        clock <= not clock;
    end process;
    
    uut: entity work.clock_test
    port map(
        CLK => clock,
        CE_1 => ce_p,
        CE_2 => ce_sc
    );

end Behavioral;
