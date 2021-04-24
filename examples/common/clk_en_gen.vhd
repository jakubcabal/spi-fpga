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
use IEEE.MATH_REAL.ALL;

entity CLK_EN_GEN is
    Generic (
        CLK_FREQ       : natural := 50e6 -- set system clock frequency in Hz
    );
    Port (
        CLK            : in  std_logic; -- system clock
        ASYNC_RST      : in  std_logic; -- asynchrounous reset
        CLK_EN_1K      : out std_logic  -- clock enable 1 KHz output
    );
end CLK_EN_GEN;

architecture RTL of CLK_EN_GEN is

    constant CLK_EN_1K_DIV : integer := CLK_FREQ/1e3;

    signal clk_en_1k_cnt   : integer range 0 to CLK_EN_1K_DIV-1;
    signal clk_en_1k_comb  : std_logic;
    signal clk_en_1k_reg   : std_logic;

begin

    -- -------------------------------------------------------------------------
    --  COUNTER OF CLOCK ENABLE (~1KHz)
    -- -------------------------------------------------------------------------

    clk_en_1k_cnt_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            clk_en_1k_cnt <= 0;
        elsif (rising_edge(CLK)) then
            if (clk_en_1k_cnt = CLK_EN_1K_DIV-1) then
                clk_en_1k_cnt <= 0;
            else
                clk_en_1k_cnt <= clk_en_1k_cnt + 1;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  GENERATOR OF CLOCK ENABLE (~1KHz)
    -- -------------------------------------------------------------------------

    clk_en_1k_comb <= '1' when (clk_en_1k_cnt = CLK_EN_1K_DIV-1) else '0';

    clk_en_1k_reg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            clk_en_1k_reg <= '0';
        elsif (rising_edge(CLK)) then
            clk_en_1k_reg <= clk_en_1k_comb;
        end if;
    end process;

    CLK_EN_1K <= clk_en_1k_reg;

end RTL;
