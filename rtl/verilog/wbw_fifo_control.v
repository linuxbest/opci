//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "wbw_fifo_control.v"                              ////
////                                                              ////
////  This file is part of the "PCI bridge" project               ////
////  http://www.opencores.org/cores/pci/                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Miha Dolenc (mihad@opencores.org)                     ////
////                                                              ////
////  All additional information is avaliable in the README       ////
////  file.                                                       ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Miha Dolenc, mihad@opencores.org          ////
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
// $Log: wbw_fifo_control.v,v $
// Revision 1.4  2002/09/25 15:53:52  mihad
// Removed all logic from asynchronous reset network
//
// Revision 1.3  2002/02/01 15:25:14  mihad
// Repaired a few bugs, updated specification, added test bench files and design document
//
// Revision 1.2  2001/10/05 08:14:30  mihad
// Updated all files with inclusion of timescale file for simulation purposes.
//
// Revision 1.1.1.1  2001/10/02 15:33:47  mihad
// New project directory structure
//
//

/* FIFO_CONTROL module provides read/write address and status generation for
   FIFOs implemented with standard dual port SRAM cells in ASIC or FPGA designs */
`include "pci_constants.v"
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

module WBW_FIFO_CONTROL
(
    rclock_in,
    wclock_in,
    renable_in,
    wenable_in,
    reset_in,
//    flush_in, // not used
    almost_full_out,
    full_out,
    empty_out,
    waddr_out,
    raddr_out,
    rallow_out,
    wallow_out
);

parameter ADDR_LENGTH = 7 ;

// independent clock inputs - rclock_in = read clock, wclock_in = write clock
input  rclock_in, wclock_in;

// enable inputs - read address changes on rising edge of rclock_in when reads are allowed
//                 write address changes on rising edge of wclock_in when writes are allowed
input  renable_in, wenable_in ;

// reset input
input  reset_in;

// flush input
// input flush_in ; // not used

// almost full and empy status outputs
output almost_full_out ;

// full and empty status outputs
output full_out, empty_out;

// read and write addresses outputs
output [(ADDR_LENGTH - 1):0] waddr_out, raddr_out;

// read and write allow outputs
output rallow_out, wallow_out ;

// read address register
reg [(ADDR_LENGTH - 1):0] raddr ;

// write address register
reg [(ADDR_LENGTH - 1):0] waddr;
assign waddr_out = waddr ;

// grey code registers
// grey code pipeline for write address
reg [(ADDR_LENGTH - 1):0] wgrey_addr ; // current
reg [(ADDR_LENGTH - 1):0] wgrey_next ; // next

// next write gray address calculation - bitwise xor between address and shifted address
wire [(ADDR_LENGTH - 2):0] calc_wgrey_next  = waddr[(ADDR_LENGTH - 1):1] ^ waddr[(ADDR_LENGTH - 2):0] ;

// grey code pipeline for read address
reg [(ADDR_LENGTH - 1):0] rgrey_minus2 ; // two before current
reg [(ADDR_LENGTH - 1):0] rgrey_minus1 ; // one before current
reg [(ADDR_LENGTH - 1):0] rgrey_addr ; // current
reg [(ADDR_LENGTH - 1):0] rgrey_next ; // next

// next read gray address calculation - bitwise xor between address and shifted address
wire [(ADDR_LENGTH - 2):0] calc_rgrey_next  = raddr[(ADDR_LENGTH - 1):1] ^ raddr[(ADDR_LENGTH - 2):0] ;

// FFs for registered empty and full flags
reg empty ;
reg full ;

// almost_full tag
reg almost_full ;

// write allow wire - writes are allowed when fifo is not full
wire wallow = wenable_in && ~full ;

// write allow output assignment
assign wallow_out = wallow && ~full ;

// read allow wire
wire rallow ;

// full output assignment
assign full_out  = full ;

// almost full output assignment
assign almost_full_out  = almost_full && ~full ;

// clear generation for FFs and registers
wire clear = reset_in /*|| flush_in*/ ;     // flush not used

reg wclock_nempty_detect ;
always@(posedge clear or posedge wclock_in)
begin
    if (clear)
        wclock_nempty_detect <= #`FF_DELAY 1'b0 ;
    else
        wclock_nempty_detect <= #`FF_DELAY (rgrey_addr != wgrey_addr) ;
end

// special synchronizing mechanism for different implementations - in synchronous imp., empty is prolonged for 1 clock edge if no write clock comes after initial write
reg stretched_empty ;
always@(posedge rclock_in or posedge clear)
begin
    if(clear)
        stretched_empty <= #`FF_DELAY 1'b1 ;
    else
        stretched_empty <= #`FF_DELAY empty && ~wclock_nempty_detect ;
end

// empty output is actual empty + 1 read clock cycle ( stretched empty )
assign empty_out = empty || stretched_empty ;

//rallow generation
assign rallow = renable_in && ~empty && ~stretched_empty ; // reads allowed if read enable is high and FIFO is not empty

// rallow output assignment
assign rallow_out = rallow ;

// at any clock edge that rallow is high, this register provides next read address, so wait cycles are not necessary
// when FIFO is empty, this register provides actual read address, so first location can be read
reg [(ADDR_LENGTH - 1):0] raddr_plus_one ;

// address output mux - when FIFO is empty, current actual address is driven out, when it is non - empty next address is driven out
// done for zero wait state burst
assign raddr_out = rallow ? raddr_plus_one : raddr ;

