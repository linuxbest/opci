
/*
 * Copyright 2002 Picture Elements
 *    Stephen Williams <steve@icarus.com>
 *
 *    This source code is free software; you can redistribute it
 *    and/or modify it in source code form under the terms of the GNU
 *    General Public License as published by the Free Software
 *    Foundation; either version 2 of the License, or (at your option)
 *    any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

`timescale 1ns / 1ns

/*
 * This implementes a PCI arbiter of arbitrary width. It receives the
 * PCI clock from the outside, as well as a vector of REQ signals. An
 * arbitration decision is made, and a single GNT made active, using
 * round-robin scheduling.
 */

module pci_arbiter(CLK, RESET, FRAME, IRDY, REQ, GNT);

   parameter width = 4;

   input     CLK, RESET, FRAME, IRDY;

   input  [(width-1) : 0] REQ;
   output [(width-1) : 0] GNT;

   wire   [(width-1) : 0] REQ;
   reg    [(width-1) : 0] GNT;

   reg [(width-1) : 0] 	  sel = 1;


   // A convenience clear_gnt clears all the GNT output bits.
   task clear_gnt;
      integer idx;
      begin
	 for (idx = 0 ;  idx < width ;  idx = idx + 1)
	   GNT[idx] <= 1'b1;
      end
   endtask // clear_gnt

   localparam IDLE       = 0;
   localparam OFFER_HOLD = 1;
   localparam OFFER      = 2;
   reg [2:0] state = IDLE;
   always @(posedge CLK)
      if (RESET == 0) begin
	 // The RESET is active, clear all the grants and start
	 // the scheduler back at the beginning.
	 clear_gnt;
	 sel = 1;
	 state = IDLE;

      end else begin
      //$write(" arb clock, REQ %h, %h, %h, %h\n", REQ[0], REQ[1], REQ[2], REQ[3]);
	 case (state)

	   // In IDLE state, wait for REQ.
	   IDLE:
	     if (&REQ == 0) begin
		// There is at least one REQ active. Scan forward the select
		// bit until I select one that is requesting, and change the
		// GNT output. This has the effect of leaving the GNT where
		// it is if the current requester is also the selected GNT.
		while ((REQ & sel) != 0) begin
		   sel = sel << 1;
		   //$write("sel %x, REQ %h\n", sel, REQ);
		   if (sel == 0)
		     sel = 1;
		end
		GNT <= ~sel;
		//$write("gnt %h, %h\n", GNT, sel);
		if (FRAME == 0)
		  state = OFFER_HOLD;
		else
		  state = OFFER;
	     end

	   // In OFFER_HOLD, GNT a REQ while the last granted
	   // transaction is still active. Remain in this state
	   // until the pending transaction finishes.
	   OFFER_HOLD:
	     if ((FRAME&IRDY) != 0)
	       state = OFFER;

	   // In offer, wait for the master to receive the grant
	   // by activating a frame. Then withdraw the GNT and
	   // return to IDLE state, ready for another REQ.
	   OFFER:
	     if (FRAME == 0) begin
		clear_gnt;
		state = IDLE;
	     end

	 endcase // case(state)
      end


endmodule // arbiter
