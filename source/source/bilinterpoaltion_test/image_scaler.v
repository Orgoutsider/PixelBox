
module image_scaler #(
    parameter PIXEL_DATA_WIDTH     = 24,
    parameter SRC_IMAGE_RES_WIDTH  = 640,
    parameter SRC_IMAGE_RES_HEIGHT = 720,
    parameter DST_IMAGE_RES_WIDTH  = 320,
    parameter DST_IMAGE_RES_HEIGHT = 360

)(
    input  pixclk_in, /*synthesis PAP_MARK_DEBUG="1"*/
    input  rst_n,

    input  de_in/*synthesis PAP_MARK_DEBUG="1"*/,  /*synthesis PAP_MARK_DEBUG="1"*/ //de 信号有效，新的一行开始；de无效，一行传输结束
    output reg de_out/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:有问题,一直输出1
    
    input  [23:0] i_pixel /*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
    output reg [23:0] o_pixel/*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:有问题,一直输出0
    // output reg vs_out
);

parameter FIRST_PIXEL  = 'd0; // 第一个像素点
parameter SECOND_PIXEL = 'd1; // 第二个像素点
parameter THIRD_PIXEL  = 'd2; // 第三个像素点
parameter FOURTH_PIXEL = 'd3; // 第四个像素点

parameter FIRST_LINE  = 'd0; // 第一行
parameter SECOND_LINE = 'd1; // 第二行
parameter THIRD_LINE  = 'd2; // 第三行
parameter FOURTH_LINE = 'd3; // 第四行

reg [2:0] pixel_saved_cnt; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
reg two_pixels_saved; /*synthesis PAP_MARK_DEBUG="1"*/  //#TODO:没问题
reg interpolation_data_save_flag; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题

reg [23:0] pixel_data0; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
reg [23:0] pixel_data1; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
reg [23:0] pixel_data2; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题
reg [23:0] pixel_data3; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:没问题

reg ram0_wr_en;/*synthesis PAP_MARK_DEBUG="1"*/
reg ram1_wr_en;/*synthesis PAP_MARK_DEBUG="1"*/

wire [23:0] ram0_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
wire [23:0] ram1_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/

reg [23:0] ram0_wr_data;/*synthesis PAP_MARK_DEBUG="1"*/
reg [23:0] ram1_wr_data;/*synthesis PAP_MARK_DEBUG="1"*/

reg [9:0] ram0_wr_addr;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] ram1_wr_addr;/*synthesis PAP_MARK_DEBUG="1"*/

reg [9:0] ram0_rd_addr;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] ram1_rd_addr;/*synthesis PAP_MARK_DEBUG="1"*/

reg [8:0] second_interpolated_pixel_cnt_per_line; /*synthesis PAP_MARK_DEBUG="1"*/  // 最大320
reg [8:0] fisrt_interpolated_pixel_cnt_per_line;  /*synthesis PAP_MARK_DEBUG="1"*/ // 最大320

reg first_interpolation_done12; /*synthesis PAP_MARK_DEBUG="1"*/
reg first_interpolation_done34; /*synthesis PAP_MARK_DEBUG="1"*/
reg [1:0] first_interpolated_line; /*synthesis PAP_MARK_DEBUG="1"*/
reg second_interpolation_done12; /*synthesis PAP_MARK_DEBUG="1"*/
reg second_interpolation_done34; /*synthesis PAP_MARK_DEBUG="1"*/

// 对输入数据暂存
// 每输入两个数据就拉高interpolation_data_save
always @(posedge pixclk_in) begin

    // $display("pixel_saved_cnt: %d", pixel_saved_cnt);
    if (!rst_n) begin
        pixel_saved_cnt  <= 'd0;             // 当前暂存到第几个像素点，插值计数
        two_pixels_saved <= 1'b0;             // 插值保存标志，每两个像素保存就拉高
        interpolation_data_save_flag <= 1'b0; // 插值保存标志，保存前两像素为低，保存后两个像素为高
        
        pixel_data0 <= 'd0;  // 双线性插值的第1个像素
        pixel_data1 <= 'd0;  // 双线性插值的第2个像素
        pixel_data2 <= 'd0;  // 双线性插值的第3个像素
        pixel_data3 <= 'd0;  // 双线性插值的第4个像素
    end
    else if(de_in) begin   // de拉高后说明像素有效，对输入的微据进行暂存
        // $display("pixel_saved_cnt: %d, two_pixels_saved:%d ,interpolation_data_save_flag:%d", pixel_saved_cnt, two_pixels_saved, interpolation_data_save_flag);
        case(pixel_saved_cnt)
            FIRST_PIXEL: begin
                pixel_data0 <= i_pixel;     //暂存第一个微据
               
                two_pixels_saved <= 1'b0;   //还未存好两个数据，然后拉低
                pixel_saved_cnt <=  'd1;   //已经存了第一个微据，准备存第二个像素
            end
            SECOND_PIXEL: begin 
                pixel_data1 <= i_pixel;              //背存第二个数据
                
                interpolation_data_save_flag <= 'd0; //为0时，1，2像素值存好了
                two_pixels_saved <= 1'b1;            //已经存了两个数据，然后拉高
                pixel_saved_cnt <= 'd2;             //已经存了第二个微据，准备存第三个像素
            end
            THIRD_PIXEL: begin 
                pixel_data2 <= i_pixel;              //暂存第3个微据
                
                two_pixels_saved <= 1'b0;            //还未存好两个数据，然后拉低
                pixel_saved_cnt <= 'd3;     //已经存了第三个微据，准备存第四个像素
            end
            FOURTH_PIXEL: begin
                pixel_data3 <= i_pixel;              //暂存第4个微据
                
                interpolation_data_save_flag <= 'd1; // 为1时，34像素值存好了
                two_pixels_saved <= 1'b1;            //已经存了两个数据，然后拉高
                pixel_saved_cnt <= 'd0;             //已经存了第四个微据，又返回准备存第一个像素
            end
        endcase     
    end
    else begin // 如果de信号无效，说明一行像素传输结束
        pixel_data0 <= 'd0;
        pixel_data1 <= 'd0;
        pixel_data2 <= 'd0;
        pixel_data3 <= 'd0;

        pixel_saved_cnt  <=  1'b0;
        two_pixels_saved <= 1'b0;
        interpolation_data_save_flag <= 'd0;
    end
