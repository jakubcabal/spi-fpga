--------------------------------------------------------------------------------
-- PROJECT: SPI MASTER CONTROLLER FOR FPGA
--------------------------------------------------------------------------------
-- MODULE NAME: SPI_MASTER
-- AUTHORS:     Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE:     LGPL-3.0, please read LICENSE file
-- WEBSITE:     https://github.com/jakubcabal/spi_master_fpga
-- USED TOOLS:  Quartus II 13.0 SP1
-- CREATE DATE: 02.06.‎2016
--------------------------------------------------------------------------------
-- COPYRIGHT NOTICE:
--------------------------------------------------------------------------------
-- SPI MASTER CONTROLLER FOR FPGA
-- Copyright (C) 2016 Jakub Cabal
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- MY SPI MASTER MODULE SUPPORT ONLY SPI MODE 0 (CPOL=0, CPHA=0)!!!

entity SPI_MASTER is
    Generic (
        CLK_FREQ   : integer := 50; -- set system clock frequency in MHz
        SCLK_FREQ  : integer := 5;  -- set SPI clock frequency in MHz (must be < CLK_FREQ/9)
        DATA_WIDTH : integer := 8   -- set SPI datawidth in bits
    );
    Port (
        CLK      : in  std_logic; -- system clock
        RST      : in  std_logic; -- high active synchronous reset
        -- SPI MASTER INTERFACE
        SCLK     : out std_logic;
        CS_N     : out std_logic;
        MOSI     : out std_logic;
        MISO     : in  std_logic;
        -- USER INTERFACE
        DIN      : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- input data
        DIN_VLD  : in  std_logic; -- when DIN_VLD = 1, input data are valid and can be accept
        READY    : out std_logic; -- when READY = 1, SPI master is ready to accept input data
        DOUT     : out std_logic_vector(DATA_WIDTH-1 downto 0); -- output data
        DOUT_VLD : out std_logic  -- when DOUT_VLD = 1, output data are valid
    );
end SPI_MASTER;

architecture FULL of SPI_MASTER is

    constant DIVIDER_VALUE_REAL : real    := (real(CLK_FREQ)/real(SCLK_FREQ))/2.0;
    constant DIVIDER_VALUE      : integer := integer(ceil(DIVIDER_VALUE_REAL));
    constant WIDTH_CLK_CNT      : integer := integer(ceil(log2(real(DIVIDER_VALUE))));
    constant WIDTH_BIT_CNT      : integer := integer(ceil(log2(real(DATA_WIDTH))));

    signal sys_clk_cnt              : unsigned(WIDTH_CLK_CNT-1 downto 0);
    signal spi_clk                  : std_logic;
    signal spi_clk_reg0             : std_logic;
    signal spi_clk_reg1             : std_logic;
    signal spi_clk_rising_edge_en1  : std_logic;
    signal spi_clk_falling_edge_en0 : std_logic;
    signal spi_clk_falling_edge_en1 : std_logic;
    signal spi_clk_en_set           : std_logic;
    signal spi_chip_select_n        : std_logic;
    signal spi_mosi_reg             : std_logic;
    signal spi_mosi_reg_en          : std_logic;
    signal spi_mosi_reg_load        : std_logic;
    signal spi_shreg                : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal spi_shreg_en             : std_logic;
    signal spi_shreg_load           : std_logic;
    signal spi_bit_cnt              : unsigned(WIDTH_BIT_CNT-1 downto 0);
    signal spi_bit_cnt_en           : std_logic;
    signal spi_last_bit             : std_logic;
    signal spi_dout_vld             : std_logic;
    signal spi_ready                : std_logic;

    type state is (idle, transmit, check_data);
    signal present_state, next_state : state;

