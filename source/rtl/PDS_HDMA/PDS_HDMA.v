
module PDS_HDMA #(
	parameter HDMA_PINGPANG_EN = 1 ,	// 1-->开启兵乓操作,图像三帧缓存, 0-->关闭兵乓操作,图像一帧缓存
	parameter VIDEO_DATA_BIT   = 32		// 输入视频数据位宽,这里选择32,也可以选择16
)(  
    // 输入和输出视频接口	
    input                        i_video_1_pclk   ,//第一路输入视频像素时钟   
    input                        i_video_1_vs     ,//第一路输入视频场同步信号	
    input                        i_video_1_de     ,//第一路输入视频数据有效信号
    input   [VIDEO_DATA_BIT-1:0] i_video_1_data   ,//第一路输入视频数据信号 {8'h00,24'hRGB}		
    input                        i_video_2_pclk   ,//第二路输入视频像素时钟   
    input                        i_video_2_vs     ,//第二路输入视频场同步信号	
    input                        i_video_2_de     ,//第二路输入视频数据有效信号
    input   [VIDEO_DATA_BIT-1:0] i_video_2_data   ,//第二路输入视频数据信号 {8'h00,24'hRGB}
    input                        i_video_out_pclk ,//输出视频像素时钟 	
    input                        i_video_out_vs   ,//输出视频场同步信号	
    input                        i_video_out_de   ,//输出视频数据有效信号  
    output  [VIDEO_DATA_BIT-1:0] o_video_out_data ,//输出视频数据信号 {8'h00,24'hRGB}
	input   [12:0]               h_disp           ,//HDMI屏水平分辨率
    // 视频缓存地址配置和 DDR3 初始化
    input   [27:0]               app_addr_rd_min  ,//读ddr3的起始地址
    input   [27:0]               app_addr_rd_max  ,//读ddr3的结束地址
    input   [7:0]                rd_bust_len      ,//从ddr3中读数据时的突发长度
    input   [27:0]               app_addr_wr_min  ,//读ddr3的起始地址
    input   [27:0]               app_addr_wr_max  ,//读ddr3的结束地址
    input   [7:0]                wr_bust_len      ,//从ddr3中读数据时的突发长度
    input                        ddr3_read_valid  ,//DDR3 读使能 	
    input                        ddr_init_done    ,//DDR初始化完成
    output                       fram_done        ,//DDR中已经存入一帧画面标志	
	// AXI4-FULL 128 BIT
    input                        axi_clk          , // AXI CLK
    input                        rst_n            ,//外部复位输入	
    output [28-1:0]              axi_awaddr       , //写地址
    output [3:0   ]              axi_awlen        , //写突发长度
    output [2:0   ]              axi_awsize       , //写突发大小
    output [1:0   ]              axi_awburst      , //写突发类型
    output                       axi_awlock       , //写锁定类型
    input                        axi_awready      , //写地址准备信号
    output                       axi_awvalid      , //写地址有效信号
    output                       axi_awurgent     , //写紧急信号,1:Write address指令优先执行
    output                       axi_awpoison     , //写抑制信号,1:Write address指令无效
    output [15:0  ]              axi_wstrb        , //写选通
    output                       axi_wvalid       , //写数据有效信号
    input                        axi_wready       , //写数据准备信号
    output                       axi_wlast        , //最后一次写信号
    output [128-1:0]             axi_wdata        ,
    output                       axi_bready       , //写回应准备信号
    output [28-1:0]              axi_araddr       , //读地址
    output [3:0   ]              axi_arlen        , //读突发长度
    output [2:0   ]              axi_arsize       , //读突发大小
    output [1:0   ]              axi_arburst      , //读突发类型
    output                       axi_arlock       , //读锁定类型
    output                       axi_arpoison     , //读抑制信号,1:Read address指令无效
    output                       axi_arurgent     , //读紧急信号,1:Read address指令优先执行
    input                        axi_arready      , //读地址准备信号
    output                       axi_arvalid      , //读地址有效信号
    input                        axi_rlast        , //最后一次读信号
    input                        axi_rvalid       , //读数据有效信号
    output                       axi_rready       , //读数据准备信号
    input [128-1:0]              axi_rdata
   );

    wire [10:0]       wfifo_rcount_1  ;//rfifo剩余数据计数
    wire [10:0]       rfifo_wcount_1  ;//wfifo写进数据计数
	wire [10:0]       wfifo_rcount_2  ;//rfifo剩余数据计数
    wire [10:0]       rfifo_wcount_2  ;//wfifo写进数据计数
    wire              wrfifo_en_ctrl  ;//写FIFO数据读使能控制位
    wire              wfifo_rden_1    ;//写FIFO数据读使能
    wire              pre_wfifo_rden_1;//写FIFO数据预读使能
    wire              wfifo_rden_2    ;//写FIFO数据读使能
    wire              pre_wfifo_rden_2;//写FIFO数据预读使能
    wire              axi_rvalid_2    ;
    wire              axi_rvalid_1    ;	

//*****************************************************
//**                    main code
//*****************************************************

