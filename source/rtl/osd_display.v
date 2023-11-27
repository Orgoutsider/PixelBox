module osd_display#(
    parameter                     OSD_WIDTH       = 12'd16,
    parameter                     OSD_HEGIHT      =  12'd32
)
(
    input clk,
    input [3:0] num,
    input [12:0] pos_x,
    input [12:0] pos_y,
    input pos_de,
    input pos_vs,
    output reg pos_en
);

wire        region_active;
reg        region_active_d0;
reg[12:0]  osd_x;
reg[12:0]  osd_y;
reg[15:0]  osd_ram_addr;
reg[15:0] base_addr;
reg null;
reg        pos_vs_d0;
reg        pos_vs_d1;
wire[7:0]  q;

assign region_active = pos_de && (pos_y >= 13'd9 && pos_y <= 13'd9 + OSD_HEGIHT - 13'd1 && pos_x >= 13'd9 && pos_x  <= 13'd9 + OSD_WIDTH - 13'd1);

always @(posedge clk) begin
    region_active_d0 <= region_active & ~null;
end

always@(posedge clk)
begin
	pos_vs_d0 <= pos_vs;
	pos_vs_d1 <= pos_vs_d0;
end

always@(posedge clk)
begin
	if(region_active_d0 == 1'b1)
		osd_x <= osd_x + 12'd1;
	else
		osd_x <= 12'd0;
end

always@(posedge clk)
begin
	if(pos_vs_d1 == 1'b1 && pos_vs_d0 == 1'b0)
		osd_ram_addr <= base_addr;
	else if(region_active == 1'b1)
		osd_ram_addr <= osd_ram_addr + 16'd1;
end

always@(posedge clk)
begin
	if(region_active_d0 == 1'b1)
        pos_en <= q[osd_x[2:0]];
	else
		pos_en <= 1'b0;
end

osd_rom osd_rom_m0 (
    .addr(osd_ram_addr[13:3]),// input [10:0]
    .clk(clk),// input
    .rst(1'b0),// input
    .rd_data(q));// output [7:0]

always @(*) begin
    case (num)
        4'd0:    begin base_addr = 16'h0000; null = 1'b0; end 
        4'd1:    begin base_addr = 16'h0200; null = 1'b0; end
        4'd2:    begin base_addr = 16'h0400; null = 1'b0; end
        4'd3:    begin base_addr = 16'h0600; null = 1'b0; end
        4'd4:    begin base_addr = 16'h0800; null = 1'b0; end
        4'd5:    begin base_addr = 16'h0a00; null = 1'b0; end
        4'd6:    begin base_addr = 16'h0c00; null = 1'b0; end
        4'd7:    begin base_addr = 16'h0e00; null = 1'b0; end
        4'd8:    begin base_addr = 16'h1000; null = 1'b0; end
        4'd9:    begin base_addr = 16'h1200; null = 1'b0; end
        default: begin base_addr = 16'h0000; null = 1'b1; end
    endcase
end

endmodule