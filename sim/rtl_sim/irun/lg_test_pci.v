task lg_test_pci_configuration;
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
			," expected:%h ",header_value[reg_address]," read:%h",read_data," Time %t ", $time) ;
	       test_fail("Initial value of register not as expected") ;
	       failed = 1 ;
	    end // if ( read_data !== header_value[reg_address])
	    reg_address= reg_address+1;
	 end // while (reg_address <= 'd16)
	 
      end
      
   end
endtask // lg_test_pci_configuration

task lg_test_pci_master ;
   reg [31:0] pci_address;
   reg 	      ok;
   begin
      repeat( 10 )
	@(posedge pci_clock) ;
      
      $display ("master test");
      
      pci_address = 32'hC000_0000;
      
      fork 
	 begin
	    SYSTEM.bridge32_top.master_tb.start_enable(0, pci_address);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ; 
	    @(posedge pci_clock) ;
	 end
      join
      
      repeat( 2 )
	@(posedge pci_clock) ;
      
      fork 
	 begin
	    SYSTEM.bridge32_top.master_tb.start_enable(1, pci_address);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_WRITE, 1, 0, 1'b1, 1'b0, 0, ok ) ; 
	    @(posedge pci_clock) ;
	 end
      join
      
      repeat( 2 )
	@(posedge pci_clock) ;
   end
endtask

