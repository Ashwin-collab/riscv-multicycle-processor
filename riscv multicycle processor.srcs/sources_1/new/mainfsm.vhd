library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mainfsm is
    port(
        clk, reset      : in  STD_LOGIC;
        op              : in  STD_LOGIC_VECTOR(6 downto 0);
        Zero            : in  STD_LOGIC;

        -- =========================================================
        -- Control outputs
        -- =========================================================
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
end mainfsm;


architecture behave of mainfsm is

    -- =============================================================
    -- FSM STATES
    -- =============================================================
    type statetype is (
        FETCH,
        DECODE,
        MEMADR,
        MEMREAD,
        MEMWB,
        MEMWRITE_STATE,   -- Renamed from MEMWRITE
        EXECUTER,
        ALUWB,
        EXECUTEI,
        JAL,
        BEQ
    );

    signal state, nextstate : statetype;

begin

    ----------------------------------------------------------------
    -- STATE REGISTER
    ----------------------------------------------------------------
    process(clk, reset)
    begin

        if reset = '1' then
            state <= FETCH;

        elsif rising_edge(clk) then
            state <= nextstate;

        end if;

    end process;


    ----------------------------------------------------------------
    -- NEXT STATE LOGIC
    ----------------------------------------------------------------
    process(state, op)
    begin

        -- Default
        nextstate <= FETCH;

        case state is

            ---------------------------------------------------------
            -- FETCH
            ---------------------------------------------------------
            when FETCH =>
                nextstate <= DECODE;


            ---------------------------------------------------------
            -- DECODE
            ---------------------------------------------------------
            when DECODE =>

                case op is

                    -- lw
                    when "0000011" =>
                        nextstate <= MEMADR;

                    -- sw
                    when "0100011" =>
                        nextstate <= MEMADR;

                    -- R-type
                    when "0110011" =>
                        nextstate <= EXECUTER;

                    -- I-type ALU
                    when "0010011" =>
                        nextstate <= EXECUTEI;

                    -- jal
                    when "1101111" =>
                        nextstate <= JAL;

                    -- beq
                    when "1100011" =>
                        nextstate <= BEQ;

                    when others =>
                        nextstate <= FETCH;

                end case;


            ---------------------------------------------------------
            -- MEMORY ADDRESS
            ---------------------------------------------------------
            when MEMADR =>

                if op = "0000011" then
                    nextstate <= MEMREAD;
                else
                    nextstate <= MEMWRITE_STATE;
                end if;


            ---------------------------------------------------------
            -- MEMORY READ
            ---------------------------------------------------------
            when MEMREAD =>
                nextstate <= MEMWB;


            ---------------------------------------------------------
            -- MEMORY WRITEBACK
            ---------------------------------------------------------
            when MEMWB =>
                nextstate <= FETCH;


            ---------------------------------------------------------
            -- MEMORY WRITE
            ---------------------------------------------------------
            when MEMWRITE_STATE =>
                nextstate <= FETCH;


            ---------------------------------------------------------
            -- R-TYPE EXECUTE
            ---------------------------------------------------------
            when EXECUTER =>
                nextstate <= ALUWB;


            ---------------------------------------------------------
            -- ALU WRITEBACK
            ---------------------------------------------------------
            when ALUWB =>
                nextstate <= FETCH;


            ---------------------------------------------------------
            -- I-TYPE ALU EXECUTE
            ---------------------------------------------------------
            when EXECUTEI =>
                nextstate <= ALUWB;


            ---------------------------------------------------------
            -- JAL
            ---------------------------------------------------------
            when JAL =>
                nextstate <= ALUWB;


            ---------------------------------------------------------
            -- BEQ
            ---------------------------------------------------------
            when BEQ =>
                nextstate <= FETCH;

        end case;

    end process;


    ----------------------------------------------------------------
    -- MAIN CONTROL SIGNALS
    ----------------------------------------------------------------
    process(state, op)
    begin

        -- =========================================================
        -- DEFAULT CONTROL SIGNALS
        -- =========================================================

        AdrSrc         <= '0';
        IRWrite        <= '0';
        PCUpdate       <= '0';
        OldPCWrite     <= '0';

        AWrite         <= '0';
        WriteDataWrite <= '0';
        ALUOutWrite    <= '0';
        DataWrite      <= '0';

        RegWrite       <= '0';
        MemWrite       <= '0';

        Branch         <= '0';

        ALUSrcA        <= "00";
        ALUSrcB        <= "00";
        ResultSrc      <= "00";

        ImmSrc         <= "00";
        ALUOp          <= "00";


        ----------------------------------------------------------------
        -- IMMEDIATE SOURCE
        ----------------------------------------------------------------
        case op is

            -- I-type / Load
            when "0000011" =>
                ImmSrc <= "00";

            -- S-type
            when "0100011" =>
                ImmSrc <= "01";

            -- B-type
            when "1100011" =>
                ImmSrc <= "10";

            -- J-type
            when "1101111" =>
                ImmSrc <= "11";

            when others =>
                ImmSrc <= "00";

        end case;


        ----------------------------------------------------------------
        -- FSM CONTROL
        ----------------------------------------------------------------
        case state is


            ------------------------------------------------------------
            -- FETCH
            --
            -- IR <- Memory[PC]
            -- PC <- PC + 4
            -- OldPC <- PC
            ------------------------------------------------------------
            when FETCH =>

                AdrSrc      <= '0';
                IRWrite     <= '1';

                OldPCWrite  <= '1';
                PCUpdate    <= '1';

                ALUSrcA     <= "00";
                ALUSrcB     <= "10";

                ResultSrc   <= "10";
                ALUOp       <= "00";


            ------------------------------------------------------------
            -- DECODE
            --
            -- A         <- rs1
            -- WriteData <- rs2
            -- ALUOut    <- OldPC + ImmExt
            ------------------------------------------------------------
            when DECODE =>

                AWrite         <= '1';
                WriteDataWrite <= '1';

                ALUSrcA         <= "01";
                ALUSrcB         <= "01";

                ALUOutWrite    <= '1';

                ALUOp           <= "00";


            ------------------------------------------------------------
            -- MEMORY ADDRESS
            --
            -- ALUOut <- A + ImmExt
            ------------------------------------------------------------
            when MEMADR =>

                ALUSrcA      <= "10";
                ALUSrcB      <= "01";

                ALUOutWrite  <= '1';

                ALUOp        <= "00";


            ------------------------------------------------------------
            -- MEMORY READ
            --
            -- DataReg <- Memory[ALUOut]
            ------------------------------------------------------------
            when MEMREAD =>

                AdrSrc       <= '1';

                DataWrite    <= '1';

                ResultSrc    <= "00";


            ------------------------------------------------------------
            -- MEMORY WRITEBACK
            --
            -- rd <- DataReg
            ------------------------------------------------------------
            when MEMWB =>

                ResultSrc    <= "01";

                RegWrite     <= '1';


            ------------------------------------------------------------
            -- MEMORY WRITE
            --
            -- Memory[ALUOut] <- WriteData
            ------------------------------------------------------------
            when MEMWRITE_STATE =>

                AdrSrc       <= '1';

                MemWrite     <= '1';

                ResultSrc    <= "00";


            ------------------------------------------------------------
            -- R-TYPE EXECUTE
            --
            -- ALUOut <- A op WriteData
            ------------------------------------------------------------
            when EXECUTER =>

                ALUSrcA      <= "10";
                ALUSrcB      <= "00";

                ALUOp        <= "10";

                ALUOutWrite  <= '1';


            ------------------------------------------------------------
            -- ALU WRITEBACK
            --
            -- rd <- ALUOut
            ------------------------------------------------------------
            when ALUWB =>

                ResultSrc    <= "00";

                RegWrite     <= '1';


            ------------------------------------------------------------
            -- I-TYPE ALU
            --
            -- ALUOut <- A op ImmExt
            ------------------------------------------------------------
            when EXECUTEI =>

                ALUSrcA      <= "10";
                ALUSrcB      <= "01";

                ALUOp        <= "10";

                ALUOutWrite  <= '1';


            ------------------------------------------------------------
            -- JAL
            --
            -- PC <- ALUOut
            -- ALUOut <- OldPC + 4
            ------------------------------------------------------------
            when JAL =>

                ALUSrcA      <= "01";
                ALUSrcB      <= "10";

                ALUOp        <= "00";

                ResultSrc    <= "00";

                PCUpdate     <= '1';

                ALUOutWrite  <= '1';


            ------------------------------------------------------------
            -- BEQ
            --
            -- Compare A and WriteData
            -- If equal, PC <- ALUOut
            ------------------------------------------------------------
            when BEQ =>

                ALUSrcA      <= "10";
                ALUSrcB      <= "00";

                ALUOp        <= "01";

                ResultSrc    <= "00";

                Branch       <= '1';


        end case;

    end process;

end behave;