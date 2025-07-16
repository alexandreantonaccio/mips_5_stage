transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/mips_5_stage.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/hazardunit.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/controller.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/maindec.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/aludec.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/regfile.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/alu.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/dmem.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/flopr.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/mux2.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/mux3.sv}
vlog -sv -work work +incdir+C:/Users/alexa/Documents/GitHub/mips_5_stage {C:/Users/alexa/Documents/GitHub/mips_5_stage/imem.sv}

