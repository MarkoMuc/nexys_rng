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
        SYS_CLK : in STD_LOGIC; -- System clk
        START: in STD_LOGIC; -- Start reading
        
        -- SPI Interface signals
        MISO: in STD_LOGIC; -- MISO
        MOSI : out STD_LOGIC; -- MOSI
        SCLK : out STD_LOGIC; -- SCLK
        CSN : out STD_LOGIC; -- CSN, active low

        -- Data Signals
        X_DATA : out STD_LOGIC_VECTOR(7 downto 0); -- X data, 8 bit resolution
        Y_DATA : out STD_LOGIC_VECTOR(7 downto 0); -- Y data, 8 bit resolution
        Z_DATA : out STD_LOGIC_VECTOR(7 downto 0); -- Z data, 8 bit resolution
        FIN : out STD_LOGIC -- Finished signal
    );
end adxl_ctrl;

architecture Behavioral of adxl_ctrl is
    -- ADXL constants
    constant START_ADR: STD_LOGIC_VECTOR(7 downto 0) := X"08"; -- Start address of the data registers. Read x08=x, x09=y, x0A=z
    constant PCR_ADR: STD_LOGIC_VECTOR(7 downto 0) := X"2D"; -- Power Control Register address
    constant W_CMD: STD_LOGIC_VECTOR(7 downto 0) := X"0A"; -- Write command
    constant R_CMD: STD_LOGIC_VECTOR(7 downto 0) := X"0B"; -- Read command
    constant M_CMD: STD_LOGIC_VECTOR(7 downto 0) := X"02"; -- Measurement mode

    -- STATE signals
    type STATES is (
        ST_ACT, -- Active. Set accelerometer to measure mode.
        ST_IDLE, -- Go to idle mode, no need to read.
        ST_INIT, -- Initialize/reset all signals.
        ST_READ, -- Start read, read the 8 byte register.
        ST_DONE -- Pass done signal and shift out read data.
    );
    signal state: STATES := ST_ACT; 
    signal next_state : STATES := ST_ACT;
    
    -- SPI signals
    component spi_master is
        generic(
            SYS_CLK_FREQ : integer := 1e8;
            SCLK_FREQ : integer := 1e6
        );
        Port (
            SYS_CLK : in STD_LOGIC;
            RESET : in STD_LOGIC;
            START : in STD_LOGIC;
            Din : in STD_LOGIC_VECTOR(7 downto 0);
            HOLD_SS : in STD_LOGIC;
            Dout : out STD_LOGIC_VECTOR(7 downto 0);
            DONE: out STD_LOGIC;
          
            MISO : in STD_LOGIC;
            MOSI : out STD_LOGIC;
            SCLK : out STD_LOGIC;
            CS : out STD_LOGIC
        );
    end component;

    signal done_spi : STD_LOGIC := '0'; -- SPI writes/reads done
    signal start_spi : STD_LOGIC := '0'; -- SPI writes/reads start
    signal byte_count : integer := 0; -- Counts received/transfered bytes
    signal spi_done_sig : STD_LOGIC := '0'; -- Done signal from spi
    signal hold_ss : STD_LOGIC := '0'; -- Multi byte transfer
    signal start_int : STD_LOGIC := '0'; -- Start SPI
    signal dout: STD_LOGIC_VECTOR(7 downto 0); -- SPI dout 

    -- Data signals
    type spi_data is array(0 to 2) of STD_LOGIC_VECTOR(7 downto 0);
    
    constant activate_data: spi_data := (W_CMD, PCR_ADR, M_CMD);
    constant read_data: spi_data := (R_CMD, START_ADR, x"00");
    
    -- signal x_vec: STD_LOGIC_VECTOR(7 downto 0); -- X data, 8 bit resolution
    -- signal y_vec: STD_LOGIC_VECTOR(7 downto 0); -- Y data, 8 bit resolution
    -- signal z_vec: STD_LOGIC_VECTOR(7 downto 0); -- Z data, 8 bit resolution    
    signal dout_array : spi_data := (x"00", x"00", x"00");
    signal spi_in : STD_LOGIC_VECTOR(7 downto 0) := x"00"; -- Data passed to the SPI interface
    
    -- Control signals
    signal reset_int : STD_LOGIC := '1'; -- Resets counters
begin
    hold_ss <= '1' when state = ST_ACT or state = ST_READ else '0';
    reset_int <= '1' when state = ST_IDLE or state = ST_DONE else '0';
    X_DATA <= dout_array(2);
    Y_DATA <= dout_array(1);
    Z_DATA <= dout_array(0);
    
    spi_interface: spi_master
    generic map(
        SYS_CLK_FREQ => 1e8,
        SCLK_FREQ => 1e6
    )
    port map(
        SYS_CLK => SYS_CLK,
        RESET => reset_int,
        START => start_int,
        Din => spi_in,
        HOLD_SS => hold_ss, 
        Dout => dout,
        DONE => spi_done_sig,
        MISO => MISO,
        MOSI => MOSI,
        SCLK => SCLK,
        CS => CSN);
    
    BYTE_TR: process(SYS_CLK, spi_done_sig, reset_int)
    begin
        if rising_edge(SYS_CLK) then
            if reset_int = '1' then
                byte_count <= 0;
            elsif spi_done_sig = '1' then
                byte_count <= byte_count + 1 ;
            end if;
        end if;
    end process;
    
    SAVE_OUT: process(SYS_CLK, byte_count, spi_done_sig, state)
    begin
        if rising_edge(SYS_CLK) then
            if state = ST_READ and byte_count > 2 and spi_done_sig = '1' then
                    dout_array(5 - byte_count) <= dout;
            end if;
        end if;
    end process;
    
    OUTPUT_DECODE: process(state, spi_in, byte_count)
    begin
        case state is
            when ST_ACT =>
                spi_in <= activate_data(byte_count) when byte_count <= 2 else x"00";
            --when ST_IDLE =>
            --when ST_INIT =>
            when ST_READ =>
                spi_in <= x"00" when byte_count > 2 else read_data(byte_count);
            when ST_DONE =>
                FIN <= '0';
            when others =>
                spi_in <= spi_in;
        end case;
    end process;
    
    start_int <= '1' when state = ST_IDLE or state = ST_READ or state = ST_ACT else '0';
    
    start_spi <= '1' when state = ST_INIT else '0';
    done_spi <= '1' when ((state = ST_ACT and byte_count > 3) or (state = ST_READ and byte_count > 5)) else '0';

    SYNC_PROC: process(SYS_CLK, next_state)
    begin
        if RISING_EDGE(SYS_CLK) then
            state <= next_state;
        end if;
    end process;
    
    NEXT_STATE_DECODE: process(START, state, done_spi, start_spi)
    begin
        next_state <= state;
        case state is
            when ST_ACT => if done_spi = '1' then next_state <= ST_IDLE; end if;
            when ST_IDLE => if START = '1' then next_state <= ST_INIT; end if;
            when ST_INIT => if start_spi = '1' then next_state <= ST_READ; end if;
            when ST_READ => if done_spi = '1' then next_state <= ST_DONE; end if;
            when ST_DONE => next_state <= ST_IDLE;
            when others => next_state <= ST_IDLE;
        end case;
    end process;
end Behavioral;
