// master_behavioral.v --- 
// 
// Filename: master_behavioral.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二 12月 16 09:25:42 2008 (+0800)
// Version: 
// Last-Updated: 二 12月 16 11:50:54 2008 (+0800)
//           By: Hu Gang
//     Update #: 175
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

module master_behavioral (/*AUTOARG*/
   // Outputs
   adio_in, complete, m_ready, m_cbe, m_wrdn, request,
   requesthold,
   // Inputs
   CLK, reset, adio_out, m_data, m_data_vld, m_addr_n,
   m_src_en, csr
   );
   input CLK;
   input reset;

   input [31:0] adio_out;
   output [32:0] adio_in;
   input 	m_data;
   input 	m_data_vld;
   input 	m_addr_n;
   input 	m_src_en;
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
   reg [31:2] address;
   
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
	     else if (burst_done)
	       n_state = S_DONE;
	     else
	       n_state = S_WRITE;
	  end else
	    n_state = S_WRITE;

	  S_READ:  if (m_data_fell) begin
	     if (fatal)
	       n_state = S_DEAD;
	     else if (retry)
	       n_state = S_RTY;
	     else if (burst_done)
	       n_state = S_DONE;
	     else
	       n_state = S_READ;
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

   reg 	      burst_done = 1;
   reg 	      complete;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  complete <= #1 1'b0;
	else case (c_state)
	       S_REQ:   complete <= #1 burst_done;
	       S_READ:  complete <= #1 burst_done;
	       S_WRITE: complete <= #1 burst_done;
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
   
   assign adio_in = ~addr_oe ? {address, 2'b00} : 
		    oe ? q : 32'hz;

   reg `WRITE_STIM_TYPE blk_write_data [0:(`MAX_BLK_SIZE-1)];

   task block_write;
      input  `WB_TRANSFER_FLAGS write_flags ;
      inout  `WRITE_RETURN_TYPE return ;
      
      reg    in_use ;
      reg    `WRITE_STIM_TYPE  current_write ;
      reg    cab ;
      reg    ok ;
      integer cyc_count ;
      integer rty_count ;
      reg     end_blk ;
      reg [2:0] use_cti    ;
      reg [1:0] use_bte    ;

      reg [31:0] t_address;
      
      begin: main
	 return`CYC_ACTUAL_TRANSFER = 0;
	 rty_count = 0;

	 if (in_use === 1) begin
	    $display("*E: master: block_write routine re-entered! Time %t ", $time);
	    return `TB_ERROR_BIT = 1'b1;
	    disable main;
	 end

	 if (write_flags`WB_TRANSFER_SIZE > `MAX_BLK_SIZE)
	   begin
	      $display("*E, number of transfers passed to wb_block_write routine exceeds defined maximum transaction length! Time %t", $time) ;
	      
	      return`TB_ERROR_BIT = 1'b1 ;
	      disable main ;
	   end

	 in_use = 1;
	 retry  = 1;
	 burst_done = 0;
	 
	 while (retry === 1) begin
	    @(posedge CLK)
	      if (c_state == S_IDLE)
		retry = 0;
	 end
	 
	 current_write = blk_write_data[0] ;
	 
	 start   = 1;
	 dir     = 1;
	 t_address = current_write`WRITE_ADDRESS;
	 address[31:2] = t_address[31:2];
	 
	 @(posedge CLK);
	 start = 0;
	 
	 @(posedge CLK);
	 if (c_state == S_REQ) begin
	    retry = 0;
	 end else begin
	    $display("*E: Failed to initialize cycle! Routine master block write, Time %t ", 
		     $time) ;
	    return `TB_ERROR_BIT = 1'b1;
	 end

	 cyc_count = write_flags`WB_TRANSFER_SIZE;
	 while (cyc_count > 0) begin
	    @(posedge CLK);
	    if (m_data_vld)
	      cyc_count = cyc_count - 1;
	 end
	 burst_done = 1;
	 
      end
      
   endtask // block_write
   
   task single_read;
      input [31:0] target_address;
      inout 	   `READ_RETURN_TYPE return;
      input [2:0]  init_wait;
      
      reg 	   in_use;
      reg 	   ok;
      reg 	   retry;
      
      begin : main
	 if (in_use === 1) begin
	    $display("*E: master: single_read routine re-entered! Time %t ", $time);
	    return `TB_ERROR_BIT = 1'b1;
	    disable main;
	 end
	 
	 in_use = 1;
	 retry  = 1;
	 return `CYC_ACTUAL_TRANSFER = 0;
	 while (retry === 1) begin
	    @(posedge CLK)
	      if (c_state == S_IDLE)
		retry = 0;
	 end
	 
	 start   = 1;
	 dir     = 0;
	 address[31:2] = target_address[31:2];
	 @(posedge CLK);
	 start = 0;
	 
	 @(posedge CLK);
	 if (c_state == S_REQ) begin
	    retry = 0;
	 end else begin
	    $display("*E: Failed to initialize cycle! Routine master single read, Time %t ", 
		     $time) ;
	    return `TB_ERROR_BIT = 1'b1;
	 end
	 
	 @(posedge load);
	 return `READ_DATA = adio_out;
	 @(posedge c_state == S_DONE);
	 return `CYC_ACTUAL_TRANSFER = 1;
	 
	 in_use = 0;
      end
   endtask // single_read
   
   task single_write;
      input [31:0] target_address;
      input [31:0] write_data;
      inout	   `WRITE_RETURN_TYPE return;
      input [2:0]  init_wait;
      
      reg 	   in_use;
      reg 	   ok;
      reg 	   retry;
      
      begin: main
	 if (in_use === 1) begin
	    $display("*E: master: single_write routine re-entered! Time %t ", $time);
	    return `TB_ERROR_BIT = 1'b1;
	    disable main;
	 end

	 in_use = 1;
	 retry  = 1;
	 q = write_data;
	 return `CYC_ACTUAL_TRANSFER = 0;
	 while (retry === 1) begin
	    @(posedge CLK)
	    if (c_state == S_IDLE)
	      retry = 0;
	 end
	 
	 start   = 1;
	 dir     = 1;
	 address[31:2] = target_address[31:2];
	 @(posedge CLK);
	 start = 0;

	 @(posedge CLK);
	 if (c_state == S_REQ) begin
	    retry = 0;
	 end else begin
	    $display("*E: Failed to initialize cycle! Routine master single write, Time %t ", 
		     $time) ;
	    return `TB_ERROR_BIT = 1'b1;
	 end
	 
	 @(posedge c_state == S_DONE);
	 return `CYC_ACTUAL_TRANSFER = 1;
	 
	 in_use = 0;
      end
      
   endtask // single_write

endmodule // master_behavioral

// 
// master_behavioral.v ends here
