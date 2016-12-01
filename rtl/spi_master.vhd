--------------------------------------------------------------------------------
-- PROJECT: SPI MASTER AND SLAVE FOR FPGA
--------------------------------------------------------------------------------
-- NAME:    SPI_MASTER
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: LGPL-3.0, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/spi-fpga
--------------------------------------------------------------------------------
-- COPYRIGHT NOTICE:
--------------------------------------------------------------------------------
-- SPI MASTER AND SLAVE FOR FPGA
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

-- THE SPI MASTER MODULE SUPPORT ONLY SPI MODE 0 (CPOL=0, CPHA=0)!!!

entity SPI_MASTER is
    Generic (
        CLK_FREQ    : natural := 50; -- set system clock frequency in MHz
        SCLK_FREQ   : natural := 5;  -- set SPI clock frequency in MHz (must be < CLK_FREQ/9)
        SLAVE_COUNT : natural := 1   -- count of SPI slaves
    );
    Port (
        CLK      : in  std_logic; -- system clock
        RST      : in  std_logic; -- high active synchronous reset
        -- SPI MASTER INTERFACE
        SCLK     : out std_logic;
        CS_N     : out std_logic_vector(SLAVE_COUNT-1 downto 0);
        MOSI     : out std_logic;
        MISO     : in  std_logic;
        -- USER INTERFACE
        ADDR     : in  std_logic_vector(integer(ceil(log2(real(SLAVE_COUNT))))-1 downto 0); -- slave address
        READY    : out std_logic; -- when READY = 1, SPI master is ready to accept input data
        DIN      : in  std_logic_vector(7 downto 0); -- input data for slave
        DIN_VLD  : in  std_logic; -- when DIN_VLD = 1, input data are valid and can be accept
        DOUT     : out std_logic_vector(7 downto 0); -- output data from slave
        DOUT_VLD : out std_logic  -- when DOUT_VLD = 1, output data are valid
    );
end SPI_MASTER;

architecture RTL of SPI_MASTER is

    constant DIVIDER_VALUE_REAL : real    := (real(CLK_FREQ)/real(SCLK_FREQ))/2.0;
    constant DIVIDER_VALUE      : integer := integer(ceil(DIVIDER_VALUE_REAL));
    constant WIDTH_CLK_CNT      : integer := integer(ceil(log2(real(DIVIDER_VALUE))));
    constant WIDTH_ADDR         : integer := integer(ceil(log2(real(SLAVE_COUNT))));

    signal addr_reg             : std_logic_vector(WIDTH_ADDR-1 downto 0);
    signal sys_clk_cnt          : unsigned(WIDTH_CLK_CNT-1 downto 0);
    signal sys_clk_cnt_max      : std_logic;
    signal spi_clk              : std_logic;
    signal spi_clk_reg          : std_logic;
    signal spi_clk_redge_en     : std_logic;
    signal spi_clk_fedge_en     : std_logic;
    signal chip_select_n        : std_logic;
    signal load_data            : std_logic;
    signal spi_shreg            : std_logic_vector(7 downto 0);
    signal bit_cnt              : unsigned(2 downto 0);
    signal last_bit_en          : std_logic;
    signal master_transmit      : std_logic;
    signal master_transmit_end  : std_logic;
    signal master_ready         : std_logic;

    type state is (idle, sync, active_cs, transmit, transmit_end, deactive_cs);
    signal present_state, next_state : state;

