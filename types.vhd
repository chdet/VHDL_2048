library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types_p is

	constant GAME_SIZE : integer := 4;
	constant TILE_SIZE : integer := 16;
	constant zero_value : std_logic_vector(TILE_SIZE-1 downto 0) := (others => '0');

	type tile_interface_mosi is record
		input_value_i   : std_logic_vector(TILE_SIZE-1 downto 0);
		clear_stopped_i : std_logic;
		clear_value_i   : std_logic;
		set_value_i     : std_logic;
		merge_value_i   : std_logic;		
	end record;

	type tile_interface_miso is record
		current_value_o : std_logic_vector(TILE_SIZE-1 downto 0);
		stopped_o       : std_logic;
		merge_ack_o 	: std_logic;
	end record;

	type tile_interface_mosi_array is array(1 to GAME_SIZE, 1 to GAME_SIZE) of tile_interface_mosi;
	type tile_interface_miso_array is array(1 to GAME_SIZE, 1 to GAME_SIZE) of tile_interface_miso;

	type game_state is (IDLE, NEXT_LEFT, CLEAR_LEFT,NEXT_RIGHT, CLEAR_RIGHT,NEXT_UP, CLEAR_UP,NEXT_DOWN, CLEAR_DOWN, GEN_NEW_VAL, PRESET);

	type board_values_array is array(1 to GAME_SIZE, 1 to GAME_SIZE) of std_logic_vector(TILE_SIZE-1 downto 0);

end package ; -- types_p 