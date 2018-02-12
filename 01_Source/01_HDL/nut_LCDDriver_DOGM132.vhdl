-- Handles the display
-- DOGM132 132x32 graphic display
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nut_LCDDriver is
    port(
        clk_in      : in std_logic;     -- 1 MHz CPU clock
        cpu_clk_in  : in std_logic;
        reset_in    : in std_logic;   -- active high async reset
        addr_in     : in std_logic_vector(3 downto 0); -- only 4 bits are significant 
        data_in     : in std_logic_vector(47 downto 0); -- only 48 bits are significant (12 nibbles)
        data_o      : out std_logic_vector(55 downto 0); -- only 48 bits are significant (12 nibbles)
        perif_in    : in std_logic_vector(7 downto 0);
        rd_in       : in std_logic;
        we_in       : in std_logic;
        ann_we_in   : in std_logic;
        -- LCD Interface
        disp_cs_n_o : out std_logic;
        disp_res_n_o: out std_logic;
        disp_data_o : out std_logic;
        disp_addr_o : out std_logic;
        disp_sck_o  : out std_logic
    );
    
end nut_LCDDriver;


architecture logic of nut_LCDDriver is
    type font_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant font : font_t :=(
    	-- 64 X"40 '@' 
	X"3e", -- 01111100 
	X"7f", -- 11000110 
	X"41", -- 11011110 
	X"5d", -- 11011110 
	X"5d", -- 11011110 
	X"1f", -- 11000000 
	X"1e", -- 01111000 
	X"00", -- 00000000 

	-- 65 X"41 'A' 
	X"7c", -- 00111000 
	X"7e", -- 01101100 
	X"0b", -- 11000110 
	X"09", -- 11111110 
	X"0b", -- 11000110 
	X"7e", -- 11000110 
	X"7c", -- 11000110 
	X"00", -- 00000000 

	-- 66 X"42 'B' 
	X"41", -- 11111100 
	X"7f", -- 01100110 
	X"7f", -- 01100110 
	X"49", -- 01111100 
	X"49", -- 01100110 
	X"7f", -- 01100110 
	X"36", -- 11111100 
	X"00", -- 00000000 

	-- 67 X"43 'C' 
	X"1c", -- 00111100 
	X"3e", -- 01100110 
	X"63", -- 11000000 
	X"41", -- 11000000 
	X"41", -- 11000000 
	X"63", -- 01100110 
	X"22", -- 00111100 
	X"00", -- 00000000 

	-- 68 X"44 'D' 
	X"41", -- 11111000 
	X"7f", -- 01101100 
	X"7f", -- 01100110 
	X"41", -- 01100110 
	X"63", -- 01100110 
	X"3e", -- 01101100 
	X"1c", -- 11111000 
	X"00", -- 00000000 

	-- 69 X"45 'E' 
	X"41", -- 11111110 
	X"7f", -- 01100010 
	X"7f", -- 01101000 
	X"49", -- 01111000 
	X"5d", -- 01101000 
	X"41", -- 01100010 
	X"63", -- 11111110 
	X"00", -- 00000000 

	-- 70 X"46 'F' 
	X"41", -- 11111110 
	X"7f", -- 01100010 
	X"7f", -- 01101000 
	X"49", -- 01111000 
	X"1d", -- 01101000 
	X"01", -- 01100000 
	X"03", -- 11110000 
	X"00", -- 00000000 

	-- 71 X"47 'G' 
	X"1c", -- 00111100 
	X"3e", -- 01100110 
	X"63", -- 11000000 
	X"41", -- 11000000 
	X"51", -- 11001110 
	X"33", -- 01100110 
	X"72", -- 00111010 
	X"00", -- 00000000 

	-- 72 X"48 'H' 
	X"7f", -- 11000110 
	X"7f", -- 11000110 
	X"08", -- 11000110 
	X"08", -- 11111110 
	X"08", -- 11000110 
	X"7f", -- 11000110 
	X"7f", -- 11000110 
	X"00", -- 00000000 

	-- 73 X"49 'I' 
	X"00", -- 00111100 
	X"00", -- 00011000 
	X"41", -- 00011000 
	X"7f", -- 00011000 
	X"7f", -- 00011000 
	X"41", -- 00011000 
	X"00", -- 00111100 
	X"00", -- 00000000 

	-- 74 X"4a 'J' 
	X"30", -- 00011110 
	X"70", -- 00001100 
	X"40", -- 00001100 
	X"41", -- 00001100 
	X"7f", -- 11001100 
	X"3f", -- 11001100 
	X"01", -- 01111000 
	X"00", -- 00000000 

	-- 75 X"4b 'K' 
	X"41", -- 11100110 
	X"7f", -- 01100110 
	X"7f", -- 01101100 
	X"08", -- 01111000 
	X"1c", -- 01101100 
	X"77", -- 01100110 
	X"63", -- 11100110 
	X"00", -- 00000000 

	-- 76 X"4c 'L' 
	X"41", -- 11110000 
	X"7f", -- 01100000 
	X"7f", -- 01100000 
	X"41", -- 01100000 
	X"40", -- 01100010 
	X"60", -- 01100110 
	X"70", -- 11111110 
	X"00", -- 00000000 

	-- 77 X"4d 'M' 
	X"7f", -- 11000110 
	X"7f", -- 11101110 
	X"0e", -- 11111110 
	X"1c", -- 11111110 
	X"0e", -- 11010110 
	X"7f", -- 11000110 
	X"7f", -- 11000110 
	X"00", -- 00000000 

	-- 78 X"4e 'N' 
	X"7f", -- 11000110 
	X"7f", -- 11100110 
	X"06", -- 11110110 
	X"0c", -- 11011110 
	X"18", -- 11001110 
	X"7f", -- 11000110 
	X"7f", -- 11000110 
	X"00", -- 00000000 

	-- 79 X"4f 'O' 
	X"3e", -- 01111100 
	X"7f", -- 11000110 
	X"41", -- 11000110 
	X"41", -- 11000110 
	X"41", -- 11000110 
	X"7f", -- 11000110 
	X"3e", -- 01111100 
	X"00", -- 00000000 

	-- 80 X"50 'P' 
	X"41", -- 11111100 
	X"7f", -- 01100110 
	X"7f", -- 01100110 
	X"49", -- 01111100 
	X"09", -- 01100000 
	X"0f", -- 01100000 
	X"06", -- 11110000 
	X"00", -- 00000000 

	-- 81 X"51 'Q' 
	X"3e", -- 01111100 
	X"7f", -- 11000110 
	X"41", -- 11000110 
	X"41", -- 11000110 
	X"e1", -- 11000110 
	X"ff", -- 11001110 
	X"be", -- 01111100 
	X"00", -- 00001110 

	-- 82 X"52 'R' 
	X"41", -- 11111100 
	X"7f", -- 01100110 
	X"7f", -- 01100110 
	X"09", -- 01111100 
	X"19", -- 01101100 
	X"7f", -- 01100110 
	X"66", -- 11100110 
	X"00", -- 00000000 

	-- 83 X"53 'S' 
	X"00", -- 00111100 
	X"22", -- 01100110 
	X"67", -- 00110000 
	X"4d", -- 00011000 
	X"59", -- 00001100 
	X"73", -- 01100110 
	X"22", -- 00111100 
	X"00", -- 00000000 

	-- 84 X"54 'T' 
	X"00", -- 01111110 
	X"07", -- 01111110 
	X"43", -- 01011010 
	X"7f", -- 00011000 
	X"7f", -- 00011000 
	X"43", -- 00011000 
	X"07", -- 00111100 
	X"00", -- 00000000 

	-- 85 X"55 'U' 
	X"3f", -- 11000110 
	X"7f", -- 11000110 
	X"40", -- 11000110 
	X"40", -- 11000110 
	X"40", -- 11000110 
	X"7f", -- 11000110 
	X"3f", -- 01111100 
	X"00", -- 00000000 

	-- 86 X"56 'V' 
	X"1f", -- 11000110 
	X"3f", -- 11000110 
	X"60", -- 11000110 
	X"40", -- 11000110 
	X"60", -- 11000110 
	X"3f", -- 01101100 
	X"1f", -- 00111000 
	X"00", -- 00000000 

	-- 87 X"57 'W' 
	X"3f", -- 11000110 
	X"7f", -- 11000110 
	X"60", -- 11000110 
	X"38", -- 11010110 
	X"60", -- 11010110 
	X"7f", -- 11111110 
	X"3f", -- 01101100 
	X"00", -- 00000000 

	-- 88 X"58 'X' 
	X"63", -- 11000110 
	X"77", -- 11000110 
	X"1c", -- 01101100 
	X"08", -- 00111000 
	X"1c", -- 01101100 
	X"77", -- 11000110 
	X"63", -- 11000110 
	X"00", -- 00000000 

	-- 89 X"59 'Y' 
	X"00", -- 01100110 
	X"07", -- 01100110 
	X"4f", -- 01100110 
	X"78", -- 00111100 
	X"78", -- 00011000 
	X"4f", -- 00011000 
	X"07", -- 00111100 
	X"00", -- 00000000 

	-- 90 X"5a 'Z' 
	X"47", -- 11111110 
	X"63", -- 11000110 
	X"71", -- 10001100 
	X"59", -- 00011000 
	X"4d", -- 00110010 
	X"67", -- 01100110 
	X"73", -- 11111110 
	X"00", -- 00000000 

	-- 91 X"5b '[' 
	X"00", -- 00111100 
	X"00", -- 00110000 
	X"7f", -- 00110000 
	X"7f", -- 00110000 
	X"41", -- 00110000 
	X"41", -- 00110000 
	X"00", -- 00111100 
	X"00", -- 00000000 

	-- 92 X"5c '\' 
	X"01", -- 11000000 
	X"03", -- 01100000 
	X"06", -- 00110000 
	X"0c", -- 00011000 
	X"18", -- 00001100 
	X"30", -- 00000110 
	X"60", -- 00000010 
	X"00", -- 00000000 

	-- 93 X"5d ']' 
	X"00", -- 00111100 
	X"00", -- 00001100 
	X"41", -- 00001100 
	X"41", -- 00001100 
	X"7f", -- 00001100 
	X"7f", -- 00001100 
	X"00", -- 00111100 
	X"00", -- 00000000 

	-- 94 X"5e '^' 
	X"08", -- 00010000 
	X"0c", -- 00111000 
	X"06", -- 01101100 
	X"03", -- 11000110 
	X"06", -- 00000000 
	X"0c", -- 00000000 
	X"08", -- 00000000 
	X"00", -- 00000000 

	-- 95 X"5f '_' 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 00000000 
	X"80", -- 11111111 

	-- 32 X"20 ' ' 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 

	-- 33 X"21 '!' 
	X"00", -- 00011000 
	X"00", -- 00111100 
	X"06", -- 00111100 
	X"5f", -- 00011000 
	X"5f", -- 00011000 
	X"06", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00000000 

	-- 34 X"22 '"' 
	X"00", -- 01100110 
	X"03", -- 01100110 
	X"07", -- 00100100 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"07", -- 00000000 
	X"03", -- 00000000 
	X"00", -- 00000000 

	-- 35 X"23 '#' 
	X"14", -- 01101100 
	X"7f", -- 01101100 
	X"7f", -- 11111110 
	X"14", -- 01101100 
	X"7f", -- 11111110 
	X"7f", -- 01101100 
	X"14", -- 01101100 
	X"00", -- 00000000 

	-- 36 X"24 '$' 
	X"00", -- 00011000 
	X"24", -- 00111110 
	X"2e", -- 01100000 
	X"6b", -- 00111100 
	X"6b", -- 00000110 
	X"3a", -- 01111100 
	X"12", -- 00011000 
	X"00", -- 00000000 

	-- 37 X"25 '%' 
	X"46", -- 00000000 
	X"66", -- 11000110 
	X"30", -- 11001100 
	X"18", -- 00011000 
	X"0c", -- 00110000 
	X"66", -- 01100110 
	X"62", -- 11000110 
	X"00", -- 00000000 

	-- 38 X"26 '&' 
	X"30", -- 00111000 
	X"7a", -- 01101100 
	X"4f", -- 00111000 
	X"5d", -- 01110110 
	X"37", -- 11011100 
	X"7a", -- 11001100 
	X"48", -- 01110110 
	X"00", -- 00000000 

	-- 39 X"27 ''' 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"04", -- 00110000 
	X"07", -- 00000000 
	X"03", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 

	-- 40 X"28 '(' 
	X"00", -- 00001100 
	X"00", -- 00011000 
	X"1c", -- 00110000 
	X"3e", -- 00110000 
	X"63", -- 00110000 
	X"41", -- 00011000 
	X"00", -- 00001100 
	X"00", -- 00000000 

	-- 41 X"29 ')' 
	X"00", -- 00110000 
	X"00", -- 00011000 
	X"41", -- 00001100 
	X"63", -- 00001100 
	X"3e", -- 00001100 
	X"1c", -- 00011000 
	X"00", -- 00110000 
	X"00", -- 00000000 

	-- 42 X"2a '*' 
	X"08", -- 00000000 
	X"2a", -- 01100110 
	X"3e", -- 00111100 
	X"1c", -- 11111111 
	X"1c", -- 00111100 
	X"3e", -- 01100110 
	X"2a", -- 00000000 
	X"08", -- 00000000 

	-- 43 X"2b '+' 
	X"00", -- 00000000 
	X"08", -- 00011000 
	X"08", -- 00011000 
	X"3e", -- 01111110 
	X"3e", -- 00011000 
	X"08", -- 00011000 
	X"08", -- 00000000 
	X"00", -- 00000000 

	-- 44 X"2c '",' 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"80", -- 00000000 
	X"e0", -- 00000000 
	X"60", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"00", -- 00110000 

	-- 45 X"2d '-' 
	X"00", -- 00000000 
	X"08", -- 00000000 
	X"08", -- 00000000 
	X"08", -- 01111110 
	X"08", -- 00000000 
	X"08", -- 00000000 
	X"08", -- 00000000 
	X"00", -- 00000000 

	-- 46 X"2e '.' 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 
	X"60", -- 00000000 
	X"60", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"00", -- 00000000 

	-- 47 X"2f '/' 
	X"60", -- 00000110 
	X"30", -- 00001100 
	X"18", -- 00011000 
	X"0c", -- 00110000 
	X"06", -- 01100000 
	X"03", -- 11000000 
	X"01", -- 10000000 
	X"00", -- 00000000 

	-- 48 X"30 '0' 
	X"1c", -- 00111000 
	X"3e", -- 01101100 
	X"63", -- 11000110 
	X"49", -- 11010110 
	X"63", -- 11000110 
	X"3e", -- 01101100 
	X"1c", -- 00111000 
	X"00", -- 00000000 

	-- 49 X"31 '1' 
	X"00", -- 00011000 
	X"40", -- 00111000 
	X"42", -- 00011000 
	X"7f", -- 00011000 
	X"7f", -- 00011000 
	X"40", -- 00011000 
	X"40", -- 01111110 
	X"00", -- 00000000 

	-- 50 X"32 '2' 
	X"42", -- 01111100 
	X"63", -- 11000110 
	X"71", -- 00000110 
	X"59", -- 00011100 
	X"49", -- 00110000 
	X"6f", -- 01100110 
	X"66", -- 11111110 
	X"00", -- 00000000 

	-- 51 X"33 '3' 
	X"22", -- 01111100 
	X"63", -- 11000110 
	X"49", -- 00000110 
	X"49", -- 00111100 
	X"49", -- 00000110 
	X"7f", -- 11000110 
	X"36", -- 01111100 
	X"00", -- 00000000 

	-- 52 X"34 '4' 
	X"18", -- 00011100 
	X"1c", -- 00111100 
	X"16", -- 01101100 
	X"53", -- 11001100 
	X"7f", -- 11111110 
	X"7f", -- 00001100 
	X"50", -- 00011110 
	X"00", -- 00000000 

	-- 53 X"35 '5' 
	X"2f", -- 11111110 
	X"6f", -- 11000000 
	X"49", -- 11000000 
	X"49", -- 11111100 
	X"49", -- 00000110 
	X"79", -- 11000110 
	X"31", -- 01111100 
	X"00", -- 00000000 

	-- 54 X"36 '6' 
	X"3c", -- 00111000 
	X"7e", -- 01100000 
	X"4b", -- 11000000 
	X"49", -- 11111100 
	X"49", -- 11000110 
	X"78", -- 11000110 
	X"30", -- 01111100 
	X"00", -- 00000000 

	-- 55 X"37 '7' 
	X"03", -- 11111110 
	X"03", -- 11000110 
	X"71", -- 00001100 
	X"79", -- 00011000 
	X"0d", -- 00110000 
	X"07", -- 00110000 
	X"03", -- 00110000 
	X"00", -- 00000000 

	-- 56 X"38 '8' 
	X"36", -- 01111100 
	X"7f", -- 11000110 
	X"49", -- 11000110 
	X"49", -- 01111100 
	X"49", -- 11000110 
	X"7f", -- 11000110 
	X"36", -- 01111100 
	X"00", -- 00000000 

	-- 57 X"39 '9' 
	X"06", -- 01111100 
	X"4f", -- 11000110 
	X"49", -- 11000110 
	X"49", -- 01111110 
	X"69", -- 00000110 
	X"3f", -- 00001100 
	X"1e", -- 01111000 
	X"00", -- 00000000 

	-- 58 X"3a ':' 
	X"00", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"66", -- 00000000 
	X"66", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"00", -- 00000000 

	-- 59 X"3b ';' 
	X"00", -- 00000000 
	X"00", -- 00011000 
	X"80", -- 00011000 
	X"e6", -- 00000000 
	X"66", -- 00000000 
	X"00", -- 00011000 
	X"00", -- 00011000 
	X"00", -- 00110000 

	-- 60 X"3c '<' 
	X"00", -- 00000110 
	X"00", -- 00001100 
	X"08", -- 00011000 
	X"1c", -- 00110000 
	X"36", -- 00011000 
	X"63", -- 00001100 
	X"41", -- 00000110 
	X"00", -- 00000000 

	-- 61 X"3d '=' 
	X"00", -- 00000000 
	X"24", -- 00000000 
	X"24", -- 01111110 
	X"24", -- 00000000 
	X"24", -- 00000000 
	X"24", -- 01111110 
	X"24", -- 00000000 
	X"00", -- 00000000 

	-- 62 X"3e '>' 
	X"00", -- 01100000 
	X"41", -- 00110000 
	X"63", -- 00011000 
	X"36", -- 00001100 
	X"1c", -- 00011000 
	X"08", -- 00110000 
	X"00", -- 01100000 
	X"00", -- 00000000 

	-- 63 X"3f '?' 
	X"02", -- 01111100 
	X"03", -- 11000110 
	X"01", -- 00001100 
	X"59", -- 00011000 
	X"5d", -- 00011000 
	X"07", -- 00000000 
	X"02", -- 00011000 
	X"00", -- 00000000 

	-- 96 X"60 '`' 
	X"00", -- 00110000 
	X"00", -- 00011000 
	X"01", -- 00001100 
	X"03", -- 00000000 
	X"06", -- 00000000 
	X"04", -- 00000000 
	X"00", -- 00000000 
	X"00", -- 00000000 

	-- 97 X"61 'a' 
	X"20", -- 00000000 
	X"74", -- 00000000 
	X"54", -- 01111000 
	X"54", -- 00001100 
	X"3c", -- 01111100 
	X"78", -- 11001100 
	X"40", -- 01110110 
	X"00", -- 00000000 

	-- 98 X"62 'b' 
	X"41", -- 11100000 
	X"7f", -- 01100000 
	X"3f", -- 01111100 
	X"44", -- 01100110 
	X"44", -- 01100110 
	X"7c", -- 01100110 
	X"38", -- 11011100 
	X"00", -- 00000000 

	-- 99 X"63 'c' 
	X"38", -- 00000000 
	X"7c", -- 00000000 
	X"44", -- 01111100 
	X"44", -- 11000110 
	X"44", -- 11000000 
	X"6c", -- 11000110 
	X"28", -- 01111100 
	X"00", -- 00000000 

	-- 100 X"64 'd' 
	X"38", -- 00011100 
	X"7c", -- 00001100 
	X"44", -- 01111100 
	X"45", -- 11001100 
	X"3f", -- 11001100 
	X"7f", -- 11001100 
	X"40", -- 01110110 
	X"00", -- 00000000 

	-- 101 X"65 'e' 
	X"38", -- 00000000 
	X"7c", -- 00000000 
	X"54", -- 01111100 
	X"54", -- 11000110 
	X"54", -- 11111110 
	X"5c", -- 11000000 
	X"18", -- 01111100 
	X"00", -- 00000000 

	-- 102 X"66 'f' 
	X"48", -- 00111100 
	X"7e", -- 01100110 
	X"7f", -- 01100000 
	X"49", -- 11111000 
	X"09", -- 01100000 
	X"03", -- 01100000 
	X"02", -- 11110000 
	X"00", -- 00000000 

	-- 103 X"67 'g' 
	X"98", -- 00000000 
	X"bc", -- 00000000 
	X"a4", -- 01110110 
	X"a4", -- 11001100 
	X"f8", -- 11001100 
	X"7c", -- 01111100 
	X"04", -- 00001100 
	X"00", -- 11111000 

	-- 104 X"68 'h' 
	X"41", -- 11100000 
	X"7f", -- 01100000 
	X"7f", -- 01101100 
	X"08", -- 01110110 
	X"04", -- 01100110 
	X"7c", -- 01100110 
	X"78", -- 11100110 
	X"00", -- 00000000 

	-- 105 X"69 'i' 
	X"00", -- 00011000 
	X"00", -- 00000000 
	X"44", -- 00111000 
	X"7d", -- 00011000 
	X"7d", -- 00011000 
	X"40", -- 00011000 
	X"00", -- 00111100 
	X"00", -- 00000000 

	-- 106 X"6a 'j' 
	X"00", -- 00000110 
	X"60", -- 00000000 
	X"e0", -- 00000110 
	X"80", -- 00000110 
	X"80", -- 00000110 
	X"fd", -- 01100110 
	X"7d", -- 01100110 
	X"00", -- 00111100 

	-- 107 X"6b 'k' 
	X"41", -- 11100000 
	X"7f", -- 01100000 
	X"7f", -- 01100110 
	X"10", -- 01101100 
	X"38", -- 01111000 
	X"6c", -- 01101100 
	X"44", -- 11100110 
	X"00", -- 00000000 

	-- 108 X"6c 'l' 
	X"00", -- 00111000 
	X"00", -- 00011000 
	X"41", -- 00011000 
	X"7f", -- 00011000 
	X"7f", -- 00011000 
	X"40", -- 00011000 
	X"00", -- 00111100 
	X"00", -- 00000000 

	-- 109 X"6d 'm' 
	X"7c", -- 00000000 
	X"7c", -- 00000000 
	X"0c", -- 11101100 
	X"78", -- 11111110 
	X"0c", -- 11010110 
	X"7c", -- 11010110 
	X"78", -- 11010110 
	X"00", -- 00000000 

	-- 110 X"6e 'n' 
	X"04", -- 00000000 
	X"7c", -- 00000000 
	X"78", -- 11011100 
	X"04", -- 01100110 
	X"04", -- 01100110 
	X"7c", -- 01100110 
	X"78", -- 01100110 
	X"00", -- 00000000 

	-- 111 X"6f 'o' 
	X"38", -- 00000000 
	X"7c", -- 00000000 
	X"44", -- 01111100 
	X"44", -- 11000110 
	X"44", -- 11000110 
	X"7c", -- 11000110 
	X"38", -- 01111100 
	X"00"  -- 00000000 

    );
    signal RA       : std_logic_vector(47 downto 0) := X"000000000000";
    signal RB       : std_logic_vector(47 downto 0) := X"000000000000";
    signal RC       : std_logic_vector(47 downto 0) := X"000000000000";
    signal RANN     : std_logic_vector(11 downto 0) := X"000";
    signal srra     : std_logic; -- rotate right A
    signal srrb     : std_logic; -- rotate right B
    signal srrc     : std_logic; -- rotate right C
    signal srra4    : std_logic; -- rotate right A
    signal srrb4    : std_logic; -- rotate right B
    signal srrc4    : std_logic; -- rotate right C
    signal slra     : std_logic; -- rotate left A
    signal slrb     : std_logic; -- rotate left B
    signal slrc     : std_logic; -- rotate left C
    signal slra4    : std_logic; -- rotate left A
    signal slrb4    : std_logic; -- rotate left B
    signal slrc4    : std_logic; -- rotate left C
    signal slra6    : std_logic; -- rotate left A
    signal slrb6    : std_logic; -- rotate left B
        type state_t is (
        ST_RESET,
        ST_INIT,
        ST_WAIT_FOR_RFSH,
        ST_RFSH_START,
        ST_RFSH_LINE,
        ST_SLEEP_CMD,
        ST_POWER_DOWN,
        ST_WAKE_UP
    );
    type cmd_t is array (natural range <>) of std_logic_vector(7 downto 0);
    type cmd_rfsh_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant cmd        : cmd_t := (X"40", X"A0", X"C8", X"A6", X"A2", X"2F", X"F8", X"00", 
                                    X"23", X"81", X"1F", X"AC", X"00", X"AF");
    constant cmd_rfsh   : cmd_rfsh_t := (X"B0", X"10", X"00");
    signal state        : state_t;
    signal curr_bit     : integer range 0 to 31;
    signal ss           : std_logic := '0';
    signal dispon       : std_logic := '0';
    signal send_ready   : std_logic := '0';
    signal disp_sck     : std_logic := '0';
    signal clock_active : std_logic := '0';
    signal lcd_page     : std_logic_vector(2 downto 0);
    signal lcd_col      : std_logic_vector(7 downto 0);
    signal out_data     : std_logic_vector(7 downto 0);
    signal cmddata      : std_logic_vector(7 downto 0);
    signal fontdata     : std_logic_vector(7 downto 0);
    signal force_refresh : std_logic := '0';
    signal refresh_ti   : integer range 0 to 511;
    signal active_digit : integer range 0 to 15;
    signal active_vline : integer range 0 to 7; -- it should be 11 for : ; and ,
    signal fontaddr     : std_logic_vector(9 downto 0);
    signal cmdaddr      : integer range 0 to 31;
    signal digit        : std_logic_vector(6 downto 0);
    signal ann          : std_logic;                    -- current annunciator
    signal up           : std_logic;                    -- current upper point of the semicolon
    signal lp           : std_logic;                    -- current lower point
    signal cm           : std_logic;                    -- current comma
    signal punct        : std_logic_vector(1 downto 0); -- current punctuation
