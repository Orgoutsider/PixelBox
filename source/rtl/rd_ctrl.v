`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 07/01/23 17:29:29
// Design Name: 
// Module Name: rd_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module rd_ctrl #(
    parameter CTRL_ADDR_WIDTH      = 28,
    parameter MEM_DQ_WIDTH         = 16 
)(
    input                                clk           ,
    input                                rst_n         ,   
    
    input [CTRL_ADDR_WIDTH-1:0]          read_addr     ,
    input [3:0]                          read_id       ,
    input [3:0]                          read_len      ,
    input                                read_en       ,
    output reg                           read_done_p   =0,
    
    input                                read_ready    ,
    output   [MEM_DQ_WIDTH*8-1:0]        read_rdata    ,
    output                               read_rdata_en1 ,
    output                               read_rdata_en2 ,
    output                               read_rdata_en3 ,
    output                               read_rdata_en4 ,
    input                                read_done   ,
    output                               read_cmd_en_p,
    input                                read_line   ,
   
    output reg [CTRL_ADDR_WIDTH-1:0]     axi_araddr    =0,    
    output reg [3:0]                     axi_arid      =0,
    output reg [3:0]                     axi_arlen     =0,
    output     [2:0]                     axi_arsize    ,
    output     [1:0]                     axi_arburst   ,
    output reg                           axi_arvalid   =0, 
    input                                axi_arready   ,      //only support 2'b01: INCR
                                         
    output                               axi_rready    ,
    input   [MEM_DQ_WIDTH*8-1:0]         axi_rdata     ,
    input                                axi_rvalid    ,
    input                                axi_rlast     ,
    input   [3:0]                        axi_rid       ,
    input   [1:0]                        axi_rresp     ,
    output reg [1:0]                        read_port
);

    localparam E_IDLE =  3'b001; 
    localparam E_RD   =  3'b010;
    localparam E_END  =  3'b100;
    localparam DQ_NUM = MEM_DQ_WIDTH/8; 
    
    assign axi_arburst = 2'b01;
    assign axi_arsize = 3'b110;
    
    reg [2:0] test_rd_state;
    reg [3:0] rd_delay_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_port <= 2'd0;
        end
        // else if ((test_rd_state == E_IDLE) && read_en)
        else if (read_done)
        begin
            if (read_port == 2'd0)
                read_port <= 2'd2;
            else if (read_port == 2'd2)
                read_port <= 2'd1;
            else if (read_port == 2'd1)
                read_port <= 2'd3;
            else if (read_port == 2'd3)
                read_port <= 2'd0;
        end
    end

    assign read_cmd_en_p = (read_port > 2'd0) & ~read_done;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n) begin
        test_rd_state <= E_IDLE;
        end
        else begin      
        case (test_rd_state)
            E_IDLE: begin
                if (read_en) begin
                    test_rd_state <= E_RD;
                end
            end
            E_RD: begin                
                if (axi_arvalid&axi_arready)//(rd_delay_cnt == 4'd7)//
                    test_rd_state <= E_END;
            end
            E_END:  begin
                if (rd_delay_cnt == 4'd15)
                    test_rd_state <= E_IDLE;
            end 
            default:  test_rd_state <= E_IDLE;
        endcase     
        end
    end        
    
    // wire rd_opera_en_2;
    //读端口1操作使能 
    // assign rd_opera_en_1 = (test_rd_state == E_RD1) || (test_rd_state == E_END1);
    //读端口2操作使能 
    // assign rd_opera_en_2 = (test_rd_state == E_RD2) || (test_rd_state == E_END2);

    always @(posedge clk or negedge rst_n)
    begin
       if (!rst_n)
           rd_delay_cnt       <= 4'b0; 
       else if((test_rd_state == E_END))
           rd_delay_cnt <= rd_delay_cnt + 1'b1;
       else
           rd_delay_cnt       <= 4'b0; 
    end
    
    always @(posedge clk or negedge rst_n)
    begin
       if (!rst_n) begin
           axi_araddr     <= {CTRL_ADDR_WIDTH{1'b0}}; 
           axi_arid       <= 4'b0; 
           axi_arlen      <= 4'b0; 
       end
       else if((test_rd_state == E_IDLE) & read_en)
       begin
           axi_arid <= read_id;
           axi_araddr <= read_addr;
           axi_arlen  <=  read_len;              
       end
    end
    
    always @(posedge clk or negedge rst_n)
    begin
    	if (!rst_n) begin
            axi_arvalid    <= 1'b0; 
            read_done_p    <= 1'b0;
    	end
    	else begin
        	case (test_rd_state)
                E_IDLE: begin
                    read_done_p <= 1'b0 ;
                    axi_arvalid <= 1'b0;
                end
                E_RD: begin
                    axi_arvalid <= 1'b1;   
                                   
                    if (axi_arvalid&axi_arready)
                        axi_arvalid <= 1'b0; 
                end
                E_END: begin
                    axi_arvalid <= 1'b0;
                    if(rd_delay_cnt == 4'd15)
                        read_done_p <= 1'b1;
                end
                default: begin
                    axi_arvalid <= 1'b0;
                    read_done_p <= 1'b0;
                end
            endcase  
    	end
    end

    assign axi_ready = read_ready;
    assign read_rdata = axi_rdata;
    assign read_rdata_en1 = (read_port == 2'd0) ? axi_rvalid : 1'b0;
    assign read_rdata_en2 = (read_port == 2'd1) ? axi_rvalid : 1'b0;
    assign read_rdata_en3 = (read_port == 2'd2) ? axi_rvalid : 1'b0;
    assign read_rdata_en4 = (read_port == 2'd3) ? axi_rvalid : 1'b0;
    assign axi_rready = 1'b1;
 
endmodule  
                
