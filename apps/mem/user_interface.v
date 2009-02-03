// user_interface.v --- 
// 
// Filename: user_interface.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二  2月  3 18:27:52 2009 (+0800)
// Version: 
// Last-Updated: 二  2月  3 18:31:11 2009 (+0800)
//           By: Hu Gang
//     Update #: 6
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
   adio_in, c_term, c_ready, m_cbe, m_cbe64, adio64_in,
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
   output [31:0] adio_in;
   input [31:0]  adio_out;
   output        c_term;
   output        c_ready;

   output [3:0]  m_cbe;
   output [3:0]  m_cbe64;
   output [31:0] adio64_in;
   
endmodule
// 
// user_interface.v ends here
