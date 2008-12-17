TBS = tb_sg tb_adma tpci tc
PCISIM?=/p/hw/pcisim/
OC_DIR?=../../rtl/verilog
LZFDMA?=/p/hw/lzs/kernel
LZS?=/p/hw/lzs
VPATH=../../rtl/verilog:$(PCISIM)/ver

TLSF_DIR = TLSF-2.4/src/
VPATH+=${TLSF_DIR}

all: ${TBS}

tb_sg: tb_sgr.v ben_sgr.v ss_sg.v
	iverilog -Wall -o $@ $^

tb_adma: tb_adma.v ben_adma.v dummy_spi.v 
	iverilog -Wall -o $@ $^ -y ../../rtl/verilog/

tpci: top.v pci_tb.v pci_arbiter.v  pci_master.v  pci_memory.v
	iverilog -DENCODE -DDECODE -Wall -y $(OC_DIR) -I $(OC_DIR) -y ../../rtl/verilog/ -y ${LZS}/encode/rtl/verilog -y ${LZS}/decode/rtl/verilog -y. -o $@ $^
trun: tpci tc
	vvp -M${PCISIM}/vpi/ -mpci tpci
trun0: tpci tc
	vvp -M${PCISIM}/vpi/ -mpci tpci +mem-retry-rate=4 +mem-discon-rate=8

tc: pci_test.c tlsf.c
	${CC} -g -o $@ -I${LZFDMA} -I${LZS} -I${TLSF_DIR} -I${PCISIM}/libpcisim/ -L${PCISIM}/libpcisim/ -lpcisim -Wl,-rpath,${PCISIM}/libpcisim $^

clean:
	rm -f ${TBS} *.vpp
