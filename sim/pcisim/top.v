module top (/*AUTOARG*/
   // Outputs
   REQ, SERR,
   // Inouts
   AD, CBE, INTA, FRAME, IRDY, DEVSEL, TRDY, STOP, PAR,
   PERR, AD64, CBE64, PAR64, ACK64, REQ64,
   // Inputs
   CLK, RST, GNT, IDSEL
   );

   parameter oe_act = 1'b0 ;
   
   input           CLK ;
   inout [31:0]    AD ;
   inout [3:0] 	   CBE ;
   input           RST ;
   inout           INTA ;
   output          REQ ;
   input           GNT ;
   inout           FRAME ;
   inout           IRDY ;
   input           IDSEL ;
   inout           DEVSEL ;
   inout           TRDY ;
   inout           STOP ;
   inout           PAR ;
   inout           PERR ;
   output          SERR ;

   inout [31:0]    AD64;
   inout [3:0] 	   CBE64;
   inout 	   PAR64;
   inout 	   ACK64;
   inout 	   REQ64;
   
   wire [31:0] 	   AD_out ;
   wire [31:0] 	   AD_en ;
   wire [31:0] 	   AD_in   ;

   wire [31:0] 	   AD64_out ;
   wire [31:0] 	   AD64_en ;
   wire [31:0] 	   AD64_in   ;
   
   assign AD_in[0 ] = (AD_en[0 ] == oe_act) ? 1'bx : AD[0 ] ;
   assign AD_in[1 ] = (AD_en[1 ] == oe_act) ? 1'bx : AD[1 ] ;
   assign AD_in[2 ] = (AD_en[2 ] == oe_act) ? 1'bx : AD[2 ] ;
   assign AD_in[3 ] = (AD_en[3 ] == oe_act) ? 1'bx : AD[3 ] ;
   assign AD_in[4 ] = (AD_en[4 ] == oe_act) ? 1'bx : AD[4 ] ;
   assign AD_in[5 ] = (AD_en[5 ] == oe_act) ? 1'bx : AD[5 ] ;
   assign AD_in[6 ] = (AD_en[6 ] == oe_act) ? 1'bx : AD[6 ] ;
   assign AD_in[7 ] = (AD_en[7 ] == oe_act) ? 1'bx : AD[7 ] ;
   assign AD_in[8 ] = (AD_en[8 ] == oe_act) ? 1'bx : AD[8 ] ;
   assign AD_in[9 ] = (AD_en[9 ] == oe_act) ? 1'bx : AD[9 ] ;
   assign AD_in[10] = (AD_en[10] == oe_act) ? 1'bx : AD[10] ;
   assign AD_in[11] = (AD_en[11] == oe_act) ? 1'bx : AD[11] ;
   assign AD_in[12] = (AD_en[12] == oe_act) ? 1'bx : AD[12] ;
   assign AD_in[13] = (AD_en[13] == oe_act) ? 1'bx : AD[13] ;
   assign AD_in[14] = (AD_en[14] == oe_act) ? 1'bx : AD[14] ;
   assign AD_in[15] = (AD_en[15] == oe_act) ? 1'bx : AD[15] ;
   assign AD_in[16] = (AD_en[16] == oe_act) ? 1'bx : AD[16] ;
   assign AD_in[17] = (AD_en[17] == oe_act) ? 1'bx : AD[17] ;
   assign AD_in[18] = (AD_en[18] == oe_act) ? 1'bx : AD[18] ;
   assign AD_in[19] = (AD_en[19] == oe_act) ? 1'bx : AD[19] ;
   assign AD_in[20] = (AD_en[20] == oe_act) ? 1'bx : AD[20] ;
   assign AD_in[21] = (AD_en[21] == oe_act) ? 1'bx : AD[21] ;
   assign AD_in[22] = (AD_en[22] == oe_act) ? 1'bx : AD[22] ;
   assign AD_in[23] = (AD_en[23] == oe_act) ? 1'bx : AD[23] ;
   assign AD_in[24] = (AD_en[24] == oe_act) ? 1'bx : AD[24] ;
   assign AD_in[25] = (AD_en[25] == oe_act) ? 1'bx : AD[25] ;
   assign AD_in[26] = (AD_en[26] == oe_act) ? 1'bx : AD[26] ;
   assign AD_in[27] = (AD_en[27] == oe_act) ? 1'bx : AD[27] ;
   assign AD_in[28] = (AD_en[28] == oe_act) ? 1'bx : AD[28] ;
   assign AD_in[29] = (AD_en[29] == oe_act) ? 1'bx : AD[29] ;
   assign AD_in[30] = (AD_en[30] == oe_act) ? 1'bx : AD[30] ;
   assign AD_in[31] = (AD_en[31] == oe_act) ? 1'bx : AD[31] ;

   wire [3:0] 	   CBE_out ;
   wire [3:0] 	   CBE_en ;
   wire [3:0] 	   CBE_in  ;

   wire [3:0] 	   CBE64_out ;
   wire [3:0] 	   CBE64_en ;
   wire [3:0] 	   CBE64_in  ;
   
   assign CBE_in[3] = (CBE_en[3] == oe_act) ? 1'bx : CBE[3] ;
   assign CBE_in[2] = (CBE_en[2] == oe_act) ? 1'bx : CBE[2] ;
   assign CBE_in[1] = (CBE_en[1] == oe_act) ? 1'bx : CBE[1] ;
   assign CBE_in[0] = (CBE_en[0] == oe_act) ? 1'bx : CBE[0] ;
   
   wire            RST_in = RST ;
   wire            RST_out ;
   wire            RST_en ;
   
   wire            INTA_en ;
   wire            INTA_out ;
   wire            INTA_in = INTA  ;
   
   wire            REQ_en ;
   wire            REQ_out ;

   wire 	   REQ64_en ;
   wire 	   REQ64_out;
   wire            REQ64_in = REQ64 ;
   
   wire            FRAME_out ;
   wire            FRAME_en ;
   wire            FRAME_in = FRAME ;

   wire 	   ACK64_out;
   wire 	   ACK64_en;
   wire 	   ACK64_in = ACK64;
   
   wire            IRDY_out ;
   wire            IRDY_en ;
   wire            IRDY_in = IRDY ;
   
   wire            DEVSEL_out ;
   wire            DEVSEL_en ;
   wire            DEVSEL_in = DEVSEL ;
   
   wire            TRDY_out ;
   wire            TRDY_en ;
   wire            TRDY_in = TRDY ;
   
   wire            STOP_out ;
   wire            STOP_en ;
   wire            STOP_in = STOP ;
   
   wire            PAR_out ;
   wire            PAR_en ;
   wire            PAR_in = PAR ;

   wire            PAR64_out ;
   wire            PAR64_en ;
   wire            PAR64_in = PAR64 ;
   
   wire            PERR_out ;
   wire            PERR_en ;
   wire            PERR_in = PERR ;
   
   wire            SERR_out ;
   wire            SERR_en ;
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]		addr;			// From bridge of pci_bridge32.v
   wire			addr_vld;		// From bridge of pci_bridge32.v
   wire [31:0]		adio64_in;		// From master_tb of master_tb.v
   wire [31:0]		adio64_out;		// From bridge of pci_bridge32.v
   wire [31:0]		adio_in;		// From cfg_wait of cfg_wait.v, ...
   wire [31:0]		adio_out;		// From bridge of pci_bridge32.v
   wire			b_busy;			// From bridge of pci_bridge32.v
   wire			backoff;		// From bridge of pci_bridge32.v
   wire [7:0]		base_hit;		// From bridge of pci_bridge32.v
   wire			c_ready;		// From cfg_wait of cfg_wait.v
   wire			c_term;			// From cfg_wait of cfg_wait.v
   wire			cfg_hit;		// From bridge of pci_bridge32.v
   wire			cfg_vld;		// From bridge of pci_bridge32.v
   wire			complete;		// From master_tb of master_tb.v
   wire [39:0]		csr;			// From bridge of pci_bridge32.v
   wire			devselq_n;		// From bridge of pci_bridge32.v
   wire			dr_bus;			// From bridge of pci_bridge32.v
   wire			frameq_n;		// From bridge of pci_bridge32.v
   wire			i_idle;			// From bridge of pci_bridge32.v
   wire			idle;			// From bridge of pci_bridge32.v
   wire			irdyq_n;		// From bridge of pci_bridge32.v
   wire			m_addr_n;		// From bridge of pci_bridge32.v
   wire [3:0]		m_cbe;			// From master_tb of master_tb.v
   wire [3:0]		m_cbe64;		// From master_tb of master_tb.v
   wire			m_data;			// From bridge of pci_bridge32.v
   wire			m_data_vld;		// From bridge of pci_bridge32.v
   wire			m_ready;		// From master_tb of master_tb.v
   wire			m_src_en;		// From bridge of pci_bridge32.v
   wire			m_wrdn;			// From master_tb of master_tb.v
   wire [15:0]		pci_cmd;		// From bridge of pci_bridge32.v
   wire			perrq_n;		// From bridge of pci_bridge32.v
   wire			request;		// From master_tb of master_tb.v
   wire			request64;		// From master_tb of master_tb.v
   wire			requesthold;		// From master_tb of master_tb.v
   wire			s_abort;		// From mem_target of mem_target.v
   wire [3:0]		s_cbe;			// From bridge of pci_bridge32.v
   wire [3:0]		s_cbe64;		// From bridge of pci_bridge32.v
   wire			s_data;			// From bridge of pci_bridge32.v
   wire			s_data_vld;		// From bridge of pci_bridge32.v
   wire			s_ready;		// From mem_target of mem_target.v
   wire			s_src_en;		// From bridge of pci_bridge32.v
   wire			s_term;			// From mem_target of mem_target.v
   wire			s_wrdn;			// From bridge of pci_bridge32.v
   wire			serrq_n;		// From bridge of pci_bridge32.v
   wire			stopq_n;		// From bridge of pci_bridge32.v
   wire			time_out;		// From bridge of pci_bridge32.v
   wire			trdyq_n;		// From bridge of pci_bridge32.v
   // End of automatics
   
