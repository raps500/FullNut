--
-- FullNut
-- (c) 2018 R.A. Paz Schmidt
-- A parallel FullNut implementation in VHDL
-- Target device Lattice MachXO2 or iCE4UP5K

-------------------------------------------------------------------------------
--
-- Nut Instruction set
--   9   8   7   6   5   4   3   2   1   0
-- +---+---+---+---+---+---+---+---+---+---+
-- |   |   |   |   |   |   |   |   | 0 | 0 | Special type
-- +---+---+---+---+---+---+---+---+---+---+
--
-- 0nnn 0000 : NOP
-- 1nnn 0000 : HPIL n,C
-- nnnn 0001 : ST=0 n (n:0..14) uses scrambled n 
-- 1111 0001 : CLRST   (first 8 bits only)
-- nnnn 0010 : ST=1 n (n:0..14) uses scrambled n 
-- 1111 0010 : RSTKB 
-- nnnn 0011 : ?ST=1 n (n:0..14) uses scrambled n 
-- 1111 0011 : CHKKB
-- nnnn 0100 : LC n C[PT] = n PT=PT+1
-- nnnn 0101 : ?PT = n uses scrambled n 
-- 1111 0101 : PT=PT-1
--
-- 0000 0110 : ?, NOP
-- 0001 0110 : G=C[PT]
-- 0010 0110 : C[PT]=G     
-- 0011 0110 : C[PT]EXG     
-- 0100 0110 : ?, NOP
-- 0101 0110 : M=C
-- 0110 0110 : C=M
-- 0111 0110 : CMEX
-- 1000 0110 : ?, NOP
-- 1001 0110 : F=SB (Output port(7..0) = ST(7..0)
-- 1010 0110 : SB=F ST(7..0) = Output port(7..0)
-- 1011 0110 : FSBEX ST(7..0) xchg Output port(7..0)
-- 1100 0110 : ?
-- 1101 0110 : ST=C(7..0)
-- 1110 0110 : C=ST(7..0)
-- 1111 0110 : CSTEX(7..0)
--
-- nnnn 0111 : PT=n (n: 0..14) uses scrambled n 
-- 1111 0111 : PT=PT+1
-- 0000 1000 : SPOPND
-- 0001 1000 : PWROFF
-- 0010 1000 : SELP
-- 0011 1000 : SELQ
-- 0100 1000 : ?P=Q
-- 0101 1000 : LLD Battery status to C 0 : OK 1 low
-- 0110 1000 : CLRABC
-- 0111 1000 : GOTOC
-- 1000 1000 : C=KEYS
-- 1001 1000 : SETHEX
-- 1010 1000 : SETDEC
-- 1011 1000 : DSPOFF
-- 1100 1000 : DSPTOGGLE
-- 1101 1000 : RTNC
-- 1110 1000 : RTNNC
-- 1111 1000 : RTN
--
-- nnnn 1001 : SELPF n
-- nnnn 1010 : REGN=C n
-- nnnn 1011 : ?Fx=1 uses scrambled n 
-- 0000 1100 : HEXPAK
-- 0001 1100 : N=C
-- 0010 1100 : C=N
-- 0011 1100 : CNEX
-- 0100 1100 : LDI nnn
-- 0101 1100 : STK=C
-- 0110 1100 : C=STK
-- 0111 1100 : WPTOG (HEXPAK)
-- 1000 1100 : GOKEYS
-- 1001 1100 : DA=C
-- 1010 1100 : CLRREGS
-- 1011 1100 : DATA=C
-- 1100 1100 : CXISA
-- 1101 1100 : C=C!A
-- 1110 1100 : C=C&A
-- 1111 1100 : PFAD=C Peripheral address
--
-- 0000 1110 : C=DATA 
-- nnnn 1110 : C=REGn 
-- nnnn 1111 : RCR n (n:0..14) 14 = 0 uses scrambled n 
-- 1111 1111 : Display Compensation
--
-- Subroutine and long conditional jumps, two words opcodes
--   9   8   7   6   5   4   3   2   1   0       9   8   7   6   5   4   3   2   1   0
-- +---+---+---+---+---+---+---+---+---+---+   +---+---+---+---+---+---+---+---+---+---+
-- | l | l | l | l | l | l | l | l | 0 | 1 |   | h | h | h | h | h | h | h | h | t | t |
-- +---+---+---+---+---+---+---+---+---+---+   +---+---+---+---+---+---+---+---+---+---+
--
-- type (tt) :
-- 00 GOSUBNC subroutine call if carry clear
-- 01 GOSUBC  subroutine call if carry set
-- 10 GOLNC   long jump if carry clear
-- 11 GOLC    long jump call if carry set
--
-- Target address PC = hhll (absolute)
--
--   9   8   7   6   5   4   3   2   1   0
-- +---+---+---+---+---+---+---+---+---+---+
-- | o | o | o | o | o | f | f | f | 1 | 0 | Arithmetic
-- +---+---+---+---+---+---+---+---+---+---+
-- field type (fff):
-- 000  P : PQ..PQ (uses actual pointer)
-- 001  X :  2..0
-- 010 WP : PQ..0
-- 011  W : 13..0
-- 100 PQ :  Q..P, if Q > P then uses 13 as left position
-- 101 XS :  2..2
-- 110  M : 12..3
-- 111  S : 13..13
--
-- arithmetic operation on selected field
-- 00000 : A = 0
-- 00001 : B = 0
-- 00010 : C = 0
-- 00011 : AEXB
-- 00100 : B = A
-- 00101 : AEXC
-- 00110 : C = B
-- 00111 : BEXC
-- 01000 : A = C
-- 01001 : A = A + B
-- 01010 : A = A + C
-- 01011 : A = A + 1
-- 01100 : A = A - B
-- 01101 : A = A - 1
-- 01110 : A = A - C
-- 01111 : C = C + C
-- 10000 : C = A + C
-- 10001 : C = C + 1
-- 10010 : C = A - C
-- 10011 : C = C - 1
-- 10100 : C = 0 - C
-- 10101 : C = 0 - C - 1
-- 10110 : ?0#B
-- 10111 : ?0#C
-- 11000 : ?A<C
-- 11001 : ?A<B
-- 11010 : ?0#A
-- 11011 : ?A#C
-- 11100 : ASR
-- 11101 : BSR
-- 11110 : CSR
-- 11111 : ASL
-- 
-- Short jumps
--   9   8   7   6   5   4   3   2   1   0
-- +---+---+---+---+---+---+---+---+---+---+
-- |   |   |   |   |   |   |   |   | 1 | 1 | 
-- +---+---+---+---+---+---+---+---+---+---+
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- Masks part of a register given the mask
--

entity nut_mask is
   port(a_in            : in std_logic_vector(55 downto 0);
		mask_in         : in std_logic_vector(13 downto 0);
		ignore_mask_in  : in std_logic;
        q_out           : out std_logic_vector(55 downto 0)
    );
end nut_mask;

architecture logic of nut_mask is
begin
    q_out( 3 downto  0) <= a_in( 3 downto  0) when  mask_in(0) = '1' or ignore_mask_in = '1' else "0000";
    q_out( 7 downto  4) <= a_in( 7 downto  4) when  mask_in(1) = '1' or ignore_mask_in = '1' else "0000";	
    q_out(11 downto  8) <= a_in(11 downto  8) when  mask_in(2) = '1' or ignore_mask_in = '1' else "0000";
    q_out(15 downto 12) <= a_in(15 downto 12) when  mask_in(3) = '1' or ignore_mask_in = '1' else "0000";
    q_out(19 downto 16) <= a_in(19 downto 16) when  mask_in(4) = '1' or ignore_mask_in = '1' else "0000";
    q_out(23 downto 20) <= a_in(23 downto 20) when  mask_in(5) = '1' or ignore_mask_in = '1' else "0000";
    q_out(27 downto 24) <= a_in(27 downto 24) when  mask_in(6) = '1' or ignore_mask_in = '1' else "0000";
    q_out(31 downto 28) <= a_in(31 downto 28) when  mask_in(7) = '1' or ignore_mask_in = '1' else "0000";
    q_out(35 downto 32) <= a_in(35 downto 32) when  mask_in(8) = '1' or ignore_mask_in = '1' else "0000";
    q_out(39 downto 36) <= a_in(39 downto 36) when  mask_in(9) = '1' or ignore_mask_in = '1' else "0000";
    q_out(43 downto 40) <= a_in(43 downto 40) when mask_in(10) = '1' or ignore_mask_in = '1' else "0000";
    q_out(47 downto 44) <= a_in(47 downto 44) when mask_in(11) = '1' or ignore_mask_in = '1' else "0000";
    q_out(51 downto 48) <= a_in(51 downto 48) when mask_in(12) = '1' or ignore_mask_in = '1' else "0000";
    q_out(55 downto 52) <= a_in(55 downto 52) when mask_in(13) = '1' or ignore_mask_in = '1' else "0000";
    
end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- Circular right shift 
--

entity nut_rcr is
   port(a_in        : in std_logic_vector(55 downto 0);
		cnt_in      : in std_logic_vector(3 downto 0);
        q_out       : out std_logic_vector(55 downto 0)
    );
end nut_rcr;

architecture logic of nut_rcr is
    signal icnt : integer range 0 to 15;
begin
    icnt <= to_integer(unsigned(cnt_in));
    q_out <= a_in( 3 downto  0) & a_in(55 downto  4) when icnt =  1 else
             a_in( 7 downto  0) & a_in(55 downto  8) when icnt =  2 else
             a_in(11 downto  0) & a_in(55 downto 12) when icnt =  3 else
             a_in(15 downto  0) & a_in(55 downto 16) when icnt =  4 else
             a_in(19 downto  0) & a_in(55 downto 20) when icnt =  5 else
             a_in(23 downto  0) & a_in(55 downto 24) when icnt =  6 else
             a_in(27 downto  0) & a_in(55 downto 28) when icnt =  7 else
             a_in(31 downto  0) & a_in(55 downto 32) when icnt =  8 else
             a_in(35 downto  0) & a_in(55 downto 36) when icnt =  9 else
             a_in(39 downto  0) & a_in(55 downto 40) when icnt = 10 else
             a_in(43 downto  0) & a_in(55 downto 44) when icnt = 11 else
             a_in(47 downto  0) & a_in(55 downto 48) when icnt = 12 else
             a_in(51 downto  0) & a_in(55 downto 52) when icnt = 13 else
             a_in(55 downto  0);
    
end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nut_addsub1 is
    port(
        a_in : in std_logic;
        b_in : in std_logic;
        c_in : in std_logic;
        as_in : in std_logic;
        q_out : out std_logic;
        qc_out : out std_logic
    );
end nut_addsub1;

--
-- 1 Bit Decimal/Binary subtracter with carry in/carry out
--

architecture logic of nut_addsub1 is
    signal pq: std_logic;
begin
    pq <= a_in xor b_in;
    q_out <= pq xor c_in;
    qc_out <= (( (not a_in) and b_in ) or ( (not pq) and c_in)) when (as_in = '1') -- sub
         else (( a_in and b_in ) or (pq and c_in)); -- add
end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nut_addsub4 is
    port(
        a_in : in std_logic_vector(3 downto 0);
        b_in : in std_logic_vector(3 downto 0);
        c_in : in std_logic;
        as_in : in std_logic;
        dec_in : in std_logic;
        q_out : out std_logic_vector(3 downto 0);
        qc_out : out std_logic
    );
end nut_addsub4;

architecture logic of nut_addsub4 is
component nut_addsub1 is
    port(
        a_in : in std_logic;
        b_in : in std_logic;
        c_in : in std_logic;
        as_in : in std_logic;
        q_out : out std_logic;
	    qc_out : out std_logic
    );
end component nut_addsub1;

    signal part_q: std_logic_vector(3 downto 0);
    signal part_qc: std_logic_vector(3 downto 0);
    signal da_q : std_logic_vector(3 downto 0);
    signal da_qc : std_logic_vector(3 downto 0);
    signal final_qc : std_logic;
begin

-- A+B

as0 : nut_addsub1 port map (a_in => a_in(0), b_in => b_in(0), c_in =>       c_in, as_in => as_in, q_out => part_q(0), qc_out => part_qc(0));
as1 : nut_addsub1 port map (a_in => a_in(1), b_in => b_in(1), c_in => part_qc(0), as_in => as_in, q_out => part_q(1), qc_out => part_qc(1));
as2 : nut_addsub1 port map (a_in => a_in(2), b_in => b_in(2), c_in => part_qc(1), as_in => as_in, q_out => part_q(2), qc_out => part_qc(2));
as3 : nut_addsub1 port map (a_in => a_in(3), b_in => b_in(3), c_in => part_qc(2), as_in => as_in, q_out => part_q(3), qc_out => part_qc(3));

-- Decimal adjust

    da_q(0) <= part_q(0);
    da_qc(0) <= '0';

da1 : nut_addsub1 port map (a_in => part_q(1), b_in => '1', c_in => da_qc(0), as_in => as_in, q_out => da_q(1), qc_out => da_qc(1));
da2 : nut_addsub1 port map (a_in => part_q(2), b_in => '1', c_in => da_qc(1), as_in => as_in, q_out => da_q(2), qc_out => da_qc(2));
da3 : nut_addsub1 port map (a_in => part_q(3), b_in => '0', c_in => da_qc(2), as_in => as_in, q_out => da_q(3), qc_out => da_qc(3));

-- Final mux

    final_qc <= (dec_in and (not as_in) and part_q(3) and (part_q(1) or part_q(2))) or part_qc(3);
    qc_out <= final_qc;
    q_out <= da_q when ((final_qc and dec_in) = '1') else part_q;

end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 56 bit binary/decimal adder/subtracter/comparer
--  carry in, carry out are taken, set using the position
-- zero and greater than results are provided too

entity nut_addsub56 is 
port (
	a_in        : in std_logic_vector(55 downto 0);
	b_in        : in std_logic_vector(55 downto 0);
    c_in        : in std_logic;
    as_in       : in std_logic;
    dec_in      : in std_logic;
    c_in_pos_in : in std_logic_vector(3 downto 0);
	q_out       : out std_logic_vector(55 downto 0);
    qc_out_pos_in : in std_logic_vector(3 downto 0);
	qc_out      : out std_logic;
    a_eq_b_o    : out std_logic;
    a_neq_b_o   : out std_logic;
    a_gt_b_o    : out std_logic 
    );
end nut_addsub56;

architecture logic of nut_addsub56 is

component nut_addsub4 is
    port(
        a_in    : in std_logic_vector(3 downto 0);
        b_in    : in std_logic_vector(3 downto 0);
        c_in    : in std_logic;
        as_in   : in std_logic;
        dec_in  : in std_logic;
        q_out   : out std_logic_vector(3 downto 0);
	    qc_out  : out std_logic
    );
end component nut_addsub4;

    signal c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13 : std_logic; -- comparison per nibble
    signal s0_c, s1_c, s2_c, s3_c, s4_c, s5_c, s6_c, s7_c, s8_c, s9_c, sa_c, sb_c, sc_c, sd_c : std_logic; -- last stage carry
    signal f0_c, f1_c, f2_c, f3_c, f4_c, f5_c, f6_c, f7_c, f8_c, f9_c, fa_c, fb_c, fc_c, fd_c : std_logic; -- forced carry or last stage carry
    signal t1_c, t2_c, t3_c, t4_c, t5_c, t6_c, t7_c, t8_c, t9_c, ta_c, tb_c, tc_c, td_c : std_logic; -- forced carry
    signal qc : std_logic; -- carry
begin
    f0_c <= c_in when (c_in_pos_in = "0000") else '0';
    t1_c <= c_in when (c_in_pos_in = "0001") else '0';
    t2_c <= c_in when (c_in_pos_in = "0010") else '0';
    t3_c <= c_in when (c_in_pos_in = "0011") else '0';
    t4_c <= c_in when (c_in_pos_in = "0100") else '0';
    t5_c <= c_in when (c_in_pos_in = "0101") else '0';
    t6_c <= c_in when (c_in_pos_in = "0110") else '0';
    t7_c <= c_in when (c_in_pos_in = "0111") else '0';
    t8_c <= c_in when (c_in_pos_in = "1000") else '0';
    t9_c <= c_in when (c_in_pos_in = "1001") else '0';
    ta_c <= c_in when (c_in_pos_in = "1010") else '0';
    tb_c <= c_in when (c_in_pos_in = "1011") else '0';
    tc_c <= c_in when (c_in_pos_in = "1100") else '0';
    td_c <= c_in when (c_in_pos_in = "1101") else '0';
    
    f1_c <= s0_c or t1_c;
    f2_c <= s1_c or t2_c;
    f3_c <= s2_c or t3_c;
    f4_c <= s3_c or t4_c;
    f5_c <= s4_c or t5_c;
    f6_c <= s5_c or t6_c;
    f7_c <= s6_c or t7_c;
    f8_c <= s7_c or t8_c;
    f9_c <= s8_c or t9_c;
    fa_c <= s9_c or ta_c;
    fb_c <= sa_c or tb_c;
    fc_c <= sb_c or tc_c;
    fd_c <= sc_c or td_c;

    s0 : nut_addsub4 port map (a_in => a_in( 3 downto  0), b_in => b_in( 3 downto  0), c_in => f0_c, as_in => as_in, dec_in => dec_in, q_out => q_out( 3 downto  0), qc_out => s0_c);
    s1 : nut_addsub4 port map (a_in => a_in( 7 downto  4), b_in => b_in( 7 downto  4), c_in => f1_c, as_in => as_in, dec_in => dec_in, q_out => q_out( 7 downto  4), qc_out => s1_c);
    s2 : nut_addsub4 port map (a_in => a_in(11 downto  8), b_in => b_in(11 downto  8), c_in => f2_c, as_in => as_in, dec_in => dec_in, q_out => q_out(11 downto  8), qc_out => s2_c);
    s3 : nut_addsub4 port map (a_in => a_in(15 downto 12), b_in => b_in(15 downto 12), c_in => f3_c, as_in => as_in, dec_in => dec_in, q_out => q_out(15 downto 12), qc_out => s3_c);
    s4 : nut_addsub4 port map (a_in => a_in(19 downto 16), b_in => b_in(19 downto 16), c_in => f4_c, as_in => as_in, dec_in => dec_in, q_out => q_out(19 downto 16), qc_out => s4_c);
    s5 : nut_addsub4 port map (a_in => a_in(23 downto 20), b_in => b_in(23 downto 20), c_in => f5_c, as_in => as_in, dec_in => dec_in, q_out => q_out(23 downto 20), qc_out => s5_c);
    s6 : nut_addsub4 port map (a_in => a_in(27 downto 24), b_in => b_in(27 downto 24), c_in => f6_c, as_in => as_in, dec_in => dec_in, q_out => q_out(27 downto 24), qc_out => s6_c);
    s7 : nut_addsub4 port map (a_in => a_in(31 downto 28), b_in => b_in(31 downto 28), c_in => f7_c, as_in => as_in, dec_in => dec_in, q_out => q_out(31 downto 28), qc_out => s7_c);
    s8 : nut_addsub4 port map (a_in => a_in(35 downto 32), b_in => b_in(35 downto 32), c_in => f8_c, as_in => as_in, dec_in => dec_in, q_out => q_out(35 downto 32), qc_out => s8_c);
    s9 : nut_addsub4 port map (a_in => a_in(39 downto 36), b_in => b_in(39 downto 36), c_in => f9_c, as_in => as_in, dec_in => dec_in, q_out => q_out(39 downto 36), qc_out => s9_c);
    sa : nut_addsub4 port map (a_in => a_in(43 downto 40), b_in => b_in(43 downto 40), c_in => fa_c, as_in => as_in, dec_in => dec_in, q_out => q_out(43 downto 40), qc_out => sa_c);
    sb : nut_addsub4 port map (a_in => a_in(47 downto 44), b_in => b_in(47 downto 44), c_in => fb_c, as_in => as_in, dec_in => dec_in, q_out => q_out(47 downto 44), qc_out => sb_c);
    sc : nut_addsub4 port map (a_in => a_in(51 downto 48), b_in => b_in(51 downto 48), c_in => fc_c, as_in => as_in, dec_in => dec_in, q_out => q_out(51 downto 48), qc_out => sc_c);
    sd : nut_addsub4 port map (a_in => a_in(55 downto 52), b_in => b_in(55 downto 52), c_in => fd_c, as_in => as_in, dec_in => dec_in, q_out => q_out(55 downto 52), qc_out => sd_c);
 
    -- select output carry

    qc     <= s0_c when (qc_out_pos_in = "0000") else 
              s1_c when (qc_out_pos_in = "0001") else 
              s2_c when (qc_out_pos_in = "0010") else 
              s3_c when (qc_out_pos_in = "0011") else 
              s4_c when (qc_out_pos_in = "0100") else 
              s5_c when (qc_out_pos_in = "0101") else 
              s6_c when (qc_out_pos_in = "0110") else 
              s7_c when (qc_out_pos_in = "0111") else 
              s8_c when (qc_out_pos_in = "1000") else 
              s9_c when (qc_out_pos_in = "1001") else 
              sa_c when (qc_out_pos_in = "1010") else 
              sb_c when (qc_out_pos_in = "1011") else 
              sc_c when (qc_out_pos_in = "1100") else 
              sd_c when (qc_out_pos_in = "1101") else '0';
    
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
    a_gt_b_o <= not qc;
    qc_out <= qc;
              
end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nut_field_decoder is
    port (
        field_in       : in std_logic_vector(2 downto 0); -- 3 left most bits
        p_in           : in std_logic_vector(3 downto 0); -- register P
        ptr_in         : in std_logic_vector(3 downto 0); --  current pointer
        q_in           : in std_logic_vector(3 downto 0); --  register Q
        start_o        : out std_logic_vector(3 downto 0); -- 
        end_o          : out std_logic_vector(3 downto 0)  -- 
    );
end nut_field_decoder;

architecture logic of nut_field_decoder is
    signal pi : integer range 0 to 15;
    signal qi : integer range 0 to 15;
    signal limit : std_logic_vector(3 downto 0);
begin

    pi <= to_integer(unsigned(p_in));
    qi <= to_integer(unsigned(q_in));

    process (field_in, p_in, ptr_in, q_in, pi, qi, limit)
        begin
            if (qi < pi) then
                limit <= "1101";
            else
                limit <= q_in;
            end if;
        
            case(field_in) is
                when "000" => start_o <= ptr_in; end_o <= ptr_in; -- Pointer field
                when "001" => start_o <= "0000"; end_o <= "0010"; -- X
                when "010" => start_o <= "0000"; end_o <= ptr_in; -- WP
                when "011" => start_o <= "0000"; end_o <= "1101"; -- W
                when "100" => start_o <= p_in;   end_o <= limit; -- PQ
                when "101" => start_o <= "0010"; end_o <= "0010"; -- XS
                when "110" => start_o <= "0011"; end_o <= "1100"; -- M
                when "111" => start_o <= "1101"; end_o <= "1101"; -- S
                when others =>
                    start_o <= ptr_in; end_o <= ptr_in;
            end case;
    end process;

end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- Top entity Fullnut processor
-- The display unit is not a part of this entity !
-- A set of registers (for display) is exported
--
entity nut_Main is
    port(
        clk_in          : in std_logic;                     -- sync clock
        reset_in        : in std_logic;                     -- asserted high reset
        use_trace_in    : in std_logic;						-- trace enable
		key_in          : in std_logic_vector(7 downto 0);  -- last pressed key
        key_scan_o      : out std_logic;                    -- start keyboard scan
        key_ack_o       : out std_logic;                    -- acknowledge keyboard scan
        key_flag_in     : in std_logic;                     -- keyboard scanned flag (S15)
        flags_in        : in std_logic_vector( 7 downto 0); -- input flags
        flags_o         : out std_logic_vector( 7 downto 0);-- output flags
        reg_data_in     : in std_logic_vector(55 downto 0); -- data from Module
        reg_data_o      : out std_logic_vector(55 downto 0);
        reg_addr_o      : out std_logic_vector(11 downto 0);
        reg_perif_o     : out std_logic_vector(7 downto 0);
        reg_we_o        : out std_logic;                    -- Register or peripheral write strobe
        reg_rd_o        : out std_logic                     -- Register or peripheral read strobe
    );
end nut_Main;
    
architecture logic of nut_Main is
    component nut_addsub56 is
        port (
            a_in        : in std_logic_vector(55 downto 0);
            b_in        : in std_logic_vector(55 downto 0);
            c_in        : in std_logic;
            as_in       : in std_logic;
            dec_in      : in std_logic;
            c_in_pos_in : in std_logic_vector(3 downto 0);
            q_out       : out std_logic_vector(55 downto 0);
            qc_out_pos_in : in std_logic_vector(3 downto 0);
            qc_out      : out std_logic;
            a_eq_b_o    : out std_logic;
            a_neq_b_o   : out std_logic;
            a_gt_b_o    : out std_logic 
        );
    end component nut_addsub56;
    
    component nut_mask is
        port(
            a_in            : in std_logic_vector(55 downto 0);
            mask_in         : in std_logic_vector(13 downto 0);
            ignore_mask_in  : in std_logic;
            q_out           : out std_logic_vector(55 downto 0)
        );
    end component nut_mask;
    
    component nut_rcr is
        port(
            a_in        : in std_logic_vector(55 downto 0);
            cnt_in      : in std_logic_vector(3 downto 0);
            q_out       : out std_logic_vector(55 downto 0)
        );
    end component nut_rcr;
    
    component nut_regs is
        port(
            clk_in      : in std_logic;
            addr_in     : in std_logic_vector(5 downto 0);
            data_in     : in std_logic_vector(55 downto 0);
            wr_in       : in std_logic;
            data_o      : out std_logic_vector(55 downto 0)
        );
    end component nut_regs;
    
    component nut_calcmask is
        port(
            start_in    : in std_logic_vector(3 downto 0);
            stop_in     : in std_logic_vector(3 downto 0);
            mask_o      : out std_logic_vector(13 downto 0)
        );
    end component nut_calcmask;

	component nut_compare is
        port(
            a_in        : in std_logic_vector(55 downto 0);
            b_in        : in std_logic_vector(55 downto 0);
            a_eq_b_o    : out std_logic;
            a_neq_b_o   : out std_logic;
            a_gt_b_o    : out std_logic
        );
	end component nut_compare;

    component ROM41C is
        port(
            OutClock    : in std_logic;
            OutClockEn  : in std_logic;
            Reset       : in std_logic;
            Address     : in std_logic_vector(13 downto 0);
            Q           : out std_logic_vector(9 downto 0)
        );
    end component ROM41C;

    component nut_field_decoder is
        port (
            field_in    : in std_logic_vector(2 downto 0); -- 3 left most bits
            p_in        : in std_logic_vector(3 downto 0); -- register P
            ptr_in      : in std_logic_vector(3 downto 0); --  current pointer
            q_in        : in std_logic_vector(3 downto 0); --  register Q
            start_o     : out std_logic_vector(3 downto 0); -- 
            end_o       : out std_logic_vector(3 downto 0)  -- 
        );
    end component nut_field_decoder;
    
    component nut_disassembler is
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
    end component nut_disassembler;
    
    component nut_MemModule is
        port(
            clk_in      : in std_logic;                      -- sync clock
            addr_in     : in std_logic_vector(8 downto 0);  -- a
            we_in       : in std_logic;                      -- write strobe
            data_o      : out std_logic_vector(55 downto 0); -- 
            data_in     : in std_logic_vector(55 downto 0)
        );
    end component nut_MemModule;
    type alu_op_t is ( -- ALU Opcodes
        ALU_NONE,
        ALU_ADD,        -- dst = dst + op1
        ALU_SUB,        -- dst = dst - op1
        ALU_EQ,         -- carry = op1 == dst
        ALU_NEQ,	    -- carry = op1 != dst
        ALU_LT,         -- carry = op1 < op2
        ALU_RCR,        -- dst = circular right shift op1 only used in C
        ALU_LSL,        -- dst = left shift op1
        ALU_LSR,        -- dst = right shift op1
        ALU_AND,        -- dst = op1 & op2
        ALU_OR,         -- dst = op1 or op2
        ALU_TST,        -- carry = op1 and op2
        ALU_TFR,        -- dst = op1
        ALU_EX          -- dst <> op1
    );

    type state_t is (
        ST_INIT, 		   
        ST_FETCH_OP0,	   
        ST_FETCH_OP1,	   
        ST_FETCH_OP2,	   
        --ST_HW_TRACE_START,  
        --ST_HW_TRACE_PREPARE,
        --ST_HW_TRACE_READ,   
        --ST_HW_TRACE_OUTPUT, 
        ST_DECODE,          
        ST_FETCH_CXISA,	   
        ST_EXE_NORM,		   
        ST_EXE_JUMP
    );
    type dst_t is (
        DST_NONE,
        DST_A,	
        DST_B,	
        DST_C,
        DST_ABC,
        DST_M,	
        DST_N,   
        DST_DATA,   
        DST_DA,  
        DST_G,    
        DST_PC,
        DST_STK,       
        DST_ST,
        DST_PT,
        DST_FO,
        DST_PRF
    );
    type op1_t is ( -- first alu operand and exchange destination
        OP1_A,	
        OP1_B,	
        OP1_C,	
        OP1_M,	
        OP1_N,   
        OP1_DATA,
        --OP1_DA,  
        OP1_P,   
        OP1_G,   
        OP1_PC,
        OP1_STK,
        OP1_ST,
        OP1_PT,
        OP1_FO,
        OP1_0,   
        OP1_9,
        OP1_CNT,	
        OP1_KEY,
        OP1_LV -- constant from opcode        
    );
    type op2_t is ( -- second alu operand
        OP2_A,	
        OP2_B,	
        OP2_C,
        OP2_0,   
        OP2_9,
        OP2_FO,
        OP2_LV,
        OP2_Q
    );
    -- Microcode signals
    signal op_alu_op            : alu_op_t;
    signal op_write_carry       : std_logic;
    signal op_src_reg_1         : op1_t;
    signal op_src_reg_2         : op2_t;
    signal op_dest_reg          : dst_t;
    signal op_shf_a             : integer range 0 to 15;
    signal op_shf_b             : integer range 0 to 15;
    signal op_lvalue            : std_logic_vector(15 downto 0);
    signal op_field_right       : integer range 0 to 15;
    signal op_field_dec_right   : std_logic_vector(3 downto 0);
    signal op_field_left        : integer range 0 to 15;
    signal op_field_dec_left    : std_logic_vector(3 downto 0);
    signal op_cxisa             : std_logic;
    signal op_reset_kb          : std_logic;
    signal op_test_kb           : std_logic;
    signal op_disp_toggle       : std_logic;
    signal op_disp_off          : std_logic;
    signal op_pwr_off           : std_logic;
    signal op_jump              : std_logic;
    signal op_nop               : std_logic;
    signal op_if_c              : std_logic;
    signal op_if_nc             : std_logic;
    signal op_pop               : std_logic;
    signal op_push              : std_logic;
    signal op_sethex            : std_logic;
    signal op_setdec            : std_logic;
    signal op_test_ext          : std_logic;
    signal op_key_ack           : std_logic;
    signal op_force_hex         : std_logic;
    signal op_dec_ptr           : std_logic;
    signal op_no_src_mask       : std_logic; -- set when source mask is not used. CGEX,C=G,G=C,C=KEYS
    signal op_set_carry_early   : std_logic;
    signal op_selp              : integer range 0 to 1;
    signal op_selq              : integer range 0 to 1;
    -- Register set 
    signal RA                   : std_logic_vector(55 downto 0) := X"00000000000000";
    signal RB                   : std_logic_vector(55 downto 0) := X"00000000000000";
    signal RC                   : std_logic_vector(55 downto 0) := X"00000000000000";
    signal RM                   : std_logic_vector(55 downto 0) := X"00000000000000";
    signal RN                   : std_logic_vector(55 downto 0) := X"00000000000000";
    signal RG                   : std_logic_vector( 7 downto 0) := X"00";
    signal RP                   : std_logic_vector( 3 downto 0) := "0000";
    signal RQ                   : std_logic_vector( 3 downto 0) := "0000";
    signal PT                   : std_logic_vector( 3 downto 0) := "0000"; -- actual selected pointer value
    signal iPT                  : integer range 0 to 15;                   -- actual selected pointer value as integer
    signal iPTP1                : integer range 0 to 15;                   -- actual selected pointer value as integer plus 1
    signal RDA                  : std_logic_vector(11 downto 0) := X"000"; -- memory register address 12 bits
    signal RPC                  : std_logic_vector(15 downto 0) := X"0000"; -- Program counter
    signal RST                  : std_logic_vector(15 downto 0) := X"0000"; -- Status bits
    signal RSTK0                : std_logic_vector(15 downto 0) := X"0000"; -- stack
    signal RSTK1                : std_logic_vector(15 downto 0) := X"0000";
    signal RSTK2                : std_logic_vector(15 downto 0) := X"0000";
    signal RSTK3                : std_logic_vector(15 downto 0) := X"0000";
    signal RFO                  : std_logic_vector( 7 downto 0) := X"00"; -- output flags
    signal RFI                  : std_logic_vector( 7 downto 0) := X"00"; -- input flags
    signal RPERIF               : std_logic_vector( 7 downto 0) := X"00"; -- Peripheral address
    signal RCY                  : std_logic := '0'; -- carry
    signal PQ                   : integer range 0 to 1 := 0; -- selected pointer
    signal DECIMAL              : std_logic := '0'; -- Decimal or Hex mode
    signal DISPON               : std_logic := '0'; -- Display ON/OFF flag used by DISP and PWROFF
    -- mask generation
    signal lmask		        : std_logic_vector(13 downto 0);
	signal rmask		        : std_logic_vector(13 downto 0);
    signal mask                 : std_logic_vector(13 downto 0);
    
    signal base_value           : std_logic_vector(55 downto 0);
    signal result_to_op1        : std_logic_vector(55 downto 0);
    signal reg_path_a           : std_logic_vector(55 downto 0);
    signal reg_path_b           : std_logic_vector(55 downto 0);
    
    signal reg_path_a_masked    : std_logic_vector(55 downto 0);
    signal reg_path_b_masked    : std_logic_vector(55 downto 0);
    signal shf_reg_path_a       : std_logic_vector(55 downto 0); -- shift right path b digit count
    signal shf_reg_path_b       : std_logic_vector(55 downto 0); -- shift right path b digit count
    
    signal qadd56               : std_logic_vector(55 downto 0);
    signal qadd56c              : std_logic;
    signal cmp_eq               : std_logic;
    signal cmp_neq              : std_logic;
    signal cmp_gt               : std_logic; 
    signal alu_carry_out        : std_logic; 
    signal result_to_dst        : std_logic_vector(55 downto 0);
    signal data_from_ram_bank   : std_logic_vector(55 downto 0);
    -- Extra signals
    signal rom_addr             : std_logic_vector(15 downto 0); -- rom address, either PC or C from CXISA
    signal nut_state            : state_t := ST_INIT;
    signal target_pc            : std_logic_vector(15 downto 0) := X"0000";
    signal short_jump_ofs       : std_logic_vector(15 downto 0);
    signal rom_bank_0_data      : std_logic_vector(9 downto 0); -- data at rom_addr
    signal rom_opcode           : std_logic_vector(9 downto 0); -- opcode at rom_addr
    signal opcode               : std_logic_vector(9 downto 0); -- fetched opcode
    signal second_opcode        : std_logic_vector(9 downto 0); -- fetched second opcode
    signal op_is_sub            : std_logic; -- 0 when ADD, 1 when SUB or compare
    signal last_carry           : std_logic := '0';
    signal last_was_gosub       : std_logic := '0'; -- set when last instruction was gosub helpts to check for empty modules
    signal seq_src_reg_1        : op1_t;
    signal seq_src_reg_2        : op2_t;
    signal seq_dest_reg         : dst_t;
    signal seq_alu_op           : alu_op_t;
    signal seq_write_dst        : integer range 0 to 1 := 0;--
    signal seq_write_op1        : integer range 0 to 1 := 0;--
    signal seq_field_left       : integer range 0 to 15 := 0; -- left most field position
    signal seq_field_right      : integer range 0 to 15 := 0; -- right most field position
    signal sv_seq_field_left    : std_logic_vector(3 downto 0); -- left most field position
    signal sv_seq_field_right   : std_logic_vector(3 downto 0); -- left most field position
    signal seq_shf_a            : integer range 0 to 13 := 0; -- shift right path a digit count
    signal seq_shf_b            : integer range 0 to 13 := 0; -- shift right path b digit count
    signal seq_push             : std_logic;
    signal seq_pop              : std_logic;
    
    signal inut_state           : integer range 0 to 15;
    type unscrambled_t          is array (natural range <>) of integer range 0 to 15;
    constant unscrambled_rom    : unscrambled_t := (3, 4, 5, 10, 8, 6, 11, 15, 2, 9, 7, 13, 1, 12, 0, 14);
    constant unscrambled_rom_rcr: unscrambled_t := (3, 4, 5, 10, 8, 6, 11, 1, 2, 9, 7, 13, 1, 12, 0, 0);
    constant rev_pt_rom         : unscrambled_t := (0, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0);
    signal unscrambled          : integer range 0 to 15 ;-- unscrambled version of the high 4 bits of the opcode
    signal unscrambled_rcr      : integer range 0 to 15 ;-- unscrambled version of the high 4 bits of the opcode
    signal opcode_pc            : std_logic_vector(15 downto 0) := X"0000";
    signal ram_bank_we          : std_logic;
    signal seq_DA               : std_logic_vector(11 downto 0) := X"000"; -- latched RAM address
    signal sanitized_result     : std_logic_vector(3 downto 0); -- 
    signal add_sub_decimal      : std_logic; -- arithmetic mode used by this opcode
    signal bit_value            : std_logic_vector(15 downto 0); -- used to set/test flags
    signal bit_value_n          : std_logic_vector(15 downto 0); -- used to clr flags
    signal tst_result           : std_logic; -- used to test flags
    signal sv_seq_shf_a         : std_logic_vector(3 downto 0); -- shift count for RCR
    signal sv_seq_shf_b         : std_logic_vector(3 downto 0); -- shift count for RCR
    signal decoded_opcode_ready : std_logic;
begin
    -- IO Ports
    reg_data_o <= reg_path_a;
    reg_addr_o <= seq_DA;
    --reg_we_o <= ram_bank_we;
    reg_perif_o <= RPERIF;
    reg_we_o <= '1' when (seq_write_dst = 1) and (seq_dest_reg = DST_DATA) else '0';
    reg_rd_o <= '1' when (nut_state = ST_EXE_NORM) and (seq_src_reg_1 = OP1_DATA) else '0'; -- Memory or peripheral read
    -- Useful conversions
    PT <= RP when (PQ = 0) else RQ;
    iPT <= to_integer(unsigned(PT));
    iPTP1 <= 0 when iPT = 13 else (to_integer(unsigned(PT)) + 1);
    sv_seq_field_left <= std_logic_vector(to_unsigned(seq_field_left, 4));
    sv_seq_field_right <= std_logic_vector(to_unsigned(seq_field_right, 4));
    inut_state <= 0 when nut_state = ST_INIT else
                  1 when nut_state = ST_FETCH_OP0 else
                  2 when nut_state = ST_FETCH_OP1 else
                  3 when nut_state = ST_FETCH_OP2 else
                  4 when nut_state = ST_DECODE else
                  5 when nut_state = ST_FETCH_CXISA else
                  6 when nut_state = ST_EXE_NORM else
                  7 when nut_state = ST_EXE_JUMP else 15;

    -- get operands
    
    unscrambled <= unscrambled_rom(to_integer(unsigned(opcode(9 downto 6))));
    unscrambled_rcr <= unscrambled_rom_rcr(to_integer(unsigned(opcode(9 downto 6))));
    
    -- mask generation
    PROCESS (seq_field_right)
        BEGIN
            case seq_field_right is
                when  0 => lmask <= "11111111111111";
                when  1 => lmask <= "11111111111110";
                when  2 => lmask <= "11111111111100";
                when  3 => lmask <= "11111111111000";
                when  4 => lmask <= "11111111110000";
                when  5 => lmask <= "11111111100000";
                when  6 => lmask <= "11111111000000";
                when  7 => lmask <= "11111110000000";
                when  8 => lmask <= "11111100000000";
                when  9 => lmask <= "11111000000000";
                when 10 => lmask <= "11110000000000";
                when 11 => lmask <= "11100000000000";
                when 12 => lmask <= "11000000000000";
                when 13 => lmask <= "10000000000000";
                when others => lmask <= "10000000000000";
            end case;
        END PROCESS;
    PROCESS (seq_field_left)
        BEGIN
            case seq_field_left is
                when  0 => rmask <= "00000000000001";
                when  1 => rmask <= "00000000000011";
                when  2 => rmask <= "00000000000111";
                when  3 => rmask <= "00000000001111";
                when  4 => rmask <= "00000000011111";
                when  5 => rmask <= "00000000111111";
                when  6 => rmask <= "00000001111111";
                when  7 => rmask <= "00000011111111";
                when  8 => rmask <= "00000111111111";
                when  9 => rmask <= "00001111111111";
                when 10 => rmask <= "00011111111111";
                when 11 => rmask <= "00111111111111";
                when 12 => rmask <= "01111111111111";
                when 13 => rmask <= "11111111111111";
                when others => rmask <= "11111111111111";
            end case; 
        END PROCESS;
        
    mask <= lmask and rmask; 
    
    bit_value <= X"0001" when unscrambled =  0 else
                 X"0002" when unscrambled =  1 else
                 X"0004" when unscrambled =  2 else
                 X"0008" when unscrambled =  3 else
                 X"0010" when unscrambled =  4 else
                 X"0020" when unscrambled =  5 else
                 X"0040" when unscrambled =  6 else
                 X"0080" when unscrambled =  7 else
                 X"0100" when unscrambled =  8 else
                 X"0200" when unscrambled =  9 else
                 X"0400" when unscrambled = 10 else
                 X"0800" when unscrambled = 11 else
                 X"1000" when unscrambled = 12 else
                 X"2000" when unscrambled = 13 else
                 X"4000" when unscrambled = 14 else X"0000"; -- flag 15 cannot be accessed
    bit_value_n <= not bit_value;
    
    base_value <= X"99999999999999" when DECIMAL = '1' else 
                  X"FFFFFFFFFFFFFF";
    -- first operand mux
    reg_path_a <= RA                        when (seq_src_reg_1 = OP1_A  ) else
                  RB                        when (seq_src_reg_1 = OP1_B  ) else
                  RC                        when (seq_src_reg_1 = OP1_C  ) else
                  RM                        when (seq_src_reg_1 = OP1_M  ) else
                  RN                        when (seq_src_reg_1 = OP1_N  ) else
                  data_from_ram_bank        when (seq_src_reg_1 = OP1_DATA) and (RPERIF = X"00") else -- memory
                  reg_data_in               when (seq_src_reg_1 = OP1_DATA) and (RPERIF /= X"00") else -- peripherals
                  X"0000000000000" & RP     when (seq_src_reg_1 = OP1_P  ) else
                  X"000000000000" & RG      when (seq_src_reg_1 = OP1_G  ) else
                  X"0000000000" & RPC       when (seq_src_reg_1 = OP1_PC ) else
                  X"0000000000" & RSTK0     when (seq_src_reg_1 = OP1_STK) else
                  X"0000000000" & RST       when (seq_src_reg_1 = OP1_ST ) else
                  PT & PT & PT & PT & PT & PT & PT & 
                  PT & PT & PT & PT & PT & PT & PT
                                            when (seq_src_reg_1 = OP1_PT ) else
                  X"000000000000" & RFO     when (seq_src_reg_1 = OP1_FO ) else
                  base_value                when (seq_src_reg_1 = OP1_9  ) else
                  X"00000000000" & "00" & second_opcode
                                            when (seq_src_reg_1 = OP1_CNT) else -- ldi & cxisa
                  X"000000000000" & key_in  when (seq_src_reg_1 = OP1_KEY) else -- needs shift to be placed on right field of C
                  X"0000000000" & op_lvalue when (seq_src_reg_1 = OP1_LV ) else -- opcode constant for P and flags
                  X"00000000000000"; -- OP1_0


    -- second operand mux
    reg_path_b <= RA                        when (seq_src_reg_2 = OP2_A  ) else
                  RB                        when (seq_src_reg_2 = OP2_B  ) else
                  RC                        when (seq_src_reg_2 = OP2_C  ) else
                  base_value                when (seq_src_reg_2 = OP2_9  ) else
                  X"000000000000" & RFO     when (seq_src_reg_2 = OP2_FO ) else -- output flags
                  X"0000000000" & op_lvalue when (seq_src_reg_2 = OP2_LV ) else -- for test, set and clear or flags
                  X"0000000000000" & RQ     when (seq_src_reg_2 = OP2_Q  ) else
                  X"00000000000000"; -- OP2_0
                  
    ml : nut_mask
        port map(
            a_in    => reg_path_a,
            mask_in => mask,
            ignore_mask_in => op_no_src_mask,
            q_out   => reg_path_a_masked
            );
    mr : nut_mask
    	port map(
            a_in    => reg_path_b,
            mask_in => mask, 
            ignore_mask_in => op_no_src_mask,
            q_out   => reg_path_b_masked
            );

    -- Circular right shifter for op1
    sv_seq_shf_a <= std_logic_vector(to_unsigned(seq_shf_a, 4));
    rcr_a : nut_rcr
    	port map(
            a_in   => reg_path_a_masked,
            cnt_in => sv_seq_shf_a, 
            q_out  => shf_reg_path_a
            );

    -- Circular right shifter for op2     
    sv_seq_shf_b <= std_logic_vector(to_unsigned(seq_shf_b, 4));
    rcr_b : nut_rcr
    	port map(
            a_in   => reg_path_b_masked,
            cnt_in => sv_seq_shf_b, 
            q_out  => shf_reg_path_b
            );   

    -- adder/subtracter/comparator    
    
    op_is_sub <= '0' when (seq_alu_op = ALU_ADD) else '1';
    
    add_sub_decimal <= '0' when (DECIMAL = '0') or (op_force_hex = '1') else '1';
    
    add56 : nut_addsub56
        port map(
            a_in            => reg_path_a_masked,
            b_in            => reg_path_b_masked,
            c_in            => op_set_carry_early,
            as_in           => op_is_sub,
            dec_in          => add_sub_decimal,
            c_in_pos_in     => sv_seq_field_right,
            q_out           => qadd56,
            qc_out_pos_in   => sv_seq_field_left,
            qc_out          => qadd56c,
            a_eq_b_o        => cmp_eq,
            a_neq_b_o       => cmp_neq,
            a_gt_b_o        => cmp_gt
        );
        
    -- alu output and destination mux 
    result_to_dst <= qadd56                                  when ((seq_alu_op = ALU_ADD) or (seq_alu_op = ALU_SUB)) else -- ADD
			         shf_reg_path_a(55 downto 4) & "0000"    when (seq_alu_op = ALU_LSL) else -- LSL
                     "0000" & shf_reg_path_a(51 downto 0)    when (seq_alu_op = ALU_LSR) else -- LSR
                     reg_path_a_masked and reg_path_b_masked when (seq_alu_op = ALU_AND) else -- AND
                     reg_path_a_masked or  reg_path_b_masked when (seq_alu_op = ALU_OR)  else -- OR
                     shf_reg_path_a                          when (seq_alu_op = ALU_RCR) else -- RCR
                     shf_reg_path_a                          when (seq_alu_op = ALU_TFR) else -- TFR
                     shf_reg_path_a                          when (seq_alu_op = ALU_EX)  else -- EX
                     X"00000000000000";
    
    tst_result <= '1' when (reg_path_a_masked(15 downto 0) and reg_path_b_masked(15 downto 0)) /= X"0000" else '0';

    -- carry mux
    alu_carry_out <= qadd56c            when ((seq_alu_op = ALU_ADD) or (seq_alu_op = ALU_SUB)) else -- ADD
                     cmp_eq             when (seq_alu_op = ALU_EQ) else -- EQ
                     cmp_neq            when (seq_alu_op = ALU_NEQ) else -- NEQ
                     cmp_eq or cmp_gt   when (seq_alu_op = ALU_LT) else -- LT
                     tst_result         when (seq_alu_op = ALU_TST) else -- FLag test
                     '0';

    -- Exchange path (OP1 is the destination)
    result_to_op1 <= shf_reg_path_b; -- used for exchanges
    
    ram_bank_we <= '1' when (seq_write_dst = 1) and 
                            (seq_dest_reg = DST_DATA) and 
                            (RPERIF = X"00") and 
                            (to_integer(unsigned(seq_DA)) < 512) else '0';
    -- There are 2 opcodes to access the register file with different sources for the address
    -- C=DATA uses the full DA
    -- C=REGn uses the high 8 bits of DA plus the 4 bits provided by the opcode
    -- seq_DA is generated during decode to have a stable address during execute
    mem_bank : nut_MemModule
    port map(
        clk_in         => clk_in,
        addr_in        => seq_DA(8 downto 0), 
        we_in          => ram_bank_we,
        data_o         => data_from_ram_bank,
        data_in        => result_to_dst
    );
    
    -- sanitize the result for P and Q after add/sub
    sanitized_result <= X"0" when ( (seq_alu_op = ALU_ADD) and ((result_to_dst(3 downto 0) = X"E") or (result_to_dst(3 downto 0) = X"F"))) else
                        X"E" when ( (seq_alu_op = ALU_SUB) and ((result_to_dst(3 downto 0) = X"E") or (result_to_dst(3 downto 0) = X"F"))) else
                        result_to_dst(3 downto 0);
    -- ALU write back results
    process (clk_in, reset_in)
    begin
        if reset_in = '1' then
            RPC <= X"0000";
            RCY <= '0';
        elsif rising_edge(clk_in) then
            if (seq_write_dst = 1) then -- ALU result, transfers and exchanges
                if (seq_dest_reg = DST_A) or (seq_dest_reg = DST_ABC) then
                        if (mask(13) = '1') then RA(55 downto 52) <= result_to_dst(55 downto 52); end if;
                        if (mask(12) = '1') then RA(51 downto 48) <= result_to_dst(51 downto 48); end if;
                        if (mask(11) = '1') then RA(47 downto 44) <= result_to_dst(47 downto 44); end if;
                        if (mask(10) = '1') then RA(43 downto 40) <= result_to_dst(43 downto 40); end if;
                        if (mask( 9) = '1') then RA(39 downto 36) <= result_to_dst(39 downto 36); end if;
                        if (mask( 8) = '1') then RA(35 downto 32) <= result_to_dst(35 downto 32); end if;
                        if (mask( 7) = '1') then RA(31 downto 28) <= result_to_dst(31 downto 28); end if;
                        if (mask( 6) = '1') then RA(27 downto 24) <= result_to_dst(27 downto 24); end if;
                        if (mask( 5) = '1') then RA(23 downto 20) <= result_to_dst(23 downto 20); end if;
                        if (mask( 4) = '1') then RA(19 downto 16) <= result_to_dst(19 downto 16); end if;
                        if (mask( 3) = '1') then RA(15 downto 12) <= result_to_dst(15 downto 12); end if;
                        if (mask( 2) = '1') then RA(11 downto  8) <= result_to_dst(11 downto  8); end if;
                        if (mask( 1) = '1') then RA( 7 downto  4) <= result_to_dst( 7 downto  4); end if;
                        if (mask( 0) = '1') then RA( 3 downto  0) <= result_to_dst( 3 downto  0); end if;
                end if;
                if (seq_dest_reg = DST_B) or (seq_dest_reg = DST_ABC) then
                        if (mask(13) = '1') then RB(55 downto 52) <= result_to_dst(55 downto 52); end if;
                        if (mask(12) = '1') then RB(51 downto 48) <= result_to_dst(51 downto 48); end if;
                        if (mask(11) = '1') then RB(47 downto 44) <= result_to_dst(47 downto 44); end if;
                        if (mask(10) = '1') then RB(43 downto 40) <= result_to_dst(43 downto 40); end if;
                        if (mask( 9) = '1') then RB(39 downto 36) <= result_to_dst(39 downto 36); end if;
                        if (mask( 8) = '1') then RB(35 downto 32) <= result_to_dst(35 downto 32); end if;
                        if (mask( 7) = '1') then RB(31 downto 28) <= result_to_dst(31 downto 28); end if;
                        if (mask( 6) = '1') then RB(27 downto 24) <= result_to_dst(27 downto 24); end if;
                        if (mask( 5) = '1') then RB(23 downto 20) <= result_to_dst(23 downto 20); end if;
                        if (mask( 4) = '1') then RB(19 downto 16) <= result_to_dst(19 downto 16); end if;
                        if (mask( 3) = '1') then RB(15 downto 12) <= result_to_dst(15 downto 12); end if;
                        if (mask( 2) = '1') then RB(11 downto  8) <= result_to_dst(11 downto  8); end if;
                        if (mask( 1) = '1') then RB( 7 downto  4) <= result_to_dst( 7 downto  4); end if;
                        if (mask( 0) = '1') then RB( 3 downto  0) <= result_to_dst( 3 downto  0); end if;
                end if;
                if (seq_dest_reg = DST_C) or (seq_dest_reg = DST_ABC) then
                        if (mask(13) = '1') then RC(55 downto 52) <= result_to_dst(55 downto 52); end if;
                        if (mask(12) = '1') then RC(51 downto 48) <= result_to_dst(51 downto 48); end if;
                        if (mask(11) = '1') then RC(47 downto 44) <= result_to_dst(47 downto 44); end if;
                        if (mask(10) = '1') then RC(43 downto 40) <= result_to_dst(43 downto 40); end if;
                        if (mask( 9) = '1') then RC(39 downto 36) <= result_to_dst(39 downto 36); end if;
                        if (mask( 8) = '1') then RC(35 downto 32) <= result_to_dst(35 downto 32); end if;
                        if (mask( 7) = '1') then RC(31 downto 28) <= result_to_dst(31 downto 28); end if;
                        if (mask( 6) = '1') then RC(27 downto 24) <= result_to_dst(27 downto 24); end if;
                        if (mask( 5) = '1') then RC(23 downto 20) <= result_to_dst(23 downto 20); end if;
                        if (mask( 4) = '1') then RC(19 downto 16) <= result_to_dst(19 downto 16); end if;
                        if (mask( 3) = '1') then RC(15 downto 12) <= result_to_dst(15 downto 12); end if;
                        if (mask( 2) = '1') then RC(11 downto  8) <= result_to_dst(11 downto  8); end if;
                        if (mask( 1) = '1') then RC( 7 downto  4) <= result_to_dst( 7 downto  4); end if;
                        if (mask( 0) = '1') then RC( 3 downto  0) <= result_to_dst( 3 downto  0); end if;
                end if;
                if (seq_dest_reg = DST_M) then RM  <= result_to_dst; end if;
                if (seq_dest_reg = DST_N) then RN  <= result_to_dst; end if;
                if (seq_dest_reg = DST_PC) then RPC  <= result_to_dst(15 downto 0); end if;-- used by RTN
                if (seq_dest_reg = DST_PT) then 
                        if (PQ = 1) then
                            RQ  <= sanitized_result;
                        else
                            RP  <= sanitized_result;
                        end if;
                end if;
                if (seq_dest_reg = DST_ST) then 
                    if (mask( 3) = '1') then RST(14 downto 12) <= result_to_dst(14 downto 12);  end if;
                    if (mask( 2) = '1') then RST(11 downto  8) <= result_to_dst(11 downto  8);  end if;
                    if (mask( 1) = '1') then RST( 7 downto  4) <= result_to_dst( 7 downto  4);  end if;
                    if (mask( 0) = '1') then RST( 3 downto  0) <= result_to_dst( 3 downto  0);  end if;
                end if;
                if (seq_dest_reg = DST_G) then RG  <= result_to_dst(7 downto 0); end if;
                if (seq_dest_reg = DST_DA) then RDA <= result_to_dst(11 downto 0); end if;
                if (seq_dest_reg = DST_FO) then RFO <= result_to_dst(7 downto 0); end if;
                if (seq_dest_reg = DST_PRF) then RPERIF <= result_to_dst(7 downto 0); end if;-- peripheral address
                if (seq_dest_reg = DST_STK) then RSTK0 <= result_to_dst(15 downto 0); end if;-- Used by gosub
            end if;
            -- Exchange DST = OP1
            --          OP1 = OP2
            --           DST and OP2 must be equal
            if (seq_write_op1 = 1) then
                case seq_src_reg_1 is
                    when OP1_A => 
                        if (mask(13) = '1') then RA(55 downto 52) <= result_to_op1(55 downto 52); end if;
                        if (mask(12) = '1') then RA(51 downto 48) <= result_to_op1(51 downto 48); end if;
                        if (mask(11) = '1') then RA(47 downto 44) <= result_to_op1(47 downto 44); end if;
                        if (mask(10) = '1') then RA(43 downto 40) <= result_to_op1(43 downto 40); end if;
                        if (mask( 9) = '1') then RA(39 downto 36) <= result_to_op1(39 downto 36); end if;
                        if (mask( 8) = '1') then RA(35 downto 32) <= result_to_op1(35 downto 32); end if;
                        if (mask( 7) = '1') then RA(31 downto 28) <= result_to_op1(31 downto 28); end if;
                        if (mask( 6) = '1') then RA(27 downto 24) <= result_to_op1(27 downto 24); end if;
                        if (mask( 5) = '1') then RA(23 downto 20) <= result_to_op1(23 downto 20); end if;
                        if (mask( 4) = '1') then RA(19 downto 16) <= result_to_op1(19 downto 16); end if;
                        if (mask( 3) = '1') then RA(15 downto 12) <= result_to_op1(15 downto 12); end if;
                        if (mask( 2) = '1') then RA(11 downto  8) <= result_to_op1(11 downto  8); end if;
                        if (mask( 1) = '1') then RA( 7 downto  4) <= result_to_op1( 7 downto  4); end if;
                        if (mask( 0) = '1') then RA( 3 downto  0) <= result_to_op1( 3 downto  0); end if;
                    when OP1_B => 
                        if (mask(13) = '1') then RB(55 downto 52) <= result_to_op1(55 downto 52); end if;
                        if (mask(12) = '1') then RB(51 downto 48) <= result_to_op1(51 downto 48); end if;
                        if (mask(11) = '1') then RB(47 downto 44) <= result_to_op1(47 downto 44); end if;
                        if (mask(10) = '1') then RB(43 downto 40) <= result_to_op1(43 downto 40); end if;
                        if (mask( 9) = '1') then RB(39 downto 36) <= result_to_op1(39 downto 36); end if;
                        if (mask( 8) = '1') then RB(35 downto 32) <= result_to_op1(35 downto 32); end if;
                        if (mask( 7) = '1') then RB(31 downto 28) <= result_to_op1(31 downto 28); end if;
                        if (mask( 6) = '1') then RB(27 downto 24) <= result_to_op1(27 downto 24); end if;
                        if (mask( 5) = '1') then RB(23 downto 20) <= result_to_op1(23 downto 20); end if;
                        if (mask( 4) = '1') then RB(19 downto 16) <= result_to_op1(19 downto 16); end if;
                        if (mask( 3) = '1') then RB(15 downto 12) <= result_to_op1(15 downto 12); end if;
                        if (mask( 2) = '1') then RB(11 downto  8) <= result_to_op1(11 downto  8); end if;
                        if (mask( 1) = '1') then RB( 7 downto  4) <= result_to_op1( 7 downto  4); end if;
                        if (mask( 0) = '1') then RB( 3 downto  0) <= result_to_op1( 3 downto  0); end if;
                    when OP1_C => -- C
                        if (mask(13) = '1') then RC(55 downto 52) <= result_to_op1(55 downto 52); end if;
                        if (mask(12) = '1') then RC(51 downto 48) <= result_to_op1(51 downto 48); end if;
                        if (mask(11) = '1') then RC(47 downto 44) <= result_to_op1(47 downto 44); end if;
                        if (mask(10) = '1') then RC(43 downto 40) <= result_to_op1(43 downto 40); end if;
                        if (mask( 9) = '1') then RC(39 downto 36) <= result_to_op1(39 downto 36); end if;
                        if (mask( 8) = '1') then RC(35 downto 32) <= result_to_op1(35 downto 32); end if;
                        if (mask( 7) = '1') then RC(31 downto 28) <= result_to_op1(31 downto 28); end if;
                        if (mask( 6) = '1') then RC(27 downto 24) <= result_to_op1(27 downto 24); end if;
                        if (mask( 5) = '1') then RC(23 downto 20) <= result_to_op1(23 downto 20); end if;
                        if (mask( 4) = '1') then RC(19 downto 16) <= result_to_op1(19 downto 16); end if;
                        if (mask( 3) = '1') then RC(15 downto 12) <= result_to_op1(15 downto 12); end if;
                        if (mask( 2) = '1') then RC(11 downto  8) <= result_to_op1(11 downto  8); end if;
                        if (mask( 1) = '1') then RC( 7 downto  4) <= result_to_op1( 7 downto  4); end if;
                        if (mask( 0) = '1') then RC( 3 downto  0) <= result_to_op1( 3 downto  0); end if;
                    when OP1_M => RM <= result_to_op1;
                    when OP1_N => RM <= result_to_op1;
                    when OP1_G => RG <= result_to_op1(7 downto 0);
                    when OP1_ST => RST(7 downto 0) <= result_to_op1(7 downto 0);
                    when OP1_FO => RFO <= result_to_op1(7 downto 0);
                    when others =>
                        null;
                end case;
            end if;
            if (nut_state = ST_FETCH_OP0) or (nut_state = ST_FETCH_OP2) then
            -- Program counter
                RPC <= std_logic_vector(to_unsigned(to_integer(unsigned(RPC)) + 1, 16));
                RCY <= '0'; -- carry does not persist between opcodes
                RST(15) <= key_flag_in; -- keyboard ready
            elsif (nut_state = ST_EXE_JUMP) then
                RPC <= target_pc;
            end if;

            if (nut_state = ST_EXE_NORM) then
            -- Pointer operations
                if (op_selp = 1) then
                    PQ <= 0;
                elsif (op_selq = 1) then
                    PQ <= 1;
                end if;
                if (op_dec_ptr = '1') then -- This is only used for LC n where PT has to be decremented
                    if (PQ = 1) then       -- P=P-1 is done via the ALU
                        if iPT = 0 then 
                            RQ <= X"D";
                        else
                            RQ <= std_logic_vector(to_unsigned(iPT - 1, 4));
                        end if;
                    else
                        if iPT = 0 then 
                            RP <= X"D";
                        else
                            RP <= std_logic_vector(to_unsigned(iPT - 1, 4));
                        end if;
                    end if;
                end if;
            -- Keyboard Flags
                
            -- Carry
                if (op_pwr_off = '1') then
                    RCY <= not DISPON;
                elsif (op_write_carry = '1') then
                    RCY <= alu_carry_out;
                end if;

            -- Stack
                if (seq_pop = '1') then
                    RSTK0 <= RSTK1;
                    RSTK1 <= RSTK2;
                    RSTK2 <= RSTK3;
                    RSTK3 <= X"0000";
                elsif (seq_push = '1') then
                    RSTK3 <= RSTK2;
                    RSTK2 <= RSTK1;
                    RSTK1 <= RSTK0;
                end if;
            -- flags
                if (op_sethex = '1') then
                    DECIMAL <= '0';
                elsif (op_setdec = '1') then
                    DECIMAL <= '1';
                end if;
                if (op_reset_kb = '1') then
                    key_scan_o <= '1';
                else
                    key_scan_o <= '0';
                end if;
                if (op_key_ack = '1') then
                    key_ack_o <= '1';
                else
                    key_ack_o <= '0';
                end if;
            -- display
                if (op_disp_off = '1') then
                    DISPON <= '0';
                elsif (op_disp_toggle = '1') then
                    DISPON <= not DISPON;
                end if;
            end if; -- if (nut_state ...)
        end if; -- if rising_edge
    end process;
    -- Decode/Execute state machine
    
    rom_addr <= RC(27 downto 12) when (nut_state = ST_DECODE) or (nut_state = ST_FETCH_CXISA) else RPC;
    
    rom : ROM41C
    port map (
        Address => rom_addr(13 downto 0),
        OutClock => clk_in,
        OutClockEn => '1',
        Reset => reset_in,
        Q => rom_bank_0_data
    );
    -- return 0 on missing roms
    --rom_opcode <= rom_bank_0_data when to_integer(unsigned(rom_addr)) < 12288 else "0000000000"; -- use registered address
    rom_opcode <= rom_bank_0_data when unsigned(rom_addr) < 12288 else "0000000000"; -- use registered address
    -- Short jump target offset 03B 00 00 11 10 11
    short_jump_ofs <= "1111111111" & rom_opcode(8 downto 3) when rom_opcode(9) = '1' else 
                      "0000000000" & rom_opcode(8 downto 3);

    -- DATA Address
    --seq_DA <= (RDA(11 downto 4) & rom_opcode(9 downto 6)) when 
    --          ((rom_opcode(5 downto 0) = "111000") and (rom_opcode(9 downto 6) /= "0000")) or (rom_opcode(5 downto 0) = "101000") else
    --          RDA;
    
    decoded_opcode_ready <= '1' when nut_state = ST_DECODE else '0';
    
    dis : nut_disassembler 
        port map (
            pc_in         => opcode_pc,
            opcode        => opcode,
            second_opcode => second_opcode,
            RA_in         => RA,
            RB_in         => RB,
            RC_in         => RC,
            RP_in         => RP,
            RQ_in         => RQ,
            PT_in         => PT,
            RCY_in        => last_carry,
			use_trace_in  => use_trace_in,
            decode_ready_in => decoded_opcode_ready
        );

    main_state_machine : process(clk_in, reset_in)
        begin
            if reset_in = '1' then
                nut_state <= ST_INIT;
                seq_field_right <= 0;
                seq_field_left <= 0;
                seq_write_op1 <= 0; 
                seq_write_dst <= 0;
                second_opcode  <= "0000000000";
                opcode  <= "0000000000";
                seq_alu_op <= ALU_NONE;
                target_pc <= X"0000";
                seq_src_reg_2 <= OP2_A;
                seq_src_reg_1 <= OP1_A;
                seq_dest_reg <= DST_NONE;
                last_was_gosub <= '0';
                last_carry <= '0';
                flags_o <= X"00";
                seq_shf_a <= 0;
                seq_shf_b <= 0;
                seq_push <= '0';
                seq_pop <= '0';
            elsif rising_edge(clk_in) then
                case (nut_state) is
                    when ST_INIT =>
                        nut_state <= ST_FETCH_OP0;
                        -- update flags
                        RFI <= flags_in;
                        flags_o <= RFO;
                    when ST_FETCH_OP0 =>
                        last_carry <= RCY; -- save carry from last instruction, to be used by jump instructions
                        nut_state <= ST_FETCH_OP1;
                        target_pc <= RPC;
                        opcode_pc <= RPC; -- for the disassembler
                    when ST_FETCH_OP1 =>
                        if (rom_opcode = "0000000000") and (last_was_gosub = '1') then
                            opcode <= "1111100000"; -- force rtn if empty slot
                        else
                            opcode <= rom_opcode;
                        end if;
                        if (rom_opcode(1 downto 0) = "01") or (rom_opcode = "0100110000") then -- long gosub/jump & LDI need extra word
                            nut_state <= ST_FETCH_OP2;
                        else
                            nut_state <= ST_DECODE;                        
                        end if;
                        -- short jumps
                        target_pc <= std_logic_vector(unsigned(target_pc) + unsigned(short_jump_ofs));
                        -- DATA Address
                        if ((rom_opcode(5 downto 0) = "111000") and (rom_opcode(9 downto 6) /= "0000")) or (rom_opcode(5 downto 0) = "101000") then
                            seq_DA <= (RDA(11 downto 4) & rom_opcode(9 downto 6));
                        else
                            seq_DA <= RDA;
                        end if;
                    when ST_FETCH_OP2 =>
                        nut_state <= ST_DECODE;
                        second_opcode <= rom_opcode;
                    when ST_DECODE =>
                        if opcode(1 downto 0) = "01" then -- long gosub and conditional jumps
                            target_pc <= second_opcode(9 downto 2) & opcode(9 downto 2); -- absolute address
                        end if;
                        if (op_cxisa = '1') then
                            nut_state <= ST_FETCH_CXISA;
                        else
                            nut_state <= ST_EXE_NORM;
                        end if;
                        if (op_alu_op /= ALU_NONE) and (op_alu_op /= ALU_EQ) and (op_alu_op /= ALU_NEQ) and
                           (op_alu_op /= ALU_LT) and (op_alu_op /= ALU_TST) then
                            seq_write_dst <= 1;
                        end if;
                        if (op_alu_op = ALU_EX) then
                            seq_write_op1 <= 1;
                        end if;
                        seq_alu_op <= op_alu_op;
                        seq_src_reg_1 <= op_src_reg_1;
                        seq_src_reg_2 <= op_src_reg_2;
                        seq_dest_reg <= op_dest_reg;
                        seq_field_left <= op_field_left;
                        seq_field_right <= op_field_right;
                        last_was_gosub <= op_jump and op_push;
                        seq_push <= op_push;
                        if (op_if_c = '1') or (op_if_nc = '1') then
                            if ((op_if_c and last_carry) = '1') or ((op_if_nc and (not last_carry)) = '1') then -- do not execute
                                seq_pop <= '1';
                            else
                                seq_pop <= '0'; -- RTNxC ignored because condition is not met
                            end if;
                        else
                            seq_pop <= op_pop;
                        end if;
                        -- shifts
                        if op_alu_op = ALU_RCR then
                            seq_shf_a <= unscrambled_rcr;
                        else-- exchange result shift, used for G (this is expensive !)
                            seq_shf_a <= op_shf_a; -- used for Key and GOTOC and G
                            seq_shf_b <= op_shf_b; -- used for Key and GOTOC and G
                        end if;   
                    when ST_FETCH_CXISA =>
                        nut_state <= ST_EXE_NORM;
                        seq_write_dst <= 1;
                        seq_alu_op <= ALU_TFR;
                        second_opcode <= rom_opcode; -- OP1_CNT uses second_opcode as source
                    when ST_EXE_NORM =>
                        if (op_jump = '1') then
                            nut_state <= ST_EXE_JUMP;
                        else
                            nut_state <= ST_FETCH_OP0;
                        end if;
                        seq_write_op1 <= 0;
                        seq_write_dst <= 0;
                    when ST_EXE_JUMP =>
                        nut_state <= ST_FETCH_OP0;
                        
                end case;
            end if;
        end process;
    
        
    -- Microcode 
    
    field_dec : nut_field_decoder 
    port map (
        field_in       => opcode(4 downto 2),
        p_in           => RP,
        ptr_in         => PT,
        q_in           => RQ,
        start_o        => op_field_dec_right,
        end_o          => op_field_dec_left
    );

    process(opcode, second_opcode, iPT, iPTP1, op_field_dec_right, 
            op_field_dec_left, last_carry, bit_value, bit_value_n, unscrambled)
        begin
        op_alu_op           <= ALU_NONE; -- ALU operation, NONE is used to select/deselect write back of results
        op_write_carry      <= '0'; -- write back carry result
        op_src_reg_1        <= OP1_A; -- ALU operand 1 or transfer source or exchange source/destination
        op_src_reg_2        <= OP2_A; -- ALU operand 2 or exchange source/destination
        op_dest_reg         <= DST_A; -- Destination for ALU, TFR and exchange
        op_lvalue           <= X"000" & opcode(9 downto 6); -- literal value
        op_shf_a            <= 0;   -- shift amount of path a
        op_shf_b            <= 0;   -- shift amount on path b
        op_field_right      <= 0;   -- right most digit
        op_field_left       <= 13;  -- left most digit
        op_cxisa            <= '0'; -- use C[6:3] as address to read rom value into C[2:0]
        op_reset_kb         <= '0'; -- start keyboard scan
        op_test_kb          <= '0'; -- read scanned keyboard
        op_disp_toggle      <= '0'; -- turn display on if off or off if on
        op_disp_off         <= '0'; -- turn display off
        op_pwr_off          <= '0'; -- turn calc off
        op_jump             <= '0'; -- adds extra state to reload the PC
        op_nop              <= '0'; -- no operation
        op_if_c             <= '0'; -- execute if carry set 
        op_if_nc            <= '0'; -- execute if carry not set
        op_pop              <= '0'; -- used for pop and pop c 
        op_push             <= '0'; -- push onto the stack
        op_dec_ptr          <= '0'; -- decrement pointer - used by LC
        op_sethex           <= '0'; -- set HEXADECIMAL mode
        op_setdec           <= '0'; -- set DECIMAL mode
        op_test_ext         <= '0';
        op_key_ack          <= '0'; -- send keyboard acknowledge
        op_force_hex        <= '0'; -- force hex mode on arithmetic opcode
        op_no_src_mask      <= '0'; -- do not use masking of source operands
        op_set_carry_early  <= '0'; -- used to set the carry for opcodes that need a 1 as op_lvalue
        op_selp             <= 0;
        op_selq             <= 0;
        
        case (opcode(1 downto 0)) is
            when "00" => -- general opcodes
                case (opcode(9 downto 2)) is
                    -- NOP, HPIL
                    when "00000000" | "00010000" | "00100000" | "00110000" | 
                         "01000000" | "01010000" | "01100000" | "01110000" | 
                         "10000000" | "10010000" | "10100000" | "10110000" | 
                         "11000000" | "11010000" | "11100000" | "11110000"
                     => op_nop <= '1';                        
                    -- ST=0 n
                    when "00000001" | "00010001" | "00100001" | "00110001" | 
                         "01000001" | "01010001" | "01100001" | "01110001" | 
                         "10000001" | "10010001" | "10100001" | "10110001" | 
                         "11000001" | "11010001" | "11100001"
                    => op_alu_op <= ALU_AND; op_dest_reg <= DST_ST; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_LV; op_field_left <= 3; op_lvalue <= bit_value_n;
                    -- CLRST
                    when "11110001" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_ST; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_0; op_field_left <= 1; -- CLRST
                    -- ST=1 n
                    when "00000010" | "00010010" | "00100010" | "00110010" | 
                         "01000010" | "01010010" | "01100010" | "01110010" | 
                         "10000010" | "10010010" | "10100010" | "10110010" | 
                         "11000010" | "11010010" | "11100010"
                    => op_alu_op <= ALU_OR; op_dest_reg <= DST_ST; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_LV; op_field_left <= 3; op_lvalue <= bit_value;
                    when "11110010" => op_reset_kb <= '1'; -- 
                    -- ?ST=1 n
                    when "00000011" | "00010011" | "00100011" | "00110011" | 
                         "01000011" | "01010011" | "01100011" | "01110011" | 
                         "10000011" | "10010011" | "10100011" | "10110011" | 
                         "11000011" | "11010011" | "11100011"
                    => op_alu_op <= ALU_TST; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_LV; op_field_left <= 3; op_lvalue <= bit_value; op_write_carry <= '1';
                    -- LC n
                    when "00000100" | "00010100" | "00100100" | "00110100" |
                         "01000100" | "01010100" | "01100100" | "01110100" |
                         "10000100" | "10010100" | "10100100" | "10110100" |
                         "11000100" | "11010100" | "11100100" | "11110100"
                    => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_LV; op_field_right <= iPT; op_field_left <= iPT; 
                       op_shf_a <= rev_pt_rom(iPT); op_no_src_mask <= '1'; op_dec_ptr <= '1'; -- Load Constant @P
                    -- 014
                    when "00000101" | "00010101" | "00100101" | "00110101" |
                         "01000101" | "01010101" | "01100101" | "01110101" |
                         "10000101" | "10010101" | "10100101" | "10110101" |
                         "11000101" | "11010101" | "11100101"  
                          => op_alu_op <= ALU_EQ; op_src_reg_1 <= OP1_PT; op_src_reg_2 <= OP2_LV; 
                             op_lvalue <= X"000" & std_logic_vector(to_unsigned(unscrambled, 4)); op_write_carry <= '1'; --  ? pt == %d
                    when "11110101" => op_alu_op <= ALU_SUB; op_dest_reg <= DST_PT; op_src_reg_1 <= OP1_PT; op_src_reg_2 <= OP2_0; op_set_carry_early <= '1'; op_force_hex <= '1'; -- P=P-1
                    -- 018
                    when "00000110" => op_nop <= '1';
                    when "00010110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_G; op_src_reg_1 <= OP1_C; 
                                       op_shf_a <= iPT; op_field_left <= 1; op_no_src_mask <= '1'; --  g=c
                    when "00100110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_G; 
                                       op_field_right <= iPT; op_field_left <= iPTP1; op_no_src_mask <= '1'; --  c=g
                    when "00110110" => op_alu_op <= ALU_EX;  op_dest_reg <= DST_C; op_src_reg_1 <= OP1_G; op_src_reg_2 <= OP2_C; 
                                       op_field_right <= iPT; op_field_left <= iPT; --  c <-> g
                    when "01000110" => op_nop <= '1';
                    when "01010110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_M; op_src_reg_1 <= OP1_C; --  m = C
                    when "01100110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_M; --  c = m
                    when "01110110" => op_alu_op <= ALU_EX;  op_dest_reg <= DST_C; op_src_reg_1 <= OP1_M; op_src_reg_2 <= OP2_C;--  c <-> m
                    when "10000110" => op_nop <= '1';
                    when "10010110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_FO; op_src_reg_1 <= OP1_ST; op_field_left <= 1; --  fo=s byte
                    when "10100110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_ST; op_src_reg_1 <= OP1_FO; op_field_left <= 1; --  s = fo byte
                    when "10110110" => op_alu_op <= ALU_EX;  op_dest_reg <= DST_FO; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_FO; op_field_left <= 1; --  s <-> fo
                    when "11000110" => op_nop <= '1';
                    when "11010110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_ST; op_src_reg_1 <= OP1_C; op_field_left <= 1; --  s=c byte
                    when "11100110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_ST; op_field_left <= 1; --  c = s byte
                    when "11110110" => op_alu_op <= ALU_EX;  op_dest_reg <= DST_C; op_src_reg_1 <= OP1_ST; op_src_reg_2 <= OP2_C; op_field_left <= 1; --  s <-> C
                    -- 01c
                    when "00000111" | "00010111" | "00100111" | "00110111" | 
                         "01000111" | "01010111" | "01100111" | "01110111" | 
                         "10000111" | "10010111" | "10100111" | "10110111" | 
                         "11000111" | "11010111" | "11100111"
                                    => op_alu_op <= ALU_TFR; op_dest_reg <= DST_PT; op_src_reg_1 <= OP1_LV; op_lvalue <= X"000" & std_logic_vector(to_unsigned(unscrambled, 4)); --  Load Constant to P, carry cleared from reg_p module
                    when "11110111" => op_alu_op <= ALU_ADD; op_dest_reg <= DST_PT; op_src_reg_1 <= OP1_PT; op_src_reg_2 <= OP2_0; op_set_carry_early <= '1'; op_force_hex <= '1'; -- P=P+1
                    -- 020
                    when "00001000" => op_pop <= '1';
                    when "00011000" => op_pwr_off <= '1'; op_pop <= '1'; op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_STK; op_field_left <= 3; -- PWROFF
                    when "00101000" => op_selp <= 1;
                    when "00111000" => op_selq <= 1;
                    when "01001000" => op_alu_op <= ALU_EQ; op_src_reg_1 <= OP1_P; op_src_reg_2 <= OP2_Q; -- ? p==q 
                    when "01011000" => op_nop <= '1'; -- FIXME: lld battery status c:clear batteries ok
                    when "01101000" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_0; op_dest_reg <= DST_ABC; -- CLRREGS
                    when "01111000" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_C; -- goto C[6:3]
                                       op_shf_a <= 3; op_no_src_mask <= '1'; op_field_left <= 3; 
                    when "10001000" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_KEY; 
                                       op_shf_a <= 3; op_no_src_mask <= '1'; op_field_left <= 3; op_field_right <= 4; op_key_ack <= '1'; -- C=KEY
                    when "10011000" => op_sethex <= '1'; 
                    when "10101000" => op_setdec <= '1'; 
                    when "10111000" => op_disp_off <= '1'; 
                    when "11001000" => op_disp_toggle <= '1'; -- really used ?
                    when "11011000" => op_pop <= '1'; op_if_c <= '1'; op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_STK; op_field_left <= 3; -- RTNC
                    when "11101000" => op_pop <= '1'; op_if_nc <= '1'; op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_STK; op_field_left <= 3; -- rtnnc
                    when "11111000" => op_pop <= '1'; op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_STK; op_field_left <= 3; -- rtn                       
                    when "00001001" | "00011001" | "00101001" | "00111001" |
                         "01001001" | "01011001" | "01101001" | "01111001" |
                         "10001001" | "10011001" | "10101001" | "10111001" |
                         "11001001" | "11011001" | "11101001" |
                         "11111001" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_PRF; op_src_reg_1 <= OP1_C; op_field_left <= 1; -- selprf
                    when "00001010" | "00011010" | "00101010" | "00111010" |
                         "01001010" | "01011010" | "01101010" | "01111010" |
                         "10001010" | "10011010" | "10101010" | "10111010" |
                         "11001010" | "11011010" | "11101010" |
                         "11111010" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_DATA; op_src_reg_1 <= OP1_C; -- C -> reg n 
                    when "00001011" | "00011011" | "00101011" | "00111011" |
                         "01001011" | "01011011" | "01101011" | "01111011" |
                         "10001011" | "10011011" | "10101011" | "10111011" |
                         "11001011" | "11011011" | "11101011" |
                         "11111011" => op_nop <= '1'; -- Not implemented ? 1 = ext flag
                    when "00001100" => op_nop <= '1'; -- FIXME:disp blink
                    when "00011100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_N; op_src_reg_1 <= OP1_C; -- n=c
                    when "00101100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_N; -- c=n
                    when "00111100" => op_alu_op <= ALU_EX;  op_dest_reg <= DST_C; op_src_reg_1 <= OP1_N; op_src_reg_2 <= OP2_C;-- c <-> n                        
                    when "01001100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_CNT; op_field_left <= 2; -- c=op2 ldi
                    when "01011100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_STK; op_src_reg_1 <= OP1_C; 
                                       op_shf_a <= 3; op_no_src_mask <= '1'; op_field_left <= 3; op_push <= '1';-- push c
                    when "01101100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_STK; 
                                       op_shf_a <= 11; op_no_src_mask <= '1'; op_field_left <= 6; op_field_right <= 3; op_pop <= '1'; -- pop c
                    when "01111100" => op_nop <= '1'; -- ??? 0x1f0
                    when "10001100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_PC; op_src_reg_1 <= OP1_KEY; -- goto keys
                                       op_jump <= '1'; op_key_ack <= '1'; -- goto keys
                                       op_shf_a <= 3; op_no_src_mask <= '1'; op_field_left <= 1; 
                    when "10011100" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_DA; op_src_reg_1 <= OP1_C; op_field_left <= 2; -- RAM Addr=C
                    when "10101100" => op_nop <= '1'; -- FIXME:clear regs 0x2b0
                    when "10111100" => op_alu_op <= ALU_TFR; op_dest_reg  <= DST_DATA; op_src_reg_1 <= OP1_C; --  reg[RAMAddr]=C
                    when "11001100" => op_alu_op <= ALU_TFR; op_dest_reg  <= DST_C;    op_src_reg_1 <= OP1_CNT; op_field_left <= 2; op_cxisa <= '1'; -- cxisa
                    when "11011100" => op_alu_op <= ALU_OR;  op_src_reg_1 <= OP1_A;  op_src_reg_2 <= OP2_C;  op_dest_reg  <= DST_C; --  c=c|a
                    when "11101100" => op_alu_op <= ALU_AND; op_src_reg_1 <= OP1_A;  op_src_reg_2 <= OP2_C;  op_dest_reg  <= DST_C; --  c=c|a
                    when "11111100" => op_alu_op <= ALU_TFR; op_dest_reg  <= DST_PRF; op_src_reg_1 <= OP1_C; op_field_left <= 1; -- FIXME:sel pfad
                    when "00001101" | "00011101" | "00101101" | "00111101" | 
                         "01001101" | "01011101" | "01101101" | "01111101" | 
                         "10001101" | "10011101" | "10101101" | "10111101" | 
                         "11001101" | "11011101" | "11101101" |
                         "11111101" => op_nop <= '1'; -- ??? x34
                    when "00001110" | "00011110" | "00101110" | "00111110" |
                         "01001110" | "01011110" | "01101110" | "01111110" |
                         "10001110" | "10011110" | "10101110" | "10111110" |
                         "11001110" | "11011110" | "11101110" |
                         "11111110" => op_alu_op <= ALU_TFR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_DATA; -- Register number overrides DataAddr reg n -> C
                    when "00001111" | "00011111" | "00101111" | "00111111" |
                         "01001111" | "01011111" | "01101111" | "01111111" |
                         "10001111" | "10011111" | "10101111" | "10111111" |
                         "11001111" | "11011111" | "11101111" |
                         "11111111" => op_alu_op <= ALU_RCR; op_dest_reg <= DST_C; op_src_reg_1 <= OP1_C; --op_lvalue <= X"000" & std_logic_vector(to_unsigned(unscrambled, 4)); 
                    when others => op_nop <= '1';
                            --$display("%04o %10b unrecognized opcode", fetched_addr, opcode);
                end case;
            when "01"=> -- long jump/call
                if ( second_opcode(1 downto 0) = "01") or ( second_opcode(1 downto 0) = "00")then --
                    op_push <= '1';
                    op_alu_op <= ALU_TFR;
                    op_dest_reg <= DST_STK; 
                    op_src_reg_1 <= OP1_PC; 
                    op_field_left <= 3;
                end if; -- push only if call
                if ((last_carry xor second_opcode(0)) = '0') then
                    op_jump <= '1';
                else
                    op_nop <= '1'; -- ignore jump if condition false
                end if;
            when "10" => -- arithmetic opcodes
                op_field_right <= to_integer(unsigned(op_field_dec_right));
                op_field_left <= to_integer(unsigned(op_field_dec_left));
                case (opcode(9 downto 5)) is
                    when "00000" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; --0 -> a[w ]
                    when "00001" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_B; --0 -> b[w ]
                    when "00010" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_C; --0 -> c[w ]
                    when "00011" => op_alu_op <= ALU_EX;  op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_B; op_dest_reg <= DST_B; --a exchange b[wp]
                    when "00100" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_B; --a -> b[x ]
                    when "00101" => op_alu_op <= ALU_EX;  op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; --a exchange c[w ]
                    when "00110" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_B; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_C; --b -> c[wp]
                    when "00111" => op_alu_op <= ALU_EX;  op_src_reg_1 <= OP1_B; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; --b exchange c[w ]
                    when "01000" => op_alu_op <= ALU_TFR; op_src_reg_1 <= OP1_C; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; --c -> a[wp]
                    when "01001" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_B; op_src_reg_2 <= OP2_B; op_dest_reg <= DST_A; op_write_carry <= '1'; -- a + b -> a[ms]
                    when "01010" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_C; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_A; op_write_carry <= '1'; -- a + c -> a[m ]op_set_carry_early <= '1';
                    when "01011" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; op_write_carry <= '1'; op_set_carry_early <= '1'; -- a + 1 -> a[p ] carry used as constant 1
                    when "01100" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_B; op_dest_reg <= DST_A; op_write_carry <= '1'; -- a - b -> a[ms]
                    when "01101" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_0; op_dest_reg <= DST_A; op_write_carry <= '1'; op_set_carry_early <= '1'; -- a - 1 -> a[s ] carry used as constant 1
                    when "01110" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_A; op_write_carry <= '1'; -- a - c -> a[wp]
                    when "01111" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_C; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; -- c + c -> c[w ]
                    when "10000" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; -- a + c -> c[x ]
                    when "10001" => op_alu_op <= ALU_ADD; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; op_set_carry_early <= '1'; -- c + 1 -> c[xs] carry used as constant 1
                    when "10010" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; -- a - c -> c[s ]
                    when "10011" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_C; op_src_reg_2 <= OP2_0; op_dest_reg <= DST_C; op_write_carry <= '1'; op_set_carry_early <= '1'; -- c - 1 -> c[x ] carry used as constant 1
                    when "10100" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; -- 0 - c -> c[s ]
                    when "10101" => op_alu_op <= ALU_SUB; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_C; op_write_carry <= '1'; op_set_carry_early <= '1'; -- 0 - c - 1 -> c[s ]
                    when "10110" => op_alu_op <= ALU_NEQ; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_B; op_dest_reg <= DST_B; op_write_carry <= '1'; -- ? 0 <> b
                    when "10111" => op_alu_op <= ALU_NEQ; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_A; op_write_carry <= '1'; -- ? 0 <> c
                    when "11000" => op_alu_op <= ALU_LT;  op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_A; op_write_carry <= '1'; -- ? a < c
                    when "11001" => op_alu_op <= ALU_LT;  op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_B; op_dest_reg <= DST_A; op_write_carry <= '1'; -- ? a < b
                    when "11010" => op_alu_op <= ALU_NEQ; op_src_reg_1 <= OP1_0; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; op_write_carry <= '1'; -- ? 0 <> a
                    when "11011" => op_alu_op <= ALU_NEQ; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_C; op_dest_reg <= DST_A; op_write_carry <= '1'; -- ? a <> c
                    when "11100" => op_alu_op <= ALU_LSR; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; op_shf_a <= 1; -- shift right a[wp]
                    when "11101" => op_alu_op <= ALU_LSR; op_src_reg_1 <= OP1_B; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_B; op_shf_a <= 1; -- shift right b[wp]
                    when "11110" => op_alu_op <= ALU_LSR; op_src_reg_1 <= OP1_C; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_C; op_shf_a <= 1; -- shift right c[w ]
                    when "11111" => op_alu_op <= ALU_LSL; op_src_reg_1 <= OP1_A; op_src_reg_2 <= OP2_A; op_dest_reg <= DST_A; op_shf_a <= 13; -- shift left a[w ] 
                    when others =>
                        null;
                end case;
            when "11" => -- short goto c/nc
                if ((last_carry xor opcode(2)) = '0') then
                    op_jump <= '1';
                else
                    op_nop <= '1'; -- ignore jump if condition false
                end if;
            when others =>
                null;
        end case;
        
        
    end process;
                     
                     
end architecture logic;