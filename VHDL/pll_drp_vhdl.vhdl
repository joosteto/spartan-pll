--Author: Joost Witteveen
--
-- Generate repeated signals
--
--Part of TVU source.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.types.all;




entity PLL_DRP_VHDL is
  Port (
    -- These signals are controlled by user logic interface and are covered
    -- in more detail within the XAPP.    input SADDR,
    SEN  : in STD_LOGIC;
    SCLK : in STD_LOGIC;
    RST  : in STD_LOGIC;

    -- These signals are to be connected to the PLL_ADV by port name.
    -- Their use matches the PLL port description in the Device User Guide.

    SRDY : OUT STD_LOGIC;
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
end PLL_DRP_VHDL;


architecture BEHAVIOUR of PLL_DRP_VHDL is
  signal rom: romRecArr(23 downto 0);
  signal rom_addr: unsigned(4 downto 0);
  signal rom_do: romRec;
  
  signal next_srdy: std_logic;

  signal next_rom_addr: unsigned(4 downto 0);
  signal next_daddr: std_logic_vector(4 downto 0);
  signal next_dwe: std_logic;
  signal next_den: std_logic;
  signal next_rst_pll: std_logic;
  signal next_di: std_logic_vector(15 downto 0);

  constant RESTART:     unsigned:="0001";
  constant WAIT_LOCK:   unsigned:="0010";
  constant WAIT_SEN:    unsigned:="0011";
  constant ADDRESS:     unsigned:="0100";
  constant WAIT_A_DRDY: unsigned:="0101";
  constant BITMASK:     unsigned:="0110";
  constant BITSET:      unsigned:="0111";
  constant WRITESTATE:  unsigned:="1000";
  constant WAIT_DRDY :  unsigned:="1001";
  signal current_state:unsigned(3 downto 0):=RESTART;
  signal next_state:unsigned(3 downto 0):=RESTART;

  constant STATE_COUNT_CONST: unsigned:="10111";  --23=16+7
  signal state_count, next_state_count:unsigned(4 downto 0):=STATE_COUNT_CONST;

begin
  main_prcs:process(SCLK)
  begin
    if SCLK'event and SCLK = '1' then
      rom_do <= rom(to_integer(rom_addr));

      DADDR  <= next_daddr;
      DWE    <= next_dwe;
      DEN    <= next_den;
      RST_PLL<= next_rst_pll;
      DI     <= next_di;
      SRDY   <= next_srdy;
      rom_addr<=next_rom_addr;
      state_count <= next_state_count;

      if(RST='1') then
        current_state<=RESTART;
      else
        current_state<=next_state;
      end if;

      --Setup the default values
      next_srdy         <= '0';
      --next_daddr        <= DADDR;
      next_dwe          <= '0';
      next_den          <= '0';
      --next_rst_pll      <= RST_PLL;
      --next_di           <= DI;
      --next_rom_addr     <= rom_addr;
      --next_state_count  <= state_count;

      CASE_STATE: case current_state is
        when RESTART =>
          next_daddr <= (others => '0');
          next_di   <= (others => '0');
          next_rom_addr<=(others => '0');
          next_rst_pll<='1';
          next_state<= WAIT_LOCK;
        when WAIT_LOCK =>
          --Make sure reset is de-asserted          
          next_rst_pll <= '0';
          -- Reset the number of registers left to write for the next 
          -- reconfiguration event.
          next_state_count <= STATE_COUNT_CONST;
          if (LOCKED = '1') then
            -- PLL is locked, go on to wait for the SEN signal
            next_state  <= WAIT_SEN;
            -- Assert SRDY to indicate that the reconfiguration module is
            -- ready
            next_srdy   <= '1';
          else
            -- Keep waiting, locked has not asserted yet
            next_state  <= WAIT_LOCK;
          end if;
          
        -- Wait for the next SEN pulse and set the ROM addr appropriately 
        --    based on SADDR
        when WAIT_SEN =>
          if(SEN='1') then 
            -- SEN was asserted
            next_rom_addr <= (others =>'0');
            -- Go on to address the PLL
            next_state <= ADDRESS;
          else
            -- Keep waiting for SEN to be asserted
            next_state <= WAIT_SEN;
          end if;

        -- Set the address on the PLL and assert DEN to read the value
        when ADDRESS => 
          -- Reset the DCM through the reconfiguration
          next_rst_pll  <= '1';
          -- Enable a read from the PLL and set the PLL address
          next_den       <= '1';
          next_daddr     <= rom_do.next_addr;
          
          --Wait for the data to be ready
          next_state     <= WAIT_A_DRDY;

        -- Wait for DRDY to assert after addressing the PLL
        when WAIT_A_DRDY =>
          if (DRDY='1') then
            -- Data is ready, mask out the bits to save
            next_state <= BITMASK;
          else
            -- Keep waiting till data is ready
            next_state <= WAIT_A_DRDY;
          end if;

        -- Zero out the bits that are not set in the mask stored in rom
        when BITMASK =>
          -- Do the mask
          next_di     <= rom_do.mask and DO;
          -- Go on to set the bits
          next_state  <= BITSET;
          
        -- After the input is masked, OR the bits with calculated value in rom
        when BITSET => 
          -- Set the bits that need to be assigned
          next_di           <= rom_do.data or next_di;   --CHANGED: was 'or DI'
          -- Set the next address to read from ROM
          next_rom_addr     <= rom_addr + 1;
          -- Go on to write the data to the PLL
          next_state        <= WRITESTATE;

        -- DI is setup so assert DWE, DEN, and RST_PLL.  Subtract one from the
        --    state count and go to wait for DRDY.
        when WRITESTATE => 
          -- Set WE and EN on PLL
          next_dwe          <= '1';
          next_den          <= '1';
          
          -- Decrement the number of registers left to write
          next_state_count  <= state_count - 1;
          -- Wait for the write to complete
          next_state        <= WAIT_DRDY;
          
        -- Wait for DRDY to assert from the PLL.  If the state count is not 0
        --    jump to ADDRESS (continue reconfiguration).  If state count is
        --    0 wait for lock.
        when WAIT_DRDY =>
          if (DRDY='1') then
            -- Write is complete
            if (state_count /= "00000") then
              -- If there are more registers to write keep going
              next_state  <= ADDRESS;
            else
              -- There are no more registers to write so wait for the PLL
              -- to lock
              next_state  <= WAIT_LOCK;
            end if;
          else
            -- Keep waiting for write to complete
            next_state     <= WAIT_DRDY;
          end if;
        when others =>
          next_state <= RESTART;
      end case CASE_STATE;
    end if;
  end process;
end BEHAVIOUR;
