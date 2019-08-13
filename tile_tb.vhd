--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : tile_tb.vhd
-- Author      : Charles Detemmerman <cdetemme@ulb.ac.be>
-- Company     : IIHE
-- Created     : Fri May 17 04:39:16 2019
-- Last update : Fri May 17 04:39:33 2019
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

entity tile_tb is

end entity tile_tb;

-----------------------------------------------------------

architecture testbench of tile_tb is

	-- Testbench DUT generics as constants
	constant TILE_SIZE : integer := 16;

	-- Testbench DUT ports as signals
	signal clk             : std_logic;
	signal reset           : std_logic;
	signal current_value_o : std_logic_vector(TILE_SIZE-1 downto 0);
	signal input_value_i   : std_logic_vector(TILE_SIZE-1 downto 0);
	signal stopped_o       : std_logic;
	signal clear_stopped_i : std_logic;
	signal clear_value_i   : std_logic;
	signal set_value_i     : std_logic;
	signal merge_value_i   : std_logic;
	signal merge_ack_o     : std_logic;

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
		wait until reset = '0';
		input_value_i <= x"0002";
		set_value_i <= '1';
		wait for C_CLK_PERIOD * (1 SEC);
		set_value_i <= '0';
		merge_value_i <= '1';
		wait for C_CLK_PERIOD * (1 SEC);
		input_value_i <= x"0004";
		wait for C_CLK_PERIOD * (1 SEC);
		clear_stopped_i <= '1';
		wait for 2.0*C_CLK_PERIOD * (1 SEC);
		clear_value_i <= '1';
		wait;
	end process; -- STIM_GEN

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.tile
		generic map (
			TILE_SIZE => TILE_SIZE
		)
		port map (
			clk             => clk,
			reset           => reset,
			current_value_o => current_value_o,
			input_value_i   => input_value_i,
			stopped_o       => stopped_o,
			clear_stopped_i => clear_stopped_i,
			clear_value_i   => clear_value_i,
			set_value_i     => set_value_i,
			merge_value_i   => merge_value_i,
			merge_ack_o     => merge_ack_o
		);

end architecture testbench;