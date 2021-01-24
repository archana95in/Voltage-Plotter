
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

use IEEE.MATH_REAL.ALL;


entity main is
  Generic (
      PARITY_BIT  : string := "none"; -- type of parity: "none", "even", "odd"
      CLK_FREQ      : integer := 100000000;   -- system clock frequency in Hz
      BAUD_RATE     : integer := 9600);-- baud rate value
      
Port ( clk : in STD_LOGIC;
           rst,WriteEn,ReadEn,wr_uart : in std_logic;
           full,empty,tx,busy: out std_logic;
           JA : in STD_LOGIC_VECTOR (7 downto 0));
end main;

-----------------------
--ADC
----------------------------------

architecture structural of main is
COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;
    dwe_in : IN STD_LOGIC;
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    vauxp5 : IN STD_LOGIC;
    vauxn5 : IN STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC
  );
END COMPONENT;
-----
---FIFO
-----

COMPONENT fifo_generator_0
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

    signal channel_out : std_logic_vector(4 downto 0);
    signal daddr_in  : std_logic_vector(6 downto 0);
    signal eoc_out : std_logic;
    signal do_out,fifo_out  : std_logic_vector(15 downto 0); 
    signal vp_in, vn_in, drdy: std_logic;
    signal led :  STD_LOGIC_VECTOR (15 downto 0);
    
    ---
    constant DIVIDER_VALUE    : integer := CLK_FREQ/(16*BAUD_RATE);
constant CLK_CNT_WIDTH    : integer := integer(ceil(log2(real(DIVIDER_VALUE))));
constant CLK_CNT_MAX      : unsigned := to_unsigned(DIVIDER_VALUE-1, CLK_CNT_WIDTH);
signal uart_clk_cnt       : unsigned(CLK_CNT_WIDTH-1 downto 0);
signal uart_clk_en        : std_logic;
begin

------
---uart clk and FPGA clk map--
------------------

uart_clk_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_clk_cnt <= (others => '0');
            else
                if (uart_clk_cnt = CLK_CNT_MAX) then
                    uart_clk_cnt <= (others => '0');
                else
                    uart_clk_cnt <= uart_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    uart_clk_en_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_clk_en <= '0';
            elsif (uart_clk_cnt = CLK_CNT_MAX) then
                uart_clk_en <= '1';
            else
                uart_clk_en <= '0';
            end if;
        end if;
    end process;


    daddr_in <= "00" & channel_out;
    vp_in <= JA(4);
    vn_in <= JA(0);
    led <= do_out;
    
ADC: xadc_wiz_0
  PORT MAP (
    di_in => "0000000000000000",
    daddr_in => daddr_in,
    den_in => eoc_out,
    dwe_in => '0',
    drdy_out => drdy,
    do_out => do_out,
    dclk_in => clk,
    reset_in => rst,
    vp_in => '0',
    vn_in => '0',
    vauxp5 => vp_in,
    vauxn5 => vn_in,
    channel_out => channel_out,
    eoc_out => eoc_out,
    alarm_out => open,
    eos_out => open,
    busy_out => open
  );
  
FIFO: fifo_generator_0
  PORT MAP (
    clk => clk,
    srst => rst,
    din => do_out(15 DOWNTO 0),
    wr_en => WriteEn,
    rd_en => ReadEn,
    dout => fifo_out(15 DOWNTO 0),
    full => full,
    empty => empty
  );
  
  
  
  --
  			     
		UART_TRANSMISSION : entity work.UART_TX	     
	    Port map (
                     CLK         => clk, -- system clock
                     RST         => rst,
                     -- UART INTERFACE
                     UART_CLK_EN => uart_clk_en, -- oversampling (16x) 
                     UART_TXD    => tx, -- serial transmit data
                     -- USER DATA INPUT INTERFACE
                     DATA_IN    => fifo_out(15 DOWNTO 8) , -- input data
                     DATA_SEND   => wr_uart,-- when DATA_SEND = 1, input data will be transmit
                     BUSY        => busy-- data transmitting via UART
      );

end structural;
