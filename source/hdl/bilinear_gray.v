module bilinear_gray
                          #(parameter ADJUST_MODE = 1,
                            parameter DATA_WIDTH = 8,
                            parameter INDEX_WIDTH = 11,
                            parameter INT_WIDTH  = 8,// <= INDEX_WIDTH
                            parameter FIX_WIDTH  = 12)
                          (
                           input                            clk_i,
                           input                            rst_i,
         
                           input[INDEX_WIDTH-1:0]           destx_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///current x location
                           input[INDEX_WIDTH-1:0]           desty_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///current y location
         
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factorx_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///srcx_width/destx_width
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factory_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///srcy_height/desty_height

                           output[INDEX_WIDTH-1:0]          srcx_int_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           output[INDEX_WIDTH-1:0]          srcy_int_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///

                           input[15 : 0]         dest_width_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]         dest_height_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]         src_width_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]         src_height_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///

                           input                  tvalid_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/
                           input[DATA_WIDTH-1:0]  tdata00_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///æåŒç¹å·Šäžè§æ°æ
                           input[DATA_WIDTH-1:0]  tdata01_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///æåŒç¹å³äžè§æ°æ 
                           input[DATA_WIDTH-1:0]  tdata10_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///æåŒç¹å·Šäžè§æ°æ
                           input[DATA_WIDTH-1:0]  tdata11_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///æåŒç¹å³äžè§æ°æ                    
         
                           output                 tvalid_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/
                           output[DATA_WIDTH-1:0] tdata_o /*synthesis PAP_MARK_DEBUG="1"*/                               
                           );

wire[FIX_WIDTH-1:0]  srcx_fix;/*synthesis PAP_MARK_DEBUG="1"*/
wire[FIX_WIDTH-1:0]  srcy_fix;/*synthesis PAP_MARK_DEBUG="1"*/
wire[FIX_WIDTH -1:0] weight00;/*synthesis PAP_MARK_DEBUG="1"*/
wire[FIX_WIDTH -1:0] weight01; /*synthesis PAP_MARK_DEBUG="1"*/
wire[FIX_WIDTH -1:0] weight10;/*synthesis PAP_MARK_DEBUG="1"*/
wire[FIX_WIDTH -1:0] weight11;  /*synthesis PAP_MARK_DEBUG="1"*/

cal_bilinear_srcxy #(
                     .ADJUST_MODE(ADJUST_MODE),
                     .INDEX_WIDTH(INDEX_WIDTH),
                     .INT_WIDTH(INT_WIDTH),// <= INDEX_WIDTH
                     .FIX_WIDTH(FIX_WIDTH)
                     )
                   u0_cal_bilinear_srcxy (
                                          .clk_i(clk_i), 
                                          .rst_i(rst_i), 
                                          .destx_i(destx_i), 
                                          .desty_i(desty_i), 
                                          .scale_factorx_i(scale_factorx_i), 
                                          .scale_factory_i(scale_factory_i), 
                                          .srcx_int_o(srcx_int_o), 
                                          .srcy_int_o(srcy_int_o), 
                                          .srcx_fix_o(srcx_fix), 
                                          .srcy_fix_o(srcy_fix)
                                          );
    
cal_bilinear_weight#(
                     .FIX_WIDTH(FIX_WIDTH)
                     ) 
                    u1_cal_bilinear_weight (
                                            .clk_i(clk_i), 
                                            .rst_i(rst_i), 
                                            .srcx_fix_i(srcx_fix), 
                                            .srcy_fix_i(srcy_fix), 
                                            .weight00_o(weight00), 
                                            .weight01_o(weight01), 
                                            .weight10_o(weight10), 
                                            .weight11_o(weight11)
                                            );
    
cal_bilinear_data #(
                     .DATA_WIDTH(DATA_WIDTH),// <= INDEX_WIDTH
                     .FIX_WIDTH(FIX_WIDTH)
                     )
                  u2_cal_bilinear_data (
                                        .clk_i(clk_i), 
                                        .rst_i(rst_i), 
                                        .tvalid_i(tvalid_i), 

                                        
                                        
                                        .tdata00_i(tdata00_i), 
                                        .tdata01_i(tdata01_i), 
                                        .tdata10_i(tdata10_i), 
                                        .tdata11_i(tdata11_i),

                                        .dest_width_i(dest_width_i),//
                                        .dest_height_i(dest_height_i),//
                                        .src_width_i(src_width_i),//
                                        .src_height_i(src_height_i),//

                                        .weight00_i(weight00), 
                                        .weight01_i(weight01), 
                                        .weight10_i(weight10), 
                                        .weight11_i(weight11), 
                                        
                                        .tvalid_o(tvalid_o), 
                                        .tdata_o(tdata_o)
                                        );

endmodule