#!/bin/sh

iverilog -o tb `cat ../bin/rtl_file_list.lst ../bin/sim_file_list.lst ` -I ../../../rtl/verilog/ -I ../../../bench/verilog/ -s SYSTEM
