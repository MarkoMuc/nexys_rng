----------------------------------------------------------------------------------
-- Author: Marko Z. Muc
--
-- Description:
--  - SPI simulation.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_sim is
end spi_sim;

architecture Behavioral of spi_sim is
    constant clock_period:time := 10 ns;
    constant doutc: STD_LOGIC_VECTOR(7 downto 0) := x"F0";
    signal clock: STD_LOGIC := '0';
    signal mosiv: STD_LOGIC := '0';
    signal misov: STD_LOGIC := '0';
    signal ss : STD_LOGIC := '0';
    signal sclkv : STD_LOGIC := '0';
    
    signal hold : STD_LOGIC := '0';
    signal donev: STD_LOGIC := '0';

    signal dinv : STD_LOGIC_VECTOR(7 downto 0):= X"00";
    signal doutv : STD_LOGIC_VECTOR(7 downto 0):= X"00";
    signal start : STD_LOGIC := '0';
 
begin
    dinv <= doutc;
    
    uut: entity work.spi_master(Behavioral)
    generic map(
        SYS_CLK_FREQ => 1e8,
        SCLK_FREQ => 1e6
    )
    port map(
        SYS_CLK => clock,
        RESET => '0',
        START => start,
        Din => dinv,
        HOLD_SS => hold, 
        Dout => doutv,
        DONE => donev,
        MISO => misov, 
        MOSI => mosiv,
        SCLK => sclkv,
        CS => ss);

    clk: process
    begin
        wait for clock_period/2;
        clock <= not clock;
    end process;
    
    stimuli: process
    begin
        start <= '1';
        wait for 2*clock_period;
        start <= '0';
    end process;

end Behavioral;