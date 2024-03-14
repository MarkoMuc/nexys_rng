----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_tb is
--  Port ( );
end top_tb;

architecture Behavioral of top_tb is
    constant clock_period:time := 10 ns;
    signal clock: STD_LOGIC := '0';
    
    signal spi_mosi: STD_LOGIC := '0';
    signal spi_miso: STD_LOGIC := '0';
    signal spi_ss : STD_LOGIC := '0';
    signal spi_sclk : STD_LOGIC := '0';

    signal sw_sig: STD_LOGIC := '0';
    signal uartr: STD_LOGIC := '0';
    signal uarts : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal uarta : STD_LOGIC_VECTOR(7 downto 0) := x"00";
begin
    utt: entity work.top
    port map(
        CLK100MHZ => clock,
        CPU_RESETN => '0',
        SW => sw_sig,
        ACL_MISO => spi_miso,
        ACL_SCLK => spi_mosi,
        ACL_CSN => spi_ss,
        ACL_MOSI => spi_sclk, 
        UART_RXD_OUT => uartr,
        SEG => uarts,
        AN => uarta
    );

    clk: process
    begin
        wait for clock_period/2;
        clock <= not clock;
    end process;
    
    stimuli2: process
    begin
        sw_sig <= '1';
        wait for clock_period/2;
    end process;
end Behavioral;
