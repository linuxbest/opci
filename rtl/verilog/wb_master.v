//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name: wb_master.v                                      ////
////                                                              ////
////  This file is part of the "PCI bridge" project               ////
////  http://www.opencores.org/cores/pci/                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Tadej Markovic, tadej@opencores.org                   ////
////                                                              ////
////  All additional information is avaliable in the README.txt   ////
////  file.                                                       ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Tadej Markovic, tadej@opencores.org       ////
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
// $Log: wb_master.v,v $
// Revision 1.7  2002/12/05 12:19:23  mihad
// *** empty log message ***
//
// Revision 1.6  2002/10/11 14:15:29  mihad
// Cleaned up non-blocking assignments in combinatinal logic statements
//
// Revision 1.5  2002/03/05 11:53:47  mihad
// Added some testcases, removed un-needed fifo signals
//
// Revision 1.4  2002/02/19 16:32:37  mihad
// Modified testbench and fixed some bugs
//
// Revision 1.3  2002/02/01 15:25:13  mihad
// Repaired a few bugs, updated specification, added test bench files and design document
//
// Revision 1.2  2001/10/05 08:14:30  mihad
// Updated all files with inclusion of timescale file for simulation purposes.
//
// Revision 1.1.1.1  2001/10/02 15:33:47  mihad
// New project directory structure
//
//

