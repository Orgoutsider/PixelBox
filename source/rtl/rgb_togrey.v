module rgb_togrey(
    input                   i_clk,
    input                   i_rst_n,
    input       [15:0]      i_rgbdata,
    input                   i_de,
    input                   i_vs,
    
    output      [15:0]      o_greydata,
    output      [7:0 ]      o_grey8b,
    output      reg         o_de,
    output      reg         o_vs
);

// 定义加权平均法的参数
parameter para_0299_8b = 8'd77    ; // 0.299的定点数
parameter para_0587_8b = 8'd150   ; // 0.587的定点数
parameter para_0114_8b = 8'd29    ; // 0.114的定点数

// 定义中间变量
reg     [15:0]          mult_r_16b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 红色分量乘以权重的结果
reg     [15:0]          mult_g_16b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 绿色分量乘以权重的结果
reg     [15:0]          mult_b_16b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 蓝色分量乘以权重的结果
reg     [15:0]          add_0_16b; // 前两个结果的和
reg     [15:0]          add_16b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 最终的和
// reg     [9:0 ]          gray_10b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 灰度值的定点数
reg     [ 7:0]          gray_8b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ // 灰度值的字节

reg                     i_de_1d;
reg                     i_vs_1d;
always @(posedge i_clk) begin
    i_de_1d <= i_de;
    o_de <= i_de_1d;
    i_vs_1d <= i_vs;
    o_vs <= i_vs_1d;
end

// 第一级流水：乘法
always @(posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        mult_r_16b <= 16'd0;
        mult_g_16b <= 16'd0;
        mult_b_16b <= 16'd0;
    end else begin
        // 提取RGB565的各个分量，并乘以相应的权重
        mult_r_16b <= {i_rgbdata[15:11], 3'b0} * para_0299_8b;
        mult_g_16b <= {i_rgbdata[10:5], 2'b0} * para_0587_8b;
        mult_b_16b <= {i_rgbdata[4:0], 3'b0} * para_0114_8b;
    end
end

// 第二级流水：加法
always @(posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        add_16b <= 16'd0;
    end else begin
        // 计算加权平均值
        add_16b <= mult_b_16b + mult_r_16b + mult_g_16b;
    end
end

// 提取灰度值的高8位
assign o_greydata = {add_16b[15:11], add_16b[15:10], add_16b[15:11]};
// 输出RGB565格式的灰度图像
assign o_grey8b = add_16b[15:8];

endmodule