----------------------------------------------------------------------------------
-- SPI master inteface.
-- Used to communicate over the SPI inteface.
-- Author: Marko Z. Muc
--
-- Description:
--  - HOLD_SS signal is used to transfer multiple bytes.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_master is
    generic(
        SYS_CLK_FREQ : integer := 1e8; -- Default is 100MHz
        SCLK_FREQ : integer := 1e6 -- Default is 1Mhz
    );
    Port (
        SYS_CLK : in STD_LOGIC; -- System clock
        RESET : in STD_LOGIC; -- Reset SPI interface
        START : in STD_LOGIC; -- Start transmission
        Din : in STD_LOGIC_VECTOR(7 downto 0); -- Data to be transmitted
        HOLD_SS : in STD_LOGIC; -- For multi-byte transfers
        Dout : out STD_LOGIC_VECTOR(7 downto 0); -- Data to be transmitted
        DONE: out STD_LOGIC; -- Done transmitting/receiving

        -- SPI Interface Signals 
        MISO : in STD_LOGIC; -- Master In Slave Out
        MOSI : out STD_LOGIC; -- Master Out Slave In
        SCLK : out STD_LOGIC; -- SPI clock
        CS : out STD_LOGIC -- Chip select
    );
end entity;

architecture Behavioral of spi_master is
    -- Signals and components for the SCLK
    component sclk_gen is
        generic(
            WIDTH: INTEGER := 32;
            SYS_CLK_FREQ : INTEGER := 1e8;
            SCLK_FREQ : INTEGER := 1e6
        );
        Port(
            SYS_CLK : in STD_LOGIC;
            RESET : in STD_LOGIC;
            CE : out STD_LOGIC;
            CE_2X : out STD_LOGIC);
    end component;
    
    
    signal sclk_2x : STD_LOGIC := '0'; -- 2x SCLK Internal
    signal sclk_int : STD_LOGIC := '0'; -- Internal SCLK
    
    -- State Machine
    type STATES is (
        ST_IDLE, -- Idle state 
        ST_INIT, -- Initialize state 
        ST_TRD, -- Transmit/Receive data state 
        ST_DONE -- Finished transmitting or receiving data 
    );

    -- Load in, Enable shift, Reset counters, Enable SCLK, Enable CS, Load out + 2 extra bits
    constant ST_IDLE_VEC: STD_LOGIC_VECTOR(7 downto 0) := "10100000";
    constant ST_INIT_VEC: STD_LOGIC_VECTOR(7 downto 0) := "00001001";
    constant ST_TRD_VEC: STD_LOGIC_VECTOR(7 downto 0) :=  "01011011";
    constant ST_DONE_VEC: STD_LOGIC_VECTOR(7 downto 0) := "00001110";
    
    signal state, next_state : STATES := ST_IDLE; -- State control signals
    signal start_trd, done_trd : STD_LOGIC := '0'; -- State transition signals
    signal state_vector : STD_LOGIC_VECTOR(7 downto 0) := ST_IDLE_VEC;
    
    -- Control signals
    signal reset_int : STD_LOGIC := '0'; -- Internal reset signal
    signal done_1 : STD_LOGIC := '0'; -- Used to delay done signal for one tick

    signal cnt_bits : INTEGER := 0; -- Counter for shifted bits
    signal shift_in  : STD_LOGIC := '0'; -- Shift data in
    signal shift_out : STD_LOGIC := '0'; -- Shift data out

    signal cs_int : STD_LOGIC := '1'; -- Internal cs signal
    signal reset_counters : STD_LOGIC := '0'; -- Reset counters and the SCLK before transmission
    
    signal load_in : STD_LOGIC := '0'; -- Load in new data to transmit
    signal load_out : STD_LOGIC := '0'; -- Load out received data
    
    signal en_shift : STD_LOGIC := '0'; -- Start shifting data IN/OUT
    signal en_sclk : STD_LOGIC := '0'; -- Start passing SCLK to SPI interface
    
    -- Data signals
    signal mosi_reg: STD_LOGIC_VECTOR(7 downto 0):= X"00"; -- MOSI shift register
    signal miso_reg: STD_LOGIC_VECTOR(7 downto 0):= X"00"; -- MISO shift register
