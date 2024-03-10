
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_test is
    Port ( CLK : in STD_LOGIC;
           CE_1 : out STD_LOGIC;
           CE_2 : out STD_LOGIC);
end clock_test;

architecture Behavioral of clock_test is
    constant DIV_RATE : integer := ((1e8 / ( 2 * 1e6)) - 1);
    signal count : unsigned (32 - 1 downto 0) := (others => '0');
    signal limit: integer := (1e8/1e6)/2 - 1;

    signal Reset_Counters : STD_LOGIC := '0';
    signal RESET : STD_LOGIC := '0';
    signal ce_int : STD_LOGIC := '0';
    
    signal SCLK_2X_DIV      : integer range 0 to DIV_RATE := 0;
    signal SCLK_2X_TICK     : STD_LOGIC := '0';
    signal SCLK_INT         : STD_LOGIC := '0';
begin
    CE_1 <= ce_int;
    CE_2 <= SCLK_INT;

    Div_2X_SCLK: process (CLK, Reset_Counters, SCLK_2X_DIV)
    begin
    if RISING_EDGE (CLK) then
        if Reset_Counters = '1' 
            or SCLK_2X_DIV = DIV_RATE then
                SCLK_2X_DIV <= 0;
        else
                SCLK_2X_DIV <= SCLK_2X_DIV + 1;
        end if;
    end if;
    end process Div_2X_SCLK;

    SCLK_2X_TICK <= '1' when SCLK_2X_DIV = DIV_RATE else '0';

    --Generate SCLK_INT;
    Gen_SCLK_INT: process (CLK, Reset_Counters, SCLK_2X_TICK, SCLK_INT)
    begin
    if RISING_EDGE (CLK) then
        if Reset_Counters = '1' then
            SCLK_INT <= '0';
        elsif SCLK_2X_TICK = '1' then
            SCLK_INT <= not SCLK_INT;
        end if;
    end if;
    end process Gen_SCLK_INT;

    s_gen: entity work.sckl_gen
    generic map(
        WIDTH => 32,
        SYS_CLK_FREQ => 1e8,
        SCLK_FREQ => 1e6
    )
    port map(
        SYS_CLK => CLK,
        RESET => RESET,
        LIMIT => limit,
        CE => ce_int.    );

end Behavioral;