begin

    ASSERT (DIVIDER_VALUE_REAL > 4.5) REPORT "SCLK_FREQ must be < CLK_FREQ/9" SEVERITY ERROR;

    load_data <= master_ready and DIN_VLD;
    SCLK      <= spi_clk_reg and master_transmit;
    READY     <= master_ready;
    DOUT      <= spi_shreg;

    -- -------------------------------------------------------------------------
    --  SYSTEM CLOCK COUNTER
    -- -------------------------------------------------------------------------

    sys_clk_cnt_max <= '1' when (to_integer(sys_clk_cnt) = DIVIDER_VALUE-1) else '0';

    sys_clk_cnt_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                sys_clk_cnt <= (others => '0');
            else
                if (sys_clk_cnt_max = '1') then
                    sys_clk_cnt <= (others => '0');
                else
                    sys_clk_cnt <= sys_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  SPI CLOCK GENERATOR AND REGISTER
    -- -------------------------------------------------------------------------

    spi_clk_gen_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_clk <= '0';
            elsif (sys_clk_cnt_max = '1') then
                spi_clk <= not spi_clk;
            end if;
        end if;
    end process;

    spi_clk_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                spi_clk_reg <= '0';
            else
                spi_clk_reg <= spi_clk;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  SPI CLOCK EDGES FLAGS
    -- -------------------------------------------------------------------------

    spi_clk_fedge_en <= not spi_clk and spi_clk_reg;
    spi_clk_redge_en <= spi_clk and not spi_clk_reg;

    -- -------------------------------------------------------------------------
    --  SPI MASTER ADDRESSING
    -- -------------------------------------------------------------------------

    addr_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                addr_reg <= (others => '0');
            elsif (load_data = '1') then
                addr_reg <= ADDR;
            end if;
        end if;
    end process;

    cs_n_g : for i in 0 to SLAVE_COUNT-1 generate
        cs_n_p : process (addr_reg, chip_select_n)
        begin
            if (to_integer(unsigned(addr_reg)) = i) then
                CS_N(i) <= chip_select_n;
            else
                CS_N(i) <= '1';
            end if;
        end process;
    end generate;

    -- -------------------------------------------------------------------------
    --  MOSI REGISTER
    -- -------------------------------------------------------------------------

    mosi_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (load_data = '1') then
                MOSI <= DIN(7);
            elsif (spi_clk_fedge_en = '1' and chip_select_n = '0') then
                MOSI <= spi_shreg(7);
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  DATA SHIFT REGISTER
    -- -------------------------------------------------------------------------

    spi_shreg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (load_data = '1') then
                spi_shreg <= DIN;
            elsif (spi_clk_redge_en = '1' and chip_select_n = '0') then
                spi_shreg <= spi_shreg(6 downto 0) & MISO;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  DATA OUT VALID FLAG REGISTER
    -- -------------------------------------------------------------------------

    dout_vld_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                DOUT_VLD <= '0';
            else
                DOUT_VLD <= master_transmit_end;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  BIT COUNTER
    -- -------------------------------------------------------------------------

    bit_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                bit_cnt <= (others => '0');
            elsif (spi_clk_fedge_en = '1' and chip_select_n = '0') then
                if (bit_cnt = "111") then
                    bit_cnt <= (others => '0');
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  LAST BIT FLAG REGISTER
    -- -------------------------------------------------------------------------

    last_bit_en_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                last_bit_en <= '0';
            else
                if (bit_cnt = "111") then
                    last_bit_en <= '1';
                else
                    last_bit_en <= '0';
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  SPI MASTER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    fsm_present_state_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                present_state <= idle;
            else
                present_state <= next_state;
            end if;
        end if;
    end process;

    -- NEXT STATE LOGIC
    fsm_next_state_p : process (present_state, DIN_VLD, spi_clk_redge_en,
                                spi_clk_fedge_en, last_bit_en)
    begin

        case present_state is

            when idle =>
                if (DIN_VLD = '1') then
                    next_state <= sync;
                else
                    next_state <= idle;
                end if;

            when sync =>
                if (spi_clk_fedge_en = '1') then
                    next_state <= active_cs;
                else
                    next_state <= sync;
                end if;

            when active_cs =>
                if (spi_clk_redge_en = '1') then
                    next_state <= transmit;
                else
                    next_state <= active_cs;
                end if;

            when transmit =>
                if (spi_clk_fedge_en = '1' and last_bit_en = '1') then
                    next_state <= transmit_end;
                else
                    next_state <= transmit;
                end if;

            when transmit_end =>
                next_state <= deactive_cs;

            when deactive_cs =>
                if (spi_clk_redge_en = '1') then
                    next_state <= idle;
                else
                    next_state <= deactive_cs;
                end if;

            when others =>
                next_state <= idle;

        end case;
    end process;

    -- OUTPUTS LOGIC
    fsm_outputs_p : process (present_state)
    begin

        case present_state is

            when idle =>
                master_ready        <= '1';
                chip_select_n       <= '1';
                master_transmit     <= '0';
                master_transmit_end <= '0';

            when sync =>
                master_ready        <= '0';
                chip_select_n       <= '1';
                master_transmit     <= '0';
                master_transmit_end <= '0';

            when active_cs =>
                master_ready        <= '0';
                chip_select_n       <= '0';
                master_transmit     <= '0';
                master_transmit_end <= '0';

            when transmit =>
                master_ready        <= '0';
                chip_select_n       <= '0';
                master_transmit     <= '1';
                master_transmit_end <= '0';

            when transmit_end =>
                master_ready        <= '0';
                chip_select_n       <= '0';
                master_transmit     <= '0';
                master_transmit_end <= '1';

            when deactive_cs =>
                master_ready        <= '0';
                chip_select_n       <= '0';
                master_transmit     <= '0';
                master_transmit_end <= '0';

            when others =>
                master_ready        <= '0';
                chip_select_n       <= '1';
                master_transmit     <= '0';
                master_transmit_end <= '0';

        end case;
    end process;

end RTL;
