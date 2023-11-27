`timescale 1ns / 1ps

// `define COLOR_VIDEO_1920_1080
// `define COLOR_VIDEO_1680_1050
// `define COLOR_VIDEO_1280_1024
`define COLOR_VIDEO_1280_720
// `define COLOR_VIDEO_1024_768
// `define COLOR_VIDEO_800_600
// `define COLOR_VIDEO_640_480
module video_timing_color #(
	parameter VIDEO_H       = 1280,
	parameter VIDEO_V       = 720 ,
	parameter VIDEO_START_X = 0   ,
	parameter VIDEO_START_Y = 0   
) (
	input	wire		i_clk     ,	
	input   wire        i_rst_n   , 
	input   wire [23:0] i_rgb     ,
	output	reg			o_hs      ,
	output	reg			o_vs      ,
	output	reg			o_de      ,
	output  wire [23:0] o_rgb     ,
	output  wire        o_data_req,
	output  wire [10:0] o_h_dis   ,
	output  wire [10:0] o_v_dis   ,
	output	reg  [10:0]	o_x_pos   ,
	output	reg  [10:0] o_y_pos   
);

//1920x1080 148.5Mhz
`ifdef  COLOR_VIDEO_1920_1080
localparam  H_ACTIVE 		= 1920;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 88;  // ������ǰ��ʱ��
localparam  H_SYNC_TIME 		= 44;  // ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 148; // ���������ʱ�� 
localparam  H_POLARITY       = 1;   // ��ͬ������                                   
localparam  V_ACTIVE 		= 1080;// ��������Чʱ��
localparam  V_FRONT_PORCH 	= 4;   // ������ǰ��ʱ��
localparam  V_SYNC_TIME  	= 5;   // ��ͬ���ź�ʱ��
localparam  V_BACK_PORCH 	= 36;  // ���������ʱ��
localparam  V_POLARITY       = 1;   // ��ͬ������
`endif

//1680x1050 119Mhz
`ifdef  COLOR_VIDEO_1680_1050
localparam  H_ACTIVE 		= 1680;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 48;  // ������ǰ��ʱ��
localparam  H_SYNC_TIME 		= 32;  // ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 80;  // ���������ʱ��                                 
localparam  V_ACTIVE 		= 1050;// ��������Чʱ��
localparam  V_FRONT_PORCH 	= 3;   // ������ǰ��ʱ��
localparam  V_SYNC_TIME  	= 6;   // ��ͬ���ź�ʱ��
localparam  V_BACK_PORCH 	= 21;  // ���������ʱ��
`endif

//1280x1024 108Mhz
`ifdef  COLOR_VIDEO_1280_1024
localparam  H_ACTIVE 		= 1280;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 48;  // ������ǰ��ʱ��
localparam  H_SYNC_TIME 		= 112; // ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 248; // ���������ʱ��                                   
localparam  V_ACTIVE 		= 1024;// ��������Чʱ��
localparam  V_FRONT_PORCH 	= 1;   // ������ǰ��ʱ��
localparam  V_SYNC_TIME  	= 3;   // ��ͬ���ź�ʱ��
localparam  V_BACK_PORCH 	= 38;  // ���������ʱ��
`endif

//1280X720 74.25MHZ
`ifdef  COLOR_VIDEO_1280_720
localparam  H_ACTIVE 		= 640;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 110; // ������ǰ��ʱ��
localparam  H_SYNC_TIME 		= 40;  // ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 220; // ���������ʱ��    
localparam  H_POLARITY       = 1;   // ��ͬ������                                    
localparam  V_ACTIVE 		= 720; // ��������Чʱ��
localparam  V_FRONT_PORCH 	= 5;   // ������ǰ��ʱ��
localparam  V_SYNC_TIME  	= 5;   // ��ͬ���ź�ʱ��
localparam  V_BACK_PORCH 	= 20;  // ���������ʱ��
localparam  V_POLARITY       = 1;   // ��ͬ������
`endif

//1024x768 65Mhz
`ifdef  COLOR_VIDEO_1024_768
localparam  H_ACTIVE 		= 1024;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 24;  // ������ǰ��ʱ��
localparam  H_SYNC_TIME 		= 136; // ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 160; // ���������ʱ��                                       
localparam  V_ACTIVE 		= 768; // ��������Чʱ��
localparam  V_FRONT_PORCH 	= 3;   // ������ǰ��ʱ��
localparam  V_SYNC_TIME  	= 6;   // ��ͬ���ź�ʱ��
localparam  V_BACK_PORCH 	= 29;  // ���������ʱ��
`endif

