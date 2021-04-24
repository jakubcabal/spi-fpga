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

entity SPI_MASTER_TB is
    Generic (
        CLK_FREQ    : natural := 50e6; -- system clock frequency in Hz
        SPI_FREQ    : natural := 1e6;  -- spi clock frequency in Hz
        WORD_SIZE   : natural := 8;    -- size of transfer word in bits, must be power of two
        TRANS_COUNT : natural := 1e4   -- number of test transaction
    );
end entity;

architecture SIM of SPI_MASTER_TB is

    constant CLK_PERIOD : time := 1 ns * integer(real(1e9)/real(CLK_FREQ));
    constant SPI_PERIOD : time := 1 ns * integer(real(1e9)/real(SPI_FREQ));
    constant RX_OFFSET  : natural := 42;
    constant TX_OFFSET  : natural := 11;

    signal CLK            : std_logic;
    signal RST            : std_logic;

    signal sclk           : std_logic;
    signal cs_n           : std_logic;
    signal mosi           : std_logic;
    signal miso           : std_logic;

    signal udi            : std_logic_vector(WORD_SIZE-1 downto 0);
    signal udi_vld        : std_logic;
    signal udi_rdy        : std_logic;
    signal udo            : std_logic_vector(WORD_SIZE-1 downto 0);
    signal udo_exp        : std_logic_vector(WORD_SIZE-1 downto 0);
    signal udo_vld        : std_logic;

    signal spi_sdi        : std_logic_vector(WORD_SIZE-1 downto 0);
    signal spi_sdo        : std_logic_vector(WORD_SIZE-1 downto 0);
    signal spi_sdo_exp    : std_logic_vector(WORD_SIZE-1 downto 0);

    signal spi_model_done : std_logic := '0';
    signal udi_done       : std_logic := '0';
    signal udo_done       : std_logic := '0';
    signal sim_done       : std_logic := '0';
    signal rand_int       : integer := 0;
    signal count_rx       : integer;
    signal count_tx       : integer;

    procedure SPI_SLAVE (
        signal SSM_SDI  : in  std_logic_vector(WORD_SIZE-1 downto 0);
        signal SSM_SDO  : out std_logic_vector(WORD_SIZE-1 downto 0);
        signal SSM_SCLK : in  std_logic;
        signal SSM_CS_N : in  std_logic;
        signal SSM_MOSI : in  std_logic;
        signal SSM_MISO : out std_logic
    ) is
    begin
        wait until SSM_CS_N = '0';
        for i in 0 to (WORD_SIZE-1) loop
            SSM_MISO <= SSM_SDI(WORD_SIZE-1-i);
            wait until rising_edge(SSM_SCLK);
            SSM_SDO(WORD_SIZE-1-i) <= SSM_MOSI;
            wait until falling_edge(SSM_SCLK);
        end loop;
    end procedure;

begin

    rand_int_p : process
        variable seed1, seed2: positive;
        variable rand : real;
    begin
        uniform(seed1, seed2, rand);
        rand_int <= integer(rand*real(20));
        --report "Random number X: " & integer'image(rand_int);
        wait for CLK_PERIOD;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    dut : entity work.SPI_MASTER
    generic map (
        CLK_FREQ  => CLK_FREQ,
        SCLK_FREQ => SPI_FREQ,
        WORD_SIZE => WORD_SIZE
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        -- SPI SLAVE INTERFACE
        SCLK     => sclk,
        CS_N(0)  => cs_n,
        MOSI     => mosi,
        MISO     => miso,
        -- USER INTERFACE
        DIN      => udi,
        DIN_ADDR => (others => '0'),
        DIN_LAST => '1',
        DIN_VLD  => udi_vld,
        DIN_RDY  => udi_rdy,
        DOUT     => udo,
        DOUT_VLD => udo_vld
    );

    clk_gen_p : process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    rst_gen_p : process
    begin
        report "======== SIMULATION START! ========";
        report "Total transactions for master to slave direction: " & integer'image(TRANS_COUNT);
        report "Total transactions for slave to master direction: " & integer'image(TRANS_COUNT);
        RST <= '1';
        wait for CLK_PERIOD*3;
        RST <= '0';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  DUT TEST
    -- -------------------------------------------------------------------------

    spi_slave_model_p : process
    begin
        count_tx <= 1;
        wait until RST = '0';
        for i in 0 to TRANS_COUNT-1 loop
            spi_sdi     <= std_logic_vector(to_unsigned(((i+RX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            spi_sdo_exp <= std_logic_vector(to_unsigned(((i+TX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            SPI_SLAVE(spi_sdi, spi_sdo, sclk, cs_n, mosi, miso);
            if (spi_sdo = spi_sdo_exp) then
                if ((count_tx mod (TRANS_COUNT/10)) = 0) then
                    report "Transactions received from master: " & integer'image(count_tx);
                end if;
            else
                report "======== UNEXPECTED TRANSACTION ON MOSI SIGNAL (master to slave)! ========" severity failure;
            end if;
            count_tx <= count_tx + 1;
        end loop;
        spi_model_done <= '1';
        wait;
    end process;

    spi_master_udi_p : process
    begin
        wait until RST = '0';
        wait until rising_edge(CLK);
        wait for CLK_PERIOD/2;
        for i in 0 to TRANS_COUNT-1 loop
            udi <= std_logic_vector(to_unsigned(((i+TX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            udi_vld <= '1';
            if (udi_rdy = '0') then	
                wait until udi_rdy = '1';
                wait for CLK_PERIOD/2;
            end if;
            wait for CLK_PERIOD;
            udi_vld <= '0';
            wait for rand_int*CLK_PERIOD;
        end loop;
        udi_done <= '1';
        wait;
    end process;

    spi_master_udo_p : process
    begin
        count_rx <= 1;
        for i in 0 to TRANS_COUNT-1 loop
            udo_exp <= std_logic_vector(to_unsigned(((i+RX_OFFSET) mod 2**WORD_SIZE),WORD_SIZE));
            wait until udo_vld = '1';
            if (udo = udo_exp) then
                if ((count_rx mod (TRANS_COUNT/10)) = 0) then
                    report "Transactions received from slave: " & integer'image(count_rx);
                end if;
            else
                report "======== UNEXPECTED TRANSACTION ON DOUT SIGNAL (slave to master)! ========" severity failure;
            end if;
            count_rx <= count_rx + 1;
            wait for CLK_PERIOD;
        end loop;
        udo_done <= '1';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  TEST DONE CHECK
    -- -------------------------------------------------------------------------

    test_done_p : process
        variable v_test_done : std_logic;
    begin
        v_test_done := spi_model_done and udi_done and udo_done;
        if (v_test_done = '1') then
            wait for 100*CLK_PERIOD;
            sim_done <= '1';
            report "======== SIMULATION SUCCESSFULLY COMPLETED! ========";
            wait;
        end if;
        wait for CLK_PERIOD;
    end process;

end architecture;
