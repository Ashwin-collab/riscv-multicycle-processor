library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity top_multi is
    port(
        clk, reset : in  STD_LOGIC;

        WriteData  : out STD_LOGIC_VECTOR(31 downto 0);
        DataAdr    : out STD_LOGIC_VECTOR(31 downto 0);

        MemWrite   : out STD_LOGIC
    );
end top_multi;


architecture struct of top_multi is

    component riscvmulti
        port(
            clk, reset : in  STD_LOGIC;

            MemWrite   : out STD_LOGIC;

            DataAdr    : out STD_LOGIC_VECTOR(31 downto 0);
            WriteData  : out STD_LOGIC_VECTOR(31 downto 0);

            ReadData   : in  STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;


    component mem
        port(
            clk : in  STD_LOGIC;
            we  : in  STD_LOGIC;

            a   : in  STD_LOGIC_VECTOR(31 downto 0);
            wd  : in  STD_LOGIC_VECTOR(31 downto 0);

            rd  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;


    signal ReadData_i : STD_LOGIC_VECTOR(31 downto 0);

    signal DataAdr_i  : STD_LOGIC_VECTOR(31 downto 0);
    signal WriteData_i: STD_LOGIC_VECTOR(31 downto 0);

    signal MemWrite_i : STD_LOGIC;

begin

    ----------------------------------------------------------------
    -- Processor
    ----------------------------------------------------------------
    rvmulti : riscvmulti
        port map(
            clk,
            reset,

            MemWrite_i,

            DataAdr_i,
            WriteData_i,

            ReadData_i
        );


    ----------------------------------------------------------------
    -- Shared instruction/data memory
    ----------------------------------------------------------------
    memory : mem
        port map(
            clk,
            MemWrite_i,

            DataAdr_i,
            WriteData_i,

            ReadData_i
        );


    ----------------------------------------------------------------
    -- Outputs
    ----------------------------------------------------------------
    WriteData <= WriteData_i;
    DataAdr   <= DataAdr_i;
    MemWrite  <= MemWrite_i;

end struct;