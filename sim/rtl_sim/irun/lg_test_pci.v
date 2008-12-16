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
   begin
   end
endtask // test_pci_master_error_handling

task lg_test_pci;
   begin
      do_reset;

      lg_test_initial_all_conf_values;

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

	       /* wb */
	       test_pci_master;
	       test_pci_master_error_handling; 
	       //test_pci_master_transcations;
	       //test_pci_master_overload;
	       
	       $display("Testing PCI target images' features!") ;
	       configure_bridge_target_base_addresses;

	       /*test_pci_image(1);
	       test_pci_image(2);
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
      
      /* test the pci target mode */
      //lg_test_pci_target;

      /* test the pci master mode */
      //lg_test_pci_master;

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
