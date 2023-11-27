module image_scaler2 #(
    parameter SRC_IMAGE_RES_WIDTH  = 640,
    parameter SRC_IMAGE_RES_HEIGHT = 720,
    parameter DST_IMAGE_RES_WIDTH  = 320,
    parameter DST_IMAGE_RES_HEIGHT = 360
) (
    input             pixclk_in,/*synthesis PAP_MARK_DEBUG="1"*/
    input             rst_n,
    input             de_in   /*synthesis PAP_MARK_DEBUG="1"*/,  /*synthesis PAP_MARK_DEBUG="1"*/ //de 信号有效，新的一行开始；de无效，一行传输结束
    input  [23:0]     i_pixel /*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
    
    output reg        de_out  /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:有问题,一直输出1
    output reg [23:0] o_pixel /*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:有问题,一直输出0
);
parameter FIRST_PIXEL  = 'd1; // 第一个像素点
parameter SECOND_PIXEL = 'd2; // 第二个像素点
parameter THIRD_PIXEL  = 'd3; // 第三个像素点
parameter FOURTH_PIXEL = 'd4; // 第四个像素点

parameter FIRST_LINE  = 'd1; // 第一行
parameter SECOND_LINE = 'd2; // 第二行
parameter THIRD_LINE  = 'd2; // 第三行
parameter FOURTH_LINE = 'd3; // 第四行

reg [23:0] pixel1;  // 双线性插值的第1个像素
reg [23:0] pixel2;  // 双线性插值的第2个像素
reg [2:0] pix_cnt;


// 暂存输入像素
assgin pixel1 = (pix_cnt == FIRST_PIXEL)  ? i_pixel : 0;
assgin pixel2 = (pix_cnt == SECOND_PIXEL) ? i_pixel : 0;
// 对输入的像素进行计数
always @(posedge pix_cnt) begin
    if (!de_in) begin
        pix_cnt <= 0;
    end
    else begin
        if (pix_cnt < 2) begin
            pix_cnt <= pix_cnt + 1;
        end
        else begin
            pix_cnt <= 1;
        end
    end
end



assign ram1_wr_data[23:16] = (pix_cnt == 2 && line_state == 1) ? (pixel1[23:16] / 2) + (pixel2[23:16] / 2); //r8
assign ram1_wr_data[15: 8] = (pix_cnt == 2 && line_state == 1) ? (pixel1[15: 8] / 2) + (pixel2[15: 8] / 2); //g8
assign ram1_wr_data[7 : 0] = (pix_cnt == 2 && line_state == 1) ? (pixel1[7 : 0] / 2) + (pixel2[7 : 0] / 2); //b8

assign ram2_wr_data[23:16] = (pix_cnt == 2 && line_state == 2) ? (pixel1[23:16] / 2) + (pixel2[23:16] / 2); //r8
assign ram2_wr_data[15: 8] = (pix_cnt == 2 && line_state == 2) ? (pixel1[15: 8] / 2) + (pixel2[15: 8] / 2); //g8
assign ram2_wr_data[7 : 0] = (pix_cnt == 2 && line_state == 2) ? (pixel1[7 : 0] / 2) + (pixel2[7 : 0] / 2); //b8
// 第一次线性插值
always @(posedge pixclk_in) begin
    if(!rst_n) begin
        ram0_wr_data <= 0;
    end
    else begin
        if (pix_cnt == 2) begin
            ram0_wr_data[23:16] <= (pix_cnt == 2) ? (pixel1[23:16] / 2) + (pixel2[23:16] / 2); //r8
            ram0_wr_data[15: 8] <= (pix_cnt == 2) ? (pixel1[15: 8] / 2) + (pixel2[15: 8] / 2); //g8
            ram0_wr_data[7 : 0] <= (pix_cnt == 2) ? (pixel1[7 : 0] / 2) + (pixel2[7 : 0] / 2); //b8
        end
    end
end

// 第一行一次插值数据写使能
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        ram1_wr_en <= 0;
    end
    else begin
        if (first_interpolated_line == 1) begin
            ram1_wr_en <= 1;
        end
    end
end
// 第二行一次插值数据写使能
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        ram2_wr_en <= 0;
    end
    else begin
        if (first_interpolated_line == 2) begin
            ram2_wr_en <= 1;
        end
    end
end
// 完成第一次线性插值的行
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        first_interpolated_line <= 0;
    end
    else begin
        if (fisrt_interpolated_pix == 320 - 1) begin
            if (first_interpolated_line < 2) 
                first_interpolated_line <= first_interpolated_line + 1;
            else 
                first_interpolated_line <= 1;
        end
    end
end

// assign line_state <= (fisrt_interpolated_pix == 319) ? 1 : 0; 
// 每行完成第一次插值的像素数
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        fisrt_interpolated_pix <= 0;
    end
    else begin
        if (pix_cnt == 2) begin // 算完一个第一次插值
             if (fisrt_interpolated_pix == 320 - 1) begin
                fisrt_interpolated_pix <= 0;
            end
            else begin
                fisrt_interpolated_pix <= fisrt_interpolated_pix + 1;
            end
        end
           
    end
end

// 第二次插值像素计数
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        second_interpolate_pix <= 0;
    end
    else begin
        if (first_interpolated_line == 2) begin
            if (second_interpolate_pix == 320 - 1) begin
                second_interpolate_pix <= 0;
            end
            else begin
                second_interpolate_pix <= second_interpolate_pix + 1;
            end
        end
        end
          
end
// 第二次线性插值
assgin o_pixel[23:16] <= (first_interpolated_line == 2) ? ram1_rd_data[23:16] / 2 + ram2_rd_data[23:16] / 2;
assgin o_pixel[15: 8] <= (first_interpolated_line == 2) ? ram1_rd_data[15: 8] / 2 + ram2_rd_data[15: 8] / 2;
assgin o_pixel[7 : 0] <= (first_interpolated_line == 2) ? ram1_rd_data[7 : 0] / 2 + ram2_rd_data[7 : 0] / 2;

// 第一行插值写地址
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        ram1_wr_addr <= 0;
    end
    else begin
        if (pix_cnt == 2 && line_state == 1) begin
            ram1_wr_addr <= fisrt_interpolated_pix;
        end
    end
end

// 第二行插值写地址
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        ram2_wr_addr <= 0;
    end
    else begin
        if (line_state == 2) begin
            ram2_wr_addr <= fisrt_interpolated_pix;
        end
    end
end

// 第一行读地址
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        ram1_rd_addr <= 0;
    end
    else begin
        if (pix_cnt == 2 && line_state == 2) begin
            ram2_wr_addr <= second_interpolate_pix;
        end
    end
end

image_resize_ram u_ram1 (
  .wr_data(ram1_wr_data),    // input [23:0]
  .wr_addr(ram1_wr_addr),    // input [10:0]
  .wr_en(ram1_wr_en),        // input
  .wr_clk(pixclk_in),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(ram1_rd_addr),    // input [10:0]
  .rd_data(ram1_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),      // input
  .rd_rst(~rst_n)       // input
);

// 缓存2, 4行像素点的ram1
image_resize_ram u_ram2 (
  .wr_data(ram2_wr_data),    // input [23:0]
  .wr_addr(ram2_wr_addr),    // input [10:0]
  .wr_en(ram2_wr_en),        // input
  .wr_clk(pixclk_in),  // input
  .wr_rst(~rst_n),            // input
  .rd_addr(ram2_rd_addr),    // input [10:0]
  .rd_data(ram2_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),  // input
  .rd_rst(~rst_n)             // input
);     
endmodule   