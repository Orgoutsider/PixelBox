module cal_bilinear_data
                        #(parameter DATA_WIDTH = 8,
                          parameter FIX_WIDTH  = 12)
                        (
                         input                  clk_i,
                         input                  rst_i,
                         input                  tvalid_i,

                         input[DATA_WIDTH-1:0]  tdata00_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点左上角数据
                         input[DATA_WIDTH-1:0]  tdata01_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点右上角数据  
                         input[DATA_WIDTH-1:0]  tdata10_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点左下角数据
                         input[DATA_WIDTH-1:0]  tdata11_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点右下角数据

                         input[15 : 0]         dest_width_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                         input[15 : 0]         dest_height_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                         input[15 : 0]         src_width_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///
                         input[15 : 0]         src_height_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///


                         input[FIX_WIDTH -1:0]  weight00_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w00
                         input[FIX_WIDTH -1:0]  weight01_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w01 
                         input[FIX_WIDTH -1:0]  weight10_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w10
                         input[FIX_WIDTH -1:0]  weight11_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w11                  
         
                         output                 tvalid_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/
                         output[DATA_WIDTH-1:0] tdata_o/*synthesis PAP_MARK_DEBUG="1"*/
                         );

localparam MULTI_WIDTH = FIX_WIDTH + DATA_WIDTH;
//---------calculation ------------
reg[MULTI_WIDTH - 1 : 0] multi00 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[MULTI_WIDTH - 1 : 0] multi01 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[MULTI_WIDTH - 1 : 0] multi10 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[MULTI_WIDTH - 1 : 0] multi11 = 0;/*synthesis PAP_MARK_DEBUG="1"*/

always@(posedge clk_i)begin
  multi00 <=  weight00_i * tdata00_i;  
  multi01 <=  weight01_i * tdata01_i;
  multi10 <=  weight10_i * tdata10_i;
  multi11 <=  weight11_i * tdata11_i;     
end

reg[MULTI_WIDTH : 0] level1_add0 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[MULTI_WIDTH : 0] level1_add1 = 0;/*synthesis PAP_MARK_DEBUG="1"*/

always@(posedge clk_i)begin
  level1_add0 <= multi00 + multi01;  
  level1_add1 <= multi10 + multi11;     
end

reg[MULTI_WIDTH + 1 : 0] level2_add0 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  level2_add0 <= level1_add0 + level1_add1;     
end

// 四舍五入
reg[DATA_WIDTH + 1 : 0] round_data = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  if(&level2_add0[MULTI_WIDTH + 1 : FIX_WIDTH])begin
    round_data <= level2_add0[MULTI_WIDTH + 1 : FIX_WIDTH];
  end else if(level2_add0[FIX_WIDTH - 1])begin // 看小数部分第一位，0.5
    round_data <= level2_add0[MULTI_WIDTH + 1 : FIX_WIDTH] + 1; // 进位
  end else begin
    round_data <= level2_add0[MULTI_WIDTH + 1 : FIX_WIDTH]; // 不进位 
  end                                                
end

reg[DATA_WIDTH - 1 : 0] tdata = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  tdata <= (|round_data[DATA_WIDTH + 1 -: 2]) ? {DATA_WIDTH{1'b1}} : round_data[DATA_WIDTH - 1 : 0];     
end
// 打五拍才能使 tvalid_i与 tdata同步
// 从 tvalid_i有效开始，经过五个时钟才算出对应的tdata
reg[4:0] tvalid_d = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  tvalid_d <= {tvalid_d[3:0], tvalid_i};     
end

assign tvalid_o = tvalid_d[4];
assign tdata_o  = tdata;



endmodule