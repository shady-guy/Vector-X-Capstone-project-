transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv "Vector Simulation/vector_pkg.sv"
vlog -sv "Vector Simulation/vector_config.sv"
vlog -sv "Vector Simulation/vector_register_file.sv"
vlog -sv "Vector Simulation/vector_alu.sv"
vlog -sv "Vector Simulation/vector_lsu.sv"
vlog -sv "Vector Simulation/vector_controller.sv"
vlog -sv "Vector Simulation/vector_datapath.sv"
vlog -sv "Vector Simulation/vector_top.sv"
vlog -sv "Vector Simulation/vector_tb.sv"
vlog -sv "Vector Simulation/vector_tb_ext.sv"

vsim -t 1ns work.vector_tb_ext
onfinish stop

# Wave setup
quietly WaveActivateNextPane {} 0
radix hexadecimal

add wave -divider {TB Clock/Reset}
add wave sim:/vector_tb_ext/clk
add wave sim:/vector_tb_ext/rst

add wave -divider {Top-Level Memory Interface}
add wave sim:/vector_tb_ext/t_mem_addr
add wave sim:/vector_tb_ext/t_mem_req
add wave sim:/vector_tb_ext/t_mem_read
add wave sim:/vector_tb_ext/t_mem_write
add wave sim:/vector_tb_ext/t_mem_wdata
add wave sim:/vector_tb_ext/t_mem_valid
add wave sim:/vector_tb_ext/t_mem_rdata
add wave sim:/vector_tb_ext/t_lsu_done

add wave -divider {Top Control Path}
add wave sim:/vector_tb_ext/dut_top/pc
add wave sim:/vector_tb_ext/dut_top/instruction
add wave sim:/vector_tb_ext/dut_top/instr_hold
add wave sim:/vector_tb_ext/dut_top/instr_to_exec
add wave sim:/vector_tb_ext/dut_top/hold_valid
add wave sim:/vector_tb_ext/dut_top/vec_busy
add wave sim:/vector_tb_ext/dut_top/regwrite
add wave sim:/vector_tb_ext/dut_top/alu_op
add wave sim:/vector_tb_ext/dut_top/lsu_op
add wave sim:/vector_tb_ext/dut_top/mode
add wave sim:/vector_tb_ext/dut_top/lsu_en
add wave sim:/vector_tb_ext/dut_top/memtoreg

add wave -divider {Datapath Core}
add wave sim:/vector_tb_ext/dut_top/dp/rd
add wave sim:/vector_tb_ext/dut_top/dp/rs1
add wave sim:/vector_tb_ext/dut_top/dp/rs2
add wave sim:/vector_tb_ext/dut_top/dp/vl
add wave sim:/vector_tb_ext/dut_top/dp/sew
add wave sim:/vector_tb_ext/dut_top/dp/vsew
add wave sim:/vector_tb_ext/dut_top/dp/vma
add wave sim:/vector_tb_ext/dut_top/dp/vta
add wave sim:/vector_tb_ext/dut_top/dp/vl_lanes
add wave sim:/vector_tb_ext/dut_top/dp/read_data1
add wave sim:/vector_tb_ext/dut_top/dp/read_data2
add wave sim:/vector_tb_ext/dut_top/dp/vd_old
add wave sim:/vector_tb_ext/dut_top/dp/mask_reg
add wave sim:/vector_tb_ext/dut_top/dp/alu_result
add wave sim:/vector_tb_ext/dut_top/dp/load_data
add wave sim:/vector_tb_ext/dut_top/dp/write_data
add wave sim:/vector_tb_ext/dut_top/dp/regwrite_final
add wave sim:/vector_tb_ext/dut_top/dp/is_load

add wave -divider {Top LSU Internals}
add wave sim:/vector_tb_ext/dut_top/dp/lsu/state
add wave sim:/vector_tb_ext/dut_top/dp/lsu/nstate
add wave sim:/vector_tb_ext/dut_top/dp/lsu/start
add wave sim:/vector_tb_ext/dut_top/dp/lsu/elem_idx
add wave sim:/vector_tb_ext/dut_top/dp/lsu/SHIFT
add wave sim:/vector_tb_ext/dut_top/dp/lsu/elem_shift
add wave sim:/vector_tb_ext/dut_top/dp/lsu/addr
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_req
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_read
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_write
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_addr
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_wdata
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_valid
add wave sim:/vector_tb_ext/dut_top/dp/lsu/mem_rdata
add wave sim:/vector_tb_ext/dut_top/dp/lsu/done

add wave -divider {Direct LSU TB Instance}
add wave sim:/vector_tb_ext/lsu_op
add wave sim:/vector_tb_ext/lsu_mode
add wave sim:/vector_tb_ext/lsu_vl
add wave sim:/vector_tb_ext/lsu_base
add wave sim:/vector_tb_ext/lsu_stride
add wave sim:/vector_tb_ext/lsu_index
add wave sim:/vector_tb_ext/lsu_sdata
add wave sim:/vector_tb_ext/lsu_ldata
add wave sim:/vector_tb_ext/lsu_maddr
add wave sim:/vector_tb_ext/lsu_mreq
add wave sim:/vector_tb_ext/lsu_mread
add wave sim:/vector_tb_ext/lsu_mwrite
add wave sim:/vector_tb_ext/lsu_mwdata
add wave sim:/vector_tb_ext/lsu_mrdata
add wave sim:/vector_tb_ext/lsu_mvalid
add wave sim:/vector_tb_ext/t_lsu_done
add wave sim:/vector_tb_ext/dut_lsu/state
add wave sim:/vector_tb_ext/dut_lsu/elem_idx
add wave sim:/vector_tb_ext/dut_lsu/addr
add wave sim:/vector_tb_ext/dut_lsu/load_data

add wave -divider {ALU Output Registers (quick check)}
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(3)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(4)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(5)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(6)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(7)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(8)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(9)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(10)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(11)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(12)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(13)
add wave sim:/vector_tb_ext/dut_top/dp/vrf/vrf(14)

add wave -divider {Config/Policy}
add wave sim:/vector_tb_ext/dut_top/dp/cfg_unit/vtype_reg
add wave sim:/vector_tb_ext/dut_top/dp/cfg_unit/vl_reg
add wave sim:/vector_tb_ext/dut_top/dp/cfg_unit/vl
add wave sim:/vector_tb_ext/dut_top/dp/cfg_unit/lane_active

configure wave -namecolwidth 280
configure wave -valuecolwidth 120
configure wave -timelineunits ns
update

run -all
echo "Simulation reached finish/stop. ModelSim stays open for debug."