begin
    -- Control signals
    load_in <= state_vector(7);
    en_shift <= state_vector(6);
    reset_counters <= state_vector(5);
    en_sclk <= state_vector(4);
    cs_int <= state_vector(3);
    load_out <= state_vector(2);

    -- SPI outputs
    CS <= '0' when RESET='0' and (HOLD_SS='1' or cs_int='1') else '1';
    MOSI <= mosi_reg(7);
    SCLK <= sclk_int when en_sclk='1' else '0'; 
    
    sclk_generator: sclk_gen
        generic map(
            WIDTH => 32,
            SYS_CLK_FREQ => SYS_CLK_FREQ,
            SCLK_FREQ => SCLK_FREQ)
        port map(
            SYS_CLK => SYS_CLK,
            RESET => reset_counters, 
            CE => sclk_int,
            CE_2X => sclk_2x);
    
    SET_DONE: process(SYS_CLK, load_out, done_1)
    begin
        if rising_edge(SYS_CLK) then
            --DONE_1 <= load_out;
            DONE <= load_out;
        end if;
    end process;

    LOAD_OUTPUT: process(SYS_CLK, load_out, miso_reg)
    begin
        if rising_edge(SYS_CLK) then
            if load_out = '1' then
                Dout <= miso_reg;
            end if;
        end if;
    end process;
    
    shift_in <= '1' when en_shift = '1' and sclk_2x = '1' and  sclk_int = '0' else '0';
    shift_out <= '1' when en_shift = '1' and sclk_2x = '1' and sclk_int = '1' else '0';
    
    SHIFT_INTO: process(SYS_CLK, shift_in, miso_reg)
    begin
        if rising_edge(SYS_CLK) then
            if shift_in = '1' then
                miso_reg(7 downto 0) <= miso_reg(6 downto 0) & MISO;
            end if;
        end if;

    end process;

    SHIFT_OUTOF: process(SYS_CLK, load_in, Din, shift_out, mosi_reg)
    begin
        if rising_edge(SYS_CLK) then
            if load_in = '1' then
                mosi_reg <= Din;
            elsif shift_out = '1' then
                mosi_reg (7 downto 0) <= MOSI_REG(6 downto 0) & '0';
            end if;
        end if;
    end process;
    
    COUNT_BITS: process(SYS_CLK, reset_counters, shift_out, cnt_bits)
    begin
        if RISING_EDGE(SYS_CLK) then
            if reset_counters = '1' then
                cnt_bits <= 0;
            elsif shift_out = '1' then
                if cnt_bits = 7 then
                    cnt_bits <= 0;
                else
                    cnt_bits <= cnt_bits + 1;
                end if;
            end if;
         end if;
    end process;

    OUTPUT_DECODE: process(state, load_in, en_shift, reset_counters, en_sclk, cs_int, load_out)
    begin
        case state is
            when ST_IDLE =>
                state_vector <= ST_IDLE_VEC;
            when ST_INIT =>
                state_vector <= ST_INIT_VEC;    
            when ST_TRD =>
                state_vector <= ST_TRD_VEC;
            when ST_DONE =>
                state_vector <= ST_DONE_VEC;
            when others =>
                state_vector <= ST_IDLE_VEC;
        end case;
    end process;

    start_trd <= '1' when state = ST_INIT and (HOLD_SS = '1' or (sclk_int = '1' and sclk_2x = '1')) else '0'; 
    done_trd <= '1' when state = ST_TRD and cnt_bits = 7 and sclk_int = '1' and sclk_2x = '1' else '0'; 
    
    SYNC_PROC: process(SYS_CLK, RESET, next_state)
    begin
        if RISING_EDGE(SYS_CLK) then
            if RESET = '1' then
                state <= ST_IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    NEXT_STATE_DECODE: process(START, state, start_trd, done_trd )
    begin
        next_state <= state;
        case state is
            when ST_IDLE => if START = '1' then next_state <= ST_INIT; end if;
            when ST_INIT => if start_trd = '1' then next_state <= ST_TRD; end if;
            when ST_TRD => if done_trd = '1' then next_state <= ST_DONE; end if;
            when ST_DONE => next_state <= ST_IDLE;
            when others => next_state <= ST_IDLE;
        end case;
    end process;

end Behavioral;
