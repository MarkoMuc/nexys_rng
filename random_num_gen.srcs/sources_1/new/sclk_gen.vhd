----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sclk_gen is
    generic(
        WIDTH : INTEGER := 32;
        SYS_CLK_FREQ : INTEGER := 1e8; -- Default is 100MHz
        SCLK_FREQ : INTEGER := 1e6 -- Default is 1Mhz
    );
    Port ( SYS_CLK : in STD_LOGIC;
           RESET : in STD_LOGIC;
           LIMIT : in INTEGER;
           CE : out STD_LOGIC);
end sclk_gen;

architecture Behavioral of sclk_gen is
    signal counter : UNSIGNED (WIDTH - 1 downto 0) := (others => '0');
    signal ce_int : STD_LOGIC := '0';
begin
    CE <= ce_int;
    
    division: process(SYS_CLK, RESET)
    begin
        if rising_edge(SYS_CLK) then
            if RESET = '1' then
                counter <= (others => '0');
                ce_int <= '0';
            elsif counter >= LIMIT then
                counter <= (others => '0');
                ce_int <= not ce_int;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
end Behavioral;
