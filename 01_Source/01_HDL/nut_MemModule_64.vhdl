library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
-- 16 Register Memory module
-- 
-- 
--
entity nut_MemModule_16 is
    port(
        clk_in         : in std_logic;                      -- sync clock
        addr_in        : in std_logic_vector(3 downto 0);   -- a
        we_in          : in std_logic;                      -- write strobe
        data_o         : out std_logic_vector(55 downto 0); -- 
        data_in        : in std_logic_vector(55 downto 0)
    );
end nut_MemModule_16;

-- Use this values to avoid cold start
-- For 320 Regs
-- 8 4B000000000000
-- C 1000000000019C
-- D 1A70016919C19B
-- E 0000042C048001
-- For 64 regs
-- C 000000000000EF
-- D 0FA001690EF0EE
-- E 0000002C048020
architecture logic of nut_MemModule_16 is
    type mem_bank_16_t is  array (0 to 15) of std_logic_vector(55 downto 0);
    signal mem_bank : mem_bank_16_t := 
        ( X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000"
          --X"000000000000EF", X"0FA001690EF0EE", X"0000002C048020", X"00000000000000" 
        );
    signal raddr : integer range 0 to 15 := 0;
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
-- 64 Register Memory module
-- 
-- 
--
entity nut_MemModule_64 is
    port(
        clk_in         : in std_logic;                      -- sync clock
        addr_in        : in std_logic_vector(5 downto 0);   -- a
        we_in          : in std_logic;                      -- write strobe
        data_o         : out std_logic_vector(55 downto 0); -- 
        data_in        : in std_logic_vector(55 downto 0)
    );
end nut_MemModule_64;

-- Use this values to avoid cold start
-- EE 00000000C00020
-- 
architecture logic of nut_MemModule_64 is
    type mem_bank_64_t is  array (0 to 63) of std_logic_vector(55 downto 0);
    signal mem_bank : mem_bank_64_t :=
        ( X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", -- C0
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", -- D0
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", -- E0
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000C00020", X"00000000000000", 
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", -- F0
          X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000", X"00000000000000" 
        ); 
    signal raddr : integer range 0 to 63 := 0;
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
    component nut_MemModule_16 is
        port(
            clk_in         : in std_logic;                      -- sync clock
            addr_in        : in std_logic_vector(3 downto 0);   -- a
            we_in          : in std_logic;                      -- write strobe
            data_o         : out std_logic_vector(55 downto 0); -- 
            data_in        : in std_logic_vector(55 downto 0)
        );
    end component nut_MemModule_16;
    component nut_MemModule_64 is
        port(
            clk_in         : in std_logic;                      -- sync clock
            addr_in        : in std_logic_vector(5 downto 0);   -- a
            we_in          : in std_logic;                      -- write strobe
            data_o         : out std_logic_vector(55 downto 0); -- 
            data_in        : in std_logic_vector(55 downto 0)
        );
    end component nut_MemModule_64;
    
    signal en_000_00F       : std_logic; 
    signal en_0C0_0FF       : std_logic; 
    signal we_000_00F       : std_logic; 
    signal we_0C0_0FF       : std_logic; 
    signal data_o_b0        : std_logic_vector(55 downto 0);
    signal data_o_b1        : std_logic_vector(55 downto 0);
begin

    en_000_00F <= '1' when addr_in(8 downto 4) = "00000" else '0';
    en_0C0_0FF <= '1' when addr_in(8 downto 6) = "011" else '0';

    we_000_00F <= '1' when (en_000_00F and we_in) = '1' else '0';
    we_0C0_0FF <= '1' when (en_0C0_0FF and we_in) = '1' else '0';
    
    b0 : nut_MemModule_16 
        port map (
            clk_in => clk_in,
            addr_in => addr_in(3 downto 0),
            we_in => we_000_00F,
            data_o => data_o_b0,
            data_in => data_in
        );
     b1 : nut_MemModule_64 
        port map (
            clk_in => clk_in,
            addr_in => addr_in(5 downto 0),
            we_in => we_0C0_0FF,
            data_o => data_o_b1,
            data_in => data_in
        );
    
    
    data_o <= data_o_b0 when en_000_00F = '1' else
              data_o_b1 when en_0C0_0FF = '1' else
              X"00000000000000";

end architecture logic;