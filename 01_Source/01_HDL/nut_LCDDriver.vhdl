---
--- HP-41 Display unit
---
--- Drives a 12x14 segments plus annunciators LCD unit
---
---
--- 
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nut_LCDDriver is
    port(
        clk_in      : in std_logic;     -- 1 MHz CPU clock
        reset_in    : in std_logic;   -- active high async reset
        addr_in     : in std_logic_vector(3 downto 0); -- only 4 bits are significant 
        data_in     : in std_logic_vector(47 downto 0); -- only 48 bits are significant (12 nibbles)
        data_o      : out std_logic_vector(55 downto 0); -- only 48 bits are significant (12 nibbles)
        perif_in    : in std_logic_vector(7 downto 0);
        rd_in       : in std_logic;
        we_in       : in std_logic;
        ann_we_in   : in std_logic;
        -- LCD Interface
        commons_o   : inout std_logic_vector(35 downto 0);
        segments_o  : inout std_logic_vector(5 downto 0)
    );
    
end nut_LCDDriver;

architecture logic of nut_LCDDriver is
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
    -- lcd driver
    signal clk_divider : integer range 0 to 9999 := 0;
    signal active_seg : integer range 0 to 11 := 0;
    signal active_digit : integer range 0 to 11 := 0;
    signal digit    : std_logic_vector(6 downto 0);
    signal c0       : std_logic_vector(2 downto 0);
    signal c1       : std_logic_vector(2 downto 0);
    signal c2       : std_logic_vector(2 downto 0);
    signal c3       : std_logic_vector(2 downto 0);
    signal c4       : std_logic_vector(2 downto 0);
    signal c5       : std_logic_vector(2 downto 0);
    signal inactive_low: std_logic;
    signal co0      : std_logic;
    signal co1      : std_logic;
    signal co2      : std_logic;
    signal ann      : std_logic;                    -- current annunciator
    signal up       : std_logic;                    -- current upper point of the semicolon
    signal lp       : std_logic;                    -- current lower point
    signal cm       : std_logic;                    -- current comma
    signal punct    : std_logic_vector(1 downto 0); -- current punctuation
    