//800x600 40Mhz
`ifdef  COLOR_VIDEO_800_600
localparam  H_ACTIVE 		= 800;// ��������Чʱ��
localparam  H_FRONT_PORCH 	= 40 ;// ������ǰ��ʱ�� 
localparam  H_SYNC_TIME 		= 128;// ��ͬ���ź�ʱ��
localparam  H_BACK_PORCH 	= 88 ;// ���������ʱ��                                       
localparam  V_ACTIVE 		= 600;// ��������Чʱ��
localparam  V_FRONT_PORCH 	= 1  ;// ������ǰ��ʱ��  
localparam  V_SYNC_TIME  	= 4  ;// ��ͬ���ź�ʱ��  
localparam  V_BACK_PORCH 	= 23 ;// ���������ʱ�� 
`endif

//640x480 25.175Mhz
`ifdef  COLOR_VIDEO_640_480
localparam H_ACTIVE 			= 640; // ��������Чʱ��
localparam H_FRONT_PORCH 	= 16 ; // ������ǰ��ʱ��
localparam H_SYNC_TIME 		= 96 ; // ��ͬ���ź�ʱ��
localparam H_BACK_PORCH 		= 48 ; // ���������ʱ��
localparam H_POLARITY        = 0;   // ��ͬ������								 
localparam V_ACTIVE 			= 480; // ��������Чʱ��
localparam V_FRONT_PORCH 	= 10 ; // ������ǰ��ʱ��
localparam V_SYNC_TIME 		= 2	 ; // ��ͬ���ź�ʱ��
localparam V_BACK_PORCH 		= 33 ; // ���������ʱ��
localparam V_POLARITY        = 0;   // ��ͬ������
`endif

localparam  H_TOTAL_TIME 	= H_ACTIVE + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH; 
localparam  V_TOTAL_TIME 	= V_ACTIVE + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH;

assign o_h_dis = H_ACTIVE;
assign o_v_dis = V_ACTIVE;
assign o_data_req = (o_y_pos>VIDEO_START_Y) && (o_y_pos<=VIDEO_START_Y+VIDEO_V) && (o_x_pos>VIDEO_START_X) && (o_x_pos<=VIDEO_START_X+VIDEO_H) ;

reg [12:0] 	h_syn_cnt;
reg [12:0] 	v_syn_cnt;
reg r_hs;
reg r_vs;
reg r_de;
reg r_data_req;
wire p_vs;
wire n_de;
wire p_de;
assign p_de=~o_de&&r_de;
//assign p_de=~r_data_req&&o_data_req;
assign p_vs=~o_vs&&r_vs;

always@(posedge i_clk) begin
	if(~i_rst_n) begin
		o_hs<='d0;
		o_vs<='d0;
		o_de<='d0;	
        r_data_req<='d0;
	end
	else begin
		o_hs<=r_hs;
		o_vs<=r_vs;
		o_de<=r_de;
        r_data_req<=o_data_req;			
	end
end

assign o_rgb= o_data_req? i_rgb: 24'd0;

// ��ɨ�������
always@(posedge i_clk) begin
	if(~i_rst_n) h_syn_cnt <= 0;
	else if(h_syn_cnt == H_TOTAL_TIME) h_syn_cnt <= 0;
    else h_syn_cnt <= h_syn_cnt + 1;
end

// ��ɨ�������
always@(posedge i_clk) begin
	if(~i_rst_n) v_syn_cnt <= 0;
	else if(h_syn_cnt == H_TOTAL_TIME)
	begin
        if(v_syn_cnt == V_TOTAL_TIME) v_syn_cnt <= 0;
        else v_syn_cnt <= v_syn_cnt + 1;
	end
end

// ��ͬ������
always@(posedge i_clk) begin
    if(h_syn_cnt < H_SYNC_TIME) r_hs <= H_POLARITY;
    else r_hs <= ~H_POLARITY;
end

// ��ͬ������
always@(posedge i_clk) begin
    if(v_syn_cnt < V_SYNC_TIME) r_vs <= V_POLARITY;
    else r_vs <= ~V_POLARITY;
end

// ����ʹ��.
always@(posedge i_clk) begin
    if(v_syn_cnt >= V_SYNC_TIME + V_BACK_PORCH && v_syn_cnt < V_SYNC_TIME + V_BACK_PORCH + V_ACTIVE)
    begin
        if(h_syn_cnt >= H_SYNC_TIME + H_BACK_PORCH && 
		h_syn_cnt < H_SYNC_TIME + H_BACK_PORCH + H_ACTIVE) r_de <= 1;
        else r_de <= 0;
    end
    else r_de <= 0;
end

always@(posedge i_clk) begin
	if(~i_rst_n) o_x_pos <= 0;
	else if(r_de) o_x_pos<=o_x_pos+1'b1;
	else o_x_pos <= 0;
end

always@(posedge i_clk) begin
	if(~i_rst_n) o_y_pos <= 0;
	else if(p_vs) o_y_pos <= 0; 
	else if(p_de) o_y_pos <= o_y_pos+1'b1;
end

endmodule
