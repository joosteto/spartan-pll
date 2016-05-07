--
-- TEST PLL_ADV_DRP VHDL
--
-- Joost Witteveen

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use work.types.all;
library UNISIM;
use UNISIM.VComponents.all;

entity TOP is
  port(
    clkin: in std_logic;
    sstep: inout std_logic;
    state: inout std_logic;
    RST: inout std_logic;
    CLK0OUT: out std_logic;
    CLK1OUT: out std_logic);
end TOP;

architecture BEHAVIOUR of TOP is
  component genctrl
    port(
      clkin: in std_logic;
      sstep: out std_logic;
      state: out std_logic;
      RST: out std_logic);
  end component;
  component PLL_DRP_VHDL
    port(
      -- These signals are controlled by user logic interface and are covered
      -- in more detail within the XAPP.    input SADDR,
    SEN  : in STD_LOGIC;
    SCLK : in STD_LOGIC;
    RST  : in STD_LOGIC;

      -- These signals are to be connected to the PLL_ADV by port name.
      -- Their use matches the PLL port description in the Device User Guide.
    SRDY : out STD_LOGIC;
    DO    : in  STD_LOGIC_VECTOR(15 downto 0);
    DRDY  : in  STD_LOGIC;
    LOCKED: in  STD_LOGIC;
    DWE   : out STD_LOGIC;
    DEN   : out STD_LOGIC;
    DADDR : out STD_LOGIC_VECTOR(4 downto 0);
    DI    : out STD_LOGIC_VECTOR(15 downto 0);
    DCLK  : out STD_LOGIC;
    RST_PLL: out STD_LOGIC
    );      
  end component;

  signal feedback: std_logic;
  signal gnd: std_logic :='0';
  
  signal SRDY: std_logic;
  signal DO: std_logic_vector(15 downto 0);
  signal DRDY: std_logic;
  signal LOCKED: std_logic;
  signal DWE: std_logic;
  signal DEN: std_logic;
  signal DADDR: std_logic_vector(4 downto 0);
  signal DI: std_logic_vector(15 downto 0);
  signal DCLK: std_logic;
  signal RST_PLL: std_logic;
--  signal RST_PLL: std_logic;
begin
  genctrl_inst: genctrl
    port Map(
      clkin=>clkin,
      sstep=> sstep,
      state=> state,
      RST  => RST);    
  PLL_DRP_inst: PLL_DRP_VHDL
    port Map(
      SEN => sstep,
      SCLK=> CLKIN,
      RST => RST,
      SRDY=> SRDY,

      DO  => DO,
      DRDY=> DRDY,
      LOCKED=>LOCKED,
      DWE => DWE,
      DEN => DEN,
      DADDR=> DADDR,
      DI  => DI,
      DCLK => DCLK,
      RST_PLL=> RST_PLL);
  
  PLL_ADV_inst : PLL_ADV
      generic map (
        BANDWIDTH             => "OPTIMIZED",
        CLKFBOUT_MULT         => 20,
        CLKFBOUT_PHASE        => 0.0,
        CLKIN1_PERIOD         => 40.0,
        CLKIN2_PERIOD         => 40.0,
        CLKOUT0_DIVIDE        => 20,
        CLKOUT0_DUTY_CYCLE    => 0.5,
        CLKOUT0_PHASE         => 0.0,
        CLKOUT1_DIVIDE        => 20,
        CLKOUT1_DUTY_CYCLE    => 0.5,
        CLKOUT1_PHASE         => 0.0,
        CLKOUT2_DIVIDE        => 10,
        CLKOUT2_DUTY_CYCLE    => 0.5,
        CLKOUT2_PHASE         => 0.0,
        CLKOUT3_DIVIDE        => 10,
        CLKOUT3_DUTY_CYCLE    => 0.5,
        CLKOUT3_PHASE         => 0.0,
        CLKOUT4_DIVIDE        => 10,
        CLKOUT4_DUTY_CYCLE    => 0.5,
        CLKOUT4_PHASE         => 0.0,
        CLKOUT5_DIVIDE        => 10,
        CLKOUT5_DUTY_CYCLE    => 0.5,
        CLKOUT5_PHASE         => 0.0,
        COMPENSATION          => "SYSTEM_SYNCHRONOUS",
        DIVCLK_DIVIDE         => 1,
        EN_REL                => false,
        PLL_PMCD_MODE         => false,
        REF_JITTER            => 0.100,
        RESET_ON_LOSS_OF_LOCK => false,
        RST_DEASSERT_CLK      => "CLKIN1",
        CLKOUT0_DESKEW_ADJUST => "NONE",
        CLKOUT1_DESKEW_ADJUST => "NONE",
        CLKOUT2_DESKEW_ADJUST => "NONE",
        CLKOUT3_DESKEW_ADJUST => "NONE",
        CLKOUT4_DESKEW_ADJUST => "PPC",
        CLKOUT5_DESKEW_ADJUST => "PPC",
        CLKFBOUT_DESKEW_ADJUST => "PPC"--,
--		  SIM_DEVICE => "SPARTAN6"
        )
      port map (
        CLKFBDCM              => open,
        CLKFBOUT              => feedback,
        CLKOUT0               => CLK0OUT,
        CLKOUT1               => CLK1OUT,
        CLKOUT2               => open,
        CLKOUT3               => open,
        CLKOUT4               => open,
        CLKOUT5               => open,
        CLKOUTDCM0            => open,
        CLKOUTDCM1            => open,
        CLKOUTDCM2            => open,
        CLKOUTDCM3            => open,
        CLKOUTDCM4            => open,
        CLKOUTDCM5            => open,
        DO                    => open,
        DRDY                  => SRDY,
        LOCKED                => open,
        CLKFBIN               => feedback,
        CLKIN1                => clkin,
        CLKIN2                => gnd, --clkin, 
        CLKINSEL              => '1', -- 1 selects CLKIN1, and 0 selects CLKIN2
        DADDR                 => DADDR, --"00000",
        DCLK                  => '0',
        DEN                   => DEN, --'0',
        DI                    => DI, --"0000000000000000",
        DWE                   => DWE, --'0',
        REL                   => '0',
        RST                   => RST_PLL    -- Asynchronous PLL reset
        );
  
end BEHAVIOUR;
    
