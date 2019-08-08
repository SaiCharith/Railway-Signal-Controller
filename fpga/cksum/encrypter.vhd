----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:39:24 01/23/2018 
-- Design Name: 
-- Module Name:    encrypter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity encrypter is
    Port ( clock : in  STD_LOGIC;
           K : in  STD_LOGIC_VECTOR (31 downto 0);
           P : in  STD_LOGIC_VECTOR (31 downto 0);
           C : out  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           reset : in  STD_LOGIC;
           enable : in  STD_LOGIC;
			  done : out std_logic);
end encrypter;

architecture Behavioral of encrypter is
	signal T: STD_LOGIC_VECTOR (3 downto 0);
	signal N1 : STD_LOGIC_VECTOR (5 downto 0); -- Nin is used to get value from n1.vhd and assign it to N1
	signal Ct : STD_LOGIC_VECTOR (31 downto 0);    -- Temporary storage for C
	signal initial : std_logic := '0' ;            -- Represent state changes, one for initialization and other for normal computation
begin
   process(clock, reset, enable)
	 begin
		if (reset = '1') then
			C <= "00000000000000000000000000000000";
			initial <= '0';
			done <= '0';
			T <= "0000";
			N1 <= "000000";
			Ct <= "00000000000000000000000000000000";
		elsif (clock'event and clock = '1' and enable = '1') then  
			if ( initial = '0') then            -- initialization of T, N1, Ct
				done <= '0';
				N1 <= ("0"&(("0"&(("0"&(("0"&(("0"&K(0))+("0"&K(1))))+("0"&(("0"&K(2))+("0"&K(3))))))+
				("0"&(("0"&(("0"&K(4))+("0"&K(5))))+("0"&(("0"&K(6))+("0"&K(7))))))))+
				("0"&(("0"&(("0"&(("0"&K(8))+("0"&K(9))))+("0"&(("0"&K(10))+("0"&K(11))))))+
				("0"&(("0"&(("0"&K(15))+("0"&K(14))))+("0"&(("0"&K(13))+("0"&K(12))))))))))+
				("0"&(("0"&(("0"&(("0"&(("0"&K(16))+("0"&K(17))))+("0"&(("0"&K(18))+("0"&K(19))))))+
				("0"&(("0"&(("0"&K(23))+("0"&K(22))))+("0"&(("0"&K(21))+("0"&K(20))))))))+
				("0"&(("0"&(("0"&(("0"&K(24))+("0"&K(25))))+("0"&(("0"&K(26))+("0"&K(27))))))+
				("0"&(("0"&(("0"&K(31))+("0"&K(30))))+("0"&(("0"&K(29))+("0"&K(28)))))))))) ;
				T(0) <= K(0) xor K(4) xor K(8) xor K(12) xor K(16) xor K(20) xor K(24) xor K(28); 
				T(1) <= K(1) xor K(5) xor K(9) xor K(13) xor K(17) xor K(21) xor K(25) xor K(29);  
				T(2) <= K(2) xor K(6) xor K(10) xor K(14) xor K(18) xor K(22) xor K(26) xor K(30); 
				T(3) <= K(3) xor K(7) xor K(11) xor K(15) xor K(19) xor K(23) xor K(27) xor K(31); 
				Ct <= P;
				initial <= '1';
			else
				if ( not (N1 = "000000")) then  -- for looping
					Ct <= Ct xor (T & T & T & T & T & T & T & T);
					N1 <= N1 + "111111";
					T <= T + "0001";                                                              
				else                              -- termination of for loop
					C <= Ct;
					done <= '1';
				end if;
			end if;		 
		end if;	
			
	 end process;

end Behavioral;
