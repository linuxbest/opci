// user_interface.v --- 
// 
// Filename: user_interface.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二  2月  3 18:27:52 2009 (+0800)
// Version: 
// Last-Updated: 二  2月  3 20:21:56 2009 (+0800)
//           By: Hu Gang
//     Update #: 24
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// user interface for top, as pci master and pci slave.
// 
// 

// Change log:
// 
// 
// 

// Copyright (C) 2008 Beijing Soul tech.

// Code:


module user_interface (/*AUTOARG*/
   // Outputs
   adio_in, c_term, c_ready, adio64_in, s_ready, s_term,
   s_abort, complete, m_ready, m_cbe, m_cbe64, m_wrdn,
   request, request64, requesthold, int_n,
   // Inputs
   cfg_hit, cfg_vld, s_wrdn, s_data, s_data_vld, addr,
   adio_out
   );
   input cfg_hit;
   input cfg_vld;
   input s_wrdn;
   input s_data;
   input s_data_vld;
   input [31:0] addr;
   input [31:0] adio_out;
   
   output [31:0] adio_in;
   output        c_term;
   output        c_ready;
   output [31:0] adio64_in;
   assign adio_in = 0;
   assign c_ready = 1;
   assign c_term  = 1;
   assign adio64_in = 0;

   output 	 s_ready;
   output 	 s_term;
   output 	 s_abort;
   assign s_ready = 1;
   assign s_term  = 1;
   assign s_abort = 0;
   
   output 	 complete;
   output 	 m_ready;
   output [3:0]  m_cbe;
   output [3:0]  m_cbe64;
   output 	 m_wrdn;
   output 	 request;
   output 	 request64;
   output 	 requesthold;
   output 	 int_n;
   assign complete = 0;
   assign m_ready = 0;
   assign m_cbe = 0;
   assign m_cbe64 = 0;
   assign m_wrdn = 0;
   assign request = 0;
   assign request64 = 0;
   assign requesthold = 0;
   assign int_n = 1;

endmodule
// 
// user_interface.v ends here
