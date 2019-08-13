--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : rng_tb.vhd
-- Author      : Charles Detemmerman <cdetemme@ulb.ac.be>
-- Company     : IIHE
-- Created     : Fri May 17 00:53:08 2019
-- Last update : Fri May 17 00:53:22 2019
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

entity rng_tb is

end entity rng_tb;

-----------------------------------------------------------

architecture testbench of rng_tb is

	-- Testbench DUT generics as constants
	constant NUM_SIZE : integer                      := 4;
	constant SEED     : std_logic_vector(7 downto 0) := x"CD";

	-- Testbench DUT ports as signals
	signal clk      : std_logic;
	signal reset    : std_logic;
	signal en       : std_logic;
	signal rand_num : std_logic_vector(NUM_SIZE-1 downto 0);

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
	DUT : entity work.rng
		generic map (
			NUM_SIZE => NUM_SIZE,
			SEED     => SEED
		)
		port map (
			clk      => clk,
			reset    => reset,
			en       => en,
			rand_num => rand_num
		);

end architecture testbench;