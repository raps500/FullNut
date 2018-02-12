-- Stub to use in synthesis
--
--
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
begin

end architecture logic;