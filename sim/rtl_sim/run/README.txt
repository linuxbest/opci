How to run PCI Bridge simulation:
You have to have ncsim simulator available to run pci simulation.
Simulation is started by invoking the script run_pci_sim.scr in this directory.
It can take one argument as an option: xilinx or artisan.
If you want to run the simulation using xilinx RAM primitives, you have to provide glbl.v primitive with
path relative to this directory: ../../../../lib/xilinx/lib/glbl/glbl.v and
RAM primitives with following paths relative to this directory:
../../../../lib/xilinx/lib/unisims/RAMB4_S16_S16.v and
../../../../lib/xilinx/lib/unisims/RAM16X1D.v

Regression tests are still in preparation! 