`define WB_FSM_BITS 3 // number of bits needed for FSM states


`include "bus_commands.v"
`include "pci_constants.v"
//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module WB_MASTER (  wb_clock_in,        // CLK_I
                    reset_in,           // RST_I
                    
                    pci_tar_read_request,
                    pci_tar_address,
                    pci_tar_cmd,
                    pci_tar_be,
                    pci_tar_burst_ok,
                    pci_cache_line_size,
                    cache_lsize_not_zero,
                    wb_read_done_out,
                    w_attempt,

                    pcir_fifo_wenable_out, 
                    pcir_fifo_data_out,    
                    pcir_fifo_be_out, 
                    pcir_fifo_control_out,  
                    //pcir_fifo_renable_out,            for PCI Target !!!
                    //pcir_fifo_data_in,                for PCI Target !!!
                    //pcir_fifo_be_in,                  for PCI Target !!!
                    //pcir_fifo_control_in,             for PCI Target !!!
                    //pcir_fifo_flush_out,              for PCI Target !!!
                    //pcir_fifo_almost_empty_in,        for PCI Target !!!
                    //pcir_fifo_empty_in,               NOT used
                    //pcir_fifo_transaction_ready_in,   NOT used
                    //pciw_fifo_wenable_out,            for PCI Target !!!
                    //pciw_fifo_addr_data_out,          for PCI Target !!!   
                    //pciw_fifo_cbe_out,                for PCI Target !!!
                    //pciw_fifo_control_out,            for PCI Target !!!       
                    pciw_fifo_renable_out, 
                    pciw_fifo_addr_data_in,                              
                    pciw_fifo_cbe_in, 
                    pciw_fifo_control_in,                                   
                    //pciw_fifo_flush_out,              NOT used
                    //pciw_fifo_almost_full_in,         for PCI Target !!!
                    //pciw_fifo_full_in,                for PCI Target !!!
                    pciw_fifo_almost_empty_in, 
                    pciw_fifo_empty_in, 
                    pciw_fifo_transaction_ready_in,

                    pci_error_sig_out,
                    pci_error_bc,
                    write_rty_cnt_exp_out,
                    error_source_out,
                    read_rty_cnt_exp_out,

                    CYC_O,
                    STB_O,
                    WE_O,
                    SEL_O,
                    ADR_O,
                    MDATA_I,
                    MDATA_O,
                    ACK_I,
                    RTY_I,
                    ERR_I,
                    CAB_O
                );

/*----------------------------------------------------------------------------------------------------------------------
Various parameters needed for state machine and other stuff
----------------------------------------------------------------------------------------------------------------------*/
parameter       S_IDLE          = `WB_FSM_BITS'h0 ; 
parameter       S_WRITE         = `WB_FSM_BITS'h1 ;
parameter       S_WRITE_ERR_RTY = `WB_FSM_BITS'h2 ;
parameter       S_READ          = `WB_FSM_BITS'h3 ;
parameter       S_READ_RTY      = `WB_FSM_BITS'h4 ;
parameter       S_TURN_ARROUND  = `WB_FSM_BITS'h5 ;

/*----------------------------------------------------------------------------------------------------------------------
System signals inputs
wb_clock_in - WISHBONE bus clock input
reset_in    - system reset input controlled by bridge's reset logic
----------------------------------------------------------------------------------------------------------------------*/
input           wb_clock_in ; 
input           reset_in ;

/*----------------------------------------------------------------------------------------------------------------------
Control signals from PCI Target for READS to PCIR_FIFO
---------------------------------------------------------------------------------------------------------------------*/
input           pci_tar_read_request ;      // read request from PCI Target
input   [31:0]  pci_tar_address ;           // address for requested read from PCI Target                   
input   [3:0]   pci_tar_cmd ;               // command for requested read from PCI Target                   
input   [3:0]   pci_tar_be ;                // byte enables for requested read from PCI Target              
input           pci_tar_burst_ok ;
input   [7:0]   pci_cache_line_size ;       // CACHE line size register value for burst length   
input           cache_lsize_not_zero ;           
output          wb_read_done_out ;              // read done and PCIR_FIFO has data ready
output          w_attempt ;

reg             wb_read_done_out ;
reg             wb_read_done ;

/*----------------------------------------------------------------------------------------------------------------------
PCIR_FIFO control signals used for sinking data into PCIR_FIFO and status monitoring         
---------------------------------------------------------------------------------------------------------------------*/
output          pcir_fifo_wenable_out ;     // PCIR_FIFO write enable output
output  [31:0]  pcir_fifo_data_out ;        // data output to PCIR_FIFO
output  [3:0]   pcir_fifo_be_out ;          // byte enable output to PCIR_FIFO
output  [3:0]   pcir_fifo_control_out ;     // control bus output to PCIR_FIFO

reg     [31:0]  pcir_fifo_data_out ;
reg             pcir_fifo_wenable_out ;
reg             pcir_fifo_wenable ;
reg     [3:0]   pcir_fifo_control_out ;
reg     [3:0]   pcir_fifo_control ;

/*----------------------------------------------------------------------------------------------------------------------
PCIW_FIFO control signals used for fetching data from PCIW_FIFO and status monitoring
---------------------------------------------------------------------------------------------------------------------*/
output          pciw_fifo_renable_out ;     // read enable for PCIW_FIFO output
input   [31:0]  pciw_fifo_addr_data_in ;    // address and data input from PCIW_FIFO
input   [3:0]   pciw_fifo_cbe_in ;          // command and byte_enables from PCIW_FIFO
input   [3:0]   pciw_fifo_control_in ;      // control bus input from PCIW_FIFO
input           pciw_fifo_almost_empty_in ; // almost empty status indicator from PCIW_FIFO
input           pciw_fifo_empty_in ;        // empty status indicator from PCIW_FIFO
input           pciw_fifo_transaction_ready_in ;    // write transaction is ready in PCIW_FIFO

reg             pciw_fifo_renable_out ;
reg             pciw_fifo_renable ;

/*----------------------------------------------------------------------------------------------------------------------
Control INPUT / OUTPUT signals for configuration space reporting registers !!!
---------------------------------------------------------------------------------------------------------------------*/
output          pci_error_sig_out ;         // When error occures (on WB bus, retry counter, etc.)
output  [3:0]   pci_error_bc ;              // bus command at which error occured !
output          write_rty_cnt_exp_out ;     // Signaling that RETRY counter has expired during write transaction!
output          read_rty_cnt_exp_out ;      // Signaling that RETRY counter has expired during read transaction!
                                            //  if error_source is '0' other side didn't respond
                                            //  if error_source is '1' other side RETRIED for max retry counter value
output          error_source_out ;          // Signaling error source - '0' other WB side signaled error OR didn't respond
                                            //   if '1' wridge counted max value in retry counter because of RTY responds
reg             pci_error_sig_out ;
reg             write_rty_cnt_exp_out ;
reg             read_rty_cnt_exp_out ;
reg             error_source_out ;

/*----------------------------------------------------------------------------------------------------------------------
WISHBONE bus interface signals - can be connected directly to WISHBONE bus
---------------------------------------------------------------------------------------------------------------------*/
output          CYC_O ;         // cycle indicator output
output          STB_O ;         // strobe output - data is valid when strobe and cycle indicator are high
output          WE_O  ;         // write enable output - 1 - write operation, 0 - read operation
output  [3:0]   SEL_O ;         // Byte select outputs
output  [31:0]  ADR_O ;         // WISHBONE address output
input   [31:0]  MDATA_I ;       // WISHBONE slave interface input data bus
output  [31:0]  MDATA_O ;       // WISHBONE slave interface output data bus
input           ACK_I ;         // Acknowledge input - qualifies valid data on data output bus or received data on data input bus
input           RTY_I ;         // retry input - signals from WISHBONE slave that cycle should be terminated and retried later
input           ERR_I ;         // Signals from WISHBONE slave that access resulted in an error
output          CAB_O ;         // consecutive address burst output - indicated that master will do a serial address transfer in current cycle

reg             CYC_O ;
reg             STB_O ;
reg             WE_O  ;
reg     [3:0]   SEL_O ;
reg     [31:0]  MDATA_O ;
reg             CAB_O ;


/*###########################################################################################################
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    LOGIC, COUNTERS, STATE MACHINE and some control register bits
    =============================================================
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
###########################################################################################################*/

reg             last_data_transferred ; // signal is set by STATE MACHINE after each complete transfere !

// wire for write attempt - 1 when PCI Target attempt to write and PCIW_FIFO has a write transaction ready
`ifdef REGISTER_WBM_OUTPUTS
    reg     w_attempt;
    always@(posedge wb_clock_in or posedge reset_in)
    begin
        if (reset_in)
            w_attempt <= #`FF_DELAY 1'b0;
        else
        begin
            if (pciw_fifo_transaction_ready_in && ~pciw_fifo_empty_in)
                w_attempt <= #`FF_DELAY 1'b1;
            else
                if (last_data_transferred)
                    w_attempt <= #`FF_DELAY 1'b0;
        end
    end
`else
    assign w_attempt = ( pciw_fifo_transaction_ready_in && ~pciw_fifo_empty_in ) ; 
`endif

// wire for read attempt - 1 when PCI Target is attempting a read and PCIR_FIFO is not full !
// because of transaction ordering, PCI Master must not start read untill all writes are done -> at that
//   moment PCIW_FIFO is empty !!! (when read is pending PCI Target will block new reads and writes)
wire r_attempt = ( pci_tar_read_request && !w_attempt);// pciw_fifo_empty_in ) ; 

// Signal is used for reads on WB, when there is retry!
reg             first_wb_data_access ;

reg             last_data_from_pciw_fifo ;  // signal tells when there is last data in pciw_fifo
reg             last_data_from_pciw_fifo_reg ;
reg             last_data_to_pcir_fifo ;    // signal tells when there will be last data for pcir_fifo

