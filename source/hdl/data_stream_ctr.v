module data_stream_ctr
                          #(parameter ADJUST_MODE = 1,
                            parameter BRAM_DEEPTH = 1280,
                            parameter DATA_WIDTH  = 8,
                            parameter INDEX_WIDTH = 11,
                            parameter INT_WIDTH   = 8,   // 定点数整数位�?
                            parameter FIX_WIDTH   = 12)
                          (
                           input                            clk_i, 
                           input                            rst_i,
                           
                           input                            tvalid_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
                           input[DATA_WIDTH-1:0]            tdata_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///image stream
                           output                           tready_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
                           
                           
                           input[15 : 0]                    src_width_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]                    src_height_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]                    dest_width_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                           input[15 : 0]                    dest_height_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                                                     
                           
                           input[INDEX_WIDTH-1:0]           srcx_int_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/// 对应原图x坐标整数部分 addr width
                           input[INDEX_WIDTH-1:0]           srcy_int_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/// 对应原图y坐标整数部分 addr height                                                     
         
                           output[INDEX_WIDTH-1:0]          destx_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///current x location
                           output[INDEX_WIDTH-1:0]          desty_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///current y location
         
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factorx_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ // srcx_width / destx_width
                           input[INT_WIDTH + FIX_WIDTH-1:0] scale_factory_i/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ // srcy_height / desty_height

                           output                           tvalid_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
                           output[DATA_WIDTH-1:0]           tdata00_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                           output[DATA_WIDTH-1:0]           tdata01_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/// 
                           output[DATA_WIDTH-1:0]           tdata10_o/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*///
                           output[DATA_WIDTH-1:0]           tdata11_o /*synthesis PAP_MARK_DEBUG="1"*///                                                             
                           );

//----------------------------�?适应参数的位宽�?�算函数-------------------------------------//   
//计算一�?十进制数对应二进制的位�??                  
function integer clogb2 (input integer bit_depth);              
  begin                                                           
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
      bit_depth = bit_depth >> 1;                                 
  end                                                           
endfunction                       
                      
localparam BRAM_ADDR_WIDTH  = clogb2(BRAM_DEEPTH - 1);         // BRAN地址位�??
localparam BRAM_DATA_WIDTH  = DATA_WIDTH;                      // 每个数据的位宽度
localparam BRAM_MEMORY_SIZE = BRAM_DEEPTH * BRAM_DATA_WIDTH;   // 所需要的BRAM的面�?                        

wire scaler_done;
reg[15:0] r_row_pixel_cnt; /*synthesis PAP_MARK_DEBUG="1"*/ // 读像素�?�数
reg[15:0] r_row_cnt;       /*synthesis PAP_MARK_DEBUG="1"*/      // 读�?��?�数
reg[2:0] scaler_st;        /*synthesis PAP_MARK_DEBUG="1"*/        // 缩放状�?
reg[1:0] delay_cnt;        /*synthesis PAP_MARK_DEBUG="1"*/       // 延迟的节拍数

assign scaler_done = &scaler_st; // 一帧缩放完�?                   


//------------------------------------输入数据计数----------------------------------------//
// 列�?�数
reg[15:0] w_row_pixel_cnt; /*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge clk_i) begin
  if(rst_i) begin
    w_row_pixel_cnt <= 16'd0;
  end else  begin
    if((w_row_pixel_cnt == src_width_i -1) & tvalid_i) begin // 存完一行像�?
      w_row_pixel_cnt <= 16'd0;
    end 
    else if(tvalid_i) begin // 像素有效则�?�数+1
      w_row_pixel_cnt <= w_row_pixel_cnt + 16'd1; 
    end
  end
end


wire w_image_tlast;/*synthesis PAP_MARK_DEBUG="1"*///�?否存到每行图像的�?�? image row end;
assign w_image_tlast = (w_row_pixel_cnt == src_width_i -1) & tvalid_i;//�?否存到每行图像的�?�?


// 输入行�?�数
reg[15:0] w_row_cnt;/*synthesis PAP_MARK_DEBUG="1"*/ 
always@(posedge clk_i)begin
  if(rst_i)begin
    w_row_cnt <= 16'd0;
  end else begin
    if(scaler_done)begin  // 等待一帧缩放结束才能清�?
      w_row_cnt <= 16'd0;
    end 
    else if(w_image_tlast) begin
      w_row_cnt <= w_row_cnt + 16'd1; // 一行存完，+1
    end 
    else begin
      w_row_cnt <= w_row_cnt;
    end
  end
