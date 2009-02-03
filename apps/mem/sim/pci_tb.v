`timescale 1ns / 1ps

module main;

   // Signals of the PCI BUS
   wire reset;
   tri1 frame, irdy, trdy, stop, devsel, par;
   tri1 [31:0] ad;
   tri1 [3:0]  c_be;
   tri1 [3:0]  req;
   wire [3:0]  gnt;
   wire [15:0] irq;

   tri1 [31:0] ad64;
   tri1 [3:0]  c_be64;
   tri1        req64;
   tri1        ack64;
   tri1        par64;

   /* 66MHZ */
   reg 	       clk = 1;
   always #7.5 clk = !clk;

   // This is the system arbiter.
   pci_arbiter arb(clk, reset, frame, irdy, req, gnt);
   
   // This is the device that talks to the host operating system.
   pci_master cpu(.CLK(clk), .RESET(reset),
		  .FRAME(frame), .IRDY(irdy), .TRDY(trdy),
		  .STOP(stop), .DEVSEL(devsel),
		  .AD(ad), .C_BE(c_be), .PAR(par),
		  .REQ(req[0] ), .GNT(gnt[0]),
		  .nIRQ(irq), .PAR64(par64), .AD64(ad64), .C_BE64(c_be64),
                  .ACK64(ack64));

   // Need a memory device to act as a target.
   pci_memory #(.BAR0_MASK(32'hf0000000), .RETRY_RATE(0), .DISCON_RATE(0)) 
     mem1 (.CLK(clk), .RESET(reset),
	   .FRAME(frame), .IRDY(irdy), .TRDY(trdy),
	   .STOP(stop), .DEVSEL(devsel), .IDSEL(ad[17]),
	   .AD(ad), .C_BE(c_be), .PAR(par), .PAR64(par64),
	   .AD64(ad64), .C_BE64(c_be64), 
	   .REQ64(req64),
	   .ACK64(ack64)
	   );

   wire [7:0] usb_d;
   wire usb_fwrn;
   wire spi_sel;
   top
     lzf (.PCI_CLK(clk), .PCI_RSTn(reset),
	  .PCI_FRAMEn(frame), .PCI_IRDYn(irdy), .PCI_TRDYn(trdy),
	  .PCI_STOPn(stop), .PCI_DEVSELn(devsel), .PCI_IDSEL(ad[18]),
	  .PCI_AD(ad), .PCI_CBE(c_be), .PCI_PAR(par),
	  .PCI_REQn(req[1]), .PCI_GNTn(gnt[1]), .PCI_ACK64n(ack64),
	  .PCI_AD64(ad64), .PCI_CBE64(c_be64),
	  .PCI_REQ64n(req64), .PCI_PAR64(par64));

   assign usb_d = 0;
   assign usb_fwrn = 0;
   assign spi_sel = 0;
   initial begin
#10;
      glbl.GSR_int = 1'b1;
      glbl.GTS_int = 1'b1;
#20;
      glbl.GSR_int = 1'b0;
#20;
      glbl.GTS_int = 1'b0;
#50;
      $display("DONE");
      $dumpfile("pci.vcd");
      $dumpvars(0, main);
   end
  
endmodule