pci_bridge32 bridge
(
    // pci interface - system pins
    .pci_clk_i    (CLK),
    .pci_rst_i    ( RST_in ),
    .pci_rst_o    ( RST_out ),
    .pci_inta_i   ( INTA_in ),
    .pci_inta_o   ( INTA_out),
    .pci_rst_oe_o ( RST_en),
    .pci_inta_oe_o(INTA_en),

    // arbitration pins
    .pci_req_o   ( REQ_out ),
    .pci_req_oe_o( REQ_en ),

    .pci_gnt_i   ( GNT ),

    // protocol pins
    .pci_frame_i   ( FRAME_in),
    .pci_frame_o   ( FRAME_out ),
    .pci_frame_oe_o( FRAME_en ),
 
    .pci_req64_i   ( REQ64_in),
    .pci_req64_o   ( REQ64_out ),
    .pci_req64_oe_o( REQ64_en ),

    .pci_ack64_i   ( ACK64_in),
    .pci_ack64_o   ( ACK64_out ),
    .pci_ack64_oe_o( ACK64_en ),

    .pci_irdy_oe_o ( IRDY_en ),
    .pci_devsel_oe_o( DEVSEL_en ),
    .pci_trdy_oe_o ( TRDY_en ),
    .pci_stop_oe_o ( STOP_en ),
    .pci_ad_oe_o   (AD_en),
    .pci_ad64_oe_o   (AD64_en),
    .pci_cbe_oe_o  ( CBE_en) ,
    .pci_cbe64_oe_o  ( CBE64_en) ,
 
    .pci_irdy_i    ( IRDY_in ),
    .pci_irdy_o    ( IRDY_out ),
                    
    .pci_idsel_i   ( IDSEL ),
                    
    .pci_devsel_i  ( DEVSEL_in ),
    .pci_devsel_o  ( DEVSEL_out ),
                    
    .pci_trdy_i    ( TRDY_in ),
    .pci_trdy_o    ( TRDY_out ),
                    
    .pci_stop_i    ( STOP_in ),
    .pci_stop_o    ( STOP_out ),

    // data transfer pins
    .pci_ad_i(AD_in),
    .pci_ad_o(AD_out),
    .pci_ad64_i(AD64_in),
    .pci_ad64_o(AD64_out),
 
    .pci_cbe_i( CBE_in ),
    .pci_cbe_o( CBE_out ),
    .pci_cbe64_i( CBE64_in ),
    .pci_cbe64_o( CBE64_out ),
 
    // parity generation and checking pins
    .pci_par_i    ( PAR_in ),
    .pci_par_o    ( PAR_out ),
    .pci_par_oe_o ( PAR_en ),

    .pci_par64_i    ( PAR64_in ),
    .pci_par64_o    ( PAR64_out ),
    .pci_par64_oe_o ( PAR64_en ),
 
    .pci_perr_i   ( PERR_in ),
    .pci_perr_o   ( PERR_out ),
    .pci_perr_oe_o( PERR_en ),

    // system error pin
    .pci_serr_o   ( SERR_out ),
    .pci_serr_oe_o( SERR_en )

 ,
 /*AUTOINST*/
 // Outputs
 .addr					(addr[31:0]),
 .adio_out				(adio_out[31:0]),
 .adio64_out				(adio64_out[31:0]),
 .addr_vld				(addr_vld),
 .cfg_vld				(cfg_vld),
 .s_data_vld				(s_data_vld),
 .s_src_en				(s_src_en),
 .s_wrdn				(s_wrdn),
 .pci_cmd				(pci_cmd[15:0]),
 .s_cbe					(s_cbe[3:0]),
 .s_cbe64				(s_cbe64[3:0]),
 .base_hit				(base_hit[7:0]),
 .cfg_hit				(cfg_hit),
 .m_data_vld				(m_data_vld),
 .m_src_en				(m_src_en),
 .time_out				(time_out),
 .m_data				(m_data),
 .dr_bus				(dr_bus),
 .m_addr_n				(m_addr_n),
 .i_idle				(i_idle),
 .idle					(idle),
 .b_busy				(b_busy),
 .s_data				(s_data),
 .backoff				(backoff),
 .frameq_n				(frameq_n),
 .devselq_n				(devselq_n),
 .irdyq_n				(irdyq_n),
 .trdyq_n				(trdyq_n),
 .stopq_n				(stopq_n),
 .perrq_n				(perrq_n),
 .serrq_n				(serrq_n),
 .csr					(csr[39:0]),
 // Inputs
 .adio_in				(adio_in[31:0]),
 .adio64_in				(adio64_in[31:0]),
 .c_ready				(c_ready),
 .c_term				(c_term),
 .s_ready				(s_ready),
 .s_term				(s_term),
 .s_abort				(s_abort),
 .request				(request),
 .request64				(request64),
 .requesthold				(requesthold),
 .m_cbe					(m_cbe[3:0]),
 .m_cbe64				(m_cbe64[3:0]),
 .m_wrdn				(m_wrdn),
 .complete				(complete),
 .m_ready				(m_ready),
 .cfg_self				(cfg_self),
 .int_n					(int_n));
   
   
