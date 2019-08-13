--------------------------------------------------------------------------------
-- Title       : Linear Feedback Shift Register
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : lfsr.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon May  6 16:30:13 2019
-- Last update : Fri May 17 00:55:28 2019
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
	generic (
		SEED : std_logic_vector(7 downto 0) := x"AB"
	);
	port (
		clk 	  : in std_logic;
		reset 	  : in std_logic;
		en 		  : in std_logic;
		rand_bit  : out std_logic
	);
end entity lfsr;

architecture arch of lfsr is
	signal count_i        : std_logic_vector (7 downto 0) := SEED; 
	signal feedback     : std_logic;

begin

	feedback <= not(count_i(2) xor count_i(4) xor count_i(1) xor count_i(6) xor count_i(7) );

	process (reset, clk) 
	begin
		if (reset = '1') then
		 	count_i <= SEED;
		elsif (rising_edge(clk)) then
			if en = '1' then
				count_i <= count_i(6 downto 0) & feedback;
			end if;
		end if;
	end process;

	rand_bit <= count_i(0);

end architecture;
