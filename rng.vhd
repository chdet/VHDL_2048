library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rng is
	generic (
		NUM_SIZE : integer := 1;
		SEED : std_logic_vector(7 downto 0) := x"CD"
	);
	port (
		clk 		: in std_logic;
		reset 		: in std_logic;
		en 			: in std_logic;
		rand_num  	: out std_logic_vector(NUM_SIZE-1 downto 0)
	);
end entity rng;

architecture std of rng is

begin
	
	LFSR_GEN : for i in 1 to NUM_SIZE generate

		lfsr_1 : entity work.lfsr
		generic map (
			SEED => SEED xor std_logic_vector(to_unsigned(i, 8))
		)
		port map (
			clk   => clk,
			reset => reset,
			en    => en,
			rand_bit => rand_num(i-1)
		);		

	end generate ; -- LFSR_GEN

end architecture std;