bufif0 AD_buf0   ( AD[0],  AD_out[0], AD_en[0]) ;
bufif0 AD_buf1   ( AD[1],  AD_out[1], AD_en[1]) ;
bufif0 AD_buf2   ( AD[2],  AD_out[2], AD_en[2]) ;
bufif0 AD_buf3   ( AD[3],  AD_out[3], AD_en[3]) ;
bufif0 AD_buf4   ( AD[4],  AD_out[4], AD_en[4]) ;
bufif0 AD_buf5   ( AD[5],  AD_out[5], AD_en[5]) ;
bufif0 AD_buf6   ( AD[6],  AD_out[6], AD_en[6]) ;
bufif0 AD_buf7   ( AD[7],  AD_out[7], AD_en[7]) ;
bufif0 AD_buf8   ( AD[8],  AD_out[8], AD_en[8]) ;
bufif0 AD_buf9   ( AD[9],  AD_out[9], AD_en[9]) ;
bufif0 AD_buf10  ( AD[10], AD_out[10],AD_en[10] ) ;
bufif0 AD_buf11  ( AD[11], AD_out[11],AD_en[11] ) ;
bufif0 AD_buf12  ( AD[12], AD_out[12],AD_en[12] ) ;
bufif0 AD_buf13  ( AD[13], AD_out[13],AD_en[13] ) ;
bufif0 AD_buf14  ( AD[14], AD_out[14],AD_en[14] ) ;
bufif0 AD_buf15  ( AD[15], AD_out[15],AD_en[15] ) ;
bufif0 AD_buf16  ( AD[16], AD_out[16],AD_en[16] ) ;
bufif0 AD_buf17  ( AD[17], AD_out[17],AD_en[17] ) ;
bufif0 AD_buf18  ( AD[18], AD_out[18],AD_en[18] ) ;
bufif0 AD_buf19  ( AD[19], AD_out[19],AD_en[19] ) ;
bufif0 AD_buf20  ( AD[20], AD_out[20],AD_en[20] ) ;
bufif0 AD_buf21  ( AD[21], AD_out[21],AD_en[21] ) ;
bufif0 AD_buf22  ( AD[22], AD_out[22],AD_en[22] ) ;
bufif0 AD_buf23  ( AD[23], AD_out[23],AD_en[23] ) ;
bufif0 AD_buf24  ( AD[24], AD_out[24],AD_en[24] ) ;
bufif0 AD_buf25  ( AD[25], AD_out[25],AD_en[25] ) ;
bufif0 AD_buf26  ( AD[26], AD_out[26],AD_en[26] ) ;
bufif0 AD_buf27  ( AD[27], AD_out[27],AD_en[27] ) ;
bufif0 AD_buf28  ( AD[28], AD_out[28],AD_en[28] ) ;
bufif0 AD_buf29  ( AD[29], AD_out[29],AD_en[29] ) ;
bufif0 AD_buf30  ( AD[30], AD_out[30],AD_en[30] ) ;
bufif0 AD_buf31  ( AD[31], AD_out[31],AD_en[31] ) ;

