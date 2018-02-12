
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- 56 Bit comparator
--
entity nut_compare is
    port(
        a_in        : in std_logic_vector(55 downto 0);
        b_in        : in std_logic_vector(55 downto 0);
        a_eq_b_o    : out std_logic;
        a_neq_b_o   : out std_logic;
        a_gt_b_o    : out std_logic        
    );
end nut_compare;

architecture logic of nut_compare is

    signal c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13 : std_logic;
    signal a, b : unsigned(55 downto 0);
begin
    a <= unsigned(a_in);
	b <= unsigned(b_in);
    
    c0  <= '1' when (a_in( 3 downto  0) = b_in( 3 downto  0)) else '0';
    c1  <= '1' when (a_in( 7 downto  4) = b_in( 7 downto  4)) else '0';
    c2  <= '1' when (a_in(11 downto  8) = b_in(11 downto  8)) else '0';
    c3  <= '1' when (a_in(15 downto 12) = b_in(15 downto 12)) else '0';
    c4  <= '1' when (a_in(19 downto 16) = b_in(19 downto 16)) else '0';
    c5  <= '1' when (a_in(23 downto 20) = b_in(23 downto 20)) else '0';
    c6  <= '1' when (a_in(27 downto 24) = b_in(27 downto 24)) else '0';
    c7  <= '1' when (a_in(31 downto 28) = b_in(31 downto 28)) else '0';
    c8  <= '1' when (a_in(35 downto 32) = b_in(35 downto 32)) else '0';
    c9  <= '1' when (a_in(39 downto 36) = b_in(39 downto 36)) else '0';
    c10 <= '1' when (a_in(43 downto 40) = b_in(43 downto 40)) else '0';
    c11 <= '1' when (a_in(47 downto 44) = b_in(47 downto 44)) else '0';
    c12 <= '1' when (a_in(51 downto 48) = b_in(51 downto 48)) else '0';
    c13 <= '1' when (a_in(55 downto 52) = b_in(55 downto 52)) else '0';
    
    a_eq_b_o <= c0 and c1 and c2 and c3 and c4 and c5 and c6 and c7 and c8 and c9 and c10 and c11 and c12 and c13;
    a_neq_b_o <= not (c0 and c1 and c2 and c3 and c4 and c5 and c6 and c7 and c8 and c9 and c10 and c11 and c12 and c13);

    process (a_in, b_in, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13)
        begin
            if (a(55 downto 52) > b(55 downto 52)) then
                a_gt_b_o <= '1';
            else
            if (c13 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(51 downto 48) > b(51 downto 48)) then
                a_gt_b_o <= '1';
            else
            if (c12 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(47 downto 44) > b(47 downto 44)) then
                a_gt_b_o <= '1';
            else
            if (c11 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(43 downto 40) > b(43 downto 40)) then
                a_gt_b_o <= '1';
            else
            if (c10 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(39 downto 36) > b(39 downto 36)) then
                a_gt_b_o <= '1';
            else
            if (c9 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(35 downto 32) > b(35 downto 32)) then
                a_gt_b_o <= '1';
            else
            if (c8 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(31 downto 28) > b(31 downto 28)) then
                a_gt_b_o <= '1';
            else
            if (c7 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(27 downto 24) > b(27 downto 24)) then
                a_gt_b_o <= '1';
            else
            if (c6 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(23 downto 20) > b(23 downto 20)) then
                a_gt_b_o <= '1';
            else
            if (c5 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(19 downto 16) > b(19 downto 16)) then
                a_gt_b_o <= '1';
            else
            if (c4 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(15 downto 12) > b(15 downto 12)) then
                a_gt_b_o <= '1';
            else
            if (c3 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a(11 downto  8) > b(11 downto  8)) then
                a_gt_b_o <= '1';
            else
            if (c2 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a( 7 downto  4) > b( 7 downto  4)) then      
                a_gt_b_o <= '1';
            else
            if (c1 = '0') then 
                a_gt_b_o <= '0';
            else
            if (a( 3 downto  0) > b( 3 downto  0)) then
                a_gt_b_o <= '1';
            else
            if (c0 = '0') then 
                a_gt_b_o <= '0';
            else
                a_gt_b_o <= '1';                
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
            end if;
			end if; 

        end process;
end architecture logic;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- Calculates the 14 bits mask give the start and stop nibble
--

entity nut_calcmask is
   port(start_in        : in std_logic_vector(3 downto 0);
		stop_in         : in std_logic_vector(3 downto 0);
        mask_o          : out std_logic_vector(13 downto 0)
    );
end nut_calcmask;

architecture logic of nut_calcmask is


    signal lmask		  : std_logic_vector(13 downto 0);
	signal rmask		  : std_logic_vector(13 downto 0);
BEGIN    
    mask_o <= lmask and rmask;	

    PROCESS (start_in)
        BEGIN
            case start_in is
                when "0000" => lmask <= "11111111111111";
                when "0001" => lmask <= "11111111111110";
                when "0010" => lmask <= "11111111111100";
                when "0011" => lmask <= "11111111111000";
                when "0100" => lmask <= "11111111110000";
                when "0101" => lmask <= "11111111100000";
                when "0110" => lmask <= "11111111000000";
                when "0111" => lmask <= "11111110000000";
                when "1000" => lmask <= "11111100000000";
                when "1001" => lmask <= "11111000000000";
                when "1010" => lmask <= "11110000000000";
                when "1011" => lmask <= "11100000000000";
                when "1100" => lmask <= "11000000000000";
                when "1101" => lmask <= "10000000000000";
                when others => lmask <= "10000000000000";
            end case;
        END PROCESS;
    PROCESS (stop_in)
        BEGIN
            case stop_in is
                when "0000" => rmask <= "00000000000001";
                when "0001" => rmask <= "00000000000011";
                when "0010" => rmask <= "00000000000111";
                when "0011" => rmask <= "00000000001111";
                when "0100" => rmask <= "00000000011111";
                when "0101" => rmask <= "00000000111111";
                when "0110" => rmask <= "00000001111111";
                when "0111" => rmask <= "00000011111111";
                when "1000" => rmask <= "00000111111111";
                when "1001" => rmask <= "00001111111111";
                when "1010" => rmask <= "00011111111111";
                when "1011" => rmask <= "00111111111111";
                when "1100" => rmask <= "01111111111111";
                when "1101" => rmask <= "11111111111111";
                when others => rmask <= "11111111111111";
            end case; 
        END PROCESS;
	

end architecture logic;