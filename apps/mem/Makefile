
CVER_LIB=-y /p/hw/unisims/ -y ../../rtl/verilog/  -y /p/hw/XAPP708/verilog/
CVER_LIB+=-y /p/hw/ssce2/usb-mcu/ledblink/rtl/ -y .
CVER_LIB+=+libext+.v
CVER_LIB+=+incdir+../../rtl/verilog/+/p/hw/XAPP708/verilog/

all:
	cver ${CVER_LIB} top.v pci_wrapper.v glbl.v
