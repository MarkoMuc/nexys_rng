----------------------------------------------------------------------------------
-- Uart controller.
-- Used to send Randomly generated numbers using the UART protocol.
-- Author: Marko Z. Muc
--
-- Description:
--  - Packet : STARTBIT + 8BITS + STOP BIT
--    - Bits are in LSB 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_ctrl is
    Port(
        SYS_CLK : in STD_LOGIC; -- 100 MHz clock
        VALUE : in STD_LOGIC_VECTOR (7 downto 0); -- Value to transfer
        START : in STD_LOGIC; -- Start transfer
        RXD_OUT : out STD_LOGIC; -- RXD out
        FIN : out std_logic
    );
end entity;

architecture Behavioral of uart_ctrl is
    constant baud_rate_limit : integer := 100e6/ 9600 - 1; -- 14 bits needed, 10415
    
    signal clock, i_reset, prescaler_reset, i_start : STD_LOGIC;
    signal psc_r, wd, shift, tx_clk : STD_LOGIC; 
begin
    clock <= SYS_CLK;
    i_reset <= '0';
    prescaler_reset <= i_reset or psc_r;

    baud_rate_gen: entity work.prescaler(Behavioral)
        generic map(WIDTH => 14)
        port map(
            SYS_CLK => clock,
            RESET => prescaler_reset,
            LIMIT => baud_rate_limit,
            CE => tx_clk
        );
    
    PISO: entity work.shift_reg(Behavioral)
        port map(
            CLK => clock, 
            RESET => i_reset,
            WRITE_DATA => wd,
            SR_EN => shift,
            D => VALUE,
            S_OUT => RXD_OUT
        );

    controller: entity work.tx_ctrl(Behavioral)
        port map(
            SYS_CLK => clock,
            RESET => i_reset,
            START => START,
            TX_CLK => tx_clk,
            PSC_RESET => psc_r,
            WRITE_DATA => wd,
            SR_EN => shift,
            FIN => FIN
        );
end Behavioral;
