`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-03-17  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
//cmos1��cmos2��ѡһ����Ϊ��ƵԴ����
// `define CMOS_1      //cmos1��Ϊ��Ƶ���룻
// `define CMOS_2      //cmos2��Ϊ��Ƶ���룻
// `define COLOR

module hdmi_ddr_ov5640_top#(
	parameter MEM_ROW_ADDR_WIDTH   = 15         ,
	parameter MEM_COL_ADDR_WIDTH   = 10         ,
	parameter MEM_BADDR_WIDTH      = 3          ,
	parameter MEM_DQ_WIDTH         =  32        ,
	parameter MEM_DQS_WIDTH        =  32/8
)(
	input                                sys_clk              ,//50Mhz
//OV5647
    output  [1:0]                        cmos_init_done       ,//OV5640�Ĵ�����ʼ�����?
    //coms1	
    inout                                cmos1_scl            ,//cmos1 i2c 
    inout                                cmos1_sda            ,//cmos1 i2c 
    input                                cmos1_vsync          ,//cmos1 vsync
    input                                cmos1_href           ,//cmos1 hsync refrence,data valid
    input                                cmos1_pclk           ,//cmos1 pxiel clock
    input   [7:0]                        cmos1_data           ,//cmos1 data
    output                               cmos1_reset          ,//cmos1 reset
    //coms2
    inout                                cmos2_scl            ,//cmos2 i2c 
    inout                                cmos2_sda            ,//cmos2 i2c 
    input                                cmos2_vsync          ,//cmos2 vsync
    input                                cmos2_href           ,//cmos2 hsync refrence,data valid
    input                                cmos2_pclk           ,//cmos2 pxiel clock
    input   [7:0]                        cmos2_data           ,//cmos2 data
    output                               cmos2_reset          ,//cmos2 reset
//DDR
    output                               mem_rst_n                 ,
    output                               mem_ck                    ,
    output                               mem_ck_n                  ,
    output                               mem_cke                   ,
    output                               mem_cs_n                  ,
    output                               mem_ras_n                 ,
    output                               mem_cas_n                 ,
    output                               mem_we_n                  ,
    output                               mem_odt                   ,
    output      [MEM_ROW_ADDR_WIDTH-1:0] mem_a                     ,
    output      [MEM_BADDR_WIDTH-1:0]    mem_ba                    ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs                   ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs_n                 ,
    inout       [MEM_DQ_WIDTH-1:0]       mem_dq                    ,
    output      [MEM_DQ_WIDTH/8-1:0]     mem_dm                    ,
    output reg                           heart_beat_led            ,
    output                               ddr_init_done             ,
//MS72xx       
    output                               rstn_out                  ,
    output                               iic_tx_scl                ,
    inout                                iic_tx_sda                ,
    output                               iic_scl,
    inout                                iic_sda, 
    output                               hdmi_int_led              ,//HDMI_OUT��ʼ�����?
//HDMI_OUT
    output                               pix_clk                   ,//pixclk                           
    output     reg                       vs_out                    , 
    output     reg                       hs_out                    , 
    output     reg                       de_out                    ,
    output     reg[7:0]                  r_out                     , 
    output     reg[7:0]                  g_out                     , 
    output     reg[7:0]                  b_out         ,
// HDMI_IN
    input                                pix_clk_in,                            
    input                                vs_in, 
    input                                hs_in, 
    input                                de_in,
    input     [7:0]                      r_in, 
    input     [7:0]                      g_in, 
    input     [7:0]                      b_in,
// KEY
    input                                key_gamma,
    input                                key_saturation,
    input                                key_rotate,
    // input                                key_scaler,
    input                                key_scaler_width,
    input                                key_scaler_height,
    input                                key_color_reverse,
    input                                key_panning_y,
//Ethernet
    output                               led,
    output                               phy_rstn,

    input                                rgmii_rxc,
    input                                rgmii_rx_ctl,
    input     [3:0]                      rgmii_rxd,
                 
    output                               rgmii_txc,
    output                               rgmii_tx_ctl,
    output    [3:0]                      rgmii_txd
    
);
/////////////////////////////////////////////////////////////////////////////////////
// ENABLE_DDR
    parameter CTRL_ADDR_WIDTH = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH;//28
    parameter TH_1S = 27'd33000000;
