----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity adxl is
end adxl;

architecture Behavioral of adxl is
    constant clock_period:time := 10 ns;
    signal clock: STD_LOGIC := '0';
    
    signal spi_mosi: STD_LOGIC := '0';
    signal spi_miso: STD_LOGIC := '0';
    signal spi_ss : STD_LOGIC := '0';
    signal spi_sclk : STD_LOGIC := '0';


    signal start : STD_LOGIC := '0';
    signal done : STD_LOGIC := '0';
    signal x : STD_LOGIC_VECTOR(7 downto 0); -- Data passed to the SPI interface
    signal y : STD_LOGIC_VECTOR(7 downto 0); -- Data passed to the SPI interface
    signal z : STD_LOGIC_VECTOR(7 downto 0); -- Data passed to the SPI interface
begin
    
    uut: entity work.adxl_ctrl
    port map(
        SYS_CLK => clock,
        START => start,
        
        -- SPI Interface signals
        MISO => spi_miso,
        MOSI => spi_mosi,
        SCLK => spi_sclk,
        CSN  => spi_ss,

        -- Data Signals
        X_DATA => x,
        Y_DATA => y,
        Z_DATA => z,
        FIN  => done
    );

    clk: process
    begin
        wait for clock_period/2;
        clock <= not clock;
    end process;
    
    stimuli2: process
    begin
        spi_miso <= '1';
        wait for clock_period;
    end process;
    
    stimuli: process
    begin
        start <= '1';
        wait for 2*clock_period;
        start <= '0';
    end process;

end Behavioral;
