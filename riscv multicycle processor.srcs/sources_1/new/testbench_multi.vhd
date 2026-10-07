
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity testbench_multi is
end testbench_multi;


architecture test of testbench_multi is

    -- =========================================================
    -- DUT SIGNALS
    -- =========================================================

    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '1';

    signal WriteData : STD_LOGIC_VECTOR(31 downto 0);
    signal DataAdr   : STD_LOGIC_VECTOR(31 downto 0);
    signal MemWrite  : STD_LOGIC;

begin

    -- =========================================================
    -- DUT
    -- =========================================================

    dut : entity work.top_multi
        port map(
            clk       => clk,
            reset     => reset,
            WriteData => WriteData,
            DataAdr   => DataAdr,
            MemWrite  => MemWrite
        );


    -- =========================================================
    -- CLOCK GENERATION
    -- 10 ns period
    --
    -- 0 ns  : LOW
    -- 5 ns  : HIGH
    -- 10 ns : LOW
    -- =========================================================

    clock_process : process
    begin

        while true loop

            clk <= '0';
            wait for 5 ns;

            clk <= '1';
            wait for 5 ns;

        end loop;

    end process;


    -- =========================================================
    -- RESET GENERATION
    --
    -- Active HIGH reset
    --
    -- 0 ns  -> 20 ns : reset = 1
    -- 20 ns onward  : reset = 0
    -- =========================================================

    reset_process : process
    begin

        reset <= '1';

        report "==========================================";
        report " RISC-V MULTICYCLE PROCESSOR";
        report " LOAD WORD TEST";
        report "==========================================";

        report "Reset asserted";

        wait for 20 ns;

        reset <= '0';

        report "Reset released";
        report "Processor execution started";

        wait;

    end process;


    -- =========================================================
    -- MEMORY WRITE MONITOR
    --
    -- Test program:
    --
    -- addi x1, x0, 100
    -- addi x2, x0, 42
    -- sw   x2, 0(x1)
    -- lw   x3, 0(x1)
    -- sw   x3, 4(x1)
    -- beq  x0, x0, 0
    --
    -- Expected:
    --
    -- Memory[100] = 42
    -- Memory[104] = 42
    --
    -- The second store proves that lw correctly
    -- loaded 42 into x3.
    -- =========================================================

    monitor_process : process(clk)
    begin

        if falling_edge(clk) then

            if MemWrite = '1' then

                report "------------------------------------------";
                report "STORE DETECTED";

                report "Address = " &
                    integer'image(
                        to_integer(unsigned(DataAdr))
                    );

                report "Data = " &
                    integer'image(
                        to_integer(unsigned(WriteData))
                    );

                report "------------------------------------------";


                -- =================================================
                -- FIRST STORE
                --
                -- sw x2, 0(x1)
                --
                -- x1 = 100
                -- x2 = 42
                --
                -- Therefore:
                -- Memory[100] = 42
                -- =================================================

                if (DataAdr = x"00000064") and
                   (WriteData = x"0000002A") then

                    report "PASS: Setup store";
                    report "Memory[100] = 42"
                        severity note;


                -- =================================================
                -- FINAL STORE
                --
                -- sw x3, 4(x1)
                --
                -- x3 should contain the value loaded by lw.
                --
                -- x1 = 100
                -- offset = 4
                --
                -- Address = 104
                --
                -- Expected:
                -- Memory[104] = 42
                -- =================================================

                elsif (DataAdr = x"00000068") and
                      (WriteData = x"0000002A") then

                    report "==========================================";
                    report " LOAD WORD TEST PASSED";
                    report " Memory[100] = 42";
                    report " lw loaded 42 into x3";
                    report " Memory[104] = 42";
                    report "=========================================="
                        severity failure;


                -- =================================================
                -- ANY OTHER MEMORY WRITE
                -- =================================================

                else

                    report "==========================================";
                    report " ERROR: UNEXPECTED MEMORY WRITE";
                    report " Address = " &
                        integer'image(
                            to_integer(unsigned(DataAdr))
                        );
                    report " Data = " &
                        integer'image(
                            to_integer(unsigned(WriteData))
                        );
                    report "=========================================="
                        severity failure;

                end if;

            end if;

        end if;

    end process;


    -- =========================================================
    -- SIMULATION TIMEOUT
    --
    -- If the processor does not reach the expected
    -- final store within 5000 ns, stop the simulation.
    -- =========================================================

    timeout_process : process
    begin

        wait for 5000 ns;

        report "==========================================";
        report " ERROR: SIMULATION TIMEOUT";
        report " Processor did not complete LW test";
        report "=========================================="
            severity failure;

    end process;


end test;
