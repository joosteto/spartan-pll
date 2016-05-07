library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package types is
  type bytearray is array (integer range <>) of STD_LOGIC_VECTOR(7 downto 0);
  type bitarray is array (integer range <>) of STD_LOGIC;
  
  type romRec is record
    next_addr: std_logic_vector(4 downto 0);
    mask: std_logic_vector(15 downto 0);
    data: std_logic_vector(15 downto 0);
  end record;
  type romRecArr is array(integer range <>) of romRec;
  
FUNCTION  concatenate(i: std_logic_vector; j:std_logic_vector) return std_logic_vector;
 
end package;



package body types is
function concatenate(i: std_logic_vector; j:std_logic_vector) return std_logic_vector is
begin
  return i&j;
end function; 
end package body;
