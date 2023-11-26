module rgb_togrey(
    input                   i_clk,
    input                   i_rst_n,
    input       [15:0]      i_rgbdata,
    
    output      [15:0]      o_greydata,
    output      [7:0 ]      o_grey8b,
);

// 定义加权平均法的参数
parameter para_0299_10b = 10'd77; // 0.299的定点数
parameter para_0587_10b = 10'd150; // 0.587的定点数
parameter para_0114_10b = 10'd29; // 0.114的定点数

// 定义中间变量
reg     [17:0]          mult_r_18b; // 红色分量乘以权重的结果
reg     [17:0]          mult_g_18b; // 绿色分量乘以权重的结果
reg     [17:0]          mult_b_18b; // 蓝色分量乘以权重的结果
reg     [17:0]          add_0_18b; // 前两个结果的和
reg     [17:0]          add_1_18b; // 最终的和
reg     [9:0 ]          gray_10b; // 灰度值的定点数
reg     [7:0 ]          gray_8b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 灰度值的字节

// 第一级流水：乘法
always @(posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        mult_r_18b <= 18'd0;
        mult_g_18b <= 18'd0;
        mult_b_18b <= 18'd0;
    end else begin
        // 提取RGB565的各个分量，并乘以相应的权重
        mult_r_18b <= {2'b0, i_rgbdata[15:11]} * para_0299_10b;
        mult_g_18b <= {2'b0, i_rgbdata[10:5]} * para_0587_10b;
        mult_b_18b <= {3'b0, i_rgbdata[4:0]} * para_0114_10b;
    end
end

// 第二级流水：加法
always @(posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        add_0_18b <= 18'd0;
        add_1_18b <= 18'd0;
    end else begin
        // 计算加权平均值
        add_0_18b <= mult_r_18b + mult_g_18b;
        add_1_18b <= add_0_18b + mult_b_18b;
        // 提取灰度值的高8位
        gray_8b <= add_1_18b[17:10];
    end
end

// 输出RGB565格式的灰度图像
assign o_greydata = {gray_8b[7:3], gray_8b[7:2], gray_8b[7:3]};
assign o_grey8b = gray_8b;

endmodule