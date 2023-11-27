
module PDS_HDMA #(
	parameter HDMA_PINGPANG_EN = 1 ,	// 1-->�������Ҳ���,ͼ����֡����, 0-->�رձ��Ҳ���,ͼ��һ֡����
	parameter VIDEO_DATA_BIT   = 32		// ������Ƶ����λ��,����ѡ��32,Ҳ����ѡ��16
)(  
    // ����������Ƶ�ӿ�	
    input                        i_video_1_pclk   ,//��һ·������Ƶ����ʱ��   
    input                        i_video_1_vs     ,//��һ·������Ƶ��ͬ���ź�	
    input                        i_video_1_de     ,//��һ·������Ƶ������Ч�ź�
    input   [VIDEO_DATA_BIT-1:0] i_video_1_data   ,//��һ·������Ƶ�����ź� {8'h00,24'hRGB}		
    input                        i_video_2_pclk   ,//�ڶ�·������Ƶ����ʱ��   
    input                        i_video_2_vs     ,//�ڶ�·������Ƶ��ͬ���ź�	
    input                        i_video_2_de     ,//�ڶ�·������Ƶ������Ч�ź�
    input   [VIDEO_DATA_BIT-1:0] i_video_2_data   ,//�ڶ�·������Ƶ�����ź� {8'h00,24'hRGB}
    input                        i_video_out_pclk ,//�����Ƶ����ʱ�� 	
    input                        i_video_out_vs   ,//�����Ƶ��ͬ���ź�	
    input                        i_video_out_de   ,//�����Ƶ������Ч�ź�  
    output  [VIDEO_DATA_BIT-1:0] o_video_out_data ,//�����Ƶ�����ź� {8'h00,24'hRGB}
	input   [12:0]               h_disp           ,//HDMI��ˮƽ�ֱ���
    // ��Ƶ�����ַ���ú� DDR3 ��ʼ��
    input   [27:0]               app_addr_rd_min  ,//��ddr3����ʼ��ַ
    input   [27:0]               app_addr_rd_max  ,//��ddr3�Ľ�����ַ
    input   [7:0]                rd_bust_len      ,//��ddr3�ж�����ʱ��ͻ������
    input   [27:0]               app_addr_wr_min  ,//��ddr3����ʼ��ַ
    input   [27:0]               app_addr_wr_max  ,//��ddr3�Ľ�����ַ
    input   [7:0]                wr_bust_len      ,//��ddr3�ж�����ʱ��ͻ������
    input                        ddr3_read_valid  ,//DDR3 ��ʹ�� 	
    input                        ddr_init_done    ,//DDR��ʼ�����
    output                       fram_done        ,//DDR���Ѿ�����һ֡�����־	
	// AXI4-FULL 128 BIT
    input                        axi_clk          , // AXI CLK
    input                        rst_n            ,//�ⲿ��λ����	
    output [28-1:0]              axi_awaddr       , //д��ַ
    output [3:0   ]              axi_awlen        , //дͻ������
    output [2:0   ]              axi_awsize       , //дͻ����С
    output [1:0   ]              axi_awburst      , //дͻ������
    output                       axi_awlock       , //д��������
    input                        axi_awready      , //д��ַ׼���ź�
    output                       axi_awvalid      , //д��ַ��Ч�ź�
    output                       axi_awurgent     , //д�����ź�,1:Write addressָ������ִ��
    output                       axi_awpoison     , //д�����ź�,1:Write addressָ����Ч
    output [15:0  ]              axi_wstrb        , //дѡͨ
    output                       axi_wvalid       , //д������Ч�ź�
    input                        axi_wready       , //д����׼���ź�
    output                       axi_wlast        , //���һ��д�ź�
    output [128-1:0]             axi_wdata        ,
    output                       axi_bready       , //д��Ӧ׼���ź�
    output [28-1:0]              axi_araddr       , //����ַ
    output [3:0   ]              axi_arlen        , //��ͻ������
    output [2:0   ]              axi_arsize       , //��ͻ����С
    output [1:0   ]              axi_arburst      , //��ͻ������
    output                       axi_arlock       , //����������
    output                       axi_arpoison     , //�������ź�,1:Read addressָ����Ч
    output                       axi_arurgent     , //�������ź�,1:Read addressָ������ִ��
    input                        axi_arready      , //����ַ׼���ź�
    output                       axi_arvalid      , //����ַ��Ч�ź�
    input                        axi_rlast        , //���һ�ζ��ź�
    input                        axi_rvalid       , //��������Ч�ź�
    output                       axi_rready       , //������׼���ź�
    input [128-1:0]              axi_rdata
   );

    wire [10:0]       wfifo_rcount_1  ;//rfifoʣ�����ݼ���
    wire [10:0]       rfifo_wcount_1  ;//wfifoд�����ݼ���
	wire [10:0]       wfifo_rcount_2  ;//rfifoʣ�����ݼ���
    wire [10:0]       rfifo_wcount_2  ;//wfifoд�����ݼ���
    wire              wrfifo_en_ctrl  ;//дFIFO���ݶ�ʹ�ܿ���λ
    wire              wfifo_rden_1    ;//дFIFO���ݶ�ʹ��
    wire              pre_wfifo_rden_1;//дFIFO����Ԥ��ʹ��
    wire              wfifo_rden_2    ;//дFIFO���ݶ�ʹ��
    wire              pre_wfifo_rden_2;//дFIFO����Ԥ��ʹ��
    wire              axi_rvalid_2    ;
    wire              axi_rvalid_1    ;	

