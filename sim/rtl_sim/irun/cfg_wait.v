// cfg_wait.v --- 
// 
// Filename: cfg_wait.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 五 12月 12 14:18:02 2008 (+0800)
// Version: 
// Last-Updated: 五 12月 12 15:44:03 2008 (+0800)
//           By: Hu Gang
//     Update #: 18
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

module cfg_wait (/*AUTOARG*/
   // Outputs
   adio_in, c_term, c_ready,
   // Inputs
   reset, CLK, cfg_hit, cfg_vld, s_wrdn, s_data, s_data_vld,
   addr, adio_out
   );
   input reset;
   input CLK;

   input cfg_hit;
   input cfg_vld;
   
   input s_wrdn;
   input s_data;
   input s_data_vld;
   input [31:0] addr;

   output [31:0] adio_in;
   input [31:0]  adio_out;

   output 	 c_term;
   output 	 c_ready;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			c_ready;
   reg			c_term;
   // End of automatics
   
   reg 		 cfg_rd;
   reg 			cfg_wr;
   always @(posedge CLK or posedge reset)
     begin
	if (reset) begin
	   cfg_rd <= #1 1'b0;
	   cfg_wr <= #1 1'b0;
	end else if (cfg_hit) begin
	   cfg_rd <= #1 !s_wrdn;
	   cfg_wr <= #1  s_wrdn;
	end else if (!s_data) begin
	   cfg_rd <= #1 1'b0;
	   cfg_wr <= #1 1'b0;
	end
     end
   wire load = cfg_wr & s_data_vld & addr[7:2] == 6'h20;
   wire oe   = cfg_rd & s_data && addr[7:2] == 6'h20;
   reg [31:0] q;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  q <= #1 32'h0;
	else if (load)
	  q <= #1 adio_out;
     end
   assign adio_in = oe ? q : 32'hz;

   reg [3:0] cfg_timer;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  cfg_timer <= #1 4'h0;
	else if (cfg_vld)
	  cfg_timer <= #1 4'h0;
	else if (cfg_timer != 4'h0)
	  cfg_timer <= #1 cfg_timer - 4'h1;
     end

   wire blat_rdy = (cfg_timer <= 4'h4);
   wire user_cfg = addr[7:2] == 6'h20;
   wire terminate = (!user_cfg | blat_rdy) & s_data;

   always @(posedge CLK or posedge reset)
     begin
	if (reset) begin
	   c_ready <= #1 1'b0;
	   c_term  <= #1 1'b0;
	end else begin
	   c_ready <= #1 (cfg_rd | cfg_wr) & terminate;
	   c_term  <= #1 (cfg_rd | cfg_wr) & terminate;
	end
     end

endmodule // cfg_wait_target

// 
// cfg_wait.v ends here