// Logic used in State Machine logic implemented out of State Machine because of less delay!
always@(pciw_fifo_control_in or pciw_fifo_almost_empty_in)
begin
    if (pciw_fifo_control_in[`LAST_CTRL_BIT] || pciw_fifo_almost_empty_in) // if last data is going to be transfered
        last_data_from_pciw_fifo = 1'b1 ; // signal for last data from PCIW_FIFO
    else
        last_data_from_pciw_fifo = 1'b0 ;
end

    reg read_count_load;
    reg read_count_enable;
    
    reg [(`PCIR_ADDR_LENGTH - 1):0] max_read_count ;
    always@(pci_cache_line_size or cache_lsize_not_zero or pci_tar_cmd)
    begin 
        if (cache_lsize_not_zero) 
            if ( (pci_cache_line_size >= `PCIR_DEPTH) || (~pci_tar_cmd[1] && ~pci_tar_cmd[0]) )
                // If cache line size is larger than FIFO or BC_MEM_READ_MUL command is performed!
                max_read_count = `PCIR_DEPTH - 1'b1;
            else
                max_read_count = pci_cache_line_size ;
        else
            max_read_count = 1'b1;
    end

    reg [(`PCIR_ADDR_LENGTH - 1):0] read_count ;

    // cache line bound indicator - it signals when data for one complete cacheline was read
    wire read_bound_comb = ~|( { read_count[(`PCIR_ADDR_LENGTH - 1):2], read_count[0] } ) ;

    reg  read_bound ;
    always@(posedge wb_clock_in or posedge reset_in)
    begin
        if ( reset_in )
            read_bound <= #`FF_DELAY 1'b0 ;
        else if (read_count_load)
            read_bound <= #`FF_DELAY 1'b0 ;
        else if ( read_count_enable )
            read_bound <= #`FF_DELAY read_bound_comb ;
    end

    // down counter with load
    always@(posedge reset_in or posedge wb_clock_in)
    begin
        if (reset_in)
            read_count <= #`FF_DELAY 0 ;
        else
        if (read_count_load)
            read_count <= #`FF_DELAY max_read_count ;
        else
        if (read_count_enable)
            read_count <= #`FF_DELAY read_count - 1'b1 ;
    end

