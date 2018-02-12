
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity nut_disassembler is
    port (
        pc_in           : std_logic_vector(15 downto 0);
        opcode          : in std_logic_vector(9 downto 0); -- 
        second_opcode   : in std_logic_vector(9 downto 0);
        RA_in           : in std_logic_vector(55 downto 0) := X"00000000000000";
        RB_in           : in std_logic_vector(55 downto 0) := X"00000000000000";
        RC_in           : in std_logic_vector(55 downto 0) := X"00000000000000";
        RM_in           : in std_logic_vector(55 downto 0) := X"00000000000000";
        RN_in           : in std_logic_vector(55 downto 0) := X"00000000000000";
        RG_in           : in std_logic_vector( 7 downto 0) := X"00";
        RP_in           : in std_logic_vector( 3 downto 0) := "0000";
        RQ_in           : in std_logic_vector( 3 downto 0) := "0000";
        PT_in           : in std_logic_vector( 3 downto 0) := "0000"; -- actual selected pointer value
        RCY_in          : in std_logic := '0'; 
		use_trace_in    : in std_logic;
        decode_ready_in : in std_logic
    );
end nut_disassembler;

architecture logic of nut_disassembler is
    type unscrambled_t is array (natural range <>) of string (1 to 2);
    constant unscrambled_rom : unscrambled_t := (" 3", " 4", " 5", "10", " 8", " 6", 
                                                 "11", "15", " 2", " 9", " 7", "13", 
                                                 " 1", "12", " 0", "14");
    constant normal_rom      : unscrambled_t := (" 0", " 1", " 2", " 3", " 4", " 5", 
                                                 " 6", " 7", " 8", " 9", "10", "11", 
                                                 "12", "13", "14", "15");
    --constant hex_rom         : unscrambled_t := ("0", "1", "2", "3", "4", "5", 
    --                                             "6", "7", "8", "9", "A", "B", 
    --                                             "C", "D", "E", "F");
    signal ops              : string (1 to 10);
    signal field            : string (1 to 2);
    signal unscrambled      : string (1 to 2);
    signal lvalue           : string (1 to 2);
    signal op               : std_logic_vector(79 downto 0);
    signal sop              : string(1 to 8);
    signal spc              : string(1 to 5);
    signal starget          : string (1 to 5);
    signal short_jump_ofs   : std_logic_vector(15 downto 0);
    signal target_pc        : std_logic_vector(15 downto 0);
    signal is_jump          : std_logic;
    signal is_ldi           : std_logic;
    signal dword_op         : std_logic;
    signal sregs            : string (1 to 69);
    --file trace_log : text;
    
    function to_std_logic_vector( s : string ) return std_logic_vector is
        variable r : std_logic_vector(s'length * 8 - 1 downto 0);
        begin
            for i in 1 to s'high loop
                r( i*8 - 1 downto (i - 1) * 8) := std_logic_vector(to_unsigned(character'pos(s(s'high + 1 - i)), 8));
            end loop;
            return r;
    end function;
    
    function to_shex( h : std_logic_vector(3 downto 0) ) return character is
        variable r: character;
        variable i: integer range 0 to 15;
        
        begin
            i := to_integer(unsigned(h));
            case (i) is
                when  0 => r := character'('0');
                when  1 => r := character'('1');
                when  2 => r := character'('2');
                when  3 => r := character'('3');
                when  4 => r := character'('4');
                when  5 => r := character'('5');
                when  6 => r := character'('6');
                when  7 => r := character'('7');
                when  8 => r := character'('8');
                when  9 => r := character'('9');
                when 10 => r := character'('A');
                when 11 => r := character'('B');
                when 12 => r := character'('C');
                when 13 => r := character'('D');
                when 14 => r := character'('E');
                when 15 => r := character'('F');
            end case;
             return r;
    end function;
    
