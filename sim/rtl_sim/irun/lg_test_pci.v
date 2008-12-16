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
   reg [31:0] read_data;
   begin : main
      target_address = `BEH_TAR1_MEM_START ;

      fork
	 begin
	    SYSTEM.bridge32_top.master_tb.single_write(target_address,
						       wmem_data[0],
						       write_status,
						       wb_init_waits);
	    
	    test_name = "NORMAL SINGLE MEMORY WRITE THROUGH LBUS IMAGE TO PCI" ;
	    if (write_status `CYC_ACTUAL_TRANSFER != 1) begin
	       $display("Image testing failed! Bridge failed to process single memory write! Time %t ",
			$time);
	       test_fail("LBUS Slave state machine failed to post single memory write");
	    end

	    SYSTEM.bridge32_top.master_tb.single_read(target_address,
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

      $stop;
      
   end
endtask // test_pci_master

task lg_test_pci;
   begin
      $dumpfile("pci.vcd");
      $dumpvars(0, SYSTEM.bridge32_top);

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
