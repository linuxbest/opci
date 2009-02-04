// user_interface.v --- 
// 
// Filename: user_interface.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二  2月  3 18:27:52 2009 (+0800)
// Version: 
// Last-Updated: 三  2月  4 20:23:16 2009 (+0800)
//           By: Hu Gang
//     Update #: 128
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


module user_app (/*AUTOARG*/
   // Outputs
   DDR_DIMM_RAS_L, DDR_DIMM_CAS_L, DDR_DIMM_WE_L,
   DDR_DIMM_CKE0, DDR_DIMM_CKE1, DDR_DIMM_CS_N0_7,
   DDR_DIMM_CS_N8_15, DDR_DIMM_DM, DDR_DIMM_CLK0_P,
   DDR_DIMM_CLK0_N, DDR_DIMM_CLK1_P, DDR_DIMM_CLK1_N,
   DDR_DIMM_CLK2_P, DDR_DIMM_CLK2_N, DDR_DIMM_BA,
   DDR_DIMM_ADDRESS, DDR_DIMM_SA, DDR_DIMM_SCL, adio_in,
   c_term, c_ready, adio64_in, s_ready, s_term, s_abort,
   complete, m_ready, m_cbe, m_cbe64, m_wrdn, request,
   request64, requesthold, int_n,
   // Inouts
   DDR_DIMM_DQ, DDR_DIMM_DQS, DDR_DIMM_SDA,
   // Inputs
   clk, rst, addr, adio_out, cfg_hit, cfg_vld, s_wrdn,
   s_data, s_data_vld, s_cbe, s_cbe64, clk200_p, clk200_n,
   clk133, clk133_90, clk133_div, dcm_lock
   );
   // clock and reset
   input clk;
   input rst;
   // common interface
   input [31:0] addr;
   input [31:0] adio_out;
   output [31:0] adio_in;
   // cfg interface
   input cfg_hit;
   input cfg_vld;
   input s_wrdn;
   input s_data;
   input s_data_vld;

   output        c_term;
   output        c_ready;
   output [31:0] adio64_in;
   assign c_ready = 1;
   assign c_term  = 1;
   assign adio_in = 0;
   
   input [3:0] 	 s_cbe;
   input [3:0] 	 s_cbe64;
   output 	 s_ready;
   output 	 s_term;
   output 	 s_abort;
   //assign s_ready = 1;
   //assign s_term  = 1;
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

   input 	 clk200_p, clk200_n, clk133, clk133_90, clk133_div, dcm_lock;
   /*AUTOINOUTMODULE("ddr_top", "^DDR_DIMM")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		DDR_DIMM_RAS_L;
   output		DDR_DIMM_CAS_L;
   output		DDR_DIMM_WE_L;
   output		DDR_DIMM_CKE0;
   output		DDR_DIMM_CKE1;
   output		DDR_DIMM_CS_N0_7;
   output		DDR_DIMM_CS_N8_15;
   output [7:0]		DDR_DIMM_DM;
   output		DDR_DIMM_CLK0_P;
   output		DDR_DIMM_CLK0_N;
   output		DDR_DIMM_CLK1_P;
   output		DDR_DIMM_CLK1_N;
   output		DDR_DIMM_CLK2_P;
   output		DDR_DIMM_CLK2_N;
   output [1:0]		DDR_DIMM_BA;
   output [11:0]	DDR_DIMM_ADDRESS;
   output [2:0]		DDR_DIMM_SA;
   output		DDR_DIMM_SCL;
   inout [63:0]		DDR_DIMM_DQ;
   inout [7:0]		DDR_DIMM_DQS;
   inout		DDR_DIMM_SDA;
   // End of automatics
   ddr_top i_ddr(
		 .CLK200_N(clk200_n),
		 .CLK200_P(clk200_p),

		 .USER_CLK(clk),// 66Mhz
		 .SYS_CLK_IN(clk133),
		 .SYS_RESET_IN(rst),
		 
		 .DDR_CLK90(clk133_90),
		 .DDR_CLKDIV(clk133_div),
		 .DCM_LOCK(dcm_lock),
		 
		 //output
		 .READ_DATA_OUT(),
		 .DDR_NOT_READY(),
		 .S_WAIT(),
		 .READ_DATA_VALID(),
		 .S_READY(s_ready),
		 .S_TERM(s_term),
		 // input
		 .PCI_ADDR(adio_out[26:0]),
		 .PCI_DATA_IN({adio64_out, adio_out}),
		 .PCI_WRITE_VALID(0),
		 .PCI_CBEA({s_cbe64, s_cbe}),
		 .PCI_WRITE(0),
		 .PCI_HIT(0),
		 .PCI_HIT_EARLY(0),
		 .S_DONE(0),
		 
		 /*AUTOINST*/
		 // Outputs
		 .DDR_DIMM_RAS_L	(DDR_DIMM_RAS_L),
		 .DDR_DIMM_CAS_L	(DDR_DIMM_CAS_L),
		 .DDR_DIMM_WE_L		(DDR_DIMM_WE_L),
		 .DDR_DIMM_CKE0		(DDR_DIMM_CKE0),
		 .DDR_DIMM_CKE1		(DDR_DIMM_CKE1),
		 .DDR_DIMM_CS_N0_7	(DDR_DIMM_CS_N0_7),
		 .DDR_DIMM_CS_N8_15	(DDR_DIMM_CS_N8_15),
		 .DDR_DIMM_DM		(DDR_DIMM_DM[7:0]),
		 .DDR_DIMM_CLK0_P	(DDR_DIMM_CLK0_P),
		 .DDR_DIMM_CLK0_N	(DDR_DIMM_CLK0_N),
		 .DDR_DIMM_CLK1_P	(DDR_DIMM_CLK1_P),
		 .DDR_DIMM_CLK1_N	(DDR_DIMM_CLK1_N),
		 .DDR_DIMM_CLK2_P	(DDR_DIMM_CLK2_P),
		 .DDR_DIMM_CLK2_N	(DDR_DIMM_CLK2_N),
		 .DDR_DIMM_BA		(DDR_DIMM_BA[1:0]),
		 .DDR_DIMM_ADDRESS	(DDR_DIMM_ADDRESS[11:0]),
		 .DDR_DIMM_SA		(DDR_DIMM_SA[2:0]),
		 .DDR_DIMM_SCL		(DDR_DIMM_SCL),
		 // Inouts
		 .DDR_DIMM_DQ		(DDR_DIMM_DQ[63:0]),
		 .DDR_DIMM_DQS		(DDR_DIMM_DQS[7:0]),
		 .DDR_DIMM_SDA		(DDR_DIMM_SDA));
   
   
endmodule // user_interface

// Local Variables:
// verilog-library-directories:("." "/p/hw/lzs/encode/rtl/verilog" "/p/hw/lzs/decode/rtl/verilog/" "/p/hw/ssce2/usb-mcu/ledblink/rtl/" "../../rtl/verilog" "/p/hw/XAPP708/verilog")
// verilog-library-files:("/some/path/technology.v")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// user_interface.v ends here
