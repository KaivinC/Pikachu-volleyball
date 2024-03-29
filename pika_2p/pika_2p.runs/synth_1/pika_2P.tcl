# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_param chipscope.maxJobs 1
create_project -in_memory -part xc7a12ticsg325-1L

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.cache/wt [current_project]
set_property parent.project_path D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo d:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_mem {
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/toright.mem
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/background.mem
}
read_verilog -library xil_defaultlib {
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/clk_divider.v
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/sram.v
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/sram_ball.v
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/sram_pika2.v
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/vga_sync.v
  D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/sources_1/new/pika_2P.v
}
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/constrs_1/lab10.xdc
set_property used_in_implementation false [get_files D:/GoogleDrive/Sophomore/DLAB/Pika/pika_2p/pika_2p.srcs/constrs_1/lab10.xdc]

set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top pika_2P -part xc7a12ticsg325-1L


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef pika_2P.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file pika_2P_utilization_synth.rpt -pb pika_2P_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
