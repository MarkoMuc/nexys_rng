----------------------------------------------------------------------------------
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port(
        CLK100MHZ : in STD_LOGIC; -- System clk 100MHZ
        CPU_RESETN : in STD_LOGIC; -- CPU reset button
        SW : in STD_LOGIC; -- Switch J15 for switching modes
        ACL_MISO: in STD_LOGIC; -- Accelerometer master in slave out
---------------------------------------------------------------------------------        
        ACL_SCLK : out STD_LOGIC; -- Accelerometer SPI SCLK
        ACL_CSN : out STD_LOGIC; -- Accelerometer chip select
        ACL_MOSI: out STD_LOGIC; -- ACcelerometer master out slave in
        UART_RXD_OUT : out STD_LOGIC; -- UART TX
        SEG : out STD_LOGIC_VECTOR (0 to 7); -- Catodes
        AN : out STD_LOGIC_VECTOR (7 downto 0) -- Digits
    );
end top;

architecture Behavioral of top is
    component display_ctrl is
        Port(
            SYS_CLK : in STD_LOGIC;
            MODE : in STD_LOGIC;
            SEG_VEC : out STD_LOGIC_VECTOR (0 to 7);
            AN_VEC : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;
    
    component uart_ctrl is
        Port(
            SYS_CLK : in STD_LOGIC;
            VALUE : in STD_LOGIC_VECTOR (7 downto 0);
            START : in STD_LOGIC;
            RXD_OUT : out STD_LOGIC;
            FIN : out STD_LOGIC
        );
    end component;

    component adxl_ctrl is
        Port(
            SYS_CLK : in STD_LOGIC;
            START: in STD_LOGIC;
            
            MISO: in STD_LOGIC;
            MOSI : out STD_LOGIC;
            SCLK : out STD_LOGIC;
            CSN : out STD_LOGIC;

            X_DATA : out STD_LOGIC_VECTOR(7 downto 0);
            Y_DATA : out STD_LOGIC_VECTOR(7 downto 0);
            Z_DATA : out STD_LOGIC_VECTOR(7 downto 0);
            FIN : out STD_LOGIC
        );
    end component;
    
    -- State signals
    type STATES is (
        ST_PICK, -- Switch decides which RNG to use
        ST_GET, -- Send start and wait for data
        ST_SEND -- Sends data through UART
    );
    
    signal state : STATES := ST_PICK; 
    signal next_state : STATES := ST_PICK; 

    type msg is Array(0 to 2) of STD_LOGIC_VECTOR(7 downto 0);
    signal data_array : msg := (x"00", x"00", x"00");
    signal msg_vector : STD_LOGIC_VECTOR(7 downto 0);

    signal msg_index : integer := 0;
    signal start, done_sending, done_sending_old : STD_LOGIC;
    signal sending : STD_LOGIC := '1';
    
    constant msg_max: integer := 3;
    signal accl_done: STD_LOGIC := '0'; 
    signal start_accl : STD_LOGIC := '0';
    signal sent_data : STD_LOGIC := '0';
    signal received_data : STD_LOGIC := '0';

begin
    start_accl <= '1' when state = ST_GET and SW = '1' else '0';
    start <= '1' when state = ST_SEND else '0';
    
    send_data: process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            done_sending_old <= done_sending;

            if done_sending = '1' and done_sending_old = '0' and msg_index < msg_max then
                msg_vector <= data_array(msg_index);
                msg_index <= msg_index + 1;
                
            elsif msg_index = msg_max then
                msg_index <= 0;
            end if;

        end if;
    end process;

-- Used to read from the accelerometer
    acl_inst: adxl_ctrl
    port map(
        SYS_CLK => CLK100MHZ,
        START => start_accl, 
        
        -- SPI Interface signals
        MISO => ACL_MISO, 
        MOSI => ACL_MOSI,
        SCLK => ACL_SCLK,
        CSN => ACL_CSN,

        -- Data Signals
        X_DATA => data_array(0),
        Y_DATA => data_array(1),
        Z_DATA => data_array(2),
        FIN => accl_done
    );

-- Used to transfer data through UART
    uart_inst: uart_ctrl
        port map(
            SYS_CLK => CLK100MHZ,
            VALUE => msg_vector,
            START => start,
            RXD_OUT => UART_RXD_OUT,
            FIN => done_sending);

-- Used to display the current mode    
    display_inst: display_ctrl
        port map(
            SYS_CLK => CLK100MHZ,
            MODE => SW,
            SEG_VEC => SEG,
            AN_VEC => AN);
    
    received_data <= '1' when state = ST_GET and (accl_done = '1') else '0';
    sent_data <= '1' when state = ST_SEND and msg_index = msg_max else '0';
    
    SYNC_PROC: process(CLK100MHZ, next_state)
    begin
        if RISING_EDGE(CLK100MHZ) then
            state <= next_state;
        end if;
    end process;
    
    NEXT_STATE_DECODE: process(START, state, received_data, sent_data)
    begin
        next_state <= state;
        case state is
            when ST_PICK => next_state <= ST_GET;
            when ST_GET => if received_data = '1' then next_state <= ST_SEND; end if;
            when ST_SEND => if sent_data = '1' then next_state <= ST_PICK; end if;
            when others => next_state <= ST_PICK;
        end case;
    end process;

end Behavioral;
