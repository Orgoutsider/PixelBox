//该模块是用来计算源图像的虚拟坐标,由于源图像和目的图像都是正方形，所以只考虑一个缩放倍数即可
//
module sourceimage_virtualcoordinate(input clk,
												 input [7:0]src_width,/src_width = src_height
												 input [5:0]dest_width,/dest_width = dest_height = 'd64
												 input start,///数据缓存满了以后才可以进行计算
												 output [7:0]coordinate_x,
												 output [7:0]coordinate_y,
												 output [7:0]coefficient1,
												 output [7:0]coefficient2,
												 output [7:0]coefficient3,
												 output [7:0]coefficient4,
												 output reg en = 'd0
												 
    );
//高电平有效rst
reg [1:0]cnt = 'd0;
always @(posedge clk)
	if(cnt == 'd3)
		cnt <= 'd3;
	else
		cnt <= cnt + 'd1;
reg rst = 'd1;
always @(posedge clk)
	if(cnt == 'd3)
		rst <= 'd0;
	else
		rst <= 'd1;
localparam [1:0]IDLE = 2'b01;
localparam [1:0]START = 2'b10;
//
reg[1:0]next_state = 'd0;
reg[1:0]current_state = 'd0;
always @(posedge clk)
	if(rst)高电平复位
		current_state <= IDLE;
	else
		current_state <= next_state;
//
reg finish = 'd0;
always @(*)
	case(current_state)	
		IDLE:	begin
			if(start)
				next_state = START;
			else
				next_state = IDLE;
		end
		START:	begin
			if(finish)
				next_state = IDLE;
			else
				next_state = START;
		end
		default:	next_state = IDLE;
	endcase	
//
//reg en = 'd0;//目的坐标计数器使能
always @(*)
		case(current_state)
			IDLE:	begin
				en = 'd0;
			end
			START:	begin
				en = 'd1;
			end
			default:	en = 'd0;
		endcase
///对目的图像坐标进行计数
reg[5:0] pos_x = 'd0;/列计数
always@(posedge clk)
	if(en)	begin
		if(pos_x == 'd63)
			pos_x <= 'd0;
		else
			pos_x <= pos_x + 'd1;
	end
	else
		pos_x <= pos_x;
reg[5:0] pos_y = 'd0;行计数
always @(posedge clk)
	if(pos_x == 'd63)
		pos_y <= pos_y + 'd1; 
	else
		pos_y <= pos_y;
//结束标志
always@(posedge clk)
	if((pos_x == 'd62)&&(pos_y == 'd63))///是pos_x==62而不是63
		finish <= 'd1;
	else
		finish <= 'd0;
//通过pos_x、pos_y可以计算对应源图像位置的虚拟坐标
reg [15:0]src_x = 'd0;///高8位表示整数，低8位表示小数
reg [15:0]src_y = 'd0;///高8位表示整数，低8位表示小数
assign src_x = ((pos_x<<1 + 'd1)*src_width - 'd64 > 'd0)?(pos_x<<1 + 'd1)*src_width - 'd64:'d64-(pos_x<<1 + 'd1)*src_width;
assign src_y = ((pos_y<<1 + 'd1)*src_width - 'd64 > 'd0)?(pos_y<<1 + 'd1)*src_width - 'd64:'d64-(pos_y<<1 + 'd1)*src_width;
// wire [7:0]pos_xq;
wire [7:0]pos_yq;
assign pos_xq = pos_x<<1;
assign pos_yq = pos_y<<1;
///
always @(posedge clk)
	if(pos_x == 'd0)	begin
		if(src_width > 'd64)
			src_x <= src_width - 'd64;
		else
			src_x <= 'd64 - src_width;
	end
	else 	begin
		if((pos_xq + 'd1)*src_width > 'd64)
			src_x <= (pos_xq + 'd1)*src_width - 'd64;
		else
			src_x <= 'd64 - (pos_xq + 'd1)*src_width;
	end
 
always @(posedge clk)
	if(pos_y == 'd0)	begin
		if(src_width > 'd64)
			src_y <= src_width - 'd64;
		else
			src_y <= 'd64 - src_width;
	end
	else 	begin
		if((pos_yq + 'd1)*src_width > 'd64)
			src_y <= (pos_yq + 'd1)*src_width - 'd64;
		else 
			src_y <= 'd64 - (pos_yq + 'd1)*src_width;
	end
//生成对应坐标
wire [6:0]coordinate_x;
wire [6:0]coordinate_y;
assign coordinate_x = src_x[14:7];
assign coordinate_y = src_y[14:7];
//生成对应系数 
wire [7:0]coefficient1;
wire [7:0]coefficient2;
wire [7:0]coefficient3;
wire [7:0]coefficient4;
assign coefficient2 = {1'b0,src_x[6:0]};
assign coefficient1 = 'd128 - coefficient2;
 
assign coefficient4 = {1'b0,src_y[6:0]};
assign coefficient3 = 'd128 - coefficient4;
endmodule