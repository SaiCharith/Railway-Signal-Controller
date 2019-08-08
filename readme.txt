
Locations : 
--------------------------

fpga files :
-------------

1) 20140524/makestuff/hdlmake/libs/makestuff/comm-fpga/fx2/vhdl :- comm_fpga_fx2.vhdl

2) 20140524/makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl :- baudrate_gen.vhd, cksum_rtl.vhdl, encrypter.vhd, 				decrypter.vhd, uart_tx.vhd, uart_rx.vhd, network.txt, hdlmake.cfg, fpga_commands.sh

3) 20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/vhdl :- top_level.vhdl, debouncer.vhd, hdlmake.cfg

4) 20140524/makestuff/hdlmake/apps/makestuff/swled/templates :- harness.vhdl

5) 20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/boards/Atlys :- board.ucf

host files :
-------------------
1) 20140524/makestuff/apps/flcli :- main.c 

2) 20140524/makestuff/libs/libfpgalink :- libfpgalink.c

3) 20140524/makestuff/libs :- rec_make.sh

4) 20140524/makestuff/libs/libusbwrap :- libusbwrap.c



Running the code :
---------------------------

1) Synthesise and generate the bit file using the command "../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhd
	l -b atlys -p fpga" from cksum/vhdl directory.

2) Use the script "rec_make.sh" to compile all the library files.

3) Replace libfpgalink.so file in flcli/lin.x64/rel by the newly obtained version(after compilation) of the file from libs/libfpgalink/lin.x64/rel/

4) Replace libusbwrap.so file in flcli/lin.x64/rel by the newly obtained version(after compilation) of the file from libs/libusbwrap/lin.x64/rel/

5) Run "make deps" from flcli directory.

6) Use fpga_commands.sh script to initialise and program the fpga board.

7) Use command "sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -m -b" to execute the code.

Relay commands (for optional part) :-
---------------------------------------

1) sudo chmod 777 /dev/ttyXRUSB0
2) sudo chmod 777 /dev/ttyXRUSB1
3) sudo cat /dev/ttyXRUSB0 > /dev/ttyXRUSB1
4) sudo cat /dev/ttyXRUSB1 > /dev/ttyXRUSB0 (run commands 3 and 4 in seperate terminals)

For mandatory part of UART :-
-------------------------------

1) open gtkterm and run through it