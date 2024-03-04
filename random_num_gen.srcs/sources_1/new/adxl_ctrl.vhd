----------------------------------------------------------------------------------
-- ADXL362 controller.
-- ADXL362 sensor controller.
-- Author: Marko Z. Muc
--
-- Description:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adxl_ctrl is
    Port(
        SYS_CLK : in STD_LOGIC;
        MISO: in STD_LOGIC; -- MISO
        SCLK : out STD_LOGIC; -- SCLK
        CSN : out STD_LOGIC; -- CSN, active low
        MOSI : out STD_LOGIC; -- MOSI
        X_DATA : out STD_LOGIC_VECTOR(0 to 11); -- X data, 12 bit resolution
        Y_DATA : out STD_LOGIC_VECTOR(0 to 11); -- Y data, 12 bit resolution
        Z_DATA : out STD_LOGIC_VECTOR(0 to 11); -- Z data, 12 bit resolution
        FIN : out STD_LOGIC -- Finished signal
    );
end adxl_ctrl;

architecture Behavioral of adxl_ctrl is
    constant START_ADR: STD_LOGIC_VECTOR(0 to 7) := X"0E"; -- Start address of the data registers.
    constant PCR_ADR: STD_LOGIC_VECTOR(0 to 7) := X"2D"; -- Power Control Register address
    constant W_CMD: STD_LOGIC_VECTOR(0 to 7) := X"0A"; -- Write command
    constant R_CMD: STD_LOGIC_VECTOR(0 to 7) := X"0B"; -- Read command
    constant M_CMD: STD_LOGIC_VECTOR(0 to 7) := X"02"; -- Measurement mode
    constant WAIT_5: integer := 500000; -- Wait 5ms limit
    constant WAIT_10: integer := 1000000; -- Wait 10ms limit
    constant WAIT_40: integer := 4000000; -- Wait 40ms limit
    constant PRESCALER_MAX: integer := 100e6/5e6 - 1; -- 5Mhz prescaler limit

    type STATES is (
        ST_INIT1, ST_WCMD, ST_PCR, ST_MCMD,
        ST_INIT2, ST_RCMD, ST_SREG, ST_XL, ST_XH,
        ST_YL, ST_YH, ST_ZL, ST_ZH, ST_WAIT);
    signal state: STATES := ST_INIT1; 
    signal next_state : STATES := ST_INIT1;
    
    signal x_vec: STD_LOGIC_VECTOR(0 to 11); -- X data, 12 bit resolution
    signal y_vec: STD_LOGIC_VECTOR(0 to 11); -- Y data, 12 bit resolution
    signal z_vec: STD_LOGIC_VECTOR(0 to 11); -- Z data, 12 bit resolution    
    signal fin_sig: STD_LOGIC:= '0'; -- Finished signal

    -- State machine
    signal t_bits: integer := 0; -- Amount of transfered bits
    signal bit_count: integer := 0; -- Current bit to write to
    signal cs_bit: STD_LOGIC := '1'; -- Chip select signal
    signal out_bit: STD_LOGIC; -- SPI MOSI signal
    signal spi_clk: STD_LOGIC; -- SPI clock signal

    -- Waiting process signals
    signal START: STD_LOGIC := '0'; -- To move to next state
    signal start_count: STD_LOGIC := '0'; -- Start count internal signal
    signal count_to: integer := 0; -- Max number to count to
    signal wait_counter: integer := 0; -- Currect count
    signal old_startc: STD_LOGIC  := '0'; -- Currect count