// Logic used in State Machine logic implemented out of State Machine because of less delay!
//   definition of signal telling, when there is last data written into FIFO
always@(pci_tar_cmd or pci_tar_burst_ok or read_bound)
begin
    // burst is OK for reads when there is ((MEM_READ_LN or MEM_READ_MUL) and AD[1:0]==2'b00) OR
    //   (MEM_READ and Prefetchable_IMAGE and AD[1:0]==2'b00) -> pci_tar_burst_ok
    case ({pci_tar_cmd, pci_tar_burst_ok})
    {`BC_MEM_READ, 1'b1},
    {`BC_MEM_READ_LN, 1'b1} :
    begin   // when burst cycle
        if (read_bound)
            last_data_to_pcir_fifo = 1'b1 ;
        else
            last_data_to_pcir_fifo = 1'b0 ;
    end
    {`BC_MEM_READ_MUL, 1'b1} :
    begin   // when burst cycle
        if (read_bound)
            last_data_to_pcir_fifo = 1'b1 ;
        else
            last_data_to_pcir_fifo = 1'b0 ;
    end
    default :
    // {`BC_IO_READ, 1'b0},
    // {`BC_IO_READ, 1'b1},
    // {`BC_MEM_READ, 1'b0},
    // {`BC_MEM_READ_LN, 1'b0},
    // {`BC_MEM_READ_MUL, 1'b0}:
    begin   // when single cycle
        last_data_to_pcir_fifo = 1'b1 ;
    end
    endcase
end

reg     [3:0]   wb_no_response_cnt ;
reg     [3:0]   wb_response_value ;
reg             wait_for_wb_response ;
reg             set_retry ; // 

// internal WB no response retry generator counter!
always@(posedge reset_in or posedge wb_clock_in)
begin
    if (reset_in)
        wb_no_response_cnt <= #`FF_DELAY 4'h0 ; 
    else
        wb_no_response_cnt <= #`FF_DELAY wb_response_value ;
end
// internal WB no response retry generator logic
always@(wait_for_wb_response or wb_no_response_cnt)
begin
    if (wb_no_response_cnt == 4'h8) // when there isn't response for 8 clocks, set internal retry
    begin
        wb_response_value = 4'h0 ;
        set_retry = 1'b1 ;
    end
    else
    begin
        if (wait_for_wb_response)
            wb_response_value = wb_no_response_cnt + 1'h1 ; // count clocks when no response
        else
            wb_response_value = 4'h0 ;
        set_retry = 1'b0 ;
    end
end

wire    retry = RTY_I || set_retry ; // retry signal - logic OR function between RTY_I and internal WB no response retry!
reg     [7:0]   rty_counter ; // output from retry counter
reg     [7:0]   rty_counter_in ; // input value - output value + 1 OR output value
reg             rty_counter_almost_max_value ; // signal tells when retry counter riches maximum value - 1!
reg             reset_rty_cnt ; // signal for asynchronous reset of retry counter after each complete transfere

// sinchronous signal after each transfere and asynchronous signal 'reset_rty_cnt' after reset  
//   for reseting the retry counter
always@(posedge reset_in or posedge wb_clock_in)
begin
    if (reset_in)
        reset_rty_cnt <= #`FF_DELAY 1'b1 ; // asynchronous set when reset signal is active
    else
        reset_rty_cnt <= #`FF_DELAY ACK_I || ERR_I || last_data_transferred ; // synchronous set after completed transfere
end

// Retry counter register control
always@(posedge reset_in or posedge wb_clock_in)
begin
    if (reset_in)
        rty_counter <= #`FF_DELAY 8'h00 ;
    else
    begin
        if (reset_rty_cnt)
            rty_counter <= #`FF_DELAY 8'h00 ;
        else if (retry)
            rty_counter <= #`FF_DELAY rty_counter_in ;
    end
end
// Retry counter logic
always@(rty_counter)
begin
    if(rty_counter == `WB_RTY_CNT_MAX - 1'b1) // stop counting
    begin
        rty_counter_in = rty_counter ;
        rty_counter_almost_max_value = 1'b1 ;
    end
    else
    begin
        rty_counter_in = rty_counter + 1'b1 ; // count up
        rty_counter_almost_max_value = 1'b0 ;
    end
end     

reg     [31:0]  addr_cnt_out ;  // output value from address counter to WB ADDRESS output
reg     [31:0]  addr_cnt_in ;   // input address value to address counter
reg             addr_into_cnt ; // control signal for loading starting address into counter
reg             addr_count ; // control signal for count enable
reg     [3:0]   bc_register ; // used when error occures during writes!

// wb address counter register control
always@(posedge wb_clock_in or posedge reset_in)
begin
    if (reset_in) // reset counter
    begin
        addr_cnt_out <= #`FF_DELAY 32'h0000_0000 ;
        bc_register  <= #`FF_DELAY 4'h0 ;
    end
    else
    begin
        addr_cnt_out <= #`FF_DELAY addr_cnt_in ; // count up or hold value depending on cache line counter logic
        if (addr_into_cnt)
            bc_register  <= #`FF_DELAY pciw_fifo_cbe_in ;
    end
end

// when '1', the bus command is IO command - not supported commands are checked in pci_decoder modules
wire    io_memory_bus_command = !pci_tar_cmd[3] && !pci_tar_cmd[2] ;

// wb address counter logic
always@(addr_into_cnt or r_attempt or addr_count or pciw_fifo_addr_data_in or pci_tar_address or addr_cnt_out or
        io_memory_bus_command)
begin
    if (addr_into_cnt) // load starting address into counter
    begin
        if (r_attempt)
        begin // if read request, then load read addresss from PCI Target
            addr_cnt_in = {pci_tar_address[31:2], pci_tar_address[1] && io_memory_bus_command, 
                                                  pci_tar_address[0] && io_memory_bus_command} ; 
        end
        else
        begin // if not read request, then load write address from PCIW_FIFO
            addr_cnt_in = pciw_fifo_addr_data_in[31:0] ; 
        end
    end
    else
    if (addr_count)
    begin
        addr_cnt_in = addr_cnt_out + 3'h4 ; // count up for 32-bit alligned address 
    end
    else
    begin
        addr_cnt_in = addr_cnt_out ;
    end
end

reg wb_stb_o ; // Internal signal for driwing STB_O on WB bus
reg wb_we_o ; // Internal signal for driwing WE_O on WB bus
reg wb_cyc_o ; // Internal signal for driwing CYC_O on WB bus and for enableing burst signal generation

reg retried ; // Signal is output value from FF and is set for one clock period after retried_d is set
reg retried_d ; // Signal is set whenever cycle is retried and is input to FF for delaying -> used in S_IDLE state
reg retried_write;
reg rty_i_delayed; // Dignal used for determinig the source of retry!

reg     first_data_is_burst ; // Signal is set in S_WRITE or S_READ states, when data transfere is burst!
reg     first_data_is_burst_reg ;
wire    burst_transfer ; // This signal is set when data transfere is burst and is reset with RESET or last data transfered

// FFs output signals tell, when there is first data out from FIFO (for BURST checking)
//   and for delaying retried signal
always@(posedge wb_clock_in or posedge reset_in)
begin
    if (reset_in) // reset signals
    begin
        retried <= #`FF_DELAY 1'b0 ;
        retried_write <= #`FF_DELAY 1'b0 ;
        rty_i_delayed <= #`FF_DELAY 1'B0 ;
    end
    else
    begin
        retried <= #`FF_DELAY retried_d ; // delaying retried signal  
        retried_write <= #`FF_DELAY retried ;
        rty_i_delayed <= #`FF_DELAY RTY_I ;
    end
end

// Determinig if first data is a part of BURST or just a single transfere!
always@(addr_into_cnt or r_attempt or pci_tar_burst_ok or max_read_count or 
        pciw_fifo_control_in or pciw_fifo_empty_in)
begin
    if (addr_into_cnt)
    begin
        if (r_attempt)
        begin
                // burst is OK for reads when there is ((MEM_READ_LN or MEM_READ_MUL) and AD[1:0]==2'b00) OR
                //   (MEM_READ and Prefetchable_IMAGE and AD[1:0]==2'b00) -> pci_tar_burst_ok
            if  (pci_tar_burst_ok && (max_read_count != 8'h1))
                first_data_is_burst = 1'b1 ; 
            else
                first_data_is_burst = 1'b0 ;
        end
        else
        begin
            first_data_is_burst = 1'b0 ;
        end
    end
    else
        first_data_is_burst = pciw_fifo_control_in[`BURST_BIT] && ~pciw_fifo_empty_in && ~pciw_fifo_control_in[`LAST_CTRL_BIT];
end

// FF for seting and reseting burst_transfer signal
always@(posedge wb_clock_in or posedge reset_in)
begin
    if (reset_in) 
        first_data_is_burst_reg <= #`FF_DELAY 1'b0 ;
    else
    begin
        if (last_data_transferred || first_data_is_burst)
            first_data_is_burst_reg <= #`FF_DELAY ~last_data_transferred ;
    end
end
`ifdef REGISTER_WBM_OUTPUTS
    assign  burst_transfer = first_data_is_burst || first_data_is_burst_reg ;
`else
    assign  burst_transfer = (first_data_is_burst && ~last_data_transferred) || first_data_is_burst_reg ;
`endif

reg [(`WB_FSM_BITS - 1):0]  c_state ; //current state register
reg [(`WB_FSM_BITS - 1):0]  n_state ; //next state input to current state register

// state machine register control
always@(posedge wb_clock_in or posedge reset_in)
begin
    if (reset_in) // reset state machine ti S_IDLE state
        c_state <= #`FF_DELAY S_IDLE ;
    else
        c_state <= #`FF_DELAY n_state ;
end

// state machine logic
always@(c_state or
        ACK_I or 
        RTY_I or 
        ERR_I or 
        w_attempt or
        r_attempt or
        retried or 
        rty_i_delayed or
        pci_tar_read_request or
        rty_counter_almost_max_value or 
        set_retry or 
        last_data_to_pcir_fifo or 
        first_wb_data_access or
        last_data_from_pciw_fifo_reg
        )
begin
    case (c_state)
    S_IDLE:
        begin
            // Default values for signals not used in this state
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_count = 1'b0 ;
            read_count_enable = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            retried_d = 1'b0 ;
            last_data_transferred = 1'b0 ;
            wb_read_done = 1'b0 ;
            wait_for_wb_response = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            error_source_out = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            case ({w_attempt, r_attempt, retried})
            3'b101 : // Write request for PCIW_FIFO to WB bus transaction
            begin    // If there was retry, the same transaction must be initiated
                pciw_fifo_renable = 1'b0 ; // the same data
                addr_into_cnt = 1'b0 ; // the same address
                read_count_load = 1'b0 ; // no need for cache line when there is write
                n_state = S_WRITE ;
            end
            3'b100 : // Write request for PCIW_FIFO to WB bus transaction
            begin    // If there is new transaction
                pciw_fifo_renable = 1'b1 ; // first location is address (in FIFO), next will be data
                addr_into_cnt = 1'b1 ; // address must be latched into address counter
                read_count_load = 1'b0 ; // no need for cache line when there is write
                n_state = S_WRITE ;
            end
            3'b011 : // Read request from PCI Target for WB bus to PCIR_FIFO transaction
            begin    // If there was retry, the same transaction must be initiated
                addr_into_cnt = 1'b0 ; // the same address
                read_count_load = 1'b0 ; // cache line counter must not be changed for retried read
                pciw_fifo_renable = 1'b0 ; // don't read from FIFO, when read transaction from WB to FIFO
                n_state = S_READ ;
            end
            3'b010 : // Read request from PCI Target for WB bus to PCIR_FIFO transaction
            begin    // If there is new transaction
                addr_into_cnt = 1'b1 ; // address must be latched into counter from separate request bus
                read_count_load = 1'b1 ; // cache line size must be latched into its counter
                pciw_fifo_renable = 1'b0 ; // don't read from FIFO, when read transaction from WB to FIFO
                n_state = S_READ ;
            end
            default : // stay in IDLE state
            begin
                pciw_fifo_renable = 1'b0 ;
                addr_into_cnt = 1'b0 ;
                read_count_load = 1'b0 ;
                n_state = S_IDLE ;
            end
            endcase
            wb_stb_o = 1'b0 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b0 ;
        end
    S_WRITE: // WRITE from PCIW_FIFO to WB bus
        begin
            // Default values for signals not used in this state
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            read_count_enable = 1'b0 ;
            wb_read_done = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            case ({ACK_I, ERR_I, RTY_I})
            3'b100 : // If writting of one data is acknowledged
            begin
                pciw_fifo_renable = 1'b1 ; // prepare next value (address when new trans., data when burst tran.)
                addr_count = 1'b1 ; // prepare next address if there will be burst
                pci_error_sig_out = 1'b0 ; // there was no error
                error_source_out = 1'b0 ;
                retried_d = 1'b0 ; // there was no retry
                write_rty_cnt_exp_out = 1'b0 ; // there was no retry
                wait_for_wb_response = 1'b0 ;
                if (last_data_from_pciw_fifo_reg) // if last data was transfered
                begin                   
                    n_state = S_IDLE ;
                    last_data_transferred = 1'b1 ; // signal for last data transfered
                end
                else
                begin
                    n_state = S_WRITE ;
                    last_data_transferred = 1'b0 ;
                end
            end
            3'b010 : // If writting of one data is terminated with ERROR
            begin
                pciw_fifo_renable = 1'b1 ; // prepare next value (address when new trans., data when cleaning FIFO)
                addr_count = 1'b0 ; // no need for new address
                retried_d = 1'b0 ; // there was no retry
                last_data_transferred = 1'b1 ; // signal for last data transfered
                pci_error_sig_out = 1'b1 ; // segnal for error reporting
                error_source_out = 1'b0 ; // error source from other side of WB bus
                write_rty_cnt_exp_out = 1'b0 ; // there was no retry
                wait_for_wb_response = 1'b0 ;
                if (last_data_from_pciw_fifo_reg) // if last data was transfered
                    n_state = S_IDLE ; // go to S_IDLE for new transfere
                else // if there wasn't last data of transfere
                    n_state = S_WRITE_ERR_RTY ; // go here to clean this write transaction from PCIW_FIFO
            end
            3'b001 : // If writting of one data is retried
            begin
                addr_count = 1'b0 ;
                last_data_transferred = 1'b0 ;
                retried_d = 1'b1 ; // there was a retry
                wait_for_wb_response = 1'b0 ;
                if(rty_counter_almost_max_value) // If retry counter reached maximum allowed value
                begin
	                if (last_data_from_pciw_fifo_reg) // if last data was transfered
                        pciw_fifo_renable = 1'b0 ;
	                else // if there wasn't last data of transfere
	                    pciw_fifo_renable = 1'b1 ;
	                n_state = S_WRITE_ERR_RTY ; // go here to clean this write transaction from PCIW_FIFO
                    write_rty_cnt_exp_out = 1'b1 ; // signal for reporting write counter expired
                    pci_error_sig_out = 1'b1 ;
                    error_source_out = 1'b1 ; // error ocuerd because of retry counter
                end
                else
                begin
                	pciw_fifo_renable = 1'b0 ;
                    n_state = S_IDLE ; // go to S_IDLE state for retrying the transaction
                    write_rty_cnt_exp_out = 1'b0 ; // retry counter hasn't expired yet
                    pci_error_sig_out = 1'b0 ;
                    error_source_out = 1'b0 ;
                end
            end
            default :
            begin
                addr_count = 1'b0 ;
                last_data_transferred = 1'b0 ;
                wait_for_wb_response = 1'b1 ; // wait for WB device to response (after 8 clocks RTY CNT is incremented)
                error_source_out = 1'b0 ; // if error ocures, error source is from other WB bus side
                if((rty_counter_almost_max_value)&&(set_retry)) // when no WB response and RTY CNT reached maximum allowed value 
                begin
                    retried_d = 1'b1 ;
	                if (last_data_from_pciw_fifo_reg) // if last data was transfered
                        pciw_fifo_renable = 1'b0 ;
	                else // if there wasn't last data of transfere
	                    pciw_fifo_renable = 1'b1 ;
	                n_state = S_WRITE_ERR_RTY ; // go here to clean this write transaction from PCIW_FIFO
                    write_rty_cnt_exp_out = 1'b1 ; // signal for reporting write counter expired
                    pci_error_sig_out = 1'b1 ; // signal for error reporting
                end
                else
                begin
                	pciw_fifo_renable = 1'b0 ;
                    retried_d = 1'b0 ;
                    n_state = S_WRITE ; // stay in S_WRITE state to wait WB to response
                    write_rty_cnt_exp_out = 1'b0 ; // retry counter hasn't expired yet
                    pci_error_sig_out = 1'b0 ;
                end
            end
            endcase
            wb_stb_o = 1'b1 ;
            wb_we_o = 1'b1 ;
            wb_cyc_o = 1'b1 ;
        end
    S_WRITE_ERR_RTY: // Clean current write transaction from PCIW_FIFO if ERROR or Retry counter expired occures
        begin
`ifdef REGISTER_WBM_OUTPUTS
            pciw_fifo_renable = !last_data_from_pciw_fifo_reg ; // put out next data (untill last data or FIFO empty)
`else
            pciw_fifo_renable = 1'b1 ; // put out next data (untill last data or FIFO empty)
`endif
            last_data_transferred = 1'b1 ; // after exiting this state, negedge of this signal is used
            // Default values for signals not used in this state
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            read_count_enable = 1'b0 ;
            addr_count = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            retried_d = 1'b0 ;
            wb_read_done = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            wait_for_wb_response = 1'b0 ;
            // If last data is cleaned out from PCIW_FIFO
            if (last_data_from_pciw_fifo_reg)
                n_state = S_IDLE ;
            else
                n_state = S_WRITE_ERR_RTY ; // Clean until last data is cleaned out from FIFO
            wb_stb_o = 1'b0 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b0 ;
        end
    S_READ: // READ from WB bus to PCIR_FIFO
        begin
            // Default values for signals not used in this state
            pciw_fifo_renable = 1'b0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            case ({ACK_I, ERR_I, RTY_I})
            3'b100 : // If reading of one data is acknowledged
            begin
                pcir_fifo_wenable = 1'b1 ; // enable writting data into PCIR_FIFO
                addr_count = 1'b1 ; // prepare next address if there will be burst
                read_count_enable = 1'b1 ; // decrease counter value for cache line size
                retried_d = 1'b0 ; // there was no retry
                read_rty_cnt_exp_out = 1'b0 ; // there was no retry
                wait_for_wb_response = 1'b0 ;
                // if last data was transfered
                if (last_data_to_pcir_fifo)
                begin
                    pcir_fifo_control[`LAST_CTRL_BIT]       = 1'b1 ; // FIFO must indicate LAST data transfered
                    pcir_fifo_control[`DATA_ERROR_CTRL_BIT] = 1'b0 ;
                    pcir_fifo_control[`UNUSED_CTRL_BIT]     = 1'b0 ;
                    pcir_fifo_control[`ADDR_CTRL_BIT]       = 1'b0 ;
                    last_data_transferred = 1'b1 ; // signal for last data transfered
                    wb_read_done = 1'b1 ; // signal last data of read transaction for PCI Target
                    n_state = S_TURN_ARROUND ;
                end
                else // if not last data transfered
                begin
                    pcir_fifo_control = 4'h0 ; // ZERO for control code
                    last_data_transferred = 1'b0 ; // not last data transfered
                    wb_read_done = 1'b0 ; // read is not done yet
                    n_state = S_READ ;
                end
            end
            3'b010 : // If reading of one data is terminated with ERROR
            begin
                pcir_fifo_wenable = 1'b1 ; // enable for writting to FIFO data with ERROR
                addr_count = 1'b0 ; // no need for new address
                pcir_fifo_control[`LAST_CTRL_BIT]       = 1'b0 ;
                pcir_fifo_control[`DATA_ERROR_CTRL_BIT] = 1'b1 ; // FIFO must indicate the DATA with ERROR
                pcir_fifo_control[`UNUSED_CTRL_BIT]     = 1'b0 ;
                pcir_fifo_control[`ADDR_CTRL_BIT]       = 1'b0 ;
                last_data_transferred = 1'b1 ; // signal for last data transfered
                wb_read_done = 1'b1 ; // signal last data of read transaction for PCI Target
                read_count_enable = 1'b0 ; // no need for cache line, when error occures
                n_state = S_TURN_ARROUND ;
                retried_d = 1'b0 ; // there was no retry
                wait_for_wb_response = 1'b0 ;
                read_rty_cnt_exp_out = 1'b0 ; // there was no retry
            end
            3'b001 : // If reading of one data is retried
            begin
                pcir_fifo_wenable = 1'b0 ;
                pcir_fifo_control = 4'h0 ;
                addr_count = 1'b0 ;
                read_count_enable = 1'b0 ;
                wait_for_wb_response = 1'b0 ;
                case ({first_wb_data_access, rty_counter_almost_max_value})
                2'b10 :
                begin  // if first data of the cycle (CYC_O) is retried - after each retry CYC_O goes inactive 
                    n_state = S_IDLE ; // go to S_IDLE state for retrying the transaction
                    read_rty_cnt_exp_out = 1'b0 ; // retry counter hasn't expired yet   
                    last_data_transferred = 1'b0 ;
                    wb_read_done = 1'b0 ;
                    retried_d = 1'b1 ; // there was a retry
                end
                2'b11 :
                begin  // if retry counter reached maximum value
                    n_state = S_READ_RTY ; // go here to wait for PCI Target to remove read request
                    read_rty_cnt_exp_out = 1'b1 ; // signal for reporting read counter expired  
                    last_data_transferred = 1'b0 ;
                    wb_read_done = 1'b0 ;
                    retried_d = 1'b1 ; // there was a retry
                end
                default : // if retry occures after at least 1 data was transferred without breaking cycle (CYC_O inactive)
                begin     // then PCI device will retry access!
                    n_state = S_TURN_ARROUND ; // go to S_TURN_ARROUND state 
                    read_rty_cnt_exp_out = 1'b0 ; // retry counter hasn't expired  
                    last_data_transferred = 1'b1 ;
                    wb_read_done = 1'b1 ;
                    retried_d = 1'b0 ; // retry must not be retried, since there is not a first data
                end
                endcase
            end
            default :
            begin
                addr_count = 1'b0 ;
                read_count_enable = 1'b0 ;
                read_rty_cnt_exp_out = 1'b0 ;
                wait_for_wb_response = 1'b1 ; // wait for WB device to response (after 8 clocks RTY CNT is incremented)
                if((rty_counter_almost_max_value)&&(set_retry)) // when no WB response and RTY CNT reached maximum allowed value 
                begin
                    retried_d = 1'b1 ;
                    n_state = S_TURN_ARROUND ; // go here to stop read request
                    pcir_fifo_wenable = 1'b1 ;
                    pcir_fifo_control[`LAST_CTRL_BIT]       = 1'b0 ;
                    pcir_fifo_control[`DATA_ERROR_CTRL_BIT] = 1'b1 ; // FIFO must indicate the DATA with ERROR
                    pcir_fifo_control[`UNUSED_CTRL_BIT]     = 1'b0 ;
                    pcir_fifo_control[`ADDR_CTRL_BIT]       = 1'b0 ;
                    last_data_transferred = 1'b1 ;
                    wb_read_done = 1'b1 ;
                end
                else
                begin
                    retried_d = 1'b0 ;
                    n_state = S_READ ; // stay in S_READ state to wait WB to response
                    pcir_fifo_wenable = 1'b0 ;
                    pcir_fifo_control = 4'h0 ;
                    last_data_transferred = 1'b0 ;
                    wb_read_done = 1'b0 ;
                end
            end
            endcase
            wb_stb_o = 1'b1 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b1 ;
        end
    S_READ_RTY: // Wait for PCI Target to remove read request, when retry counter reaches maximum value!
        begin
            // Default values for signals not used in this state
            pciw_fifo_renable = 1'b0 ;
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            read_count_enable = 1'b0 ;
            addr_count = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            retried_d = 1'b0 ;
            wb_read_done = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            wait_for_wb_response = 1'b0 ;
            // wait for PCI Target to remove read request
            if (pci_tar_read_request)
            begin
                n_state = S_READ_RTY ; // stay in this state until read request is removed
                last_data_transferred = 1'b0 ;
            end
            else // when read request is removed
            begin
                n_state = S_IDLE ;
                last_data_transferred = 1'b1 ; // when read request is removed, there is "last" data
            end
            wb_stb_o = 1'b0 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b0 ;
        end     
    S_TURN_ARROUND: // Turn arround cycle after writting to PCIR_FIFO (for correct data when reading from PCIW_FIFO) 
        begin
            // Default values for signals not used in this state
            pciw_fifo_renable = 1'b0 ;
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            read_count_enable = 1'b0 ;
            addr_count = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            retried_d = 1'b0 ;
            last_data_transferred = 1'b1 ;
            wb_read_done = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            wait_for_wb_response = 1'b0 ;
            n_state = S_IDLE ;
            wb_stb_o = 1'b0 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b0 ;
        end     
    default : 
        begin
            // Default values for signals not used in this state
            pciw_fifo_renable = 1'b0 ;
            pcir_fifo_wenable = 1'b0 ;
            pcir_fifo_control = 4'h0 ;
            addr_into_cnt = 1'b0 ;
            read_count_load = 1'b0 ;
            read_count_enable = 1'b0 ;
            addr_count = 1'b0 ;
            pci_error_sig_out = 1'b0 ;
            error_source_out = 1'b0 ;
            retried_d = 1'b0 ;
            last_data_transferred = 1'b0 ;
            wb_read_done = 1'b0 ;
            write_rty_cnt_exp_out = 1'b0 ;
            read_rty_cnt_exp_out = 1'b0 ;
            wait_for_wb_response = 1'b0 ;
            n_state = S_IDLE ;
            wb_stb_o = 1'b0 ;
            wb_we_o = 1'b0 ;
            wb_cyc_o = 1'b0 ;
        end
    endcase
end

// Signal for retry monitor in state machine when there is read and first (or single) data access
wire ack_rty_response = ACK_I || RTY_I ;

// Signal first_wb_data_access is set when no WB cycle present till end of first data access of WB cycle on WB bus
always@(posedge wb_clock_in or posedge reset_in)
begin
    if (reset_in)
        first_wb_data_access = 1'b1 ;
    else
    begin
        if (~wb_cyc_o)
            first_wb_data_access = 1'b1 ;
        else if (ack_rty_response)
            first_wb_data_access = 1'b0 ;
    end
end

reg     [3:0]   wb_sel_o;
always@(pciw_fifo_cbe_in or pci_tar_be or wb_we_o or burst_transfer or pci_tar_read_request)
begin
    case ({wb_we_o, burst_transfer, pci_tar_read_request})
    3'b100,
    3'b101,
    3'b110,
    3'b111:
        wb_sel_o = ~pciw_fifo_cbe_in ;
    3'b011:
        wb_sel_o = 4'hf ;
    default:
        wb_sel_o = ~pci_tar_be ;
    endcase
end

// Signals to FIFO
assign  pcir_fifo_be_out = 4'hf ; // pci_tar_be ;

// OUTPUT signals
assign  pci_error_bc = bc_register ;

assign  ADR_O = addr_cnt_out ;

`ifdef REGISTER_WBM_OUTPUTS

    reg     no_sel_o_change_due_rty;
    reg     wb_cyc_reg ;
    always@(posedge wb_clock_in or posedge reset_in)
    begin
        if (reset_in)
        begin
        	no_sel_o_change_due_rty <= #`FF_DELAY 1'b0;
            CYC_O   <= #`FF_DELAY 1'h0 ;
            STB_O   <= #`FF_DELAY 1'h0 ;
            WE_O    <= #`FF_DELAY 1'h0 ;
            CAB_O   <= #`FF_DELAY 1'h0 ;
            MDATA_O <= #`FF_DELAY 32'h0 ;
            SEL_O   <= #`FF_DELAY 4'h0 ;
            wb_cyc_reg <= #`FF_DELAY 1'h0 ;
            wb_read_done_out <= #`FF_DELAY 1'b0 ;
            pcir_fifo_data_out <= #`FF_DELAY 32'h0 ;
            pcir_fifo_wenable_out <= #`FF_DELAY 1'b0 ;
            pcir_fifo_control_out <= #`FF_DELAY 1'b0 ;
        end
        else
        begin
        	if (w_attempt)
        	    if (ACK_I || ERR_I || last_data_transferred)
        	        no_sel_o_change_due_rty <= #`FF_DELAY 1'b0;
        	    else if (retry)
        	        no_sel_o_change_due_rty <= #`FF_DELAY 1'b1;
            if (wb_cyc_o)
            begin // retry = RTY_I || set_retry
                CYC_O   <= #`FF_DELAY ~((ACK_I || retry || ERR_I) && (last_data_transferred || retried_d)) ;
                CAB_O   <= #`FF_DELAY ~((ACK_I || retry || ERR_I) && (last_data_transferred || retried_d)) && burst_transfer ;
                STB_O   <= #`FF_DELAY ~((ACK_I || retry || ERR_I) && (last_data_transferred || retried_d)) ;
            end
            WE_O    <= #`FF_DELAY wb_we_o ;
            if (((wb_cyc_o && ~wb_cyc_reg && !retried_write) || ACK_I) && wb_we_o)
                MDATA_O <= #`FF_DELAY pciw_fifo_addr_data_in ;
            if (w_attempt)
            begin
                if (((wb_cyc_o && ~wb_cyc_reg && !retried_write) || ACK_I) && wb_we_o)
                    SEL_O   <= #`FF_DELAY ~pciw_fifo_cbe_in ;
            end
            else
            begin
                if ((wb_cyc_o && ~wb_cyc_reg) || ACK_I)
                    SEL_O   <= #`FF_DELAY wb_sel_o ;
            end
            wb_cyc_reg <= #`FF_DELAY wb_cyc_o ;
            wb_read_done_out <= #`FF_DELAY wb_read_done ;
            pcir_fifo_data_out <= #`FF_DELAY MDATA_I ;
            pcir_fifo_wenable_out <= #`FF_DELAY pcir_fifo_wenable ;
            pcir_fifo_control_out <= #`FF_DELAY pcir_fifo_control ;
        end
    end
    always@(pciw_fifo_renable or last_data_from_pciw_fifo_reg or wb_cyc_o or wb_cyc_reg or wb_we_o or retried_write or 
            pciw_fifo_control_in or pciw_fifo_empty_in)
    begin
        pciw_fifo_renable_out <=    #`FF_DELAY (pciw_fifo_renable && ~wb_cyc_o) || 
                                    (pciw_fifo_renable && ~last_data_from_pciw_fifo_reg) || 
                                    (wb_cyc_o && ~wb_cyc_reg && wb_we_o && !retried_write) ;
        last_data_from_pciw_fifo_reg <= #`FF_DELAY pciw_fifo_control_in[`ADDR_CTRL_BIT] || pciw_fifo_empty_in ;
    end
`else
    always@(wb_cyc_o or wb_stb_o or wb_we_o or burst_transfer or pciw_fifo_addr_data_in or wb_sel_o or 
            wb_read_done or MDATA_I or pcir_fifo_wenable or pcir_fifo_control)
    begin
        CYC_O   = wb_cyc_o ;
        STB_O   = wb_stb_o ;
        WE_O    = wb_we_o ;
        CAB_O   = wb_cyc_o & burst_transfer ;
        MDATA_O = pciw_fifo_addr_data_in ;
        SEL_O   = wb_sel_o ;
        wb_read_done_out = wb_read_done ;
        pcir_fifo_data_out = MDATA_I ;
        pcir_fifo_wenable_out = pcir_fifo_wenable ;
        pcir_fifo_control_out = pcir_fifo_control ;
    end
    always@(pciw_fifo_renable or last_data_from_pciw_fifo)
    begin
        pciw_fifo_renable_out = pciw_fifo_renable ;
        last_data_from_pciw_fifo_reg = last_data_from_pciw_fifo ;
    end
`endif


endmodule

