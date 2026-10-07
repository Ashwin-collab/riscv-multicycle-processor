library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity controller_multi is
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
end controller_multi;


architecture struct of controller_multi is

    component mainfsm
        port(
            clk, reset      : in  STD_LOGIC;
            op              : in  STD_LOGIC_VECTOR(6 downto 0);
            Zero            : in  STD_LOGIC;

            AdrSrc          : out STD_LOGIC;
            IRWrite         : out STD_LOGIC;
            PCUpdate        : out STD_LOGIC;
            OldPCWrite      : out STD_LOGIC;

            AWrite          : out STD_LOGIC;
            WriteDataWrite  : out STD_LOGIC;
            ALUOutWrite     : out STD_LOGIC;
            DataWrite       : out STD_LOGIC;

            RegWrite        : out STD_LOGIC;
            MemWrite        : out STD_LOGIC;

            Branch          : out STD_LOGIC;

            ALUSrcA         : out STD_LOGIC_VECTOR(1 downto 0);
            ALUSrcB         : out STD_LOGIC_VECTOR(1 downto 0);
            ResultSrc       : out STD_LOGIC_VECTOR(1 downto 0);

            ImmSrc          : out STD_LOGIC_VECTOR(1 downto 0);
            ALUOp           : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;


    component aludec
        port(
            opb5      : in  STD_LOGIC;
            funct3    : in  STD_LOGIC_VECTOR(2 downto 0);
            funct7b5  : in  STD_LOGIC;
            ALUOp     : in  STD_LOGIC_VECTOR(1 downto 0);
            ALUControl: out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;


    signal PCUpdate : STD_LOGIC;
    signal Branch   : STD_LOGIC;

    signal ALUOp    : STD_LOGIC_VECTOR(1 downto 0);

begin

    ----------------------------------------------------------------
    -- Main FSM
    ----------------------------------------------------------------
    fsm : mainfsm
        port map(
            clk,
            reset,
            op,
            Zero,

            AdrSrc,
            IRWrite,
            PCUpdate,
            OldPCWrite,

            AWrite,
            WriteDataWrite,
            ALUOutWrite,
            DataWrite,

            RegWrite,
            MemWrite,

            Branch,

            ALUSrcA,
            ALUSrcB,
            ResultSrc,

            ImmSrc,
            ALUOp
        );


    ----------------------------------------------------------------
    -- ALU Decoder
    ----------------------------------------------------------------
    ad : aludec
        port map(
            op(5),
            funct3,
            funct7b5,
            ALUOp,
            ALUControl
        );


    ----------------------------------------------------------------
    -- PC update logic
    --
    -- Fetch / JAL:
    -- PCUpdate = 1
    --
    -- BEQ:
    -- PCWrite = Branch AND Zero
    ----------------------------------------------------------------
    PCWrite <= PCUpdate or (Branch and Zero);

end struct;