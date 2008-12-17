`timescale 1ns / 1ps

module main;

   // Signals of the PCI BUS
   wire reset;
   tri1 frame, irdy, trdy, stop, devsel, par;
   wire [31:0] ad;
   wire [3:0]  c_be;
   /*wire*/tri1 [3:0]  req;
   wire [3:0]  gnt;
   tri0 [15:0] irq;

   wire [31:0] ad64;
   wire [3:0]  c_be64;
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
   top top (.CLK(clk),
	    .RST(reset),
	    .FRAME(frame),
	    .IRDY(irdy),
	    .TRDY(trdy),
	    .STOP(stop),
	    .DEVSEL(devsel),
	    .IDSEL(ad[18]),
	    .AD(ad),
	    .CBE(c_be),
	    .PAR(par),
	    .REQ(req[1]),
	    .GNT(gnt[1]),
	    .AD64(ad64),
	    .CBE64(c_be64),
	    .REQ64(req64),
	    .PAR64(par64),
	    .INTA(irq[0]));
   
   assign usb_d = 0;
   assign usb_fwrn = 0;
   assign spi_sel = 0;

   reg 	started = 0;
   
   initial begin
      $dumpfile("pci.vcd");
      $dumpvars(0, top);
      started = 1;
   end

   always @(posedge clk) begin
      if (top.mem_target.q == 32'haa55) begin
	 top.mem_target.q = 32'haa66;
	 top.master_tb.start_enable(0, 32'ha000_0000);
      end
   end
   
endmodule
