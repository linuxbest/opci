//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "meta_flop.v"                                     ////
////                                                              ////
////  This file is part of the "PCI bridge" project               ////
////  http://www.opencores.org/cores/pci/                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Miha Dolenc (mihad@opencores.org)                     ////
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
// $Log: meta_flop.v,v $
// Revision 1.1  2002/09/30 16:03:04  mihad
// Added meta flop module for easier meta stable FF identification during synthesis
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

// this module is just an ordinary flip-flop - used for identifying meta stable critical flip flops - similar to synchronizer flop
module meta_flop
(
    rst_i,
    clk_i,
    ld_i,
    ld_val_i,
    en_i,
    d_i,
    meta_q_o
) ;

parameter p_reset_value = 0 ;

input   rst_i,
        clk_i,
        ld_i,
        ld_val_i,
        en_i,
        d_i ;

output  meta_q_o ;
reg     meta_q_o ;

always@(posedge rst_i or posedge clk_i)
begin
    if (rst_i)
        meta_q_o <= #1 p_reset_value ;
    else if (ld_i)
        meta_q_o <= #1 ld_val_i ;
    else if (en_i)
        meta_q_o <= #1 d_i ;
end

endmodule