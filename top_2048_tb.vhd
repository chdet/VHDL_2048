--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : top_2048_tb.vhd
-- Author      : Charles Detemmerman <cdetemme@ulb.ac.be>
-- Company     : IIHE
-- Created     : Fri May 17 02:14:46 2019
-- Last update : Fri May 17 04:10:09 2019
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

use work.types_p.all;

-----------------------------------------------------------

entity top_2048_tb is

end entity top_2048_tb;

-----------------------------------------------------------

architecture testbench of top_2048_tb is

	type integer_array is array(1 to GAME_SIZE) of integer;

	-- Testbench DUT generics as constants
	file moves_file : text open read_mode is "F:\Documents\Vivado\ELEC-H505\src\hdl\new_2048\moves.dat";
	file preset_file : text open read_mode is "F:\Documents\Vivado\ELEC-H505\src\hdl\new_2048\preset.dat";

	-- Testbench DUT ports as signals
	signal clk                 : std_logic;
	signal reset               : std_logic := '1';
	signal move_command_i      : std_logic_vector(3 downto 0);
	signal preset_command_i    : std_logic;
	signal tile_preset_array_i : board_values_array;

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
		variable fline : line;
		variable f_data : std_logic_vector(3 downto 0);
		variable preset_data : integer_array;
		variable idx : integer := 1;
	begin

		if reset = '1' then
			--== SETUP ==--
			-- Read from the preset.dat file to create an initial array

			wait until reset = '0';
			preset_command_i <= '1';
			while (not endfile(preset_file)) loop
				readline(preset_file, fline);
				for ii in 1 to GAME_SIZE loop
					read(fline, preset_data(ii));
					tile_preset_array_i(idx,ii) <= std_logic_vector(to_unsigned(preset_data(ii), TILE_SIZE));
				end loop ;
				idx := idx + 1;
			end loop ; -- PRESET_ARRAY_READ
			wait for 3.0*C_CLK_PERIOD * (1 SEC);
			preset_command_i <= '0';

		else
			--== LOOP ==--
			-- Read from the moves.dat to apply inputs to the system
			move_command_i <= "0000";
			wait for 14.0*C_CLK_PERIOD * (1 SEC);
			if (not endfile(moves_file)) then
				readline(moves_file, fline);
				read(fline, f_data);
			else
				f_data := "0000";
			end if;
			move_command_i <= f_data; 
			wait for 1.0*C_CLK_PERIOD * (1 SEC);

		end if;
	end process; -- STIM_GEN

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.top_2048
		port map (
			clk                 => clk,
			reset               => reset,
			move_command_i      => move_command_i,
			preset_command_i    => preset_command_i,
			tile_preset_array_i => tile_preset_array_i
		);

end architecture testbench;