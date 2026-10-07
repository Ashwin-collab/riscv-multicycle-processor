library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mem is
    generic(
        words : integer := 64
    );

    port(
        clk : in  STD_LOGIC;
        we  : in  STD_LOGIC;

        a   : in  STD_LOGIC_VECTOR(31 downto 0);
        wd  : in  STD_LOGIC_VECTOR(31 downto 0);

        rd  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end mem;


architecture behave of mem is

    type mem_array is array (0 to words-1)
        of STD_LOGIC_VECTOR(31 downto 0);

    constant INIT_MEM : mem_array := (
        0 => x"06400093", -- addi x1, x0, 100
        1 => x"02A00113", -- addi x2, x0, 42
        2 => x"0020A023", -- sw   x2, 0(x1)
        3 => x"0000A183", -- lw   x3, 0(x1)
        4 => x"0030A223", -- sw   x3, 4(x1)
        5 => x"00000063", -- beq  x0, x0, 0
        others => x"00000013" -- nop
    );

    signal RAM : mem_array := INIT_MEM;

begin

    ----------------------------------------------------------------
    -- Asynchronous read
    ----------------------------------------------------------------
    rd <= RAM(to_integer(unsigned(a(7 downto 2))));


    ----------------------------------------------------------------
    -- Synchronous write
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if we = '1' then
                RAM(to_integer(unsigned(a(7 downto 2)))) <= wd;
            end if;

        end if;
    end process;

end behave;