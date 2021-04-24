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

entity SPI_LOOPBACK is
    Port (
        CLK             : in  std_logic;
        BTN_RST         : in  std_logic;
        -- SPI MASTER INTERFACE
        M_SCLK          : out std_logic;
        M_CS_N          : out std_logic;
        M_MOSI          : out std_logic;
        M_MISO          : in  std_logic;
        -- SPI SLAVE INTERFACE
        S_SCLK          : in  std_logic;
        S_CS_N          : in  std_logic;
        S_MOSI          : in  std_logic;
        S_MISO          : out std_logic;
        -- USER INTERFACE
        BTN_MENU_MODE   : in  std_logic;
        BTN_MENU_ACTION : in  std_logic;
        SSEG            : out std_logic_vector(7 downto 0);
        SSEG_AN         : out std_logic_vector(3 downto 0)
    );
end entity;

architecture RTL of SPI_LOOPBACK is

    signal reset           : std_logic;
    signal clk_en_1k       : std_logic;

    signal menu_mode_en    : std_logic;
    signal menu_action_en  : std_logic;

    signal menu_cnt        : unsigned(1 downto 0);
    signal menu_mode_led   : std_logic_vector(3 downto 0);
    signal m_cnt           : unsigned(3 downto 0);
    signal s_cnt           : unsigned(3 downto 0);
    signal m_cnt_en        : std_logic;
    signal s_cnt_en        : std_logic;

    signal m_din           : std_logic_vector(7 downto 0);
    signal s_din           : std_logic_vector(7 downto 0);
    signal m_din_vld       : std_logic;
    signal s_din_vld       : std_logic;
    signal m_dout          : std_logic_vector(7 downto 0);
    signal s_dout          : std_logic_vector(7 downto 0);
    signal m_dout_vld      : std_logic;
    signal s_dout_vld      : std_logic;
    signal m_dout_reg      : std_logic_vector(3 downto 0);
    signal s_dout_reg      : std_logic_vector(3 downto 0);

