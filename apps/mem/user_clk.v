// user_clk.v --- 
// 
// Filename: user_clk.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 三  2月  4 10:38:38 2009 (+0800)
// Version: 
// Last-Updated: 三  2月  4 12:03:00 2009 (+0800)
//           By: Hu Gang
//     Update #: 32
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

module user_clk (/*AUTOARG*/
   // Outputs
   clk200_p, clk200_n, clk133_p, clk133_n, clk133,
   clk133_90, clk133_div, dcm_lock,
   // Inputs
   clk48, rst
   );
   input clk48;
   input rst;
   /* 48 * 25 / 6 = 200 
    * 48 * 11 / 4 = 132 */
   output clk200_p, clk200_n;
   output clk133_p, clk133_n, clk133, clk133_90, clk133_div;
   output dcm_lock;
   
   dcm132 i_dcm132 (.CLKIN_IN(clk48),
		    .RST_IN(rst),
		    .CLKFX_OUT(clk133_p),
		    .CLKFX180_OUT(clk133_n),
		    // Outputs
		    .CLKIN_IBUFG_OUT	(),
		    .CLK0_OUT		(),
		    .LOCKED_OUT		(dcm_lock));
   dcm200 i_dcm200 (.CLKIN_IN(clk48),
		    .RST_IN(rst),
		    .CLKFX_OUT(clk200_p),
		    .CLKFX180_OUT(clk200_n),
		    // Outputs
		    .CLKIN_IBUFG_OUT	(),
		    .CLK0_OUT		(),
		    .LOCKED_OUT		());
   // synthesis translate_off
   defparam XPCI_DLL.DLL_FREQUENCY_MODE = "LOW";
   defparam XPCI_DLL.DUTY_CYCLE_CORRECTION = "TRUE";
   defparam XPCI_DLL.CLKDV_DIVIDE = 16.0;
   // synthesis translate_on
   //synthesis attribute DLL_FREQUENCY_MODE of XPCI_DLL is "LOW"
   //synthesis attribute DUTY_CYCLE_CORRECTION of XPCI_DLL is "TRUE"
   //synthesis attribute CLKDV_DIVIDE of XPCI_DLL is "16.0"
   DCM_BASE XPCI_DLL (.CLKIN(clk133_p), 
		      .CLKFB(clk133), 
		      .RST(rst), 
		      .CLK0(clk133),
		      .CLK90(clk133_90), 
		      .CLK180(), 
		      .CLK270(),
		      .CLK2X(), 
		      .CLKDV(clk133_div),
		      .LOCKED())/*synthesis xc_props="DLL_FREQUENCY_MODE = LOW,DUTY_CYCLE_CORRECTION = TRUE,CLKDV_DIVIDE = 16.0" */;
   
endmodule // user_clk

// 
// user_clk.v ends here
