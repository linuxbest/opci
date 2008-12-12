// mem_target.v --- 
// 
// Filename: mem_target.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 五 12月 12 14:22:23 2008 (+0800)
// Version: 
// Last-Updated: 五 12月 12 16:32:29 2008 (+0800)
//           By: Hu Gang
//     Update #: 48
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

module mem_target (/*AUTOARG*/
   // Outputs
   adio_in, s_ready, s_term, s_abort,
   // Inputs
   reset, CLK, s_wrdn, pci_cmd, addr, base_hit, s_data,
   s_data_vld, addr_vld, adio_out
   );
   input reset;
   input CLK;

   input s_wrdn;
   input [15:0] pci_cmd;
   input [31:0] addr;
   input [7:0] 	base_hit;
   input 	s_data;
   input 	s_data_vld;
   input 	addr_vld;
   
   input [31:0] adio_out;
   output [31:0] adio_in;

   output 	 s_ready;
   output 	 s_term;
   output 	 s_abort;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			s_abort;
   reg			s_ready;
   reg			s_term;
   // End of automatics
   reg 		 bar_0_rd;
   reg 		 bar_0_wr;
   wire 	 optional;
   always @(posedge CLK or posedge reset)
     begin
	if (reset) begin
	   bar_0_rd <= #1 1'b0;
	   bar_0_wr <= #1 1'b0;
	end else if (base_hit[2]) begin
	   bar_0_rd <= #1 !s_wrdn & optional;
	   bar_0_wr <= #1  s_wrdn & optional;
	end else if (!s_data) begin
	   bar_0_wr <= #1 1'b0;
	   bar_0_rd <= #1 1'b0;
	end
     end // always @ (posedge CLK or posedge RST_I)

   assign optional = pci_cmd[15:0] == 16'h40 && addr[31:0] == 32'h4000_0000;
   wire load     = bar_0_wr & s_data_vld;
   wire oe       = bar_0_rd & s_data;
   reg [31:0] q;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  q <= #1 32'h0123_4567;
	else if (load)
	  q <= #1 adio_out;
     end
   assign adio_in = oe ? q : 32'hz;

   always @(posedge CLK)
     begin
	s_ready <= #1 1'b1;
	s_term  <= #1 1'b0;
	s_abort <= #1 1'b0;
     end

endmodule // mem_target

// 
// mem_target.v ends here
