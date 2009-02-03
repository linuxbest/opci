#CFLAGS += -DDEBUG -Wall -I../apps/ -I../opencores/
CFLAGS += -DDEBUG -I../apps/ -I../opencores/

#FILES = $(shell cat ../opci.lst) 
FILES += /p/hw/pcisim/ver/pci_memory.v
FILES += /p/hw/pcisim/ver/pci_master.v
FILES += /p/hw/pcisim/ver/pci_arbiter.v
FILES += pci_tb.v

all: opci ctest

opci: FORCE
	iverilog -DDEBUG  -o opci.vpp /p/hw/pcisim/ver/pci_memory.v /p/hw/pcisim/ver/pci_master.v /p/hw/pcisim/ver/pci_arbiter.v pci_tb.v -y ../ -y /p/hw/unisims/ -y /p/hw/ssce2/usb-mcu/ledblink/rtl/ -y ../../../rtl/verilog/ -v -I ../../../rtl/verilog/ ../glbl.v

run: opci ctest 
	vvp -M/p/hw/pcisim/vpi/ -mpci opci.vpp

ctest: pci_test.c
	${CC} -g -o $@ -I/p/hw/pcisim/libpcisim/ $< -L/p/hw/pcisim/libpcisim/ -lpcisim -Wl,-rpath,/p/hw/pcisim/libpcisim 

FORCE:

clean:
	rm -f ctest *.vpp *.vcd *.bin *_fifo* 