task lg_test_pci_target ;
   reg   [11:0] offset;
   reg [31:0] 	data;
   reg [31:0] 	read_data;
   reg [31:0] 	expected_value;
   reg [PCI_BUS_DATA_RANGE:0] pci_address;
   reg [PCI_BUS_CBE_RANGE:0]  byte_enables_l; // active LOW
   reg 			      ok, failed;
   begin
      SYSTEM.bridge32_top.mem_target.q = 32'h0123_4567;
      $display(" ");
      $display("########################################################################") ;
      configuration_cycle_read(8'h00,         /* bus number */
			       `TAR0_IDSEL_INDEX - 11, /* device number */
			       0,                      /* function */
			       8'h00,                  /* register */
			       0,                      /* type */
			       4'hF,                   /* byte enable */
			       data);
      expected_value = 32'h1234_5678;
      configuration_cycle_write(8'h00,        /* bus number */
				`TAR0_IDSEL_INDEX - 11, /* device number */
				0,                      /* function */
				8'h20,                  /* register */
				0,                      /* type */
				4'hF,                   /* byte enable */
				expected_value);
      configuration_cycle_read(8'h00,         /* bus number */
			       `TAR0_IDSEL_INDEX - 11, /* device number */
			       0,                      /* function */
			       8'h20,                  /* register */
			       0,                      /* type */
			       4'hF,                   /* byte enable */
			       read_data);
      if( read_data !== expected_value)
	begin
           test_fail("initial value of BAR0 register(8'h20) not as expected") ;
           failed = 1 ;
	end
      
      @(posedge pci_clock) ;
      configure_target(1);
      @(posedge pci_clock) ;
      //configure_target(2);
      configure_bridge_target_base_addresses;
      @(posedge pci_clock) ;
      
      $display(" ");
      $display("########################################################################") ;
      $display("LG test PCI");
      test_name = "PCI IMAGE SETTINGS" ;
      offset = 12'h0;
      data   = 32'h12153524;
      byte_enables_l = ~4'hF;
      
      /* reading bar0 with register 0 */
      pci_address = Target_Base_Addr_R[0] | { 20'h0, 12'h0} ;
      fork 
	 begin
	    DO_REF ("MEM_R_CONF", `Test_Master_2, pci_address[PCI_BUS_DATA_RANGE:0],
                    PCI_COMMAND_MEMORY_READ, data[PCI_BUS_DATA_RANGE:0],
                    byte_enables_l[PCI_BUS_CBE_RANGE:0],
                    `Test_One_Word, `Test_No_Addr_Perr, `Test_No_Data_Perr,
                    8'h0_0, `Test_One_Zero_Target_WS,
                    `Test_Devsel_Medium, `Test_No_Fast_B2B,
                    `Test_Target_Normal_Completion, `Test_Expect_No_Master_Abort);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    @(posedge pci_clock) ;
	 end
      join
      repeat( 2 )
	@(posedge wb_clock) ;
      
      pci_address = Target_Base_Addr_R[2] | { 20'h0, 12'h00} ;
      fork 
	 begin
	    DO_REF ("MEM_R_MEM", `Test_Master_2, pci_address[PCI_BUS_DATA_RANGE:0],
                    PCI_COMMAND_MEMORY_READ, data[PCI_BUS_DATA_RANGE:0],
                    byte_enables_l[PCI_BUS_CBE_RANGE:0],
                    `Test_One_Word, `Test_No_Addr_Perr, `Test_No_Data_Perr,
                    8'h0_0, `Test_One_Zero_Target_WS,
                    `Test_Devsel_Medium, `Test_No_Fast_B2B,
                    `Test_Target_Normal_Completion, `Test_Expect_No_Master_Abort);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    @(posedge pci_clock) ;
	 end
      join
      repeat( 2 )
	@(posedge wb_clock) ;
      
      pci_address = Target_Base_Addr_R[2] | { 20'h0, 12'h00} ;
      fork 
	 begin
	    DO_REF ("MEM_W_MEM", `Test_Master_2, pci_address[PCI_BUS_DATA_RANGE:0],
                    PCI_COMMAND_MEMORY_WRITE, data[PCI_BUS_DATA_RANGE:0],
                    byte_enables_l[PCI_BUS_CBE_RANGE:0],
                    `Test_One_Word, `Test_No_Addr_Perr, `Test_No_Data_Perr,
                    8'h0_0, `Test_One_Zero_Target_WS,
                    `Test_Devsel_Medium, `Test_No_Fast_B2B,
                    `Test_Target_Normal_Completion, `Test_Expect_No_Master_Abort);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_WRITE, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    @(posedge pci_clock) ;
	 end
      join
      repeat( 2 )
	@(posedge wb_clock) ;
      
      pci_address = Target_Base_Addr_R[2] | { 20'h0, 12'h00} ;
      fork 
	 begin
	    DO_REF ("MEM_R_MEM", `Test_Master_2, pci_address[PCI_BUS_DATA_RANGE:0],
                    PCI_COMMAND_MEMORY_READ, data[PCI_BUS_DATA_RANGE:0],
                    byte_enables_l[PCI_BUS_CBE_RANGE:0],
                    `Test_One_Word, `Test_No_Addr_Perr, `Test_No_Data_Perr,
                    8'h0_0, `Test_One_Zero_Target_WS,
                    `Test_Devsel_Medium, `Test_No_Fast_B2B,
                    `Test_Target_Normal_Completion, `Test_Expect_No_Master_Abort);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    @(posedge pci_clock) ;
	 end
      join
      repeat( 2 )
	@(posedge wb_clock) ;
      
      pci_address = 32'hc000_0000;
      fork 
	 begin
	    DO_REF ("MEM_R_MEM", `Test_Master_2, pci_address[PCI_BUS_DATA_RANGE:0],
                    PCI_COMMAND_MEMORY_READ, data[PCI_BUS_DATA_RANGE:0],
                    byte_enables_l[PCI_BUS_CBE_RANGE:0],
                    `Test_One_Word, `Test_No_Addr_Perr, `Test_No_Data_Perr,
                    8'h0_0, `Test_One_Zero_Target_WS,
                    `Test_Devsel_Medium, `Test_No_Fast_B2B,
                    `Test_Target_Normal_Completion, `Test_Expect_No_Master_Abort);
	    do_pause( 1 ) ;
	 end
	 begin
	    pci_transaction_progress_monitor( pci_address, `BC_MEM_READ, 1, 0, 1'b1, 1'b0, 0, ok ) ;
	    @(posedge pci_clock) ;
	 end
      join
      repeat( 2 )
	@(posedge wb_clock) ;
      
   end
endtask

task lg_test_pci;
   begin
      $dumpfile("pci.vcd");
      $dumpvars(0, SYSTEM.bridge32_top);

      /* test the pci configuration */
      lg_test_pci_configuration;
      
      /* test the pci target mode */
      //lg_test_pci_target;

      /* test the pci master mode */
      //lg_test_pci_master;
   end
endtask
