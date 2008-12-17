// master_tb.v --- 
// 
// Filename: master_tb.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Áù 12ÔÂ 13 15:51:09 2008 (+0800)
// Version: 
// Last-Updated: ¶ş 12ÔÂ 16 09:33:33 2008 (+0800)
//           By: Hu Gang
//     Update #: 94
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

module master_tb (/*AUTOARG*/
   // Outputs
   adio_in, complete, m_ready, m_cbe, m_wrdn, request,
   requesthold,
   // Inputs
   CLK, reset, adio_out, m_data, m_data_vld, m_addr_n, csr
   );
   input CLK;
   input reset;

   input [31:0] adio_out;
   output [32:0] adio_in;
   input 	m_data;
   input 	m_data_vld;
   input 	m_addr_n;
   input [39:0] csr;
   
   output 	complete;
   output 	m_ready;
   output [3:0] m_cbe;
   output 	m_wrdn;
   output 	request;
   output 	requesthold;

   reg 		m_dataq;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  m_dataq <= #1 1'b0;
	else
	  m_dataq <= #1 m_data;
     end
   wire m_data_fell = ~m_data & m_dataq;

   reg 	fatal, retry;
   always @(posedge CLK or posedge reset)
     begin
	if (reset) begin
	   fatal <= #1 1'b0;
	   retry <= #1 1'b0;
	end else if (~m_addr_n) begin
	   fatal <= #1 1'b0;
	   retry <= #1 1'b0;
	end else if (m_data) begin
	   fatal <= #1 csr[39] || csr[38];
	   retry <= #1 csr[36];
	end
     end

   reg dir = 1'b0;
   reg start = 1'b0;
   reg [31:0] address;
   
   task start_enable;
      input cmd_dir;
      input [31:0] cmd_address;
      begin
	 start = 1;
	 dir   = cmd_dir;
	 address = cmd_address;
      end
   endtask // start
   
   parameter [2:0] 
		S_IDLE = 3'h0,
		S_REQ  = 3'h1,
		S_READ = 3'h2,
		S_WRITE= 3'h3,
		S_DEAD = 3'h4,
		S_DONE = 3'h5,
		S_RTY  = 3'h6;
   reg [2:0] c_state, n_state;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  c_state <= #1 S_IDLE;
	else
	  c_state <= #1 n_state;
     end

   always @(/*AS*/c_state or dir or fatal or m_data_fell
	    or retry or start)
     begin
	n_state = S_IDLE;
	
	case (c_state)
	  S_IDLE: if (start)
	    n_state = S_REQ;
	  
	  S_REQ: if (dir)
	    n_state = S_WRITE;
	  else
	    n_state = S_READ;
	  
	  S_WRITE: if (m_data_fell) begin
	     if (fatal)
	       n_state = S_DEAD;
	     else if (retry)
	       n_state = S_RTY;
	     else
	       n_state = S_DONE;
	  end else
	    n_state = S_WRITE;

	  S_READ:  if (m_data_fell) begin
	     if (fatal)
	       n_state = S_DEAD;
	     else if (retry)
	       n_state = S_RTY;
	     else
	       n_state = S_DONE;
	  end else
	    n_state = S_READ;
	  
	  S_RTY:  n_state = S_REQ;
	  S_DONE: n_state = S_IDLE;
	  S_DEAD: n_state = S_DEAD;
	endcase
     end
   
   reg m_ready;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  m_ready <= #1 1'b0;
	else 
	  m_ready <= #1 1'b1;
     end
   assign request = c_state == S_REQ;
   assign requesthold = 1'b0;

   wire [3:0] command = {3'b011, dir};
   wire [3:0] byte_enable = 4'b0000;
   
   wire       addr_oe = m_addr_n;

   assign m_cbe   = ~addr_oe ? command       : byte_enable;
   assign m_wrdn  = dir;

   reg 	      complete;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  complete <= #1 1'b0;
	else case (c_state)
	       S_REQ:   complete <= #1 1'b1;
	       S_READ:  complete <= #1 1'b1;
	       S_WRITE: complete <= #1 1'b1;
	       default: complete <= #1 1'b0;
	     endcase
     end // always @ (posedge CLK or posedge reset)

   wire load = c_state == S_READ & m_data_vld;
   wire oe   = c_state == S_WRITE & m_data;

   reg [31:0] q;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  q <= #1 32'h0;
	else if (load)
	  q <= #1 adio_out;
     end
   
   assign adio_in = ~addr_oe ? 32'hC000_0000 : 
		    oe ? q : 32'hz;   
endmodule // master_tb


// 
// master_tb.v ends here