begin

    -- -------------------------------------------------------------------------
    --  RESET SYNCHRONIZER
    -- -------------------------------------------------------------------------

    reset_sync_i : entity work.RST_SYNC
    port map (
        CLK        => CLK,
        ASYNC_RST  => BTN_RST,
        SYNCED_RST => reset
    );

    -- -------------------------------------------------------------------------
    --  CLOCK ENABLE GENERATOR
    -- -------------------------------------------------------------------------

    clk_en_gen_i : entity work.CLK_EN_GEN
    generic map (
        CLK_FREQ => 50e6
    )
    port map (
        CLK       => CLK,
        ASYNC_RST => reset,
        CLK_EN_1K => clk_en_1k
    );

    -- -------------------------------------------------------------------------
    --  BUTTONS DEBOUNCE
    -- -------------------------------------------------------------------------

    btn1_debounce_i : entity work.BTN_DEBOUNCE
    port map (
        CLK        => CLK,
        ASYNC_RST  => reset,
        SAMPLE_EN  => clk_en_1k,
        BTN_RAW    => BTN_MENU_MODE,
        BTN_DEB    => open,
        BTN_DEB_RE => menu_mode_en
    );

    btn2_debounce_i : entity work.BTN_DEBOUNCE
    port map (
        CLK        => CLK,
        ASYNC_RST  => reset,
        SAMPLE_EN  => clk_en_1k,
        BTN_RAW    => BTN_MENU_ACTION,
        BTN_DEB    => open,
        BTN_DEB_RE => menu_action_en
    );

    -- -------------------------------------------------------------------------
    --  MENU MODE COUNTER
    -- -------------------------------------------------------------------------

    menu_cnt_p : process (CLK, reset)
    begin
        if (reset = '1') then
            menu_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (menu_mode_en = '1') then
                if (menu_cnt = "11") then
                    menu_cnt <= (others => '0');
                else
                    menu_cnt <= menu_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process(menu_cnt,menu_action_en)
    begin
        case menu_cnt is
            when "00" =>
                m_cnt_en <= '0';
                s_cnt_en <= menu_action_en;
                m_din_vld <= '0';
                s_din_vld <= '0';
                menu_mode_led <= "0001";
            when "01" =>
                m_cnt_en <= '0';
                s_cnt_en <= '0';
                m_din_vld <= '0';
                s_din_vld <= menu_action_en;
                menu_mode_led <= "0010";
            when "10" =>
                m_cnt_en <= menu_action_en;
                s_cnt_en <= '0';
                m_din_vld <= '0';
                s_din_vld <= '0';
                menu_mode_led <= "0100";
            when "11" =>
                m_cnt_en <= '0';
                s_cnt_en <= '0';
                m_din_vld <= menu_action_en;
                s_din_vld <= '0';
                menu_mode_led <= "1000";
            when others =>
                m_cnt_en <= '0';
                s_cnt_en <= '0';
                m_din_vld <= '0';
                s_din_vld <= '0';
                menu_mode_led <= "0000";
        end case;
    end process;

    -- -------------------------------------------------------------------------
    --  MASTER COUNTER
    -- -------------------------------------------------------------------------

    m_cnt_p : process (CLK, reset)
    begin
        if (reset = '1') then
            m_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (m_cnt_en = '1') then
                if (m_cnt = "1111") then
                    m_cnt <= (others => '0');
                else
                    m_cnt <= m_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    m_din <= std_logic_vector(m_cnt) & std_logic_vector(m_cnt);

    -- -------------------------------------------------------------------------
    --  SLAVE COUNTER
    -- -------------------------------------------------------------------------

    s_cnt_p : process (CLK, reset)
    begin
        if (reset = '1') then
            s_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (s_cnt_en = '1') then
                if (s_cnt = "1111") then
                    s_cnt <= (others => '0');
                else
                    s_cnt <= s_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    s_din <= std_logic_vector(s_cnt) & std_logic_vector(s_cnt);

    -- -------------------------------------------------------------------------
    --  SPI MASTER AND SLAVE
    -- -------------------------------------------------------------------------

    master_i : entity work.SPI_MASTER
    generic map(
        CLK_FREQ    => 50e6,
        SCLK_FREQ   => 1e6,
        SLAVE_COUNT => 1
    )
    port map (
        CLK      => CLK,
        RST      => reset,
        -- SPI MASTER INTERFACE
        SCLK     => M_SCLK,
        CS_N(0)  => M_CS_N,
        MOSI     => M_MOSI,
        MISO     => M_MISO,
        -- USER INTERFACE
        DIN_ADDR => (others => '0'),
        DIN      => m_din,
        DIN_LAST => '1',
        DIN_VLD  => m_din_vld,
        DIN_RDY  => open,
        DOUT     => m_dout,
        DOUT_VLD => m_dout_vld
    );

    m_dout_reg_p : process (CLK, reset)
    begin
        if (reset = '1') then
            m_dout_reg <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (m_dout_vld = '1') then
                m_dout_reg <= m_dout(3 downto 0);
            end if;
        end if;
    end process;

    slave_i : entity work.SPI_SLAVE
    port map (
        CLK      => CLK,
        RST      => reset,
        -- SPI MASTER INTERFACE
        SCLK     => S_SCLK,
        CS_N     => S_CS_N,
        MOSI     => S_MOSI,
        MISO     => S_MISO,
        -- USER INTERFACE
        DIN      => s_din,
        DIN_VLD  => s_din_vld,
        DIN_RDY  => open,
        DOUT     => s_dout,
        DOUT_VLD => s_dout_vld
    );

    s_dout_reg_p : process (CLK, reset)
    begin
        if (reset = '1') then
            s_dout_reg <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (s_dout_vld = '1') then
                s_dout_reg <= s_dout(3 downto 0);
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  SSEG DRIVER
    -- -------------------------------------------------------------------------

    sseg_driver_i : entity work.SSEG_DRIVER
    port map (
        CLK       => CLK,
        CLK_EN_1K => clk_en_1k,
        ASYNC_RST => reset,
        DATA0     => s_din(3 downto 0),
        DATA1     => s_dout_reg,
        DATA2     => m_din(3 downto 0),
        DATA3     => m_dout_reg,
        DOTS      => menu_mode_led,
        SSEG      => SSEG,
        SSEG_AN   => SSEG_AN
    );

end architecture;