begin

    disp_sck_o <= disp_sck;
    disp_cs_n_o <= ss;
    disp_data_o <= out_data(7); -- MSB first
    disp_addr_o <= '1' when state = ST_RFSH_LINE else '0';
                     
    disp_res_n_o <= not reset_in;

    -- LCD Initialization and refresh state machine
    fontaddr <= digit & std_logic_vector(to_unsigned(active_vline, 3));
    fontdata <= font( to_integer(unsigned(fontaddr)));
    
    process (clk_in, reset_in)
    begin
        if reset_in = '1' then 
            state <= ST_INIT;
            ss <= '1';
            send_ready <= '1';
            lcd_page <= "000";
            lcd_col <= X"00";
            curr_bit <= 0;
            cmdaddr <= 0;
            active_digit <= 0;
        elsif rising_edge(clk_in) then

            if clock_active = '1' then
                disp_sck <= not disp_sck;
            else
                disp_sck <= '0';
            end if;
            case (state) is
                when ST_INIT =>
                    if send_ready = '1' then
                        if cmdaddr < 14 then -- send initialization sequence
                            cmddata <= cmd(cmdaddr);
                            cmdaddr <= cmdaddr + 1;
                            send_ready <= '0';
                            curr_bit <= 0;
                        else
                            state <= ST_WAIT_FOR_RFSH;
                            cmdaddr <= 0;
                        end if;
                    end if;
                when ST_WAIT_FOR_RFSH =>
                    if force_refresh = '1' then
                        state <= ST_RFSH_START;
                    end if;
                when ST_RFSH_START => 
                    if send_ready = '1' then
                        if cmdaddr < 2 then -- send initialization sequence
                            cmddata <= cmd_rfsh(cmdaddr);
                            cmdaddr <= cmdaddr + 1;
                            send_ready <= '0';
                            curr_bit <= 0;
                        else
                            state <= ST_RFSH_LINE;
                            cmdaddr <= 0;
                            active_digit <= 11;
                            active_vline <= 0;
                        end if;
                    end if;
                when ST_RFSH_LINE =>
                    if send_ready = '1' then
                        curr_bit <= 0;
                        cmddata <= fontdata;
                        if active_vline = 7 then
                            if active_digit = 0 then -- end of refresh
                                state <= ST_WAIT_FOR_RFSH;
                            else
                                send_ready <= '0';
                                active_digit <= active_digit - 1;
                            end if;
                            active_vline <= 0;
                        else
                            send_ready <= '0';
                            active_vline <= active_vline + 1;
                        end if;
                    end if;
                when others => null;
            end case;
            -- sender state machine
            -- the SPI clock is only output when the slave device is selected
            if send_ready = '0' then
                case (curr_bit) is
                    when 0 => out_data <= cmddata;              -- load data to shift
                    when 1 => clock_active <= '1'; ss <= '0';   -- select target device and activate clock output
                    when 3 | 5 | 7 | 9 | 11 | 13 | 15 =>
                        out_data <= out_data(6 downto 0) & '0'; -- shift left, MSB is sent first
                    when 16 => clock_active <= '0';             -- deactivate clock
                    when 18 => ss <= '1'; send_ready <= '1';    -- deactivate slave device
                    when others => null;
                end case;
                curr_bit <= curr_bit + 1;
            end if;
        end if;
    end process;
    