end


//----------------------------------------写地址，写使能，写数据-----------------------------------------------//
// 生成写地址
reg[10:0] w_addr;/*synthesis PAP_MARK_DEBUG="1"*/ 
always@(posedge clk_i)begin
  if(rst_i)begin
    w_addr <= 16'd0;
  end else begin
    if((w_addr == {src_width_i,1'b0} - 1) & tvalid_i)begin // 一个ram存两行像素，如果写地址写到了ram的末尾，清零重头再来
      w_addr <= 16'd0;
    end 
    else if(tvalid_i) begin
      w_addr <= w_addr + 16'd1; // 地址�?增，存入下一�?像素
    end
  end
end


// 写入ram的数�?
wire[DATA_WIDTH-1:0] w_data;/*synthesis PAP_MARK_DEBUG="1"*/
assign w_data = tdata_i;

// 写数�?使能
wire w_en; /*synthesis PAP_MARK_DEBUG="1"*/
assign w_en = tvalid_i;


//-----------------------------------------�?------------------------------------------------//
// 控制什么时候�?? 

// reg[2:0] scaler_st; // 缩放状�?
// reg[1:0] delay_cnt; // 延迟的节拍数
always@(posedge clk_i)begin
  if(rst_i)begin
    scaler_st <= 3'd0;
    delay_cnt <= 3'd0;
  end else begin
    case(scaler_st)

    //控制读的时机，当存到我们要�?�算的�?�才读，或者在放大时，行都已经存完，�?�应的原图坐标一直在最后一�?
    3'd0:begin
      delay_cnt <= 0;
      if(w_row_cnt > srcy_int_i + 1'b1 || (srcy_int_i == src_height_i - 1'b1))begin 
        scaler_st <= 3'd1; // �?以开始�?�存好的额两行进行插�?
      end 
      else begin
        scaler_st <= 3'd0; // 继续存数�?
      end    
    end
      
    //每�?��?�的次数等于�?标图宽度时，说明新一行算完了
    // 此时处于读的状�?
    3'd1:begin
      if(r_row_pixel_cnt == dest_width_i - 1'b1)begin 
        scaler_st <= 3'd2;
      end 
      else begin
        scaler_st <= 3'd1;
      end    
    end

    3'd2:begin
      if(r_row_cnt == 16'd0)begin //原图的所有�?�都读过�? read last row done 
        scaler_st <= 3'd4;
      end
      else begin // 还没算完一�?
        scaler_st <= 3'd3;
      end    
    end
    
    // 还没读完一帧，打拍之后继续�?
    3'd3:begin
      delay_cnt <= delay_cnt + 1;
      if(delay_cnt == 2)begin  // 每�?�一�?数据要打拍，因为要跟系数输出时机对齐
        scaler_st <= 3'd0;
      end 
      else begin
        scaler_st <= 3'd3;
      end        
    end    
    
    // 输入的数�?都�?�完了，但是有可能插值还没结束，比�?�放�?
    3'd4:begin
      if(scale_factory_i[INT_WIDTH + FIX_WIDTH - 1 : FIX_WIDTH])begin //scaler down 
      // 根据缩放因子整数部分，判�?�?放大还是缩小�?>1�?放大�?<1�?缩小
      // 放大：存储会比�?�算提前结束
      // 缩小：存储与计算结束时机�?不�??
        scaler_st <= 3'd5; // 放大
      end 
      else begin 
        scaler_st <= 3'd6; // 缩小
      end
    end 
      
    5:begin
      if(w_row_cnt == src_height_i)begin  // 一帧所有数�?都存过了
        scaler_st <= 3'd6;
      end 
      else begin
        scaler_st <= 3'd5;
      end         
    end   

    // 相当于打拍输�?
    6:begin
      scaler_st <= 3'd7;        
    end
    
    7:begin
      scaler_st <= 3'd0;        
    end    
                               
    endcase
  end
end



wire scaler_valid;/*synthesis PAP_MARK_DEBUG="1"*/
assign scaler_valid = (scaler_st == 3'd1) ? 1'b1 : 1'b0; 
 
// 读出每�?�的像素 列�?�数

always@(posedge clk_i)begin
  if(rst_i)begin
    r_row_pixel_cnt <= 16'd0;
  end else begin
    if((r_row_pixel_cnt == dest_width_i -1'b1) & scaler_valid)begin
      r_row_pixel_cnt <= 16'd0; // 读的次数等于�?标图的一行，说明一行已经算�?
    end 
    else if(scaler_valid) begin
      r_row_pixel_cnt <= r_row_pixel_cnt + 16'd1;
    end
  end
end


// 算到每�?�最后一�?像素时拉�?
wire r_image_tlast;/*synthesis PAP_MARK_DEBUG="1"*/// 读到最后最后一�? image row end;
assign r_image_tlast = (r_row_pixel_cnt == dest_width_i -1'b1) & scaler_valid;

// 读�?��?�数
always@(posedge clk_i)begin
  if(rst_i)begin
    r_row_cnt <= 16'd0;
  end else begin
    if(r_image_tlast)begin  //如果算到最后一行，同时算完最后一行的最后一�?像素，一帧算完了
        if (r_row_cnt == dest_height_i -1'b1)
            r_row_cnt <= 16'd0;
        else
            r_row_cnt <= r_row_cnt + 16'd1;
    end else begin
      r_row_cnt <= r_row_cnt;
    end
  end
end


// 更新读地址
reg[10:0] r_addrb00 = 11'hfff;/*synthesis PAP_MARK_DEBUG="1"*/
reg[10:0] r_addrb01 = 11'hfff;/*synthesis PAP_MARK_DEBUG="1"*/
reg[10:0] r_addrb10 = 11'hfff;/*synthesis PAP_MARK_DEBUG="1"*/
reg[10:0] r_addrb11 = 11'hfff;/*synthesis PAP_MARK_DEBUG="1"*/
// 原图的�?�数行存在ram的前半部分，偶数行存在ram的后半部�?
// 如果读偶数�?�，相邻两�?�就刚好存在ram的前后两部分
// 如果读�?�数行，ram�?存的行顺序是反的，因为下一行已经把原来的上一行�?�盖掉了
always@(posedge clk_i)begin
  if(srcy_int_i[0])begin // 如果算的�?奇数行，相邻后一行存在ram的前半部�?
    if(srcx_int_i == src_width_i - 1) begin // last pixel in line
           // 如果读取的是奇数行，并且还是该�?�的最后一�?像素，后一行存在ram的前半部�?
      r_addrb00 <= src_width_i + srcx_int_i - 1;
      r_addrb01 <= src_width_i + srcx_int_i;
      r_addrb10 <= srcx_int_i - 1;
      r_addrb11 <= srcx_int_i;
    end 
    else begin
      r_addrb00 <= src_width_i + srcx_int_i;
      r_addrb01 <= src_width_i + srcx_int_i + 1;
      r_addrb10 <= srcx_int_i;
      r_addrb11 <= srcx_int_i + 1;    
    end
  end 
  else begin // 如果读取的是偶数行，后一行存在ram的后半部�?
    if(srcx_int_i == src_width_i - 1)begin  
      r_addrb00 <= srcx_int_i -1;
      r_addrb01 <= srcx_int_i;
      r_addrb10 <= src_width_i + srcx_int_i - 1;
      r_addrb11 <= src_width_i + srcx_int_i;
    end 
    else begin
      r_addrb00 <= srcx_int_i;
      r_addrb01 <= srcx_int_i + 1;
      r_addrb10 <= src_width_i + srcx_int_i;
      r_addrb11 <= src_width_i + srcx_int_i + 1;    
    end
  end
end


//------------------------ 产生要�?�算的目标图像像素坐�?-----------------------------------//
reg[INDEX_WIDTH-1:0] destx = 0;/*synthesis PAP_MARK_DEBUG="1"*///current x location
reg[INDEX_WIDTH-1:0] desty = 0;/*synthesis PAP_MARK_DEBUG="1"*///current y location


always@(*)begin
  destx = r_row_pixel_cnt;
  desty = r_row_cnt;  
end

//产生要�?�算的目标图像像素坐标之后输出到，cal_bilinear_srcxy�?计算该目标像素�?�应在的原图�?的坐�?
assign destx_o = destx;
assign desty_o = desty;


reg[7:0] scaler_valid_d = 0;
always@(posedge clk_i)begin
  scaler_valid_d <= {scaler_valid_d[6:0],scaler_valid}; // 不断左移
end

// scaler_st一变成1，scaler_valid�?上为1�?
//但是如果此时把data_valid
// 因为当r_en�?1后，要延迟一周期才从ram�?读取数据
wire r_enb;/*synthesis PAP_MARK_DEBUG="1"*/
generate
  if(ADJUST_MODE == 0)begin//-------------normal mode: delay 1+2 clk-------------------------
                             
  assign tvalid_o = scaler_valid_d[3]; //打四�?
  assign r_enb    = scaler_valid_d[1];
  
  end 

  else begin//---------------adjust mode: delay 3+2 clk-------------------------
  
  assign tvalid_o = scaler_valid_d[5]; //打六�?
  assign r_enb    = scaler_valid_d[3];
  
  end
endgenerate

wire[DATA_WIDTH -1:0] r_doutb00;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH -1:0] r_doutb01;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH -1:0] r_doutb10;/*synthesis PAP_MARK_DEBUG="1"*/
wire[DATA_WIDTH -1:0] r_doutb11;/*synthesis PAP_MARK_DEBUG="1"*/

reg[DATA_WIDTH -1:0] r_doutb00_d;/*synthesis PAP_MARK_DEBUG="1"*/
reg[DATA_WIDTH -1:0] r_doutb01_d;/*synthesis PAP_MARK_DEBUG="1"*/
reg[DATA_WIDTH -1:0] r_doutb10_d;/*synthesis PAP_MARK_DEBUG="1"*/
reg[DATA_WIDTH -1:0] r_doutb11_d;/*synthesis PAP_MARK_DEBUG="1"*/

// 打一�?
always@(posedge clk_i)begin//sync to weight
  r_doutb00_d <= r_doutb00;
  r_doutb01_d <= r_doutb01;
  r_doutb10_d <= r_doutb10;
  r_doutb11_d <= r_doutb11;
end

assign tdata00_o = r_doutb00_d;
assign tdata01_o = r_doutb01_d;
assign tdata10_o = r_doutb10_d;
assign tdata11_o = r_doutb11_d;

// �?否存储完一�?
wire wr_end;/*synthesis PAP_MARK_DEBUG="1"*/
assign wr_end = (w_row_cnt == src_height_i);

// �?否接受�?�部像素
wire tready;/*synthesis PAP_MARK_DEBUG="1"*/
assign tready = (w_row_cnt < srcy_int_i + 2) ? 1: 0; // 假�?�当前存的�?�还不�?�，允�?�进新数�?; 假�?�当前存的�?�足够算了，不允许进新数�?0，防止�?�盖
assign tready_o = tready  && (!wr_end); // 如果已经存完一帧中的所有�?�，在插值结束之前，不允许再进新数据，因为图像放大，图像的存储会比�?�算结束的更�?





// 四个RAM入相同的数据
// 同时读取四个相邻�?
scaler_ram u_scaler_ram00 (
  .a_addr(w_addr),          // input [10:0]
  .a_wr_data(w_data),    // input [7:0]
  .a_rd_data(),             // output [7:0]
  .a_wr_en(w_en),        // input
  .a_clk(clk_i),            // input
  .a_rst(0),            // input
  .b_addr(r_addrb00),          // input [10:0]
  .b_wr_data(),             // input [7:0]
  .b_rd_data(r_doutb00),    // output [7:0]
  .b_wr_en(~r_enb),          // input
  .b_clk(clk_i),            // input
  .b_rst(0)             // input
);
scaler_ram u_scaler_ram01 (
  .a_addr(w_addr),          // input [10:0]
  .a_wr_data(w_data),    // input [7:0]
  .a_rd_data(),    // output [7:0]
  .a_wr_en(w_en),        // input
  .a_clk(clk_i),            // input
  .a_rst(0),            // input

  .b_addr(r_addrb01),          // input [10:0]
  .b_wr_data(),    // input [7:0]
  .b_rd_data(r_doutb01),    // output [7:0]
  .b_wr_en(~r_enb),        // input
  .b_clk(clk_i),            // input
  .b_rst(0)             // input
);
scaler_ram u_scaler_ram10 (
  .a_addr(w_addr),      // input [10:0]
  .a_wr_data(w_data),   // input [7:0]
  .a_rd_data(),         // output [7:0]
  .a_wr_en(w_en),       // input
  .a_clk(clk_i),        // input
  .a_rst(0),            // input

  .b_addr(r_addrb10),          // input [10:0]
  .b_wr_data(),    // input [7:0]
  .b_rd_data(r_doutb10),    // output [7:0]
  .b_wr_en(~r_enb),        // input
  .b_clk(clk_i),            // input
  .b_rst(0)             // input
);
scaler_ram u_scaler_ram11 (
  .a_addr(w_addr),          // input [10:0]
  .a_wr_data(w_data),    // input [7:0]
  .a_rd_data(),    // output [7:0]
  .a_wr_en(w_en),        // input
  .a_clk(clk_i),            // input
  .a_rst(0),            // input

  .b_addr(r_addrb11),          // input [10:0]
  .b_wr_data(),    // input [7:0]
  .b_rd_data(r_doutb11),    // output [7:0]
  .b_wr_en(~r_enb),        // input
  .b_clk(clk_i),            // input
  .b_rst(0)             // input
);





// // xpm_memory_sdpram: Simple Dual Port RAM
// // Xilinx Parameterized Macro, version 2019.1
// // | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// // |---------------------------------------------------------------------------------------------------------------------|
// // | Designate the memory primitive (resource type) to use.                                                              |
// // |                                                                                                                     |
// // |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// // |   "distributed"- Distributed memory                                                                                 |
// // |   "block"- Block memory                                                                                             |
// // |   "ultra"- Ultra RAM memory                                                                                         |
// // |                                                                                                                     |
// // | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with MEMORY_PRIMITIVE set to "auto".|

//    xpm_memory_sdpram #(
//                        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .AUTO_SLEEP_TIME(0),            // DECIMAL
//                        .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .CASCADE_HEIGHT(0),             // DECIMAL
//                        .CLOCKING_MODE("common_clock"), // String
//                        .ECC_MODE("no_ecc"),            // String
//                        .MEMORY_INIT_FILE("none"), // String  w_table.mem
//                        .MEMORY_INIT_PARAM(""),        // String
//                        .MEMORY_OPTIMIZATION("true"),   // String
//                        .MEMORY_PRIMITIVE("block"),     // String
//                        .MEMORY_SIZE(BRAM_MEMORY_SIZE),      // DECIMAL
//                        .MESSAGE_CONTROL(0),            // DECIMAL
//                        .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),         // DECIMAL
//                        .READ_LATENCY_B(1),             // DECIMAL
//                        .READ_RESET_VALUE_B("0"),       // String
//                        .RST_MODE_A("SYNC"),            // String
//                        .RST_MODE_B("SYNC"),            // String
//                        .SIM_ASSERT_CHK(1),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//                        .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
//                        .USE_MEM_INIT(0),               // DECIMAL
//                        .WAKEUP_TIME("disable_sleep"),  // String
//                        .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .WRITE_MODE_B("read_first")      // String
//                        )
                       
//                        xpm_memory_sdpram00 (
//                                                .clkb(clk_i),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
//                                                                                 // "independent_clock". Unused when parameter CLOCKING_MODE is
//                                                                                 // "common_clock".        

//                                                .enb(r_enb),                  // 1-bit input: Memory enable signal for port B. Must be high on clock
//                                                                              // cycles when read operations are initiated. Pipelined internally.
//                                                .addrb(r_addrb00),              // ADDR_WIDTH_B-bit input: Address for port B read operations.
//                                                .doutb(r_doutb00),              // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.

//                                                .injectdbiterra(0),              // 1-bit input: Controls double bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .injectsbiterra(0),              // 1-bit input: Controls single bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .regceb(0),                      // 1-bit input: Clock Enable for the last register stage on the output
//                                                                                 // data path.

//                                                .rstb(0),                        // 1-bit input: Reset signal for the final port B output register stage.
//                                                                                 // Synchronously resets output port doutb to the value specified by
//                                                                                 // parameter READ_RESET_VALUE_B.

//                                                .sleep(0),                       // 1-bit input: sleep signal to enable the dynamic power saving feature.
                                               
//                                                .clka(clk_i),                      // 1-bit input: Clock signal for port A. Also clocks port B when
//                                                                                 // parameter CLOCKING_MODE is "common_clock".                                       
//                                                .addra(w_addr),             // ADDR_WIDTH_A-bit input: Address for port A write operations.
                                               
//                                                .dina(w_data),              // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
                                               
//                                                .ena(w_en),                   // 1-bit input: Memory enable signal for port A. Must be high on clock
//                                                                                 // cycles when write operations are initiated. Pipelined internally.      
//                                                .wea(1'b1)                     // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
//                                                                                 // data port dina. 1 bit wide when word-wide writes are used. In
//                                                                                 // byte-wide write configurations, each bit controls the writing one
//                                                                                 // byte of dina to address addra. For example, to synchronously write
//                                                                                 // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
//                                                                                 // 4'b0010.

//                                                );
                                               
// // xpm_memory_sdpram: Simple Dual Port RAM
// // Xilinx Parameterized Macro, version 2019.1
// // | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// // |---------------------------------------------------------------------------------------------------------------------|
// // | Designate the memory primitive (resource type) to use.                                                              |
// // |                                                                                                                     |
// // |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// // |   "distributed"- Distributed memory                                                                                 |
// // |   "block"- Block memory                                                                                             |
// // |   "ultra"- Ultra RAM memory                                                                                         |
// // |                                                                                                                     |
// // | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with MEMORY_PRIMITIVE set to "auto".|

//    xpm_memory_sdpram #(
//                        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .AUTO_SLEEP_TIME(0),            // DECIMAL
//                        .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .CASCADE_HEIGHT(0),             // DECIMAL
//                        .CLOCKING_MODE("common_clock"), // String
//                        .ECC_MODE("no_ecc"),            // String
//                        .MEMORY_INIT_FILE("none"), // String  w_table.mem
//                        .MEMORY_INIT_PARAM(""),        // String
//                        .MEMORY_OPTIMIZATION("true"),   // String
//                        .MEMORY_PRIMITIVE("block"),     // String
//                        .MEMORY_SIZE(BRAM_MEMORY_SIZE),      // DECIMAL
//                        .MESSAGE_CONTROL(0),            // DECIMAL
//                        .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),         // DECIMAL
//                        .READ_LATENCY_B(1),             // DECIMAL
//                        .READ_RESET_VALUE_B("0"),       // String
//                        .RST_MODE_A("SYNC"),            // String
//                        .RST_MODE_B("SYNC"),            // String
//                        .SIM_ASSERT_CHK(1),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//                        .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
//                        .USE_MEM_INIT(0),               // DECIMAL
//                        .WAKEUP_TIME("disable_sleep"),  // String
//                        .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .WRITE_MODE_B("read_first")      // String
//                        )
                       
//                        xpm_memory_sdpram01 (
//                                                .clkb(clk_i),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
//                                                                                 // "independent_clock". Unused when parameter CLOCKING_MODE is
//                                                                                 // "common_clock".        

//                                                .enb(r_enb),                  // 1-bit input: Memory enable signal for port B. Must be high on clock
//                                                                              // cycles when read operations are initiated. Pipelined internally.
//                                                .addrb(r_addrb01),              // ADDR_WIDTH_B-bit input: Address for port B read operations.
//                                                .doutb(r_doutb01),            // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.

//                                                .injectdbiterra(0),              // 1-bit input: Controls double bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .injectsbiterra(0),              // 1-bit input: Controls single bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .regceb(0),                      // 1-bit input: Clock Enable for the last register stage on the output
//                                                                                 // data path.

//                                                .rstb(0),                        // 1-bit input: Reset signal for the final port B output register stage.
//                                                                                 // Synchronously resets output port doutb to the value specified by
//                                                                                 // parameter READ_RESET_VALUE_B.

//                                                .sleep(0),                       // 1-bit input: sleep signal to enable the dynamic power saving feature.
                                               
//                                                .clka(clk_i),                      // 1-bit input: Clock signal for port A. Also clocks port B when
//                                                                                 // parameter CLOCKING_MODE is "common_clock".                                       
//                                                .addra(w_addr),             // ADDR_WIDTH_A-bit input: Address for port A write operations.
                                               
//                                                .dina(w_data),              // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
                                               
//                                                .ena(w_en),                   // 1-bit input: Memory enable signal for port A. Must be high on clock
//                                                                                 // cycles when write operations are initiated. Pipelined internally.      
//                                                .wea(1'b1)                     // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
//                                                                                 // data port dina. 1 bit wide when word-wide writes are used. In
//                                                                                 // byte-wide write configurations, each bit controls the writing one
//                                                                                 // byte of dina to address addra. For example, to synchronously write
//                                                                                 // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
//                                                                                 // 4'b0010.

//                                                );
                                               
                                               
// // xpm_memory_sdpram: Simple Dual Port RAM
// // Xilinx Parameterized Macro, version 2019.1
// // | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// // |---------------------------------------------------------------------------------------------------------------------|
// // | Designate the memory primitive (resource type) to use.                                                              |
// // |                                                                                                                     |
// // |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// // |   "distributed"- Distributed memory                                                                                 |
// // |   "block"- Block memory                                                                                             |
// // |   "ultra"- Ultra RAM memory                                                                                         |
// // |                                                                                                                     |
// // | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with MEMORY_PRIMITIVE set to "auto".|

//    xpm_memory_sdpram #(
//                        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .AUTO_SLEEP_TIME(0),            // DECIMAL
//                        .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .CASCADE_HEIGHT(0),             // DECIMAL
//                        .CLOCKING_MODE("common_clock"), // String
//                        .ECC_MODE("no_ecc"),            // String
//                        .MEMORY_INIT_FILE("none"), // String  w_table.mem
//                        .MEMORY_INIT_PARAM(""),        // String
//                        .MEMORY_OPTIMIZATION("true"),   // String
//                        .MEMORY_PRIMITIVE("block"),     // String
//                        .MEMORY_SIZE(BRAM_MEMORY_SIZE),      // DECIMAL
//                        .MESSAGE_CONTROL(0),            // DECIMAL
//                        .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),         // DECIMAL
//                        .READ_LATENCY_B(1),             // DECIMAL
//                        .READ_RESET_VALUE_B("0"),       // String
//                        .RST_MODE_A("SYNC"),            // String
//                        .RST_MODE_B("SYNC"),            // String
//                        .SIM_ASSERT_CHK(1),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//                        .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
//                        .USE_MEM_INIT(0),               // DECIMAL
//                        .WAKEUP_TIME("disable_sleep"),  // String
//                        .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .WRITE_MODE_B("read_first")      // String
//                        )
                       
//                        xpm_memory_sdpram10 (
//                                                .clkb(clk_i),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
//                                                                                 // "independent_clock". Unused when parameter CLOCKING_MODE is
//                                                                                 // "common_clock".        

//                                                .enb(r_enb),                  // 1-bit input: Memory enable signal for port B. Must be high on clock
//                                                                              // cycles when read operations are initiated. Pipelined internally.
//                                                .addrb(r_addrb10),              // ADDR_WIDTH_B-bit input: Address for port B read operations.
//                                                .doutb(r_doutb10),              // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.

//                                                .injectdbiterra(0),              // 1-bit input: Controls double bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .injectsbiterra(0),              // 1-bit input: Controls single bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .regceb(0),                      // 1-bit input: Clock Enable for the last register stage on the output
//                                                                                 // data path.

//                                                .rstb(0),                        // 1-bit input: Reset signal for the final port B output register stage.
//                                                                                 // Synchronously resets output port doutb to the value specified by
//                                                                                 // parameter READ_RESET_VALUE_B.

//                                                .sleep(0),                       // 1-bit input: sleep signal to enable the dynamic power saving feature.
                                               
//                                                .clka(clk_i),                      // 1-bit input: Clock signal for port A. Also clocks port B when
//                                                                                 // parameter CLOCKING_MODE is "common_clock".                                       
//                                                .addra(w_addr),             // ADDR_WIDTH_A-bit input: Address for port A write operations.
                                               
//                                                .dina(w_data),              // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
                                               
//                                                .ena(w_en),                   // 1-bit input: Memory enable signal for port A. Must be high on clock
//                                                                                 // cycles when write operations are initiated. Pipelined internally.      
//                                                .wea(1'b1)                     // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
//                                                                                 // data port dina. 1 bit wide when word-wide writes are used. In
//                                                                                 // byte-wide write configurations, each bit controls the writing one
//                                                                                 // byte of dina to address addra. For example, to synchronously write
//                                                                                 // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
//                                                                                 // 4'b0010.

//                                                ); 
                                               
                                               
// // xpm_memory_sdpram: Simple Dual Port RAM
// // Xilinx Parameterized Macro, version 2019.1
// // | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// // |---------------------------------------------------------------------------------------------------------------------|
// // | Designate the memory primitive (resource type) to use.                                                              |
// // |                                                                                                                     |
// // |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// // |   "distributed"- Distributed memory                                                                                 |
// // |   "block"- Block memory                                                                                             |
// // |   "ultra"- Ultra RAM memory                                                                                         |
// // |                                                                                                                     |
// // | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with MEMORY_PRIMITIVE set to "auto".|

//    xpm_memory_sdpram #(
//                        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),               // DECIMAL
//                        .AUTO_SLEEP_TIME(0),            // DECIMAL
//                        .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .CASCADE_HEIGHT(0),             // DECIMAL
//                        .CLOCKING_MODE("common_clock"), // String
//                        .ECC_MODE("no_ecc"),            // String
//                        .MEMORY_INIT_FILE("none"), // String  w_table.mem
//                        .MEMORY_INIT_PARAM(""),        // String
//                        .MEMORY_OPTIMIZATION("true"),   // String
//                        .MEMORY_PRIMITIVE("block"),     // String
//                        .MEMORY_SIZE(BRAM_MEMORY_SIZE),      // DECIMAL
//                        .MESSAGE_CONTROL(0),            // DECIMAL
//                        .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),         // DECIMAL
//                        .READ_LATENCY_B(1),             // DECIMAL
//                        .READ_RESET_VALUE_B("0"),       // String
//                        .RST_MODE_A("SYNC"),            // String
//                        .RST_MODE_B("SYNC"),            // String
//                        .SIM_ASSERT_CHK(1),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
//                        .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
//                        .USE_MEM_INIT(0),               // DECIMAL
//                        .WAKEUP_TIME("disable_sleep"),  // String
//                        .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),        // DECIMAL
//                        .WRITE_MODE_B("read_first")      // String
//                        )
                       
//                        xpm_memory_sdpram11 (
//                                                .clkb(clk_i),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
//                                                                                 // "independent_clock". Unused when parameter CLOCKING_MODE is
//                                                                                 // "common_clock".        

//                                                .enb(r_enb),                  // 1-bit input: Memory enable signal for port B. Must be high on clock
//                                                                              // cycles when read operations are initiated. Pipelined internally.
//                                                .addrb(r_addrb11),              // ADDR_WIDTH_B-bit input: Address for port B read operations.
//                                                .doutb(r_doutb11),              // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.

//                                                .injectdbiterra(0),              // 1-bit input: Controls double bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .injectsbiterra(0),              // 1-bit input: Controls single bit error injection on input data when
//                                                                                 // ECC enabled (Error injection capability is not available in
//                                                                                 // "decode_only" mode).

//                                                .regceb(0),                      // 1-bit input: Clock Enable for the last register stage on the output
//                                                                                 // data path.

//                                                .rstb(0),                        // 1-bit input: Reset signal for the final port B output register stage.
//                                                                                 // Synchronously resets output port doutb to the value specified by
//                                                                                 // parameter READ_RESET_VALUE_B.

//                                                .sleep(0),                       // 1-bit input: sleep signal to enable the dynamic power saving feature.
                                               
//                                                .clka(clk_i),                      // 1-bit input: Clock signal for port A. Also clocks port B when
//                                                                                 // parameter CLOCKING_MODE is "common_clock".                                       
//                                                .addra(w_addr),             // ADDR_WIDTH_A-bit input: Address for port A write operations.
                                               
//                                                .dina(w_data),              // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
                                               
//                                                .ena(w_en),                   // 1-bit input: Memory enable signal for port A. Must be high on clock
//                                                                                 // cycles when write operations are initiated. Pipelined internally.      
//                                                .wea(1'b1)                     // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
//                                                                                 // data port dina. 1 bit wide when word-wide writes are used. In
//                                                                                 // byte-wide write configurations, each bit controls the writing one
//                                                                                 // byte of dina to address addra. For example, to synchronously write
//                                                                                 // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
//                                                                                 // 4'b0010.

//                                                );                                                                                                                                            

endmodule