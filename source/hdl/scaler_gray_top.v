module scaler_gray_top
                          #(parameter ADJUST_MODE = 1, // 虚拟像素点计算方式，直接计算0 还是 中心对齐1
                            parameter BRAM_DEEPTH = 1280,//src_width_i * 2
                            parameter DATA_WIDTH  = 8, // 每个通道单独处理
                            parameter INDEX_WIDTH = 11, // 索引宽度，即图形长宽的范围
                            parameter INT_WIDTH   = 8,   // <= INDEX_WIDTH
                            parameter FIX_WIDTH   = 12
                            )
                          (
                           input                            clk_i, // 时钟
                           input                            rst_i, // 复位
                           
                           input                            tvalid_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ // 输入de
                           input[DATA_WIDTH-1:0]            tdata_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/  //输入像素
                           output                           tready_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ // 
                           
                           
                           input[15 : 0]                    src_width_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/// 输入图像的宽
                           input[15 : 0]                    src_height_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/// 输入图像的高
                           input[15 : 0]                    dest_width_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///  目标图像的宽
                           input[15 : 0]                    dest_height_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///  目标图像的高                                                                             
         
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factorx_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///srcx_width/destx_width x方向缩放比
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factory_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ //srcy_height/desty_height y方向缩放比

                           output                           tvalid_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ // 输出de
                           output[DATA_WIDTH-1:0]           tdata_o /*synthesis PAP_MARK_DEBUG="1"*/  // 输出像素                                                        
                           );
                           

wire[INDEX_WIDTH-1:0]  destx;/*synthesis PAP_MARK_DEBUG="1"*/ // 目标像素x坐标
wire[INDEX_WIDTH-1:0]  desty;/*synthesis PAP_MARK_DEBUG="1"*/ // 目标像素y坐标

wire[INDEX_WIDTH-1:0]  srcx_int;/*synthesis PAP_MARK_DEBUG="1"*/ // 对应原图像素x坐标整数部分
wire[INDEX_WIDTH-1:0]  srcy_int;/*synthesis PAP_MARK_DEBUG="1"*/ // 对应原图像素y坐标整数部分

wire                  tvalid ; /*synthesis PAP_MARK_DEBUG="1"*/       
wire[DATA_WIDTH-1:0]  tdata00;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH-1:0]  tdata01;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH-1:0]  tdata10;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH-1:0]  tdata11;/*synthesis PAP_MARK_DEBUG="1"*/

// wire[4 * DATA_WIDTH:0]  tdata_d;


// 像素数据流控制模块
data_stream_ctr
                          #(.ADJUST_MODE(ADJUST_MODE),
                            .BRAM_DEEPTH(BRAM_DEEPTH),
                            .DATA_WIDTH(DATA_WIDTH),
                            .INDEX_WIDTH(INDEX_WIDTH),
                            .INT_WIDTH(INT_WIDTH),   // <= INDEX_WIDTH
                            .FIX_WIDTH(FIX_WIDTH))
                            
                          u0_data_stream_ctr  
                          (
                           .clk_i(clk_i),
                           .rst_i(rst_i),
                           
                           .tvalid_i(tvalid_i),
                           .tdata_i(tdata_i),//image stream
                           .tready_o(tready_o),
                           
                           
                           .src_width_i(src_width_i),//
                           .src_height_i(src_height_i),//
                           .dest_width_i(dest_width_i),//
                           .dest_height_i(dest_height_i),//
                           
                           
                           .srcx_int_i(srcx_int),//addr width
                           .srcy_int_i(srcy_int),//addr height                                                     
                           
                           .destx_o(destx),// 生成一个目标像素坐标x ，传入另一个模块中计算对应原像素坐标x current x location
                           .desty_o(desty),// 生成一个目标像素坐标y ，传入另一个模块中计算对应原像素坐标y current y location
                           
                           .scale_factorx_i(scale_factorx_i),//srcx_width/destx_width
                           .scale_factory_i(scale_factory_i),//srcy_height/desty_height
                           
                           .tvalid_o(tvalid),
                           .tdata00_o(tdata00),//
                           .tdata01_o(tdata01),// 
                           .tdata10_o(tdata10),//
                           .tdata11_o(tdata11) //                                                             
                           );
                           
// 图像缩放算法模块                                              
bilinear_gray
                          #(.ADJUST_MODE(ADJUST_MODE),
                            .DATA_WIDTH(DATA_WIDTH),
                            .INDEX_WIDTH(INDEX_WIDTH),
                            .INT_WIDTH(INT_WIDTH),
                            .FIX_WIDTH(FIX_WIDTH))
                            
                          u1_bilinear_gray  
                          (
                           .clk_i(clk_i),
                           .rst_i(rst_i),
                           
                           .destx_i(destx),//current x location
                           .desty_i(desty),//current y location
                           .src_width_i(src_width_i),//
                           .src_height_i(src_height_i),//
                           
                           .scale_factorx_i(scale_factorx_i),//srcx_width/destx_width
                           .scale_factory_i(scale_factory_i),//srcy_height/desty_height
                           
                           .srcx_int_o(srcx_int), // 输出计算好的原图像素坐标x
                           .srcy_int_o(srcy_int), // 输出计算好的原图像素坐标y

                           .dest_width_i(dest_width_i),//
                           .dest_height_i(dest_height_i),//
                           .tvalid_i (tvalid), // 输入数据有效
                           .tdata00_i(tdata00),//left top
                           .tdata01_i(tdata01),//right top 
                           .tdata10_i(tdata10),//left down
                           .tdata11_i(tdata11),//right down   
                                                                       
                           .tvalid_o(tvalid_o),
                           .tdata_o(tdata_o)                                
                           );



endmodule