/////////////////////////////////////////////////////////////////////////////////////
    reg  [15:0]                 rstn_1ms            ;
    wire                        cmos_scl            ;//cmos i2c clock
    wire                        cmos_sda            ;//cmos i2c data
    wire                        cmos_vsync          ;//cmos vsync
    wire                        cmos_href           ;//cmos hsync refrence,data valid
    wire                        cmos_pclk           ;//cmos pxiel clock
    wire   [7:0]                cmos_data           ;//cmos data
    wire                        cmos_reset          ;//cmos reset
    wire                        initial_en          ;
    wire[15:0]                  cmos1_d_16bit       ;
    wire                        cmos1_href_16bit    ;
    wire                        cmos1_vsync_16bit    ;
    reg [7:0]                   cmos1_d_d0          ;
    reg                         cmos1_href_d0       ;
    reg                         cmos1_vsync_d0      ;
    wire                        cmos1_pclk_16bit    ;
    wire[15:0]                  cmos2_d_16bit       /*synthesis PAP_MARK_DEBUG="1"*/;
    wire                        cmos2_href_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
    wire                        cmos2_vsync_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
    reg [7:0]                   cmos2_d_d0          /*synthesis PAP_MARK_DEBUG="1"*/;
    reg                         cmos2_href_d0       /*synthesis PAP_MARK_DEBUG="1"*/;
    reg                         cmos2_vsync_d0      /*synthesis PAP_MARK_DEBUG="1"*/;
    wire                        cmos2_pclk_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
    wire[15:0]                  o_rgb565            ;
    // wire                        pclk_in_test        ;    
    // wire                        vs_in_test          ;
    // wire                        de_in_test          ;
    // wire[15:0]                  i_rgb565            ;
    wire                        de_re               ;
    wire                        hdmi_pclk           ;    
    wire                        hdmi_vs             ;
    wire                        hdmi_de             ;
    wire [23:0]                 hdmi_rgb            ;
    wire [23:0]                 video_rgb                  ;
    wire                        video_vs                   ;
    wire                        video_de                   ;
//axi bus   
    wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr                 ;
    wire                        axi_awuser_ap              ;
    wire [3:0]                  axi_awuser_id              ;
    wire [3:0]                  axi_awlen                  ;
    wire                        axi_awready                ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire                        axi_awvalid                ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
    wire [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb                  ;
    wire                        axi_wready                 ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [3:0]                  axi_wusero_id              ;
    wire                        axi_wusero_last            ;
    wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr                 ;
    wire                        axi_aruser_ap              ;
    wire [3:0]                  axi_aruser_id              ;
    wire [3:0]                  axi_arlen                  ;
    wire                        axi_arready                ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire                        axi_arvalid                ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata                   /* synthesis syn_keep = 1 */;
    wire                        axi_rvalid                  /* synthesis syn_keep = 1 */;
    wire [3:0]                  axi_rid                    ;
    wire                        axi_rlast                  ;
    reg  [26:0]                 cnt                        ;
    reg  [15:0]                 cnt_1                      ;
    wire [3:0]                  num                        ;
    wire                        num_vld                    ;
    wire                        clk_200m                   ;
    wire                        clk_125m                   ;
    wire  [1:0]                 gamma_ctrl                 ;
    wire                        saturation_ctrl             ;
    wire                        rotate_ctrl                 ;
    // wire                     scaler_ctrl                 ;
    wire   [5:0]                scaler_ctrl_width           ;
    wire   [6:0]                scaler_ctrl_height          ;
    wire                        color_reverse_ctrl          ;
    wire    [5:0]               panning_y_ctrl              ;
/////////////////////////////////////////////////////////////////////////////////////
//PLL
    pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pix_clk    ),//74.25M 640*720@30
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .clkout3  (  clk_200m   ),
        .clkout4  (  clk_125m   ),
        .pll_lock (  locked     )
    );

