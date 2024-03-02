----------------------------------------------------------------------------------
-- TX controller for UART.
-- Contains a state machine for transfering data.
-- Author: Marko Z. Muc
--
-- Description:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx_ctrl is
    Port(
        SYS_CLK : in STD_LOGIC; -- 100MHz clock for shifting 
        RESET : in STD_LOGIC; -- Reset the register
        START : in STD_LOGIC; -- Start UART communication
        TX_CLK : in STD_LOGIC; -- TX clock/baud rate
        PSC_RESET : out STD_LOGIC; -- Reset prescaler
        WRITE_DATA : out STD_LOGIC; -- Start writing new data
        SR_EN : out STD_LOGIC; -- Enable/start shifting
        FIN : out STD_LOGIC
    );
end entity;

architecture Behavioral of tx_ctrl is
    type STATES is (
        ST_RESET, ST_IDLE, ST_START, ST_B0, ST_B1, ST_B2,
        ST_B3, ST_B4, ST_B5, ST_B6, ST_B7, ST_STOP);
    signal state, next_state : STATES;
    signal psc_r, wd, shift, fin_i : STD_LOGIC;
begin
    SYNC_PROC: process(SYS_CLK, RESET)
    begin
        if rising_edge(SYS_CLK) then
            if RESET = '1' then
                state <= ST_RESET;
                PSC_RESET <= '0';
                WRITE_DATA <= '0';
                SR_EN <= '0';
                FIN <= '0';
            else
                state <= next_state;
                PSC_RESET <= psc_r;
                WRITE_DATA <= wd;
                SR_EN <= shift;
                FIN <= fin_i;
            end if;
        end if;
    end process;
    
    -- MEALY State-Machine, outputs based on state and inputs
    OUTPUT_DECODE: process(STATE, START, TX_CLK, fin_i)
    begin
        psc_r <= '0';
        wd <= '0';
        shift <= '0';
        fin_i <= '0';

        case state is
            when ST_RESET =>
                wd <= '1';
            when ST_IDLE =>
                if START = '1' then
                    psc_r <= '1';
                    shift <= '1';
                end if;
            when ST_START| ST_B0| ST_B1| ST_B2| ST_B3|
                 ST_B4| ST_B5| ST_B6| ST_B7 =>
                if TX_CLK = '1' then
                    shift <= '1';
                end if;
            when ST_STOP =>
                fin_i <= '1';
                if TX_CLK = '1' then
                    shift <= '1';
                end if;
            when others =>
                psc_r <= '0';
                wd <= '0';
                shift <= '0';
                fin_i <= '0';
        end case;        
    end process;

    NEXT_STATE_DECODE: process(state, START, TX_CLK)
    begin
        next_state <= state;
        case (state) is
            when ST_RESET =>
                next_state <= ST_IDLE;
            when ST_IDLE =>
                if START = '1' then next_state <= ST_START; end if;
            when ST_START =>
                if TX_CLK = '1' then next_state <= ST_B0; end if;
            when ST_B0 =>
                if TX_CLK = '1' then next_state <= ST_B1; end if;
            when ST_B1 =>
                if TX_CLK = '1' then next_state <= ST_B2; end if;
            when ST_B2 =>
                if TX_CLK = '1' then next_state <= ST_B3; end if;
            when ST_B3 =>
                if TX_CLK = '1' then next_state <= ST_B4; end if;
            when ST_B4 =>
                if TX_CLK = '1' then next_state <= ST_B5; end if;
            when ST_B5 =>
                if TX_CLK = '1' then next_state <= ST_B6; end if;
            when ST_B6 =>
                if TX_CLK = '1' then next_state <= ST_B7; end if;
            when ST_B7 =>
                if TX_CLK = '1' then next_state <= ST_STOP; end if;
            when ST_STOP =>
                if TX_CLK = '1' then next_state <= ST_RESET; end if;
            when others =>
                next_state <= ST_RESET;
        end case;
    end process;
end Behavioral;