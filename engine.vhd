library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

use work.types_p.all;

entity engine is
	port (
		clk : in std_logic;
		reset: in std_logic;

		tile_interfaces_mosi : out tile_interface_mosi_array;
		tile_interfaces_miso : in tile_interface_miso_array;

		move_command_i : in std_logic_vector(3 downto 0);
		preset_command_i : in std_logic;
		tile_preset_array_i : in board_values_array
	);
end entity engine;

architecture std of engine is
	
	--== GAME STATES ==--

	signal current_game_state : game_state 	:= IDLE;
	signal next_game_state : game_state 	:= IDLE;

	signal ref_idx_current : integer range 1 to 4 	:= 1;
	signal ref_idx_next : integer range 1 to 4 		:= 1;
	signal comp_idx_current : integer range 1 to 4 	:= 2;
	signal comp_idx_next : integer range 1 to 4 	:= 2;

	--== RANDOM NUMBER GENERATOR ==--

	constant RNG_NBIT 	: integer := integer(ceil(log2(real(GAME_SIZE)))); -- Number of bits required to describe one dimension of the game board
	constant RNG_NUM_SIZE : integer := 2*RNG_NBIT+1;

	signal rng_en 		: std_logic;
	signal rng_val_switch		: std_logic;	-- '0' for 2, '1' for 4
	signal rng_val : std_logic_vector(TILE_SIZE-1 downto 0);
	signal rng_x 		: unsigned(RNG_NBIT-1 downto 0);
	signal rng_y 		: unsigned(RNG_NBIT-1 downto 0);
	signal rng_num		: std_logic_vector(RNG_NUM_SIZE-1 downto 0);

