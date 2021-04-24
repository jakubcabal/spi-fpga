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

entity RST_SYNC is
    Port (
        CLK        : in  std_logic;
        ASYNC_RST  : in  std_logic;
        SYNCED_RST : out std_logic
    );
end entity;

architecture RTL of RST_SYNC is

    attribute ALTERA_ATTRIBUTE : string;
    attribute PRESERVE         : boolean;

    signal meta_reg  : std_logic;
    signal reset_reg : std_logic;

    attribute ALTERA_ATTRIBUTE of RTL : architecture is "-name SDC_STATEMENT ""set_false_path -to [get_registers {*RST_SYNC:*|meta_reg}] """;
    attribute ALTERA_ATTRIBUTE of meta_reg  : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
    attribute ALTERA_ATTRIBUTE of reset_reg : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
    attribute PRESERVE of meta_reg  : signal is TRUE;
    attribute PRESERVE of reset_reg : signal is TRUE;

begin

    process (CLK, ASYNC_RST)
    begin
        if (ASYNC_RST = '1') then
            meta_reg  <= '1';
            reset_reg <= '1';
        elsif (rising_edge(CLK)) then
            meta_reg  <= '0';
            reset_reg <= meta_reg;
        end if;
    end process;

    SYNCED_RST <= reset_reg;

end architecture;
