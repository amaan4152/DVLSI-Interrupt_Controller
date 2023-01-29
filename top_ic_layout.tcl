# Define libraries
source icc2_common_setup.tcl
set_app_var search_path [concat $search_path $ADDITIONAL_SEARCH_PATHS]

# Set the target libraries
#set_app_var target_library "$TARGET_LIB"
set_app_var link_library "* $TARGET_LIB"

# Create a MW design lib and attach the reference lib and techfiles
if {[file isdirectory $DESIGN_LIB_NAME]} {
   file delete -force $DESIGN_LIB_NAME
}
create_lib $DESIGN_LIB_NAME -ref_libs $REFERENCE_LIBS -tech $TECHFILE_PATH/$TECHFILE

open_lib $DESIGN_LIB_NAME

# Read Verilog netlist files. Design name is set to top module name
read_verilog $VERILOG_FILE -top INTR_CTRL

# Set up parasitic model files in TLUPlus format
read_parasitic_tech -tlup $TLUPLUS_PATH/$MAX_TLUPLUS_FILE -layermap $TLUPLUS_PATH/$TECH2ITF_MAP_FILE
read_parasitic_tech -tlup $TLUPLUS_PATH/$MIN_TLUPLUS_FILE -layermap $TLUPLUS_PATH/$TECH2ITF_MAP_FILE

# Read sdc file
read_sdc /afs/ee.cooper.edu/user/a/amaan.rahman/ECE447-DVLSI/intr_ctrl/results/INTR_CTRL.sdc

# Initial floorplanning
initialize_floorplan -core_utilization 0.5 -core_offset {7}

# Save design
save_lib
get_ports *

# Set contraints for pins. Refer set_individual_pin_constraints for detail placements
set_block_pin_constraints -pin_spacing 1 -allowed_layers {M2 M3 M4 M5 M6 M7 M8 M9} -exclude_sides {2 4} -allow_feedthroughs true
report_block_pin_constraints

# Gather Bus in/output pins and define new variables
create_bundle -name {bundle1_in_bus} {intr_rq[*]} 
create_bundle -name {bundle2_out_bus} {intr_bus[*]}

# Set how to deploy Bus in/output pins
create_pin_constraint -type bundle -bundles bundle1_in_bus -keep_pins_together true -self -sides 1 -range {10 40} -pin_spacing_distance 3 
create_pin_constraint -type bundle -bundles bundle2_out_bus -keep_pins_together true -self -sides 3 -range {10 40} -pin_spacing_distance 3

# Set additional constraints for pins such that all the input pins are deployed at the left side and all the output pins to right side.
set_individual_pin_constraints -ports {clk rst_in intr_in} -sides 1 -offset {45 60} -pin_spacing_distance 5
set_individual_pin_constraints -ports {intr_out bus_oe} -sides 3 -offset {45 60} -pin_spacing_distance 5

#check_pre_pin_placement -self
# Placing the ports according to the constraints defined above.
place_pins -self

#Define the power and ground nets
create_net -power VDD
create_net -ground VSS

#Connect the power and ground nets to power and ground pins
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]

#No need to define VIA master rules(ex. ContactCode) because they are already defined at .tf file in the Back_End milkyway library.
#Create ring pattern
create_pg_ring_pattern ring_pat -horizontal_layer M9 -horizontal_width {5} -horizontal_spacing {2} -vertical_layer M8 -vertical_width {5} -vertical_spacing {2} -corner_bridge false

#Set above set-ups as one strategy. Use this option when the pattern will be used again at other blocks. If you work for only one block, no need to use.
set_pg_strategy ring_strat -core -pattern {{name: ring_pat} {nets: {VDD VSS}} {offset: {3 3}} {parameters: {M9 5 2 M8 5 2 true}}} -extension {{stop: design_boundary}}  	
create_pg_mesh_pattern mesh_pat -layers {{{vertical_layer: M8} {width: 5} {spacing: interleaving} {pitch: 32}} {{vertical_layer: M6} {width: 2} {spacing: interleaving} {pitch: 32}} {{horizontal_layer: M9} {width: 5} {spacing: interleaving} {pitch: 32}}}

#Save above mesh power setting as one strategy. For some reason, ICC2 does not take parameters. So, please remove the last parameter set-up
set_pg_strategy mesh_strat -pattern {{name: mesh_pat} {nets: {VDD VSS}} {parameters: {32 32 32}}} -extension {{{nets: VDD}{layers: M8 M6}{stop: outermost_ring}} {{nets: VSS}{layers: M8 M6}{stop: outermost_ring}}} -design_boundary

#Standard cell rail pattern specifies the metal layers, rail width and rail offset to use to create the power and ground rails for the standard cell rows
create_pg_std_cell_conn_pattern rail_pat -layers {M2} -rail_width {1 1}

#Set stretagy related with above pattern
set_pg_strategy rail_strat -core -pattern {{name: rail_pat} {nets: VDD VSS} {parameters: {1 1}}}

# compile strategies
compile_pg