begin
    unscrambled <= unscrambled_rom(to_integer(unsigned(opcode(9 downto 6))));
    lvalue <= normal_rom(to_integer(unsigned(opcode(9 downto 6))));

    op <= to_std_logic_vector(ops);
       
    process (opcode(4 downto 2))
        begin
            case(opcode(4 downto 2)) is
                when "000" => field <= "PT"; -- Pointer field
                when "001" => field <= " X"; -- X
                when "010" => field <= "WP"; -- WP
                when "011" => field <= " W"; -- W
                when "100" => field <= "PQ";-- PQ
                when "101" => field <= "XS"; -- XS
                when "110" => field <= " M"; -- M
                when "111" => field <= " S"; -- S
                when others =>
                    field <= " S"; -- S
            end case;
        end process;
    
    process (opcode, second_opcode, lvalue, unscrambled)
    
    begin
        case (opcode(1 downto 0)) is
            when "00" => -- general opcodes
                case (opcode(9 downto 2)) is
                    when "00000000" | "00010000" | "00100000" | "00110000" | 
                         "01000000" | "01010000" | "01100000" | "01110000" | 
                         "10000000" | "10010000" | "10100000" | "10110000" | 
                         "11000000" | "11010000" | "11100000" | "11110000"
                     => ops <= "NOP     " & "  ";                        
                    
                    when "00000001" | "00010001" | "00100001" | "00110001" | 
                         "01000001" | "01010001" | "01100001" | "01110001" | 
                         "10000001" | "10010001" | "10100001" | "10110001" | 
                         "11000001" | "11010001" | "11100001"
                    => ops <= "ST=0    " & unscrambled;
                    when "11110001" => ops <= "CLRST     ";
                    
                    when "00000010" | "00010010" | "00100010" | "00110010" | 
                         "01000010" | "01010010" | "01100010" | "01110010" | 
                         "10000010" | "10010010" | "10100010" | "10110010" | 
                         "11000010" | "11010010" | "11100010"
                    => ops <= "ST=1    " & unscrambled;
                    when "11110010" => ops <= "RSTKB     ";
                    
                    when "00000011" | "00010011" | "00100011" | "00110011" | 
                         "01000011" | "01010011" | "01100011" | "01110011" | 
                         "10000011" | "10010011" | "10100011" | "10110011" | 
                         "11000011" | "11010011" | "11100011"
                    => ops <= "?ST=1   " & unscrambled; -- if 1 = s
                    when "11110011" => ops <= "CHKKB     ";
                    when "00000100" | "00010100" | "00100100" | "00110100" |
                         "01000100" | "01010100" | "01100100" | "01110100" |
                         "10000100" | "10010100" | "10100100" | "10110100" |
                         "11000100" | "11010100" | "11100100" | "11110100"
                    => ops <= "LC      " & lvalue; -- Load Constant @P
                    -- 014
                    when "00000101" | "00010101" | "00100101" | "00110101" |
                         "01000101" | "01010101" | "01100101" | "01110101" |
                         "10000101" | "10010101" | "10100101" | "10110101" |
                         "11000101" | "11010101" | "11100101"  
                          => ops <= "?P=     " & unscrambled; --  ? pt == %d
                    when "11110101" => ops <= "P=P-1     "; -- 10'h3d4
                    -- 018
                    when "00000110" => ops <= "NOP       ";
                    when "00010110" => ops <= "G=C[PT]   "; --  g=c
                    when "00100110" => ops <= "C[PT]=G   "; --  c=g
                    when "00110110" => ops <= "C[PT]GEX  "; --  c <-> g
                    when "01000110" => ops <= "NOP       ";
                    when "01010110" => ops <= "M=C      W"; --  m = C
                    when "01100110" => ops <= "C=M      W"; --  c = m
                    when "01110110" => ops <= "CMEX     W"; --  c <-> m
                    when "10000110" => ops <= "NOP       ";
                    when "10010110" => ops <= "F=SB      "; --  fo=s byte
                    when "10100110" => ops <= "SB=F      "; --  s = fo byte
                    when "10110110" => ops <= "FSBEX     "; --  s <-> fo
                    when "11000110" => ops <= "NOP       ";
                    when "11010110" => ops <= "ST=C      "; --  s=c byte
                    when "11100110" => ops <= "C=ST      "; --  c = s byte
                    when "11110110" => ops <= "CSTEX     "; --  s <-> C
                    -- 01c
                    when "00000111" | "00010111" | "00100111" | "00110111" | 
                         "01000111" | "01010111" | "01100111" | "01110111" | 
                         "10000111" | "10010111" | "10100111" | "10110111" | 
                         "11000111" | "11010111" | "11100111"
                                    => ops <= "P=      " & unscrambled; --  Load Constant to P, carry cleared from reg_p module
                    when "11110111" => ops <= "P=P+1     "; -- 10'h3dc
                    -- 020
                    when "00001000" => ops <= "SPOPND    ";
                    when "00011000" => ops <= "PWROFF    "; -- Powers off: executes a RET and loads C with the display status (1 ON, 0 OFF)
                    when "00101000" => ops <= "SELP      ";
                    when "00111000" => ops <= "SELQ      ";
                    when "01001000" => ops <= "?P=Q      ";-- ? p==q 
                    when "01011000" => ops <= "LLD       "; -- FIXME: lld battery status c:clear batteries ok
                    when "01101000" => ops <= "CLRABC    "; -- clear abc
                    when "01111000" => ops <= "GOTOC     "; -- goto c[6:3]
                    when "10001000" => ops <= "NOP       "; -- 
                    when "10011000" => ops <= "SETHEX    "; 
                    when "10101000" => ops <= "SETDEC    "; 
                    when "10111000" => ops <= "DISPOFF   "; 
                    when "11001000" => ops <= "DSPTGL    "; -- really used ?
                    when "11011000" => ops <= "RTNC      "; -- RTNC
                    when "11101000" => ops <= "RTNNC     "; -- rtnnc
                    when "11111000" => ops <= "RTN       "; -- RTN
                    when "00001001" | "00011001" | "00101001" | "00111001" |
                         "01001001" | "01011001" | "01101001" | "01111001" |
                         "10001001" | "10011001" | "10101001" | "10111001" |
                         "11001001" | "11011001" | "11101001" |
                         "11111001" => ops <= "SELPRF    "; -- selprf
                    when "00001010" | "00011010" | "00101010" | "00111010" |
                         "01001010" | "01011010" | "01101010" | "01111010" |
                         "10001010" | "10011010" | "10101010" | "10111010" |
                         "11001010" | "11011010" | "11101010" |
                         "11111010" => ops <= "REG=C   " & lvalue; --  C -> reg n 
                    when "00001011" | "00011011" | "00101011" | "00111011" |
                         "01001011" | "01011011" | "01101011" | "01111011" |
                         "10001011" | "10011011" | "10101011" | "10111011" |
                         "11001011" | "11011011" | "11101011" |
                         "11111011" => ops <= "?Fn=1   " & unscrambled; -- ? 1 = ext flag
                    when "00001100" => ops <= "DSPBLINK  "; -- disp blink
                    when "00011100" => ops <= "N=C      W"; -- n=c
                    when "00101100" => ops <= "C=N      W"; -- c=n
                    when "00111100" => ops <= "CEXN     W";-- c <-> n                        
                    when "01001100" => ops <= "LDI       "; -- c=op2 ldi
                    when "01011100" => ops <= "PUSH C    "; -- push c
                    when "01101100" => ops <= "POP C     "; -- pop c
                    when "01111100" => ops <= "NOP       "; -- ??? 0x1f0
                    when "10001100" => ops <= "GOKEYS    "; -- goto keys
                    when "10011100" => ops <= "DA=C     X"; -- RAM Addr=C
                    when "10101100" => ops <= "CLRREGS   "; -- FIXME:clear regs 0x2b0
                    when "10111100" => ops <= "DATA=C   W"; --  reg[RAMAddr]=C
                    when "11001100" => ops <= "CXISA     "; -- cxisa
                    when "11011100" => ops <= "C=C|A    W"; --  c=c|a
                    when "11101100" => ops <= "C=C&A    W"; --  c=c&a
                    when "11111100" => ops <= "PFAD=C    "; -- sel pfad
                    when "00001101" | "00011101" | "00101101" | "00111101" | 
                         "01001101" | "01011101" | "01101101" | "01111101" | 
                         "10001101" | "10011101" | "10101101" | "10111101" | 
                         "11001101" | "11011101" | "11101101" |
                         "11111101" => ops <= "???       "; -- ??? x34
                    when "00001110" => ops <= "C=DATA    "; -- C=DATA
                    when "00011110" | "00101110" | "00111110" |
                          "01001110" | "01011110" | "01101110" | "01111110" |
                          "10001110" | "10011110" | "10101110" | "10111110" |
                          "11001110" | "11011110" | "11101110" |
                          "11111110" => ops <= "C=REG   " & lvalue; -- reg n -> C
                    when "00001111" | "00011111" | "00101111" | "00111111" |
                         "01001111" | "01011111" | "01101111" | "01111111" |
                         "10001111" | "10011111" | "10101111" | "10111111" |
                         "11001111" | "11011111" | "11101111" |
                         "11111111" => ops <= "RCR     " & unscrambled; -- disp compensation, rcr
                    when others => ops <= "NOP       ";
                            --$display("%04o %10b unrecognized opcode", fetched_addr, opcode);
                end case;
            when "01"=> -- long jump/call
                case (second_opcode(1 downto 0)) is
                    when "00" => ops <= "GOSUBNC   ";
                    when "01" => ops <= "GOSUBC    ";
                    when "10" => ops <= "GOLNC     ";
                    when "11" => ops <= "GOLC      ";
                    when others => null;
                end case;
            when "10" => -- arithmetic opcodes
                case (opcode(9 downto 5)) is
                    when "00000" => ops <= "A=0     " & field; --0 -> a[w ]
                    when "00001" => ops <= "B=0     " & field; --0 -> b[w ]
                    when "00010" => ops <= "C=0     " & field; --0 -> c[w ]
                    when "00011" => ops <= "AEXB    " & field; --a exchange b[wp]
                    when "00100" => ops <= "B=A     " & field; --a -> b[x ]
                    when "00101" => ops <= "AEXC    " & field; --a exchange c[w ]
                    when "00110" => ops <= "C=B     " & field; --b -> c[wp]
                    when "00111" => ops <= "BEXC    " & field; --b exchange c[w ]
                    when "01000" => ops <= "A=C     " & field; --c -> a[wp]
                    when "01001" => ops <= "A=A+B   " & field; -- a + b -> a[ms]
                    when "01010" => ops <= "A=A+C   " & field; -- a + c -> a[m ]
                    when "01011" => ops <= "A=A+1   " & field; -- a + 1 -> a[p ]
                    when "01100" => ops <= "A=A-B   " & field; -- a - b -> a[ms]
                    when "01101" => ops <= "A=A-1   " & field; -- a - 1 -> a[s ]
                    when "01110" => ops <= "A=A-C   " & field; -- a - c -> a[wp]
                    when "01111" => ops <= "C=C+C   " & field; -- c + c -> c[w ]
                    when "10000" => ops <= "C=A+C   " & field; -- a + c -> c[x ]
                    when "10001" => ops <= "C=C+1   " & field; -- c + 1 -> c[xs
                    when "10010" => ops <= "C=C-A   " & field; -- a - c -> c[s ]
                    when "10011" => ops <= "C=C-1   " & field; -- c - 1 -> c[x ]
                    when "10100" => ops <= "C=-C    " & field; -- 0 - c -> c[s ]
                    when "10101" => ops <= "C=-C-1  " & field; -- 0 - c - 1 -> c[s ]
                    when "10110" => ops <= "?0#B    " & field; -- ? 0 <> b
                    when "10111" => ops <= "?0#C    " & field; -- ? 0 <> c
                    when "11000" => ops <= "?A<C    " & field; -- ? a < c
                    when "11001" => ops <= "?A<B    " & field; -- ? a < b
                    when "11010" => ops <= "?0#A    " & field; -- ? 0 <> a
                    when "11011" => ops <= "?A#C    " & field; -- ? a <> c
                    when "11100" => ops <= "ASR     " & field; -- shift right a[wp]
                    when "11101" => ops <= "BSR     " & field; -- shift right b[wp]
                    when "11110" => ops <= "CSR     " & field; -- shift right c[w ]
                    when "11111" => ops <= "ASL     " & field; -- shift left a[w ] 
                    when others =>
                        null;
                end case;
            when "11" => -- short goto c/nc
                if (opcode(2) = '0') then
                    ops <= "GONC      ";
                else
                    ops <= "GOC       ";
                end if;
            when others =>
                ops <= "???       ";
        end case;
    end process;
    
    
    
    dword_op <= '1' when opcode(1 downto 0) = "01" or opcode = "0100110000" else '0';
    -- current PC
    spc(1) <= to_shex(pc_in(15 downto 12));
    spc(2) <= to_shex(pc_in(11 downto  8));
    spc(3) <= to_shex(pc_in( 7 downto  4));
    spc(4) <= to_shex(pc_in( 3 downto  0));
    spc(5) <= character'(' ');

    -- opcode
    sop(1) <= to_shex("00" & opcode(9 downto 8));
    sop(2) <= to_shex(opcode( 7 downto  4));
    sop(3) <= to_shex(opcode( 3 downto  0));
    sop(4) <= character'(' ');
    sop(5) <= character'(' ') when dword_op = '0' else to_shex("00" & second_opcode(9 downto 8));
    sop(6) <= character'(' ') when dword_op = '0' else to_shex(second_opcode(7 downto 4));
    sop(7) <= character'(' ') when dword_op = '0' else to_shex(second_opcode(3 downto 0));
    sop(8) <= character'(' ');
        
    short_jump_ofs <= "1111111111" & opcode(8 downto 3) when opcode(9) = '1' else 
                      "0000000000" & opcode(8 downto 3);

    target_pc <= (second_opcode(9 downto 2) & opcode(9 downto 2)) when (opcode(1 downto 0) = "01") else
                 std_logic_vector(unsigned(pc_in) + unsigned(short_jump_ofs)); -- short branches
    
    is_jump   <= '1' when opcode(1 downto 0) = "01" or opcode(1 downto 0) = "11" else '0';
    is_ldi    <= '1' when opcode = "0100110000" else '0';
    -- target address
    starget(1) <= character'(' ');
    starget(2) <= to_shex(target_pc(15 downto 12)) when is_ldi = '0' else to_shex("00" & second_opcode(9 downto 8));
    starget(3) <= to_shex(target_pc(11 downto  8)) when is_ldi = '0' else to_shex(second_opcode(7 downto 4));
    starget(4) <= to_shex(target_pc( 7 downto  4)) when is_ldi = '0' else to_shex(second_opcode(3 downto 0));
    starget(5) <= to_shex(target_pc( 3 downto  0)) when is_ldi = '0' else character'(' ');
    -- register dump
    sregs( 1) <= character'(' ');
    sregs( 2) <= character'('P');
    sregs( 3) <= character'(':');
    sregs( 4) <= to_shex(RP_in);
    sregs( 5) <= character'(' ');
    sregs( 6) <= character'('Q');
    sregs( 7) <= character'(':');
    sregs( 8) <= to_shex(RQ_in);
    sregs( 9) <= character'(' ');
    sregs(10) <= character'('P');
    sregs(11) <= character'('T');
    sregs(12) <= character'(':');
    sregs(13) <= to_shex(PT_in);
    sregs(14) <= character'(' ');
    sregs(15) <= character'('C');
    sregs(16) <= character'('Y');
    sregs(17) <= character'(':');
    sregs(18) <= to_shex("000" & RCY_in);
    sregs(19) <= character'(' ');
    sregs(20) <= character'('A');
    sregs(21) <= character'(':');
    sregs(22) <= to_shex(RA_in(55 downto 52));
    sregs(23) <= to_shex(RA_in(51 downto 48));
    sregs(24) <= to_shex(RA_in(47 downto 44));
    sregs(25) <= to_shex(RA_in(43 downto 40));
    sregs(26) <= to_shex(RA_in(39 downto 36));
    sregs(27) <= to_shex(RA_in(35 downto 32));
    sregs(28) <= to_shex(RA_in(31 downto 28));
    sregs(29) <= to_shex(RA_in(27 downto 24));
    sregs(30) <= to_shex(RA_in(23 downto 20));
    sregs(31) <= to_shex(RA_in(19 downto 16));
    sregs(32) <= to_shex(RA_in(15 downto 12));
    sregs(33) <= to_shex(RA_in(11 downto  8));
    sregs(34) <= to_shex(RA_in( 7 downto  4));
    sregs(35) <= to_shex(RA_in( 3 downto  0));
    sregs(36) <= character'(' ');
    sregs(37) <= character'('B');
    sregs(38) <= character'(':');
    sregs(39) <= to_shex(RB_in(55 downto 52));
    sregs(40) <= to_shex(RB_in(51 downto 48));
    sregs(41) <= to_shex(RB_in(47 downto 44));
    sregs(42) <= to_shex(RB_in(43 downto 40));
    sregs(43) <= to_shex(RB_in(39 downto 36));
    sregs(44) <= to_shex(RB_in(35 downto 32));
    sregs(45) <= to_shex(RB_in(31 downto 28));
    sregs(46) <= to_shex(RB_in(27 downto 24));
    sregs(47) <= to_shex(RB_in(23 downto 20));
    sregs(48) <= to_shex(RB_in(19 downto 16));
    sregs(49) <= to_shex(RB_in(15 downto 12));
    sregs(50) <= to_shex(RB_in(11 downto  8));
    sregs(51) <= to_shex(RB_in( 7 downto  4));
    sregs(52) <= to_shex(RB_in( 3 downto  0));
    sregs(53) <= character'(' ');
    sregs(54) <= character'('C');
    sregs(55) <= character'(':');
    sregs(56) <= to_shex(RC_in(55 downto 52));
    sregs(57) <= to_shex(RC_in(51 downto 48));
    sregs(58) <= to_shex(RC_in(47 downto 44));
    sregs(59) <= to_shex(RC_in(43 downto 40));
    sregs(60) <= to_shex(RC_in(39 downto 36));
    sregs(61) <= to_shex(RC_in(35 downto 32));
    sregs(62) <= to_shex(RC_in(31 downto 28));
    sregs(63) <= to_shex(RC_in(27 downto 24));
    sregs(64) <= to_shex(RC_in(23 downto 20));
    sregs(65) <= to_shex(RC_in(19 downto 16));
    sregs(66) <= to_shex(RC_in(15 downto 12));
    sregs(67) <= to_shex(RC_in(11 downto  8));
    sregs(68) <= to_shex(RC_in( 7 downto  4));
    sregs(69) <= to_shex(RC_in( 3 downto  0));


    process (decode_ready_in)
    variable oline : line;
    begin
        if falling_edge(decode_ready_in) then
		    if (use_trace_in ='1') then
				if (is_jump = '1') or is_ldi = '1' then
					write(OUTPUT, spc & sop & ops & starget & sregs);
				else
					write(OUTPUT, spc & sop & ops & "     " & sregs);
				end if;
			end if;
		end if;
    end process;
    
end architecture logic;
