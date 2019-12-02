# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Fri Nov 29 20:06:35 2019
# Designs open: 1
#   Sim: tb_sblk_row_simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: tb_sblk_row.u_sblk_row.u_sblk_ctrl
#   Wave.1: 50 signals
#   Group count = 7
#   Group Group1 signal count = 3
#   Group SBLK 0 signal count = 23
#   Group TPE 0 signal count = 6
#   Group TPE 1 signal count = 6
#   Group TPE 2 signal count = 6
#   Group TPE 3 signal count = 6
#   Group Group11 signal count = 0
# End_DVE_Session_Save_Info

# DVE version: O-2018.09-SP2_Full64
# DVE build date: Feb 28 2019 23:39:41


#<Session mode="Full" path="/home/yhding/code/ftdnn/hw/rtl/tb/tb_sblk_row.tcl" type="Debug">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Helvetica,10,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE top-level session


# Create and position top-level window: TopLevel.1

if {![gui_exist_window -window TopLevel.1]} {
    set TopLevel.1 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.1 TopLevel.1
}
gui_show_window -window ${TopLevel.1} -show_state maximized -rect {{2 51} {1921 1054}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 249]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 249
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 248} {height 727} {dock_state left} {dock_on_new_line true} {child_hier_colhier 186} {child_hier_coltype 100} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 479]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 479
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 725
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 478} {height 727} {dock_state left} {dock_on_new_line true} {child_data_colvariable 267} {child_data_colvalue 103} {child_data_coltype 107} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 170]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value -1
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 170
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 295} {height 169} {dock_state bottom} {dock_on_new_line true}}
set DriverLoad.1 [gui_create_window -type DriverLoad -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line false -dock_extent 170]
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_width -value_type integer -value 150
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_height -value_type integer -value 170
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DriverLoad.1} {{left 0} {top 0} {width 1623} {height 169} {dock_state bottom} {dock_on_new_line false}}
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size
gui_sync_global -id ${TopLevel.1} -option true

# MDI window settings
set Source.1 [gui_create_window -type {Source}  -parent ${TopLevel.1}]
gui_show_window -window ${Source.1} -show_state maximized
gui_update_layout -id ${Source.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false}}

# End MDI window settings


# Create and position top-level window: TopLevel.2

if {![gui_exist_window -window TopLevel.2]} {
    set TopLevel.2 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.2 TopLevel.2
}
gui_show_window -window ${TopLevel.2} -show_state maximized -rect {{16 51} {1935 1054}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
gui_sync_global -id ${TopLevel.2} -option true

# MDI window settings
set Wave.1 [gui_create_window -type {Wave}  -parent ${TopLevel.2}]
gui_show_window -window ${Wave.1} -show_state maximized
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 551} {child_wave_right 1363} {child_wave_colname 245} {child_wave_colvalue 302} {child_wave_col1 0} {child_wave_col2 1}}

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(Source) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Schematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(PathSchematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Wave) none
gui_set_env TOPLEVELS::TARGET_FRAME(List) none
gui_set_env TOPLEVELS::TARGET_FRAME(Memory) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(DriverLoad) none
gui_update_statusbar_target_frame ${TopLevel.1}
gui_update_statusbar_target_frame ${TopLevel.2}

#</WindowLayout>

#<Database>

# DVE Open design session: 

if { [llength [lindex [gui_get_db -design Sim] 0]] == 0 } {
gui_set_env SIMSETUP::SIMARGS {{-ucligui -licqueue -l simulate.log -do tb_sblk_row_simulate.do}}
gui_set_env SIMSETUP::SIMEXE {tb_sblk_row_simv}
gui_set_env SIMSETUP::ALLOW_POLL {0}
if { ![gui_is_db_opened -db {tb_sblk_row_simv}] } {
gui_sim_run Ucli -exe tb_sblk_row_simv -args {-ucligui -licqueue -l simulate.log -do tb_sblk_row_simulate.do} -dir ../vcs -nosource
}
}
if { ![gui_sim_state -check active] } {error "Simulator did not start correctly" error}
gui_set_precision 1ps
gui_set_time_units 1ns
#</Database>

# DVE Global setting session: 


# Global: Breakpoints

# Global: Bus

# Global: Expressions

# Global: Signal Time Shift
gui_shift_signal_create -signals { {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data} } -offset 4000 -unit 1ps
gui_shift_signal_create -signals { {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data} } -offset 4e+07 -unit 1ps
gui_shift_signal_create -signals { {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data} } -offset 40000 -unit 1ps
gui_shift_signal_create -signals { {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_out} } -offset 4e+07 -unit 1ps

