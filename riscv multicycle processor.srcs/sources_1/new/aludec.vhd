library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity aludec is
    port(
        opb5      : in  STD_LOGIC;
        funct3    : in  STD_LOGIC_VECTOR(2 downto 0);
        funct7b5  : in  STD_LOGIC;
        ALUOp     : in  STD_LOGIC_VECTOR(1 downto 0);
        ALUControl: out STD_LOGIC_VECTOR(2 downto 0)
    );
end aludec;


architecture behave of aludec is
begin

    process(opb5, funct3, funct7b5, ALUOp)
    begin

        case ALUOp is

            -- Memory instructions / address calculation
            -- and JAL: ADD
            when "00" =>
                ALUControl <= "000";

            -- BEQ: SUB
            when "01" =>
                ALUControl <= "001";

            -- R-type / I-type ALU operations
            when "10" =>

                case funct3 is

                    -- ADD / SUB
                    when "000" =>
                        if opb5 = '1' and funct7b5 = '1' then
                            ALUControl <= "001"; -- SUB
                        else
                            ALUControl <= "000"; -- ADD
                        end if;

                    -- SLT
                    when "010" =>
                        ALUControl <= "101";

                    -- AND
                    when "111" =>
                        ALUControl <= "010";

                    -- OR
                    when "110" =>
                        ALUControl <= "011";

                    when others =>
                        ALUControl <= "000";

                end case;

            when others =>
                ALUControl <= "000";

        end case;

    end process;

end behave;