begin
    -- LCD driver
    -- Target LCD is a 6 common 12 digit 14 segment LCD
    -- Each common is a group of 6 segments, each digit is divided in 3 groups actuated by consecutive commons
    --
    --                          common  0        common  1         common  2
    --     ---------                             ---------                  
    --    |\   |   /|          |\                 0  |   /                  |
    --    | \  |  / |        0 | \ 1                1|  / 2               1 |
    --    |  \ | /  |  o       |  \                  | /                    |  o 0
    --     ---- ----            ---- 2                ---- 3                
    --    |  / | \  |          |  /                  | \                    |
    --    | /  |  \ |        3 | / 4               5 |  \ 4               2 |
    --    |/   |   \|  o       |/   5                |   \                  |  o 3
    --     ---------   ,        ---------                                      , 4
    --                                                             5
    --    Ann0 Ann1 Ann2                                          Ann0           
    --
    -- The segments are biased with 47 k resistors to VCC and GND and the segments
    -- Waveform
    --
    -- Segment 0
    --      --                                  --
    --     |  |__ __ __ __ __ __ __ __ __ __   |  |__ 
    --     |                                |  |   
    --   --                                  --      
    --  +  0  +  1  +  2  +  3  +  4  +  5  +  0  +    
    -- Segment 1
    --            --                                  --
    --   __ __   |  |__ __ __ __ __ __ __ __ __ __   |  |__
    --        |  |                                |  |
    --         --                                  --                     
    --   +    +     +     +     +     +     +     +     +
    -- Common for "on"
    --   --
    --  |  | 
    --  |  |  
    --      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    
    -- segment driving
    segments_o(0)<= '0' when active_seg =  0 else
                  '1' when active_seg =  1 else 'Z';
    segments_o(1)<= '0' when active_seg =  2 else
                  '1' when active_seg =  3 else 'Z';
    segments_o(2)<= '0' when active_seg =  4 else
                  '1' when active_seg =  5 else 'Z';
    segments_o(3)<= '0' when active_seg =  6 else
                  '1' when active_seg =  7 else 'Z';
    segments_o(4)<= '0' when active_seg =  8 else
                  '1' when active_seg =  9 else 'Z';
    segments_o(5)<= '0' when active_seg = 10 else
                  '1' when active_seg = 11 else 'Z';
    
    -- Common generation, uses look-up tables

    inactive_low <= '0' when (active_seg =  0) else
                    '0' when (active_seg =  2) else
                    '0' when (active_seg =  4) else
                    '0' when (active_seg =  6) else
                    '0' when (active_seg =  8) else
                    '0' when (active_seg = 10) else '1';
    
    commons_o( 0) <= co0 when active_digit =  0 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 1) <= co1 when active_digit =  0 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 2) <= co2 when active_digit =  0 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 3) <= co0 when active_digit =  1 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 4) <= co1 when active_digit =  1 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 5) <= co2 when active_digit =  1 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 6) <= co0 when active_digit =  2 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 7) <= co1 when active_digit =  2 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 8) <= co2 when active_digit =  2 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o( 9) <= co0 when active_digit =  3 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(10) <= co1 when active_digit =  3 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(11) <= co2 when active_digit =  3 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(12) <= co0 when active_digit =  4 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(13) <= co1 when active_digit =  4 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(14) <= co2 when active_digit =  4 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(15) <= co0 when active_digit =  5 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(16) <= co1 when active_digit =  5 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(17) <= co2 when active_digit =  5 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(18) <= co0 when active_digit =  6 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(19) <= co1 when active_digit =  6 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(20) <= co2 when active_digit =  6 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(21) <= co0 when active_digit =  7 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(22) <= co1 when active_digit =  7 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(23) <= co2 when active_digit =  7 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(24) <= co0 when active_digit =  8 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(25) <= co1 when active_digit =  8 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(26) <= co2 when active_digit =  8 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(27) <= co0 when active_digit =  9 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(28) <= co1 when active_digit =  9 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(29) <= co2 when active_digit =  9 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(30) <= co0 when active_digit = 10 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(31) <= co1 when active_digit = 10 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(32) <= co2 when active_digit = 10 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(33) <= co0 when active_digit = 11 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(34) <= co1 when active_digit = 11 else 'Z'; -- when inactive_low = '0' else '1';
    commons_o(35) <= co2 when active_digit = 11 else 'Z'; -- when inactive_low = '0' else '1';


    co0 <= '1' when (c0(0) = '0') and (active_seg =  0) else
           '1' when (c0(0) = '1') and (active_seg =  1) else
           '1' when (c1(0) = '0') and (active_seg =  2) else
           '1' when (c1(0) = '1') and (active_seg =  3) else
           '1' when (c2(0) = '0') and (active_seg =  4) else
           '1' when (c2(0) = '1') and (active_seg =  5) else
           '1' when (c3(0) = '0') and (active_seg =  6) else
           '1' when (c3(0) = '1') and (active_seg =  7) else
           '1' when (c4(0) = '0') and (active_seg =  8) else
           '1' when (c4(0) = '1') and (active_seg =  9) else
           '1' when (c5(0) = '0') and (active_seg = 10) else
           '1' when (c5(0) = '1') and (active_seg = 11) else '0';
          
    co1 <= '1' when (c0(1) = '0') and (active_seg =  0) else
           '1' when (c0(1) = '1') and (active_seg =  1) else
           '1' when (c1(1) = '0') and (active_seg =  2) else
           '1' when (c1(1) = '1') and (active_seg =  3) else
           '1' when (c2(1) = '0') and (active_seg =  4) else
           '1' when (c2(1) = '1') and (active_seg =  5) else
           '1' when (c3(1) = '0') and (active_seg =  6) else
           '1' when (c3(1) = '1') and (active_seg =  7) else
           '1' when (c4(1) = '0') and (active_seg =  8) else
           '1' when (c4(1) = '1') and (active_seg =  9) else
           '1' when (c5(1) = '0') and (active_seg = 10) else
           '1' when (c5(1) = '1') and (active_seg = 11) else '0';

    co2 <= '1' when (c0(2) = '0') and (active_seg =  0) else
           '1' when (c0(2) = '1') and (active_seg =  1) else
           '1' when (c1(2) = '0') and (active_seg =  2) else
           '1' when (c1(2) = '1') and (active_seg =  3) else
           '1' when (c2(2) = '0') and (active_seg =  4) else
           '1' when (c2(2) = '1') and (active_seg =  5) else
           '1' when (c3(2) = '0') and (active_seg =  6) else
           '1' when (c3(2) = '1') and (active_seg =  7) else
           '1' when (c4(2) = '0') and (active_seg =  8) else
           '1' when (c4(2) = '1') and (active_seg =  9) else
           '1' when (c5(2) = '0') and (active_seg = 10) else
           '1' when (c5(2) = '1') and (active_seg = 11) else '0';
    
    process (digit, ann, lp, cm, up)
    begin
        case (digit) is
            when "0000000" => c0 <= "11" & up; c1 <= "011"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- @
            when "0000001" => c0 <= "11" & up; c1 <= "001"; c2 <= "101"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- A
            when "0000010" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "01" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- B
            when "0000011" => c0 <= "11" & up; c1 <= "000"; c2 <= "000"; c3 <= "10" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- C
            when "0000100" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- D
            when "0000101" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- E
            when "0000110" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- F
            when "0000111" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- G
            when "0001000" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- H
            when "0001001" => c0 <= "11" & up; c1 <= "001"; c2 <= "101"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- A
            when "0001010" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "01" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- B
            when "0001011" => c0 <= "11" & up; c1 <= "000"; c2 <= "000"; c3 <= "10" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- C
            when "0001100" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- D
            when "0001101" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- E
            when "0001110" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- F
            when "0001111" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- G
            when "0010000" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- H
            when "0010001" => c0 <= "11" & up; c1 <= "001"; c2 <= "101"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- A
            when "0010010" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "01" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- B
            when "0010011" => c0 <= "11" & up; c1 <= "000"; c2 <= "000"; c3 <= "10" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- C
            when "0010100" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- D
            when "0010101" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- E
            when "0010110" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- F
            when "0010111" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- G
            when "0011000" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- H
            when "0011001" => c0 <= "11" & up; c1 <= "001"; c2 <= "101"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- A
            when "0011010" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "01" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- B
            when "0011011" => c0 <= "11" & up; c1 <= "000"; c2 <= "000"; c3 <= "10" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- C
            when "0011100" => c0 <= "01" & up; c1 <= "011"; c2 <= "001"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "11" & ann; -- D
            when "0011101" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- E
            when "0011110" => c0 <= "11" & up; c1 <= "000"; c2 <= "100"; c3 <= "00" & lp; c4 <= "00" & cm; c5 <= "00" & ann; -- F
            when "0011111" => c0 <= "11" & up; c1 <= "000"; c2 <= "001"; c3 <= "11" & lp; c4 <= "00" & cm; c5 <= "10" & ann; -- G
              
            when others => c0 <= "000"; c1 <= "000"; c2 <= "000"; c3 <= "000"; c4 <= "000"; c5 <= "000";
        end case;
    end process;
    
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
    
    -- Driver clock generation
    process (clk_in, reset_in)
    begin
        if reset_in = '1' then
            clk_divider <= 0;
            active_seg <= 0;
            active_digit <= 0;
        elsif rising_edge(clk_in) then
            if clk_divider = 499 then-- 400 Hz 2499
                clk_divider <= 0;
                if active_seg = 11 then -- 0 to 11 for the 2 phases of the signals
                    active_seg <= 0;
                    if active_digit = 11 then
                        active_digit <= 0;
                    else
                        active_digit <= active_digit + 1;
                    end if;
                else
                    active_seg <= active_seg + 1;
                end if;
            else
                clk_divider <= clk_divider + 1;
            end if;
        end if;
    end process;
    
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
    
    process(clk_in, reset_in)
    begin
        if reset_in = '1' then
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

        elsif rising_edge(clk_in) then
            if perif_in = X"FD" then -- Display Module
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
                end if;
                if ann_we_in = '1' then
                    RANN <= data_in(11 downto  0);
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
           
            end if;
        end if;
    end process;
    
    
end architecture logic;    