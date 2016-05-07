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

entity genctrl is
  port(
    clkin: in std_logic;
    sstep: out std_logic;
    state: out std_logic;
    RST: out std_logic);
end genctrl;

architecture BEHAVIOUR of genctrl is
  signal count: unsigned(15 downto 0);
  signal tmpstate:std_logic:='0';
  signal tmpreset:std_logic:='1';
begin
  genctrl_process:process(clkin, count, tmpstate)
  begin
    state<=tmpstate;
    RST<=tmpreset;
    if clkin'event and clkin = '1' then
      if count = 20000 then
        count <= x"0000";
        tmpstate<=not tmpstate;
        tmpreset<='0';
      else
        count<=count + 1;
      end if;
    end if;
    if count = 16 then
      sstep<='1';
    else
      sstep<='0';
    end if;
  end process;
end behaviour;
