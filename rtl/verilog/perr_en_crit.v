//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "perr_en_crit.v"                                  ////
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
//// Copyright (C) 2000 Miha Dolenc, mihad@opencores.org          ////
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
// $Log: perr_en_crit.v,v $
// Revision 1.1  2001/10/02 15:33:47  mihad
// Initial revision
//
//

// module is used to separate logic which uses criticaly constrained inputs from slower logic.
// It is used to synthesize critical timing logic separately with faster cells or without optimization

// This one is used in parity generator/checker for parity error (PERR#) output enable driving

module PERR_EN_CRIT
(
    reset_in,
    clk_in,
    perr_en_out,
    perr_en_reg_out,
    non_critical_par_in,
    pci_par_in,
    perr_generate_in,
    par_err_response_in
) ;
output  perr_en_out,
        perr_en_reg_out ;
    
input   reset_in,
        clk_in,
        non_critical_par_in,
        pci_par_in,
        perr_generate_in,
        par_err_response_in ;

wire perr = par_err_response_in && perr_generate_in && ( non_critical_par_in ^^ pci_par_in ) ;

// PERR# is enabled for two clocks after parity error is detected - one cycle active, another inactive
reg perr_en_reg_out ;
always@(posedge reset_in or posedge clk_in)
begin
    if ( reset_in )
        perr_en_reg_out <= #1 1'b0 ;
    else
        perr_en_reg_out <= #1 perr ;
end

assign perr_en_out = perr || perr_en_reg_out ;

endmodule