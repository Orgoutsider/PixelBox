# ----------------------------------------
# Create compilation libraries
vlib usim
vmap usim "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/usim"
vlib vsim
vmap vsim "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/vsim"
vlib adc
vmap adc "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/adc"
vlib ddrc
vmap ddrc "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ddrc"
vlib ddrphy
vmap ddrphy "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ddrphy"
vlib hsst_e2
vmap hsst_e2 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/hsst_e2"
vlib iolhr_dft
vmap iolhr_dft "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/iolhr_dft"
vlib ipal_e1
vmap ipal_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ipal_e1"
vlib iserdes_e1
vmap iserdes_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/iserdes_e1"
vlib oserdes_e1
vmap oserdes_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/oserdes_e1"
vlib pciegen2
vmap pciegen2 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/pciegen2"


#compile basic library
vlog -incr "D:/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/*.v" -work usim
vlog -incr "D:/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/modelsim10.2c/*.vp" -work usim


#compile basic library
vlog -incr "D:/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/bsim/*.v" -work vsim
vlog -incr "D:/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/bsim/modelsim10.2c/*.vp" -work vsim


#compile common library
cd "D:/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/modelsim10.2c"
vmap adc "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/adc"
vlog -incr -f ./filelist_adc_gtp.f -work adc
vmap ddrc "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ddrc"
vlog -incr -f ./filelist_ddrc_gtp.f -work ddrc -sv -mfcu
vmap ddrphy "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ddrphy"
vlog -incr -f ./filelist_ddrphy_gtp.f -work ddrphy
vmap hsst_e2 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/hsst_e2"
vlog -incr -f ./filelist_hsst_e2_gtp.f -work hsst_e2
vmap iolhr_dft "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/iolhr_dft"
vlog -incr -f ./filelist_iolhr_dft_gtp.f -work iolhr_dft
vmap ipal_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/ipal_e1"
vlog -incr -f ./filelist_ipal_e1_gtp.f -work ipal_e1
vmap iserdes_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/iserdes_e1"
vlog -incr -f ./filelist_iserdes_e1_gtp.f -work iserdes_e1
vmap oserdes_e1 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/oserdes_e1"
vlog -incr -f ./filelist_oserdes_e1_gtp.f -work oserdes_e1
vmap pciegen2 "D:/WorkSpace/Project/PangoFPGA/pixel-box/compile/pciegen2"
vlog -incr -f ./filelist_pciegen2_gtp.f -work pciegen2 -sv -mfcu

quit -force

# ----------------------------------------
