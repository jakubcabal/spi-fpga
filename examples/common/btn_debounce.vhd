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

entity BTN_DEBOUNCE is
    Generic (
        CNT_WIDTH : natural := 2 -- width of debounce counter
    );
    Port (
        CLK        : in  std_logic; -- system clock
        ASYNC_RST  : in  std_logic; -- asynchrounous reset
        SAMPLE_EN  : in  std_logic; -- sample clock enable
        BTN_RAW    : in  std_logic; -- button raw signal
        BTN_DEB    : out std_logic; -- button debounce signal
        BTN_DEB_RE : out std_logic  -- rising edge of debounced signal
    );
end entity;

architecture RTL of BTN_DEBOUNCE is

    signal btn_raw_sync_reg1  : std_logic;
    signal btn_raw_sync_reg2  : std_logic;
    signal btn_raw_sample_reg : std_logic;
    signal btn_raw_diff       : std_logic;
    signal deb_cnt            : unsigned(CNT_WIDTH-1 downto 0);
    signal deb_cnt_max        : std_logic;
    signal btn_deb_reg        : std_logic;
    signal btn_deb_re_reg     : std_logic;

begin

    -- -------------------------------------------------------------------------
    --  BUTTON RAW SIGNAL SYNCHRONIZATION REGISTERS
    -- -------------------------------------------------------------------------

    btn_raw_sync_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            btn_raw_sync_reg1 <= BTN_RAW;
            btn_raw_sync_reg2 <= btn_raw_sync_reg1;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  BUTTON RAW SIGNAL SAMPLE REGISTERS
    -- -------------------------------------------------------------------------

    btn_raw_sample_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (SAMPLE_EN = '1') then
                btn_raw_sample_reg <= btn_raw_sync_reg2;  
            end if;
        end if;
    end process;

    btn_raw_diff <= btn_raw_sample_reg xor btn_raw_sync_reg2;

    -- -------------------------------------------------------------------------
    --  DEBOUNCE COUNTER
    -- -------------------------------------------------------------------------

    deb_cnt_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            deb_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (SAMPLE_EN = '1') then
                if (btn_raw_diff = '1') then
                    deb_cnt <= (others => '0');
                else
                    deb_cnt <= deb_cnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    deb_cnt_max <= '1' when (deb_cnt = (2**CNT_WIDTH)-1) else '0';

    -- -------------------------------------------------------------------------
    --  BUTTON DEBOUNCE SIGNAL REGISTER
    -- -------------------------------------------------------------------------

    btn_deb_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (deb_cnt_max = '1') then
                btn_deb_reg <= btn_raw_sample_reg;
            end if;
        end if;
    end process;

    BTN_DEB <= btn_deb_reg;

    -- -------------------------------------------------------------------------
    --  RISING EDGE DETECTOR OF BUTTON DEBOUNCE SIGNAL
    -- -------------------------------------------------------------------------

    btn_deb_re_reg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            btn_deb_re_reg <= '0';
        elsif (rising_edge(CLK)) then
            btn_deb_re_reg <= deb_cnt_max and btn_raw_sample_reg and not btn_deb_reg;
        end if;
    end process;

    BTN_DEB_RE <= btn_deb_re_reg;

end architecture;
