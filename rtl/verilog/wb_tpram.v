//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Two-Port Synchronous RAM                            ////
////                                                              ////
////  This file is part of pci bridge project                     ////
////  http://www.opencores.org/cvsweb.shtml/pci/                  ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common two-port                ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  two-port synchronous RAM.                                   ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Double-Port Sync RAM                              ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage 2-port Sync RAM                                    ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Xilinx Virtex RAMB4_S16_S16                               ////
////                                                              ////
////  To Do:                                                      ////
////   - fix Avant!                                               ////
////   - xilinx rams need external tri-state logic                ////
////   - add additional RAMs (Altera, VS etc)                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////      - Miha Dolenc, mihad@opencores.org                      ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: wb_tpram.v,v $
// Revision 1.3  2002/09/30 17:22:27  mihad
// Added support for Virtual Silicon two port RAM. Didn't run regression on it yet!
//
// Revision 1.2  2002/08/19 16:51:36  mihad
// Extracted distributed RAM module from wb/pci_tpram.v to its own file, got rid of undef directives
//
// Revision 1.1  2002/02/01 14:43:31  mihad
// *** empty log message ***
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "pci_constants.v"

module WB_TPRAM
(
	// Generic synchronous two-port RAM interface
	clk_a,
    rst_a,
    ce_a,
    we_a,
    oe_a,
    addr_a,
    di_a,
    do_a,
	clk_b,
    rst_b,
    ce_b,
    we_b,
    oe_b,
    addr_b,
    di_b,
    do_b
);

//
// Default address and data buses width
//
parameter aw = 8;
parameter dw = 40;

//
// Generic synchronous two-port RAM interface
//
input			clk_a;	// Clock
input			rst_a;	// Reset
input			ce_a;	// Chip enable input
input			we_a;	// Write enable input
input			oe_a;	// Output enable input
input 	[aw-1:0]	addr_a;	// address bus inputs
input	[dw-1:0]	di_a;	// input data bus
output	[dw-1:0]	do_a;	// output data bus
input			clk_b;	// Clock
input			rst_b;	// Reset
input			ce_b;	// Chip enable input
input			we_b;	// Write enable input
input			oe_b;	// Output enable input
input 	[aw-1:0]	addr_b;	// address bus inputs
input	[dw-1:0]	di_b;	// input data bus
output	[dw-1:0]	do_b;	// output data bus

//
// Internal wires and registers
//