//����7210
    ms72xx_ctl ms72xx_ctl(
        .clk             (  cfg_clk        ), //input       clk,
        .rst_n           (  rstn_out       ), //input       rstn,
        .init_over_tx    (  init_over_tx   ), //output      init_over,                                
        .init_over_rx    (  init_over_rx   ), //output      init_over,
        .iic_tx_scl      (  iic_tx_scl     ), //output      iic_scl,
        .iic_tx_sda      (  iic_tx_sda     ), //inout       iic_sda
        .iic_scl         (  iic_scl        ), //output      iic_scl,
        .iic_sda         (  iic_sda        )  //inout       iic_sda
    );
   assign    hdmi_int_led    =    init_over_tx; 
    
    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms <= 16'd0;
    	else
    	begin
    		if(rstn_1ms == 16'h2710)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 16'h2710);

    // ����
    video_block_move #(
    .H_DISP            (640)        ,  //video h
    .V_DISP            (720)        ,  //video v
    .VIDEO_CLK         (76500000)   ,  //video clk
    .BLOCK_CLK         (100)        ,  //move block clk
    .SIDE_W            (40)         ,  //screen side size
    .BLOCK_W           (80)         ,  //move block size
    .SCREEN_SIDE_COLOR (24'hff00ff) ,   //screen side color
    .SCREEN_BKG_COLOR  (24'hffffff) ,   //screen background color
    .MOVE_BLOCK_COLOR  (24'hffffff)  //move block color
    ) video_block_move (
        .pixel_clk (pix_clk),
        .sys_rst_n (rstn_out),
        .video_hs  (video_hs),
        .video_vs  (video_vs),
        .video_de  (video_de),
        .video_rgb(video_rgb)
    );

//����CMOS///////////////////////////////////////////////////////////////////////////////////
//OV5640 register configure enable    
    power_on_delay	power_on_delay_inst(
    	.clk_50M                 (sys_clk        ),//input
    	.reset_n                 (1'b1           ),//input	
    	.camera1_rstn            (cmos1_reset    ),//output
    	.camera2_rstn            (cmos2_reset    ),//output	
    	.camera_pwnd             (               ),//output
    	.initial_en              (initial_en     ) //output		
    );
//CMOS1 Camera 
    reg_config #(
    .DISPAY_H(640),
    .DISPAY_V(722)
    )	coms1_reg_config  (
    	.clk_25M                 (clk_25M            ),//input
    	.camera_rstn             (cmos1_reset        ),//input
    	.initial_en              (initial_en         ),//input		
    	.i2c_sclk                (cmos1_scl          ),//output
    	.i2c_sdat                (cmos1_sda          ),//inout
    	.reg_conf_done           (cmos_init_done[0]  ),//output config_finished
    	.reg_index               (                   ),//output reg [8:0]
    	.clock_20k               (                   ) //output reg
    );

//CMOS2 Camera 
    reg_config	#(
    .DISPAY_H(640),
    .DISPAY_V(722)
    ) coms2_reg_config(
    	.clk_25M                 (clk_25M            ),//input
    	.camera_rstn             (cmos2_reset        ),//input
    	.initial_en              (initial_en         ),//input		
    	.i2c_sclk                (cmos2_scl          ),//output
    	.i2c_sdat                (cmos2_sda          ),//inout
    	.reg_conf_done           (cmos_init_done[1]  ),//output config_finished
    	.reg_index               (                   ),//output reg [8:0]
    	.clock_20k               (                   ) //output reg
    );
//CMOS 8bitת16bit///////////////////////////////////////////////////////////////////////////////////
//CMOS1
    always@(posedge cmos1_pclk)
        begin
            cmos1_d_d0        <= cmos1_data    ;
            cmos1_href_d0     <= cmos1_href    ;
            cmos1_vsync_d0    <= cmos1_vsync   ;
        end

    wire [15:0] pdata_1;
    wire de_1, vs_1;
    cmos_8_16bit cmos1_8_16bit(
    	.pclk           (cmos1_pclk       ),//input
    	.rst_n          (cmos_init_done[0]),//input
    	.pdata_i        (cmos1_d_d0       ),//input[7:0]
    	.de_i           (cmos1_href_d0    ),//input
    	.vs_i           (cmos1_vsync_d0    ),//input
    	
    	.pixel_clk      (cmos1_pclk_16bit ),//output
    	.pdata_o        (pdata_1  ),//output[15:0]
    	.de_o           (de_1 ), //output
        .vs_o           (vs_1)
    );
    cmos_mix #(
        .H_ACT  (12'd320),
        .H_OFFSET (12'd319),
        .LEFT  (1'b1)
    ) cmos1_mix(
        .pixel_clk (cmos1_pclk_16bit)  ,    // input                 pixel_clk    ,
        .de_i	   (de_1)    ,	// input				   de_i	        ,
        .pdata_i	(pdata_1)    ,	// input	[15:0]	       pdata_i	    ,
        .vs_i      (vs_1)  ,    // input                  vs_i         ,
        .gamma_ctrl (gamma_ctrl),
        .saturation_ctrl (saturation_ctrl),

        .de_o      (cmos1_href_16bit)  , 	// output	reg			   de_o         ,
        .pdata_o   (cmos1_d_16bit)  ,	// output  reg [15:0]	   pdata_o      ,
        .vs_o      (cmos1_vsync_16bit)     // output  reg            vs_o
    );
//CMOS2
    always@(posedge cmos2_pclk)
        begin
            cmos2_d_d0        <= cmos2_data    ;
            cmos2_href_d0     <= cmos2_href    ;
            cmos2_vsync_d0    <= cmos2_vsync   ;
        end

    wire [15:0] pdata_2;
    wire de_2, vs_2;
    cmos_8_16bit cmos2_8_16bit(
    	.pclk           (cmos2_pclk       ),//input
    	.rst_n          (cmos_init_done[1]),//input
    	.pdata_i        (cmos2_d_d0       ),//input[7:0]
    	.de_i           (cmos2_href_d0    ),//input
    	.vs_i           (cmos2_vsync_d0    ),//input
    	
    	.pixel_clk      (cmos2_pclk_16bit ),//output
    	.pdata_o        (pdata_2    ),//output[15:0]
    	.de_o           (de_2 ), //output
        .vs_o           (vs_2)
    );
    cmos_mix #(
        .H_ACT  (12'd320),
        .H_OFFSET (12'd319),
        .LEFT  (1'b0)
    ) cmos2_mix(
        .pixel_clk (cmos2_pclk_16bit)  ,    // input                 pixel_clk    ,
        .de_i	   (de_2)    ,	// input				   de_i	        ,
        .pdata_i	(pdata_2)    ,	// input	[15:0]	       pdata_i	    ,
        .vs_i      (vs_2)  ,    // input                  vs_i         ,
        .gamma_ctrl (gamma_ctrl),
        .saturation_ctrl (saturation_ctrl),

        .de_o      (cmos2_href_16bit)  , 	// output	reg			   de_o         ,
        .pdata_o   (cmos2_d_16bit)  ,	// output  reg [15:0]	   pdata_o      ,
        .vs_o      (cmos2_vsync_16bit)     // output  reg            vs_o
    );

// HDMI
    hdmi_in hdmi_in (
    .pixclk_in(pix_clk_in),                // input pixclk_in,
    .init_over_tx(init_over_tx),                // input init_over_tx,
    .vs_in(vs_in),                // input vs_in,
    .hs_in(hs_in),                // input hs_in,
    .de_in(de_in),                // input de_in,
    . r_in(r_in),                // input [7:0] r_in,
    . g_in(g_in),                // input [7:0] g_in,
    . b_in(b_in),                 // input [7:0] b_in,
    .scaler_ctrl_width(scaler_ctrl_width), 
    .scaler_ctrl_height(scaler_ctrl_height), 
    .color_reverse_ctrl(color_reverse_ctrl), 
    .panning_y_ctrl(panning_y_ctrl), 
    // .scaler_ctrl(scaler_ctrl), 
    .vs_out(hdmi_vs),                // output reg vs_out,
    .hs_out(),                // output reg hs_out,
    .de_out(hdmi_de),                // output reg de_out,
    .data_out(hdmi_rgb)                // output reg [23:0] r_out,
    );

    assign hdmi_pclk = pix_clk_in;
//������ƵԴѡ��//////////////////////////////////////////////////////////////////////////////////////////
// `ifdef CMOS_1
// assign     pclk_in_test    =    cmos1_pclk_16bit    ;
// assign     vs_in_test      =    cmos1_vsync_d0      ;
// assign     de_in_test      =    cmos1_href_16bit    ;
// assign     i_rgb565        =    {cmos1_d_16bit[4:0],cmos1_d_16bit[10:5],cmos1_d_16bit[15:11]};//{r,g,b}
// `elsif CMOS_2
// assign     pclk_in_test    =    cmos2_pclk_16bit    ;
// assign     vs_in_test      =    cmos2_vsync_d0      ;
// assign     de_in_test      =    cmos2_href_16bit    ;
// assign     i_rgb565        =    {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]};//{r,g,b}
// `elsif COLOR
// assign     pclk_in_test    =    pix_clk;
// assign     vs_in_test      =    video_vs;
// assign     de_in_test      =    video_de;
// assign     i_rgb565        =    {video_rgb[23:19],video_rgb[15:10],video_rgb[7:3]};
// `endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//�޸�ddr��дģ��v1
    fram_buf fram_buf(
        .ddr_clk        (  core_clk             ),//input                         ddr_clk,
        .ddr_rstn       (  ddr_init_done        ),//input                         ddr_rstn,
        //data_in                                  
        .vin_clk1        (  cmos1_pclk_16bit         ),//input                         vin_clk,
        .wr_fsync1       (  cmos1_vsync_16bit           ),//input                         wr_fsync,
        .wr_en1          (  cmos1_href_16bit           ),//input                         wr_en,
        .wr_data1        (  {cmos1_d_16bit[4:0],cmos1_d_16bit[10:5],cmos1_d_16bit[15:11]} ),//input  [15 : 0]  wr_data,
        .vin_clk2        (  hdmi_pclk         ),//input                         vin_clk,
        .wr_fsync2       (  hdmi_vs           ),//input                         wr_fsync,
        .wr_en2          (  hdmi_de           ),//input                         wr_en,
        .wr_data2        (  {hdmi_rgb[23:19],hdmi_rgb[15:10],hdmi_rgb[7:3]} ),//input  [15 : 0]  wr_data,
        .vin_clk3        (  cmos2_pclk_16bit         ),//input                         vin_clk,
        .wr_fsync3       (  cmos2_vsync_16bit           ),//input                         wr_fsync,
        .wr_en3          (  cmos2_href_16bit           ),//input                         wr_en,
        .wr_data3        (  {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]} ),//input  [15 : 0]  wr_data,
        //data_out
        .vout_clk       (  pix_clk              ),//input                         vout_clk,
        .rd_fsync       (  vs_o               ),//input                         rd_fsync,
        .rd_en          (  de_re                ),//input                         rd_en,
        .vout_de        (  de_o               ),//output                        vout_de,
        .vout_data      (  o_rgb565             ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
        .init_done      (  init_done            ),//output reg                    init_done,
        //axi bus
        .axi_awaddr     (  axi_awaddr           ),// output[27:0]
        .axi_awid       (  axi_awuser_id        ),// output[3:0]
        .axi_awlen      (  axi_awlen            ),// output[3:0]
        .axi_awsize     (                       ),// output[2:0]
        .axi_awburst    (                       ),// output[1:0]
        .axi_awready    (  axi_awready          ),// input
        .axi_awvalid    (  axi_awvalid          ),// output               
        .axi_wdata      (  axi_wdata            ),// output[255:0]
        .axi_wstrb      (  axi_wstrb            ),// output[31:0]
        .axi_wlast      (  axi_wusero_last      ),// input
        .axi_wvalid     (                       ),// output
        .axi_wready     (  axi_wready           ),// input
        .axi_bid        (  4'd0                 ),// input[3:0]
        .axi_araddr     (  axi_araddr           ),// output[27:0]
        .axi_arid       (  axi_aruser_id        ),// output[3:0]
        .axi_arlen      (  axi_arlen            ),// output[3:0]
        .axi_arsize     (                       ),// output[2:0]
        .axi_arburst    (                       ),// output[1:0]
        .axi_arvalid    (  axi_arvalid          ),// output
        .axi_arready    (  axi_arready          ),// input
        .axi_rready     (                       ),// output
        .axi_rdata      (  axi_rdata            ),// input[255:0]
        .axi_rvalid     (  axi_rvalid           ),// input
        .axi_rlast      (  axi_rlast            ),// input
        .axi_rid        (  axi_rid              ), // input[3:0] 
        .num            (  num                  ),//input  [3:0]      
        .num_vld        (  num_vld              ),//input
        .rotate_ctrl    (  rotate_ctrl         )
    );

     always@(posedge pix_clk) begin
        r_out<={o_rgb565[15:11],3'b0};
        g_out<={o_rgb565[10:5],2'b0};
        b_out<={o_rgb565[4:0],3'b0}; 
        vs_out<=vs_o;
        hs_out<=hs_o;
        de_out<=de_o;
     end
/////////////////////////////////////////////////////////////////////////////////////
//����visaʱ�� 
     sync_vg sync_vg(                            
        .clk            (  pix_clk              ),//input                   clk,                                 
        .rstn           (  init_done            ),//input                   rstn,                            
        .vs_out         (  vs_o                 ),//output reg              vs_out,                                                                                                                                      
        .hs_out         (  hs_o                 ),//output reg              hs_out,            
        .de_out         (                       ),//output reg              de_out, 
        .de_re          (  de_re                )    
    );  
////////////////////////////////////////////////////////////////////////////////////////////
//ddr    
        DDR3_50H u_DDR3_50H (
             .ref_clk                   (sys_clk            ),
             .resetn                    (rstn_out           ),// input
             .ddr_init_done             (ddr_init_done      ),// output
             .ddrphy_clkin              (core_clk           ),// output
             .pll_lock                  (pll_lock           ),// output

             .axi_awaddr                (axi_awaddr         ),// input [27:0]
             .axi_awuser_ap             (1'b0               ),// input
             .axi_awuser_id             (axi_awuser_id      ),// input [3:0]
             .axi_awlen                 (axi_awlen          ),// input [3:0]
             .axi_awready               (axi_awready        ),// output
             .axi_awvalid               (axi_awvalid        ),// input
             .axi_wdata                 (axi_wdata          ),
             .axi_wstrb                 (axi_wstrb          ),// input [31:0]
             .axi_wready                (axi_wready         ),// output
             .axi_wusero_id             (                   ),// output [3:0]
             .axi_wusero_last           (axi_wusero_last    ),// output
             .axi_araddr                (axi_araddr         ),// input [27:0]
             .axi_aruser_ap             (1'b0               ),// input
             .axi_aruser_id             (axi_aruser_id      ),// input [3:0]
             .axi_arlen                 (axi_arlen          ),// input [3:0]
             .axi_arready               (axi_arready        ),// output
             .axi_arvalid               (axi_arvalid        ),// input
             .axi_rdata                 (axi_rdata          ),// output [255:0]
             .axi_rid                   (axi_rid            ),// output [3:0]
             .axi_rlast                 (axi_rlast          ),// output
             .axi_rvalid                (axi_rvalid         ),// output

             .apb_clk                   (1'b0               ),// input
             .apb_rst_n                 (1'b1               ),// input
             .apb_sel                   (1'b0               ),// input
             .apb_enable                (1'b0               ),// input
             .apb_addr                  (8'b0               ),// input [7:0]
             .apb_write                 (1'b0               ),// input
             .apb_ready                 (                   ), // output
             .apb_wdata                 (16'b0              ),// input [15:0]
             .apb_rdata                 (                   ),// output [15:0]
             .apb_int                   (                   ),// output

             .mem_rst_n                 (mem_rst_n          ),// output
             .mem_ck                    (mem_ck             ),// output
             .mem_ck_n                  (mem_ck_n           ),// output
             .mem_cke                   (mem_cke            ),// output
             .mem_cs_n                  (mem_cs_n           ),// output
             .mem_ras_n                 (mem_ras_n          ),// output
             .mem_cas_n                 (mem_cas_n          ),// output
             .mem_we_n                  (mem_we_n           ),// output
             .mem_odt                   (mem_odt            ),// output
             .mem_a                     (mem_a              ),// output [14:0]
             .mem_ba                    (mem_ba             ),// output [2:0]
             .mem_dqs                   (mem_dqs            ),// inout [3:0]
             .mem_dqs_n                 (mem_dqs_n          ),// inout [3:0]
             .mem_dq                    (mem_dq             ),// inout [31:0]
             .mem_dm                    (mem_dm             ),// output [3:0]
             //debug
             .debug_data                (                   ),// output [135:0]
             .debug_slice_state         (                   ),// output [51:0]
             .debug_calib_ctrl          (                   ),// output [21:0]
             .ck_dly_set_bin            (                   ),// output [7:0]
             .force_ck_dly_en           (1'b0               ),// input
             .force_ck_dly_set_bin      (8'h05              ),// input [7:0]
             .dll_step                  (                   ),// output [7:0]
             .dll_lock                  (                   ),// output
             .init_read_clk_ctrl        (2'b0               ),// input [1:0]
             .init_slip_step            (4'b0               ),// input [3:0]
             .force_read_clk_ctrl       (1'b0               ),// input
             .ddrphy_gate_update_en     (1'b0               ),// input
             .update_com_val_err_flag   (                   ),// output [3:0]
             .rd_fake_stop              (1'b0               ) // input
       );

//�����ź�
     always@(posedge core_clk) begin
        if (!ddr_init_done)
            cnt <= 27'd0;
        else if ( cnt >= TH_1S )
            cnt <= 27'd0;
        else
            cnt <= cnt + 27'd1;
     end

     always @(posedge core_clk)
        begin
        if (!ddr_init_done)
            heart_beat_led <= 1'd1;
        else if ( cnt >= TH_1S )
            heart_beat_led <= ~heart_beat_led;
    end

    key_ctl#(
        .CNT_WIDTH(4'd2),
        .CNT_MAX  (4'd2)
    ) key_ctl_gamma(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_gamma),// input           key,    
        .ctrl(gamma_ctrl) //output     [1:0] ctrl
    );

    key_ctl#(
        .CNT_WIDTH(4'd1),
        .CNT_MAX  (4'd1)
    ) key_ctl_saturation(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_saturation),// input           key,    
        .ctrl(saturation_ctrl) //output     [1:0] ctrl
    );

    key_ctl#(
        .CNT_WIDTH(4'd1),
        .CNT_MAX  (4'd1)
    ) key_ctl_rotate(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_rotate),// input           key,    
        .ctrl(rotate_ctrl) //output     [1:0] ctrl
    );
    // scaler_ctrl
    // key_ctl#(
    //     .CNT_WIDTH(4'd1),
    //     .CNT_MAX  (4'd1)
    // ) key_ctl_scaler(
    //     .clk (sys_clk),// input           clk,//50MHz
    //     .key (key_scaler),// input           key,    
    //     .ctrl(scaler_ctrl) //output     [1:0] ctrl
    // );

    // ?????
    // ???100
    key_ctl#(
        .CNT_WIDTH('d6),
        .CNT_MAX  ('d62)
    ) key_ctl_scaler_width(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_scaler_width),// input           key,    
        .ctrl(scaler_ctrl_width) //output     [1:0] ctrl
    );

    // ?????
    // ???100
    key_ctl#(
        .CNT_WIDTH('d7),
        .CNT_MAX  ('d70)
    ) key_ctl_scaler_height(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_scaler_height),// input           key,    
        .ctrl(scaler_ctrl_height) //output     [1:0] ctrl
    );

    key_ctl#(
        .CNT_WIDTH('d1),
        .CNT_MAX  ('d1)
    ) key_ctl_color_reverse(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_color_reverse),// input           key,    
        .ctrl(color_reverse_ctrl) //output     [1:0] ctrl
    );

    key_ctl#(
        .CNT_WIDTH('d6),
        .CNT_MAX  ('d36)
    ) key_ctl_panning_y(
        .clk (sys_clk),// input           clk,//50MHz
        .key (key_panning_y),// input           key,    
        .ctrl(panning_y_ctrl) //output     [1:0] ctrl
    );

    ethernet_test ethernet_test(
        .clk_200m(clk_200m),    // input        clk_200m,
        .clk_125m(clk_125m),    // input        clk_125m,
        .rstn(locked),    // input        rstn,
        .led(led),    // output reg   led,
        .phy_rstn(phy_rstn),    // output       phy_rstn,

        .rgmii_rxc(rgmii_rxc),    // input        rgmii_rxc,
        .rgmii_rx_ctl(rgmii_rx_ctl),    // input        rgmii_rx_ctl,
        .rgmii_rxd(rgmii_rxd),    // input [3:0]  rgmii_rxd,
                
        .rgmii_txc(rgmii_txc),    // output       rgmii_txc,
        .rgmii_tx_ctl(rgmii_tx_ctl),    // output       rgmii_tx_ctl,
        .rgmii_txd(rgmii_txd),    // output [3:0] rgmii_txd,

        .num(num),    // output reg [3:0] num,
        .num_vld(num_vld)       // output reg num_vld = 1'b0;     
    );
                 
/////////////////////////////////////////////////////////////////////////////////////
endmodule