# Global: Signal Compare
gui_compare_create {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_out->>4e+07} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_casout[47:0]}
gui_compare_set_option -name {Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_out->>4e+07<>Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_casout[47:0]} -ignore {none} -timeUnit 1ps -tolerance 0 -typesOfSignal {{in} {out} {inout} {signal} } -mismatch_per_signal 100 -mismatch_total 1000 -recompare {true}
gui_compare_create {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data[63:0]} {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data->>4000}
gui_compare_set_option -name {Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data[63:0]<>Sim:tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data->>4000} -ignore {none} -timeUnit 1ps -tolerance 0 -typesOfSignal {{in} {out} {inout} {signal} } -mismatch_per_signal 100 -mismatch_total 1000 -recompare {true}
gui_compare_create {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data->>40000} {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]}
gui_compare_set_option -name {Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data->>40000<>Sim:tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]} -ignore {none} -timeUnit 1ps -tolerance 0 -typesOfSignal {{in} {out} {inout} {signal} } -mismatch_per_signal 100 -mismatch_total 1000 -recompare {true}
gui_compare_create {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data->>4e+07} {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]}
gui_compare_set_option -name {Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data->>4e+07<>Sim:tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]} -ignore {none} -timeUnit 1ps -tolerance 0 -typesOfSignal {{in} {out} {inout} {signal} } -mismatch_per_signal 100 -mismatch_total 1000 -recompare {true}
gui_compare_create {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data[63:0]} {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]}
gui_compare_set_option -name {Sim:tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data[63:0]<>Sim:tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_data[63:0]} -ignore {none} -timeUnit 1ps -tolerance 0 -typesOfSignal {{in} {out} {inout} {signal} } -mismatch_per_signal 100 -mismatch_total 1000 -recompare {true}

# Global: Signal Groups
gui_load_child_values {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile}
gui_load_child_values {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile}
gui_load_child_values {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile}
gui_load_child_values {tb_sblk_row}
gui_load_child_values {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile}
gui_load_child_values {tb_sblk_row.u_sblk_row.u_sblk_unit_start}


set _session_group_1 Group1
gui_sg_create "$_session_group_1"
set Group1 "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { tb_sblk_row.clk_l tb_sblk_row.clk_h tb_sblk_row.rst_n }

set _session_group_2 {SBLK 0}
gui_sg_create "$_session_group_2"
set {SBLK 0} "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_wr_en tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_wr_addr_hbit tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_data_in tb_sblk_row.u_sblk_row.u_sblk_unit_start.w_rd_addr tb_sblk_row.act_data_in_req tb_sblk_row.status_sblk tb_sblk_row.u_sblk_row.u_sblk_ctrl.inst_en tb_sblk_row.u_sblk_row.u_sblk_ctrl.trip_finish tb_sblk_row.u_sblk_row.u_sblk_ctrl.inst_finish tb_sblk_row.u_sblk_row.u_sblk_ctrl.comp_flag tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_tp tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_tm tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_tn tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_ln tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_lp tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_wr_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_wr_en tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_wr_data tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_wr_d tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_rd_addr_hbit tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_rd_data }

set _session_group_3 {TPE 0}
gui_sg_create "$_session_group_3"
set {TPE 0} "$_session_group_3"

gui_sg_addsignal -group "$_session_group_3" { tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.w_rd_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.act_rd_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.w_rd_data_d tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.act_rd_data_d tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_sumin tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.p_casout }

set _session_group_4 {TPE 1}
gui_sg_create "$_session_group_4"
set {TPE 1} "$_session_group_4"

gui_sg_addsignal -group "$_session_group_4" { {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.w_rd_addr} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.act_rd_addr} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.w_rd_data_d} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.act_rd_data_d} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.p_casin} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.p_casout} }

set _session_group_5 {TPE 2}
gui_sg_create "$_session_group_5"
set {TPE 2} "$_session_group_5"

gui_sg_addsignal -group "$_session_group_5" { {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.w_rd_addr} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.act_rd_addr} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.w_rd_data_d} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.act_rd_data_d} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.p_casin} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.p_casout} }

set _session_group_6 {TPE 3}
gui_sg_create "$_session_group_6"
set {TPE 3} "$_session_group_6"

gui_sg_addsignal -group "$_session_group_6" { tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.w_rd_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.act_rd_addr tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.w_rd_data_d tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.act_rd_data_d tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.p_casin tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.p_out }

set _session_group_7 Group11
gui_sg_create "$_session_group_7"
set Group11 "$_session_group_7"


# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 384



# Save global setting...

# Wave/List view global setting
gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 