end

//对输入的数据进行第一次线性插值
always @(posedge pixclk_in) begin
    // $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d, ",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line);
    // $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line, );
    if(!rst_n) begin
        fisrt_interpolated_pixel_cnt_per_line  <= 'd0; // 计数一行中轮到第几个像素进行了插值，用于计算地址
        first_interpolated_line <= 'd0;
        ram0_wr_en   <= 1'b0;
        ram1_wr_en   <= 1'b0;
        ram0_wr_data <= 'd0;
        ram1_wr_data <= 'd0;
        ram0_wr_addr <= 'd0;
        ram1_wr_addr <= 'd0;
        first_interpolation_done12 <= 'd0;
        first_interpolation_done34 <= 'd0;
    end
    //RGB888
    else if(two_pixels_saved) begin //two_pixels_saved信号拉高后，对暂存的两个数据进行一次线性插值，同时计数，当插值达到视频横向分辨率一半时结束插值
        // $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d, r0_wen:%d, r1_wen:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line, ram0_wr_en, ram1_wr_en);
        case(first_interpolated_line)
            FIRST_LINE: begin  
                //第一行数据插值，存入ram0的page0中
                ram0_wr_addr <= {1'b0, fisrt_interpolated_pixel_cnt_per_line}; // 地址的最高位表示页数，0表示第0页，1表示第1页
                if(interpolation_data_save_flag == 0) begin//当save_flag为0时，计算pix0pix1 写数据到ram0, 切记进行分通道计算
                    ram0_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2); //r8
                    ram0_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2); //g8
                    ram0_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2); //b8
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram0_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
                // 当计算的新像素点达到我们目标图像的行分辨率时，说明第0行的新像素已经计算完，计算第1行
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
                    ram0_wr_en                             <= 1'b0;
                    // ram1_wr_en                             <= 1'b0;
                    
                    fisrt_interpolated_pixel_cnt_per_line  <= 'd0;
                    first_interpolation_done12             <= 'd0;
                    first_interpolation_done34             <= 'd0;               
                    first_interpolated_line                <= 'd1;
                end
                else begin
                    ram0_wr_en <= 1'b1; //计算完一个像素点，就可以写入ram
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1; // 每计算完一个新像素点+1
                end
            end
            SECOND_LINE: begin //第二行数据插值,存入ram1的page0中
                ram1_wr_addr <= {1'b0, fisrt_interpolated_pixel_cnt_per_line};  // 地址的最高位表示页数，0表示第0页，1表示第1页
                if(interpolation_data_save_flag == 0) begin//当save_flag为0时，计算pix1pix2 
                    ram1_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram1_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
               
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
                    ram1_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    first_interpolation_done12 <= 'd1; // 相邻两行的像素已经计算完成，拉高
                    first_interpolated_line <= 'd2;   // 第1行像素计算完成，接下来计算第2行
                end   
                else begin
                    ram1_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1;
                end
            end
            THIRD_LINE: begin     //由于前两行插值完成后需要进行计算，所以还需要第三第四行来进行暂存,第三行数据插值，存入ram0的page1中
                ram0_wr_addr <= {1'b1, fisrt_interpolated_pixel_cnt_per_line}; // 地址的最高位表示页数，0表示第0页，1表示第1页
                if(interpolation_data_save_flag == 0) begin  
                    ram0_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram0_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
               
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
                    ram0_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    first_interpolation_done12 <= 'd0;
                    first_interpolation_done34 <= 'd0;               
                    first_interpolated_line <= 'd3;
                end
                else begin
                    ram0_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1;
                end
            end     
            FOURTH_LINE: begin //第4行数据插值，存入ram1的page1中
                ram1_wr_addr <= {1'b1, fisrt_interpolated_pixel_cnt_per_line};  // 地址的最高位表示页数，0表示第0页，1表示第1页
                if(interpolation_data_save_flag == 0) begin
                    ram1_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram1_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
                    ram1_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    // first_interpolation_done12 <= 'd0;
                    first_interpolation_done34 <= 'd1; 
                    first_interpolated_line <= 'd0;
                end   
                else begin
                    ram1_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1; 
                end
            end 
        endcase
    end
    // else begin 
    //     if (de_in) begin
    //         fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line;
    //         first_interpolated_line <= first_interpolated_line;
    //         ram0_wr_en <= ram0_wr_en;
    //         ram1_wr_en <= ram1_wr_en;
    //     end
    //     else begin
    //         fisrt_interpolated_pixel_cnt_per_line <= 0;
    //         first_interpolated_line <= 0;
    //         ram0_wr_en <= 1'b0;
    //         ram1_wr_en <= 1'b0;
    //     end
    // end
    else begin
        fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line;
        first_interpolated_line <= first_interpolated_line;
    end
end


// 每计算完一次新一行的第二次线性插值，就 ssecond_interpolated_pixel_cnt_per_line 计数+1
// 如果插值完一行就清零
//完成两行的线性插值后，读出存入ram的第一次插值的数值，进行第二次线性插帧
always @(posedge pixclk_in) begin
    // $display("two_pixels_saved: %d, fisrt_interpolated_pixel_cnt_per_line:%d, first_interpolated_line:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line);
    if(!rst_n) begin
        o_pixel <= 'd0;
        de_out  <= 'd0;
        ram0_rd_addr <= 'd0;
        ram1_rd_addr <= 'd0;
        second_interpolated_pixel_cnt_per_line <= 0;
        second_interpolation_done12 <= 'd0; 
        second_interpolation_done34 <= 'd0; 
    end
    //两个ram第0页写入完成，即第一二行第一次插值的新像素点计算完成，可以进行第二次线性插值
    else if(first_interpolation_done12 && !second_interpolation_done12) begin     // 12行第二次插值

        ram0_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        ram1_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        o_pixel[23:16] <= ram0_rd_data[23:16] / 2 + ram1_rd_data[23:16] / 2;
        o_pixel[15: 8] <= ram0_rd_data[15: 8] / 2 + ram1_rd_data[15: 8] / 2;
        o_pixel[7 : 0] <= ram0_rd_data[7 : 0] / 2 + ram1_rd_data[7 : 0] / 2;

        
        if(second_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
            second_interpolated_pixel_cnt_per_line <= 'd0;
            second_interpolation_done12 <= 'd1;
            second_interpolation_done34 <= 'd0;
            de_out <= 'd0;
        end
        else begin
            second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line + 1;
            de_out <= 'd1;
        end
    end
    else if(first_interpolation_done34 && !second_interpolation_done34) begin     // 12行第二次插值

        ram0_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        ram1_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        o_pixel[23:16] <= ram0_rd_data[23:16] / 2 + ram1_rd_data[23:16] / 2;
        o_pixel[15: 8] <= ram0_rd_data[15: 8] / 2 + ram1_rd_data[15: 8] / 2;
        o_pixel[7 : 0] <= ram0_rd_data[7 : 0] / 2 + ram1_rd_data[7 : 0] / 2;

        
        if(second_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH-2) begin
            second_interpolated_pixel_cnt_per_line <= 'd0;
            second_interpolation_done12 <= 'd0;
            second_interpolation_done34 <= 'd1;
            de_out <= 'd0;
        end
        else begin
            second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line + 1;
            de_out <= 'd1;
        end
    end
    else begin // 当插值达到目标大小后，提前复位
        second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line;
        o_pixel <= 'd0;
        de_out <= 'd0;
    
        if (second_interpolation_done34) begin // 三四行第二次插值完成，地址转到12行
            ram0_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
            ram1_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        end
        else if (second_interpolation_done12) begin // 一二行第二次插值完成，地址转到34行
            ram0_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
            ram1_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        end
    end
end

// 缓存1, 3行像素点的ram0
image_resize_ram ram0 (
  .wr_data(ram0_wr_data),    // input [23:0]
  .wr_addr(ram0_wr_addr),    // input [10:0]
  .wr_en(ram0_wr_en),        // input
  .wr_clk(pixclk_in),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(ram0_rd_addr),    // input [10:0]
  .rd_data(ram0_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),      // input
  .rd_rst(~rst_n)       // input
);

// 缓存2, 4行像素点的ram1
image_resize_ram ram1 (
  .wr_data(ram1_wr_data),    // input [23:0]
  .wr_addr(ram1_wr_addr),    // input [10:0]
  .wr_en(ram1_wr_en),        // input
  .wr_clk(pixclk_in),  // input
  .wr_rst(~rst_n),            // input
  .rd_addr(ram1_rd_addr),    // input [10:0]
  .rd_data(ram1_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),  // input
  .rd_rst(~rst_n)             // input
);
endmodule