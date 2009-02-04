
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
 * This module is the Verilog portion of the programmable PCI
 * master. This module receives a PCI clock from outside, to
 * clock the simulaiton, and reads commands from the system
 * task $pci_master_command (the C portion of the PCI master).
 *
 * Hook up this device like any other PCI device on the bus,
 * and it will use PCI signals to do the reset, request the
 * bus, and implement the whims of the user.
 */

module pci_master(CLK, RESET, AD, C_BE, PAR,
		  FRAME, TRDY, IRDY, STOP,
		  DEVSEL, IDSEL, REQ, GNT, nIRQ, PAR64, AD64, C_BE64, ACK64);

   input  CLK;
   input RESET;
   inout [31:0] AD;
   inout [31:0] AD64;
   inout [3:0] 	C_BE;
   inout [3:0] 	C_BE64;
   inout        PAR;
   inout        PAR64;
   input        ACK64;

   inout 	FRAME, TRDY, IRDY, STOP;
   inout 	DEVSEL;
   input 	IDSEL;

   output 	REQ;
   input 	GNT;

   input [15:0] nIRQ;
 

   localparam CMD_CONFIG_READ  = 'h0a;
   localparam CMD_CONFIG_WRITE = 'h0b;
   localparam CMD_MEMORY_READ     = 'h06;
   localparam CMD_MEMORY64_READ32 = 'h86;
   localparam CMD_MEMORY_WRITE     = 'h07;
   localparam CMD_MEMORY64_WRITE32 = 'h87;
   localparam CMD_WAIT  = 'h10;
   localparam CMD_RESET = 'h20;

   // Initialize RESET to inactive.
   wire 	RESET;
   
   reg REQ;

   reg    PAR_reg;
   reg    PAR_en;
   assign PAR = PAR_en? PAR_reg : 1'bz;
 
   reg [31:0] AD_reg;
   reg 	      AD_en;
   assign     AD = AD_en? AD_reg : 32'hzzzz_zzzz;

   reg [3:0]  C_BE_reg;
   reg 	      C_BE_en;
   assign     C_BE = C_BE_en? C_BE_reg : 4'hz;

   reg 	      FRAME_reg;
   reg 	      FRAME_en;
   assign     FRAME = FRAME_en? FRAME_reg : 1'bz;

   reg 	      IRDY_reg;
   reg 	      IRDY_en;
   assign     IRDY = IRDY_en? IRDY_reg : 1'bz;

   wire [15:0] irq = ~nIRQ;

   always @(posedge CLK) begin
      PAR_en  <= AD_en;
      PAR_reg <= ^AD_reg ^ ^C_BE_reg;
   end

   // These variables receive command code and operand words from the
   // master command reader, and holds them while the tasks below
   // interpret them.
   reg [7:0] cmd;
   reg [31:0] op [15:0];
   reg [31:0] res [15:0];
   
   integer    counter;

   // increment this when a word is transferred.
   reg 	      retry_flag;