bufif0 CBE_buf0 ( CBE[0], CBE_out[0], CBE_en[0] ) ;
bufif0 CBE_buf1 ( CBE[1], CBE_out[1], CBE_en[1] ) ;
bufif0 CBE_buf2 ( CBE[2], CBE_out[2], CBE_en[2] ) ;
bufif0 CBE_buf3 ( CBE[3], CBE_out[3], CBE_en[3] ) ;

bufif0 FRAME_buf    ( FRAME, FRAME_out, FRAME_en ) ;
bufif0 IRDY_buf     ( IRDY, IRDY_out, IRDY_en ) ;
bufif0 DEVSEL_buf   ( DEVSEL, DEVSEL_out, DEVSEL_en ) ;
bufif0 TRDY_buf     ( TRDY, TRDY_out, TRDY_en ) ;
bufif0 STOP_buf     ( STOP, STOP_out, STOP_en ) ;

bufif0 INTA_buf     ( INTA, INTA_out, INTA_en) ;
bufif0 REQ_buf      ( REQ, REQ_out, REQ_en ) ;
bufif0 PAR_buf      ( PAR, PAR_out, PAR_en ) ;
bufif0 PERR_buf     ( PERR, PERR_out, PERR_en ) ;
bufif0 SERR_buf     ( SERR, SERR_out, SERR_en ) ;

   wire 		reset = ~RST_in;

   cfg_wait cfg_wait (/*AUTOINST*/
		      // Outputs
		      .adio_in		(adio_in[31:0]),
		      .c_term		(c_term),
		      .c_ready		(c_ready),
		      // Inputs
		      .reset		(reset),
		      .CLK		(CLK),
		      .cfg_hit		(cfg_hit),
		      .cfg_vld		(cfg_vld),
		      .s_wrdn		(s_wrdn),
		      .s_data		(s_data),
		      .s_data_vld	(s_data_vld),
		      .addr		(addr[31:0]),
		      .adio_out		(adio_out[31:0]));

   mem_target mem_target (/*AUTOINST*/
			  // Outputs
			  .adio_in		(adio_in[31:0]),
			  .s_ready		(s_ready),
			  .s_term		(s_term),
			  .s_abort		(s_abort),
			  // Inputs
			  .reset		(reset),
			  .CLK			(CLK),
			  .s_wrdn		(s_wrdn),
			  .pci_cmd		(pci_cmd[15:0]),
			  .addr			(addr[31:0]),
			  .base_hit		(base_hit[7:0]),
			  .s_data		(s_data),
			  .s_data_vld		(s_data_vld),
			  .addr_vld		(addr_vld),
			  .adio_out		(adio_out[31:0]));

   master_tb  master_tb  (/*AUTOINST*/
			  // Outputs
			  .adio_in		(adio_in[31:0]),
			  .adio64_in		(adio64_in[31:0]),
			  .complete		(complete),
			  .m_ready		(m_ready),
			  .m_cbe		(m_cbe[3:0]),
			  .m_cbe64		(m_cbe64[3:0]),
			  .m_wrdn		(m_wrdn),
			  .request		(request),
			  .request64		(request64),
			  .requesthold		(requesthold),
			  // Inputs
			  .CLK			(CLK),
			  .reset		(reset),
			  .adio_out		(adio_out[31:0]),
			  .adio64_out		(adio64_out[31:0]),
			  .m_data		(m_data),
			  .m_data_vld		(m_data_vld),
			  .m_addr_n		(m_addr_n),
			  .csr			(csr[39:0]));

   assign AD64_in[0 ] = (AD64_en[0 ] == oe_act) ? 1'bx : AD64[0 ] ;
   assign AD64_in[1 ] = (AD64_en[1 ] == oe_act) ? 1'bx : AD64[1 ] ;
   assign AD64_in[2 ] = (AD64_en[2 ] == oe_act) ? 1'bx : AD64[2 ] ;
   assign AD64_in[3 ] = (AD64_en[3 ] == oe_act) ? 1'bx : AD64[3 ] ;
   assign AD64_in[4 ] = (AD64_en[4 ] == oe_act) ? 1'bx : AD64[4 ] ;
   assign AD64_in[5 ] = (AD64_en[5 ] == oe_act) ? 1'bx : AD64[5 ] ;
   assign AD64_in[6 ] = (AD64_en[6 ] == oe_act) ? 1'bx : AD64[6 ] ;
   assign AD64_in[7 ] = (AD64_en[7 ] == oe_act) ? 1'bx : AD64[7 ] ;
   assign AD64_in[8 ] = (AD64_en[8 ] == oe_act) ? 1'bx : AD64[8 ] ;
   assign AD64_in[9 ] = (AD64_en[9 ] == oe_act) ? 1'bx : AD64[9 ] ;
   assign AD64_in[10] = (AD64_en[10] == oe_act) ? 1'bx : AD64[10] ;
   assign AD64_in[11] = (AD64_en[11] == oe_act) ? 1'bx : AD64[11] ;
   assign AD64_in[12] = (AD64_en[12] == oe_act) ? 1'bx : AD64[12] ;
   assign AD64_in[13] = (AD64_en[13] == oe_act) ? 1'bx : AD64[13] ;
   assign AD64_in[14] = (AD64_en[14] == oe_act) ? 1'bx : AD64[14] ;
   assign AD64_in[15] = (AD64_en[15] == oe_act) ? 1'bx : AD64[15] ;
   assign AD64_in[16] = (AD64_en[16] == oe_act) ? 1'bx : AD64[16] ;
   assign AD64_in[17] = (AD64_en[17] == oe_act) ? 1'bx : AD64[17] ;
   assign AD64_in[18] = (AD64_en[18] == oe_act) ? 1'bx : AD64[18] ;
   assign AD64_in[19] = (AD64_en[19] == oe_act) ? 1'bx : AD64[19] ;
   assign AD64_in[20] = (AD64_en[20] == oe_act) ? 1'bx : AD64[20] ;
   assign AD64_in[21] = (AD64_en[21] == oe_act) ? 1'bx : AD64[21] ;
   assign AD64_in[22] = (AD64_en[22] == oe_act) ? 1'bx : AD64[22] ;
   assign AD64_in[23] = (AD64_en[23] == oe_act) ? 1'bx : AD64[23] ;
   assign AD64_in[24] = (AD64_en[24] == oe_act) ? 1'bx : AD64[24] ;
   assign AD64_in[25] = (AD64_en[25] == oe_act) ? 1'bx : AD64[25] ;
   assign AD64_in[26] = (AD64_en[26] == oe_act) ? 1'bx : AD64[26] ;
   assign AD64_in[27] = (AD64_en[27] == oe_act) ? 1'bx : AD64[27] ;
   assign AD64_in[28] = (AD64_en[28] == oe_act) ? 1'bx : AD64[28] ;
   assign AD64_in[29] = (AD64_en[29] == oe_act) ? 1'bx : AD64[29] ;
   assign AD64_in[30] = (AD64_en[30] == oe_act) ? 1'bx : AD64[30] ;
   assign AD64_in[31] = (AD64_en[31] == oe_act) ? 1'bx : AD64[31] ;

   assign CBE64_in[3] = (CBE64_en[3] == oe_act) ? 1'bx : CBE64[3] ;
   assign CBE64_in[2] = (CBE64_en[2] == oe_act) ? 1'bx : CBE64[2] ;
   assign CBE64_in[1] = (CBE64_en[1] == oe_act) ? 1'bx : CBE64[1] ;
   assign CBE64_in[0] = (CBE64_en[0] == oe_act) ? 1'bx : CBE64[0] ;

   bufif0 AD64_buf0   ( AD64[0],  AD64_out[0], AD64_en[0]) ;
   bufif0 AD64_buf1   ( AD64[1],  AD64_out[1], AD64_en[1]) ;
   bufif0 AD64_buf2   ( AD64[2],  AD64_out[2], AD64_en[2]) ;
   bufif0 AD64_buf3   ( AD64[3],  AD64_out[3], AD64_en[3]) ;
   bufif0 AD64_buf4   ( AD64[4],  AD64_out[4], AD64_en[4]) ;
   bufif0 AD64_buf5   ( AD64[5],  AD64_out[5], AD64_en[5]) ;
   bufif0 AD64_buf6   ( AD64[6],  AD64_out[6], AD64_en[6]) ;
   bufif0 AD64_buf7   ( AD64[7],  AD64_out[7], AD64_en[7]) ;
   bufif0 AD64_buf8   ( AD64[8],  AD64_out[8], AD64_en[8]) ;
   bufif0 AD64_buf9   ( AD64[9],  AD64_out[9], AD64_en[9]) ;
   bufif0 AD64_buf10  ( AD64[10], AD64_out[10],AD64_en[10] ) ;
   bufif0 AD64_buf11  ( AD64[11], AD64_out[11],AD64_en[11] ) ;
   bufif0 AD64_buf12  ( AD64[12], AD64_out[12],AD64_en[12] ) ;
   bufif0 AD64_buf13  ( AD64[13], AD64_out[13],AD64_en[13] ) ;
   bufif0 AD64_buf14  ( AD64[14], AD64_out[14],AD64_en[14] ) ;
   bufif0 AD64_buf15  ( AD64[15], AD64_out[15],AD64_en[15] ) ;
   bufif0 AD64_buf16  ( AD64[16], AD64_out[16],AD64_en[16] ) ;
   bufif0 AD64_buf17  ( AD64[17], AD64_out[17],AD64_en[17] ) ;
   bufif0 AD64_buf18  ( AD64[18], AD64_out[18],AD64_en[18] ) ;
   bufif0 AD64_buf19  ( AD64[19], AD64_out[19],AD64_en[19] ) ;
   bufif0 AD64_buf20  ( AD64[20], AD64_out[20],AD64_en[20] ) ;
   bufif0 AD64_buf21  ( AD64[21], AD64_out[21],AD64_en[21] ) ;
   bufif0 AD64_buf22  ( AD64[22], AD64_out[22],AD64_en[22] ) ;
   bufif0 AD64_buf23  ( AD64[23], AD64_out[23],AD64_en[23] ) ;
   bufif0 AD64_buf24  ( AD64[24], AD64_out[24],AD64_en[24] ) ;
   bufif0 AD64_buf25  ( AD64[25], AD64_out[25],AD64_en[25] ) ;
   bufif0 AD64_buf26  ( AD64[26], AD64_out[26],AD64_en[26] ) ;
   bufif0 AD64_buf27  ( AD64[27], AD64_out[27],AD64_en[27] ) ;
   bufif0 AD64_buf28  ( AD64[28], AD64_out[28],AD64_en[28] ) ;
   bufif0 AD64_buf29  ( AD64[29], AD64_out[29],AD64_en[29] ) ;
   bufif0 AD64_buf30  ( AD64[30], AD64_out[30],AD64_en[30] ) ;
   bufif0 AD64_buf31  ( AD64[31], AD64_out[31],AD64_en[31] ) ;
   
   bufif0 CBE64_buf0 ( CBE64[0], CBE64_out[0], CBE64_en[0] ) ;
   bufif0 CBE64_buf1 ( CBE64[1], CBE64_out[1], CBE64_en[1] ) ;
   bufif0 CBE64_buf2 ( CBE64[2], CBE64_out[2], CBE64_en[2] ) ;
   bufif0 CBE64_buf3 ( CBE64[3], CBE64_out[3], CBE64_en[3] ) ;

   //bufif0 ACK64_buf  ( ACK64, ACK64_out, ACK64_en);
   //bufif0 REQ64_buf  ( REQ64, REQ64_out, REQ64_en);
   bufif0 REQ64_buf  ( REQ64, FRAME_out, FRAME_en);
   bufif0 PAR64_buf  ( PAR64, PAR64_out, PAR64_en);
   
endmodule // TOP

// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/")
// verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v")
// verilog-library-extensions:(".v" ".h")
// End:
