
set HW_D1 4     ;# intra-SBLK
set HW_D2 5     ;# SBLK column
set HW_D3 10    ;# SBLK row

# launch_runs synth_1 -jobs 32
# open_run synth_1

# get_property INIT_00 [get_cells sblk_col[0]*/tpe[0]*/RAMB18E2_inst]

set idx_d3 0
for {set idx_d2 0} {$idx_d2 < $HW_D2} {incr idx_d2} {
    for {set idx_d1 0} {$idx_d1 < $HW_D1} {incr idx_d1} {
        # set mem file name
        set file_name wbuf_$idx_d3\_$idx_d2\_$idx_d1\.dat
        puts $file_name
        # set cell name from finding
        set cell_name [get_cells sblk_col[$idx_d2]*/tpe[$idx_d1]*/RAMB18E2_inst]
        # open mem file
        set fileID [open ../mem/$file_name r]
        for {set xx 0} {$xx < 64} {incr xx} {
            # set property name
            set prop_name "INIT_[format "%02x" $xx]"
            # set property value as one line from file
            set prop_val [gets $fileID]
            # set to correspoding property
            set_property $prop_name $prop_val [get_cells $cell_name]
            # test if set right
            set rd_val [get_property $prop_name [get_cells $cell_name]]
            set rd_val [string range $rd_val 5 5+64]    ;# remove 256'h prefix
            if {$prop_val != $rd_val} {
                puts [format "Error at %s" $prop_name]
                puts $prop_val
                puts $rd_val
            }
        }
        close $fileID
    }
}

# clear wbuf_init.sdc file
# set fileID [open ../const/wbuf_init.sdc w]
# close $fileID

# set target constraint file
# set_property target_constrs_file ../const/wbuf_init.sdc [current_fileset -constrset]

# write new constraints into target file
# save_constraints

# set target to empty
# set_property target_constrs_file "" [current_fileset -constrset]

# refresh the whole design to update files
# refresh_design