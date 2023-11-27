`timescale 1ps/1ps
	
module PDS_DDR3_WR #(
	parameter HDMA_PINGPANG_EN = 1 ,	// 1-->开启兵乓操作,图像三帧缓存, 0-->关闭兵乓操作,图像一帧缓存
	parameter VIDEO_DATA_BIT   = 32		// 输入视频数据位宽,这里选择32,也可以选择16
)(
    input                 clk              , //时钟
    input                 rst_n            , //复位
    input                 ddr_init_done    , //DDR初始化完成
    output reg  [28-1:0]  axi_awaddr       , //写地址
    output reg  [3:0   ]  axi_awlen        , //写突发长度
    output wire [2:0   ]  axi_awsize       , //写突发大小
    output wire [1:0   ]  axi_awburst      , //写突发类型
    output                axi_awlock       , //写锁定类型
    input                 axi_awready      , //写地址准备信号
    output reg            axi_awvalid      , //写地址有效信号
    output                axi_awurgent     , //写紧急信号,1:Write address指令优先执行
    output                axi_awpoison     , //写抑制信号,1:Write address指令无效
    output wire [15:0  ]  axi_wstrb        , //写选通
    output reg            axi_wvalid       , //写数据有效信号
    input                 axi_wready       , //写数据准备信号
    output reg            axi_wlast        , //最后一次写信号
    output wire           axi_bready       , //写回应准备信号
    output reg  [28-1:0]  axi_araddr       , //读地址
    output reg  [3:0   ]  axi_arlen        , //读突发长度
    output wire [2:0   ]  axi_arsize       , //读突发大小
    output wire [1:0   ]  axi_arburst      , //读突发类型
    output wire           axi_arlock       , //读锁定类型
    output wire           axi_arpoison     , //读抑制信号,1:Read address指令无效
    output wire           axi_arurgent     , //读紧急信号,1:Read address指令优先执行
    input                 axi_arready      , //读地址准备信号
    output reg            axi_arvalid      , //读地址有效信号
    input                 axi_rlast        , //最后一次读信号
    input                 axi_rvalid       , //读数据有效信号
    output wire           axi_rready       , //读数据准备信号
    output reg            wrfifo_en_ctrl   , //写FIFO数据读使能控制位
    output reg            fram_done        ,
	
    input       [10:0  ]  wfifo_rcount_1   , //写端口FIFO中的数据量
    input       [10:0  ]  rfifo_wcount_1   , //读端口FIFO中的数据量
    input                 i_video_1_vs     , //输入源更新信号
    input       [10:0  ]  wfifo_rcount_2   , //写端口FIFO中的数据量
    input       [10:0  ]  rfifo_wcount_2   , //读端口FIFO中的数据量
    input                 i_video_2_vs     , //输入源更新信号	
	output                rd_opera_en_1,
	output                wr_opera_en_1,
	output                wr_opera_en_2,		
	
    input                 i_video_out_vs   , //输出源更新信号	
    input       [27:0  ]  app_addr_rd_min  , //读DDR3的起始地址
    input       [27:0  ]  app_addr_rd_max  , //读DDR3的结束地址
    input       [7:0   ]  rd_bust_len      , //从DDR3中读数据时的突发长度
    input       [27:0  ]  app_addr_wr_min  , //写DDR3的起始地址
    input       [27:0  ]  app_addr_wr_max  , //写DDR3的结束地址
    input       [7:0   ]  wr_bust_len      , //从DDR3中写数据时的突发长度
    input                 ddr3_read_valid    //DDR3 读使能   
);

//localparam define
localparam IDLE          = 10'b00_0000_0001; //空闲状态
localparam DDR3_DONE     = 10'b00_0000_0010; //DDR3初始化完成状态
localparam WRITE_ADDR_1  = 10'b00_0000_0100; //写源1地址
localparam WRITE_DATA_1  = 10'b00_0000_1000; //写源1数据
localparam READ_ADDR_1   = 10'b00_0001_0000; //读源1地址
localparam READ_DATA_1   = 10'b00_0010_0000; //读源1数据
localparam WRITE_ADDR_2  = 10'b00_0100_0000; //写源2地址
localparam WRITE_DATA_2  = 10'b00_1000_0000; //写源2数据
localparam READ_ADDR_2   = 10'b01_0000_0000; //读源2地址
localparam READ_DATA_2   = 10'b10_0000_0000; //读源2数据

//reg define
reg        init_start    ; //初始化完成信号
reg        wr_end_1_d0   ;
reg        wr_end_1_d1   ;
reg        rd_end_1_d0   ;
reg        rd_end_1_d1   ;
reg        wr_end_2_d0   ;
reg        wr_end_2_d1   ;
reg        rd_end_2_d0   ;
reg        rd_end_2_d1   ;
reg [27:0] axi_awaddr_n_1; //写地址计数
reg [27:0] axi_awaddr_n_2; //写地址计数
reg [27:0] axi_awaddr_n  ; //写地址计数
reg        wr_end_1      ; //一次突发写结束信号
reg [31:0] init_addr_1   ; //突发长度计数器
reg [9:0 ] lenth_cnt_1   ; //对突发写长度进行计数
reg [27:0] axi_araddr_n_1; //读地址计数
reg        rd_end_1      ; //一次突发读结束信号
reg        raddr_page_1  ; //ddr3读地址切换信号
reg        waddr_page_1  ; //ddr3写地址切换信号
reg        wr_end_2      ; //一次突发写结束信号
reg [31:0] init_addr_2   ; //突发长度计数器
reg [9:0 ] lenth_cnt_2   ; //对突发写长度进行计数
reg [27:0] axi_araddr_n_2; //读地址计数
reg        rd_end_2      ; //一次突发读结束信号
reg        raddr_page_2  ; //ddr3读地址切换信号
reg        waddr_page_2  ; //ddr3写地址切换信号
reg        rd_load_d0    ;
reg        rd_load_d1    ;
reg        wr_load_1_d0  ;
reg        wr_load_1_d1  ;
reg        wr_load_2_d0  ;
reg        wr_load_2_d1  ;
reg        wr_rst_1      ; //输入源帧复位标志
reg        wr_rst_2      ; //输入源帧复位标志
reg        rd_rst        ; //输出源帧复位标志
reg        raddr_rst_h   ; //输出源的帧复位脉冲
reg [9:0 ] state_cnt     ; //状态计数器
reg [3:0 ] axi_awlen_1   ; //写突发长度
reg        axi_wvalid_1    ; //写数据有效信号	
reg        axi_awvalid_1   ; //写地址有效信号	
reg        axi_wlast_1     ; //最后一次写信号	
reg [3:0 ] axi_arlen_1     ; //读突发长度
reg        axi_arvalid_1   ; //读地址有效信号
reg        wrfifo_en_ctrl_1; //写FIFO数据读使能控制位
reg        fram_done_1     ;
reg [3:0 ] axi_awlen_2     ; //写突发长度
reg        axi_wvalid_2    ; //写数据有效信号	
reg        axi_awvalid_2   ; //写地址有效信号	
reg        axi_wlast_2     ; //最后一次写信号	
reg [3:0 ] axi_arlen_2     ; //读突发长度
reg        axi_arvalid_2   ; //读地址有效信号
reg        wrfifo_en_ctrl_2; //写FIFO数据读使能控制位
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
wire[9:0] lenth_cnt_max  ; //最大突发次数

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

//读/写结束信号上升沿
assign wr_end_1_r=wr_end_1_d0&&(~wr_end_1_d1);
assign wr_end_2_r=wr_end_2_d0&&(~wr_end_2_d1);
assign rd_end_1_r=rd_end_1_d0&&(~rd_end_1_d1);
assign rd_end_2_r=rd_end_2_d0&&(~rd_end_2_d1);

//计算最大突发次数
//assign lenth_cnt_max = app_addr_wr_max / (wr_bust_len * 8);
assign lenth_cnt_max = app_addr_wr_max / (wr_bust_len *(128/VIDEO_DATA_BIT));

//稳定ddr3初始化信号
always @(posedge clk) begin
    if (!rst_n) init_start <= 1'b0;
    else if (ddr_init_done) init_start <= ddr_init_done;
    else init_start <= init_start;
end

//写地址乒乓操作
always @(*) begin
    if (HDMA_PINGPANG_EN) begin
	    if(wr_opera_en_1) axi_awaddr <= {1'b0,waddr_page_1,axi_awaddr_n_1[24:0],1'b0};
		else axi_awaddr <= {1'b1,waddr_page_2,axi_awaddr_n_2[24:0],1'b0};
	end
    else if(wr_opera_en_1) axi_awaddr <= {2'b0,axi_awaddr_n_1[24:0],1'b0};
	else axi_awaddr <= {2'b0,axi_awaddr_n_2[24:0],1'b0};	
end

//读地址乒乓操作
always @(*) begin
    if (HDMA_PINGPANG_EN) begin
	    if(rd_opera_en_1) axi_araddr <= {1'b0,raddr_page_1,axi_araddr_n_1[24:0],1'b0};
		else axi_araddr <= {1'b1,raddr_page_2,axi_araddr_n_2[24:0],1'b0};
	end
    else if(rd_opera_en_1) axi_araddr <= {2'b0,axi_araddr_n_1[24:0],1'b0};
	else axi_araddr <= {2'b0,axi_araddr_n_2[24:0],1'b0};	
end

//对异步信号进行打拍处理
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

//读端口1操作使能 
always @(posedge clk) begin
    if(!rst_n || rd_rst) rd_opera_en_1 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) rd_opera_en_1 <= 0;
        else if(state_cnt == READ_ADDR_1) rd_opera_en_1 <= 1; 
        else rd_opera_en_1 <= rd_opera_en_1;         
    end    
end 

//读端口2操作使能 
always @(posedge clk) begin
    if(!rst_n || rd_rst) rd_opera_en_2 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) rd_opera_en_2 <= 0;
        else if(state_cnt == READ_ADDR_2) rd_opera_en_2 <= 1; 
        else rd_opera_en_2 <= rd_opera_en_2;         
    end    
end 

//写端口1操作使能 
always @(posedge clk) begin
    if(!rst_n || wr_rst_1) wr_opera_en_1 <= 0;      
    else begin
        if(state_cnt == DDR3_DONE) wr_opera_en_1 <= 0;
        else if(state_cnt == WRITE_ADDR_1) wr_opera_en_1 <= 1; 
        else wr_opera_en_1 <= wr_opera_en_1;         
    end    
end 

//写端口2操作使能 
always @(posedge clk) begin
    if(!rst_n || wr_rst_2) wr_opera_en_2 <= 0;       
    else begin
        if(state_cnt == DDR3_DONE) wr_opera_en_2 <= 0;
        else if(state_cnt == WRITE_ADDR_2) wr_opera_en_2 <= 1; 
        else wr_opera_en_2 <= wr_opera_en_2;         
    end    
end 

//对写端口的ddr接口进行切换
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

//对读端口的ddr接口进行切换
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

//写地址1模块
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

//写地址2模块
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

//写数据1模块
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

//写数据2模块
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

//读地址1模块
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

//读地址2模块
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

//对信号进行打拍处理
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

//对输入源1做个帧复位标志
always @(posedge clk)  begin
    if(!rst_n) wr_rst_1 <= 0;
    else if(wr_load_1_d0 && !wr_load_1_d1) wr_rst_1 <= 1;
    else wr_rst_1 <= 0;
end

//对输入源2做个帧复位标志
always @(posedge clk) begin
    if(!rst_n) wr_rst_2 <= 0;
    else if(wr_load_2_d0 && !wr_load_2_d1) wr_rst_2 <= 1;
    else wr_rst_2 <= 0;
end

//对输出源做个帧复位标志 
always @(posedge clk) begin
    if(!rst_n) rd_rst <= 0;
    else if(!rd_load_d0 && rd_load_d1) rd_rst <= 1;
    else rd_rst <= 0;
end

//对输出源的读地址做个帧复位脉冲 
always @(posedge clk) begin
    if(!rst_n) raddr_rst_h <= 1'b0;
    else if(rd_load_d0 && !rd_load_d1) raddr_rst_h <= 1'b1;
    else if(axi_araddr_n_1 == app_addr_rd_min) raddr_rst_h <= 1'b0;
    else raddr_rst_h <= raddr_rst_h;
end

//对输出源1帧的读地址高位切换
always @(posedge clk) begin
    if(!rst_n) raddr_page_1 <= 1'b0;
    else if( rd_end_1_r) raddr_page_1 <= ~waddr_page_1;
    else raddr_page_1 <= raddr_page_1;
end

//对输出源2帧的读地址高位切换
always @(posedge clk) begin
    if(!rst_n) raddr_page_2 <= 1'b0;
    else if( rd_end_2_r) raddr_page_2 <= ~waddr_page_2;
    else raddr_page_2 <= raddr_page_2;
end

//对输入源1帧的写地址高位切换
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

//对输入源2帧的写地址高位切换
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

//DDR3读写逻辑实现
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
                if(wfifo_rcount_1 >= wr_bust_len  ) state_cnt <= WRITE_ADDR_1;	//当wfifo2存储数据超过一次突发长度时，跳到写操作2                     
                else if(wfifo_rcount_2 >= wr_bust_len  ) state_cnt <= WRITE_ADDR_2;                                   
                else if(raddr_rst_h) state_cnt <= DDR3_DONE;	//当帧复位到来时，对寄存器进行复位                                                   
                else if(rfifo_wcount_1 < rd_bust_len && ddr3_read_valid && fram_done ) state_cnt <= READ_ADDR_1;  //跳到读操作1 //当rfifo1存储数据少于设定阈值时，并且输入源1已经写入ddr 1帧数据                                                                                        
                else if(rfifo_wcount_2 < rd_bust_len && ddr3_read_valid && fram_done ) state_cnt <= READ_ADDR_2;  //跳到读操作2 //当rfifo2存储数据少于设定阈值时，并且输入源2已经写入ddr 1帧数据                                                                                             			                                                                                                
                else state_cnt <= state_cnt;                      
            end
            WRITE_ADDR_1: begin
                if(axi_awvalid_1 && axi_awready) state_cnt <= WRITE_DATA_1;  //跳到写数据操作
                else state_cnt <= state_cnt;   //条件不满足，保持当前值
            end
            WRITE_DATA_1: begin	//写到设定的长度跳到等待状态   
                if(axi_wvalid_1 && axi_wready && init_addr_1 == wr_bust_len - 1) state_cnt <= DDR3_DONE;  //写到设定的长度跳到等待状态
                else state_cnt <= state_cnt;  //写条件不满足，保持当前值
            end
            WRITE_ADDR_2: begin
                if(axi_awvalid_2 && axi_awready) state_cnt <= WRITE_DATA_2;  //跳到写数据操作
                else state_cnt <= state_cnt;   //条件不满足，保持当前值
            end
            WRITE_DATA_2: begin	//写到设定的长度跳到等待状态
                if(axi_wvalid_2 && axi_wready && init_addr_2 == wr_bust_len - 1) state_cnt <= DDR3_DONE;  //写到设定的长度跳到等待状态
                else state_cnt <= state_cnt;  //写条件不满足，保持当前值
            end			
            READ_ADDR_1: begin
                if(axi_arvalid_1 && axi_arready) state_cnt <= READ_DATA_1;
                else state_cnt <= state_cnt;
            end
            READ_DATA_1: begin                   //读到设定的地址长度
                if(axi_rlast) state_cnt <= DDR3_DONE;   //则跳到空闲状态
                else state_cnt   <= state_cnt; //则跳到空闲状态 //若MIG没准备好,则保持原值
            end
            READ_ADDR_2: begin
                if(axi_arvalid_2 && axi_arready) state_cnt <= READ_DATA_2;
                else state_cnt <= state_cnt;
            end
            READ_DATA_2: begin                   //读到设定的地址长度
                if(axi_rlast) state_cnt <= DDR3_DONE;   //则跳到空闲状态
                else state_cnt   <= state_cnt; //则跳到空闲状态 //若MIG没准备好,则保持原值
            end			
            default: state_cnt    <= IDLE;
        endcase
    end
end

endmodule