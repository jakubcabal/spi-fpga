--------------------------------------------------------------------------------
-- PROJECT: SPI MASTER AND SLAVE FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/spi-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPIRIT_LEVEL_CYC1000 is
    Port (
        CLK_12M   : in  std_logic; -- system clock 12 MHz
        RST_BTN_N : in  std_logic; -- low active reset button
        -- SPI MASTER INTERFACE TO LIS3DH SENSOR
        SCLK      : out std_logic;
        CS_N      : out std_logic;
        MOSI      : out std_logic;
        MISO      : in  std_logic;
        -- USER LEDS
        USER_LEDS : out std_logic_vector(8-1 downto 0)
    );
end entity;

architecture RTL of SPIRIT_LEVEL_CYC1000 is

    signal rst_btn      : std_logic;
    signal reset        : std_logic;

    signal spi_din      : std_logic_vector(8-1 downto 0);
    signal spi_din_last : std_logic;
    signal spi_din_vld  : std_logic;
    signal spi_din_rdy  : std_logic;
    signal spi_dout     : std_logic_vector(8-1 downto 0);
    signal spi_dout_vld : std_logic;

    type state is (cfg1_addr, cfg1_wr, out_addr, out_rd, out_do);
    signal fsm_pstate   : state;
    signal fsm_nstate   : state;

    signal sensor_wr    : std_logic;
    signal sensor_data  : std_logic_vector(8-1 downto 0);
    signal sensor_sigd  : signed(8-1 downto 0);

begin

    rst_btn <= not RST_BTN_N;

    rst_sync_i : entity work.RST_SYNC
    port map (
        CLK        => CLK_12M,
        ASYNC_RST  => rst_btn,
        SYNCED_RST => reset
    );

    spi_master_i : entity work.SPI_MASTER
    generic map(
        CLK_FREQ    => 12e6,
        SCLK_FREQ   => 1e6,
        SLAVE_COUNT => 1
    )
    port map (
        CLK      => CLK_12M,
        RST      => reset,
        -- SPI MASTER INTERFACE
        SCLK     => SCLK,
        CS_N(0)  => CS_N,
        MOSI     => MOSI,
        MISO     => MISO,
        -- USER INTERFACE
        DIN_ADDR => (others => '0'),
        DIN      => spi_din,
        DIN_LAST => spi_din_last,
        DIN_VLD  => spi_din_vld,
        DIN_RDY  => spi_din_rdy,
        DOUT     => spi_dout,
        DOUT_VLD => spi_dout_vld
    );

    -- -------------------------------------------------------------------------
    --  FSM
    -- -------------------------------------------------------------------------

    process (CLK_12M)
    begin
        if (rising_edge(CLK_12M)) then
            if (reset = '1') then
                fsm_pstate <= cfg1_addr;
            else
                fsm_pstate <= fsm_nstate;
            end if;
        end if;
    end process;

    process (fsm_pstate, spi_din_rdy, spi_dout_vld)
    begin
        fsm_nstate   <= fsm_pstate;
        spi_din      <= (others => '0');
        spi_din_last <= '0';
        spi_din_vld  <= '0';
        sensor_wr    <= '0';

        case fsm_pstate is
            when cfg1_addr =>
                spi_din     <= "00100000";
                spi_din_vld <= '1';
                if (spi_din_rdy = '1') then
                    fsm_nstate <= cfg1_wr;
                end if;

            when cfg1_wr =>
                spi_din      <= X"37";
                spi_din_vld  <= '1';
                spi_din_last <= '1';
                if (spi_din_rdy = '1') then
                    fsm_nstate <= out_addr;
                end if;

            when out_addr =>
                spi_din     <= "10101001";
                spi_din_vld <= '1';
                if (spi_din_rdy = '1') then
                    fsm_nstate <= out_rd;
                end if;

            when out_rd =>
                spi_din_vld <= '1';
                spi_din_last <= '1';
                if (spi_din_rdy = '1') then
                    fsm_nstate <= out_do;
                end if;

            when out_do =>
                if (spi_dout_vld = '1') then
                    sensor_wr <= '1';
                    fsm_nstate <= out_addr;
                end if;
        end case;
    end process;

    -- -------------------------------------------------------------------------
    --  SENSOR DATA REGISTER
    -- -------------------------------------------------------------------------

    process (CLK_12M)
    begin
        if (rising_edge(CLK_12M)) then
            if (sensor_wr = '1') then
                sensor_data <= spi_dout;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  USER LEDS LOGIC
    -- -------------------------------------------------------------------------

    sensor_sigd <= signed(sensor_data);

    process (CLK_12M)
    begin
        if (rising_edge(CLK_12M)) then
            USER_LEDS <= "00000000";
            if (sensor_sigd <= -16) then
                USER_LEDS <= "10000000";
            end if;
            if (sensor_sigd > -16) and (sensor_sigd <= -12) then
                USER_LEDS <= "01000000";
            end if;
            if (sensor_sigd > -12) and (sensor_sigd <= -8) then
                USER_LEDS <= "00100000";
            end if;
            if (sensor_sigd > -8) and (sensor_sigd <= -4) then
                USER_LEDS <= "00010000";
            end if;
            if (sensor_sigd > -4) and (sensor_sigd < 4) then
                USER_LEDS <= "00011000";
            end if;
            if (sensor_sigd >= 4) and (sensor_sigd < 8) then
                USER_LEDS <= "00001000";
            end if;
            if (sensor_sigd >= 8) and (sensor_sigd < 12) then
                USER_LEDS <= "00000100";
            end if;
            if (sensor_sigd >= 12) and (sensor_sigd < 16) then
                USER_LEDS <= "00000010";
            end if;
            if (sensor_sigd >= 16) then
                USER_LEDS <= "00000001";
            end if;
        end if;
    end process;

end architecture;