//*****************************************************
//**                    main code
//*****************************************************

//��ΪԤ����һ���������Զ�ʹ��wfifo_rdenҪ��һ������ͨ��wrfifo_en_ctrl����
assign wfifo_rden_1 = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) && wr_opera_en_1;
assign pre_wfifo_rden_1 = axi_awvalid && axi_awready && wr_opera_en_1;
assign wfifo_rden_2 = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) && ~wr_opera_en_1;
assign pre_wfifo_rden_2 = axi_awvalid && axi_awready && ~wr_opera_en_1;
assign axi_rvalid_2 = ~rd_opera_en_1 ? axi_rvalid : 0;
assign axi_rvalid_1 =  rd_opera_en_1 ? axi_rvalid : 0;

 PDS_DDR3_WR #(
	.HDMA_PINGPANG_EN (HDMA_PINGPANG_EN),	// 1-->�������Ҳ���,ͼ����֡����, 0-->�رձ��Ҳ���,ͼ��һ֡����
	.VIDEO_DATA_BIT   (VIDEO_DATA_BIT  )		// ������Ƶ����λ��,����ѡ��32,Ҳ����ѡ��16
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
	.VIDEO_DATA_BIT(VIDEO_DATA_BIT  )	// ������Ƶ����λ��,����ѡ��32,Ҳ����ѡ��16
)u_HDMA_fifo_ctrl_top(
    .rst_n              (rst_n &&ddr_init_done           ), //��λ�ź�    
    .rd_clk             (i_video_out_pclk                ), //rfifoʱ��
    .clk_100            (axi_clk                         ), //�û�ʱ��
    //fifo1�ӿ��ź�     
    .wr_clk_1           (i_video_1_pclk                  ), //wfifoʱ��    
    .datain_valid_1     (i_video_1_de                    ), //������Чʹ���ź�
    .datain_1           (i_video_1_data                  ), //��Ч����
    .wr_load_1          (i_video_1_vs                    ), //����Դ���ź�    
    .rfifo_din_1        (axi_rdata                       ), //�û�������
    .rfifo_wren_1       (axi_rvalid_1                    ), //��ddr3�������ݵ���Чʹ��
    .wfifo_rden_1       (wfifo_rden_1 || pre_wfifo_rden_1), //wfifo��ʹ��
    .wfifo_rcount_1     (wfifo_rcount_1                  ), //wfifoʣ�����ݼ���
    .rfifo_wcount_1     (rfifo_wcount_1                  ), //rfifoд�����ݼ��� 
    .wr_opera_en_2      (wr_opera_en_2                   ),	
    //fifo2�ӿ��ź�     
    .wr_clk_2           (i_video_2_pclk                  ), //wfifoʱ��    
    .datain_valid_2     (i_video_2_de                    ), //������Чʹ���ź�
    .datain_2           (i_video_2_data                  ), //��Ч����    
    .wr_load_2          (i_video_2_vs                    ), //����Դ���ź�
    .rfifo_din_2        (axi_rdata                       ), //�û�������
    .rfifo_wren_2       (axi_rvalid_2                    ), //��ddr3�������ݵ���Чʹ��
    .wfifo_rden_2       (wfifo_rden_2 || pre_wfifo_rden_2), //wfifo��ʹ��    
    .wfifo_rcount_2     (wfifo_rcount_2                  ), //wfifoʣ�����ݼ���
    .rfifo_wcount_2     (rfifo_wcount_2                  ), //rfifoд�����ݼ���				                                 
    .h_disp             (h_disp                          ),
    .rd_load            (i_video_out_vs                  ), //���Դ���ź�
    .rdata_req          (i_video_out_de                  ), //�������ص���ɫ��������     
    .pic_data           (o_video_out_data                ), //��Ч����  
    .wfifo_dout         (axi_wdata                       )  //�û�д����    
    );	
   
endmodule