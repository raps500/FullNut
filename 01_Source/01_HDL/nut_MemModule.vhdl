-- Memory modules

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
 -- Memory module with 512 Registers
-- 
-- 
--
entity nut_MemModule is
    port(
        clk_in         : in std_logic;                      -- sync clock
        addr_in        : in std_logic_vector(8 downto 0);  -- a
        we_in          : in std_logic;                      -- write strobe
        data_o         : out std_logic_vector(55 downto 0); -- 
        data_in        : in std_logic_vector(55 downto 0)
    );
end nut_MemModule;
    
architecture logic of nut_MemModule is
    type mem_bank_t is  array (511 downto 0) of std_logic_vector(55 downto 0);
    signal mem_bank : mem_bank_t := 
        ( X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000"
        ); 
    signal raddr : integer range 0 to 511 := 0;
begin
    data_o <= mem_bank(raddr); -- use registered address
    process(clk_in)
    begin
        if rising_edge(clk_in) then
            raddr <= to_integer(unsigned(addr_in));
            if (we_in = '1') then
                mem_bank(to_integer(unsigned(addr_in))) <= data_in;
            end if;
        end if;
    end process;
    
end architecture logic;