begin
    CSN <= cs_bit;
    MOSI <= out_bit;
    FIN <= fin_sig;
    SCLK <= spi_clk;
    X_DATA <= x_vec;
    Y_DATA <= y_vec;
    Z_DATA <= z_vec;
    
    sclk_gen: entity work.prescaler(Behavioral)
    generic map(WIDTH => 8)
    port map(
        SYS_CLK => SYS_CLK,
        RESET => '0',
        LIMIT => PRESCALER_MAX,
        CE => spi_clk
    );
    
    waiting: process(SYS_CLK, count_to, start_count)
    begin
        if rising_edge(SYS_CLK) then
            wait_counter <= wait_counter + 1;
            old_startc <= start_count;

            if old_startc = '0' and start_count = '1' then
                wait_counter <= 0;
            end if;
            
            if start_count = '1' and wait_counter >= count_to then
                START <= '1';
            else
                START <= '0';
            end if;
            
            if wait_counter >= count_to then
                wait_counter <= 0;
            end if;
        end if;
    end process;

    OUTPUT_DECODE: process(STATE, START, spi_clk, t_bits, bit_count, fin_sig)
    begin
        if t_bits >= 7 then
            t_bits <= 0;
        end if;
        
        if bit_count >= 11 then
            bit_count <= 0;     
        end if;
        
        case state is
            when ST_INIT1 =>
                cs_bit <= '1';
                start_count <= '1';
                count_to <= WAIT_5;
                t_bits <= 0;
            when ST_WCMD =>
                start_count <= '0';
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    out_bit <= W_CMD(t_bits);
                end if;
            when ST_PCR =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    out_bit <= PCR_ADR(t_bits);
                end if;
            when ST_MCMD =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    out_bit <= M_CMD(t_bits);
                end if;
            when ST_INIT2 =>
                cs_bit <= '1';
                start_count <= '1';
                count_to <= WAIT_40; 
                t_bits <= 0;

            -- Reading --
            when ST_RCMD =>
                fin_sig <= '0';
                start_count <= '0';
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    out_bit <= R_CMD(t_bits);
                end if;
            when ST_SREG =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    out_bit <= START_ADR(t_bits);
                end if;
            when ST_XL =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    x_vec(7 - bit_count) <= MISO;
                end if;
            when ST_XH =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    x_vec(15 - bit_count) <= MISO;
                end if;
            when ST_YL =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    y_vec(7 - bit_count) <= MISO;
                end if;
            when ST_YH =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    y_vec(15 - bit_count) <= MISO;
                end if;
            when ST_ZL =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    z_vec(7 - bit_count) <= MISO;
                end if;
            when ST_ZH =>
                cs_bit <= '0';
                if falling_edge(spi_clk) then
                    t_bits <= t_bits + 1;
                    bit_count <= bit_count + 1;
                    z_vec(15 - bit_count) <= MISO;
                end if;
            WHEN ST_WAIT =>
                fin_sig <= '1';
                cs_bit <= '1';
                start_count <= '1';
                count_to <= WAIT_10;
                t_bits <= 0;
            when others =>
                fin_sig <= fin_sig;
                start_count <= '0';
                cs_bit <= '0';
                t_bits <= 0;
        end case;
    end process;

    NEXT_STATE_DECODE: process(state, START, t_bits)
    begin
        next_state <= state;
        case state is
            when ST_INIT1 =>
                if START = '1' then next_state <= ST_WCMD; end if;
            when ST_WCMD =>
                if t_bits >= 7 then next_state <= ST_PCR; end if;
            when ST_PCR =>
                if t_bits >= 7 then next_state <= ST_MCMD; end if;
            when ST_MCMD =>
                if t_bits >= 7 then next_state <= ST_INIT2; end if;
            when ST_INIT2 =>
                if START = '1' then next_state <= ST_RCMD; end if;
            when ST_RCMD =>
                if t_bits >= 7 then next_state <= ST_SREG; end if;
            when ST_SREG =>
                if t_bits >= 7 then next_state <= ST_XL; end if;
            when ST_XL =>
                if t_bits >= 7 then next_state <= ST_XH; end if;
            when ST_XH =>
                if t_bits >= 7 then next_state <= ST_YL; end if;
            when ST_YL =>
                if t_bits >= 7 then next_state <= ST_YH; end if;
            when ST_YH =>
                if t_bits >= 7 then next_state <= ST_ZL; end if;
            when ST_ZL =>
                if t_bits >= 7 then next_state <= ST_ZH; end if;
            when ST_ZH =>
                if t_bits >= 7 then next_state <= ST_WAIT; end if;
            when ST_WAIT =>
                if START = '1' then next_state <= ST_RCMD; end if;
            when others =>
                next_state <= ST_WAIT;        
        end case;
    end process;

end Behavioral;