-- DOGM132 command set
--
--Befehl RS R/W DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0 Hex Bemerkung Function Set 
--Command                     | A0 D7 D6 D5 D4 D3 D2 D1 D0 Hex Remark 
--Display start line set      |  0  0  1  0  0  0  0  0  0 $40 Display start line 0 
--ADC set                     |  0  1  0  1  0  0  0  0  1 $A1 ADC reverse *) 
--Common output mode select   |  0  1  1  0  0  0  0  0  0 $C0 Normal COM0~COM31 
--Display normal/reverse      |  0  1  0  1  0  0  1  1  0 $A6 Display normal 
--LCD bias set                |  0  1  0  1  0  0  0  1  0 $A2 Set bias 1/9 (Duty 1/33) 
--Power control set           |  0  0  0  1  0  1  1  1  1 $2F Booster, Regulator and Follower on
--Booster ratio set           |  0  1  1  1  1  1  0  0  0 $F8 Set internal Booster to 3x / 4x
--                            |     0  0  0  0  0  0  0  0 $00 
--V0 voltage regulator set    |  0  0  0  1  0  0  0  1  1 $23 Contrast set
--Electronic volume mode set  |  0  1  0  0  0  0  0  0  1 $81 
--                            |     0  0  0  1  1  1  1  1 $1F
--Static indicator set        |  0  1  0  1  0  1  1  0  0 $AC No indicator  
--No indicator                |     0  0  0  0  0  0  0  0 $00 
--Display ON/OFF              |  0  1  0  1  0  1  1  1  1 $AF Display on

    
    digit <= RC( 0) & RB( 1 downto  0) & RA( 3 downto  0) when active_digit =  0 else
             RC( 4) & RB( 5 downto  4) & RA( 7 downto  4) when active_digit =  1 else
             RC( 8) & RB( 9 downto  8) & RA(11 downto  8) when active_digit =  2 else
             RC(12) & RB(13 downto 12) & RA(15 downto 12) when active_digit =  3 else
             RC(16) & RB(17 downto 16) & RA(19 downto 16) when active_digit =  4 else
             RC(20) & RB(21 downto 20) & RA(23 downto 20) when active_digit =  5 else
             RC(24) & RB(25 downto 24) & RA(27 downto 24) when active_digit =  6 else
             RC(28) & RB(29 downto 28) & RA(31 downto 28) when active_digit =  7 else
             RC(32) & RB(33 downto 32) & RA(35 downto 32) when active_digit =  8 else
             RC(36) & RB(37 downto 36) & RA(39 downto 36) when active_digit =  9 else
             RC(40) & RB(41 downto 40) & RA(43 downto 40) when active_digit = 10 else
             RC(44) & RB(45 downto 44) & RA(47 downto 44) when active_digit = 11 else "0000000";
    
    lp <= '1' when punct = "01" or punct = "11" else '0'; -- 01 : lower point
    up <= '1' when punct = "11" else '0';                 -- 01 : upper point
    cm <= '1' when punct = "10" else '0';                 -- 10 : comma
    
    punct <= RB( 3 downto  2) when active_digit =  0 else -- 00 : no punctuation
             RB( 7 downto  6) when active_digit =  1 else -- 01 : lower point
             RB(11 downto 10) when active_digit =  2 else -- 10 : comma
             RB(15 downto 14) when active_digit =  3 else -- 11 : semicolon
             RB(19 downto 18) when active_digit =  4 else --
             RB(23 downto 22) when active_digit =  5 else
             RB(27 downto 26) when active_digit =  6 else
             RB(31 downto 30) when active_digit =  7 else
             RB(35 downto 34) when active_digit =  8 else
             RB(39 downto 38) when active_digit =  9 else
             RB(43 downto 42) when active_digit = 10 else
             RB(47 downto 46) when active_digit = 11 else "00";
    ann <=   RANN(active_digit);
       
    -- Read port mux
    process (RA, RB, RC, RANN, addr_in, perif_in)
    begin
        if perif_in = X"FD" then
            case (addr_in) is
                when "0000" => data_o <= X"00" & RA;
                when "0001" => data_o <= X"00" & RB;
                when "0010" => data_o <= X"00" & RC;
                when "0011" => data_o <= X"00" &  -- interleaved access
                     RB(23 downto 20) & RA(23 downto 20) &
                     RB(19 downto 16) & RA(19 downto 16) &
                     RB(15 downto 12) & RA(15 downto 12) &
                     RB(11 downto  8) & RA(11 downto  8) &
                     RB( 7 downto  4) & RA( 7 downto  4) &
                     RB( 3 downto  0) & RA( 3 downto  0);
                when "0100" => data_o <= X"00" &
                     RC(15 downto 12) & RB(15 downto 12) & RA(15 downto 12) &
                     RC(11 downto  8) & RB(11 downto  8) & RA(11 downto  8) &
                     RC( 7 downto  4) & RB( 7 downto  4) & RA( 7 downto  4) &
                     RC( 3 downto  0) & RB( 3 downto  0) & RA( 3 downto  0);
                when "0101" => data_o <= X"00000000000" & RANN;
                when "0110" => data_o <= X"0000000000000" & RC(3 downto 0);
                when "0111" => data_o <= X"0000000000000" & RA(3 downto 0);
                when "1000" => data_o <= X"0000000000000" & RB(3 downto 0);
                when "1001" => data_o <= X"0000000000000" & RC(3 downto 0);
                when "1010" => data_o <= X"0000000000000" & RA(3 downto 0);
                when "1011" => data_o <= X"0000000000000" & RB(3 downto 0);
                when "1100" => data_o <= X"000000000000" & RB(3 downto 0) & RA(3 downto 0);
                when "1101" => data_o <= X"000000000000" & RB(3 downto 0) & RA(3 downto 0);
                when "1110" => data_o <= X"00000000000" & RC(3 downto 0) & RB(3 downto 0) & RA(3 downto 0);
                when "1111" => data_o <= X"00000000000" & RC(3 downto 0) & RB(3 downto 0) & RA(3 downto 0);
                when others => data_o <= X"00000000000000";
            end case;
        else
            data_o <= X"00000000000000";
        end if;
    end process;
    
    -- Register read/write
    
    process(cpu_clk_in, reset_in)
    begin
        if reset_in = '1' then
            force_refresh <= '0';
            refresh_ti <= 511;
            slra <= '0';
            slrb <= '0';
            slrc <= '0';
            slra4 <= '0';
            slrb4 <= '0';
            slrc4 <= '0';
            slra6 <= '0';
            slrb6 <= '0';
            srra <= '0';
            srrb <= '0';
            srrc <= '0';
            srra4 <= '0';
            srrb4 <= '0';
            srrc4 <= '0';
            RA <= X"000000000000";
            RB <= X"000000000000";
            RC <= X"000000000000";
            RANN <= X"000";
        elsif rising_edge(cpu_clk_in) then
            if we_in = '1' then
                case (addr_in) is
                    when "0000" => -- REG A full 12 nibbles
                        RA <= data_in;
                    when "0001" => -- REG A full 12 nibbles
                        RB <= data_in;
                    when "0010" => -- REG A full 12 nibbles
                        RC <= data_in;
                    when "0011" => -- REG A/B interleaved 6 nibbles
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        RB( 3 downto  0) <= data_in( 7 downto  4);
                        RA( 7 downto  4) <= data_in(11 downto  8);
                        RB( 7 downto  4) <= data_in(15 downto 12);
                        RA(11 downto  8) <= data_in(19 downto 16);
                        RB(11 downto  8) <= data_in(23 downto 20);
                        RA(15 downto 12) <= data_in(27 downto 24);
                        RB(15 downto 12) <= data_in(31 downto 28);
                        RA(19 downto 16) <= data_in(35 downto 32);
                        RB(19 downto 16) <= data_in(39 downto 36);
                        RA(23 downto 20) <= data_in(43 downto 40);
                        RB(23 downto 20) <= data_in(47 downto 44);
                        slra6 <= '1'; slrb6 <= '1';
                    when "0100"  => -- REG A/B/C interleaved 4 nibbles
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        RB( 3 downto  0) <= data_in( 7 downto  4);
                        RC( 3 downto  0) <= data_in(11 downto  8);
                        RA( 7 downto  4) <= data_in(15 downto 12);
                        RB( 7 downto  4) <= data_in(19 downto 16);
                        RC( 7 downto  4) <= data_in(23 downto 20);
                        RA(11 downto  8) <= data_in(27 downto 24);
                        RB(11 downto  8) <= data_in(31 downto 28);
                        RC(11 downto  8) <= data_in(35 downto 32);
                        RA(15 downto 12) <= data_in(39 downto 36);
                        RB(15 downto 12) <= data_in(43 downto 40);
                        RC(15 downto 12) <= data_in(47 downto 44);
                        srra4 <= '1'; srrb4 <= '1'; srrc4 <= '1';
                    when "0101"  => -- REG A/B interleaved 6 nibbles
                        RA(27 downto 24) <= data_in( 3 downto  0);
                        RB(27 downto 24) <= data_in( 7 downto  4);
                        RA(31 downto 28) <= data_in(11 downto  8);
                        RB(31 downto 28) <= data_in(15 downto 12);
                        RA(35 downto 32) <= data_in(19 downto 16);
                        RB(35 downto 32) <= data_in(23 downto 20);
                        RA(39 downto 36) <= data_in(27 downto 24);
                        RB(39 downto 36) <= data_in(31 downto 28);
                        RA(43 downto 40) <= data_in(35 downto 32);
                        RB(43 downto 40) <= data_in(39 downto 36);
                        RA(47 downto 44) <= data_in(43 downto 40);
                        RB(47 downto 44) <= data_in(47 downto 44);
                        slra6 <= '1'; slrb6 <= '1';
                    when "0110"  => -- REG A/B/C interleaved 4 nibbles
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        RB( 3 downto  0) <= data_in( 7 downto  4);
                        RC( 3 downto  0) <= data_in(11 downto  8);
                        RA( 7 downto  4) <= data_in(15 downto 12);
                        RB( 7 downto  4) <= data_in(19 downto 16);
                        RC( 7 downto  4) <= data_in(23 downto 20);
                        RA(11 downto  8) <= data_in(27 downto 24);
                        RB(11 downto  8) <= data_in(31 downto 28);
                        RC(11 downto  8) <= data_in(35 downto 32);
                        RA(15 downto 12) <= data_in(39 downto 36);
                        RB(15 downto 12) <= data_in(43 downto 40);
                        RC(15 downto 12) <= data_in(47 downto 44);
                        srra4 <= '1'; srrb4 <= '1'; srrc4 <= '1';
                    when "0111"  => -- REG A 1 nibble
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        srra <= '1';
                    when "1000"  => -- REG B 1 nibble
                        RB( 3 downto  0) <= data_in( 3 downto  0);
                        srrb <= '1';
                    when "1001"  => -- REG C 1 nibble
                        RC( 3 downto  0) <= data_in( 3 downto  0);
                        srrc <= '1';
                    when "1010"  => -- REG A 1 nibble
                        RA(47 downto 44) <= data_in( 3 downto  0);
                        slra <= '1';
                    when "1011"  => -- REG B 1 nibble
                        RB(47 downto 44) <= data_in( 3 downto  0);
                        slrb <= '1';
                    when "1100"  => -- REG A/B 1 nibble
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        RB( 3 downto  0) <= data_in( 7 downto  4);
                        srra <= '1'; srrb <= '1';
                    when "1101"  => -- REG A/B 1 nibble
                        RA(47 downto 44) <= data_in( 3 downto  0);
                        RB(47 downto 44) <= data_in( 7 downto  4);
                        slra <= '1'; slrb <= '1';
                    when "1110"  => -- REG A/B/C 1 nibble
                        RA( 3 downto  0) <= data_in( 3 downto  0);
                        RB( 3 downto  0) <= data_in( 7 downto  4);
                        RC( 3 downto  0) <= data_in(11 downto  8);
                        srra <= '1'; srrb <= '1'; srrc <= '1';
                    when "1111"  => -- REG A/B/C 1 nibble
                        RA(47 downto 44) <= data_in( 3 downto  0);
                        RB(47 downto 44) <= data_in( 7 downto  4);
                        RC(47 downto 44) <= data_in(11 downto  8);
                        slra <= '1'; slrb <= '1'; slrc <= '1';
                    when others => null;
                end case;
                refresh_ti <= 63;--511;
            end if;
            if ann_we_in = '1' then
                RANN <= data_in(11 downto  0);
                refresh_ti <= 63;--511;
            end if;
            if rd_in = '1' then
                case (addr_in) is
                    when "0011" => slra6 <= '1'; slrb6 <= '1';
                    when "0100" => slra4 <= '1'; slrb4 <= '1'; slrc4 <= '1';
                    when "0110" => slrc <= '1';
                    when "0111" => srrc <= '1';
                    when "1000" => srrb <= '1';
                    when "1001" => srrc <= '1';
                    when "1010" => slra <= '1';
                    when "1011" => slrb <= '1';
                    when "1100" => srra <= '1'; srrb <= '1';
                    when "1101" => slra <= '1'; slrb <= '1';
                    when "1110" => srra <= '1'; srrb <= '1'; srrc <= '1';
                    when "1111" => slra <= '1'; slrb <= '1'; slrc <= '1';
                    when others => null;
                end case;
            end if;

            if    (slra  = '1') then RA(47 downto  4) <= RA(43 downto  0); RA( 3 downto  0) <= RA(47 downto 44); slra  <= '0';
            elsif (slra4 = '1') then RA(47 downto 16) <= RA(31 downto  0); RA(15 downto  0) <= RA(47 downto 32); slra4 <= '0';
            elsif (slra6 = '1') then RA(47 downto 24) <= RA(23 downto  0); RA(23 downto  0) <= RA(47 downto 24); slra6 <= '0';
            elsif (srra  = '1') then RA(43 downto  0) <= RA(47 downto  4); RA(47 downto 44) <= RA( 3 downto  0); srra  <= '0';
            elsif (srra4 = '1') then RA(31 downto  0) <= RA(47 downto 16); RA(47 downto 32) <= RA(15 downto  0); srra4 <= '0'; end if;

            if    (slrb  = '1') then RB(47 downto  4) <= RB(43 downto  0); RB( 3 downto  0) <= RB(47 downto 44); slrb  <= '0';
            elsif (slrb4 = '1') then RB(47 downto 16) <= RB(31 downto  0); RB(15 downto  0) <= RB(47 downto 32); slrb4 <= '0';
            elsif (slrb6 = '1') then RB(47 downto 24) <= RB(23 downto  0); RB(23 downto  0) <= RB(47 downto 24); slrb6 <= '0';
            elsif (srrb  = '1') then RB(43 downto  0) <= RB(47 downto  4); RB(47 downto 44) <= RB( 3 downto  0); srrb  <= '0';
            elsif (srrb4 = '1') then RB(31 downto  0) <= RB(47 downto 16); RB(47 downto 32) <= RB(15 downto  0); srrb4 <= '0'; end if;

            if    (slrc  = '1') then RC(47 downto  4) <= RC(43 downto  0); RC( 3 downto  0) <= RC(47 downto 44); slrc  <= '0';
            elsif (slrc4 = '1') then RC(47 downto 16) <= RC(31 downto  0); RC(15 downto  0) <= RC(47 downto 32); slrc4 <= '0';
            elsif (srrc  = '1') then RC(43 downto  0) <= RC(47 downto  4); RC(47 downto 44) <= RC( 3 downto  0); srrc  <= '0';
            elsif (srrc4 = '1') then RC(31 downto  0) <= RC(47 downto 16); RC(47 downto 32) <= RC(15 downto  0); srrc4 <= '0'; end if;

            if refresh_ti /= 0 then
                refresh_ti <= refresh_ti - 1;
            end if;
            if refresh_ti = 1 then
                force_refresh <= '1';
            end if;
            if force_refresh = '1' and state = ST_RFSH_LINE then
                force_refresh <= '0';
            end if;
        end if;
    end process;

end architecture logic;    