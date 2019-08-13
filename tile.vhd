library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types_p.all;

entity tile is
	generic (
		TILE_SIZE : integer := 16
	);
	port (
	clk : in std_logic;
	reset : in std_logic;

	current_value_o : out std_logic_vector(TILE_SIZE-1 downto 0);
	input_value_i :	in std_logic_vector(TILE_SIZE-1 downto 0);

	stopped_o : out std_logic;
	clear_stopped_i : in std_logic;
	clear_value_i : in std_logic;
	set_value_i : in std_logic;
	merge_value_i : in std_logic;
	merge_ack_o	  : out std_logic
	) ;
end entity ; -- tile

architecture arch of tile is
	signal current_value_int : std_logic_vector(TILE_SIZE-1 downto 0);
	signal stopped_int : std_logic;
begin

	SEQ : process (clk, reset)
	begin
		if (reset = '1') then
			current_value_int <= (others => '0');
			stopped_int <= '0';
			merge_ack_o <= '0';
		elsif rising_edge(clk) then
			merge_ack_o <= '0';
			-- CLEARING (PRIORITY 1)
			if clear_value_i = '1' then
				----------------------------------------------
				-- Allow merging and clearing at the same time
						--if merge_value_i = '1' and stopped_int = '0' then
						--	current_value_int <= input_value_i;
						--	merge_ack_o <= '1';
						--else
						--	current_value_int <= (others => '0');
						--end if;
				----------------------------------------------
				current_value_int <= (others => '0');
			-- VALUE PRESET (PRIORITY 2)
			elsif set_value_i = '1' then
				current_value_int <= input_value_i;
			-- MERGING (PRIORITY 3)
			elsif merge_value_i = '1' and stopped_int = '0' then
				if current_value_int /= zero_value and input_value_i = current_value_int then
					current_value_int <= current_value_int(TILE_SIZE-2 downto 0) & '0';
					merge_ack_o <= '1';
					stopped_int <= '1';
				elsif current_value_int = zero_value then
					current_value_int <= input_value_i;
					merge_ack_o <= '1';
				elsif input_value_i /= zero_value then
					-- A non-mergeable object is in the way, so we don't merge anything else
					stopped_int <= '1';
				end if;
			end if;

			if clear_stopped_i = '1' then
				stopped_int <= '0';	-- One cycle latency between the clear stop flag being set and the tile being able to merge again
			end if;
		end if;
	end process SEQ;

	current_value_o <= current_value_int;
	stopped_o <= stopped_int;

end architecture ; -- arch