begin

    ASSERT (DIVIDER_VALUE_REAL > 4.5) REPORT "SCLK_FREQ must be < CLK_FREQ/9" SEVERITY ERROR;

    spi_shreg_load    <= spi_ready AND DIN_VLD;
    spi_shreg_en      <= spi_clk_rising_edge_en1;
    spi_mosi_reg_load <= spi_shreg_load;
    spi_mosi_reg_en   <= spi_clk_falling_edge_en1;
    spi_bit_cnt_en    <= spi_clk_falling_edge_en1 AND NOT spi_chip_select_n;
    spi_clk_en_set    <= spi_clk_falling_edge_en0;
    spi_dout_vld      <= spi_clk_rising_edge_en1 AND spi_last_bit;

    SCLK  <= spi_clk_reg1;
    CS_N  <= spi_chip_select_n;
    MOSI  <= spi_mosi_reg;
    READY <= spi_ready;
    DOUT  <= spi_shreg;

    -- -------------------------------------------------------------------------
    -- SPI MASTER CLOCK
    -- -------------------------------------------------------------------------

    sys_clk_cnt_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1' OR spi_chip_select_n = '1') then
                sys_clk_cnt <= (others => '0');
            else
                if (to_integer(sys_clk_cnt) = DIVIDER_VALUE-1) then
                    sys_clk_cnt <= (others => '0');
                else
                    sys_clk_cnt <= sys_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    spi_clk_gen_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_clk <= '0';
            elsif (to_integer(sys_clk_cnt) = DIVIDER_VALUE-1) then
                spi_clk <= NOT spi_clk;
            end if;
        end if;
    end process;

    spi_clk_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_clk_reg0 <= '0';
                spi_clk_reg1 <= '0';
            else
                spi_clk_reg0 <= spi_clk;
                spi_clk_reg1 <= spi_clk_reg0;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER CLOCK EDGES FLAGS
    -- -------------------------------------------------------------------------

    spi_clk_falling_edge_en0 <= '1' WHEN ((spi_clk = '0') AND (spi_clk_reg0 = '1')) ELSE '0';
    spi_clk_falling_edge_en1 <= '1' WHEN ((spi_clk_reg0 = '0') AND (spi_clk_reg1 = '1')) ELSE '0';
    spi_clk_rising_edge_en1  <= '1' WHEN ((spi_clk_reg0 = '1') AND (spi_clk_reg1 = '0')) ELSE '0';

    -- -------------------------------------------------------------------------
    -- SPI MASTER MOSI REGISTER
    -- -------------------------------------------------------------------------

    spi_mosi_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (spi_mosi_reg_load = '1') then
                spi_mosi_reg <= DIN(DATA_WIDTH-1);
            elsif (spi_mosi_reg_en = '1') then
                spi_mosi_reg <= spi_shreg(DATA_WIDTH-1);
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER SHIFT REGISTER
    -- -------------------------------------------------------------------------

    spi_shreg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (spi_shreg_load = '1') then
                spi_shreg <= DIN;
            elsif (spi_shreg_en = '1') then
                spi_shreg <= spi_shreg(DATA_WIDTH-2 downto 0) & MISO;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER DATA OUT VALID FLAG REGISTER
    -- -------------------------------------------------------------------------

    spi_dout_vld_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                DOUT_VLD <= '0';
            else
                DOUT_VLD <= spi_dout_vld;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER BIT COUNTER REGISTERS
    -- -------------------------------------------------------------------------

    spi_bit_cnt_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_bit_cnt <= (others => '0');
            elsif (spi_bit_cnt_en = '1') then
                if (spi_bit_cnt = to_unsigned(DATA_WIDTH-1, spi_bit_cnt'length)) then
                    spi_bit_cnt <= (others => '0');
                else
                    spi_bit_cnt <= spi_bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER LAST BIT FLAG REGISTER
    -- -------------------------------------------------------------------------

    spi_last_bit_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_last_bit <= '0';
            else
                if (spi_bit_cnt = to_unsigned(DATA_WIDTH-1, spi_bit_cnt'length)) then
                    spi_last_bit <= '1';
                else
                    spi_last_bit <= '0';
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- SPI MASTER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                present_state <= idle;
            else
                present_state <= next_state;
            end if;
        end if;
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (present_state, DIN_VLD, spi_clk_en_set, spi_last_bit)
    begin

        case present_state is

            when idle =>
                spi_chip_select_n <= '1';
                spi_ready <= '1';

                if (DIN_VLD = '1') then
                    next_state <= transmit;
                else
                    next_state <= idle;
                end if;

            when transmit =>
                spi_chip_select_n <= '0';
                spi_ready <= '0';

                if (spi_clk_en_set = '1' AND spi_last_bit = '1') then
                    next_state <= check_data;
                else
                    next_state <= transmit;
                end if;

            when check_data =>
                spi_chip_select_n <= '0';
                spi_ready <= '1';

                if (DIN_VLD = '1') then
                    next_state <= transmit;
                else
                    next_state <= idle;
                end if;

            when others =>
                spi_chip_select_n <= '1';
                spi_ready <= '0';
                next_state <= idle;

        end case;
    end process;

end FULL;
