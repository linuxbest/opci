// top.v --- 
// 
// Filename: top.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: 四  1月 22 14:34:30 2009 (+0800)
// Version: 
// Last-Updated: 二  2月  3 20:21:59 2009 (+0800)
//           By: Hu Gang
//     Update #: 45
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

module top (/*AUTOARG*/
   // Outputs
   PCI_SERRn, LED,
   // Inouts
   PCI_AD, PCI_AD64, PCI_CBE, PCI_CBE64, PCI_FRAMEn,
   PCI_IRDYn, PCI_TRDYn, PCI_DEVSELn, PCI_STOPn, PCI_LOCKn,
   PCI_REQn, PCI_RSTn, PCI_INTAn, PCI_INTBn, PCI_PERRn,
   PCI_PAR, PCI_REQ64n, PCI_ACK64n, PCI_PAR64, PA2, PA4,
   PA5, PA6, PA7, SLWR, SLRD, CTL, FD,
   // Inputs
   PCI_CLK, PCI_IDSEL, PCI_GNTn, CLK, rstn, FCLK
   );
   
   /* PCI */
   inout [31:0] PCI_AD;
   inout [31:0] PCI_AD64;
   inout [3:0] 	PCI_CBE;
   inout [3:0] 	PCI_CBE64;
   input        PCI_CLK;
   input        PCI_IDSEL;
   inout        PCI_FRAMEn;
   inout        PCI_IRDYn;
   inout        PCI_TRDYn;
   inout        PCI_DEVSELn;
   inout        PCI_STOPn;
   inout        PCI_LOCKn;
   input        PCI_GNTn;
   inout        PCI_REQn;
   inout        PCI_RSTn;
   inout        PCI_INTAn;
   inout        PCI_INTBn;
   inout        PCI_PERRn;
   output       PCI_SERRn;
   inout        PCI_PAR;
   inout        PCI_REQ64n;
   inout        PCI_ACK64n;
   inout        PCI_PAR64;

   input 	CLK;
   input 	rstn;
   output 	LED;

   /* WRITE TO FIFO */
   /* CLOCK */
   input 	FCLK;      /* PA5, PA4 FIFOADR[1:0] */
   inout 	PA2;   
   inout 	PA4;     /* FIFOADR1 */
   inout 	PA5;     /* FIFOADR0 */
   inout 	PA6;     /* PKTEND */
   inout 	PA7;
   inout 	SLWR;
   inout 	SLRD;
   inout [2:0] 	CTL;   /* CTL0
			CTL1 FULL
			CTL2 EMPTY */
   inout [15:0] FD;
   

   ledblink i_ledblink(/*AUTOINST*/
		       // Outputs
		       .LED		(LED),
		       // Inouts
		       .PA2		(PA2),
		       .PA4		(PA4),
		       .PA5		(PA5),
		       .PA6		(PA6),
		       .PA7		(PA7),
		       .SLWR		(SLWR),
		       .SLRD		(SLRD),
		       .CTL		(CTL[2:0]),
		       .FD		(FD[15:0]),
		       .PCI_AD		(PCI_AD[31:0]),
		       .PCI_AD64	(PCI_AD64[31:0]),
		       .PCI_CBE		(PCI_CBE[3:0]),
		       .PCI_CBE64	(PCI_CBE64[3:0]),
		       .PCI_FRAMEn	(PCI_FRAMEn),
		       .PCI_IRDYn	(PCI_IRDYn),
		       .PCI_TRDYn	(PCI_TRDYn),
		       .PCI_DEVSELn	(PCI_DEVSELn),
		       .PCI_STOPn	(PCI_STOPn),
		       .PCI_LOCKn	(PCI_LOCKn),
		       .PCI_REQn	(PCI_REQn),
		       .PCI_RSTn	(PCI_RSTn),
		       .PCI_INTAn	(PCI_INTAn),
		       .PCI_INTBn	(PCI_INTBn),
		       .PCI_PERRn	(PCI_PERRn),
		       .PCI_SERRn	(PCI_SERRn),
		       .PCI_PAR		(PCI_PAR),
		       .PCI_REQ64n	(PCI_REQ64n),
		       .PCI_ACK64n	(PCI_ACK64n),
		       .PCI_PAR64	(PCI_PAR64),
		       // Inputs
		       .CLK		(CLK),
		       .rstn		(rstn),
		       .FCLK		(FCLK),
		       .PCI_CLK		(PCI_CLK),
		       .PCI_IDSEL	(PCI_IDSEL),
		       .PCI_GNTn	(PCI_GNTn));

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]		addr;			// From i_bridge of pci_bridge32.v
   wire			addr_vld;		// From i_bridge of pci_bridge32.v
   wire [31:0]		adio64_in;		// From i_user of user_interface.v
   wire [31:0]		adio64_out;		// From i_bridge of pci_bridge32.v
   wire [31:0]		adio_in;		// From i_user of user_interface.v
   wire [31:0]		adio_out;		// From i_bridge of pci_bridge32.v
   wire			b_busy;			// From i_bridge of pci_bridge32.v
   wire			backoff;		// From i_bridge of pci_bridge32.v
   wire [7:0]		base_hit;		// From i_bridge of pci_bridge32.v
   wire			c_ready;		// From i_user of user_interface.v
   wire			c_term;			// From i_user of user_interface.v
   wire			cfg_hit;		// From i_bridge of pci_bridge32.v
   wire			cfg_vld;		// From i_bridge of pci_bridge32.v
   wire			complete;		// From i_user of user_interface.v
   wire [39:0]		csr;			// From i_bridge of pci_bridge32.v
   wire			devselq_n;		// From i_bridge of pci_bridge32.v
   wire			dr_bus;			// From i_bridge of pci_bridge32.v
   wire			frameq_n;		// From i_bridge of pci_bridge32.v
   wire			i_idle;			// From i_bridge of pci_bridge32.v
   wire			idle;			// From i_bridge of pci_bridge32.v
   wire			int_n;			// From i_user of user_interface.v
   wire			irdyq_n;		// From i_bridge of pci_bridge32.v
   wire			m_addr_n;		// From i_bridge of pci_bridge32.v
   wire [3:0]		m_cbe;			// From i_user of user_interface.v
   wire [3:0]		m_cbe64;		// From i_user of user_interface.v
   wire			m_data;			// From i_bridge of pci_bridge32.v
   wire			m_data_vld;		// From i_bridge of pci_bridge32.v
   wire			m_ready;		// From i_user of user_interface.v
   wire			m_src_en;		// From i_bridge of pci_bridge32.v
   wire			m_wrdn;			// From i_user of user_interface.v
   wire			pci_ack64_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_ack64_o;		// From i_bridge of pci_bridge32.v
   wire			pci_ack64_oe_o;		// From i_bridge of pci_bridge32.v
   wire [31:0]		pci_ad64_i;		// From i_wrapper of pci_wrapper.v
   wire [31:0]		pci_ad64_o;		// From i_bridge of pci_bridge32.v
   wire [31:0]		pci_ad64_oe_o;		// From i_bridge of pci_bridge32.v
   wire [31:0]		pci_ad_i;		// From i_wrapper of pci_wrapper.v
   wire [31:0]		pci_ad_o;		// From i_bridge of pci_bridge32.v
   wire [31:0]		pci_ad_oe_o;		// From i_bridge of pci_bridge32.v
   wire [3:0]		pci_cbe64_i;		// From i_wrapper of pci_wrapper.v
   wire [3:0]		pci_cbe64_o;		// From i_bridge of pci_bridge32.v
   wire [3:0]		pci_cbe64_oe_o;		// From i_bridge of pci_bridge32.v
   wire [3:0]		pci_cbe_i;		// From i_wrapper of pci_wrapper.v
   wire [3:0]		pci_cbe_o;		// From i_bridge of pci_bridge32.v
   wire [3:0]		pci_cbe_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_clk_i;		// From i_wrapper of pci_wrapper.v
   wire [15:0]		pci_cmd;		// From i_bridge of pci_bridge32.v
   wire			pci_devsel_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_devsel_o;		// From i_bridge of pci_bridge32.v
   wire			pci_devsel_oe_o;	// From i_bridge of pci_bridge32.v
   wire			pci_frame_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_frame_o;		// From i_bridge of pci_bridge32.v
   wire			pci_frame_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_gnt_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_idsel_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_inta_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_inta_o;		// From i_bridge of pci_bridge32.v
   wire			pci_inta_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_irdy_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_irdy_o;		// From i_bridge of pci_bridge32.v
   wire			pci_irdy_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_par64_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_par64_o;		// From i_bridge of pci_bridge32.v
   wire			pci_par64_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_par_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_par_o;		// From i_bridge of pci_bridge32.v
   wire			pci_par_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_perr_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_perr_o;		// From i_bridge of pci_bridge32.v
   wire			pci_perr_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_req64_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_req64_o;		// From i_bridge of pci_bridge32.v
   wire			pci_req64_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_req_o;		// From i_bridge of pci_bridge32.v
   wire			pci_req_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_rst_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_rst_o;		// From i_bridge of pci_bridge32.v
   wire			pci_rst_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_serr_o;		// From i_bridge of pci_bridge32.v
   wire			pci_serr_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_stop_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_stop_o;		// From i_bridge of pci_bridge32.v
   wire			pci_stop_oe_o;		// From i_bridge of pci_bridge32.v
   wire			pci_trdy_i;		// From i_wrapper of pci_wrapper.v
   wire			pci_trdy_o;		// From i_bridge of pci_bridge32.v
   wire			pci_trdy_oe_o;		// From i_bridge of pci_bridge32.v
   wire			perrq_n;		// From i_bridge of pci_bridge32.v
   wire			request;		// From i_user of user_interface.v
   wire			request64;		// From i_user of user_interface.v
   wire			requesthold;		// From i_user of user_interface.v
   wire			s_abort;		// From i_user of user_interface.v
   wire [3:0]		s_cbe;			// From i_bridge of pci_bridge32.v
   wire [3:0]		s_cbe64;		// From i_bridge of pci_bridge32.v
   wire			s_data;			// From i_bridge of pci_bridge32.v
   wire			s_data_vld;		// From i_bridge of pci_bridge32.v
   wire			s_ready;		// From i_user of user_interface.v
   wire			s_src_en;		// From i_bridge of pci_bridge32.v
   wire			s_term;			// From i_user of user_interface.v
   wire			s_wrdn;			// From i_bridge of pci_bridge32.v
   wire			serrq_n;		// From i_bridge of pci_bridge32.v
   wire			stopq_n;		// From i_bridge of pci_bridge32.v
   wire			time_out;		// From i_bridge of pci_bridge32.v
   wire			trdyq_n;		// From i_bridge of pci_bridge32.v
   // End of automatics
   
   pci_wrapper i_wrapper (/*AUTOINST*/
			  // Outputs
			  .PCI_SERRn		(PCI_SERRn),
			  .pci_clk_i		(pci_clk_i),
			  .pci_rst_i		(pci_rst_i),
			  .pci_inta_i		(pci_inta_i),
			  .pci_gnt_i		(pci_gnt_i),
			  .pci_frame_i		(pci_frame_i),
			  .pci_req64_i		(pci_req64_i),
			  .pci_ack64_i		(pci_ack64_i),
			  .pci_irdy_i		(pci_irdy_i),
			  .pci_idsel_i		(pci_idsel_i),
			  .pci_devsel_i		(pci_devsel_i),
			  .pci_trdy_i		(pci_trdy_i),
			  .pci_stop_i		(pci_stop_i),
			  .pci_ad_i		(pci_ad_i[31:0]),
			  .pci_ad64_i		(pci_ad64_i[31:0]),
			  .pci_cbe_i		(pci_cbe_i[3:0]),
			  .pci_cbe64_i		(pci_cbe64_i[3:0]),
			  .pci_par_i		(pci_par_i),
			  .pci_par64_i		(pci_par64_i),
			  .pci_perr_i		(pci_perr_i),
			  // Inouts
			  .PCI_AD		(PCI_AD[31:0]),
			  .PCI_AD64		(PCI_AD64[31:0]),
			  .PCI_CBE		(PCI_CBE[3:0]),
			  .PCI_CBE64		(PCI_CBE64[3:0]),
			  .PCI_FRAMEn		(PCI_FRAMEn),
			  .PCI_IRDYn		(PCI_IRDYn),
			  .PCI_TRDYn		(PCI_TRDYn),
			  .PCI_DEVSELn		(PCI_DEVSELn),
			  .PCI_STOPn		(PCI_STOPn),
			  .PCI_LOCKn		(PCI_LOCKn),
			  .PCI_REQn		(PCI_REQn),
			  .PCI_RSTn		(PCI_RSTn),
			  .PCI_INTAn		(PCI_INTAn),
			  .PCI_INTBn		(PCI_INTBn),
			  .PCI_PERRn		(PCI_PERRn),
			  .PCI_PAR		(PCI_PAR),
			  .PCI_REQ64n		(PCI_REQ64n),
			  .PCI_ACK64n		(PCI_ACK64n),
			  .PCI_PAR64		(PCI_PAR64),
			  // Inputs
			  .PCI_CLK		(PCI_CLK),
			  .PCI_IDSEL		(PCI_IDSEL),
			  .PCI_GNTn		(PCI_GNTn),
			  .pci_rst_o		(pci_rst_o),
			  .pci_rst_oe_o		(pci_rst_oe_o),
			  .pci_inta_o		(pci_inta_o),
			  .pci_inta_oe_o	(pci_inta_oe_o),
			  .pci_req_o		(pci_req_o),
			  .pci_req_oe_o		(pci_req_oe_o),
			  .pci_frame_o		(pci_frame_o),
			  .pci_frame_oe_o	(pci_frame_oe_o),
			  .pci_req64_o		(pci_req64_o),
			  .pci_req64_oe_o	(pci_req64_oe_o),
			  .pci_ack64_o		(pci_ack64_o),
			  .pci_ack64_oe_o	(pci_ack64_oe_o),
			  .pci_irdy_oe_o	(pci_irdy_oe_o),
			  .pci_devsel_oe_o	(pci_devsel_oe_o),
			  .pci_trdy_oe_o	(pci_trdy_oe_o),
			  .pci_stop_oe_o	(pci_stop_oe_o),
			  .pci_ad_oe_o		(pci_ad_oe_o[31:0]),
			  .pci_cbe_oe_o		(pci_cbe_oe_o[3:0]),
			  .pci_cbe64_oe_o	(pci_cbe64_oe_o[3:0]),
			  .pci_ad64_oe_o	(pci_ad64_oe_o[31:0]),
			  .pci_irdy_o		(pci_irdy_o),
			  .pci_devsel_o		(pci_devsel_o),
			  .pci_trdy_o		(pci_trdy_o),
			  .pci_stop_o		(pci_stop_o),
			  .pci_ad_o		(pci_ad_o[31:0]),
			  .pci_ad64_o		(pci_ad64_o[31:0]),
			  .pci_cbe_o		(pci_cbe_o[3:0]),
			  .pci_cbe64_o		(pci_cbe64_o[3:0]),
			  .pci_par_o		(pci_par_o),
			  .pci_par_oe_o		(pci_par_oe_o),
			  .pci_par64_o		(pci_par64_o),
			  .pci_par64_oe_o	(pci_par64_oe_o),
			  .pci_perr_o		(pci_perr_o),
			  .pci_perr_oe_o	(pci_perr_oe_o),
			  .pci_serr_o		(pci_serr_o),
			  .pci_serr_oe_o	(pci_serr_oe_o),
			  .pci_cmd		(pci_cmd[15:0]));
   pci_bridge32 i_bridge (
			  /*AUTOINST*/
			  // Outputs
			  .pci_rst_o		(pci_rst_o),
			  .pci_rst_oe_o		(pci_rst_oe_o),
			  .pci_inta_o		(pci_inta_o),
			  .pci_inta_oe_o	(pci_inta_oe_o),
			  .pci_req_o		(pci_req_o),
			  .pci_req_oe_o		(pci_req_oe_o),
			  .pci_frame_o		(pci_frame_o),
			  .pci_frame_oe_o	(pci_frame_oe_o),
			  .pci_req64_o		(pci_req64_o),
			  .pci_req64_oe_o	(pci_req64_oe_o),
			  .pci_ack64_o		(pci_ack64_o),
			  .pci_ack64_oe_o	(pci_ack64_oe_o),
			  .pci_irdy_oe_o	(pci_irdy_oe_o),
			  .pci_devsel_oe_o	(pci_devsel_oe_o),
			  .pci_trdy_oe_o	(pci_trdy_oe_o),
			  .pci_stop_oe_o	(pci_stop_oe_o),
			  .pci_ad_oe_o		(pci_ad_oe_o[31:0]),
			  .pci_cbe_oe_o		(pci_cbe_oe_o[3:0]),
			  .pci_cbe64_oe_o	(pci_cbe64_oe_o[3:0]),
			  .pci_ad64_oe_o	(pci_ad64_oe_o[31:0]),
			  .pci_irdy_o		(pci_irdy_o),
			  .pci_devsel_o		(pci_devsel_o),
			  .pci_trdy_o		(pci_trdy_o),
			  .pci_stop_o		(pci_stop_o),
			  .pci_ad_o		(pci_ad_o[31:0]),
			  .pci_ad64_o		(pci_ad64_o[31:0]),
			  .pci_cbe_o		(pci_cbe_o[3:0]),
			  .pci_cbe64_o		(pci_cbe64_o[3:0]),
			  .pci_par_o		(pci_par_o),
			  .pci_par_oe_o		(pci_par_oe_o),
			  .pci_par64_o		(pci_par64_o),
			  .pci_par64_oe_o	(pci_par64_oe_o),
			  .pci_perr_o		(pci_perr_o),
			  .pci_perr_oe_o	(pci_perr_oe_o),
			  .pci_serr_o		(pci_serr_o),
			  .pci_serr_oe_o	(pci_serr_oe_o),
			  .addr			(addr[31:0]),
			  .adio_out		(adio_out[31:0]),
			  .adio64_out		(adio64_out[31:0]),
			  .addr_vld		(addr_vld),
			  .cfg_vld		(cfg_vld),
			  .s_data_vld		(s_data_vld),
			  .s_src_en		(s_src_en),
			  .s_wrdn		(s_wrdn),
			  .pci_cmd		(pci_cmd[15:0]),
			  .s_cbe		(s_cbe[3:0]),
			  .s_cbe64		(s_cbe64[3:0]),
			  .base_hit		(base_hit[7:0]),
			  .cfg_hit		(cfg_hit),
			  .m_data_vld		(m_data_vld),
			  .m_src_en		(m_src_en),
			  .time_out		(time_out),
			  .m_data		(m_data),
			  .dr_bus		(dr_bus),
			  .m_addr_n		(m_addr_n),
			  .i_idle		(i_idle),
			  .idle			(idle),
			  .b_busy		(b_busy),
			  .s_data		(s_data),
			  .backoff		(backoff),
			  .frameq_n		(frameq_n),
			  .devselq_n		(devselq_n),
			  .irdyq_n		(irdyq_n),
			  .trdyq_n		(trdyq_n),
			  .stopq_n		(stopq_n),
			  .perrq_n		(perrq_n),
			  .serrq_n		(serrq_n),
			  .csr			(csr[39:0]),
			  // Inputs
			  .pci_clk_i		(pci_clk_i),
			  .pci_rst_i		(pci_rst_i),
			  .pci_inta_i		(pci_inta_i),
			  .pci_gnt_i		(pci_gnt_i),
			  .pci_frame_i		(pci_frame_i),
			  .pci_req64_i		(pci_req64_i),
			  .pci_ack64_i		(pci_ack64_i),
			  .pci_irdy_i		(pci_irdy_i),
			  .pci_idsel_i		(pci_idsel_i),
			  .pci_devsel_i		(pci_devsel_i),
			  .pci_trdy_i		(pci_trdy_i),
			  .pci_stop_i		(pci_stop_i),
			  .pci_ad_i		(pci_ad_i[31:0]),
			  .pci_ad64_i		(pci_ad64_i[31:0]),
			  .pci_cbe_i		(pci_cbe_i[3:0]),
			  .pci_cbe64_i		(pci_cbe64_i[3:0]),
			  .pci_par_i		(pci_par_i),
			  .pci_par64_i		(pci_par64_i),
			  .pci_perr_i		(pci_perr_i),
			  .adio_in		(adio_in[31:0]),
			  .adio64_in		(adio64_in[31:0]),
			  .c_ready		(c_ready),
			  .c_term		(c_term),
			  .s_ready		(s_ready),
			  .s_term		(s_term),
			  .s_abort		(s_abort),
			  .request		(request),
			  .request64		(request64),
			  .requesthold		(requesthold),
			  .m_cbe		(m_cbe[3:0]),
			  .m_cbe64		(m_cbe64[3:0]),
			  .m_wrdn		(m_wrdn),
			  .complete		(complete),
			  .m_ready		(m_ready),
			  .cfg_self		(cfg_self),
			  .int_n		(int_n));

   user_interface i_user (/*AUTOINST*/
			  // Outputs
			  .adio_in		(adio_in[31:0]),
			  .c_term		(c_term),
			  .c_ready		(c_ready),
			  .adio64_in		(adio64_in[31:0]),
			  .s_ready		(s_ready),
			  .s_term		(s_term),
			  .s_abort		(s_abort),
			  .complete		(complete),
			  .m_ready		(m_ready),
			  .m_cbe		(m_cbe[3:0]),
			  .m_cbe64		(m_cbe64[3:0]),
			  .m_wrdn		(m_wrdn),
			  .request		(request),
			  .request64		(request64),
			  .requesthold		(requesthold),
			  .int_n		(int_n),
			  // Inputs
			  .cfg_hit		(cfg_hit),
			  .cfg_vld		(cfg_vld),
			  .s_wrdn		(s_wrdn),
			  .s_data		(s_data),
			  .s_data_vld		(s_data_vld),
			  .addr			(addr[31:0]),
			  .adio_out		(adio_out[31:0]));
   
endmodule // top

// Local Variables:
// verilog-library-directories:("." "/p/hw/lzs/encode/rtl/verilog" "/p/hw/lzs/decode/rtl/verilog/" "/p/hw/ssce2/usb-mcu/ledblink/rtl/" "../../rtl/verilog")
// verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v")
// verilog-library-extensions:(".v" ".h")
// End:
