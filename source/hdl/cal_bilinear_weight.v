module cal_bilinear_weight
                          #(parameter FIX_WIDTH  = 12)
                          (
                           input                  clk_i,
                           input                  rst_i,
         
                           input[FIX_WIDTH-1:0]   srcx_fix_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点x坐标定点小数部分 u
                           input[FIX_WIDTH-1:0]   srcy_fix_i/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///插值点y坐标定点小数部分 v
         
                           output[FIX_WIDTH -1:0] weight00_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w00
                           output[FIX_WIDTH -1:0] weight01_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w01 
                           output[FIX_WIDTH -1:0] weight10_o/*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*///w10
                           output[FIX_WIDTH -1:0] weight11_o/*synthesis PAP_MARK_DEBUG="1"*/ //w11                                 
                           );

localparam FIX_MAX = {FIX_WIDTH{1'b1}};
//localparam FIX_MAX = 1 << FIX_WIDTH;

reg[FIX_WIDTH - 1:0] comp_srcx_fix;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  if(rst_i)begin
    comp_srcx_fix <= 32'd0;
  end else begin
    comp_srcx_fix <= FIX_MAX - srcx_fix_i; // 1-u
  end
end

reg[FIX_WIDTH-1:0] comp_srcy_fix;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  if(rst_i)begin
    comp_srcy_fix <= 32'd0;
  end else begin
    comp_srcy_fix <= FIX_MAX - srcy_fix_i;// 1-v
  end
end

reg[FIX_WIDTH-1:0]   srcx_fix_d = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[FIX_WIDTH-1:0]   srcy_fix_d = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  srcx_fix_d <= srcx_fix_i; // u
  srcy_fix_d <= srcy_fix_i; // v    
end

//---------calculation weight------------
reg[(FIX_WIDTH << 1)-1:0] multi00 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[(FIX_WIDTH << 1)-1:0] multi01 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[(FIX_WIDTH << 1)-1:0] multi10 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[(FIX_WIDTH << 1)-1:0] multi11 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i)begin
  multi00 <= comp_srcx_fix * comp_srcy_fix; // (1-u)(1-v)
  multi01 <= srcx_fix_d * comp_srcy_fix;    // u(1-v)
  multi10 <= comp_srcx_fix * srcy_fix_d;    // (1-u)v
  multi11 <= srcx_fix_d * srcy_fix_d;       // uv
end

reg[FIX_WIDTH -1:0] weight00 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[FIX_WIDTH -1:0] weight01 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[FIX_WIDTH -1:0] weight10 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg[FIX_WIDTH -1:0] weight11 = 0;/*synthesis PAP_MARK_DEBUG="1"*/


// 四舍五入
always@(posedge clk_i)begin
//  weight00 <= multi00[(FIX_WIDTH << 1)-1:FIX_WIDTH] + (|multi00[FIX_WIDTH -1:0]);  
//  weight01 <= multi01[(FIX_WIDTH << 1)-1:FIX_WIDTH] + (|multi01[FIX_WIDTH -1:0]);
//  weight10 <= multi10[(FIX_WIDTH << 1)-1:FIX_WIDTH] + (|multi10[FIX_WIDTH -1:0]);
//  weight11 <= multi11[(FIX_WIDTH << 1)-1:FIX_WIDTH] + (|multi11[FIX_WIDTH -1:0]); 
  weight00 <= multi00[(FIX_WIDTH << 1)-1:FIX_WIDTH] + multi00[FIX_WIDTH -1];  
  weight01 <= multi01[(FIX_WIDTH << 1)-1:FIX_WIDTH] + multi01[FIX_WIDTH -1];
  weight10 <= multi10[(FIX_WIDTH << 1)-1:FIX_WIDTH] + multi10[FIX_WIDTH -1];
  weight11 <= multi11[(FIX_WIDTH << 1)-1:FIX_WIDTH] + multi11[FIX_WIDTH -1];       
end

assign weight00_o = weight00;
assign weight01_o = weight01;
assign weight10_o = weight10;
assign weight11_o = weight11;

endmodule