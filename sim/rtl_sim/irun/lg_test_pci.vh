task lg_test_pci_master ;
    reg [31:0] pci_address;
    reg ok;
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
    reg   [31:0] data;
    reg   [31:0] read_data;
    reg   [31:0] expected_value;
    reg   [PCI_BUS_DATA_RANGE:0] pci_address;
    reg   [PCI_BUS_CBE_RANGE:0]  byte_enables_l; // active LOW
    reg   ok, failed;
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

