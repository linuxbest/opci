// tb.v --- 
// 
// Filename: tb.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 三  2月  4 10:51:19 2009 (+0800)
// Version: 
// Last-Updated: 三  2月  4 20:07:34 2009 (+0800)
//           By: Hu Gang
//     Update #: 147
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// 
// 
// 

// Change log:
// 
// 
// 

// Copyright (C) 2008 Beijing Soul tech.

// Code:
`timescale 1ns / 1ps
module tb;

   // Signals of the PCI BUS
   reg reset;
   wire reset_w;
   reg dcm_rst;
   
   tri1 frame, irdy, trdy, stop, devsel, par;
   tri0 [31:0] ad;
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
   reg         clk = 1;
   always #7.5 clk = !clk;

   reg 	       clk48 = 1;
   always #10.4 clk48 = !clk48;

   //reg 	       DDR_CLK_N = 0;
   //always #(2.5) DDR_CLK_N = ~DDR_CLK_N;
   
   parameter dimm_delay = 2.3;	// 2.5
   // Outputs
   wire         DDR_CS0_L;
   wire         DDR_CS1_L;
   wire         DDR_CS2_L;
   wire         DDR_CS3_L;
   wire         DDR_CKE;
   wire         DDR_DIMM_RAS_L;
   wire         DDR_DIMM_CAS_L;
   wire         DDR_DIMM_WE_L;
   wire         DDR_DIMM_CKE0, DDR_DIMM_CKE1;
   wire         DDR_DIMM_CS_N0_7;
   wire         DDR_DIMM_CS_N8_15;
   wire         DDR_DIMM_CLK0_P;
   wire         DDR_DIMM_CLK0_N;
   wire         DDR_DIMM_CLK1_P;
   wire         DDR_DIMM_CLK1_N;   
   wire         DDR_DIMM_CLK2_P;
   wire         DDR_DIMM_CLK2_N;
   wire [1:0]   DDR_DIMM_BA;
   wire [11:0]  DDR_DIMM_ADDRESS;
   wire [2:0]   DDR_DIMM_SA;
   wire         DDR_DIMM_SCL;
   //Bidirs
   wire [63:0]  DDR_DIMM_DQ;
   wire [7:0]   DDR_DIMM_DQS;
   wire [7:0]   DDR_DIMM_DM;
   wire         DDR_DIMM_SDA;
   //wire [1:0]   DDR_DIMM_READ_EN_IN;

   pci_arbiter arb(clk, reset_w, frame, irdy, req, gnt);
   pci_master cpu(.CLK(clk), 
		  .RESET(reset_w),
		  .FRAME(frame),
		  .IRDY(irdy), 
		  .TRDY(trdy),
		  .STOP(stop), 
		  .DEVSEL(devsel),
		  .AD(ad), 
		  .C_BE(c_be),
		  .PAR(par),
		  .REQ(req[0]),
		  .GNT(gnt[0]),
		  .nIRQ(irq),
		  .PAR64(par64),
		  .AD64(ad64),
		  .C_BE64(c_be64),
		  .ACK64(ack64));
   
   top top ( .PCI_CLK(clk), 
	     .PCI_RSTn(reset_w),
	     .PCI_FRAMEn(frame), 
	     .PCI_IRDYn(irdy), 
	     .PCI_TRDYn(trdy),
	     .PCI_STOPn(stop),
	     .PCI_DEVSELn(devsel),
	     .PCI_IDSEL(ad[18]),
	     .PCI_AD(ad), 
	     .PCI_CBE(c_be), 
	     .PCI_PAR(par),
	     .PCI_REQn(req[1]),
	     .PCI_GNTn(gnt[1]),
	     .PCI_ACK64n(ack64),
	     .PCI_AD64(ad64),
	     .PCI_CBE64(c_be64),
	     .PCI_REQ64n(req64), 
	     .PCI_PAR64(par64),

	     .FCLK(clk48),
	     .dcm_rst(dcm_rst),
	     
	     // ddr 
	     .DDR_DIMM_RAS_L		(DDR_DIMM_RAS_L),
	     .DDR_DIMM_CAS_L		(DDR_DIMM_CAS_L),
	     .DDR_DIMM_WE_L		(DDR_DIMM_WE_L),
	     .DDR_DIMM_CKE0		(DDR_DIMM_CKE0),
	     .DDR_DIMM_CKE1		(DDR_DIMM_CKE1),
	     .DDR_DIMM_CS_N0_7		(DDR_DIMM_CS_N0_7),
	     .DDR_DIMM_CS_N8_15		(DDR_DIMM_CS_N8_15),
	     .DDR_DIMM_DM		(DDR_DIMM_DM[7:0]),
	     .DDR_DIMM_CLK0_P		(DDR_DIMM_CLK0_P),
	     .DDR_DIMM_CLK0_N		(DDR_DIMM_CLK0_N),
	     .DDR_DIMM_CLK1_P		(DDR_DIMM_CLK1_P),
	     .DDR_DIMM_CLK1_N		(DDR_DIMM_CLK1_N),
	     .DDR_DIMM_CLK2_P		(DDR_DIMM_CLK2_P),
	     .DDR_DIMM_CLK2_N		(DDR_DIMM_CLK2_N),
	     .DDR_DIMM_BA		(DDR_DIMM_BA[1:0]),
	     .DDR_DIMM_ADDRESS		(DDR_DIMM_ADDRESS[11:0]),
	     .DDR_DIMM_DQ		(DDR_DIMM_DQ[63:0]),
	     .DDR_DIMM_DQS		(DDR_DIMM_DQS[7:0]));

  ddr_dimm u_dimm(
		  .Dq(DDR_DIMM_DQ[63:0]),
		  .Dqs(DDR_DIMM_DQS),
		  .Addr({DDR_DIMM_ADDRESS[11:0]}),
		  .Ba(DDR_DIMM_BA),
		  .Clk0(DDR_DIMM_CLK0_N),
		  .Clk0_n(DDR_DIMM_CLK0_P),
		  .Clk1(DDR_DIMM_CLK1_N),
		  .Clk1_n(DDR_DIMM_CLK1_P),
		  .Clk2(DDR_DIMM_CLK2_N),
		  .Clk2_n(DDR_DIMM_CLK2_P),
		  .Cke0(DDR_DIMM_CKE0),
		  .Cke1(DDR_DIMM_CKE1),
		  .Ras_n(DDR_DIMM_RAS_L),
		  .Cas_n(DDR_DIMM_CAS_L),
		  .We_n(DDR_DIMM_WE_L),
		  .Dm(DDR_DIMM_DM),
		  .S0_n(DDR_DIMM_CS_N0_7),
		  .S1_n(DDR_DIMM_CS_N8_15)
		  );
   
   assign reset_w = reset;

   initial begin
      #10;
      glbl.GSR_int = 1'b1;
      glbl.GTS_int = 1'b1;
      #20;
      glbl.GSR_int = 1'b0;
      #20;
      glbl.GTS_int = 1'b0;
      #50;
      $dumpfile("tb.vcd");
      $dumpvars(0, tb);

      cpu.do_reset;
      

      dcm_rst = 0;
      repeat (10) @(posedge clk);
      dcm_rst = 1;
      repeat (10) @(posedge clk);
      dcm_rst = 0;

      reset = 1;            
      repeat (10) @(posedge clk);
      reset = 0;
      repeat (10) @(posedge clk);
      reset = 1;
      repeat (100) @(posedge clk);
      
      wait (tb.top.i_user.i_ddr.ddr_controller0.init_done);

      /* reading the device id */
      cpu.op[0] = {1'b1, 18'h0};
      cpu.do_config_read;
      if (cpu.res[0] != 32'h0001_1895) begin
	 $write("PCI: device id %x\n", cpu.res[0]);
	 $display("PCI: reading device id failed\n");
	 $stop;
      end

      cpu.op[2] = 32'h0;
      
      cpu.op[0] = {1'b1, 18'h4};// command and status
      cpu.do_config_read;
      cpu.op[1] = 2'b10;
      cpu.do_config_write;	// enable memory space
      
      cpu.op[0] = {1'b1, 18'h10};// command and status
      cpu.do_config_read;
      cpu.op[1] = 32'h0001_0000;
      cpu.do_config_write;
      
      cpu.op[0] = {1'b1, 18'h14};// command and status
      cpu.do_config_read;
      cpu.op[1] = 32'h0002_0000;
      cpu.do_config_write;

      // testing the bar0 
      cpu.op[0] = 32'h0001_0000;
      cpu.do_memory32_read32;
      if (cpu.res[0] != 32'h0001_1895) begin
	 $write("PCI: device id %x\n", cpu.res[0]);
	 $display("PCI: reading device id failed\n");
	 $stop;
      end
      
      cpu.op[0] = 32'h0002_0000;
      cpu.op[1] = 32'hAA55;
      cpu.do_memory32_write32;

      repeat (100) @(posedge clk);
      
      $finish;
   end
endmodule // tb
// Local Variables:
// verilog-library-directories:("." "/p/hw/lzs/encode/rtl/verilog" "/p/hw/lzs/decode/rtl/verilog/" "/p/hw/ssce2/usb-mcu/ledblink/rtl/" "../")
// verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// tb.v ends here
