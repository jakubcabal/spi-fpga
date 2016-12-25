--------------------------------------------------------------------------------
-- PROJECT: FPGA MISC
--------------------------------------------------------------------------------
-- NAME:    BTN_DEBOUNCE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License
-- WEBSITE: https://github.com/jakubcabal/fpga-misc
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BTN_DEBOUNCE is
    Port (
        CLK            : in  std_logic; -- system clock
        CLK_EN_1K      : in  std_logic; -- clock enable 1 KHz
        ASYNC_RST      : in  std_logic; -- asynchrounous reset
        BTN_RAW        : in  std_logic; -- button raw signal
        BTN_DEB        : out std_logic; -- button debounce signal
        BTN_DEB_EN     : out std_logic  -- button debounce rising edge enable
    );
end BTN_DEBOUNCE;

architecture RTL of BTN_DEBOUNCE is

    signal btn_raw_shreg    : std_logic_vector(3 downto 0);
    signal btn_deb_comb     : std_logic;
    signal btn_deb_reg      : std_logic;
    signal btn_deb_en_reg   : std_logic;

begin

    -- -------------------------------------------------------------------------
    --  SHIFT REGISTER OF BUTTON RAW SIGNAL
    -- -------------------------------------------------------------------------

    btn_shreg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            btn_raw_shreg <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (CLK_EN_1K = '1') then
                btn_raw_shreg <= btn_raw_shreg(2 downto 0) & BTN_RAW;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  DEBOUNCE REGISTER OF BUTTON RAW SIGNAL
    -- -------------------------------------------------------------------------

    btn_deb_comb <= btn_raw_shreg(0) and btn_raw_shreg(1) and
                    btn_raw_shreg(2) and btn_raw_shreg(3);

    btn_deb_reg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            btn_deb_reg <= '0';
        elsif (rising_edge(CLK)) then
            btn_deb_reg <= btn_deb_comb;
        end if;
    end process;

    BTN_DEB <= btn_deb_reg;

    -- -------------------------------------------------------------------------
    --  RISING EDGE DETECTOR OF BUTTON DEBOUNCE SIGNAL
    -- -------------------------------------------------------------------------

    sseg_an_cnt_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            btn_deb_en_reg <= '0';
        elsif (rising_edge(CLK)) then
            btn_deb_en_reg <= btn_deb_comb and not btn_deb_reg;
        end if;
    end process;

    BTN_DEB_EN <= btn_deb_en_reg;

end RTL;