`ifdef WB_VS_STP
    `define PCI_WB_RAM_SELECTED
    vs_hdtp_64x40 i_vs_hdtp_64x40
    (
        .RCK        (clk_b),
        .WCK        (clk_a),
        .RADR       (addr_b),
        .WADR       (addr_a),
        .DI         (di_a),
        .DOUT       (do_b),
        .REN        (1'b0),
        .WEN        (!we_a)
    );
    
    assign do_a = 0 ;
`endif

`ifdef WB_ARTISAN_SDP
    `define PCI_WB_RAM_SELECTED
    //
    // Instantiation of ASIC memory:
    //
    // Artisan Synchronous Double-Port RAM (ra2sh)
    //
    art_hsdp_256x40 /*#(dw, 1<<aw, aw) */ artisan_sdp
    (
    	.qa(do_a),
    	.clka(clk_a),
    	.cena(~ce_a),
    	.wena(~we_a),
    	.aa(addr_a),
    	.da(di_a),
    	.oena(~oe_a),
    	.qb(do_b),
    	.clkb(clk_b),
    	.cenb(~ce_b),
    	.wenb(~we_b),
    	.ab(addr_b),
    	.db(di_b),
    	.oenb(~oe_b)
    );

`endif

`ifdef AVANT_ATP
    `define PCI_WB_RAM_SELECTED
    //
    // Instantiation of ASIC memory:
    //
    // Avant! Asynchronous Two-Port RAM
    //
    avant_atp avant_atp(
    	.web(~we),
    	.reb(),
    	.oeb(~oe),
    	.rcsb(),
    	.wcsb(),
    	.ra(addr),
    	.wa(addr),
    	.di(di),
    	.do(do)
    );

`endif

`ifdef VIRAGE_STP
    `define PCI_WB_RAM_SELECTED
    //
    // Instantiation of ASIC memory:
    //
    // Virage Synchronous 2-port R/W RAM
    //
    virage_stp virage_stp(
    	.QA(do_a),
    	.QB(do_b),

    	.ADRA(addr_a),
    	.DA(di_a),
    	.WEA(we_a),
    	.OEA(oe_a),
    	.MEA(ce_a),
    	.CLKA(clk_a),

    	.ADRB(adr_b),
    	.DB(di_b),
    	.WEB(we_b),
    	.OEB(oe_b),
    	.MEB(ce_b),
    	.CLKB(clk_b)
    );

`endif

`ifdef WB_XILINX_DIST_RAM
    `define PCI_WB_RAM_SELECTED

    reg [(aw-1):0] out_address ;
    always@(posedge clk_b or posedge rst_b)
    begin
        if ( rst_b )
            out_address <= #1 0 ;
        else if (ce_b)
            out_address <= #1 addr_b ;
    end

    pci_ram_16x40d #(aw) wb_distributed_ram
    (
        .data_out       (do_b),
        .we             (we_a),
        .data_in        (di_a),
        .read_address   (out_address),
        .write_address  (addr_a),
        .wclk           (clk_a)
    );
    assign do_a = 0 ;
`endif
`ifdef WB_XILINX_RAMB4
    `define PCI_WB_RAM_SELECTED
    //
    // Instantiation of FPGA memory:
    //
    // Virtex/Spartan2
    //

    //
    // Block 0
    //

    RAMB4_S16_S16 ramb4_s16_s16_0(
    	.CLKA(clk_a),
    	.RSTA(rst_a),
    	.ADDRA(addr_a),
    	.DIA(di_a[15:0]),
    	.ENA(ce_a),
    	.WEA(we_a),
    	.DOA(do_a[15:0]),

    	.CLKB(clk_b),
    	.RSTB(rst_b),
    	.ADDRB(addr_b),
    	.DIB(di_b[15:0]),
    	.ENB(ce_b),
    	.WEB(we_b),
    	.DOB(do_b[15:0])
    );

    //
    // Block 1
    //

    RAMB4_S16_S16 ramb4_s16_s16_1(
    	.CLKA(clk_a),
    	.RSTA(rst_a),
    	.ADDRA(addr_a),
    	.DIA(di_a[31:16]),
    	.ENA(ce_a),
    	.WEA(we_a),
    	.DOA(do_a[31:16]),

    	.CLKB(clk_b),
    	.RSTB(rst_b),
    	.ADDRB(addr_b),
    	.DIB(di_b[31:16]),
    	.ENB(ce_b),
    	.WEB(we_b),
    	.DOB(do_b[31:16])
    );

    //
    // Block 2
    //
    // block ram2 wires - non generic width of block rams
    wire [15:0] blk2_di_a = {8'h00, di_a[39:32]} ;
    wire [15:0] blk2_di_b = {8'h00, di_b[39:32]} ;

    wire [15:0] blk2_do_a ;
    wire [15:0] blk2_do_b ;

    assign do_a[39:32] = blk2_do_a[7:0] ;
    assign do_b[39:32] = blk2_do_b[7:0] ;

    RAMB4_S16_S16 ramb4_s16_s16_2(
            .CLKA(clk_a),
            .RSTA(rst_a),
            .ADDRA(addr_a),
            .DIA(blk2_di_a),
            .ENA(ce_a),
            .WEA(we_a),
            .DOA(blk2_do_a),

            .CLKB(clk_b),
            .RSTB(rst_b),
            .ADDRB(addr_b),
            .DIB(blk2_di_b),
            .ENB(ce_b),
            .WEB(we_b),
            .DOB(blk2_do_b)
    );

`endif

`ifdef PCI_WB_RAM_SELECTED
`else
    //
    // Generic two-port synchronous RAM model
    //

    //
    // Generic RAM's registers and wires
    //
    reg	[dw-1:0]	mem [(1<<aw)-1:0];	// RAM content
    reg	[dw-1:0]	do_reg_a;		// RAM data output register
    reg	[dw-1:0]	do_reg_b;		// RAM data output register

    //
    // Data output drivers
    //
    assign do_a = (oe_a) ? do_reg_a : {dw{1'bz}};
    assign do_b = (oe_b) ? do_reg_b : {dw{1'bz}};

    //
    // RAM read and write
    //
    always @(posedge clk_a)
    	if (ce_a && !we_a)
    		do_reg_a <= #1 mem[addr_a];
    	else if (ce_a && we_a)
    		mem[addr_a] <= #1 di_a;

    //
    // RAM read and write
    //
    always @(posedge clk_b)
    	if (ce_b && !we_b)
    		do_reg_b <= #1 mem[addr_b];
    	else if (ce_b && we_b)
    		mem[addr_b] <= #1 di_b;
`endif

// synopsys translate_off
initial
begin
    if (dw !== 40)
    begin
        $display("RAM instantiation error! Expected RAM width %d, actual %h!", 40, dw) ;
        $finish ;
    end
    `ifdef XILINX_RAMB4
        if (aw !== 8)
        begin
            $display("RAM instantiation error! Expected RAM address width %d, actual %h!", 40, aw) ;
            $finish ;
        end
    `endif
    // currenlty only artisan ram of depth 256 is supported - they don't provide generic ram models
    `ifdef ARTISAN_SDP
        if (aw !== 8)
        begin
            $display("RAM instantiation error! Expected RAM address width %d, actual %h!", 40, aw) ;
            $finish ;
        end
    `endif
end
// synopsys translate_on

endmodule
