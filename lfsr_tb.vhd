--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : lfsr_tb.vhd
-- Author      : Charles Detemmerman <cdetemme@ulb.ac.be>
-- Company     : IIHE
-- Created     : Fri May 17 00:45:24 2019
-- Last update : Fri May 17 00:55:07 2019
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008>
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity lfsr_tb is

end entity lfsr_tb;

-----------------------------------------------------------

architecture testbench of lfsr_tb is

	-- Testbench DUT generics as constants
	constant REG_SIZE : integer                               := 8;
	constant SEED     : std_logic_vector(REG_SIZE-1 downto 0) := x"AB";

	-- Testbench DUT ports as signals
	signal clk   : std_logic;
	signal reset : std_logic;
	signal en    : std_logic;
	signal rand_bit : std_logic;

	-- Other constants
	constant C_CLK_PERIOD : real := 10.0e-9; -- NS

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk <= '1';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
		clk <= '0';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
	end process CLK_GEN;

	RESET_GEN : process
	begin
		reset <= '1',
		         '0' after 20.0*C_CLK_PERIOD * (1 SEC);
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	STIM_GEN : process is
	begin
		en <= '0';
		wait until reset = '0';
		en <= '1';
		wait;
	end process; -- STIM_GEN

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.lfsr
		generic map (
			SEED     => SEED
		)
		port map (
			clk   => clk,
			reset => reset,
			en    => en,
			rand_bit => rand_bit
		);

end architecture testbench;