always@(posedge rclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is important - raddr initial value is 4, so this one is 5
        raddr_plus_one <= #`FF_DELAY 5 ;
    end
    else if (rallow)
        raddr_plus_one <= #`FF_DELAY raddr_plus_one + 1'b1 ;
end

// raddr is filled with raddr_plus_one on rising read clock edge when rallow is high
always@(posedge rclock_in or posedge clear)
begin
    if (clear)
        // initial value is 4
    raddr <= #`FF_DELAY 4 ;
    else if (rallow)
        raddr <= #`FF_DELAY raddr_plus_one ;
end

/*-----------------------------------------------------------------------------------------------
Read address control consists of Read address counter and Grey Address pipeline
There are 4 Grey addresses:
    - rgrey_minus2 is Grey Code of address two before current address
    - rgrey_minus1 is Grey Code of address one before current address
    - rgrey_addr is Grey Code of current read address
    - rgrey_next is Grey Code of next read address
--------------------------------------------------------------------------------------------------*/

// grey code register for two before read address
always@(posedge rclock_in or posedge clear)
begin
	if (clear)
    begin
        // initial value is 0
        rgrey_minus2 <= #`FF_DELAY 0 ;
    end
    else
    if (rallow)
        rgrey_minus2 <= #`FF_DELAY rgrey_minus1 ;
end

// grey code register for one before read address
always@(posedge rclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is 1
        rgrey_minus1 <= #`FF_DELAY 1 ;
    end
    else
    if (rallow)
        rgrey_minus1 <= #`FF_DELAY rgrey_addr ;
end

// grey code register for read address - represents current Read Address
always@(posedge rclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is 3 = ...00011
        rgrey_addr <= #`FF_DELAY 3 ;
    end
    else
    if (rallow)
        rgrey_addr <= #`FF_DELAY rgrey_next ;
end

// grey code register for next read address - represents Grey Code of next read address
always@(posedge rclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is 2 = ...00010
        rgrey_next <= #`FF_DELAY 2 ;
    end
    else
    if (rallow)
        rgrey_next <= #`FF_DELAY {raddr[ADDR_LENGTH - 1], calc_rgrey_next} ;
end

/*--------------------------------------------------------------------------------------------
Write address control consists of write address counter and two Grey Code Registers:
    - wgrey_addr represents current Grey Coded write address
    - wgrey_next represents Grey Coded next write address
----------------------------------------------------------------------------------------------*/
// grey code register for write address
always@(posedge wclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is 3 = ....011
        wgrey_addr <= #`FF_DELAY 3 ;
    end
    else
    if (wallow)
        wgrey_addr <= #`FF_DELAY wgrey_next ;
end

// grey code register for next write address
always@(posedge wclock_in or posedge clear)
begin
    if (clear)
    begin
        // initial value is 2 = ...010
        wgrey_next <= #`FF_DELAY 2 ;
    end
    else
    if (wallow)
        wgrey_next <= #`FF_DELAY {waddr[(ADDR_LENGTH - 1)], calc_wgrey_next} ;
end

// write address counter - nothing special - initial value is important though
always@(posedge wclock_in or posedge clear)
begin
    if (clear)
        // initial value 4
	waddr <= #`FF_DELAY 4 ;
    else
    if (wallow)
        waddr <= #`FF_DELAY waddr + 1'b1 ;
end

/*------------------------------------------------------------------------------------------------------------------------------
Registered full control:
registered full is set on rising edge of wclock_in when there is one free location in and another written to fifo
It's kept high until something is read from FIFO, which is registered on
next rising write clock edge.

Registered almost full control:
Almost full flag is set on rising wclock_in edge when there are two unused locations left in and another written to fifo.
It is set until something is read/written from/to fifo
--------------------------------------------------------------------------------------------------------------------------------*/
//combinatorial input to Registered full FlipFlop
wire reg_full = wallow && (wgrey_next == rgrey_minus1) || (wgrey_next == rgrey_addr) ;

always@(posedge wclock_in or posedge clear)
begin
	if (clear)
		full <= #`FF_DELAY 1'b0 ;
	else
		full <= #`FF_DELAY reg_full ;
end

// input for almost full latch
wire reg_almost_full_in = wallow && (wgrey_next == rgrey_minus2) || (wgrey_next == rgrey_minus1) ;

always@(posedge clear or posedge wclock_in)
begin
    if (clear)
        almost_full <= #`FF_DELAY 1'b0 ;
    else
        almost_full <= #`FF_DELAY reg_almost_full_in ;
end

/*------------------------------------------------------------------------------------------------------------------------------
Registered empty control:
registered empty is set on rising edge of rclock_in when one location is used and read from fifo. It's kept high
until something is written to the fifo, which is registered on the next clock edge.

Registered almost empty control:
Almost empty is set on rising edge of rclock_in when two locations are used and one read. It's kept set until something
is read/written from/to fifo.
--------------------------------------------------------------------------------------------------------------------------------*/
// combinatorial input for registered emty FlipFlop
wire comb_almost_empty = (rgrey_next == wgrey_addr) ;
wire comb_empty        = (rgrey_addr == wgrey_addr) ;
wire reg_empty         = renable_in && comb_almost_empty  || comb_empty ;

always@(posedge rclock_in or posedge clear)
begin
    if (clear)
        empty <= #`FF_DELAY 1'b1 ;
	else
        empty <= #`FF_DELAY reg_empty ;
end

endmodule
