library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity UART_TX is
Generic (
PARITY_BIT : string := "none"
);
Port (
CLK : in std_logic; 
RST : in std_logic; 
-- UART INTERFACE
UART_CLK_EN : in std_logic; 
UART_TXD : out std_logic; 
DATA_IN : in std_logic_vector(7 downto 0); 
DATA_SEND : in std_logic; 
BUSY : out std_logic 

);
end UART_TX;
architecture FULL of UART_TX is
signal tx_clk_en : std_logic;
signal tx_clk_divider_en : std_logic;
signal tx_ticks : unsigned(3 downto 0);
signal tx_data : std_logic_vector(7 downto 0);
signal tx_bit_count : unsigned(2 downto 0);
signal tx_bit_count_en : std_logic;
signal tx_busy : std_logic;
signal tx_parity_bit : std_logic;
signal tx_data_out_sel : std_logic_vector(1 downto 0);
type state is (idle, txsync, startbit, databits, paritybit, stopbit);
signal tx_pstate : state;
signal tx_nstate : state;
begin
BUSY <= tx_busy;
-- -------------------------------------------------------------------------
--Clock divider
-- -------------------------------------------------------------------------
uart_tx_clk_divider_p : process (CLK)
begin
if (rising_edge(CLK)) then
if (tx_clk_divider_en = '1') then
if (uart_clk_en = '1') then
if (tx_ticks = "1111") then
tx_ticks <= (others => '0');
else
tx_ticks <= tx_ticks + 1;
end if;
else
tx_ticks <= tx_ticks;
end if;
else
tx_ticks <= (others => '0');
end if;
end if;
end process;
uart_tx_clk_en_p : process (CLK)
begin
if (rising_edge(CLK)) then
if (RST = '1') then
tx_clk_en <= '0';
elsif (uart_clk_en = '1' AND tx_ticks = "0001") then
tx_clk_en <= '1';
else
tx_clk_en <= '0';
end if;
end if;
end process;
-- -------------------------------------------------------------------------
---store data in input reg
-- -------------------------------------------------------------------------
uart_tx_input_data_reg_p : process (CLK)
begin
if (rising_edge(CLK)) then
if (RST = '1') then
tx_data <= (others => '0');
elsif (DATA_SEND = '1' AND tx_busy = '0') then
tx_data <= DATA_IN;
end if;
end if;
end process;
-- -------------------------------------------------------------------------
--UART counting bits
-- -------------------------------------------------------------------------
uart_tx_bit_counter_p : process (CLK)
begin
if (rising_edge(CLK)) then
if (RST = '1') then
tx_bit_count <= (others => '0');
elsif (tx_bit_count_en = '1' AND tx_clk_en = '1') then
if (tx_bit_count = "111") then
tx_bit_count <= (others => '0');
else
tx_bit_count <= tx_bit_count + 1;
end if;
end if;
end if;
end process;
-- -------------------------------------------------------------------------
---Data split
-- -------------------------------------------------------------------------
uart_tx_output_data_reg_p : process (CLK)
begin
if (rising_edge(CLK)) then
if (RST = '1') then
UART_TXD <= '1';
else
case tx_data_out_sel is
when "01" => -- START BIT
UART_TXD <= '0';
when "10" => -- DATA BITS
UART_TXD <= tx_data(to_integer(tx_bit_count));
when "11" => -- PARITY BIT
UART_TXD <= tx_parity_bit;
when others => -- STOP BIT OR IDLE
UART_TXD <= '1';
end case;
end if;
end if;
end process;
-- -------------------------------------------------------------------------
-- UART TRANSMITTER FSM
-- -------------------------------------------------------------------------
-- PRESENT STATE REGISTER
process (CLK)
begin
if (rising_edge(CLK)) then
if (RST = '1') then
tx_pstate <= idle;
else
tx_pstate <= tx_nstate;
end if;
end if;
end process;
-- NEXT STATE --------------
process (tx_pstate, DATA_SEND, tx_clk_en, tx_bit_count)
begin
case tx_pstate is
when idle =>
tx_busy <= '0';
tx_data_out_sel <= "00";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '0';
if (DATA_SEND = '1') then
tx_nstate <= txsync;
else
tx_nstate <= idle;
end if;
when txsync =>
tx_busy <= '1';
tx_data_out_sel <= "00";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '1';
if (tx_clk_en = '1') then
tx_nstate <= startbit;
else
tx_nstate <= txsync;
end if;
when startbit =>
tx_busy <= '1';
tx_data_out_sel <= "01";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '1';
if (tx_clk_en = '1') then
tx_nstate <= databits;
else
tx_nstate <= startbit;
end if;
when databits =>
tx_busy <= '1';
tx_data_out_sel <= "10";
tx_bit_count_en <= '1';
tx_clk_divider_en <= '1';
if ((tx_clk_en = '1') AND (tx_bit_count = "111")) then
if (PARITY_BIT = "none") then
tx_nstate <= stopbit;
else
tx_nstate <= paritybit;
end if ;
else
tx_nstate <= databits;
end if;
when paritybit =>
tx_busy <= '1';
tx_data_out_sel <= "11";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '1';
if (tx_clk_en = '1') then
tx_nstate <= stopbit;
else
tx_nstate <= paritybit;
end if;
when stopbit =>
tx_busy <= '0';
tx_data_out_sel <= "00";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '1';
if (DATA_SEND = '1') then
tx_nstate <= txsync;
elsif (tx_clk_en = '1') then
tx_nstate <= idle;
else
tx_nstate <= stopbit;
end if;
when others =>
tx_busy <= '1';
tx_data_out_sel <= "00";
tx_bit_count_en <= '0';
tx_clk_divider_en <= '0';
tx_nstate <= idle;
end case;
end process;
end FULL;