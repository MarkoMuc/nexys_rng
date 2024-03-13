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

    component accl_ctrl is
        Port(
            SYS_CLK : in STD_LOGIC;
            MISO: in STD_LOGIC;
            SCLK : out STD_LOGIC;
            CSN : out STD_LOGIC;
            MOSI : out STD_LOGIC;
            X_DATA : out STD_LOGIC_VECTOR(0 to 11);
            Y_DATA : out STD_LOGIC_VECTOR(0 to 11);
            Z_DATA : out STD_LOGIC_VECTOR(0 to 11);
            FIN : out STD_LOGIC
        );
    end component;
    
    type state is (
        ST_START, -- When device is programmed, waits for components to init.
        ST_PICK, -- Switch decides which RNG to use
        ST_GET, -- Send start and wait for data
        ST_SEND -- Sends data through UART
    );

    constant msgLen : integer := 12;

    type msg is Array(0 to msgLen) of STD_LOGIC_VECTOR(7 downto 0);
    signal message : msg := (
       x"48",
       x"65",
       x"6c",
       x"6c",
       x"6f",
       x"2c",
       x"20",
       x"57",
       x"6f",
       x"72",
       x"6c",
       x"64",
       x"21"
    );
    signal msg_vector : STD_LOGIC_VECTOR(7 downto 0);
    signal msgIndex : integer range 0 to msgLen := 0;
    signal start, doneSending, doneSendingOld : STD_LOGIC;
    signal sending, startSending : STD_LOGIC := '1';

    signal x_vec: STD_LOGIC_VECTOR(0 to 11); -- X data, 12 bit resolution
    signal y_vec: STD_LOGIC_VECTOR(0 to 11); -- Y data, 12 bit resolution
    signal z_vec: STD_LOGIC_VECTOR(0 to 11); -- Z data, 12 bit resolution

    signal fin_read, old_fin: STD_LOGIC;
    signal data_counter: integer := 0;

begin
    
    start <= startSending and sending;
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            doneSendingOld <= doneSending;
            old_fin <= fin_read;
            
            if old_fin = '0' and fin_read = '1' then
                startSending <= '1';
            end if;

            if doneSending = '1' and doneSendingOld = '0' and msgIndex < 3 then
                if msgIndex = 0 then msg_vector <= x_vec(0 to 7);
                elsif msgIndex = 1 then msg_vector <= y_vec(0 to 7);
                else msg_vector <= z_vec(0 to 7); end if;

                msgIndex <= msgIndex + 1;
                sending <= '1';
                startSending <= '1';
            elsif doneSending = '1' and doneSendingOld = '0' and msgIndex = 3 then
                msgIndex <= 0;
                sending <= '0';
                startSending <= '0';
            end if;

        end if;
    end process;

-- Used to read from the accelerometer
    acl_inst: accl_ctrl
        port map(
            SYS_CLK => CLK100MHZ,
            MISO => ACL_MISO, 
            SCLK => ACL_SCLK,
            CSN => ACL_CSN,
            MOSI => ACL_MOSI,
            X_DATA => x_vec,
            Y_DATA => y_vec,
            Z_DATA => z_vec,
            FIN => fin_read
        );

-- Used to transfer data through UART
    uart_inst: uart_ctrl
        port map(
            SYS_CLK => CLK100MHZ,
            VALUE => msg_vector,
            START => start,
            RXD_OUT => UART_RXD_OUT,
            FIN => doneSending);

-- Used to display the current mode    
    display_inst: display_ctrl
        port map(
            SYS_CLK => CLK100MHZ,
            MODE => SW,
            SEG_VEC => SEG,
            AN_VEC => AN);

end Behavioral;
