task lg_test_initial_all_conf_values;
   reg [11:0] register_offset;
   reg [31:0] expected_value;
   reg 	      failed;
   reg [31:0] header_value[0:15];
   reg [5:0]  reg_address;
   integer    t_i;
   reg [31:0] tmp_reg_val;
   
   begin
      test_name  = "DEFINED INITIAL VALUES OF CONFIGURATION REGISTERS" ;
      
      failed = 0;      
      t_i = 0;
      while (t_i < 16) begin
	 header_value[t_i] = 0;
	 t_i = t_i + 1;
      end
      // fill header register values
      header_value[0] = {`HEADER_DEVICE_ID, `HEADER_VENDOR_ID} ;
      // determine the expected value of status and control registers
      tmp_reg_val = 'h0 ;
      tmp_reg_val[10+16:9+16] = 'b01 ;
      // devsel timing
      tmp_reg_val[7+16] = 1'b1 ;
      // fast b2b capable
`ifdef PCI66
      tmp_reg_val[5+16] = 1'b1 ;
      // 66MHz capable
`endif
      header_value[1] = tmp_reg_val ;
      // class code, revision ID register
      tmp_reg_val = 'h0 ;
      tmp_reg_val[31:24] = 'h06 ;
      tmp_reg_val[7:0] = `HEADER_REVISION_ID ;
      tmp_reg_val[23:16] = 'h80 ;
      header_value[2] = tmp_reg_val ;
      header_value[11] = {`HEADER_SUBSYS_ID, `HEADER_SUBSYS_VENDOR_ID} ;
      header_value[15] = {`HEADER_MAX_LAT, `HEADER_MIN_GNT, 8'h01, 8'h00} ;
      
      if (`PCI_AM1 >> 23) begin
	 header_value[5] = `PCI_BA1_MEM_IO ;
      end
`ifdef PCI_IMAGE2
      if (`PCI_AM2 >> 23)                        //PCi Base Address    Register2
	begin
	   header_value[6] = `PCI_BA2_MEM_IO ;
	end
`endif
`ifdef PCI_IMAGE3
    if (`PCI_AM3 >> 23)                        //PCi Base Address    Register3
      begin
	 header_value[7] = `PCI_BA3_MEM_IO ;
      end
`endif
`ifdef PCI_IMAGE4
      if (`PCI_AM4 >> 23)                        //PCi Base Address    Register4 
	begin
	   header_value[8] = `PCI_BA4_MEM_IO ;
	end
`endif
`ifdef PCI_IMAGE5
      if (`PCI_AM5 >> 23)                        //PCi Base Address    Register5 
	begin
	   header_value[9] = `PCI_BA5_MEM_IO ;
	end
`endif
      
      begin: guest_regs_check
	 reg [31:0] read_data;
	 integer    t_max;
	 reg 	    ok;
	 // first read the header portion using the configuration cycles
	 reg_address = 0;
	 while (reg_address < 'd16) begin
	    configuration_cycle_read
	      (8'h00,                          // bus number [7:0]
	       `TAR0_IDSEL_INDEX - 11,         // device number [4:0]
	       3'h0,                           // function number [2:0]
	       reg_address,                    // register number [5:0]
	       2'h0,                           // type [1:0]
	       4'hF,                           // byte enables [3:0]
	       read_data                       // data returned from configuration read [31:0]
	       );
	    if( read_data !== header_value[reg_address]) begin
	       $fdisplay(tb_log_file, "error Config Register Adress %h",
			 {4'h0, reg_address ,2'b00},
			 ," expected:%h ",header_value[reg_address]," read:%h",read_data);
	       $display("error Config Register Adress %h",
			{4'h0, reg_address ,2'b00},
			," expected:%h ",header_value[reg_address]," read:%h",read_data,
			" Time %t ", $time) ;
	       test_fail("Initial value of register not as expected") ;
	       failed = 1 ;
	    end // if ( read_data !== header_value[reg_address])
	    reg_address= reg_address+1;
	 end // while (reg_address <= 'd16)
      end // block: guest_regs_check
      
   end
endtask // lg_test_pci_configuration

task test_pci_master;
   reg [31:0] target_address;
   reg 	      `WRITE_RETURN_TYPE write_status;
   reg 	      `READ_RETURN_TYPE read_status;
   reg 	      ok;
   reg 	      byte_ofs;

   reg 	      `WRITE_STIM_TYPE write_data ;
   reg 	      `WB_TRANSFER_FLAGS write_flags ;
   reg 	      `READ_STIM_TYPE  read_data;
   
   integer    i;
   begin : main
      target_address = `BEH_TAR1_MEM_START ;

      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.single_write(target_address + ({$random}%4),
						       wmem_data[0],
						       write_status,
						       wb_init_waits);
	    
	    test_name = "NORMAL SINGLE MEMORY WRITE THROUGH LBUS IMAGE TO PCI" ;
	    if (write_status `CYC_ACTUAL_TRANSFER != 1) begin
	       $display("Image testing failed! Bridge failed to process single memory write! Time %t ",
			$time);
	       test_fail("LBUS Slave state machine failed to post single memory write");
	    end

	    SYSTEM.bridge32_top.master_tb.single_read(target_address + ({$random}%4),
						      read_status,
						      wb_init_waits);
	    if (read_status`CYC_ACTUAL_TRANSFER !== 1) begin
	       $display("Image testing failed! Bridge failed to process single memory read! Time %t ", $time) ;
	       test_fail("PCI bridge didn't process the read as expected");
	       disable main ;
	    end
	    if (read_status`READ_DATA !== wmem_data[0]) begin
	       display_warning(target_address, wmem_data[0], read_status`READ_DATA) ;
	       test_fail("PCI bridge returned unexpected Read Data");
	    end
	    else
	      test_ok ;
	 end // fork begin
	 begin
	    pci_transaction_progress_monitor( target_address, `BC_MEM_WRITE, 1, 0, 1, 0, 0, ok ) ;
	    if (ok !== 1) begin
	       test_fail("because single memory write from LBUS to PCI didn't engage expected transaction on PCI bus") ;
	    end
	    else
	      test_ok ;
	    
	    test_name = "NORMAL SINGLE MEMORY READ THROUGH LBUS IMAGE FROM PCI" ;
	    pci_transaction_progress_monitor( target_address, `BC_MEM_READ, 1, 0, 1, 0, 0, ok ) ;
	    if ( ok !== 1 ) begin
	       test_fail("because single memory read from WB to PCI didn't engage expected transaction on PCI bus") ;
	    end
	 end
      join

      test_name = "MULTIPLE NORMAL SINGLE MEMORY READS, SAME ADDRESS, CHANGE DATA" ;
      i = 32'hFFFF_FFFF;

      target_address = `BEH_TAR1_MEM_START + ({$random}%4) + 72;
      
      fork
	 begin
	    repeat(5) begin
	       pci_behaviorial_device1.pci_behaviorial_target.Test_Device_Mem[72 >> 2] = $random ;
	       SYSTEM.bridge32_top.master_tb.single_read(target_address,
							 read_status,
							 wb_init_waits);
	       if (read_status`CYC_ACTUAL_TRANSFER !== 1) begin
		  $display("Image testing failed! Bridge failed to process single memory read! Time %t ", $time) ;
		  test_fail("PCI bridge didn't process the read as expected");
		  i[0] = 1'b0;
	       end
	       if (read_status`READ_DATA !==
		   pci_behaviorial_device1.pci_behaviorial_target.Test_Device_Mem[72 >> 2]) begin
		  display_warning(target_address, 
				  pci_behaviorial_device1.pci_behaviorial_target.Test_Device_Mem[72 >> 2], 
				  read_status`READ_DATA) ;
		  test_fail("PCI bridge returned unexpected Read Data");
		  i[0] = 1'b0 ;
	       end
	       //FAST_B2B TODO, we not support it.
	       //write_flags`WB_FAST_B2B = 1'b1 ;
	    end // repeat (5)
	    if (i === 32'hFFFF_FFFF)
	      test_ok;
	 end // fork begin
	 begin
	    repeat(5) begin
	       pci_transaction_progress_monitor(target_address & 32'hffff_fffc, `BC_MEM_READ, 1, 0, 1, 0, 0, ok ) ;
	       if ( ok !== 1 ) begin
		  i[1] = 1'b0 ;
		  test_fail("because single memory read from WB to PCI didn't engage expected transaction on PCI bus") ;
	       end
	    end
	 end
      join

      test_name = "MULTIPLE NON-CONSECUTIVE SINGLE MEMORY WRITES THROUGH WISHBONE SLAVE UNIT" ;
      begin: non_consecutive_single_writes_test_blk
	 integer pause_between_writes;
	 integer rnd_seed;

	 reg [31:0] cur_wb_adr;
	 reg 	    generate_pci_traffic;
	 reg [31:0] target2_address;

	 rnd_seed = 32'h12fe_dc34;

	 fork
	  begin: wb_write_gen_blk
	    for (pause_between_writes = 128;
		 pause_between_writes > 0;
		 pause_between_writes = pause_between_writes - 1) begin
	       cur_wb_adr = `BEH_TAR1_MEM_START + pause_between_writes * 4;
	       
	       SYSTEM.bridge32_top.master_tb.single_write(cur_wb_adr + ({$random}%4),
							  $random(rnd_seed),
							  write_status,
							  wb_init_waits);
	       if ( write_status`CYC_ACTUAL_TRANSFER !== 1 ) begin
		  $display("Image testing failed! Bridge failed to process single memory write! Time %t ", $time) ;
		  test_fail("WB Slave state machine failed to post single memory write");
		  ok = 0 ;
		  disable non_consecutive_single_writes_test_blk ;
	       end // if ( write_status`CYC_ACTUAL_TRANSFER !== 1 )
	       repeat(pause_between_writes)
		 @(posedge pci_clock) ;
	    end
	 end // block: wb_write_gen_blk
	 begin:pci_write_chk_blk
	    integer cur_wriete;
	    reg [31:0] cur_pci_adr;
	    for (cur_wriete = 128;
		 cur_wriete > 0;
		 cur_wriete =  cur_wriete - 1) begin
	       cur_pci_adr = `BEH_TAR1_MEM_START + cur_wriete * 4;
	       pci_transaction_progress_monitor( cur_pci_adr, `BC_MEM_WRITE, 1, 0, 1, 0, 0, ok ) ;
	       if ( ok !== 1 ) begin
		  test_fail("single memory write from WB to PCI didn't engage expected transaction on PCI bus") ;
		  disable non_consecutive_single_writes_test_blk ;
	       end
	    end
	 end // block: pci_write_chk_blk
	 join

	 // check write data
	 rnd_seed = 32'h12fe_dc34;
	 for (pause_between_writes = 128;
	      pause_between_writes > 0;
	      pause_between_writes =  pause_between_writes -1) begin
	    cur_wb_adr = `BEH_TAR1_MEM_START + pause_between_writes * 4;
	    
	    SYSTEM.bridge32_top.master_tb.single_read(cur_wb_adr + ({$random}%4),
						      read_status,
						      wb_init_waits);
	    if (read_status`CYC_ACTUAL_TRANSFER !== 1) begin
	       $display("Image testing failed! Bridge failed to process single memory read! Time %t ", $time) ;
	       test_fail("PCI bridge didn't process the read as expected");
	       ok = 0;
	       disable non_consecutive_single_writes_test_blk ;
	    end
	    if (read_status`READ_DATA !== $random(rnd_seed)) begin
               $display("Time %t", $time) ;
	       $display("Single memory read through WB Slave unit returned unexpected data value!") ;
	       test_fail("Single memory read through WB Slave unit returned unexpected data value") ;
	       ok = 1'b0 ;
	       disable non_consecutive_single_writes_test_blk ;
	    end
	    /* B2B TODO */
	 end

	 if (ok == 1)
	   test_ok;
	 
      end // block: non_consecutive_single_writes_test_blk

      // now do one burst write
      byte_ofs = ({$random}%4);
      for (i = 0; i < 6; i = i + 1) begin
         write_data`WRITE_DATA    = wmem_data[2 + i] ;
	 write_data`WRITE_ADDRESS = `BEH_TAR1_MEM_START + 8 + 4*i + byte_ofs ;
	 write_data`WRITE_SEL     = 4'hF ;
	 SYSTEM.bridge32_top.master_tb.blk_write_data[i] = write_data;
      end
      
      write_flags`WB_TRANSFER_AUTO_RTY = 0 ;
      write_flags`WB_TRANSFER_CAB    = 1 ;
      write_flags`WB_TRANSFER_SIZE   = 6 ;

      fork
	 begin
	    test_name = "CAB MEMORY WRITE THROUGH WB SLAVE TO PCI" ;
	    SYSTEM.bridge32_top.master_tb.block_write(write_flags, write_status);
            if ( write_status`CYC_ACTUAL_TRANSFER !== 6 )
              begin
		 $display("Image testing failed! Bridge failed to process CAB memory write! Time %t ", $time) ;
		 test_fail("WB Slave state machine failed to post CAB memory write") ;
		 disable main ;
              end
	 end
	 
	 begin
	    pci_transaction_progress_monitor(`BEH_TAR1_MEM_START + 8, `BC_MEM_WRITE, 6, 0, 1'b1, 0, 0, ok ) ;
	    if ( ok !== 1 )  begin
	       test_fail("CAB memory write didn't engage expected transaction on PCI bus") ;
	    end else
	      test_ok ;
	 end
      join

      // set burst size and latency timer
      config_write( 12'h00C, {bridge_latency, 8'd4}, 4'b1111, ok ) ;
      write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
      write_flags`WB_TRANSFER_CAB    = 1 ;
      write_flags`WB_TRANSFER_SIZE   = 4 ;
      byte_ofs = ({$random} % 4) ;
      // prepare read data
      for ( i = 0 ; i < 4 ; i = i + 1 )
	begin
	   read_data`READ_ADDRESS = `BEH_TAR1_MEM_START + 8 + 4*i + byte_ofs ;
	   read_data`READ_SEL     = 4'hF ;
	   SYSTEM.bridge32_top.master_tb.blk_read_data[i] = read_data ;
	end

      fork 
	 begin
	    test_name = "CAB MEMORY READ THROUGH WB SLAVE FROM PCI" ;
	    SYSTEM.bridge32_top.master_tb.block_read(write_flags, read_status);
	    if ( read_status`CYC_ACTUAL_TRANSFER !== 4 )
	      begin
		 $display("Image testing failed! Bridge failed to process CAB memory read! Time %t ", $time) ;
		 test_fail("PCI Bridge Failed to process delayed CAB read") ;
		 disable main ;
	      end

	    // check data read from target
	    for ( i = 0 ; i < 4 ; i = i + 1 )  begin
	       read_status = SYSTEM.bridge32_top.master_tb.blk_read_data_out[i] ;
	       if (read_status`READ_DATA !== wmem_data[2 + i]) begin
		  display_warning(`BEH_TAR1_MEM_START + 8 + 4 * i, wmem_data[2 + i], read_status`READ_DATA) ;
		  test_fail("data returned by PCI bridge during completion of Delayed Read didn't have expected value") ;
	       end
	    end // for ( i = 0 ; i < 4 ; i = i + 1 )
	 end
	 begin
	    pci_transaction_progress_monitor(`BEH_TAR1_MEM_START + 8, `BC_MEM_READ, 4, 0, 1'b1, 0, 0, ok ) ;
	    if ( ok !== 1 )
	      test_fail("CAB memory read divided into single transactions didn't engage expected transaction on PCI bus") ;
	    else
	      test_ok ;
	 end
      join
      
      /*TODO 
       IO SPACE TEST
       */
      //$stop;
   end
endtask // test_pci_master

task test_pci_master_error_handling;
   reg   [11:0] ctrl_offset ;
   reg [11:0] 	ba_offset ;
   reg [11:0] 	am_offset ;
   reg [11:0] 	ta_offset ;
   reg [11:0] 	err_cs_offset ;
   reg 		`WRITE_STIM_TYPE write_data ;
   reg 		`READ_STIM_TYPE  read_data ;
   reg 		`READ_RETURN_TYPE read_status ;
   reg 		`WRITE_RETURN_TYPE write_status ;
   reg 		`WB_TRANSFER_FLAGS write_flags ;
   reg [31:0] 	temp_val1 ;
   reg [31:0] 	temp_val2 ;
   reg 		ok   ;
   reg [11:0] 	pci_ctrl_offset ;
   reg [31:0] 	image_base ;
   reg [31:0] 	target_address ;
   integer 	num_of_trans ;
   integer 	current ;
   integer 	i ;
   reg [ 1: 0] 	byte_ofs ;
   
   begin: main
      target_address = `BEH_TAR1_MEM_START;
      
      $display("************* Testing handling of PCI bus errors ***************") ;
      
      // perform two writes - one to error address and one to OK address
      // prepare write buffer
      write_data`WRITE_ADDRESS  = `BEH_TAR1_MEM_START  + ({$random} % 4) ;
      write_data`WRITE_DATA     = wmem_data[100] ;
      write_data`WRITE_SEL      = 4'hF ;
      SYSTEM.bridge32_top.master_tb.blk_write_data[0] = write_data ;
      write_flags`WB_TRANSFER_SIZE = 2 ;
      // don't handle retries
      write_flags`WB_TRANSFER_AUTO_RTY = 0 ;
      write_flags`WB_TRANSFER_CAB    = 0 ;
      
      $display("Introducing master abort error on single WB to PCI write!") ;
      test_name = "MASTER ABORT ERROR HANDLING DURING WB TO PCI WRITES" ;
      // first disable target 1
      configuration_cycle_write(0,                        // bus number
				`TAR1_IDSEL_INDEX - 11,   // device number
				0,                        // function number
				1,                        // register number
				0,                        // type of configuration cycle
				4'b0001,                  // byte enables
				32'h0000_0000             // data
				) ;
      
      fork
	 begin
	    // start no response monitor in parallel with writes
	    musnt_respond(ok) ;
	    if ( ok !== 1 ) begin
	       $display("PCI bus error handling testing failed! Test of master abort handling got one target to respond! Time %t ", $time) ;
	       $display("Testbench is configured wrong!") ;
	       test_fail("transaction wasn't initiated by PCI Master state machine or Target responded and Master Abort didn't occur");
	    end
	    else
	      test_ok ;
	 end // fork begin
	 begin
	    SYSTEM.bridge32_top.master_tb.single_write(write_data`WRITE_ADDRESS,
						       write_data`WRITE_DATA,
						       write_status,
						       wb_init_waits);
	    wishbone_master.wb_single_write(write_data, write_flags, write_status) ;
	    if ( write_status`CYC_ACTUAL_TRANSFER != 0 ) begin // XXX
	       $display("PCI bus error handling testing failed! WB slave didn't acknowledge single write cycle! Time %t ", $time) ;
	       $display("WISHBONE slave response: ACK = %b, RTY = %b, ERR = %b ", write_status`CYC_ACK, write_status`CYC_RTY, write_status`CYC_ERR) ;
	       test_fail("WB Slave state machine failed to post single memory write");
	       disable main ;
	    end // if ( write_status`CYC_ACTUAL_TRANSFER !== 1 )
	 end // fork branch
      join

      // read data from second write
      write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
      read_data`READ_ADDRESS = `BEH_TAR1_MEM_START  + ({$random} % 4) ;
      read_data`READ_SEL     = 4'hF ;
      SYSTEM.bridge32_top.master_tb.single_read(read_data`READ_ADDRESS,
						read_status,
						wb_init_waits);
      if ((read_status`CYC_ACTUAL_TRANSFER != 0) | (read_status`CYC_ERR !== 1'b1))/* XXX*/
	begin
	   $display("PCI bus error handling testing failed! WB slave didn't respond with error on Master Aborted single read! Time %t ", $time) ;
	   $display("WISHBONE slave response: ACK = %b, RTY = %b, ERR = %b ", read_status`CYC_ACK, read_status`CYC_RTY, read_status`CYC_ERR) ;
	   test_fail("WB Slave Unit didn't process the Master Abort error during single read properly");
	   disable main ;
	end // if ((read_status`CYC_ACTUAL_TRANSFER !== 0) | (read_status`CYC_ERR !== 1'b1))

      // read error status register - no errors should be reported since reporting was disabled
      test_name = "CHECKING ERROR REPORTING FUNCTIONS AFTER MASTER ABORT ERROR" ;
      @(posedge pci_clock);
      @(posedge pci_clock);
      
      if (SYSTEM.bridge32_top.csr[39] != 0) begin
	 $display("PCI bus error handling testing failed! Time %t ", $time) ;
	 $display("Error reporting was disabled, but error was reported anyway!") ;
	 test_fail("Error reporting was disabled, but error was reported anyway") ;
	 disable main ;
      end
      test_ok;

      test_name = "CHECKING INTERRUPT REQUESTS AFTER MASTER ABORT ERROR" ;
      // check for interrupts - there should be no interrupt requests active
      repeat(4)
	@(posedge pci_clock);
      if ( INTA != 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   
	   $display("WISHBONE error interrupt enable is cleared, error signal bit is cleared, but interrupt was signalled on PCI bus!") ;
	   
	   test_fail("WISHBONE error interrupts were disabled, error signal bit is clear, but interrupt was signalled on PCI bus") ;
	   
	end
      else
	test_ok ;
      $stop;
      
      test_name = "CHECKING PCI DEVICE STATUS REGISTER VALUE AFTER MASTER ABORT" ;

      pci_ctrl_offset = 12'h4;
      
      // check PCI status register
      config_read( pci_ctrl_offset, 4'hF, temp_val1 ) ;
      if ( temp_val1[29] !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Master Abort bit was not set when write was terminated with Master Abort!") ;
	   test_fail("Received Master Abort bit was not set when write was terminated with Master Abort") ;
	end
      else
	test_ok ;

      // clear
      config_write( pci_ctrl_offset, temp_val1, 4'b1100, ok ) ;

      write_flags`WB_TRANSFER_AUTO_RTY = 0 ;
      $display("Introducing master abort error to CAB write!") ;
      // now enable error reporting mechanism
      //config_write( err_cs_offset, 1, 4'h1, ok ) ;

      // configure flags for CAB transfer
      write_flags`WB_TRANSFER_CAB = 1 ;
      write_flags`WB_TRANSFER_SIZE = 3 ;
      write_flags`WB_TRANSFER_AUTO_RTY = 0 ;
      
      // prepare data for erroneous write
      byte_ofs = ({$random} % 4) ;
      for ( i = 0 ; i < 3 ; i = i + 1 )
	begin
	   write_data`WRITE_ADDRESS = `BEH_TAR1_MEM_START + 4*i + byte_ofs ;
	   write_data`WRITE_DATA    = wmem_data[110 + i] ;
	   write_data`WRITE_SEL     = 4'hF ;
	   SYSTEM.bridge32_top.master_tb.blk_write_data[i] = write_data ;
	end

      test_name = "CHECKING MASTER ABORT ERROR HANDLING ON CAB MEMORY WRITE" ;
      
      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.block_write(write_flags, write_status) ;
	    if ( write_status`CYC_ACTUAL_TRANSFER != 0 )
              begin
		 $display("PCI bus error handling testing failed! Time %t ", $time) ;
		 $display("Complete burst write through WB slave didn't succeed!") ;
		 test_fail("WB Slave state machine failed to post CAB Memory write") ;
		 disable main ;
              end
	 end // fork begin
	 begin
	    musnt_respond(ok) ;
	    if ( ok !== 1 )
	      begin
		 $display("PCI bus error handling testing failed! Test of master abort handling got one target to respond! Time %t ", $time) ;
		 $display("Testbench is configured wrong!") ;
		 test_fail("transaction wasn't initiated by PCI Master state machine or Target responded and Master Abort didn't occur");
	      end
	    else
	      test_ok ;
	 end // fork branch
      join

      // check error status address, data, byte enables and bus command
      // error status bit is signalled on PCI clock and synchronized to WB clock
      // wait one PCI clock cycle
      test_name = "CHECKING ERROR REPORTING REGISTERS' VALUES AFTER MASTER ABORT ERROR" ;
      ok = 1 ;
      @(posedge pci_clock) ;

      /* XXX */
      if (SYSTEM.bridge32_top.csr[39] != 0) begin
	 $display("PCI bus error handling testing failed! Time %t ", $time) ;
	 $display("Error reporting was disabled, but error was reported anyway!") ;
	 test_fail("Error reporting was disabled, but error was reported anyway") ;
	 disable main ;
	 ok = 0;
      end
      
      // check PCI status register
      config_read( pci_ctrl_offset, 4'hF, temp_val1 ) ;
      if ( temp_val1[29] !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Master Abort bit was not set when write was terminated with Master Abort!") ;
	   test_fail("Received Master Abort bit in PCI Device Status register was not set when write was terminated with Master Abort") ;
	   ok = 0 ;
	end

      if ( temp_val1[28] !== 0 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Target Abort bit was set for no reason!") ;
	   test_fail("Received Target Abort bit was set for no reason") ;
	   ok = 0 ;
    end
    if ( ok )
      test_ok ;

      test_name = "CHECKING INTERRUPT REQUESTS AFTER MASTER ABORT ERROR" ;
      // check for interrupts - there should be no interrupt requests active
      repeat(4)
	@(posedge pci_clock);
      if ( INTA != 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   
	   $display("WISHBONE error interrupt enable is cleared, error signal bit is cleared, but interrupt was signalled on PCI bus!") ;
	   
	   test_fail("WISHBONE error interrupts were disabled, error signal bit is clear, but interrupt was signalled on PCI bus") ;
	   
	end
      else
	test_ok ;
      $stop;
      
      test_name = "CHECK NORMAL WRITING/READING FROM WISHBONE TO PCI AFTER ERRORS WERE PRESENTED" ;
      ok = 1 ;
      
      // enable target
      configuration_cycle_write(0,                        // bus number
				`TAR1_IDSEL_INDEX - 11,   // device number
				0,                        // function number
				1,                        // register number
				0,                        // type of configuration cycle
				4'b0001,                  // byte enables
				32'h0000_0007             // data
				) ;
      
      // prepare data for ok write
      byte_ofs = ({$random} % 4) ;
      for ( i = 0 ; i < 3 ; i = i + 1 )
	begin
	   write_data`WRITE_ADDRESS = target_address + 4*i + byte_ofs ;
	   write_data`WRITE_DATA    = wmem_data[113 + i] ;
	   write_data`WRITE_SEL     = 4'hF ;
	   SYSTEM.bridge32_top.master_tb.blk_write_data[i] = write_data ;
	end // for ( i = 0 ; i < 3 ; i = i + 1 )

      SYSTEM.bridge32_top.master_tb.block_write(write_flags, write_status) ;
      if ( write_status`CYC_ACTUAL_TRANSFER !== 3 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Complete burst write through WB slave didn't succeed!") ;
	   test_fail("WB Slave state machine failed to post CAB write") ;
	   disable main ;
	end // if ( write_status`CYC_ACTUAL_TRANSFER !== 3 )

      // do a read
      byte_ofs = ({$random} % 4) ;
      for ( i = 0 ; i < 3 ; i = i + 1 )
	begin
	   read_data`READ_ADDRESS = target_address + 4*i  + byte_ofs ;
	   read_data`READ_SEL     = 4'hF ;
	   SYSTEM.bridge32_top.master_tb.blk_read_data[i] = read_data ;
	end
      write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
      write_flags`WB_TRANSFER_SIZE   = 3 ;
      write_flags`WB_TRANSFER_CAB    = 1 ;
      
      SYSTEM.bridge32_top.master_tb.block_read( write_flags, read_status ) ;
      if ( read_status`CYC_ACTUAL_TRANSFER !== 3 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	       $display("Complete burst read through WB slave didn't succeed!") ;
	       test_fail("Delayed CAB write was not processed as expected") ;
	       disable main ;
	end // if ( read_status`CYC_ACTUAL_TRANSFER !== 3 )
      for ( i = 0 ; i < 3 ; i = i + 1 )
	begin
	   read_status = SYSTEM.bridge32_top.master_tb.blk_read_data_out[i] ;
	   if ( read_status`READ_DATA !== wmem_data[113 + i] )
	     begin
		display_warning( target_address + 4*i, wmem_data[113 + i], read_status`READ_DATA ) ;
		test_fail ( "data value provided by PCI bridge for normal read was not as expected") ;
	     end
	end // for ( i = 0 ; i < 3 ; i = i + 1 )
      
      $display("Introducing master abort error to single read!") ;
      // disable target
      configuration_cycle_write(0,                        // bus number
				`TAR1_IDSEL_INDEX - 11,   // device number
				0,                        // function number
				1,                        // register number
				0,                        // type of configuration cycle
				4'b0001,                  // byte enables
				32'h0000_0000             // data
				) ;
      
      // set read data
      read_data`READ_ADDRESS  = target_address  + ({$random} % 4) ;
      read_data`READ_SEL      = 4'hF ;
      // enable automatic retry handling
      write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
      write_flags`WB_TRANSFER_CAB      = 0 ;

      test_name = "MASTER ABORT ERROR HANDLING FOR WB TO PCI READS" ;
      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.wb_single_read(read_data, write_flags, read_status);
	 end
	 begin
	    musnt_respond(ok) ;
	    if ( ok !== 1 )
	      begin
		 $display("PCI bus error handling testing failed! Test of master abort handling got one target to respond! Time %t ", $time) ;
		 $display("Testbench is configured wrong!") ;
		 test_fail("transaction wasn't initiated by PCI Master state machine or Target responded and Master Abort didn't occur");
	      end
	 end
      join

      if ( (read_status`CYC_ACTUAL_TRANSFER !== 0) || (read_status`CYC_ERR !== 1) )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Read terminated with master abort should return zero data and terminate WISHBONE cycle with error!") ;
	   $display("Actuals: Data transfered: %d, slave response: ACK = %b, RTY = %b, ERR = %b ", read_status`CYC_ACTUAL_TRANSFER, read_status`CYC_ACK, read_status`CYC_RTY, read_status`CYC_ERR) ;
	   test_fail("read didn't finish on WB bus as expected") ;
	   disable main ;
	end // if ( (read_status`CYC_ACTUAL_TRANSFER !== 0) || (read_status`CYC_ERR !== 1) )
      test_ok ;
      
      // now check for error statuses - because reads are delayed, nothing of a kind should happen on error
      test_name = "CHECKING ERROR STATUS AFTER MASTER ABORT ON READ" ;
      ok = 1;
      @(posedge pci_clock);
      
      /* XXX */
      if (SYSTEM.bridge32_top.csr[39] != 0) begin
	 $display("PCI bus error handling testing failed! Time %t ", $time) ;
	 $display("Error reporting was disabled, but error was reported anyway!") ;
	 test_fail("Error reporting was disabled, but error was reported anyway") ;
	 disable main ;
	 ok = 0;
      end
      if (ok)
	test_ok;

      // now check normal read operation
      configuration_cycle_write(0,                        // bus number
				`TAR1_IDSEL_INDEX - 11,   // device number
				0,                        // function number
				1,                        // register number
				0,                        // type of configuration cycle
				4'b0001,                  // byte enables
				32'h0000_0007             // data
				) ;
      
      test_name = "CHECK NORMAL READ AFTER MASTER ABORT TERMINATED READ" ;
      read_data`READ_ADDRESS  = target_address  + ({$random} % 4) ;
      read_data`READ_SEL      = 4'hF ;

      SYSTEM.bridge32_top.master_tb.wb_single_read(read_data, write_flags, read_status) ;
      if ( read_status`CYC_ACTUAL_TRANSFER !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("WB slave failed to process single read!") ;
	   $display("Slave response: ACK = %b, RTY = %b, ERR = %b ", read_status`CYC_ACTUAL_TRANSFER, read_status`CYC_ACK, read_status`CYC_RTY, read_status`CYC_ERR) ;
	   test_fail("PCI Bridge didn't process single Delayed Read as expected") ;
	   disable main ;
	end // if ( read_status`CYC_ACTUAL_TRANSFER !== 1 )
      if ( read_status`READ_DATA !== wmem_data[113] )
	begin
	   display_warning( target_address, wmem_data[113 + i], read_status`READ_DATA ) ;
	   test_fail("when read finished on WB bus, wrong data was provided") ;
	end
      else
	test_ok ;

      // check PCI status register
      test_name = "CHECK PCI DEVICE STATUS REGISTER VALUE AFTER MASTER ABORT ON DELAYED READ" ;
      ok = 1 ;
      config_read( pci_ctrl_offset, 4'hF, temp_val1 ) ;
      if ( temp_val1[29] !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Master Abort bit was not set when read was terminated with Master Abort!") ;
	   test_fail("Received Master Abort bit was not set when read was terminated with Master Abort") ;
	   ok = 0 ;
	end
      if ( temp_val1[28] !== 0 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Target Abort bit was set for no reason!") ;
	   test_fail("Received Target Abort bit was set for no reason") ;
	   ok = 0 ;
	end
      if ( ok )
	test_ok ;

      config_write( pci_ctrl_offset, temp_val1, 4'b1100, ok ) ;
      $display("Introducing master abort error to CAB read!") ;
      test_name = "MASTER ABORT ERROR DURING CAB READ FROM WB TO PCI" ;
      configuration_cycle_write(0,                        // bus number
			        `TAR1_IDSEL_INDEX - 11,   // device number
			        0,                        // function number
			        1,                        // register number
			        0,                        // type of configuration cycle
			        4'b0001,                  // byte enables
			        32'h0000_0000             // data
				) ;
      
      byte_ofs = ({$random} % 4) ;
      for ( i = 0 ; i < 3 ; i = i + 1 )
	begin
	   read_data`READ_ADDRESS = target_address + 4*i + byte_ofs ;
	   read_data`READ_SEL     = 4'hF ;
	   SYSTEM.bridge32_top.master_tb.blk_read_data[i] = read_data ;
	end

      write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
      write_flags`WB_TRANSFER_SIZE     = 3 ;
      write_flags`WB_TRANSFER_CAB      = 1 ;
      
      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.block_read( write_flags, read_status ) ;
	 end
	 begin
	    musnt_respond(ok) ;
	    if ( ok !== 1 )
	      begin
		 $display("PCI bus error handling testing failed! Test of master abort handling got one target to respond! Time %t ", $time) ;
		 $display("Testbench is configured wrong!") ;
		 test_fail("transaction wasn't initiated by PCI Master state machine or Target responded and Master Abort didn't occur");
	      end
	 end // fork branch
      join
      if ( (read_status`CYC_ACTUAL_TRANSFER !== 0) || (read_status`CYC_ERR !== 1) )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Read terminated with master abort should return zero data and terminate WISHBONE cycle with error!") ;
	   $display("Actuals: Data transfered: %d, slave response: ACK = %b, RTY = %b, ERR = %b ", read_status`CYC_ACTUAL_TRANSFER, read_status`CYC_ACK, read_status`CYC_RTY, read_status`CYC_ERR) ;
	   test_fail("Read terminated with Master Abort didn't return zero data or terminate WISHBONE cycle with error") ;
	   disable main ;
	end // if ( (read_status`CYC_ACTUAL_TRANSFER !== 0) || (read_status`CYC_ERR !== 1) )
      else
	test_ok ;

      test_name = "CHECK PCI DEVICE STATUS REGISTER AFTER READ TERMINATED WITH MASTER ABORT" ;
      ok = 1 ;
      // check PCI status register
      config_read( pci_ctrl_offset, 4'hF, temp_val1 ) ;
      if ( temp_val1[29] !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Master Abort bit was not set when read was terminated with Master Abort!") ;
	   test_fail("Received Master Abort bit was not set when read was terminated with Master Abort") ;
	   ok = 0 ;
	end // if ( temp_val1[29] !== 1 )
      if ( temp_val1[28] !== 0 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Target Abort bit was set for no reason!") ;
	   test_fail("Received Target Abort bit was set for no reason") ;
	   ok = 0 ;
	end // if ( temp_val1[28] !== 0 )
      if ( ok )
	test_ok ;
      config_write( pci_ctrl_offset, temp_val1, 4'b1100, ok ) ;

      // disable error reporting and interrupts
      test_name = "SETUP BRIDGE FOR TARGET ABORT HANDLING TESTS" ;
      configuration_cycle_write(0,                        // bus number
				`TAR1_IDSEL_INDEX - 11,   // device number
				0,                        // function number
				1,                        // register number
				0,                        // type of configuration cycle
				4'b0001,                  // byte enables
				32'h0000_0007             // data
				);
      /* XXX */
      test_target_response[`TARGET_ENCODED_TERMINATION]       = `Test_Target_Abort ;
      test_target_response[`TARGET_ENCODED_TERMINATE_ON]      = 1 ;
      byte_ofs = ({$random} % 4) ;
      write_data`WRITE_ADDRESS = target_address + byte_ofs ;
      write_data`WRITE_DATA    = wmem_data[0] ;
      write_data`WRITE_SEL     = 4'hF ;

      wishbone_master.blk_write_data[0] = write_data ;
      write_data`WRITE_ADDRESS = target_address + 4 + byte_ofs ;
      write_data`WRITE_DATA    = wmem_data[1] ;
      write_data`WRITE_SEL     = 4'hF ;

      wishbone_master.blk_write_data[1] = write_data ;
      write_flags`WB_TRANSFER_SIZE = 2 ;
      // don't handle retries
      write_flags`WB_TRANSFER_AUTO_RTY = 0 ;
      write_flags`WB_TRANSFER_CAB    = 0 ;
      test_name = "TARGET ABORT ERROR ON SINGLE WRITE" ;

      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.block_write(write_flags, write_status) ;
	    /*if ( write_status`CYC_ACTUAL_TRANSFER !== 2 )
              begin
		 $display("PCI bus error handling testing failed! Time %t ", $time) ;
		 $display("Image writes were not accepted as expected!") ;
		 $display("Slave response: ACK = %b, RTY = %b, ERR = %b ", write_status`CYC_ACTUAL_TRANSFER, write_status`CYC_ACK, write_status`CYC_RTY, write_status`CYC_ERR) ;
		 test_fail("WB Slave state machine failed to post two single memory writes")  ;
		 disable main ;
              end*/
	    // read data back to see, if it was written OK
	    read_data`READ_ADDRESS         = target_address + 4  + ({$random} % 4) ;
	    read_data`READ_SEL             = 4'hF ;
	    write_flags`WB_TRANSFER_AUTO_RTY = 1 ;
	    SYSTEM.bridge32_top.master_tb.wb_single_read( read_data, write_flags, read_status );
	 end
	 begin
	    pci_transaction_progress_monitor( target_address, `BC_MEM_WRITE, 0, 0, 1'b1, 1'b0, 0, ok ) ;
	    if ( ok !== 1 )
	      begin
		 test_fail("unexpected transaction or no response detected on PCI bus, when Target Abort during Memory Write was expected") ;
	      end
	    else
	      test_ok ;
	    
	    test_name = "NORMAL SINGLE MEMORY WRITE IMMEDIATELY AFTER ONE TERMINATED WITH TARGET ABORT" ;
	    // when first transaction finishes - enable normal target response!
	    test_target_response[`TARGET_ENCODED_TERMINATION] = `Test_Target_Normal_Completion ;
	    test_target_response[`TARGET_ENCODED_TERMINATE_ON] = 0 ;
	    
	    /*pci_transaction_progress_monitor( target_address + 4, `BC_MEM_WRITE, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    if ( ok !== 1 )
	      begin
		 test_fail("unexpected transaction or no response detected on PCI bus, when single Memory Write was expected") ;
	      end
	    else
	      test_ok ;*/
	    test_name = "NORMAL SINGLE MEMORY READ AFTER WRITE TERMINATED WITH TARGET ABORT" ;
	    pci_transaction_progress_monitor( target_address + 4, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    if ( ok !== 1 )
	      begin
		 test_fail("unexpected transaction or no response detected on PCI bus, when single Memory Read was expected") ;
	      end
	 end // fork branch
      join
      
      if ( read_status`CYC_ACTUAL_TRANSFER !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Bridge failed to process single read after target abort terminated write!") ;
	   test_fail("bridge failed to process single delayed read after target abort terminated write") ;
	   disable main ;
	end // if ( read_status`CYC_ACTUAL_TRANSFER !== 1 )
      
      /*if ( read_status`READ_DATA !== wmem_data[1] )
	begin
	   display_warning( target_address + 4, wmem_data[1], read_status`READ_DATA ) ;
	   test_fail("bridge returned unexpected data on read following Target Abort Terminated write") ;
	end
      else
	test_ok ;*/

    // check PCI status register
      test_name = "PCI DEVICE STATUS REGISTER VALUE CHECK AFTER WRITE TARGET ABORT" ;

      ok = 1 ;

      config_read( pci_ctrl_offset, 4'hF, temp_val1 ) ;
      if ( temp_val1[29] !== 0 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Master Abort bit was set with no reason!") ;
	   test_fail("Received Master Abort bit was set with no reason") ;
	   ok = 0 ;
	end
      if ( temp_val1[28] !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("Received Target Abort bit was not set when write transaction was terminated with target abort!") ;
	   test_fail("Received Target Abort bit was not set when write transaction was terminated with target abort") ;
	   ok = 0 ;
	end
      if ( ok )
	test_ok ;

      /* 
       XXXXX  skip
       */

      $display("***************** DONE testing handling of PCI bus errors **********************") ;
      
// 	 
      //$stop;
	
   end // block: main
endtask // test_pci_master_error_handling

task lg_test_pci_image;
   input [3:0] image;
   begin
      /* XXXX */
   end
endtask // test_pci_image

task lg_test_int;
   begin
      test_name = "CHECKING INTERRUPT REQUESTS AFTER SETTING FLAGS 0" ;
      SYSTEM.bridge32_top.master_tb.set_int(0);
      repeat(4)
	@(posedge pci_clock);
      if ( INTA != 0 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("seting int");
	   test_fail("setting int");
	end
	    else
	test_ok ;
      
      test_name = "CHECKING INTERRUPT REQUESTS AFTER SETTING FLAGS 1" ;
      SYSTEM.bridge32_top.master_tb.set_int(1);
            repeat(4)
	@(posedge pci_clock);
      if ( INTA !== 1 )
	begin
	   $display("PCI bus error handling testing failed! Time %t ", $time) ;
	   $display("clearing int");
	   test_fail("clearing int");
	end
	    else
	test_ok ;

      //$stop;
   end
endtask // lg_test_int

task lg_test_pci;
   begin
      do_reset;

      lg_test_initial_all_conf_values;
      configure_bridge_target ;
      lg_test_int;
      
      next_test_name[79:0] <= "Initing...";
      test_target_response[`TARGET_ENCODED_PARAMATERS_ENABLE] = 1 ;
      for ( wb_init_waits = 0 ; 
	    wb_init_waits <= 4 ; 
	    wb_init_waits = wb_init_waits + 1 ) begin
	 for ( wb_subseq_waits = 0 ;
	       wb_subseq_waits <= 4 ; 
	       wb_subseq_waits = wb_subseq_waits + 1 ) begin
	    pci_init_waits   = wb_init_waits ;
	    pci_subseq_waits = wb_subseq_waits ;
	    test_target_response[`TARGET_ENCODED_INIT_WAITSTATES] = pci_init_waits ;
	    test_target_response[`TARGET_ENCODED_SUBS_WAITSTATES] = pci_subseq_waits ;
	    
	    for ( tb_target_decode_speed = 0 ; 
		  tb_target_decode_speed <= 3 ;
		  tb_target_decode_speed = tb_target_decode_speed + 1 ) begin
	       test_target_response[`TARGET_ENCODED_DEVSEL_SPEED] = tb_target_decode_speed ;
	       
	       @(posedge pci_clock) ;
	       configure_target(1) ;
	       @(posedge pci_clock) ;
	       configure_target(2) ;
	       
	       configure_bridge_target ;
	       next_test_name[79:0] <= "WB_SLAVE..";

	       /* pci master test */
	       test_pci_master;
	       test_pci_master_error_handling;
	       //test_pci_parity_checking;
	       //test_pci_master_transcations;
	       //test_pci_master_overload;

	       $display(" ") ;
	       $display("WB slave images' tests finished!") ;
	       $display("########################################################################") ;
	       $display("########################################################################") ;
	       $display("||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||") ;
	       $display("########################################################################") ;
	       $display("########################################################################") ;
	       
	       $display("Testing PCI target images' features!") ;
	       configure_bridge_target_base_addresses;

	       /* pci target test */
	       lg_test_pci_image(1);
	       
	       /*test_pci_image(2);
	       test_pci_image(3);
	       test_pci_image(4);
	       test_pci_image(5);
	       test_wb_error_rd ;
	       target_fast_back_to_back ;
	       target_disconnects ;
	       test_target_overload ;
	       if ( target_io_image !== -1 )
			     test_target_abort( target_io_image ) ;
	       
	       $display(" ") ;
	       $display("PCI target images' tests finished!") ;
	       transaction_ordering;*/
	    end // for ( tb_target_decode_speed = 0 ;...
	 end // for ( wb_subseq_waits = 0 ;...
      end // for ( wb_init_waits = 0 ;...
      
      wb_init_waits   = 0 ;
      pci_init_waits  = 0 ;
      wb_subseq_waits = 0 ;
      pci_subseq_waits = 0 ;

      test_target_response[`TARGET_ENCODED_PARAMATERS_ENABLE] = 1 ;
      test_target_response[`TARGET_ENCODED_INIT_WAITSTATES] = 0 ;
      test_target_response[`TARGET_ENCODED_SUBS_WAITSTATES] = 0 ;
      test_target_response[`TARGET_ENCODED_DEVSEL_SPEED] = 0 ;

      @(posedge pci_clock) ;
      configure_target(1) ;
      @(posedge pci_clock) ;
      configure_target(2) ;

      configure_bridge_target ;

      test_summary;

      $fclose(wbu_mon_log_file_desc | pciu_mon_log_file_desc | pci_mon_log_file_desc) ;
      $finish;
   end
endtask
