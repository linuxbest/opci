// master_behavioral.v --- 
// 
// Filename: master_behavioral.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二 12月 16 09:25:42 2008 (+0800)
// Version: 
// Last-Updated: 二 12月 16 17:08:00 2008 (+0800)
//           By: Hu Gang
//     Update #: 364
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

   reg [3:0] burst_length = 1;
   reg [3:0] xfer_cnt;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  xfer_cnt <= #1 4'h0;
	else if (start)
	  xfer_cnt <= #1 burst_length;
	else if (m_data_vld)
	  xfer_cnt <= #1 xfer_cnt - 1;
     end

   wire done = (xfer_cnt == 4'h0);
   
   reg dir = 1'b0;
   reg start = 1'b0;
   reg [31:2] address;
   reg [31:0] start_addr;
   wire       back_up;
   
   parameter [2:0] 
		S_IDLE = 3'h0,
		S_REQ  = 3'h1,
		S_READ = 3'h2,
		S_WRITE= 3'h3,
		S_DEAD = 3'h4,
		S_OOPS = 3'h5;
   
   reg [2:0] c_state, n_state;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  c_state <= #1 S_IDLE;
	else
	  c_state <= #1 n_state;
     end

   always @(/*AS*/back_up or c_state or dir or done or fatal
	    or m_data_fell or start)
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
	     else
	       n_state = S_OOPS;
	  end else
	    n_state = S_WRITE;

	  S_READ:  if (m_data_fell) begin
	     if (fatal)
	       n_state = S_DEAD;
	     else
	       n_state = S_OOPS;
	  end else
	    n_state = S_READ;
	  
	  S_DEAD: n_state = S_DEAD;

	  S_OOPS: if (back_up)
	    n_state = S_OOPS;
	  else if (done)
	    n_state = S_IDLE;
	  else
	    n_state = S_IDLE;
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

   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  address <= #1 32'h0;
	else if (start)
	  address <= #1 start_addr[31:2];
	else if (m_data_vld)
	  address <= #1 address + 30'h1;
     end
   
   wire [3:0] command = {3'b011, dir};
   wire [3:0] byte_enable = 4'b0000;
   
   wire       addr_oe = m_addr_n;

   wire       oe;
   wire [31:0] src_do;
   
   assign m_cbe   = ~addr_oe ? command       : byte_enable;
   assign m_wrdn  = dir;
   assign adio_in = ~addr_oe ? {address, 2'b00} : 
		    oe ? src_do : 32'hz;

   wire        cnt3 = xfer_cnt == 4'h3;
   wire        cnt2 = xfer_cnt == 4'h2;
   wire        cnt1 = xfer_cnt == 4'h1;
   
   wire        fin1 = cnt1 & request;
   wire        fin2 = cnt2 & m_dataq;
   wire        fin3 = cnt3 & m_data_vld;
   wire        assert_complete = fin1 | fin2 | fin3;

   reg 	       hold_complete;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  hold_complete <= #1 1'b0;
	else if (m_data_fell)
	  hold_complete <= #1 1'b0;
	else if (assert_complete)
	  hold_complete <= #1 1'b1;
     end
   assign complete = assert_complete | hold_complete;

   wire te;			// total empty
   wire tf;			// total full
   wire ae;
   wire af;
   
   wire anticipated = m_src_en && (!te);
   reg [2:0] oops;
   always @(posedge CLK or posedge reset)
     begin
	if (reset)
	  oops <= #1 2'b00;
	else case({anticipated, m_data_vld, back_up, oops})
	       5'b00000: oops <= #1 2'b00;
	       5'b00001: oops <= #1 2'b01;
	       5'b00010: oops <= #1 2'b10;
	       5'b00011: oops <= #1 2'b11;
	       5'b00100: oops <= #1 2'b00;
	       5'b00101: oops <= #1 2'b00;
	       5'b00110: oops <= #1 2'b01;
	       5'b00111: oops <= #1 2'b10;
	       
	       5'b01000: oops <= #1 2'b00;
	       5'b01001: oops <= #1 2'b00;
	       5'b01010: oops <= #1 2'b01;
	       5'b01011: oops <= #1 2'b10;
	       5'b01100: oops <= #1 2'b00;
	       5'b01101: oops <= #1 2'b00;
	       5'b01110: oops <= #1 2'b00;
	       5'b01111: oops <= #1 2'b01;

	       5'b10000: oops <= #1 2'b01;
	       5'b10001: oops <= #1 2'b10;
	       5'b10010: oops <= #1 2'b11;
	       5'b10011: oops <= #1 2'b11;
	       5'b10100: oops <= #1 2'b00;
	       5'b10101: oops <= #1 2'b01;
	       5'b10110: oops <= #1 2'b10;
	       5'b10111: oops <= #1 2'b11;
	       
	       5'b11000: oops <= #1 2'b00;
	       5'b11001: oops <= #1 2'b01;
	       5'b11010: oops <= #1 2'b10;
	       5'b11011: oops <= #1 2'b11;
	       5'b11100: oops <= #1 2'b00;
	       5'b11101: oops <= #1 2'b00;
	       5'b11110: oops <= #1 2'b01;
	       5'b11111: oops <= #1 2'b10;

	       default:  oops <= #1 2'b00;
	     endcase // case ({anticipated, m_data_vld, back_up, oops})
     end
   assign back_up = (|oops) & (c_state == S_OOPS);

   parameter ADDR_LENGTH = 5;

   reg [31:0] src_di;
   reg 	      wenable_in = 0;
   
   wire [ADDR_LENGTH-1:0] waddr_out;
   wire [ADDR_LENGTH-1:0] raddr_out;
   wire almost_full_out;
   wire almost_empty_out;
   wire full_out;
   wire empty_out;
   wire rallow_out;
   wire wallow_out;
   wire three_left_out;
   wire two_left_out;
   wire renable_in;
   //wire wenable_in;
   
   wire reset_in = reset;
   wire rclock_in = CLK;
   wire wclock_in = CLK;
   wire clear_in = reset_in;
   
   fifo_control fifo_control (/*AUTOINST*/
			      // Outputs
			      .almost_full_out	(almost_full_out),
			      .almost_empty_out	(almost_empty_out),
			      .full_out		(full_out),
			      .empty_out	(empty_out),
			      .waddr_out	(waddr_out[(ADDR_LENGTH-1):0]),
			      .raddr_out	(raddr_out[(ADDR_LENGTH-1):0]),
			      .rallow_out	(rallow_out),
			      .wallow_out	(wallow_out),
			      .three_left_out	(three_left_out),
			      .two_left_out	(two_left_out),
			      .half_full_out	(half_full_out),
			      // Inputs
			      .rclock_in	(rclock_in),
			      .wclock_in	(wclock_in),
			      .renable_in	(renable_in),
			      .wenable_in	(wenable_in),
			      .reset_in		(reset_in),
			      .clear_in		(clear_in));

   tpram tpram (.clk_a(CLK),
		.rst_a(reset),
		.ce_a(1'b1),
		.oe_a(1'b1),
		.we_a(wallow_out),
		.addr_a(waddr_out),
		.di_a(src_di),
		.do_a(),
		
		.clk_b(CLK),
		.rst_b(reset),
		.ce_b(1'b1),
		.oe_b(1'b1),
		.we_b(1'b0),
		.addr_b(raddr_out),
		.di_b(),
		.do_b(src_do));
   
   defparam fifo_control.ADDR_LENGTH = ADDR_LENGTH;
   defparam tpram.aw                 = ADDR_LENGTH;
   defparam tpram.dw                 = 32;

   //assign wenable_in = (c_state == S_READ) & m_data_vld;
   assign renable_in = (c_state == S_WRITE) & m_src_en;
   assign oe         = (c_state == S_WRITE) & m_data;

   assign te = empty_out;
   assign ae = almost_empty_out;
   assign tf = full_out;
   assign af = almost_full_out;
   
   reg `WRITE_STIM_TYPE blk_write_data [0:(`MAX_BLK_SIZE-1)];
   reg `READ_STIM_TYPE  blk_read_data  [0:(`MAX_BLK_SIZE-1)];
   reg `READ_RETURN_TYPE blk_read_data_out [0:(`MAX_BLK_SIZE-1)];
   
   task block_read;
      input `WB_TRANSFER_FLAGS read_flags;
      inout `READ_RETURN_TYPE  return;

      reg   in_use ;
      reg   `READ_STIM_TYPE  current_read ;
      reg    cab ;
      reg    ok ;
      integer cyc_count ;
      integer rty_count ;
      reg     end_blk ;
      reg [2:0] use_cti    ;
      reg [1:0] use_bte    ;

      reg [31:0] t_address;
      reg 	 `READ_RETURN_TYPE t_data;
      
      integer 	 i;
      begin: main
	 return`CYC_ACTUAL_TRANSFER = 0;
	 rty_count = 0;

	 if (in_use === 1) begin
	    $display("*E: master: block_read routine re-entered! Time %t ", $time);
	    return `TB_ERROR_BIT = 1'b1;
	    disable main;
	 end

	 if (read_flags`WB_TRANSFER_SIZE > `MAX_BLK_SIZE)
	   begin
	      $display("*E, number of transfers passed to wb_block_read routine exceeds defined maximum transaction length! Time %t", $time) ;
	      
	      return`TB_ERROR_BIT = 1'b1 ;
	      disable main ;
	   end
	 
	 in_use = 1;
	 retry  = 1;
	 
	 while (retry === 1) begin
	    @(posedge CLK)
	      if (c_state == S_IDLE)
		retry = 0;
	 end

	 cyc_count = read_flags`WB_TRANSFER_SIZE;
	 burst_length = cyc_count;
	 
	 current_read = blk_read_data[0] ;
	 start   = 1;
	 dir     = 0;
	 start_addr = current_read`WRITE_ADDRESS;
	 
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

	 cyc_count = read_flags`WB_TRANSFER_SIZE;
	 i = 0;
	 while (cyc_count > 0) begin
	    @(posedge CLK);
	    if (m_data_vld) begin
	       cyc_count = cyc_count - 1;
	       t_data`READ_DATA = adio_out;
	       blk_read_data_out[i] = t_data;
	       i = i + 1;
	       /*$write("%h, %h\n", adio_out, i);*/
	    end
	 end
	 
	 @(posedge c_state == S_OOPS);
	 return `CYC_ACTUAL_TRANSFER = read_flags`WB_TRANSFER_SIZE - cyc_count;
	 
	 in_use = 0;	 
      end
   endtask // block_read
   
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

      integer 	 i;
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
	 //burst_done = 0;
	 cyc_count = write_flags`WB_TRANSFER_SIZE;
	 burst_length = cyc_count;
	 i = 0;
	 while (cyc_count > 0) begin
	    @(posedge CLK);
	    wenable_in = 1'b1;
	    current_write = blk_write_data[i];
	    src_di = current_write`WRITE_DATA;
	    cyc_count = cyc_count - 1;
	    i = i + 1;
	    @(posedge CLK);
	    wenable_in = 1'b0;
	    src_di = 32'hz;
	 end
	 
	 while (retry === 1) begin
	    @(posedge CLK)
	      if (c_state == S_IDLE)
		retry = 0;
	 end
	 
	 current_write = blk_write_data[0] ;
	 start   = 1;
	 dir     = 1;
	 start_addr = current_write`WRITE_ADDRESS;
	 
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
	 
	 @(posedge c_state == S_OOPS);
	 return `CYC_ACTUAL_TRANSFER = write_flags`WB_TRANSFER_SIZE - cyc_count;
	 
	 in_use = 0;	 
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
	 burst_length = 1;
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
	 start_addr = target_address;
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
	 
	 @(posedge m_data_vld);
	 return `READ_DATA = adio_out;
	 @(posedge c_state == S_OOPS);
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
	 
	 @(posedge CLK);
	 wenable_in = 1'b1;
	 src_di = write_data;
	 @(posedge CLK);
	 wenable_in = 1'b0;
	 src_di = 32'hz;
	 @(posedge CLK);

	 burst_length = 1;
	 in_use = 1;
	 retry  = 1;
	 
	 return `CYC_ACTUAL_TRANSFER = 0;
	 while (retry === 1) begin
	    @(posedge CLK)
	    if (c_state == S_IDLE)
	      retry = 0;
	 end
	 
	 start   = 1;
	 dir     = 1;
	 start_addr = target_address;
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
	 
	 @(posedge c_state == S_OOPS);
	 return `CYC_ACTUAL_TRANSFER = 1;
	 
	 in_use = 0;
      end
      
   endtask // single_write
   
endmodule // master_behavioral

// 
// master_behavioral.v ends here