//因为预读了一个数据所以读使能wfifo_rden要少一个周期通过wrfifo_en_ctrl控制
assign wfifo_rden_1 = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) && wr_opera_en_1;
assign pre_wfifo_rden_1 = axi_awvalid && axi_awready && wr_opera_en_1;
assign wfifo_rden_2 = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) && ~wr_opera_en_1;
assign pre_wfifo_rden_2 = axi_awvalid && axi_awready && ~wr_opera_en_1;
assign axi_rvalid_2 = ~rd_opera_en_1 ? axi_rvalid : 0;
assign axi_rvalid_1 =  rd_opera_en_1 ? axi_rvalid : 0;

 PDS_DDR3_WR #(
	.HDMA_PINGPANG_EN (HDMA_PINGPANG_EN),	// 1-->开启兵乓操作,图像三帧缓存, 0-->关闭兵乓操作,图像一帧缓存
	.VIDEO_DATA_BIT   (VIDEO_DATA_BIT  )		// 输入视频数据位宽,这里选择32,也可以选择16
)u_PDS_DDR3_WR(
    .clk             (axi_clk        ),
    .rst_n           (rst_n          ),
    .ddr_init_done   (ddr_init_done  ),
    .axi_awaddr      (axi_awaddr     ),
    .axi_awlen       (axi_awlen      ),
    .axi_awsize      (axi_awsize     ),
    .axi_awburst     (axi_awburst    ),
    .axi_awlock      (axi_awlock     ),
    .axi_awready     (axi_awready    ),
    .axi_awvalid     (axi_awvalid    ),
    .axi_awurgent    (axi_awurgent   ),
    .axi_awpoison    (axi_awpoison   ),
    .axi_wstrb       (axi_wstrb      ),
    .axi_wvalid      (axi_wvalid     ),
    .axi_wready      (axi_wready     ),
    .axi_wlast       (axi_wlast      ),
    .axi_bready      (axi_bready     ),
    .axi_araddr      (axi_araddr     ),
    .axi_arlen       (axi_arlen      ),
    .axi_arsize      (axi_arsize     ),
    .axi_arburst     (axi_arburst    ),
    .axi_arlock      (axi_arlock     ),
    .axi_arpoison    (axi_arpoison   ),
    .axi_arurgent    (axi_arurgent   ),
    .axi_arready     (axi_arready    ),
    .axi_arvalid     (axi_arvalid    ),
    .axi_rlast       (axi_rlast      ),
    .axi_rvalid      (axi_rvalid     ),
    .axi_rready      (axi_rready     ),
    .fram_done       (fram_done      ),
    .wrfifo_en_ctrl  (wrfifo_en_ctrl ),	
    .wfifo_rcount_1  (wfifo_rcount_1 ),
    .rfifo_wcount_1  (rfifo_wcount_1 ),
    .i_video_1_vs    (i_video_1_vs   ),
    .wfifo_rcount_2  (wfifo_rcount_2 ),
    .rfifo_wcount_2  (rfifo_wcount_2 ),
    .i_video_2_vs    (i_video_2_vs   ),	
	.rd_opera_en_1   (rd_opera_en_1  ),
	.wr_opera_en_1   (wr_opera_en_1  ),
	.wr_opera_en_2   (wr_opera_en_2  ),	
    .i_video_out_vs  (i_video_out_vs ),
    .app_addr_rd_min (app_addr_rd_min),
    .app_addr_rd_max (app_addr_rd_max),
    .rd_bust_len     (rd_bust_len    ),
    .app_addr_wr_min (app_addr_wr_min),
    .app_addr_wr_max (app_addr_wr_max),
    .wr_bust_len     (wr_bust_len    ),
    .ddr3_read_valid (ddr3_read_valid)
    );

HDMA_fifo_ctrl_top #(
	.VIDEO_DATA_BIT(VIDEO_DATA_BIT  )	// 输入视频数据位宽,这里选择32,也可以选择16
)u_HDMA_fifo_ctrl_top(
    .rst_n              (rst_n &&ddr_init_done           ), //复位信号    
    .rd_clk             (i_video_out_pclk                ), //rfifo时钟
    .clk_100            (axi_clk                         ), //用户时钟
    //fifo1接口信号     
    .wr_clk_1           (i_video_1_pclk                  ), //wfifo时钟    
    .datain_valid_1     (i_video_1_de                    ), //数据有效使能信号
    .datain_1           (i_video_1_data                  ), //有效数据
    .wr_load_1          (i_video_1_vs                    ), //输入源场信号    
    .rfifo_din_1        (axi_rdata                       ), //用户读数据
    .rfifo_wren_1       (axi_rvalid_1                    ), //从ddr3读出数据的有效使能
    .wfifo_rden_1       (wfifo_rden_1 || pre_wfifo_rden_1), //wfifo读使能
    .wfifo_rcount_1     (wfifo_rcount_1                  ), //wfifo剩余数据计数
    .rfifo_wcount_1     (rfifo_wcount_1                  ), //rfifo写进数据计数 
    .wr_opera_en_2      (wr_opera_en_2                   ),	
    //fifo2接口信号     
    .wr_clk_2           (i_video_2_pclk                  ), //wfifo时钟    
    .datain_valid_2     (i_video_2_de                    ), //数据有效使能信号
    .datain_2           (i_video_2_data                  ), //有效数据    
    .wr_load_2          (i_video_2_vs                    ), //输入源场信号
    .rfifo_din_2        (axi_rdata                       ), //用户读数据
    .rfifo_wren_2       (axi_rvalid_2                    ), //从ddr3读出数据的有效使能
    .wfifo_rden_2       (wfifo_rden_2 || pre_wfifo_rden_2), //wfifo读使能    
    .wfifo_rcount_2     (wfifo_rcount_2                  ), //wfifo剩余数据计数
    .rfifo_wcount_2     (rfifo_wcount_2                  ), //rfifo写进数据计数				                                 
    .h_disp             (h_disp                          ),
    .rd_load            (i_video_out_vs                  ), //输出源场信号
    .rdata_req          (i_video_out_de                  ), //请求像素点颜色数据输入     
    .pic_data           (o_video_out_data                ), //有效数据  
    .wfifo_dout         (axi_wdata                       )  //用户写数据    
    );	
   
endmodule