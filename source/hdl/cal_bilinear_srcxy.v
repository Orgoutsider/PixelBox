//-----------
//when srcx_width = 8192,scale_factorx_i must <=8,when srcy_height,scale_factory_i must <=8;
module cal_bilinear_srcxy
                          #(parameter ADJUST_MODE = 1,
                            parameter INDEX_WIDTH = 11,
                            parameter INT_WIDTH  = 8,// <= INDEX_WIDTH
                            parameter FIX_WIDTH  = 12
                            )
                          (
                           input                   clk_i,
                           input                   rst_i,
                           
                           input[INDEX_WIDTH-1:0]           destx_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///current x location
                           input[INDEX_WIDTH-1:0]           desty_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///current y location
         
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factorx_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///srcx_width/destx_width
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factory_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///srcy_height/desty_height  
         
                           output[INDEX_WIDTH-1:0]          srcx_int_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           output[INDEX_WIDTH-1:0]          srcy_int_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///                           
                           output[FIX_WIDTH-1:0]            srcx_fix_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                           output[FIX_WIDTH-1:0]            srcy_fix_o/*synthesis PAP_MARK_DEBUG="1"*/ //                                 
                           );

generate
  if(ADJUST_MODE == 0)begin
  
  //-------------normal mode-------------------------                           
  localparam LOCALTION_WIDTH = INDEX_WIDTH + FIX_WIDTH;
   
  //---------calculation srcxy------------
  reg[LOCALTION_WIDTH -1:0] srcx_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  reg[LOCALTION_WIDTH -1:0] srcy_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  always@(posedge clk_i)begin
    srcx_location <= scale_factorx_i * destx_i;  
    srcy_location <= scale_factory_i * desty_i;      
  end
    
  assign srcx_int_o = srcx_location[LOCALTION_WIDTH - 1:FIX_WIDTH];
  assign srcy_int_o = srcy_location[LOCALTION_WIDTH - 1:FIX_WIDTH];
  assign srcx_fix_o = srcx_location[FIX_WIDTH - 1:0];
  assign srcy_fix_o = srcy_location[FIX_WIDTH - 1:0];
  
  end 
  
  //中心对齐模式计算原图坐标
  else begin
  
  //---------------adjust mode-------------------------
  localparam LOCALTION_WIDTH  = INDEX_WIDTH + FIX_WIDTH;
  localparam FIX_OFFSET = {1'b1,{(FIX_WIDTH-1){1'b0}}};//0.5
   
  //---------calculation srcxy------------
  reg[LOCALTION_WIDTH -1:0] init_srcx_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  reg[LOCALTION_WIDTH -1:0] init_srcy_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  always@(posedge clk_i)begin
    init_srcx_location <= scale_factorx_i * destx_i;  
    init_srcy_location <= scale_factory_i * desty_i;      
  end  
    
  reg[LOCALTION_WIDTH -1 :0] temp_srcx_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  reg[LOCALTION_WIDTH -1 :0] temp_srcy_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  always@(posedge clk_i)begin
    temp_srcx_location <= init_srcx_location + (scale_factorx_i >> 1);  
    temp_srcy_location <= init_srcy_location + (scale_factory_i >> 1);      
  end
  
  reg[LOCALTION_WIDTH -1:0] adjust_srcx_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  always@(posedge clk_i)begin
    if(temp_srcx_location < FIX_OFFSET)begin // 
      adjust_srcx_location <= FIX_OFFSET - temp_srcx_location;//or == 0
    end else begin
      adjust_srcx_location <= temp_srcx_location - FIX_OFFSET;//
    end      
  end
  
  reg[LOCALTION_WIDTH -1:0] adjust_srcy_location = 0;/*synthesis PAP_MARK_DEBUG="1"*/
  always@(posedge clk_i)begin
    if(temp_srcy_location < FIX_OFFSET)begin // 
      adjust_srcy_location <= FIX_OFFSET - temp_srcy_location;//or == 0
    end else begin
      adjust_srcy_location <= temp_srcy_location - FIX_OFFSET;// 
    end      
  end
  
  // 提取原图坐标整数和小数部分
  // 整数部分用于读取四个相邻像素
  // 小数部分作为u，v去计算四个系数
  assign srcx_int_o = adjust_srcx_location[LOCALTION_WIDTH -1:FIX_WIDTH];
  assign srcy_int_o = adjust_srcy_location[LOCALTION_WIDTH -1:FIX_WIDTH];
  assign srcx_fix_o = adjust_srcx_location[FIX_WIDTH -1:0];
  assign srcy_fix_o = adjust_srcy_location[FIX_WIDTH -1:0];
  
  end
endgenerate

endmodule
