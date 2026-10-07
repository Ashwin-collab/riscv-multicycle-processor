library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity riscvmulti is
    port(
        clk, reset : in  STD_LOGIC;

        MemWrite   : out STD_LOGIC;

        DataAdr    : out STD_LOGIC_VECTOR(31 downto 0);
        WriteData  : out STD_LOGIC_VECTOR(31 downto 0);

        ReadData   : in  STD_LOGIC_VECTOR(31 downto 0)
    );
end riscvmulti;


architecture struct of riscvmulti is

    component controller_multi
        port(
            clk, reset      : in  STD_LOGIC;

            op              : in  STD_LOGIC_VECTOR(6 downto 0);
            funct3          : in  STD_LOGIC_VECTOR(2 downto 0);
            funct7b5        : in  STD_LOGIC;
            Zero            : in  STD_LOGIC;

            AdrSrc          : out STD_LOGIC;
            IRWrite         : out STD_LOGIC;
            PCWrite         : out STD_LOGIC;
            OldPCWrite      : out STD_LOGIC;

            AWrite          : out STD_LOGIC;
            WriteDataWrite  : out STD_LOGIC;
            ALUOutWrite     : out STD_LOGIC;
            DataWrite       : out STD_LOGIC;

            RegWrite        : out STD_LOGIC;
            MemWrite        : out STD_LOGIC;

            ALUSrcA         : out STD_LOGIC_VECTOR(1 downto 0);
            ALUSrcB         : out STD_LOGIC_VECTOR(1 downto 0);

            ResultSrc       : out STD_LOGIC_VECTOR(1 downto 0);
            ImmSrc          : out STD_LOGIC_VECTOR(1 downto 0);

            ALUControl      : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;


    component datapath_multi
        port(
            clk, reset       : in  STD_LOGIC;

            AdrSrc           : in  STD_LOGIC;
            IRWrite          : in  STD_LOGIC;
            PCWrite         : in  STD_LOGIC;
            OldPCWrite       : in  STD_LOGIC;
            AWrite           : in  STD_LOGIC;
            WriteDataWrite   : in  STD_LOGIC;
            ALUOutWrite      : in  STD_LOGIC;
            DataWrite        : in  STD_LOGIC;
            RegWrite         : in  STD_LOGIC;

            ALUSrcA          : in  STD_LOGIC_VECTOR(1 downto 0);
            ALUSrcB          : in  STD_LOGIC_VECTOR(1 downto 0);
            ResultSrc        : in  STD_LOGIC_VECTOR(1 downto 0);
            ImmSrc           : in  STD_LOGIC_VECTOR(1 downto 0);
            ALUControl       : in  STD_LOGIC_VECTOR(2 downto 0);

            ReadData         : in  STD_LOGIC_VECTOR(31 downto 0);

            PC               : out STD_LOGIC_VECTOR(31 downto 0);
            Instr            : out STD_LOGIC_VECTOR(31 downto 0);
            MemAdr           : out STD_LOGIC_VECTOR(31 downto 0);
            WriteData        : out STD_LOGIC_VECTOR(31 downto 0);
            Zero             : out STD_LOGIC
        );
    end component;


    signal PC         : STD_LOGIC_VECTOR(31 downto 0);
    signal Instr      : STD_LOGIC_VECTOR(31 downto 0);

    signal MemAdr_i   : STD_LOGIC_VECTOR(31 downto 0);
    signal WriteData_i: STD_LOGIC_VECTOR(31 downto 0);

    signal Zero       : STD_LOGIC;

    signal AdrSrc         : STD_LOGIC;
    signal IRWrite        : STD_LOGIC;
    signal PCWrite        : STD_LOGIC;
    signal OldPCWrite     : STD_LOGIC;

    signal AWrite         : STD_LOGIC;
    signal WriteDataWrite : STD_LOGIC;
    signal ALUOutWrite    : STD_LOGIC;
    signal DataWrite      : STD_LOGIC;

    signal RegWrite       : STD_LOGIC;

    signal ALUSrcA        : STD_LOGIC_VECTOR(1 downto 0);
    signal ALUSrcB        : STD_LOGIC_VECTOR(1 downto 0);

    signal ResultSrc      : STD_LOGIC_VECTOR(1 downto 0);
    signal ImmSrc         : STD_LOGIC_VECTOR(1 downto 0);

    signal ALUControl     : STD_LOGIC_VECTOR(2 downto 0);

begin

    ----------------------------------------------------------------
    -- Controller
    ----------------------------------------------------------------
    c : controller_multi
        port map(
            clk,
            reset,

            Instr(6 downto 0),
            Instr(14 downto 12),
            Instr(30),
            Zero,

            AdrSrc,
            IRWrite,
            PCWrite,
            OldPCWrite,

            AWrite,
            WriteDataWrite,
            ALUOutWrite,
            DataWrite,

            RegWrite,
            MemWrite,

            ALUSrcA,
            ALUSrcB,

            ResultSrc,
            ImmSrc,

            ALUControl
        );


    ----------------------------------------------------------------
    -- Datapath
    ----------------------------------------------------------------
    dp : datapath_multi
        port map(
            clk,
            reset,

            AdrSrc,
            IRWrite,
            PCWrite,
            OldPCWrite,
            AWrite,
            WriteDataWrite,
            ALUOutWrite,
            DataWrite,
            RegWrite,

            ALUSrcA,
            ALUSrcB,
            ResultSrc,
            ImmSrc,
            ALUControl,

            ReadData,

            PC,
            Instr,
            MemAdr_i,
            WriteData_i,
            Zero
        );


    ----------------------------------------------------------------
    -- External memory interface
    ----------------------------------------------------------------
    DataAdr   <= MemAdr_i;
    WriteData <= WriteData_i;

end struct;