# Hier 'Hier.1'
gui_show_window -window ${Hier.1}
gui_list_set_filter -id ${Hier.1} -list { {Package 1} {All 0} {Process 1} {VirtPowSwitch 0} {UnnamedProcess 1} {UDP 0} {Function 1} {Block 1} {SrsnAndSpaCell 0} {OVA Unit 1} {LeafScCell 1} {LeafVlgCell 1} {Interface 1} {LeafVhdCell 1} {$unit 1} {NamedBlock 1} {Task 1} {VlgPackage 1} {ClassDef 1} {VirtIsoCell 0} }
gui_list_set_filter -id ${Hier.1} -text {*}
gui_hier_list_init -id ${Hier.1}
gui_change_design -id ${Hier.1} -design Sim
catch {gui_list_expand -id ${Hier.1} tb_sblk_row}
catch {gui_list_expand -id ${Hier.1} tb_sblk_row.u_sblk_row}
catch {gui_list_select -id ${Hier.1} {tb_sblk_row.u_sblk_row.u_sblk_ctrl}}
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {tb_sblk_row.u_sblk_row.u_sblk_ctrl}
gui_show_window -window ${Data.1}
catch { gui_list_select -id ${Data.1} {tb_sblk_row.u_sblk_row.u_sblk_ctrl.n_ln }}
gui_view_scroll -id ${Data.1} -vertical -set 240
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# DriverLoad 'DriverLoad.1'
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_data_in[31:0]} -time 190 -starttime 192
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_unit[1].u_sblk_unit.psum_rd_addr[8:0]} -time 6 -starttime 180.768
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_rd_addr_hbit[4:0]} -time 6 -starttime 240.102
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_tp[1:0]} -time 6 -starttime 240.102
gui_get_drivers -session -id ${DriverLoad.1} -signal tb_sblk_row.u_sblk_row.u_sblk_ctrl.comp_flag -time 240 -starttime 240.102
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_rd_addr_hbit[4:0]} -time 6 -starttime 240
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_ctrl.cnt_tp[1:0]} -time 6 -starttime 240
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_ctrl.n_tp[1:0]} -time 160 -starttime 240
gui_get_drivers -session -id ${DriverLoad.1} -signal {tb_sblk_row.u_sblk_row.u_sblk_unit_start.psum_wr_addr[8:0]} -time 6 -starttime 272

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active tb_sblk_row.u_sblk_row.u_sblk_ctrl /home/yhding/code/ftdnn/hw/rtl/syn/sblk_ctrl.sv
gui_view_scroll -id ${Source.1} -vertical -set 32
gui_src_set_reusable -id ${Source.1}

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_create -id ${Wave.1} DSP0 384
gui_marker_create -id ${Wave.1} DSP1 386
gui_marker_create -id ${Wave.1} DSP2 388
gui_marker_create -id ${Wave.1} DSP3 390
gui_marker_create -id ${Wave.1} OUT 396
gui_marker_create -id ${Wave.1} DSP0_1 456
gui_marker_create -id ${Wave.1} DSP1_1 458
gui_marker_create -id ${Wave.1} DSP2_1 460
gui_marker_create -id ${Wave.1} DSP3_1 462
gui_marker_create -id ${Wave.1} OUT_1 468
gui_marker_select -id ${Wave.1} {  DSP0 }
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 362.861 475.173
gui_list_add_group -id ${Wave.1} -after {New Group} {Group1}
gui_list_add_group -id ${Wave.1} -after {New Group} {{SBLK 0}}
gui_list_add_group -id ${Wave.1} -after {New Group} {{TPE 0}}
gui_list_add_group -id ${Wave.1} -after {New Group} {{TPE 1}}
gui_list_add_group -id ${Wave.1} -after {New Group} {{TPE 2}}
gui_list_add_group -id ${Wave.1} -after {New Group} {{TPE 3}}
gui_list_add_group -id ${Wave.1} -after {New Group} {Group11}
gui_list_select -id ${Wave.1} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_start_stile.act_rd_data_d {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[1].u_mid_stile.act_rd_data_d} {tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_mid_tile[2].u_mid_stile.act_rd_data_d} tb_sblk_row.u_sblk_row.u_sblk_unit_start.u_end_stile.act_rd_data_d }
gui_seek_criteria -id ${Wave.1} {Any Edge}



gui_set_env TOGGLE::DEFAULT_WAVE_WINDOW ${Wave.1}
gui_set_pref_value -category Wave -key exclusiveSG -value $groupExD
gui_list_set_height -id Wave -height $origWaveHeight
if {$origGroupCreationState} {
	gui_list_create_group_when_add -wave -enable
}
if { $groupExD } {
 gui_msg_report -code DVWW028
}
gui_list_set_filter -id ${Wave.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Wave.1} -text {*}
gui_list_set_insertion_bar  -id ${Wave.1} -group {SBLK 0}  -item {tb_sblk_row.u_sblk_row.u_sblk_unit_start.act_rd_addr_hbit[4:0]} -position below

gui_marker_move -id ${Wave.1} {C1} 384
gui_view_scroll -id ${Wave.1} -vertical -set 450
gui_show_grid -id ${Wave.1} -enable false
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${DLPane.1}
}
if {[gui_exist_window -window ${TopLevel.2}]} {
	gui_set_active_window -window ${TopLevel.2}
	gui_set_active_window -window ${Wave.1}
}
#</Session>

