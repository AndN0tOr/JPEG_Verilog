run 50us
echo "--- STATE ---"
examine /jpeg_top_tb/uut/u19/state
examine /jpeg_top_tb/uut/u19/y_fifo_empty
examine /jpeg_top_tb/uut/u19/cb_fifo_empty
examine /jpeg_top_tb/uut/u19/cr_fifo_empty
examine /jpeg_top_tb/uut/u19/jpeg_process_inst/color_trans_inst/enable
examine /jpeg_top_tb/uut/u19/jpeg_process_inst/y_dqh_inst0/u1/output_enable
examine /jpeg_top_tb/uut/u19/jpeg_process_inst/y_dqh_inst0/u3/flushing
examine /jpeg_top_tb/uut/u19/jpeg_process_inst/y_dqh_inst0/u3/is_last_chunk
examine /jpeg_top_tb/uut/u19/jpeg_process_inst/y_dqh_inst0/u1/blocks_ready
quit
