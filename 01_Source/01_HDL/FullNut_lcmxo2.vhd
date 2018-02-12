
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity FUllNut_lcmxo2 is
	port(
            clk_in          : in std_logic;                     -- sync clock
            reset_in        : in std_logic;                     -- asserted high reset
            key_in          : in std_logic_vector(7 downto 0);  -- last pressed key
            key_scan_o      : out std_logic;                    -- start keyboard scan
            key_ack_o       : out std_logic;                    -- acknowledge keyboard scan
            key_flag_in     : in std_logic;                     -- keyboard scanned flag (S15)
            flags_in        : in std_logic_vector( 7 downto 0); -- input flags
            flags_o         : out std_logic_vector( 7 downto 0);--output flags
            -- LCD Interface
            commons_o   : out std_logic_vector(35 downto 0);
            segments_o  : inout std_logic_vector(5 downto 0)

			);
end FUllNut_lcmxo2;

architecture logic of FUllNut_lcmxo2 is
    component nut_Main is 
        port (
            clk_in          : in std_logic;                     -- sync clock
            reset_in        : in std_logic;                     -- asserted high reset
            use_trace_in    : in std_logic;						-- trace enable
			key_in          : in std_logic_vector(7 downto 0);  -- last pressed key
            key_scan_o      : out std_logic;                    -- start keyboard scan
            key_ack_o       : out std_logic;                    -- acknowledge keyboard scan
            key_flag_in     : in std_logic;                     -- keyboard scanned flag (S15)
            flags_in        : in std_logic_vector( 7 downto 0); -- input flags
            flags_o         : out std_logic_vector( 7 downto 0);--output flags
            reg_data_in     : in std_logic_vector(55 downto 0);
            reg_data_o      : out std_logic_vector(55 downto 0);
            reg_addr_o      : out std_logic_vector(11 downto 0);
            reg_perif_o     : out std_logic_vector(7 downto 0);
            reg_rd_o        : out std_logic;
            reg_we_o        : out std_logic
        );
        end component;
         
    component nut_LCDDriver is
        port(
            clk_in      : in std_logic;
            reset_in      : in std_logic;
            addr_in     : in std_logic_vector(3 downto 0); -- only 4 bits are significant 
            data_in     : in std_logic_vector(47 downto 0); -- only 48 bits are significant (12 nibbles)
            data_o      : out std_logic_vector(55 downto 0); -- only 48 bits are significant (12 nibbles)
            perif_in    : in std_logic_vector(7 downto 0);
            rd_in       : in std_logic;
            we_in       : in std_logic;
            ann_we_in   : in std_logic;
            -- LCD Interface
            commons_o   : out std_logic_vector(35 downto 0);
            segments_o  : inout std_logic_vector(5 downto 0)
        );
         end component;
    --signal    clk             : std_logic := '0'; -- clock
    --signal    reset           : std_logic := '0'; -- active high reset
    --signal    key             : std_logic_vector(7 downto 0) := X"00";           -- keyboard column signal
    --signal    key_scan        : std_logic;                    -- keyboard active row
    --signal    key_ack         : std_logic;                    -- keyboard active row
    --signal    key_flag        : std_logic := '0';                    -- keyboard active row
    --signal    flags           : std_logic_vector(7 downto 0) := X"00"; -- input flags
    --signal    flagso          : std_logic_vector(7 downto 0) := X"00"; -- input flags
    signal    reg_data_from_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_data_to_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_addr        : std_logic_vector(11 downto 0); -- Register address
    signal    reg_perif       : std_logic_vector(7 downto 0); -- Peripheral address
    signal    reg_rd          : std_logic;                    -- read strobe
    signal    reg_we          : std_logic;                    -- write strobe
    signal    lcd_we          : std_logic;                    -- write strobe
    signal    ann_we          : std_logic;                    -- annunciators write strobe
    
begin

    
    nut : nut_Main port map(
        clk_in          => clk_in,          
        reset_in        => reset_in,
        use_trace_in    => '0',
        key_in          => key_in,        
        key_scan_o      => key_scan_o,          
        key_ack_o       => key_ack_o,          
        key_flag_in     => key_flag_in,          
        flags_in        => flags_in,          
        flags_o         => flags_o,          
        reg_data_in     => reg_data_from_periph,
        reg_data_o      => reg_data_to_periph,
        reg_addr_o      => reg_addr,
        reg_perif_o     => reg_perif,
        reg_rd_o        => reg_rd,
        reg_we_o        => reg_we
    );
	ann_we <= '1' when reg_addr = X"FFF" else '0';
    lcd_we <= '1' when (ann_we /= '1') and (reg_we = '1') else '0';
    
    disp : nut_LCDDriver port map(
        clk_in      => clk_in,          
        reset_in        => reset_in,       
        addr_in     => reg_addr(3 downto 0),
        data_in     => reg_data_to_periph(47 downto 0),
        data_o      => reg_data_from_periph,
        perif_in    => reg_perif,
        rd_in       => reg_rd,
        we_in       => reg_we,
        ann_we_in   => ann_we,
        commons_o   => commons_o,
        segments_o  => segments_o
    );  

end architecture logic;




