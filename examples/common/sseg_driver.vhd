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

entity SSEG_DRIVER is
    Port (
        CLK         : in  std_logic; -- system clock
        CLK_EN_1K   : in  std_logic; -- clock enable 1 KHz
        ASYNC_RST   : in  std_logic; -- asynchrounous reset
        -- USER INTERFACE
        DATA0       : in  std_logic_vector(3 downto 0); -- BCD or HEX(4b)
        DATA1       : in  std_logic_vector(3 downto 0); -- BCD or HEX(4b)
        DATA2       : in  std_logic_vector(3 downto 0); -- BCD or HEX(4b)
        DATA3       : in  std_logic_vector(3 downto 0); -- BCD or HEX(4b)
        DOTS        : in  std_logic_vector(3 downto 0); -- DP on/off
        -- SSEG INTERFACE
        SSEG        : out std_logic_vector(7 downto 0); -- "dot" & "gfedcba"
        SSEG_AN     : out std_logic_vector(3 downto 0)  -- sseg anodes
    );
end SSEG_DRIVER;

architecture RTL of SSEG_DRIVER is

    signal sseg_anode_cnt  : unsigned(1 downto 0);
    signal sseg_anode      : std_logic_vector(3 downto 0);
    signal sseg_anode_reg  : std_logic_vector(3 downto 0);
    signal sseg_bin        : std_logic_vector(3 downto 0);
    signal sseg_code       : std_logic_vector(6 downto 0);
    signal sseg_dp         : std_logic;
    signal sseg_REG        : std_logic_vector(7 downto 0);

begin

    -- -------------------------------------------------------------------------
    --  SSEG ANODE MUXING
    -- -------------------------------------------------------------------------

    sseg_an_cnt_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            sseg_anode_cnt <= (others => '0');
        elsif (rising_edge(CLK)) then
            if (CLK_EN_1K = '1') then
                sseg_anode_cnt <= sseg_anode_cnt + 1;
            end if;
        end if;
    end process;

    process(sseg_anode_cnt, DATA0, DATA1, DATA2, DATA3, DOTS)
    begin
        case sseg_anode_cnt is
            when "00" =>
                sseg_bin   <= DATA0;
                sseg_dp    <= not DOTS(0);
                sseg_anode <= "1110";
            when "01" =>
                sseg_bin   <= DATA1;
                sseg_dp    <= not DOTS(1);
                sseg_anode <= "1101";
            when "10" =>
                sseg_bin   <= DATA2;
                sseg_dp    <= not DOTS(2);
                sseg_anode <= "1011";
            when "11" =>
                sseg_bin   <= DATA3;
                sseg_dp    <= not DOTS(3);
                sseg_anode <= "0111";
            when others =>
                sseg_bin   <= DATA0;
                sseg_dp    <= not DOTS(0);
                sseg_anode <= "1110";
        end case;
    end process;

    -- -------------------------------------------------------------------------
    --  SSEG ANODE REGISTER
    -- -------------------------------------------------------------------------

    sseg_anode_reg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            sseg_anode_reg <= (others => '1');
        elsif (rising_edge(CLK)) then
            sseg_anode_reg <= sseg_anode;
        end if;
    end process;

    SSEG_AN <= sseg_anode_reg;

    -- -------------------------------------------------------------------------
    --  SSEG DECODER
    -- -------------------------------------------------------------------------

    with sseg_bin select
        sseg_code <= "1000000" when "0000", -- 0
                     "1111001" when "0001", -- 1
                     "0100100" when "0010", -- 2
                     "0110000" when "0011", -- 3
                     "0011001" when "0100", -- 4
                     "0010010" when "0101", -- 5
                     "0000010" when "0110", -- 6
                     "1111000" when "0111", -- 7
                     "0000000" when "1000", -- 8
                     "0010000" when "1001", -- 9
                     "0001000" when "1010", -- A
                     "0000011" when "1011", -- B
                     "1000110" when "1100", -- C
                     "0100001" when "1101", -- D
                     "0000110" when "1110", -- E
                     "0001110" when "1111", -- F
                     "1111111" when others; -- nic
                  -- "gfedcba"

    -- -------------------------------------------------------------------------
    --  SSEG REGISTER
    -- -------------------------------------------------------------------------

    sseg_reg_p : process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            sseg_reg <= (others => '1');
        elsif (rising_edge(CLK)) then
            sseg_reg <= sseg_dp & sseg_code;
        end if;
    end process;

    SSEG <= sseg_reg;

end RTL;