begin
	
	--=============================--
	--== RANDOM NUMBER GENERATOR ==--
	--=============================--

	rng_1 : entity work.rng
		generic map (
			NUM_SIZE => RNG_NUM_SIZE,
			SEED     => x"CB"
		)
		port map (
			clk      => clk,
			reset    => reset,
			en       => rng_en,
			rand_num => rng_num
		);	

	rng_x <= unsigned(rng_num(RNG_NBIT-1 downto 0));
	rng_y <= unsigned(rng_num((2*RNG_NBIT)-1 downto RNG_NBIT));
	rng_val_switch <= rng_num(2*RNG_NBIT);
	rng_en <= '1';

	RNG_VAL_SWITCHING : process(rng_val_switch) is
	begin
		if (rng_val_switch = '0') then
			rng_val <= (1 => '1', others => '0');
		else
			rng_val <= (2=> '1', others => '0');
		end if;
	end process; -- RNG_VAL_SWITCHING

	--=============================--
	--== 	GAME ENGINE 		 ==--
	--=============================--

	FSM_COMB : process(current_game_state, tile_interfaces_miso, preset_command_i, move_command_i, tile_preset_array_i) is
		variable cnt : integer range 0 to 1 := 0;

	begin
		case (current_game_state) is
			when IDLE =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '1';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				if preset_command_i = '1' then
					next_game_state <= PRESET;
				elsif move_command_i = "1000" then
					next_game_state <= NEXT_LEFT;
					ref_idx_next  <= 1;
					comp_idx_next <= 2;
				elsif move_command_i = "0100" then
					next_game_state <= NEXT_RIGHT;
					ref_idx_next  <= 4;
					comp_idx_next <= 3;
				elsif move_command_i = "0010" then
					next_game_state <= NEXT_UP;
					ref_idx_next  <= 1;
					comp_idx_next <= 2;
				elsif move_command_i = "0001" then
					next_game_state <= NEXT_DOWN;
					ref_idx_next  <= 4;
					comp_idx_next <= 3;
				else
					next_game_state <= IDLE;
				end if;
				
			when PRESET =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i		<= tile_preset_array_i(j,i);
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '1';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;
				next_game_state <= IDLE;

			when NEXT_LEFT =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for j in 1 to GAME_SIZE loop
					tile_interfaces_mosi(j,ref_idx_current).input_value_i		<= tile_interfaces_miso(j,comp_idx_current).current_value_o;
					tile_interfaces_mosi(j,ref_idx_current).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(j,ref_idx_current).clear_value_i  		<= '0';
					tile_interfaces_mosi(j,ref_idx_current).set_value_i    		<= '0';
					tile_interfaces_mosi(j,ref_idx_current).merge_value_i  		<= '1';
				end loop;

				next_game_state <= CLEAR_LEFT;

			when CLEAR_LEFT =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for j in 1 to GAME_SIZE loop
					tile_interfaces_mosi(j,comp_idx_current).input_value_i		<= (others => '0');
					tile_interfaces_mosi(j,comp_idx_current).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(j,comp_idx_current).clear_value_i  	<= tile_interfaces_miso(j,ref_idx_current).merge_ack_o;
					tile_interfaces_mosi(j,comp_idx_current).set_value_i    	<= '0';
					tile_interfaces_mosi(j,comp_idx_current).merge_value_i  	<= '0';
				end loop;

				next_game_state <= NEXT_LEFT;
				if(comp_idx_current < GAME_SIZE) then	-- comp_idx < 4
					comp_idx_next <= comp_idx_current + 1;
				else
					if(ref_idx_current < GAME_SIZE-1) then	-- ref_idx < 3
						ref_idx_next <= ref_idx_current + 1;
						comp_idx_next <= ref_idx_current + 2;
						--assert (comp_idx - ref_idx = 1);
					else
						ref_idx_next <= 1;
						comp_idx_next <= 2;
						next_game_state <= GEN_NEW_VAL;
					end if;
				end if;

			when NEXT_RIGHT =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for j in 1 to GAME_SIZE loop
					tile_interfaces_mosi(j,ref_idx_current).input_value_i		<= tile_interfaces_miso(j,comp_idx_current).current_value_o;
					tile_interfaces_mosi(j,ref_idx_current).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(j,ref_idx_current).clear_value_i  		<= '0';
					tile_interfaces_mosi(j,ref_idx_current).set_value_i    		<= '0';
					tile_interfaces_mosi(j,ref_idx_current).merge_value_i  		<= '1';
				end loop;

				next_game_state <= CLEAR_RIGHT;

			when CLEAR_RIGHT =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for j in 1 to GAME_SIZE loop
					tile_interfaces_mosi(j,comp_idx_current).input_value_i		<= (others => '0');
					tile_interfaces_mosi(j,comp_idx_current).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(j,comp_idx_current).clear_value_i  	<= tile_interfaces_miso(j,ref_idx_current).merge_ack_o;
					tile_interfaces_mosi(j,comp_idx_current).set_value_i    	<= '0';
					tile_interfaces_mosi(j,comp_idx_current).merge_value_i  	<= '0';
				end loop;
				
				next_game_state <= NEXT_RIGHT;
				if(comp_idx_current > 1) then
					comp_idx_next <= comp_idx_current - 1;
				else
					if(ref_idx_current > 2) then
						ref_idx_next <= ref_idx_current - 1;
						comp_idx_next <= ref_idx_current - 2;
						--assert (comp_idx - ref_idx = 1);
					else
						ref_idx_next <= 4;
						comp_idx_next <= 3;
						next_game_state <= GEN_NEW_VAL;
					end if;
				end if;

			when NEXT_UP =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for i in 1 to GAME_SIZE loop
					tile_interfaces_mosi(ref_idx_current,i).input_value_i		<= tile_interfaces_miso(comp_idx_current,i).current_value_o;
					tile_interfaces_mosi(ref_idx_current,i).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(ref_idx_current,i).clear_value_i  		<= '0';
					tile_interfaces_mosi(ref_idx_current,i).set_value_i    		<= '0';
					tile_interfaces_mosi(ref_idx_current,i).merge_value_i  		<= '1';
				end loop;

				next_game_state <= CLEAR_UP;

			when CLEAR_UP =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for i in 1 to GAME_SIZE loop
					tile_interfaces_mosi(comp_idx_current,i).input_value_i		<= (others => '0');
					tile_interfaces_mosi(comp_idx_current,i).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(comp_idx_current,i).clear_value_i  	<= tile_interfaces_miso(ref_idx_current,i).merge_ack_o;
					tile_interfaces_mosi(comp_idx_current,i).set_value_i    	<= '0';
					tile_interfaces_mosi(comp_idx_current,i).merge_value_i  	<= '0';
				end loop;

				next_game_state <= NEXT_UP;
				if(comp_idx_current < GAME_SIZE) then	-- comp_idx < 4
					comp_idx_next <= comp_idx_current + 1;
				else
					if(ref_idx_current < GAME_SIZE-1) then	-- ref_idx < 3
						ref_idx_next <= ref_idx_current + 1;
						comp_idx_next <= ref_idx_current + 2;
						--assert (comp_idx - ref_idx = 1);
					else
						ref_idx_next <= 1;
						comp_idx_next <= 2;
						next_game_state <= GEN_NEW_VAL;
					end if;
				end if;


			when NEXT_DOWN =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for i in 1 to GAME_SIZE loop
					tile_interfaces_mosi(ref_idx_current,i).input_value_i		<= tile_interfaces_miso(comp_idx_current,i).current_value_o;
					tile_interfaces_mosi(ref_idx_current,i).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(ref_idx_current,i).clear_value_i  		<= '0';
					tile_interfaces_mosi(ref_idx_current,i).set_value_i    		<= '0';
					tile_interfaces_mosi(ref_idx_current,i).merge_value_i  		<= '1';
				end loop;

				next_game_state <= CLEAR_DOWN;

			when CLEAR_DOWN =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				for i in 1 to GAME_SIZE loop
					tile_interfaces_mosi(comp_idx_current,i).input_value_i		<= (others => '0');
					tile_interfaces_mosi(comp_idx_current,i).clear_stopped_i 	<= '0';
					tile_interfaces_mosi(comp_idx_current,i).clear_value_i  	<= tile_interfaces_miso(ref_idx_current,i).merge_ack_o;
					tile_interfaces_mosi(comp_idx_current,i).set_value_i    	<= '0';
					tile_interfaces_mosi(comp_idx_current,i).merge_value_i  	<= '0';
				end loop;
				
				next_game_state <= NEXT_DOWN;
				if(comp_idx_current > 1) then
					comp_idx_next <= comp_idx_current - 1;
				else
					if(ref_idx_current > 2) then
						ref_idx_next <= ref_idx_current - 1;
						comp_idx_next <= ref_idx_current - 2;
						--assert (comp_idx - ref_idx = 1);
					else
						ref_idx_next <= 4;
						comp_idx_next <= 3;
						next_game_state <= GEN_NEW_VAL;
					end if;
				end if;

			when GEN_NEW_VAL =>
				for i in 1 to GAME_SIZE loop
					for j in 1 to GAME_SIZE loop
						tile_interfaces_mosi(j,i).input_value_i	<= (others => '0');
						tile_interfaces_mosi(j,i).clear_stopped_i 	<= '0';
						tile_interfaces_mosi(j,i).clear_value_i  	<= '0';
						tile_interfaces_mosi(j,i).set_value_i    	<= '0';
						tile_interfaces_mosi(j,i).merge_value_i  	<= '0';
					end loop;
				end loop;

				if (tile_interfaces_miso(to_integer(rng_y)+1, to_integer(rng_x)+1).current_value_o = zero_value) then
					tile_interfaces_mosi(to_integer(rng_y)+1, to_integer(rng_x)+1).input_value_i		<= rng_val;
					tile_interfaces_mosi(to_integer(rng_y)+1, to_integer(rng_x)+1).set_value_i    	<= '1';
					next_game_state <= IDLE;
				else
					next_game_state <= GEN_NEW_VAL;
				end if;

			--when GAME_OVER =>
			--	null;

			when others =>
				null;
		end case;
	end process; -- FSM_COMB

	FSM_SEQ : process (clk, reset)
	begin
		if (reset = '1') then
			current_game_state <= IDLE;
			ref_idx_current <= 1;
			comp_idx_current <= 2;
		elsif rising_edge(clk) then
			current_game_state <= next_game_state;
			ref_idx_current <= ref_idx_next;
			comp_idx_current <= comp_idx_next;
		end if;
	end process FSM_SEQ;

end architecture std;