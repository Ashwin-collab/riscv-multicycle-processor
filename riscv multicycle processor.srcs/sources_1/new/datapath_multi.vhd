library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity datapath_multi is
    port(
        clk, reset       : in  STD_LOGIC;

        -- =========================================================
        -- Control signals
        -- =========================================================
        AdrSrc           : in  STD_LOGIC;
        IRWrite          : in  STD_LOGIC;
        PCWrite          : in  STD_LOGIC;
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

        -- =========================================================
        -- Memory interface
        -- =========================================================
        ReadData         : in  STD_LOGIC_VECTOR(31 downto 0);

        -- =========================================================
        -- Outputs
        -- =========================================================
        PC               : out STD_LOGIC_VECTOR(31 downto 0);
        Instr            : out STD_LOGIC_VECTOR(31 downto 0);
        MemAdr           : out STD_LOGIC_VECTOR(31 downto 0);
        WriteData        : out STD_LOGIC_VECTOR(31 downto 0);
        Zero             : out STD_LOGIC
    );
end datapath_multi;


architecture struct of datapath_multi is

    -- =============================================================
    -- COMPONENT DECLARATIONS
    -- =============================================================

    component flopenr
        generic(width : integer);
        port(
            clk, reset, en : in STD_LOGIC;
            d              : in STD_LOGIC_VECTOR(width-1 downto 0);
            q              : out STD_LOGIC_VECTOR(width-1 downto 0)
        );
    end component;


    component regfile
        port(
            clk           : in STD_LOGIC;
            we3           : in STD_LOGIC;
            a1            : in STD_LOGIC_VECTOR(4 downto 0);
            a2            : in STD_LOGIC_VECTOR(4 downto 0);
            a3            : in STD_LOGIC_VECTOR(4 downto 0);
            wd3           : in STD_LOGIC_VECTOR(31 downto 0);
            rd1           : out STD_LOGIC_VECTOR(31 downto 0);
            rd2           : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;


    component extend
        port(
            instr  : in STD_LOGIC_VECTOR(31 downto 7);
            immsrc : in STD_LOGIC_VECTOR(1 downto 0);
            immext : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;


    component alu
        port(
            a          : in  STD_LOGIC_VECTOR(31 downto 0);
            b          : in  STD_LOGIC_VECTOR(31 downto 0);
            ALUControl : in  STD_LOGIC_VECTOR(2 downto 0);
            ALUResult  : out STD_LOGIC_VECTOR(31 downto 0);
            Zero       : out STD_LOGIC
        );
    end component;


    -- =============================================================
    -- INTERNAL SIGNALS
    -- =============================================================

    -- Program counter path
    signal PCNext      : STD_LOGIC_VECTOR(31 downto 0);
    signal OldPC       : STD_LOGIC_VECTOR(31 downto 0);

    -- Instruction/data registers
    signal IR          : STD_LOGIC_VECTOR(31 downto 0);
    signal DataReg     : STD_LOGIC_VECTOR(31 downto 0);

    -- Register file temporary registers
    signal A           : STD_LOGIC_VECTOR(31 downto 0);
    signal WDReg       : STD_LOGIC_VECTOR(31 downto 0);

    -- ALU register
    signal ALUOut      : STD_LOGIC_VECTOR(31 downto 0);

    -- Register file outputs
    signal RD1         : STD_LOGIC_VECTOR(31 downto 0);
    signal RD2         : STD_LOGIC_VECTOR(31 downto 0);

    -- Immediate
    signal ImmExt      : STD_LOGIC_VECTOR(31 downto 0);

    -- ALU inputs/output
    signal SrcA        : STD_LOGIC_VECTOR(31 downto 0);
    signal SrcB        : STD_LOGIC_VECTOR(31 downto 0);
    signal ALUResult   : STD_LOGIC_VECTOR(31 downto 0);

    -- Register-file writeback result
    signal Result      : STD_LOGIC_VECTOR(31 downto 0);

    -- Memory address
    signal Adr         : STD_LOGIC_VECTOR(31 downto 0);


begin

    -- =============================================================
    -- 1. PROGRAM COUNTER
    -- =============================================================

    pcreg : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            PCWrite,
            Result,
            PC
        );


    -- =============================================================
    -- 2. OLD PC REGISTER
    --
    -- Saves the PC during FETCH.
    -- Used later for branch/jump target calculation.
    -- =============================================================

    oldpcreg : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            OldPCWrite,
            PC,
            OldPC
        );


    -- =============================================================
    -- 3. INSTRUCTION REGISTER
    --
    -- IR <- Memory[PC] only when IRWrite = 1
    -- =============================================================

    irreg : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            IRWrite,
            ReadData,
            IR
        );


    -- =============================================================
    -- 4. DATA REGISTER
    --
    -- Stores data read from memory during MemRead state.
    -- =============================================================

    datareg_inst : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            DataWrite,
            ReadData,
            DataReg
        );


    -- =============================================================
    -- 5. A REGISTER
    --
    -- Stores rs1 value during DECODE.
    -- =============================================================

    areg : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            AWrite,
            RD1,
            A
        );


    -- =============================================================
    -- 6. WRITEDATA REGISTER
    --
    -- Stores rs2 value during DECODE.
    -- For SW this eventually goes to memory.
    -- =============================================================

    wdreg_inst : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            WriteDataWrite,
            RD2,
            WDReg
        );


    -- =============================================================
    -- 7. ALUOUT REGISTER
    --
    -- Stores ALU result between states.
    -- =============================================================

    aluoutreg : flopenr
        generic map(32)
        port map(
            clk,
            reset,
            ALUOutWrite,
            ALUResult,
            ALUOut
        );


    -- =============================================================
    -- 8. REGISTER FILE
    --
    -- rs1 = Instr(19:15)
    -- rs2 = Instr(24:20)
    -- rd  = Instr(11:7)
    -- =============================================================

    rf : regfile
        port map(
            clk,
            RegWrite,

            IR(19 downto 15),
            IR(24 downto 20),
            IR(11 downto 7),

            Result,

            RD1,
            RD2
        );


    -- =============================================================
    -- 9. IMMEDIATE EXTENSION
    -- =============================================================

    ext : extend
        port map(
            IR(31 downto 7),
            ImmSrc,
            ImmExt
        );


    -- =============================================================
    -- 10. ALU SOURCE A MUX
    --
    -- 00 -> PC
    -- 01 -> OldPC
    -- 10 -> A
    -- =============================================================

    process(ALUSrcA, PC, OldPC, A)
    begin

        case ALUSrcA is

            when "00" =>
                SrcA <= PC;

            when "01" =>
                SrcA <= OldPC;

            when "10" =>
                SrcA <= A;

            when others =>
                SrcA <= (others => '0');

        end case;

    end process;


    -- =============================================================
    -- 11. ALU SOURCE B MUX
    --
    -- 00 -> WDReg
    -- 01 -> ImmExt
    -- 10 -> constant 4
    -- =============================================================

    process(ALUSrcB, WDReg, ImmExt)
    begin

        case ALUSrcB is

            when "00" =>
                SrcB <= WDReg;

            when "01" =>
                SrcB <= ImmExt;

            when "10" =>
                SrcB <= x"00000004";

            when others =>
                SrcB <= (others => '0');

        end case;

    end process;


    -- =============================================================
    -- 12. ALU
    -- =============================================================

    mainalu : alu
        port map(
            SrcA,
            SrcB,
            ALUControl,
            ALUResult,
            Zero
        );


    -- =============================================================
    -- 13. RESULT MUX
    --
    -- 00 -> ALUOut
    -- 01 -> DataReg
    -- 10 -> ALUResult
    --
    -- Used for:
    -- ALU writeback
    -- Load writeback
    -- PC + 4
    -- =============================================================

    process(ResultSrc, ALUOut, DataReg, ALUResult)
    begin

        case ResultSrc is

            when "00" =>
                Result <= ALUOut;

            when "01" =>
                Result <= DataReg;

            when "10" =>
                Result <= ALUResult;

            when others =>
                Result <= (others => '0');

        end case;

    end process;


    -- =============================================================
    -- 14. MEMORY ADDRESS MUX
    --
    -- 0 -> PC      during FETCH
    -- 1 -> ALUOut  during memory access
    -- =============================================================

    process(AdrSrc, PC, ALUOut)
    begin

        if AdrSrc = '0' then
            Adr <= PC;
        else
            Adr <= ALUOut;
        end if;

    end process;


    -- =============================================================
    -- 15. OUTPUTS
    -- =============================================================

    Instr     <= IR;

    MemAdr    <= Adr;

    WriteData <= WDReg;

end struct;