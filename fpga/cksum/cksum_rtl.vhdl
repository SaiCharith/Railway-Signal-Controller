--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
architecture rtl of swled is
	-- Flags for display on the 7-seg decimal points
	signal flags                   : std_logic_vector(3 downto 0);

	-- Registers implementing the channels
	signal val,val1 : std_logic_vector(63 downto 0) := (others => '0');
	signal reg        : std_logic_vector(7 downto 0)  := (others => '0');
	signal pos : std_logic_vector(3 downto 0)  := (others => '0');
	signal count : std_logic_vector(25 downto 0)  := (others => '0');

	signal state : std_logic_vector(3 downto 0) := "0000";
	signal mstate : std_logic_vector(2 downto 0) := "001";
	signal op : std_logic_vector(1 downto 0) := "00";
	signal vout : std_logic := '0';
	signal update : std_logic := '0';
	
	signal done1,done2 ,done3: std_logic := '0';
	signal it,it1,im1,im2 : std_logic_vector(2 downto 0) := "000";
	signal ctrpos,ctrack1,ctrmsg1,ctrmsg2,ctrack2 : std_logic_vector(2 downto 0) := "000";

	signal posack,msgack : std_logic_vector(31 downto 0) := (others => '0');
	signal posreply : std_logic_vector(31 downto 0) := (others => '1');

	
	signal trains : std_logic_vector(7 downto 0) := (others => '0');
	signal tc1 : std_logic_vector(25 downto 0)  := (others => '0');
	signal ns1 : std_logic_vector(8 downto 0) := (others => '0');
	signal time0 : std_logic_vector(3 downto 0) := "0000";
	
	signal resetD, resetE : std_logic := '1';
	signal enableE, enableD, doneE, doneD : std_logic := '0';
	signal PE,PD,CE,CD : std_logic_vector(31 downto 0) := (others => '0');

	signal upstate : std_logic_vector(2 downto 0) := "000";
	signal lstate : std_logic_vector(1 downto 0) := "00";
	-------------------------------------------------------UART signals
	signal sample : std_logic ;
	signal txstart: std_logic := '0';
    signal txdata : std_logic_vector(7 downto 0) := (others => '0');
	signal txdone : std_logic := '0'; --tx rdy to get new byte
	signal rxdone : std_logic := '0';
	signal rxdata, rcdata, rcdatanext : std_logic_vector(7 downto 0) :=(others => '0');
	signal got_data : std_logic := '0';
	signal tx_reset : std_logic := '1';
	signal start : std_logic := '0';
	--signal rth : std_logic_vector(1 downto 0) := "00";
	--------------------------------------------------------
	constant temp : std_logic_vector(24 downto 0)  := (others => '0');
	constant K1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000001"; 
	constant hardpos : std_logic_vector(7 downto 0) := "00100010";
	constant freq48mhz : std_logic_vector(25 downto 0) := "10110111000110110000000000";
	constant ack1 : std_logic_vector(31 downto 0) := "00000011000000100000000100000000";
	constant ack2 : std_logic_vector(31 downto 0) := "11111111111111111111111111111111";
	constant chanev : std_logic_vector(6 downto 0) := "0000010";
	constant chanod : std_logic_vector(6 downto 0) := "0000011";

	component encrypter
	port(
		clock : in STD_LOGIC;
		K : in std_logic_vector(31 downto 0);
		P : in std_logic_vector(31 downto 0);
		C : out std_logic_vector(31 downto 0);
		reset,enable : in std_logic;
		done : out std_logic
	);
	end component;
	component decrypter
	port(
		clock : in STD_LOGIC;
		K : in std_logic_vector(31 downto 0);
		C : in std_logic_vector(31 downto 0);
		P : out std_logic_vector(31 downto 0);
		reset,enable : in std_logic;
		done : out std_logic
	);
	end component;
	----------------------------uart comps

	component uart_tx 			
	port (clk    : in std_logic;
			rst    : in std_logic;
			txstart: in std_logic;
			sample : in std_logic;
			txdata : in std_logic_vector(7 downto 0);
			txdone : out std_logic;
			tx	    : out std_logic);
	end component uart_tx;

	component uart_rx is			
	port (clk	: in std_logic;
			rst	: in std_logic;
			rx		: in std_logic;
			sample: in STD_LOGIC;
			rxdone: out std_logic;
			rxdata: out std_logic_vector(7 downto 0));
	end component uart_rx;

	component baudrate_gen is
	port (clk	: in std_logic;
			rst	: in std_logic;
			sample: out std_logic);
	end component baudrate_gen;
	
	----------------------------

