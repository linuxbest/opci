// pci_wrapper.v --- 
// 
// Filename: pci_wrapper.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 二  2月  3 17:27:05 2009 (+0800)
// Version: 
// Last-Updated: 二  2月  3 20:18:20 2009 (+0800)
//           By: Hu Gang
//     Update #: 161
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// wrapper for top and pci_bridge
// 
// 

// Change log:
// 
// 
// 

// Copyright (C) 2008 Beijing Soul tech.

// Code:

module pci_wrapper (/*AUTOARG*/
   // Outputs
   pci_clk_i, pci_rst_i, pci_inta_i, pci_gnt_i, pci_frame_i,
   pci_req64_i, pci_ack64_i, pci_irdy_i, pci_idsel_i,
   pci_devsel_i, pci_trdy_i, pci_stop_i, pci_ad_i,
   pci_ad64_i, pci_cbe_i, pci_cbe64_i, pci_par_i,
   pci_par64_i, pci_perr_i, PCI_SERRn,
   // Inouts
   PCI_AD, PCI_AD64, PCI_CBE, PCI_CBE64, PCI_FRAMEn,
   PCI_IRDYn, PCI_TRDYn, PCI_DEVSELn, PCI_STOPn, PCI_LOCKn,
   PCI_REQn, PCI_RSTn, PCI_INTAn, PCI_INTBn, PCI_PERRn,
   PCI_PAR, PCI_REQ64n, PCI_ACK64n, PCI_PAR64,
   // Inputs
   pci_rst_o, pci_rst_oe_o, pci_inta_o, pci_inta_oe_o,
   pci_req_o, pci_req_oe_o, pci_frame_o, pci_frame_oe_o,
   pci_req64_o, pci_req64_oe_o, pci_ack64_o, pci_ack64_oe_o,
   pci_irdy_oe_o, pci_devsel_oe_o, pci_trdy_oe_o,
   pci_stop_oe_o, pci_ad_oe_o, pci_cbe_oe_o, pci_cbe64_oe_o,
   pci_ad64_oe_o, pci_irdy_o, pci_devsel_o, pci_trdy_o,
   pci_stop_o, pci_ad_o, pci_ad64_o, pci_cbe_o, pci_cbe64_o,
   pci_par_o, pci_par_oe_o, pci_par64_o, pci_par64_oe_o,
   pci_perr_o, pci_perr_oe_o, pci_serr_o, pci_serr_oe_o,
   pci_cmd, PCI_CLK, PCI_IDSEL, PCI_GNTn
   );
   /*AUTOINOUTMODULE("top", "^PCI_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		PCI_SERRn;
   inout [31:0]		PCI_AD;
   inout [31:0]		PCI_AD64;
   inout [3:0]		PCI_CBE;
   inout [3:0]		PCI_CBE64;
   inout		PCI_FRAMEn;
   inout		PCI_IRDYn;
   inout		PCI_TRDYn;
   inout		PCI_DEVSELn;
   inout		PCI_STOPn;
   inout		PCI_LOCKn;
   inout		PCI_REQn;
   inout		PCI_RSTn;
   inout		PCI_INTAn;
   inout		PCI_INTBn;
   inout		PCI_PERRn;
   inout		PCI_PAR;
   inout		PCI_REQ64n;
   inout		PCI_ACK64n;
   inout		PCI_PAR64;
   input		PCI_CLK;
   input		PCI_IDSEL;
   input		PCI_GNTn;
   // End of automatics
   /*AUTOINOUTCOMP("pci_bridge32", "^pci_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		pci_clk_i;
   output		pci_rst_i;
   output		pci_inta_i;
   output		pci_gnt_i;
   output		pci_frame_i;
   output		pci_req64_i;
   output		pci_ack64_i;
   output		pci_irdy_i;
   output		pci_idsel_i;
   output		pci_devsel_i;
   output		pci_trdy_i;
   output		pci_stop_i;
   output [31:0]	pci_ad_i;
   output [31:0]	pci_ad64_i;
   output [3:0]		pci_cbe_i;
   output [3:0]		pci_cbe64_i;
   output		pci_par_i;
   output		pci_par64_i;
   output		pci_perr_i;
   input		pci_rst_o;
   input		pci_rst_oe_o;
   input		pci_inta_o;
   input		pci_inta_oe_o;
   input		pci_req_o;
   input		pci_req_oe_o;
   input		pci_frame_o;
   input		pci_frame_oe_o;
   input		pci_req64_o;
   input		pci_req64_oe_o;
   input		pci_ack64_o;
   input		pci_ack64_oe_o;
   input		pci_irdy_oe_o;
   input		pci_devsel_oe_o;
   input		pci_trdy_oe_o;
   input		pci_stop_oe_o;
   input [31:0]		pci_ad_oe_o;
   input [3:0]		pci_cbe_oe_o;
   input [3:0]		pci_cbe64_oe_o;
   input [31:0]		pci_ad64_oe_o;
   input		pci_irdy_o;
   input		pci_devsel_o;
   input		pci_trdy_o;
   input		pci_stop_o;
   input [31:0]		pci_ad_o;
   input [31:0]		pci_ad64_o;
   input [3:0]		pci_cbe_o;
   input [3:0]		pci_cbe64_o;
   input		pci_par_o;
   input		pci_par_oe_o;
   input		pci_par64_o;
   input		pci_par64_oe_o;
   input		pci_perr_o;
   input		pci_perr_oe_o;
   input		pci_serr_o;
   input		pci_serr_oe_o;
   input [15:0]		pci_cmd;
   // End of automatics

   assign pci_clk_i   = PCI_CLK;
   assign pci_rst_i   = PCI_RSTn;
   assign pci_inta_i  = 1'bz;
   assign pci_idsel_i = PCI_IDSEL;
   assign pci_gnt_i   = PCI_GNTn;
   
   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO(PCI_AD[@]),
    .O(pci_ad_i[@]),
    .I(pci_ad_o[@]),
    .T(pci_ad_oe_o[@]),
    )*/
   IOBUF_PCIX AD31 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[31]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[31]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[31]),		 // Templated
		    .T			(pci_ad_oe_o[31]));	 // Templated
   IOBUF_PCIX AD30 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[30]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[30]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[30]),		 // Templated
		    .T			(pci_ad_oe_o[30]));	 // Templated
   IOBUF_PCIX AD29 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[29]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[29]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[29]),		 // Templated
		    .T			(pci_ad_oe_o[29]));	 // Templated
   IOBUF_PCIX AD28 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[28]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[28]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[28]),		 // Templated
		    .T			(pci_ad_oe_o[28]));	 // Templated
   IOBUF_PCIX AD27 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[27]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[27]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[27]),		 // Templated
		    .T			(pci_ad_oe_o[27]));	 // Templated
   IOBUF_PCIX AD26 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[26]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[26]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[26]),		 // Templated
		    .T			(pci_ad_oe_o[26]));	 // Templated
   IOBUF_PCIX AD25 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[25]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[25]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[25]),		 // Templated
		    .T			(pci_ad_oe_o[25]));	 // Templated
   IOBUF_PCIX AD24 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[24]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[24]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[24]),		 // Templated
		    .T			(pci_ad_oe_o[24]));	 // Templated
   IOBUF_PCIX AD23 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[23]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[23]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[23]),		 // Templated
		    .T			(pci_ad_oe_o[23]));	 // Templated
   IOBUF_PCIX AD22 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[22]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[22]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[22]),		 // Templated
		    .T			(pci_ad_oe_o[22]));	 // Templated
   IOBUF_PCIX AD21 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[21]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[21]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[21]),		 // Templated
		    .T			(pci_ad_oe_o[21]));	 // Templated
   IOBUF_PCIX AD20 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[20]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[20]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[20]),		 // Templated
		    .T			(pci_ad_oe_o[20]));	 // Templated
   IOBUF_PCIX AD19 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[19]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[19]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[19]),		 // Templated
		    .T			(pci_ad_oe_o[19]));	 // Templated
   IOBUF_PCIX AD18 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[18]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[18]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[18]),		 // Templated
		    .T			(pci_ad_oe_o[18]));	 // Templated
   IOBUF_PCIX AD17 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[17]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[17]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[17]),		 // Templated
		    .T			(pci_ad_oe_o[17]));	 // Templated
   IOBUF_PCIX AD16 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[16]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[16]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[16]),		 // Templated
		    .T			(pci_ad_oe_o[16]));	 // Templated
   IOBUF_PCIX AD15 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[15]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[15]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[15]),		 // Templated
		    .T			(pci_ad_oe_o[15]));	 // Templated
   IOBUF_PCIX AD14 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[14]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[14]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[14]),		 // Templated
		    .T			(pci_ad_oe_o[14]));	 // Templated
   IOBUF_PCIX AD13 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[13]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[13]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[13]),		 // Templated
		    .T			(pci_ad_oe_o[13]));	 // Templated
   IOBUF_PCIX AD12 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[12]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[12]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[12]),		 // Templated
		    .T			(pci_ad_oe_o[12]));	 // Templated
   IOBUF_PCIX AD11 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[11]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[11]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[11]),		 // Templated
		    .T			(pci_ad_oe_o[11]));	 // Templated
   IOBUF_PCIX AD10 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad_i[10]),		 // Templated
		    // Inouts
		    .IO			(PCI_AD[10]),		 // Templated
		    // Inputs
		    .I			(pci_ad_o[10]),		 // Templated
		    .T			(pci_ad_oe_o[10]));	 // Templated
   IOBUF_PCIX AD9 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[9]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[9]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[9]),		 // Templated
		   .T			(pci_ad_oe_o[9]));	 // Templated
   IOBUF_PCIX AD8 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[8]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[8]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[8]),		 // Templated
		   .T			(pci_ad_oe_o[8]));	 // Templated
   IOBUF_PCIX AD7 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[7]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[7]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[7]),		 // Templated
		   .T			(pci_ad_oe_o[7]));	 // Templated
   IOBUF_PCIX AD6 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[6]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[6]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[6]),		 // Templated
		   .T			(pci_ad_oe_o[6]));	 // Templated
   IOBUF_PCIX AD5 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[5]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[5]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[5]),		 // Templated
		   .T			(pci_ad_oe_o[5]));	 // Templated
   IOBUF_PCIX AD4 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[4]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[4]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[4]),		 // Templated
		   .T			(pci_ad_oe_o[4]));	 // Templated
   IOBUF_PCIX AD3 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[3]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[3]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[3]),		 // Templated
		   .T			(pci_ad_oe_o[3]));	 // Templated
   IOBUF_PCIX AD2 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[2]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[2]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[2]),		 // Templated
		   .T			(pci_ad_oe_o[2]));	 // Templated
   IOBUF_PCIX AD1 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[1]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[1]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[1]),		 // Templated
		   .T			(pci_ad_oe_o[1]));	 // Templated
   IOBUF_PCIX AD0 (/*AUTOINST*/
		   // Outputs
		   .O			(pci_ad_i[0]),		 // Templated
		   // Inouts
		   .IO			(PCI_AD[0]),		 // Templated
		   // Inputs
		   .I			(pci_ad_o[0]),		 // Templated
		   .T			(pci_ad_oe_o[0]));	 // Templated

   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO(PCI_AD64[@]),
    .O(pci_ad64_i[@]),
    .I(pci_ad64_o[@]),
    .T(pci_ad64_oe_o[@]),
    )*/
   IOBUF_PCIX AD_31 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[31]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[31]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[31]),	 // Templated
		     .T			(pci_ad64_oe_o[31]));	 // Templated
   IOBUF_PCIX AD_30 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[30]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[30]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[30]),	 // Templated
		     .T			(pci_ad64_oe_o[30]));	 // Templated
   IOBUF_PCIX AD_29 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[29]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[29]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[29]),	 // Templated
		     .T			(pci_ad64_oe_o[29]));	 // Templated
   IOBUF_PCIX AD_28 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[28]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[28]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[28]),	 // Templated
		     .T			(pci_ad64_oe_o[28]));	 // Templated
   IOBUF_PCIX AD_27 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[27]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[27]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[27]),	 // Templated
		     .T			(pci_ad64_oe_o[27]));	 // Templated
   IOBUF_PCIX AD_26 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[26]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[26]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[26]),	 // Templated
		     .T			(pci_ad64_oe_o[26]));	 // Templated
   IOBUF_PCIX AD_25 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[25]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[25]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[25]),	 // Templated
		     .T			(pci_ad64_oe_o[25]));	 // Templated
   IOBUF_PCIX AD_24 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[24]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[24]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[24]),	 // Templated
		     .T			(pci_ad64_oe_o[24]));	 // Templated
   IOBUF_PCIX AD_23 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[23]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[23]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[23]),	 // Templated
		     .T			(pci_ad64_oe_o[23]));	 // Templated
   IOBUF_PCIX AD_22 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[22]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[22]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[22]),	 // Templated
		     .T			(pci_ad64_oe_o[22]));	 // Templated
   IOBUF_PCIX AD_21 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[21]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[21]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[21]),	 // Templated
		     .T			(pci_ad64_oe_o[21]));	 // Templated
   IOBUF_PCIX AD_20 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[20]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[20]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[20]),	 // Templated
		     .T			(pci_ad64_oe_o[20]));	 // Templated
   IOBUF_PCIX AD_19 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[19]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[19]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[19]),	 // Templated
		     .T			(pci_ad64_oe_o[19]));	 // Templated
   IOBUF_PCIX AD_18 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[18]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[18]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[18]),	 // Templated
		     .T			(pci_ad64_oe_o[18]));	 // Templated
   IOBUF_PCIX AD_17 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[17]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[17]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[17]),	 // Templated
		     .T			(pci_ad64_oe_o[17]));	 // Templated
   IOBUF_PCIX AD_16 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[16]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[16]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[16]),	 // Templated
		     .T			(pci_ad64_oe_o[16]));	 // Templated
   IOBUF_PCIX AD_15 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[15]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[15]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[15]),	 // Templated
		     .T			(pci_ad64_oe_o[15]));	 // Templated
   IOBUF_PCIX AD_14 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[14]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[14]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[14]),	 // Templated
		     .T			(pci_ad64_oe_o[14]));	 // Templated
   IOBUF_PCIX AD_13 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[13]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[13]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[13]),	 // Templated
		     .T			(pci_ad64_oe_o[13]));	 // Templated
   IOBUF_PCIX AD_12 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[12]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[12]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[12]),	 // Templated
		     .T			(pci_ad64_oe_o[12]));	 // Templated
   IOBUF_PCIX AD_11 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[11]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[11]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[11]),	 // Templated
		     .T			(pci_ad64_oe_o[11]));	 // Templated
   IOBUF_PCIX AD_10 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_ad64_i[10]),	 // Templated
		     // Inouts
		     .IO		(PCI_AD64[10]),		 // Templated
		     // Inputs
		     .I			(pci_ad64_o[10]),	 // Templated
		     .T			(pci_ad64_oe_o[10]));	 // Templated
   IOBUF_PCIX AD_9 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[9]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[9]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[9]),	 // Templated
		    .T			(pci_ad64_oe_o[9]));	 // Templated
   IOBUF_PCIX AD_8 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[8]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[8]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[8]),	 // Templated
		    .T			(pci_ad64_oe_o[8]));	 // Templated
   IOBUF_PCIX AD_7 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[7]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[7]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[7]),	 // Templated
		    .T			(pci_ad64_oe_o[7]));	 // Templated
   IOBUF_PCIX AD_6 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[6]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[6]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[6]),	 // Templated
		    .T			(pci_ad64_oe_o[6]));	 // Templated
   IOBUF_PCIX AD_5 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[5]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[5]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[5]),	 // Templated
		    .T			(pci_ad64_oe_o[5]));	 // Templated
   IOBUF_PCIX AD_4 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[4]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[4]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[4]),	 // Templated
		    .T			(pci_ad64_oe_o[4]));	 // Templated
   IOBUF_PCIX AD_3 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[3]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[3]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[3]),	 // Templated
		    .T			(pci_ad64_oe_o[3]));	 // Templated
   IOBUF_PCIX AD_2 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[2]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[2]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[2]),	 // Templated
		    .T			(pci_ad64_oe_o[2]));	 // Templated
   IOBUF_PCIX AD_1 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[1]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[1]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[1]),	 // Templated
		    .T			(pci_ad64_oe_o[1]));	 // Templated
   IOBUF_PCIX AD_0 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_ad64_i[0]),	 // Templated
		    // Inouts
		    .IO			(PCI_AD64[0]),		 // Templated
		    // Inputs
		    .I			(pci_ad64_o[0]),	 // Templated
		    .T			(pci_ad64_oe_o[0]));	 // Templated
   
   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO(PCI_CBE[@]),
    .O(pci_cbe_i[@]),
    .I(pci_cbe_o[@]),
    .T(pci_cbe_oe_o[@]),
    )*/
   IOBUF_PCIX CBE3 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_cbe_i[3]),		 // Templated
		    // Inouts
		    .IO			(PCI_CBE[3]),		 // Templated
		    // Inputs
		    .I			(pci_cbe_o[3]),		 // Templated
		    .T			(pci_cbe_oe_o[3]));	 // Templated
   IOBUF_PCIX CBE2 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_cbe_i[2]),		 // Templated
		    // Inouts
		    .IO			(PCI_CBE[2]),		 // Templated
		    // Inputs
		    .I			(pci_cbe_o[2]),		 // Templated
		    .T			(pci_cbe_oe_o[2]));	 // Templated
   IOBUF_PCIX CBE1 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_cbe_i[1]),		 // Templated
		    // Inouts
		    .IO			(PCI_CBE[1]),		 // Templated
		    // Inputs
		    .I			(pci_cbe_o[1]),		 // Templated
		    .T			(pci_cbe_oe_o[1]));	 // Templated
   IOBUF_PCIX CBE0 (/*AUTOINST*/
		    // Outputs
		    .O			(pci_cbe_i[0]),		 // Templated
		    // Inouts
		    .IO			(PCI_CBE[0]),		 // Templated
		    // Inputs
		    .I			(pci_cbe_o[0]),		 // Templated
		    .T			(pci_cbe_oe_o[0]));	 // Templated

   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO(PCI_CBE64[@]),
    .O(pci_cbe64_i[@]),
    .I(pci_cbe64_o[@]),
    .T(pci_cbe64_oe_o[@]),
    )*/
   IOBUF_PCIX CBE_3 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_cbe64_i[3]),	 // Templated
		     // Inouts
		     .IO		(PCI_CBE64[3]),		 // Templated
		     // Inputs
		     .I			(pci_cbe64_o[3]),	 // Templated
		     .T			(pci_cbe64_oe_o[3]));	 // Templated
   IOBUF_PCIX CBE_2 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_cbe64_i[2]),	 // Templated
		     // Inouts
		     .IO		(PCI_CBE64[2]),		 // Templated
		     // Inputs
		     .I			(pci_cbe64_o[2]),	 // Templated
		     .T			(pci_cbe64_oe_o[2]));	 // Templated
   IOBUF_PCIX CBE_1 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_cbe64_i[1]),	 // Templated
		     // Inouts
		     .IO		(PCI_CBE64[1]),		 // Templated
		     // Inputs
		     .I			(pci_cbe64_o[1]),	 // Templated
		     .T			(pci_cbe64_oe_o[1]));	 // Templated
   IOBUF_PCIX CBE_0 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_cbe64_i[0]),	 // Templated
		     // Inouts
		     .IO		(PCI_CBE64[0]),		 // Templated
		     // Inputs
		     .I			(pci_cbe64_o[0]),	 // Templated
		     .T			(pci_cbe64_oe_o[0]));	 // Templated

   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO (PCI_@"(upcase vl-cell-name)"[]),
    .O(pci_@"(downcase vl-cell-name)"_i[]),
    .I(pci_@"(downcase vl-cell-name)"_o[]),
    .T(pci_@"(downcase vl-cell-name)"_oe_o[]),
    )*/
   IOBUF_PCIX par (/*AUTOINST*/
		   // Outputs
		   .O			(pci_par_i),		 // Templated
		   // Inouts
		   .IO			(PCI_PAR),		 // Templated
		   // Inputs
		   .I			(pci_par_o),		 // Templated
		   .T			(pci_par_oe_o));		 // Templated
   IOBUF_PCIX par64 (/*AUTOINST*/
		     // Outputs
		     .O			(pci_par64_i),		 // Templated
		     // Inouts
		     .IO		(PCI_PAR64),		 // Templated
		     // Inputs
		     .I			(pci_par64_o),		 // Templated
		     .T			(pci_par64_oe_o));	 // Templated

   /* IOBUF_PCIX AUTO_TEMPLATE (
    .IO (PCI_@"(upcase vl-cell-name)"[]n),
    .O(pci_@"(downcase vl-cell-name)"_i[]),
    .I(pci_@"(downcase vl-cell-name)"_o[]),
    .T(pci_@"(downcase vl-cell-name)"_oe_o[]),
    )*/
   IOBUF_PCIX frame (/*AUTOINST*/
		     // Outputs
		     .O			(pci_frame_i),		 // Templated
		     // Inouts
		     .IO		(PCI_FRAMEn),		 // Templated
		     // Inputs
		     .I			(pci_frame_o),		 // Templated
		     .T			(pci_frame_oe_o));	 // Templated
   IOBUF_PCIX trdy (/*AUTOINST*/
		    // Outputs
		    .O			(pci_trdy_i),		 // Templated
		    // Inouts
		    .IO			(PCI_TRDYn),		 // Templated
		    // Inputs
		    .I			(pci_trdy_o),		 // Templated
		    .T			(pci_trdy_oe_o));	 // Templated
   IOBUF_PCIX irdy (/*AUTOINST*/
		    // Outputs
		    .O			(pci_irdy_i),		 // Templated
		    // Inouts
		    .IO			(PCI_IRDYn),		 // Templated
		    // Inputs
		    .I			(pci_irdy_o),		 // Templated
		    .T			(pci_irdy_oe_o));	 // Templated
   IOBUF_PCIX devsel (/*AUTOINST*/
		      // Outputs
		      .O		(pci_devsel_i),		 // Templated
		      // Inouts
		      .IO		(PCI_DEVSELn),		 // Templated
		      // Inputs
		      .I		(pci_devsel_o),		 // Templated
		      .T		(pci_devsel_oe_o));	 // Templated
   
   IOBUF_PCIX perr (/*AUTOINST*/
		    // Outputs
		    .O			(pci_perr_i),		 // Templated
		    // Inouts
		    .IO			(PCI_PERRn),		 // Templated
		    // Inputs
		    .I			(pci_perr_o),		 // Templated
		    .T			(pci_perr_oe_o));	 // Templated
   IOBUF_PCIX serr (/*AUTOINST*/
		    // Outputs
		    .O			(pci_serr_i),		 // Templated
		    // Inouts
		    .IO			(PCI_SERRn),		 // Templated
		    // Inputs
		    .I			(pci_serr_o),		 // Templated
		    .T			(pci_serr_oe_o));	 // Templated
   /* REQ64, ACK64 */
endmodule // pci_wrapper

// Local Variables:
// verilog-library-directories:("." "/p/hw/lzs/encode/rtl/verilog" "/p/hw/lzs/decode/rtl/verilog/" "/p/hw/ssce2/usb-mcu/ledblink/rtl/" "../../rtl/verilog" "/p/hw/unisims")
// verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// pci_wrapper.v ends here
