@echo off
set path=c:\tools\ghdl\bin
ghdl -a --ieee=synopsys nut_MemModule_64.vhdl
if errorlevel == 1 goto error
ghdl -a --ieee=synopsys nut_Disassembler.vhdl
if errorlevel == 1 goto error
ghdl -a --ieee=synopsys nut_LCDDriver_DOGM132.vhdl
if errorlevel == 1 goto error
ghdl -a --ieee=synopsys rom41c.vhdl
if errorlevel == 1 goto error
ghdl -a --ieee=synopsys FUllNut.vhdl
if errorlevel == 1 goto error
ghdl -a --ieee=synopsys FUllNut_tb.vhdl
if errorlevel == 1 goto error
ghdl -e --ieee=synopsys FUllNut_tb
if errorlevel == 1 goto error
ghdl -r --ieee=synopsys FUllNut_tb --vcd=FUllNut_tb.vcd --stop-time=200ms
:error
