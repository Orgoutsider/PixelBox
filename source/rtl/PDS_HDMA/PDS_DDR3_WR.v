`timescale 1ps/1ps
	
module PDS_DDR3_WR #(
	parameter HDMA_PINGPANG_EN = 1 ,	// 1-->�������Ҳ���,ͼ����֡����, 0-->�رձ��Ҳ���,ͼ��һ֡����
	parameter VIDEO_DATA_BIT   = 32		// ������Ƶ����λ��,����ѡ��32,Ҳ����ѡ��16
)(
    input                 clk              , //ʱ��
    input                 rst_n            , //��λ
    input                 ddr_init_done    , //DDR��ʼ�����
    output reg  [28-1:0]  axi_awaddr       , //д��ַ
    output reg  [3:0   ]  axi_awlen        , //дͻ������
    output wire [2:0   ]  axi_awsize       , //дͻ����С
    output wire [1:0   ]  axi_awburst      , //дͻ������
    output                axi_awlock       , //д��������
    input                 axi_awready      , //д��ַ׼���ź�
    output reg            axi_awvalid      , //д��ַ��Ч�ź�
    output                axi_awurgent     , //д�����ź�,1:Write addressָ������ִ��
    output                axi_awpoison     , //д�����ź�,1:Write addressָ����Ч
    output wire [15:0  ]  axi_wstrb        , //дѡͨ
    output reg            axi_wvalid       , //д������Ч�ź�
    input                 axi_wready       , //д����׼���ź�
    output reg            axi_wlast        , //���һ��д�ź�
    output wire           axi_bready       , //д��Ӧ׼���ź�
    output reg  [28-1:0]  axi_araddr       , //����ַ
    output reg  [3:0   ]  axi_arlen        , //��ͻ������
    output wire [2:0   ]  axi_arsize       , //��ͻ����С
    output wire [1:0   ]  axi_arburst      , //��ͻ������
    output wire           axi_arlock       , //����������
    output wire           axi_arpoison     , //�������ź�,1:Read addressָ����Ч
    output wire           axi_arurgent     , //�������ź�,1:Read addressָ������ִ��
    input                 axi_arready      , //����ַ׼���ź�
    output reg            axi_arvalid      , //����ַ��Ч�ź�
    input                 axi_rlast        , //���һ�ζ��ź�
    input                 axi_rvalid       , //��������Ч�ź�
    output wire           axi_rready       , //������׼���ź�
    output reg            wrfifo_en_ctrl   , //дFIFO���ݶ�ʹ�ܿ���λ
    output reg            fram_done        ,
	
    input       [10:0  ]  wfifo_rcount_1   , //д�˿�FIFO�е�������
    input       [10:0  ]  rfifo_wcount_1   , //���˿�FIFO�е�������
    input                 i_video_1_vs     , //����Դ�����ź�
    input       [10:0  ]  wfifo_rcount_2   , //д�˿�FIFO�е�������
    input       [10:0  ]  rfifo_wcount_2   , //���˿�FIFO�е�������
    input                 i_video_2_vs     , //����Դ�����ź�	
	output                rd_opera_en_1,
	output                wr_opera_en_1,
	output                wr_opera_en_2,		
	
    input                 i_video_out_vs   , //���Դ�����ź�	
    input       [27:0  ]  app_addr_rd_min  , //��DDR3����ʼ��ַ
    input       [27:0  ]  app_addr_rd_max  , //��DDR3�Ľ�����ַ
    input       [7:0   ]  rd_bust_len      , //��DDR3�ж�����ʱ��ͻ������
    input       [27:0  ]  app_addr_wr_min  , //дDDR3����ʼ��ַ
    input       [27:0  ]  app_addr_wr_max  , //дDDR3�Ľ�����ַ
    input       [7:0   ]  wr_bust_len      , //��DDR3��д����ʱ��ͻ������
    input                 ddr3_read_valid    //DDR3 ��ʹ��   
);

//localparam define
localparam IDLE          = 10'b00_0000_0001; //����״̬
localparam DDR3_DONE     = 10'b00_0000_0010; //DDR3��ʼ�����״̬
localparam WRITE_ADDR_1  = 10'b00_0000_0100; //дԴ1��ַ
localparam WRITE_DATA_1  = 10'b00_0000_1000; //дԴ1����
localparam READ_ADDR_1   = 10'b00_0001_0000; //��Դ1��ַ
localparam READ_DATA_1   = 10'b00_0010_0000; //��Դ1����
localparam WRITE_ADDR_2  = 10'b00_0100_0000; //дԴ2��ַ
localparam WRITE_DATA_2  = 10'b00_1000_0000; //дԴ2����
localparam READ_ADDR_2   = 10'b01_0000_0000; //��Դ2��ַ
localparam READ_DATA_2   = 10'b10_0000_0000; //��Դ2����

//reg define
reg        init_start    ; //��ʼ������ź�
reg        wr_end_1_d0   ;
reg        wr_end_1_d1   ;
reg        rd_end_1_d0   ;
reg        rd_end_1_d1   ;
reg        wr_end_2_d0   ;
reg        wr_end_2_d1   ;
reg        rd_end_2_d0   ;
reg        rd_end_2_d1   ;
reg [27:0] axi_awaddr_n_1; //д��ַ����
reg [27:0] axi_awaddr_n_2; //д��ַ����
reg [27:0] axi_awaddr_n  ; //д��ַ����
reg        wr_end_1      ; //һ��ͻ��д�����ź�
reg [31:0] init_addr_1   ; //ͻ�����ȼ�����
reg [9:0 ] lenth_cnt_1   ; //��ͻ��д���Ƚ��м���
reg [27:0] axi_araddr_n_1; //����ַ����
reg        rd_end_1      ; //һ��ͻ���������ź�
reg        raddr_page_1  ; //ddr3����ַ�л��ź�
reg        waddr_page_1  ; //ddr3д��ַ�л��ź�
reg        wr_end_2      ; //һ��ͻ��д�����ź�
reg [31:0] init_addr_2   ; //ͻ�����ȼ�����
reg [9:0 ] lenth_cnt_2   ; //��ͻ��д���Ƚ��м���
reg [27:0] axi_araddr_n_2; //����ַ����
reg        rd_end_2      ; //һ��ͻ���������ź�
reg        raddr_page_2  ; //ddr3����ַ�л��ź�
reg        waddr_page_2  ; //ddr3д��ַ�л��ź�
reg        rd_load_d0    ;
reg        rd_load_d1    ;
reg        wr_load_1_d0  ;
reg        wr_load_1_d1  ;
reg        wr_load_2_d0  ;
reg        wr_load_2_d1  ;
reg        wr_rst_1      ; //����Դ֡��λ��־
reg        wr_rst_2      ; //����Դ֡��λ��־
reg        rd_rst        ; //���Դ֡��λ��־
reg        raddr_rst_h   ; //���Դ��֡��λ����
reg [9:0 ] state_cnt     ; //״̬������
reg [3:0 ] axi_awlen_1   ; //дͻ������
reg        axi_wvalid_1    ; //д������Ч�ź�	
reg        axi_awvalid_1   ; //д��ַ��Ч�ź�	
reg        axi_wlast_1     ; //���һ��д�ź�	
reg [3:0 ] axi_arlen_1     ; //��ͻ������
reg        axi_arvalid_1   ; //����ַ��Ч�ź�
reg        wrfifo_en_ctrl_1; //дFIFO���ݶ�ʹ�ܿ���λ
reg        fram_done_1     ;
reg [3:0 ] axi_awlen_2     ; //дͻ������
reg        axi_wvalid_2    ; //д������Ч�ź�	
reg        axi_awvalid_2   ; //д��ַ��Ч�ź�	
reg        axi_wlast_2     ; //���һ��д�ź�	
reg [3:0 ] axi_arlen_2     ; //��ͻ������
reg        axi_arvalid_2   ; //����ַ��Ч�ź�
reg        wrfifo_en_ctrl_2; //дFIFO���ݶ�ʹ�ܿ���λ
reg        fram_done_2     ;
reg        rd_opera_en_1   ;
reg        rd_opera_en_2   ;
reg        wr_opera_en_1   ;
reg        wr_opera_en_2   ;

//wire define
wire      wr_end_1_r     ;
wire      rd_end_1_r     ;
wire      wr_end_2_r     ;
wire      rd_end_2_r     ;
wire[9:0] lenth_cnt_max  ; //���ͻ������

//*****************************************************
//**                    main code
//*****************************************************

assign  axi_awlock   = 1'b0      ;
assign  axi_awurgent = 1'b0      ;
assign  axi_awpoison = 1'b0      ;
assign  axi_bready   = 1'b1      ;
assign  axi_wstrb    = {16{1'b1}};
assign  axi_awsize   = 3'b100    ;
assign  axi_awburst  = 2'd1      ;
assign  axi_arlock   = 1'b0      ;
assign  axi_arurgent = 1'b0      ;
assign  axi_arpoison = 1'b0      ;
assign  axi_arsize   = 3'b100    ;
assign  axi_arburst  = 2'd1      ;
assign  axi_rready   = 1'b1      ;

//��/д�����ź�������
assign wr_end_1_r=wr_end_1_d0&&(~wr_end_1_d1);
assign wr_end_2_r=wr_end_2_d0&&(~wr_end_2_d1);
assign rd_end_1_r=rd_end_1_d0&&(~rd_end_1_d1);
assign rd_end_2_r=rd_end_2_d0&&(~rd_end_2_d1);

//�������ͻ������
//assign lenth_cnt_max = app_addr_wr_max / (wr_bust_len * 8);
assign lenth_cnt_max = app_addr_wr_max / (wr_bust_len *(128/VIDEO_DATA_BIT));

//�ȶ�ddr3��ʼ���ź�
always @(posedge clk) begin
    if (!rst_n) init_start <= 1'b0;
    else if (ddr_init_done) init_start <= ddr_init_done;
    else init_start <= init_start;
end

//д��ַƹ�Ҳ���
always @(*) begin
    if (HDMA_PINGPANG_EN) begin
	    if(wr_opera_en_1) axi_awaddr <= {1'b0,waddr_page_1,axi_awaddr_n_1[24:0],1'b0};
		else axi_awaddr <= {1'b1,waddr_page_2,axi_awaddr_n_2[24:0],1'b0};
	end
    else if(wr_opera_en_1) axi_awaddr <= {2'b0,axi_awaddr_n_1[24:0],1'b0};
	else axi_awaddr <= {2'b0,axi_awaddr_n_2[24:0],1'b0};	
end

//����ַƹ�Ҳ���
always @(*) begin
    if (HDMA_PINGPANG_EN) begin
	    if(rd_opera_en_1) axi_araddr <= {1'b0,raddr_page_1,axi_araddr_n_1[24:0],1'b0};
		else axi_araddr <= {1'b1,raddr_page_2,axi_araddr_n_2[24:0],1'b0};
	end
    else if(rd_opera_en_1) axi_araddr <= {2'b0,axi_araddr_n_1[24:0],1'b0};
	else axi_araddr <= {2'b0,axi_araddr_n_2[24:0],1'b0};	
end

//���첽�źŽ��д��Ĵ���
always @(posedge clk) begin
    if(!rst_n)begin
        wr_end_1_d0<= 0;
        wr_end_1_d1<= 0;
        wr_end_2_d0<= 0;
        wr_end_2_d1<= 0;		
        rd_end_1_d0<= 0;
        rd_end_1_d1<= 0;
        rd_end_2_d0<= 0;
        rd_end_2_d1<= 0;		
    end   
    else begin
        wr_end_1_d0<= wr_end_1;
        wr_end_1_d1<= wr_end_1_d0;
        wr_end_2_d0<= wr_end_2;
        wr_end_2_d1<= wr_end_2_d0;		
        rd_end_1_d0<= rd_end_1;
        rd_end_1_d1<= rd_end_1_d0;
        rd_end_2_d0<= rd_end_2;
        rd_end_2_d1<= rd_end_2_d0;		
    end
end

//���˿�1����ʹ�� 
always @(posedge clk) begin
    if(!rst_n || rd_rst) rd_opera_en_1 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) rd_opera_en_1 <= 0;
        else if(state_cnt == READ_ADDR_1) rd_opera_en_1 <= 1; 
        else rd_opera_en_1 <= rd_opera_en_1;         
    end    
end 

//���˿�2����ʹ�� 
always @(posedge clk) begin
    if(!rst_n || rd_rst) rd_opera_en_2 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) rd_opera_en_2 <= 0;
        else if(state_cnt == READ_ADDR_2) rd_opera_en_2 <= 1; 
        else rd_opera_en_2 <= rd_opera_en_2;         
    end    
end 

//д�˿�1����ʹ�� 
always @(posedge clk) begin
    if(!rst_n || wr_rst_1) wr_opera_en_1 <= 0;      
    else begin
        if(state_cnt == DDR3_DONE) wr_opera_en_1 <= 0;
        else if(state_cnt == WRITE_ADDR_1) wr_opera_en_1 <= 1; 
        else wr_opera_en_1 <= wr_opera_en_1;         
    end    
end 

//д�˿�2����ʹ�� 
always @(posedge clk) begin
    if(!rst_n || wr_rst_2) wr_opera_en_2 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) wr_opera_en_2 <= 0;
        else if(state_cnt == WRITE_ADDR_2) wr_opera_en_2 <= 1; 
        else wr_opera_en_2 <= wr_opera_en_2;         
    end    
end 

//��д�˿ڵ�ddr�ӿڽ����л�
always @(*)  begin
    if(wr_opera_en_1)begin
        axi_awlen    <= axi_awlen_1;
        axi_awvalid  <= axi_awvalid_1;
		wrfifo_en_ctrl <= wrfifo_en_ctrl_1;
        axi_wlast  <= axi_wlast_1;
        axi_wvalid <= axi_wvalid_1;			
    end   
    else begin
        axi_awlen    <= axi_awlen_2;
        axi_awvalid  <= axi_awvalid_2; 
		wrfifo_en_ctrl <= wrfifo_en_ctrl_2;
        axi_wvalid <= axi_wvalid_2;
        axi_wlast  <= axi_wlast_2;				
    end    
end 

//�Զ��˿ڵ�ddr�ӿڽ����л�
always @(*)  begin
    if(rd_opera_en_1)begin
		axi_arlen    <= axi_arlen_1;
		axi_arvalid  <= axi_arvalid_1;	
    end   
    else begin
		axi_arlen    <= axi_arlen_2;
		axi_arvalid  <= axi_arvalid_2;		
    end    
end 

//д��ַ1ģ��
always @(posedge clk) begin
    if (!rst_n) begin
        axi_awaddr_n_1 <= app_addr_wr_min;
        axi_awlen_1    <= 4'b0;
        axi_awvalid_1  <= 1'b0;
        wr_end_1       <= 1'b0;
    end
    else if(wr_rst_1) begin
        axi_awaddr_n_1 <= app_addr_wr_min;
        wr_end_1 <= 1'b0;
    end 
    else if(init_start) begin
        axi_awlen_1 <= wr_bust_len - 1'b1;
        if (axi_awaddr_n_1 < {app_addr_wr_max , 1'b0} - wr_bust_len * 16) begin
            wr_end_1 <= 1'b0;
            if(axi_awvalid_1 && axi_awready)begin
                axi_awvalid_1 <= 1'b0;
                axi_awaddr_n_1 <= axi_awaddr_n_1 + wr_bust_len * 16;//wr_bust_len*128/8
            end
            else if(state_cnt == WRITE_ADDR_1 && axi_awready)begin
                axi_awvalid_1 <= 1'b1;
                wr_end_1 <= 1'b0;
            end
        end
        else if(axi_awaddr_n_1 == {app_addr_wr_max , 1'b0} - wr_bust_len * 16) begin
            if(axi_awvalid_1 && axi_awready) begin
                axi_awvalid_1 <= 1'b0;
                axi_awaddr_n_1 <= app_addr_wr_min;//wr_bust_len*128/8 
                wr_end_1 <= 1'b1;
            end
            else if(state_cnt == WRITE_ADDR_1 && axi_awready) axi_awvalid_1 <= 1'b1;
        end
        else axi_awvalid_1 <= 1'b0;
    end 
    else begin
        axi_awaddr_n_1   <= axi_awaddr_n_1;
        axi_awlen_1      <= 4'b0;
        axi_awvalid_1    <= 1'b0;
    end
end

//д��ַ2ģ��
always @(posedge clk) begin
    if (!rst_n) begin
        axi_awaddr_n_2 <= app_addr_wr_min;
        axi_awlen_2    <= 4'b0;
        axi_awvalid_2  <= 1'b0;
        wr_end_2       <= 1'b0;
    end
    else if(wr_rst_2)begin
        axi_awaddr_n_2 <= app_addr_wr_min;
        wr_end_2 <= 1'b0;
    end 
    else if(init_start) begin
        axi_awlen_2 <= wr_bust_len - 1'b1;
        if (axi_awaddr_n_2 < {app_addr_wr_max , 1'b0} - wr_bust_len * 16) begin
            wr_end_2 <= 1'b0;
            if(axi_awvalid_2 && axi_awready)begin
                axi_awvalid_2 <= 1'b0;
                axi_awaddr_n_2 <= axi_awaddr_n_2 + wr_bust_len * 16;//wr_bust_len*128/8
            end
            else if(state_cnt == WRITE_ADDR_2 && axi_awready)begin
                axi_awvalid_2 <= 1'b1;
                wr_end_2 <= 1'b0;
            end
        end
        else if(axi_awaddr_n_2 == {app_addr_wr_max , 1'b0} - wr_bust_len * 16) begin
            if(axi_awvalid_2 && axi_awready) begin
                axi_awvalid_2 <= 1'b0;
                axi_awaddr_n_2 <= app_addr_wr_min;//wr_bust_len*128/8 
                wr_end_2 <= 1'b1;
            end
            else if(state_cnt == WRITE_ADDR_2 && axi_awready) axi_awvalid_2 <= 1'b1;
        end
        else axi_awvalid_2 <= 1'b0;
    end 
    else begin
        axi_awaddr_n_2   <= axi_awaddr_n_2;
        axi_awlen_2      <= 4'b0;
        axi_awvalid_2    <= 1'b0;
    end
end

//д����1ģ��
always @(posedge clk) begin
    if (!rst_n) begin
        axi_wvalid_1 <= 1'b0    ;
        axi_wlast_1  <= 1'b0    ;
        init_addr_1  <= 32'd0   ; 
        lenth_cnt_1  <= 10'd0   ;
    end
    else begin
        if(init_start) begin
		    if(wr_rst_1)begin
				init_addr_1 <= 0;
				wrfifo_en_ctrl_1 <= 1'b0;
                axi_wlast_1  <= 1'b0;
                axi_wvalid_1 <= 1'b0;
                lenth_cnt_1 <= 0;				
			end 
            else if(lenth_cnt_1 < lenth_cnt_max)begin
                if(axi_wvalid_1 && axi_wready && init_addr_1 < wr_bust_len - 2'd2) begin
                    init_addr_1 <= init_addr_1 + 1'b1;
                    wrfifo_en_ctrl_1 <= 1'b0;
                end
                else if(axi_wvalid_1 && axi_wready && init_addr_1 == wr_bust_len - 2'd2) begin
                    axi_wlast_1  <= 1'b1;
                    wrfifo_en_ctrl_1<= 1'b1;
                    init_addr_1  <= init_addr_1 + 1'b1;
                end
                else if(axi_wvalid_1 && axi_wready && init_addr_1 == wr_bust_len - 2'd1) begin
                    axi_wvalid_1 <= 1'b0;
                    axi_wlast_1  <= 1'b0;
                    wrfifo_en_ctrl_1 <= 1'b0;
                    lenth_cnt_1  <= lenth_cnt_1+1'b1;
                    init_addr_1  <= 32'd0;
                end
                else if(state_cnt == WRITE_DATA_1 && axi_wready) axi_wvalid_1 <= 1'b1;
                else lenth_cnt_1 <= lenth_cnt_1;
            end
            else begin
                axi_wvalid_1 <= 1'b0   ;
                axi_wlast_1  <= 1'b0   ;
                init_addr_1  <= init_addr_1;
                lenth_cnt_1  <= 10'd0;
            end
        end
        else begin
            axi_wvalid_1 <= 1'b0   ;
            axi_wlast_1  <= 1'b0   ;
            init_addr_1  <= 32'd0;
            lenth_cnt_1  <= 8'd0   ;
        end
    end
end

//д����2ģ��
always @(posedge clk) begin
    if (!rst_n) begin
        axi_wvalid_2 <= 1'b0    ;
        axi_wlast_2  <= 1'b0    ;
        init_addr_2  <= 32'd0 ; 
        lenth_cnt_2  <= 10'd0   ;
    end
    else begin
        if(init_start) begin
		    if(wr_rst_2) begin
				init_addr_2 <= 0;
				wrfifo_en_ctrl_2 <= 1'b0;
                axi_wvalid_2 <= 1'b0;
                axi_wlast_2  <= 1'b0;
                lenth_cnt_2 <= 0;				
			end 		
            else if(lenth_cnt_2 < lenth_cnt_max) begin
                if(axi_wvalid_2 && axi_wready && init_addr_2 < wr_bust_len - 2'd2) begin
                    init_addr_2 <= init_addr_2 + 1'b1;
                    wrfifo_en_ctrl_2 <= 1'b0;
                end
                else if(axi_wvalid_2 && axi_wready && init_addr_2 == wr_bust_len - 2'd2) begin
                    axi_wlast_2  <= 1'b1;
                    wrfifo_en_ctrl_2<= 1'b1;
                    init_addr_2  <= init_addr_2 + 1'b1;
                end
                else if(axi_wvalid_2 && axi_wready && init_addr_2 == wr_bust_len - 2'd1) begin
                    axi_wvalid_2 <= 1'b0;
                    axi_wlast_2  <= 1'b0;
                    wrfifo_en_ctrl_2 <= 1'b0;
                    lenth_cnt_2  <= lenth_cnt_2+1'b1;
                    init_addr_2  <= 32'd0;
                end
                else if(state_cnt == WRITE_DATA_2 && axi_wready) axi_wvalid_2 <= 1'b1;
                else lenth_cnt_2 <= lenth_cnt_2;
            end
            else begin
                axi_wvalid_2 <= 1'b0   ;
                axi_wlast_2  <= 1'b0   ;
                init_addr_2  <= init_addr_2;
                lenth_cnt_2  <= 10'd0;
                
            end
        end
        else begin
            axi_wvalid_2 <= 1'b0   ;
            axi_wlast_2  <= 1'b0   ;
            init_addr_2  <= 32'd0;
            lenth_cnt_2  <= 8'd0   ;
        end
    end
end

//����ַ1ģ��
always @(posedge clk) begin
    if (!rst_n) begin
		axi_araddr_n_1 <= app_addr_rd_min;
		axi_arlen_1    <= 4'b0;
		axi_arvalid_1  <= 1'b0;
		rd_end_1       <= 1'b0;
    end
    else if(raddr_rst_h) axi_araddr_n_1 <= app_addr_rd_min;
    else if(init_start) begin
        axi_arlen_1 <= rd_bust_len - 1'b1;
        if (axi_araddr_n_1 < {app_addr_rd_max , 1'b0} - rd_bust_len * 16) begin
            rd_end_1 <= 1'b0;
            if(axi_arready && axi_arvalid_1)begin
                axi_arvalid_1 <= 1'b0;
                axi_araddr_n_1 <= axi_araddr_n_1 + rd_bust_len * 16;
            end
            else if(axi_arready && state_cnt == READ_ADDR_1)begin
                rd_end_1 <= 1'b0;
                axi_arvalid_1 <= 1'b1;
            end
        end
        else if(axi_araddr_n_1 == {app_addr_rd_max , 1'b0} - rd_bust_len * 16) begin
            if(axi_arready && axi_arvalid_1)begin
                axi_arvalid_1 <= 1'b0;
                axi_araddr_n_1 <= app_addr_rd_min;
                rd_end_1 <= 1'b1;
            end
            else if(axi_arready && state_cnt==READ_ADDR_1) axi_arvalid_1 <= 1'b1;
        end
        else axi_arvalid_1 <= 1'b0;
    end
    else begin
        axi_araddr_n_1 <= app_addr_rd_min;
        axi_arlen_1    <= 4'b0;
        axi_arvalid_1  <= 1'b0;
    end     
end

//����ַ2ģ��
always @(posedge clk) begin
    if (!rst_n) begin
		axi_araddr_n_2 <= app_addr_rd_min;
		axi_arlen_2    <= 4'b0;
		axi_arvalid_2  <= 1'b0;
		rd_end_2       <= 1'b0;
    end
    else if(raddr_rst_h) axi_araddr_n_2 <= app_addr_rd_min;
    else if(init_start) begin
        axi_arlen_2 <= rd_bust_len - 1'b1;
        if (axi_araddr_n_2 < {app_addr_rd_max , 1'b0} - rd_bust_len * 16) begin
            rd_end_2 <= 1'b0;
            if(axi_arready && axi_arvalid_2) begin
                axi_arvalid_2 <= 1'b0;
                axi_araddr_n_2 <= axi_araddr_n_2 + rd_bust_len * 16;
            end
            else if(axi_arready && state_cnt == READ_ADDR_2) begin
                rd_end_2 <= 1'b0;
                axi_arvalid_2 <= 1'b1;
            end
        end
        else if(axi_araddr_n_2 == {app_addr_rd_max , 1'b0} - rd_bust_len * 16) begin
            if(axi_arready && axi_arvalid_2)begin
                axi_arvalid_2 <= 1'b0;
                axi_araddr_n_2 <= app_addr_rd_min;
                rd_end_2 <= 1'b1;
            end
            else if(axi_arready && state_cnt==READ_ADDR_2) axi_arvalid_2 <= 1'b1;
        end
        else axi_arvalid_2 <= 1'b0;
    end
    else begin
        axi_araddr_n_2 <= app_addr_rd_min;
        axi_arlen_2    <= 4'b0;
        axi_arvalid_2  <= 1'b0;
    end     
end

//���źŽ��д��Ĵ���
always @(posedge clk) begin
    if(!rst_n)begin
        rd_load_d0 <= 0;
        rd_load_d1 <= 0;
        wr_load_1_d0 <= 0;
        wr_load_1_d1 <= 0;
        wr_load_2_d0 <= 0;
        wr_load_2_d1 <= 0;		
    end   
    else begin
        rd_load_d0 <= i_video_out_vs;
        rd_load_d1 <= rd_load_d0    ;
        wr_load_1_d0 <= i_video_1_vs;
        wr_load_1_d1 <= wr_load_1_d0;
        wr_load_2_d0 <= i_video_2_vs;
        wr_load_2_d1 <= wr_load_2_d0;		
    end    
end

//������Դ1����֡��λ��־
always @(posedge clk)  begin
    if(!rst_n) wr_rst_1 <= 0;
    else if(wr_load_1_d0 && !wr_load_1_d1) wr_rst_1 <= 1;
    else wr_rst_1 <= 0;
end

//������Դ2����֡��λ��־
always @(posedge clk) begin
    if(!rst_n) wr_rst_2 <= 0;
    else if(wr_load_2_d0 && !wr_load_2_d1) wr_rst_2 <= 1;
    else wr_rst_2 <= 0;
end

//�����Դ����֡��λ��־ 
always @(posedge clk) begin
    if(!rst_n) rd_rst <= 0;
    else if(!rd_load_d0 && rd_load_d1) rd_rst <= 1;
    else rd_rst <= 0;
end

//�����Դ�Ķ���ַ����֡��λ���� 
always @(posedge clk) begin
    if(!rst_n) raddr_rst_h <= 1'b0;
    else if(rd_load_d0 && !rd_load_d1) raddr_rst_h <= 1'b1;
    else if(axi_araddr_n_1 == app_addr_rd_min) raddr_rst_h <= 1'b0;
    else raddr_rst_h <= raddr_rst_h;
end

//�����Դ1֡�Ķ���ַ��λ�л�
always @(posedge clk) begin
    if(!rst_n) raddr_page_1 <= 1'b0;
    else if( rd_end_1_r) raddr_page_1 <= ~waddr_page_1;
    else raddr_page_1 <= raddr_page_1;
end

//�����Դ2֡�Ķ���ַ��λ�л�
always @(posedge clk) begin
    if(!rst_n) raddr_page_2 <= 1'b0;
    else if( rd_end_2_r) raddr_page_2 <= ~waddr_page_2;
    else raddr_page_2 <= raddr_page_2;
end

//������Դ1֡��д��ַ��λ�л�
always @(posedge clk) begin
    if(!rst_n) begin
        waddr_page_1 <= 1'b1;
        fram_done_1<= 1'b0;
    end
    else if( wr_end_1_r) begin
        fram_done_1<= 1'b1;
        waddr_page_1 <= ~waddr_page_1 ;
    end
    else waddr_page_1 <= waddr_page_1;
end

//������Դ2֡��д��ַ��λ�л�
always @(posedge clk) begin
    if(!rst_n) begin
        waddr_page_2 <= 1'b1;
        fram_done_2<= 1'b0;
    end
    else if( wr_end_2_r)begin
        fram_done_2<= 1'b1;
        waddr_page_2 <= ~waddr_page_2 ;
    end
    else waddr_page_2 <= waddr_page_2;
end

always @(posedge clk) begin
    if(!rst_n) fram_done<= 1'b0;
    else if( fram_done_1 && fram_done_2) fram_done<= 1'b1;
    else fram_done<= fram_done;
end

//DDR3��д�߼�ʵ��
always @(posedge clk) begin
    if(!rst_n) state_cnt    <= IDLE;
    else begin
        case(state_cnt)
            IDLE: begin
                if(init_start) state_cnt <= DDR3_DONE ;
                else state_cnt <= IDLE;
            end
            DDR3_DONE: begin			
                if(wr_rst_1 || wr_rst_2) state_cnt <= DDR3_DONE;					
                if(wfifo_rcount_1 >= wr_bust_len  ) state_cnt <= WRITE_ADDR_1;	//��wfifo2�洢���ݳ���һ��ͻ������ʱ������д����2                     
                else if(wfifo_rcount_2 >= wr_bust_len  ) state_cnt <= WRITE_ADDR_2;                                   
                else if(raddr_rst_h) state_cnt <= DDR3_DONE;	//��֡��λ����ʱ���ԼĴ������и�λ                                                   
                else if(rfifo_wcount_1 < rd_bust_len && ddr3_read_valid && fram_done ) state_cnt <= READ_ADDR_1;  //����������1 //��rfifo1�洢���������趨��ֵʱ����������Դ1�Ѿ�д��ddr 1֡����                                                                                        
                else if(rfifo_wcount_2 < rd_bust_len && ddr3_read_valid && fram_done ) state_cnt <= READ_ADDR_2;  //����������2 //��rfifo2�洢���������趨��ֵʱ����������Դ2�Ѿ�д��ddr 1֡����                                                                                             			                                                                                                
                else state_cnt <= state_cnt;                      
            end
            WRITE_ADDR_1: begin
                if(axi_awvalid_1 && axi_awready) state_cnt <= WRITE_DATA_1;  //����д���ݲ���
                else state_cnt <= state_cnt;   //���������㣬���ֵ�ǰֵ
            end
            WRITE_DATA_1: begin	//д���趨�ĳ��������ȴ�״̬   
                if(axi_wvalid_1 && axi_wready && init_addr_1 == wr_bust_len - 1) state_cnt <= DDR3_DONE;  //д���趨�ĳ��������ȴ�״̬
                else state_cnt <= state_cnt;  //д���������㣬���ֵ�ǰֵ
            end
            WRITE_ADDR_2: begin
                if(axi_awvalid_2 && axi_awready) state_cnt <= WRITE_DATA_2;  //����д���ݲ���
                else state_cnt <= state_cnt;   //���������㣬���ֵ�ǰֵ
            end
            WRITE_DATA_2: begin	//д���趨�ĳ��������ȴ�״̬
                if(axi_wvalid_2 && axi_wready && init_addr_2 == wr_bust_len - 1) state_cnt <= DDR3_DONE;  //д���趨�ĳ��������ȴ�״̬
                else state_cnt <= state_cnt;  //д���������㣬���ֵ�ǰֵ
            end			
            READ_ADDR_1: begin
                if(axi_arvalid_1 && axi_arready) state_cnt <= READ_DATA_1;
                else state_cnt <= state_cnt;
            end
            READ_DATA_1: begin                   //�����趨�ĵ�ַ����
                if(axi_rlast) state_cnt <= DDR3_DONE;   //����������״̬
                else state_cnt   <= state_cnt; //����������״̬ //��MIGû׼����,�򱣳�ԭֵ
            end
            READ_ADDR_2: begin
                if(axi_arvalid_2 && axi_arready) state_cnt <= READ_DATA_2;
                else state_cnt <= state_cnt;
            end
            READ_DATA_2: begin                   //�����趨�ĵ�ַ����
                if(axi_rlast) state_cnt <= DDR3_DONE;   //����������״̬
                else state_cnt   <= state_cnt; //����������״̬ //��MIGû׼����,�򱣳�ԭֵ
            end			
            default: state_cnt    <= IDLE;
        endcase
    end
end

endmodule