//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "cbe_en_crit.v"                                   ////
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
// $Log: cbe_en_crit.v,v $
// Revision 1.1  2001/10/02 15:33:46  mihad
// Initial revision
//
//

// module is used to separate logic which uses criticaly constrained inputs from slower logic.
// It is used to synthesize critical timing logic separately with faster cells or without optimization

// this one is included in master state machine for CBE output enable driving

module CBE_EN_CRIT
(
    pci_cbe_en_out,
    cbe_en_slow_in,
    cbe_en_keep_in,
    pci_stop_in,
    pci_trdy_in
) ;

output  pci_cbe_en_out ;
input   cbe_en_slow_in,
        cbe_en_keep_in,
        pci_stop_in,
        pci_trdy_in ;

assign pci_cbe_en_out = cbe_en_slow_in || cbe_en_keep_in && pci_stop_in && pci_trdy_in ;

endmodule