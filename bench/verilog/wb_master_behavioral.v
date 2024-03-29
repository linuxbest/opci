//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "wb_master_behavioral.v"                          ////
////                                                              ////
////  This file is part of the "PCI bridge" project               ////
////  http://www.opencores.org/cores/pci/                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Miha Dolenc (mihad@opencores.org)                     ////
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
// $Log: wb_master_behavioral.v,v $
// Revision 1.3  2003/08/03 18:04:45  mihad
// Added limited WISHBONE B3 support for WISHBONE Slave Unit.
// Doesn't support full speed bursts yet.
//
// Revision 1.2  2003/06/12 02:30:39  mihad
// Update!
//
// Revision 1.1  2002/02/01 13:39:43  mihad
// Initial testbench import. Still under development
//

`include "pci_testbench_defines.v"
module WB_MASTER_BEHAVIORAL
(
    CLK_I,
    RST_I,
    TAG_I,
    TAG_O,
    ACK_I,
    ADR_O,
    CYC_O,
    DAT_I,
    DAT_O,
    ERR_I,
    RTY_I,
    SEL_O,
    STB_O,
    WE_O,
    CAB_O
);

    input                    CLK_I;
    input                    RST_I;
    input    `WB_TAG_TYPE    TAG_I;
    output   `WB_TAG_TYPE    TAG_O;
    input                    ACK_I;
    output   `WB_ADDR_TYPE   ADR_O;
    output                   CYC_O;
    input    `WB_DATA_TYPE   DAT_I;
    output   `WB_DATA_TYPE   DAT_O;
    input                    ERR_I;
    input                    RTY_I;
    output   `WB_SEL_TYPE    SEL_O;
    output                   STB_O;
    output                   WE_O;
    output                   CAB_O;

// instantiate low level master module
WB_MASTER32 wbm_low_level
(
    .CLK_I(CLK_I),
    .RST_I(RST_I),
    .TAG_I(TAG_I),
    .TAG_O(TAG_O),
    .ACK_I(ACK_I),
    .ADR_O(ADR_O),
    .CYC_O(CYC_O),
    .DAT_I(DAT_I),
    .DAT_O(DAT_O),
    .ERR_I(ERR_I),
    .RTY_I(RTY_I),
    .SEL_O(SEL_O),
    .STB_O(STB_O),
    .WE_O(WE_O),
    .CAB_O(CAB_O)
) ;

// block read and write buffers definition
// single write buffer
reg `WRITE_STIM_TYPE  blk_write_data    [0:(`MAX_BLK_SIZE - 1)] ;
// read stimulus buffer - addresses, tags, selects etc.
reg `READ_STIM_TYPE   blk_read_data_in  [0:(`MAX_BLK_SIZE - 1)] ;
// read return buffer - data and tags received while performing block reads
reg `READ_RETURN_TYPE blk_read_data_out [0:(`MAX_BLK_SIZE - 1)] ;

// single write task
task wb_single_write ;
    input `WRITE_STIM_TYPE write_data ;
    input `WB_TRANSFER_FLAGS   write_flags ;
    inout `WRITE_RETURN_TYPE return ;
    reg in_use ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg retry ;
    reg [2:0] use_cti ;
    reg [1:0] use_bte ;
begin:main

    return`TB_ERROR_BIT = 1'b0 ;
    cab = 0 ;
    return`CYC_ACTUAL_TRANSFER = 0 ;
    rty_count = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_single_write routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;

    retry = 1 ;

    use_cti = {$random} % 8 ;
    if (use_cti === 3'b010)
        use_cti = 3'b111 ;
    else if (use_cti === 3'b001)
        use_cti = 3'b000 ;

    use_bte = {$random} % 4 ;

    write_data`WRITE_TAG_STIM = {use_cti, use_bte} ;

    while (retry === 1)
    begin
        // synchronize operation to clock
        if (write_flags`WB_FAST_B2B !== 1'b1)
            @(posedge CLK_I) ;

        wbm_low_level.start_cycle(cab, 1'b1, write_flags`WB_FAST_B2B, ok) ;
        if ( ok !== 1 )
        begin
            $display("*E, Failed to initialize cycle! Routine wb_single_write, Time %t ", $time) ;
            return`TB_ERROR_BIT = 1'b1 ;
            disable main ;
        end

        // first insert initial wait states
        cyc_count = write_flags`INIT_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.wbm_write(write_data, return) ;

        if ( return`CYC_ERR === 0 && return`CYC_ACK === 0 && return`CYC_RTY === 1 && write_flags`WB_TRANSFER_AUTO_RTY === 1 && return`TB_ERROR_BIT === 0)
        begin
            if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_single_write, Time %t ", $time) ;
                 retry = 0 ;
            end
            else
            begin
                retry     = 1 ;
                rty_count = rty_count + 1 ;
            end
        end
        else
            retry = 0 ;

        // if test bench error bit is set, there is no meaning in introducing subsequent wait states
        if ( return`TB_ERROR_BIT !== 0 )
        begin
            @(posedge CLK_I) ;
            wbm_low_level.end_cycle ;
            disable main ;
        end

        cyc_count = write_flags`SUBSEQ_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.end_cycle ;
    end

    in_use = 0 ;

end //main
endtask // wb_single_write

task wb_single_read ;
    input `READ_STIM_TYPE read_data ;
    input `WB_TRANSFER_FLAGS   read_flags ;
    inout `READ_RETURN_TYPE return ;
    reg in_use ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg retry ;
    reg [2:0] use_cti ;
    reg [1:0] use_bte ;
begin:main

    return`TB_ERROR_BIT = 1'b0 ;
    cab = 0 ;
    rty_count = 0 ;
    return`CYC_ACTUAL_TRANSFER = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_single_read routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;

    retry = 1 ;

    use_cti = {$random} % 8 ;
    if (use_cti === 3'b010)
        use_cti = 3'b111 ;
    else if (use_cti === 3'b001)
        use_cti = 3'b000 ;

    use_bte = {$random} % 4 ;

    read_data`READ_TAG_STIM = {use_cti, use_bte} ;

    while (retry === 1)
    begin
        // synchronize operation to clock
        if (read_flags`WB_FAST_B2B !== 1'b1)
            @(posedge CLK_I) ;

        wbm_low_level.start_cycle(cab, 1'b0, read_flags`WB_FAST_B2B, ok) ;
        if ( ok !== 1 )
        begin
            $display("*E, Failed to initialize cycle! Routine wb_single_read, Time %t ", $time) ;
            return`TB_ERROR_BIT = 1'b1 ;
            disable main ;
        end

        // first insert initial wait states
        cyc_count = read_flags`INIT_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.wbm_read(read_data, return) ;

        if ( return`CYC_ERR === 0 && return`CYC_ACK === 0 && return`CYC_RTY === 1 && read_flags`WB_TRANSFER_AUTO_RTY === 1 && return`TB_ERROR_BIT === 0)
        begin
           if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_single_read, Time %t ", $time) ;
                 retry = 0 ;
            end
            else
            begin
                retry     = 1 ;
                rty_count = rty_count + 1 ;
            end
        end
        else
        begin
            retry = 0 ;
        end

        // if test bench error bit is set, there is no meaning in introducing subsequent wait states
        if ( return`TB_ERROR_BIT !== 0 )
        begin
            @(posedge CLK_I) ;
            wbm_low_level.end_cycle ;
            disable main ;
        end

        cyc_count = read_flags`SUBSEQ_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.end_cycle ;
    end

    in_use = 0 ;

end //main
endtask // wb_single_read

task wb_RMW_read ;
    input `READ_STIM_TYPE read_data ;
    input `WB_TRANSFER_FLAGS   read_flags ;
    inout `READ_RETURN_TYPE return ;
    reg in_use ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg retry ;
    reg [2:0] use_cti ;
    reg [1:0] use_bte ;
begin:main

    return`TB_ERROR_BIT = 1'b0 ;
    cab = 0 ;
    rty_count = 0 ;
    return`CYC_ACTUAL_TRANSFER = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_RMW_read routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;

    retry = 1 ;

    use_cti = {$random} % 8 ;
    if (use_cti === 3'b010)
        use_cti = 3'b111 ;
    else if (use_cti === 3'b001)
        use_cti = 3'b000 ;

    use_bte = {$random} % 4 ;

    read_data`READ_TAG_STIM = {use_cti, use_bte} ;

    while (retry === 1)
    begin
        // synchronize operation to clock
        if (read_flags`WB_FAST_B2B !== 1'b1)
            @(posedge CLK_I) ;

        wbm_low_level.start_cycle(cab, 1'b0, read_flags`WB_FAST_B2B, ok) ;
        if ( ok !== 1 )
        begin
            $display("*E, Failed to initialize cycle! Routine wb_RMW_read, Time %t ", $time) ;
            return`TB_ERROR_BIT = 1'b1 ;
            disable main ;
        end

        // first insert initial wait states
        cyc_count = read_flags`INIT_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.wbm_read(read_data, return) ;

        if ( return`CYC_ERR === 0 && return`CYC_ACK === 0 && return`CYC_RTY === 1 && read_flags`WB_TRANSFER_AUTO_RTY === 1 && return`TB_ERROR_BIT === 0)
        begin
           if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_RMW_read, Time %t ", $time) ;
                 retry = 0 ;
            end
            else
            begin
                retry     = 1 ;
                rty_count = rty_count + 1 ;
            end
        end
        else
        begin
            retry = 0 ;
        end

        // if test bench error bit is set, there is no meaning in introducing subsequent wait states
        if ( return`TB_ERROR_BIT !== 0 )
        begin
            @(posedge CLK_I) ;
            wbm_low_level.end_cycle ;
            disable main ;
        end

        cyc_count = read_flags`SUBSEQ_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        if (retry === 1)
            wbm_low_level.end_cycle ;
        else
            wbm_low_level.modify_cycle ;
    end

    in_use = 0 ;

end //main
endtask // wb_RMW_read

task wb_RMW_write ;
    input `WRITE_STIM_TYPE write_data ;
    input `WB_TRANSFER_FLAGS   write_flags ;
    inout `WRITE_RETURN_TYPE return ;
    reg in_use ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg retry ;
    reg [2:0] use_cti ;
    reg [1:0] use_bte ;
begin:main

    return`TB_ERROR_BIT = 1'b0 ;
    cab = 0 ;
    return`CYC_ACTUAL_TRANSFER = 0 ;
    rty_count = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_RMW_write routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;

    retry = 1 ;

    use_cti = {$random} % 8 ;
    if (use_cti === 3'b010)
        use_cti = 3'b111 ;
    else if (use_cti === 3'b001)
        use_cti = 3'b000 ;

    use_bte = {$random} % 4 ;

    write_data`WRITE_TAG_STIM = {use_cti, use_bte} ;

    while (retry === 1)
    begin
        // synchronize operation to clock
        if (write_flags`WB_FAST_B2B !== 1'b1)
            @(posedge CLK_I) ;

        ok = 1 ;
        if (rty_count !== 0)
            wbm_low_level.start_cycle(cab, 1'b1, write_flags`WB_FAST_B2B, ok) ;

        if ( ok !== 1 )
        begin
            $display("*E, Failed to initialize cycle! Routine wb_single_write, Time %t ", $time) ;
            return`TB_ERROR_BIT = 1'b1 ;
            disable main ;
        end

        // first insert initial wait states
        cyc_count = write_flags`INIT_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.wbm_write(write_data, return) ;

        if ( return`CYC_ERR === 0 && return`CYC_ACK === 0 && return`CYC_RTY === 1 && write_flags`WB_TRANSFER_AUTO_RTY === 1 && return`TB_ERROR_BIT === 0)
        begin
            if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_single_write, Time %t ", $time) ;
                 retry = 0 ;
            end
            else
            begin
                retry     = 1 ;
                rty_count = rty_count + 1 ;
            end
        end
        else
            retry = 0 ;

        // if test bench error bit is set, there is no meaning in introducing subsequent wait states
        if ( return`TB_ERROR_BIT !== 0 )
        begin
            @(posedge CLK_I) ;
            wbm_low_level.end_cycle ;
            disable main ;
        end

        cyc_count = write_flags`SUBSEQ_WAITS ;
        while ( cyc_count > 0 )
        begin
            @(posedge CLK_I) ;
            cyc_count = cyc_count - 1 ;
        end

        wbm_low_level.end_cycle ;
    end

    in_use = 0 ;

end //main
endtask // wb_RMW_write

task wb_block_write ;
    input  `WB_TRANSFER_FLAGS write_flags ;
    inout  `WRITE_RETURN_TYPE return ;

    reg in_use ;
    reg `WRITE_STIM_TYPE  current_write ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg end_blk ;
    reg [2:0] use_cti    ;
    reg [1:0] use_bte    ;
begin:main

    return`CYC_ACTUAL_TRANSFER = 0 ;
    rty_count = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_block_write routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    if (write_flags`WB_TRANSFER_SIZE > `MAX_BLK_SIZE)
    begin
        $display("*E, number of transfers passed to wb_block_write routine exceeds defined maximum transaction length! Time %t", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;
    if (write_flags`WB_FAST_B2B !== 1'b1)
        @(posedge CLK_I) ;

    cab = write_flags`WB_TRANSFER_CAB ;

    current_write = blk_write_data[0] ;

    if (cab)
    begin:select_burst_type_blk
        reg [31:0] burst_start_adr ;

        use_cti = 3'b010 ;

        burst_start_adr = current_write`WRITE_ADDRESS ;
        if (burst_start_adr[5:2] === 4'b0000)
            use_bte = {$random} % 4 ;
        else if (burst_start_adr[4:2] === 3'b000)
            use_bte = {$random} % 3 ;
        else if (burst_start_adr[3:2] === 2'b00)
            use_bte = {$random} % 2 ;
        else
            use_bte = 2'b00 ;
    end
    else
    begin
        if ( (current_write`WRITE_TAG_STIM === 0) | (current_write`WRITE_TAG_STIM === {`WB_TAG_WIDTH{1'bx}}) )
        begin
            use_cti = {$random} % 8 ;
            if (use_cti === 3'b010)
                use_cti = 3'b111 ;
            else if (use_cti === 3'b001)
                use_cti = 3'b000 ;
                
            use_bte = {$random} % 4 ;
        end
        else
        begin
            {use_cti, use_bte} = current_write`WRITE_TAG_STIM ;
        end
    end

    wbm_low_level.start_cycle(cab, 1'b1, write_flags`WB_FAST_B2B, ok) ;
    if ( ok !== 1 )
    begin
        $display("*E, Failed to initialize cycle! Routine wb_block_write, Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    // insert initial wait states
    cyc_count = write_flags`INIT_WAITS ;
    while ( cyc_count > 0 )
    begin
        @(posedge CLK_I) ;
        cyc_count = cyc_count - 1 ;
    end

    end_blk = 0 ;
    while (end_blk === 0)
    begin
        
        // collect data for current data beat
        current_write = blk_write_data[return`CYC_ACTUAL_TRANSFER] ;

        if (cab)
        begin
            if ((return`CYC_ACTUAL_TRANSFER + 1'b1) >= write_flags`WB_TRANSFER_SIZE)
                use_cti = 3'b111 ;
        end

        current_write`WRITE_TAG_STIM = {use_cti, use_bte} ;

        wbm_low_level.wbm_write(current_write, return) ;

        // check result of write operation
        // check for severe test error
        if (return`TB_ERROR_BIT !== 0)
        begin
           @(posedge CLK_I) ;
           wbm_low_level.end_cycle ;
           disable main ;
        end

        // slave returned error or error signal had invalid value
        if (return`CYC_ERR !== 0)
            end_blk = 1 ;

        if (
            (return`CYC_RTY !== 0) && (return`CYC_RTY !== 1) ||
            (return`CYC_ACK !== 0) && (return`CYC_ACK !== 1) ||
            (return`CYC_ERR !== 0) && (return`CYC_ERR !== 1)
           )
        begin
            end_blk = 1 ;
            $display("*E, at least one slave response signal was invalid when cycle finished! Routine wb_block_write, Time %t ", $time) ;
            $display("ACK = %b \t RTY_O = %b \t ERR_O = %b \t", return`CYC_ACK, return`CYC_RTY, return`CYC_ERR) ;
        end

        if ((return`CYC_RTY === 1) && (write_flags`WB_TRANSFER_AUTO_RTY !== 1))
            end_blk = 1 ;

        if ((return`CYC_RTY === 1) && (write_flags`WB_TRANSFER_AUTO_RTY === 1))
        begin
            if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_block_write, Time %t ", $time) ;
                 end_blk = 1 ;
            end
            else
            begin
                if (cab)
                begin
                    use_bte = 2'b00 ;
                end

                rty_count = rty_count + 1 ;
            end
        end
        else
            rty_count = 0 ;

        // check if slave responded at all
        if (return`CYC_RESPONSE === 0)
            end_blk = 1 ;

        // check if all intended data was transfered
        if (return`CYC_ACTUAL_TRANSFER === write_flags`WB_TRANSFER_SIZE)
            end_blk = 1 ;

        // insert subsequent wait cycles, if transfer is supposed to continue
        if ( end_blk === 0 )
        begin
            cyc_count = write_flags`SUBSEQ_WAITS ;
            while ( cyc_count > 0 )
            begin
                @(posedge CLK_I) ;
                cyc_count = cyc_count - 1 ;
            end
        end

        if ( (end_blk === 0) && (return`CYC_RTY === 1) )
        begin
            if (write_flags`WB_FAST_B2B !== 1'b1)
            begin
                wbm_low_level.end_cycle ;
                @(posedge CLK_I) ;
                wbm_low_level.start_cycle(cab, 1'b1, 1'b0, ok) ;
                if ( ok !== 1 )
                begin
                    $display("*E, Failed to initialize cycle! Routine wb_block_write, Time %t ", $time) ;
                    return`TB_ERROR_BIT = 1'b1 ;
                    end_blk = 1 ;
                end
            end
        end
    end //while

    wbm_low_level.end_cycle ;
    in_use = 0 ;
end //main
endtask //wb_block_write

task wb_block_read ;
    input  `WB_TRANSFER_FLAGS      read_flags ;
    inout `READ_RETURN_TYPE       return ;

    reg in_use ;
    reg `READ_STIM_TYPE  current_read ;
    reg cab ;
    reg ok ;
    integer cyc_count ;
    integer rty_count ;
    reg end_blk ;
    integer transfered ;
    reg [2:0] use_cti ;
    reg [1:0] use_bte ;
begin:main

    return`CYC_ACTUAL_TRANSFER = 0 ;
    transfered = 0 ;
    rty_count = 0 ;

    // check if task was called before previous call finished
    if ( in_use === 1 )
    begin
        $display("*E, wb_block_read routine re-entered! Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    if (read_flags`WB_TRANSFER_SIZE > `MAX_BLK_SIZE)
    begin
        $display("*E, number of transfers passed to wb_block_read routine exceeds defined maximum transaction length! Time %t", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    in_use = 1 ;
    @(posedge CLK_I) ;
    cab = read_flags`WB_TRANSFER_CAB ;

    if (cab)
    begin:select_burst_type_blk
        reg [31:0] burst_start_adr ;

        use_cti = 3'b010 ;

        current_read = blk_read_data_in[0] ;
        burst_start_adr = current_read`READ_ADDRESS ;
        if (burst_start_adr[5:2] === 4'b0000)
            use_bte = {$random} % 4 ;
        else if (burst_start_adr[4:2] === 3'b000)
            use_bte = {$random} % 3 ;
        else if (burst_start_adr[3:2] === 2'b00)
            use_bte = {$random} % 2 ;
        else
            use_bte = 2'b00 ;
    end

    wbm_low_level.start_cycle(cab, 1'b0, read_flags`WB_FAST_B2B, ok) ;

    if ( ok !== 1 )
    begin
        $display("*E, Failed to initialize cycle! Routine wb_block_read, Time %t ", $time) ;
        return`TB_ERROR_BIT = 1'b1 ;
        disable main ;
    end

    // insert initial wait states
    cyc_count = read_flags`INIT_WAITS ;
    while ( cyc_count > 0 )
    begin
        @(posedge CLK_I) ;
        cyc_count = cyc_count - 1 ;
    end

    end_blk = 0 ;
    while (end_blk === 0)
    begin
        // collect data for current data beat
        current_read = blk_read_data_in[return`CYC_ACTUAL_TRANSFER] ;

        if (cab)
        begin
            if ((return`CYC_ACTUAL_TRANSFER + 1'b1) >= read_flags`WB_TRANSFER_SIZE)
                use_cti = 3'b111 ;
        end

        current_read`READ_TAG_STIM = {use_cti, use_bte} ;

        wbm_low_level.wbm_read(current_read, return) ;

        if ( transfered !== return`CYC_ACTUAL_TRANSFER )
        begin
            blk_read_data_out[transfered] = return ;
            transfered = return`CYC_ACTUAL_TRANSFER ;
        end

        // check result of read operation
        // check for severe test error
        if (return`TB_ERROR_BIT !== 0)
        begin
           @(posedge CLK_I) ;
           wbm_low_level.end_cycle ;
           disable main ;
        end

        // slave returned error or error signal had invalid value
        if (return`CYC_ERR !== 0)
            end_blk = 1 ;

        if (
            (return`CYC_RTY !== 0) && (return`CYC_RTY !== 1) ||
            (return`CYC_ACK !== 0) && (return`CYC_ACK !== 1) ||
            (return`CYC_ERR !== 0) && (return`CYC_ERR !== 1)
           )
        begin
            end_blk = 1 ;
            $display("*E, at least one slave response signal was invalid when cycle finished! Routine wb_block_read, Time %t ", $time) ;
            $display("ACK = %b \t RTY_O = %b \t ERR_O = %b \t", return`CYC_ACK, return`CYC_RTY, return`CYC_ERR) ;
        end

        if ((return`CYC_RTY === 1) && (read_flags`WB_TRANSFER_AUTO_RTY !== 1))
            end_blk = 1 ;

        if ((return`CYC_RTY === 1) && (read_flags`WB_TRANSFER_AUTO_RTY === 1))
        begin
            if ( rty_count === `WB_TB_MAX_RTY )
            begin
                 $display("*E, maximum number of retries received - access will not be repeated anymore! Routine wb_block_read, Time %t ", $time) ;
                 end_blk = 1 ;
            end
            else
            begin
                if (cab)
                begin
                    use_bte = 2'b00 ;
                end

                rty_count = rty_count + 1 ;
            end
        end
        else
            rty_count = 0 ;

        // check if slave responded at all
        if (return`CYC_RESPONSE === 0)
            end_blk = 1 ;

        // check if all intended data was transfered
        if (return`CYC_ACTUAL_TRANSFER === read_flags`WB_TRANSFER_SIZE)
            end_blk = 1 ;

        // insert subsequent wait cycles, if transfer is supposed to continue
        if ( end_blk === 0 )
        begin
            cyc_count = read_flags`SUBSEQ_WAITS ;
            while ( cyc_count > 0 )
            begin
                @(posedge CLK_I) ;
                cyc_count = cyc_count - 1 ;
            end
        end

        if ( (end_blk === 0) && (return`CYC_RTY === 1) )
        begin
            if (read_flags`WB_FAST_B2B !== 1'b1)
            begin
                wbm_low_level.end_cycle ;
                @(posedge CLK_I) ;
                wbm_low_level.start_cycle(cab, 1'b0, 1'b0, ok) ;
                if ( ok !== 1 )
                begin
                    $display("*E, Failed to initialize cycle! Routine wb_block_read, Time %t ", $time) ;
                    return`TB_ERROR_BIT = 1'b1 ;
                    end_blk = 1 ;
                end
            end
        end
    end //while

    wbm_low_level.end_cycle ;
    in_use = 0 ;
end //main
endtask //wb_block_read

task shift_write_buffer ;
    input [31:0] shift_num ;
    integer i ;
begin
    if (shift_num < `MAX_BLK_SIZE)
    begin
    
        for (i = 0 ; i + shift_num < `MAX_BLK_SIZE ; i = i + 1)
        begin
            blk_write_data[i] = blk_write_data[i + shift_num] ;
        end

        for (i = (`MAX_BLK_SIZE - shift_num) ; i < `MAX_BLK_SIZE ; i = i + 1)
            blk_write_data[i] = {1024{1'bx}} ;
    end
end
endtask // shift_write_buffer

endmodule