begin 
	i_brg : baudrate_gen port map (clk => clk_in, rst => tx_reset, sample => sample);
	i_tx : uart_tx port map( 
		clk => clk_in, rst => tx_reset,
		txstart => txstart,
		sample => sample, txdata => txdata,
		txdone => txdone, tx => myuart_tx);
	i_rx : uart_rx port map( clk => clk_in, rst => tx_reset,
		rx => myuart_rx, sample => sample,
		rxdone => rxdone, rxdata => rxdata);
---------------------------------
	encrypt : encrypter port map (
		clock => clk_in,
		K => K1,
		P => PE, 
		C => CE, 
		reset => resetE,
		enable => enableE,
		done => doneE 
	); 
	decrypt : decrypter port map (
		clock => clk_in,
		K => K1,
		C => CD, 
		P => PD, 
		done => doneD,
		reset => resetD,
		enable => enableD
	); 
	----------------------------
	
	                                                           
	process(clk_in)
	begin
		if ( rising_edge(clk_in)  ) then
			if ( reset_in = '1' ) then
				reg <= (others => '0');
				val <= (others => '0');
				pos <= (others => '0');
				count <= (others => '0');
				posreply <= (others => '0');posack <= (others => '0');
				msgack <= (others => '0');
				it <= (others => '0');it1 <= (others => '0');im1 <= (others => '0');
				im2 <= (others => '0');ctrpos <= (others => '0');ctrack1 <= (others => '0');
				ctrmsg1 <= (others => '0');ctrmsg2 <= (others => '0');ctrack2 <= (others => '0');
				state <= "0000";
				mstate <= "000";
				op <= "00";
				vout <= '0';
				resetE <= '1';
				enableE <= '0';
				resetD <= '1';
				enableD <= '0';
				lstate <= "00";
				tx_reset<='1';
				update <= '0';
				time0 <= "0000";
				--rth <= "00";
				got_data <= '0';
				rcdata <= (others => '0');
				rcdatanext <= (others => '0');
			else
				
				if (not(chanAddr_in = chanev) and chanAddr_in(0)='0') then
					vout <= '1';
				end if;

				------------------------other channels
				-- if rth = "00" then
				-- 	tx_reset <= '1';
				-- 	rth <= "01";
				-- else
				-- 	tx_reset <= '0';
				-- end if;

				if (mstate = "000") then                          -- reset lights  S1
					reg <= (others => '1');
					count <= count + (temp(24 downto 0)&"1");
					if(op = "10") then
						mstate <= "001"; 
						count <= (others => '0');
						op <= "00";
						reg <= (others => '0');
					end if;
					if(count = freq48mhz and not(op = "10")) then
						op <= op + "01";
						count <= (others => '0');
					end if;
				end if;

				if(mstate = "001") then                      -- S2
					if (state = "0000") then
						PE <= temp(23 downto 0) & hardpos;
						resetE<='0';
						enableE<='1';
					end if;
					if (chanAddr_in = chanev and state = "0000") then			
						if doneE = '1' then
							vout <= '1';
							f2hData_out <= CE(7 downto 0) ;
							it <= "001";
						else
							vout <= '0';
						end if;
					end if;
					if (chanAddr_in = chanev and state = "0000" and vout = '1') then  --state = "0000" :- sending coord
						if (it = "010" or it = "001" or it = "011")  and f2hReady_in = '1' then  
							f2hData_out <= CE(15 downto 8) ;
							it <= it + "001";
						end if;
					end if;
					if (it = "100") and state = "0000" then 
						state <= "0001";
						vout <= '0';
						tc1 <= (others => '0');
						ns1 <= (others => '0');
						resetE <= '1';
						enableE <= '0';
						tx_reset <= '0';                       ----- txreset (-- there)
						it <= "000";
					end if;
					------

					if (chanAddr_in = chanod and state = "0001") then 						--state = "0001" :- rec coord and timeout
						if (h2fValid_in = '1' and to_integer(unsigned(ctrpos)) < 4) then
							posreply <=  posreply(23 downto 0) & h2fData_in;
							ctrpos <= ctrpos + "001";
						end if;
					end if;
					if (ctrpos = "100") and state = "0001" then
						CD <= posreply; 
						resetD <= '0';
						enableD <= '1';
					end if;
					if (ctrpos = "100") and state = "0001" and doneD='1'then
						if PD(7 downto 0) = hardpos then 
							state <= "0010";
							tc1 <= (others => '0');
							ns1 <= (others => '0');
							resetD <= '1';
							enableD <= '0';
							ctrpos <= "000";
						else 
							if (ns1 = "10000000")  then
								state <= "0000";
								resetD <= '1';
								enableD <= '0';
								ctrpos <= "000";
							else 
								tc1 <= tc1 + (temp(24 downto 0)&"1");
							end if;
							if (tc1 = freq48mhz) then 
								ns1 <= ns1 + "000000001";
								tc1 <= (others => '0');
							end if;
						end if;	
										
					end if;
					----------------------------
					if state = "0010" then
						PE <= ack1;
						resetE <= '0';
						enableE <= '1';
					end if;
					if (chanAddr_in = chanev and state = "0010") then 						--state = "0010" :- sending ack1					
						if (doneE ='1') then
							vout <= '1';
							f2hData_out <= CE(7 downto 0);
							it1 <= "001";
						else
							vout <= '0';
						end if;
					end if;
					if (chanAddr_in = chanev and state = "0010" and vout = '1') then
						if (it1 = "010" or it1 = "001" or it1 = "011")  and f2hReady_in = '1' then    
							f2hData_out <= CE( 8*to_integer(unsigned(it1)) + 7 downto 8*to_integer(unsigned(it1)) ) ;
							it1 <= it1 + "001";
						end if;
					end if;
					if (it1 = "100") and state = "0010"  then 
						state <= "0011";
						vout <= '0';
						resetE <= '1';
						enableE <= '0';
						it1 <= "000";
					end if;
					----------------------------
					if (chanAddr_in = chanod and state = "0011") then 							--state = "0011":- rec ack2
						if (h2fValid_in = '1' and to_integer(unsigned(ctrack1)) < 4) then
							posack <= h2fData_in & posack(31 downto 8) ;
							ctrack1 <= ctrack1 + "001";
						end if;
					end if;

					if ctrack1 = "100" and state = "0011" then	
						CD <= posack;
						resetD <= '0';
						enableD <= '1';		
						if doneD = '1' and PD = ack2 then 
							state <= "0100";
							ctrack1 <= "000";
							tc1 <= (others => '0');
							ns1 <= (others => '0');
							resetD <= '1';
							enableD <= '0';
						else 
							if (ns1 = "10000000")  then								--# of sec = 256
								state <= "0000";
								resetD <= '1';
								enableD <= '0';
								ctrack1 <= "000";
							else 
								tc1 <= tc1 + (temp(24 downto 0)&"1");
							end if;
							if (tc1 = freq48mhz) then 
								ns1 <= ns1 + "000000001";
								tc1 <= (others => '0');
							end if;
						end if;
						
					end if;
				------------------------------------- Finished Position communication ---------------------------------

					if (chanAddr_in = chanod and state = "0100") then		--state = "0100":- recving 1st 4B data 
						if (h2fValid_in = '1' and to_integer(unsigned(ctrmsg1)) < 4) then
							val <=  h2fData_in & val(63 downto 8);
							ctrmsg1 <= ctrmsg1 + "001";
						end if;
					end if;
					if ctrmsg1 = "100" and state = "0100" then
						state <= "0101";
						PE <= ack1;
						resetE <= '0';
						enableE <= '1';
						ctrmsg1 <= "000";
					end if;
				----------------------------------
					if (chanAddr_in = chanev and state = "0101") then		--state = "0101":- sending ack1 in resp to 1st 4B data 
						if  doneE = '1' then
							vout <= '1';
							f2hData_out <= CE(7 downto 0);
							im1 <= "001";
						else
							vout <= '0';
						end if;
					end if;
				
					if (chanAddr_in = chanev and state = "0101" and vout = '1') then
						if (im1 = "010" or im1 = "001" or im1 = "011")  and f2hReady_in = '1' then  
							f2hData_out <= CE( 8*to_integer(unsigned(im1)) + 7 downto 8*to_integer(unsigned(im1)) ) ;
							im1 <= im1 + "001";
						end if;
					end if;
					if (im1 = "100") and state = "0101" then 
						state <= "0110";
						vout <= '0';
						resetE <= '1';
						enableE <= '0';
						im1 <= "000";
					end if;

	----------------first half received ; start receiving second half ----------------------------------

					if (chanAddr_in = chanod and state = "0110") then		--state = "0110":- recving 2nd 4B data 
						if (h2fValid_in = '1' and to_integer(unsigned(ctrmsg2)) < 4) then
							val <=  h2fData_in & val(63 downto 8);
							ctrmsg2 <= ctrmsg2 + "001";
						end if;
					end if;
					if ctrmsg2 = "100" and state = "0110" then
						state <= "0111";
						PE <= ack1;
						resetE <= '0';
						enableE <= '1';
						ctrmsg2 <= "000";
					end if;
					-----------------------------------------------------
					if (chanAddr_in = chanev and state = "0111") then		--state = "0111":- sending ack1 in resp to 2nd 4B data
						if doneE='1' then
							vout <= '1';
							f2hData_out <= CE(7 downto 0);
							im2 <= "001";
						else 
							vout <= '0';
						end if;
					end if;

					if (chanAddr_in = chanev and state = "0111" and vout = '1') then
						if (im2 = "010" or im2 = "001" or im2 = "011") and f2hReady_in = '1' then
							f2hData_out <= CE( 8*to_integer(unsigned(im2)) + 7 downto 8*to_integer(unsigned(im2)) ) ;
							im2 <= im2 + "001";
						end if;
					end if;
					if (im2 = "100") and state = "0111" then 
						state <= "1000";
						vout <= '0';
						resetE <= '1';
						enableE <= '0';
						im2 <= "000";
					end if;
	------------------- receive an ACK from host for one last time before display ------------------------
					if (chanAddr_in = chanod and state = "1000") then
						if (h2fValid_in = '1' and to_integer(unsigned(ctrack2)) < 4) then
							msgack <= h2fData_in & msgack(31 downto 8) ;
							ctrack2 <= ctrack2 + "001";
						end if;
						if (ctrack2 = "100") then
							CD <= msgack;
							resetD<='0';
							enableD<='1';
						end if;
					end if;
					if ctrack2 = "100" and state = "1000"  then
						if doneD = '1' and PD = ack2 then 
							state <= "1001";
							ctrack2 <= "000";
							tc1 <= (others => '0');
							ns1 <= (others => '0');
							resetD<='1';
							enableD<='0';
						else 
							if (ns1 = "10000000")  then
								state <= "0000";
								ctrack2 <= "000";
								resetD<='1';
								enableD<='0';
							else 
								tc1 <= tc1 + (temp(24 downto 0)&"1");
							end if;
							if (tc1 = freq48mhz) then 
								ns1 <= ns1 + "000000001";
								tc1 <= (others => '0');
							end if;
						end if;
						
					end if;
		------------------- Finished receiving signal message -----------------------------
					if (state="1001" ) then
						if done1='0' then
							CD <= val(63 downto 32);
							resetD <= '0';
							enableD <= '1';
							if (doneD = '1') then
								done1<='1';
								val1(63 downto 32) <= PD;
								resetD <= '1';
								enableD <= '0';
							end if;
						end if;
						if done2='0' and done1 ='1' then
							CD <= val(31 downto 0);
							resetD <= '0';
							enableD <= '1';
							if (doneD = '1') then
								done2<='1';
								val1(31 downto 0) <= PD;
								resetD <= '1';
								enableD <= '0';
							end if;
						end if;
						if done1 = '1' and done2 = '1' and done3 = '0' and update = '1' then
							val1(8*to_integer(unsigned(rcdatanext(5 downto 3))) +6 ) <=  val1(8*to_integer(unsigned(rcdatanext(5 downto 3))) +6 ) and rcdatanext(6);
							--val1(8*to_integer(unsigned(rcdatanext(5 downto 3))) +7 ) <=  val1(8*to_integer(unsigned(rcdatanext(5 downto 3))) +7 ) and rcdatanext(7);
							update <= '0';
							done3 <= '1';
						end if;
						if update = '0' then
							done3 <= '1';
						end if;
					end if;

					

		---------------------start displaying signals on leds --------------------------------
					if (state = "1001") then
						if (pos = "1000" and count = freq48mhz) then
							state <= "0000";
							mstate <= "010";
							rcdatanext <= (others => '0');
							resetE<= '1'; resetD<= '1';
							enableE <= '0'; enableD <= '0';
							pos <= "0000";
							op <= "00";
							done1 <= '0'; done2 <= '0';done3 <= '0';
							count <= (others => '0');
							vout<='0';
						end if;
						if (done1 = '1' and done2 = '1' and done3 = '1') then
							if (count=freq48mhz) then
								if to_integer(unsigned(pos)) < 8 then 
									if (op = "10") then 
										pos <= pos + "0001";
									end if;
									if (not(op="10")) then
										op<=op+"01";
									else 
										op <= "00";
									end if;
								end if;
								if(to_integer(unsigned(pos)) > 7) then
									reg <= (others => '0');
									pos <= pos + "0001";
								else
								reg(7 downto 5) <= val1(8*to_integer(unsigned(pos))+5 downto 8*to_integer(unsigned(pos))+3); -- dir
								reg(4 downto 3) <= "00"; 
								-- red
								reg(0) <= 	(val1(8*to_integer(unsigned(pos))+7) nand val1(8*to_integer(unsigned(pos))+6))   ---not ok or dne 
										or
												( trains(to_integer(unsigned(pos))) and trains(to_integer(unsigned(pos(2 downto 0)+"100")))  --trains in both dirs
											and 
													(not(pos(2))   --smaller dir
												or		
													(op(1) and not(op(0)) )) ) --3rd sec in GAR transition
										or
											not(trains(to_integer(unsigned(pos)))) ;  --no train
										
								-- amber
								reg(1) <= 	val1(8*to_integer(unsigned(pos))+7) and val1(8*to_integer(unsigned(pos))+6)   --TE and TOK  
										and		
										(		(trains(to_integer(unsigned(pos))) and trains(to_integer(unsigned(pos(2 downto 0)+"100"))) --trains in both dirs
												and pos(2) and op(0) and not(op(1)) ) 	--larger dir, 2nd sec in GAR trans
											or 
												( trains(to_integer(unsigned(pos))) and not(trains(to_integer(unsigned(pos(2 downto 0)+"100")))) --no train in opp dir 
												and not(val1(8*to_integer(unsigned(pos)) +1 )) and not(val1(8*to_integer(unsigned(pos)) +2 ))    -- next hop <= 1
												)
										); 

								-- green
								reg(2) <= 	val1(8*to_integer(unsigned(pos))+7) and val1(8*to_integer(unsigned(pos))+6) and  trains(to_integer(unsigned(pos)))  --TE and TOK, train exists
										 and
											(	( pos(2) and (op(1) nor op(0)) ) --larger dir, 1st sec of GAR
											  or 
												(	not(trains(to_integer(unsigned(pos(2 downto 0)+"100"))) ) --no train in opp 
												and 
													(val1(8*to_integer(unsigned(pos)) +1 ) or val1(8*to_integer(unsigned(pos)) +2 ) ) --next hop>1
												)
											);

								end if;
								count <= (others => '0');
								
							else 
								count <= count + (temp(24 downto 0)&"1");
							end if;
						else 
							pos <= "0000";
							reg <= (others => '0');	
						end if;
					end if;
				end if;
				
				if (mstate = "010") then					--S3	check up
					reg <= (others => '0');
					if (upstate = "000") then
						if (up = '1') then
							upstate <= "001";
						else
							upstate <= "100";
						end if;
					end if;
					if (upstate = "001" and down = '1') then    -- Encryption
						PE <= temp(23 downto 0) & sw_in;
						enableE <= '1';
						resetE <= '0';
						upstate <= "010";
					end if;
					if(upstate = "100") then
						PE <= ack1;
						enableE <= '1';
						resetE <= '0';
						upstate <= "010";
					end if;
					if (chanAddr_in = chanev and upstate = "010") then			--S3 sending data to host
						if doneE = '1' then
							vout <= '1';
							upstate <= "011";
							f2hData_out <= CE(7 downto 0) ;
							it <= "001";
						else
							vout <= '0';
						end if;
					end if;
					if (chanAddr_in = chanev and vout = '1' and upstate = "011") then  
						if (it = "010" or it = "001" or it = "011")  and f2hReady_in = '1' then 
							f2hData_out <= CE(8*to_integer(unsigned(it)) + 7 downto 8*to_integer(unsigned(it))) ;
							it <= it + "001";
						end if;
						if (it = "000")  then 													 
							f2hData_out <= CE(7 downto 0) ;
							it <= it + "001";
						end if;
					end if;
					if (it = "100") then 
						mstate <= "011";
						vout<= '0';
						resetE <= '1';
						enableE <= '0';
						upstate <= "000";
						it <= "000";
					end if;
				end if;

				if mstate="011" then                                 --S4 check for left
					if (lstate="00" ) then                              
						if left = '1' then
							lstate <= "01";
						else
							mstate <= "100";
						end if;
					end if;
					if (lstate = "01" and right='1') then            --S4 send data to neighbor through UART
						
						txstart <= '1';
						lstate <= "10";
					else
						txstart <= '0';
					end if;
					if lstate="10" and txdone='1' then
						txstart <= '0';
						lstate <= "00";
						mstate <= "100";
					end if;
				end if;

				if mstate="100" then                          --S5 receive data through uart
					if lstate = "00" then
						if got_data='1' then
							rcdatanext <= rcdata;
							update <= '1';
							reg <= rcdata;
						else
							update <= '0';
							reg <= "00000000";
						end if;
						lstate <= "01";
					end if;
					if lstate = "01" then
						mstate <= "101";
						lstate <= "00";
						got_data <= '0';
					end if;
				end if;	

				if mstate="101" then                       --S6 wait for 10 sec and go to S2
					if (time0 = "1010")  then
						mstate <= "001";
						time0 <= "0000";
						if start = '0' then 
							tx_reset <= '1';
						end if;
					else 
						tc1 <= tc1 + (temp(24 downto 0)&"1");
					end if;
					if (tc1 = freq48mhz) then 
						time0 <= time0 + "0001";
						tc1 <= (others => '0');
					end if;	
				end if ;
				
			end if;

			if ( tx_reset = '1' ) then                     -- receiving data through uart
				got_data<='0';
				rcdata<= (others=>'0');
			else				
				if got_data='0' then
					if rxdone='1' then
						got_data<='1';
						rcdata<=rxdata;
					end if;
				end if;
				if got_data='1' then
					if rxdone='1' then
						rcdata<=rxdata;
					end if;
				end if;
				-- if mstate="101" then
				-- 	got_data<='0';
				-- 	--rcdata<=(others=>'0');
				-- end if;
			end if;

		end if;
	end process;


	trains <= sw_in;
	txdata <= sw_in;
--	-- Select values to return for each channel when the host is reading
	-- Assert that there's always data for reading, and always room for writing
	f2hValid_out <= vout;
	h2fReady_out <= '1';  
	
	--END_SNIPPET(registers)
	-- LEDs and 7-seg display
	led_out <= reg;
	flags <= "00" & f2hReady_in & reset_in;
	seven_seg : entity work.seven_seg
		port map(
			clk_in     => clk_in,
			data_in    => val(15 downto 0),
			dots_in    => flags,
			segs_out   => sseg_out,
			anodes_out => anode_out
		);
end architecture;