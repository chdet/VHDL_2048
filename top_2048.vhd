library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types_p.all;


entity top_2048 is
	port (
		clk : in std_logic;
		reset : in std_logic;

		move_command_i : in std_logic_vector(3 downto 0);
		preset_command_i : in std_logic;
		tile_preset_array_i : in board_values_array
	);
end entity top_2048;

architecture std of top_2048 is

	signal tile_interfaces_miso : tile_interface_miso_array;	
	signal tile_interfaces_mosi : tile_interface_mosi_array;	

	signal board_values : board_values_array;

begin
	
	engine_1 : entity work.engine
		port map (
			clk             => clk,
			reset           => reset,
			tile_interfaces_mosi => tile_interfaces_mosi,
			tile_interfaces_miso => tile_interfaces_miso,
			move_command_i    => move_command_i,
			preset_command_i  => preset_command_i,
			tile_preset_array_i => tile_preset_array_i
		);	


	VIEWER : process(tile_interfaces_miso) is
	begin
		for i in 1 to GAME_SIZE loop
			for j in 1 to GAME_SIZE loop
				board_values(j,i) <= tile_interfaces_miso(j,i).current_value_o;
			end loop;
		end loop;
	end process; -- VIEWER


	TileArrayX : for i in 1 to GAME_SIZE generate
		TileArrayY : for j in 1 to GAME_SIZE generate

			tile_1 : entity work.tile
			generic map (
				TILE_SIZE => TILE_SIZE
			)
			port map (
				clk             => clk,
				reset           => reset,
				current_value_o => tile_interfaces_miso(j,i).current_value_o,	-- y axis being the first component gives the expected grid in simulator
				input_value_i   => tile_interfaces_mosi(j,i).input_value_i,
				stopped_o       => tile_interfaces_miso(j,i).stopped_o,
				clear_stopped_i => tile_interfaces_mosi(j,i).clear_stopped_i,
				clear_value_i   => tile_interfaces_mosi(j,i).clear_value_i,
				set_value_i     => tile_interfaces_mosi(j,i).set_value_i,
				merge_value_i   => tile_interfaces_mosi(j,i).merge_value_i,
				merge_ack_o 	=> tile_interfaces_miso(j,i).merge_ack_o
			);		

		end generate ; -- TileArrayY
	end generate ; -- TileArray

end architecture std;