`ifdef PCISIM
   // do_wait causes the interpreter to simply wait for a specified
   // number of PCI clocks. The first word of the operand memory is
   // the number of clocks to wait.
   task do_wait;
      reg [31:0] count_down;
      reg [15:0] irq_mask;
      begin
	 count_down = op[0];
	 irq_mask = op[1];
	 while ((count_down > 0) && ! (irq_mask & irq)) begin
	    @(posedge CLK) count_down = count_down - 1;
	 end
	 $pci_master_response(cmd, irq);
      end

   endtask // do_wait
`endif //  `ifdef PCISIM
   
   // Set the reset signal to the value of op[0].
   task do_reset;
      begin
	 REQ      <= 1;
	 C_BE_en  <= 0;
	 AD_en    <= 0;
	 FRAME_en <= 0;
	 IRDY_en  <= 0;
	 PAR_en   <= 0;
      end
   endtask // do_reset

   
   // This task starts a bus cycle for a variety of commands. It
   // generates the REQ#, watches for the GNT#, and transmits the
   // address and command code. The address is pulled from op[0].
   task start_bus_cycle;
      input [3:0] cycle_cmd;

      begin
	//$write(" start bus cycle %h\n", cycle_cmd);
	 counter = 3000;
	 // request bus and wait to be granted. Also wait for
	 // any currently active transaction to complete.
	 REQ <= 0;
	 while ((GNT == 1'b1) || (FRAME == 0) || (IRDY == 0)) begin
	   @(posedge CLK) ;
	   counter = counter - 1;
	   if (counter == 0) begin
	     $write("PCI: REQ for long time, STOP, GNT %h, FRAME %h, IRDY %h\n",
		 GNT, FRAME, IRDY);
		 $stop;
	   end
	end

	 // We can release GNT# and assert FRAME# in the same
	 // CLK. So release it now.
	 REQ <= 1;

	 // Start the transaction by driving FRAME#, driving the
	 // address and driving the C/BE#
	 FRAME_reg <= 0;
	 FRAME_en  <= 1;

	 AD_reg <= op[0];
	 AD_en  <= 1;

	 C_BE_reg <= cycle_cmd; // command word
	 C_BE_en  <= 1;

	 retry_flag = 0;
      end
   endtask // start_bus_cycle

   task start_bus_cycle64;
      input [3:0] cycle_cmd;

      begin
	 // Start with a DAC to send the LAB address bits.
	 start_bus_cycle(4'b1101);

	 // Now send the MSB address bits along with the real command.
	 @(posedge CLK) ;
	 AD_reg <= op[1];
	 AD_en  <= 1;

	 C_BE_reg <= cycle_cmd;
	 C_BE_en  <= 1;
      end
   endtask // start_bus_cycle64

   // This task completes the bus cycle for a single word read.
   // It performs a terminate with data so that the target only
   // transfers a single DWORD.
   task complete_read_cycle;
      begin
	 // Turn off AD drivers for read
	 AD_en <= 0;

	 @(posedge CLK) ; // turnaround complete, ready for transaction

	 // IRDY# is active
	 IRDY_reg <= 0;
	 IRDY_en  <= 1;

	 // We can withdraw FRAME# to make a terminate with data.
	 FRAME_reg <= 1;

	 // Wait for the DEVSEL# from the target, but only wait
	 // for 3 more clocks. If the target is fast, it already
	 // responded, allow for med, slow or subtractive timing.
	 counter = 3;
	 while ((DEVSEL != 0) && (counter > 0))
	   @(posedge CLK) counter = counter - 1;


	 if (DEVSEL != 0) begin

	    // Device never responded. Clean up and return ones.
	    //$pci_master_response(cmd, op[0], 32'hffffffff);
	    $display("PCI: read aborted by timeout");

	 end else begin

	    // Wait for the TRDY# from the target
	    while ((TRDY != 0) && (STOP != 0))
	      @(posedge CLK) /* wait */;

	    if (TRDY == 0) begin
	       retry_flag = 0;
	       if (^AD === 1'bx)
		 $display("PCI: Read from %x returns unknown bits: %b",
			  op[0], AD);

	       $display("PCI: read %08X, %08X, %h", op[0], AD, $time);
	       // Send the response to the master, with the command code,
	       // the address that we are reading, and the value.
	       //$pci_master_response(cmd, op[0], AD);
	       res[0] = AD;
	       
	       IRDY_reg  <= 1;
	       @(posedge CLK) /* Drive IRDY# high for one clock. */;

	    end else begin // if (TRDY == 0)

	       // Retry
	       retry_flag = 1;
	       IRDY_reg  <= 1;
	       @(posedge CLK) /* Drive IRDY# high for one clock. */;

	    end

	 end // else: !if(DEVSEL != 0)

	 C_BE_en  <= 0;
	 FRAME_en <= 0;
	 IRDY_en  <= 0;
      end

   endtask // complete_read_cycle

   task complete_write_cycle;
      input [7:0] val_offset;
      begin
	 // Bus command is sent, switch to BE#. Get the BE#
	 // mask from the op[2] operand.
	 @(posedge CLK)
	   C_BE_reg <= op[val_offset+1];

	 // Now switch to the data that I'm writing.
	 AD_reg <= op[val_offset+0];

	 @(posedge CLK) ; // FIXME
	 // IRDY# is active.
	 IRDY_reg <= 0;
	 IRDY_en  <= 1;
	 @(posedge CLK) ; // FIXME

	 // We can withdraw FRAME# to make a terminate with data.
	 FRAME_reg <= 1;

	 // Wait for the DEVSEL# from the target.
	 counter = 300;
	 while ((DEVSEL != 0) && (counter > 0))
	   @(posedge CLK) counter = counter - 1;
	//$write(" devl sel done\n");
     if (DEVSEL != 0) begin
	    $display("PCI: write aborted by timeout");
	 // Wait for the TRDY# from the target
	 end else while ((TRDY != 0)& (STOP != 0))
	   @(posedge CLK) /* wait */;
         if (TRDY==0) begin
	    retry_flag = 0;
	    //$pci_master_response(cmd, op[0], op[1]);
         end else begin
	    retry_flag = 1;
	 end

	 IRDY_reg  <= 1;
	 @(posedge CLK) /* Drive IRDY# high for one clock. */;

	 AD_en    <= 0;
	 C_BE_en  <= 0;
	 FRAME_en <= 0;
	 IRDY_en  <= 0;
      end
   endtask // complete_write_cycle


   // do_config_read performs a configuration read. The address to
   // read is in op[0].
   task do_config_read;
      begin
	  /*$display("PCI: configuration read from %h", op[0]);*/

	 // Start the bus cycle, and transmit the address and command.
	 start_bus_cycle(4'b1010);

	 @(posedge CLK) // Bus command is sent, switch to BE#
	   C_BE_reg <= 4'b0000;

	 complete_read_cycle;

	 if (retry_flag) begin
	    //$pci_master_response(cmd, op[0], 32'hffffffff);
	    $display("PCI: Configuration read may NOT be retried.");
	 end
      end

   endtask // do_config_read

   // do_config_write performs a configuration read. The address to
   // write is in op[0], and the value to write in op[1]
   task do_config_write;
      begin
	 /*$display("PCI: configuration write %h: %h", op[0], op[1]);*/

	 // Start the bus cycle, and transmit the address and command.
	 start_bus_cycle(4'b1011);

	 complete_write_cycle(1);
      end
   endtask // do_config_write

   task do_memory32_read32;
      reg [7:0] retry_count;
      begin
	 retry_count = 0;
	  /*$display("PCI: memory read %h <-- %h", op[0], op[1]);*/

	 retry_flag = 1;
	 while (retry_flag) begin
	    start_bus_cycle(4'b0110);

	    @(posedge CLK) // Bus command is sent, switch to BE#
	      C_BE_reg <= op[2];

	    complete_read_cycle;
	    retry_count = retry_count + 1;
	 end

	 if (retry_flag) begin
	    // Device never responded. Clean up and return ones.
	    //$pci_master_response(cmd, op[0], 32'hffffffff);
	    $display("PCI: memory read aborted by retry.");
	 end
      end
   endtask // do_memory_read

   task do_memory64_read32;
      reg [7:0] retry_count;
      begin
	 retry_count = 0;

	 retry_flag = 1;
	 while (retry_flag) begin
	    start_bus_cycle64(4'b0110);

	    @(posedge CLK) // Bus command is sent, switch to BE#
	      C_BE_reg <= op[2];

	    complete_read_cycle;
	    retry_count = retry_count + 1;
	 end

	 if (retry_flag) begin
	    // Device never responded. Clean up and return ones.
	    //$pci_master_response(cmd, op[0], 32'hffffffff);
	    $display("PCI: memory read aborted by retry.");
	 end
      end
   endtask // do_memory_read

   task do_memory32_write32;
      begin
	 // $display("PCI: memory write %h <-- %h", op[0], op[1]);
	 retry_flag = 1;
	 while (retry_flag) begin
	    start_bus_cycle(4'b0111);
	    complete_write_cycle(1);
         end
      end
   endtask // do_memory_write

   task do_memory64_write32;
      begin
	 // $display("PCI: memory write %h <-- %h", op[0], op[1]);
	 retry_flag = 1;
	 while (retry_flag) begin
	    start_bus_cycle64(4'b0111);
	    complete_write_cycle(2);
         end
      end
   endtask // do_memory_write

   // This is the main loop. Read a command from the outside world,
   // then switch on the action based on the command code.
`ifdef PCISIM
   always begin
      $pci_master_command(cmd, op);

      case (cmd)

	CMD_CONFIG_READ:  do_config_read;
	CMD_CONFIG_WRITE: do_config_write;
	CMD_MEMORY_READ:  do_memory32_read32;
	CMD_MEMORY_WRITE: do_memory32_write32;
	CMD_MEMORY64_READ32:  do_memory64_read32;
	CMD_MEMORY64_WRITE32: do_memory64_write32;
	CMD_WAIT:         do_wait;
	CMD_RESET:        do_reset;

	8'h00: begin
	   $display("PCI: Exit simulation");
	   $finish;
	end

        default: begin
	   $display("ERROR: Invalid master_command opcode: %h", cmd);
	   $stop;
	end

      endcase
   //$write(" loop\n");
   end
`endif //  `ifdef PCISIM
   
   // This snippet of code monitors the parity on the PCI data
   // busses. Report an error if the parity is odd or unknown.
   reg [35:0] par_data = 'hx;
   reg [35:0] par_data64 = 'hx;
   reg 	      par_data_flag = 1'b0;
   reg 	      FRAME_delayed = 1'b1;
   reg 	      calculated_parity; 	      
   reg 	      calculated_parity64; 	      
   always @(posedge CLK) begin

      if (par_data_flag) begin
	 calculated_parity = ^{par_data, PAR};
	 if ( 1'b0 !== (calculated_parity) ) begin
	    $display("PCI: Parity error detected: {C_BE, AD} = %h, PAR=%b, %h/%h, %h",
		     par_data, PAR, AD, C_BE, $time);
	    if ($test$plusargs("pci-parity-x-ok") && calculated_parity===1'bx)
	      $display("PCI: Ignoring bogus parity calculation.");
	    else begin
               $dumpflush(".");
	       $stop;
            end
	 end
	 calculated_parity64 = ^{par_data64, PAR64};
	 if ( 1'b0 !== (calculated_parity64) & ~ACK64) begin
	    $display("PCI: Parity error detected: {C_BE64, AD64} = %h, PAR64=%b, %h/%h, %h",
		     par_data64, PAR64, AD64, C_BE64, $time);
	    if ($test$plusargs("pci-parity-x-ok") && calculated_parity===1'bx)
	      $display("PCI: Ignoring bogus parity calculation.");
	    else begin
              $dumpflush(".");
	       $stop;
            end
	 end
      end

      // If this is an address cycle (first cycle of the frame)
      // or a data cycle (cycle with IRDY and TRDY) then
      // snapshot the data for a parity check.
      if ( ((FRAME==0) && (FRAME_delayed==1))
	   || ((IRDY==0) && (TRDY==0)) ) begin
	 par_data <= {C_BE, AD};
	 par_data64 <= {C_BE64, AD64};
	 par_data_flag <= 1;
      end else begin
	 par_data = 'h0;
	 par_data64 = 'h0;
	 par_data_flag <= 0;
      end

      FRAME_delayed <= FRAME;
   end

endmodule // pci_master
