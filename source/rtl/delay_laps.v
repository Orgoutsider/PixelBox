
module delay_laps#(
	parameter MAX_DATA_WIDTH = 24,
	parameter MAX_DELAY_LAPS = 640
 )(
	input clk,
	input rst_n,
	input [23:0] i_data,
	input [9:0] delaylap,
	output reg [15:0] delay_cnt,
	output [23:0] o_data
	);

	reg [23:0] data [640:0];
    always @(*) begin
        data[0] = i_data;
    end
	integer i;
	always @(posedge clk) begin
		if (!rst_n) begin // memåˆå?‹åŒ–ä¸?0
			for (i = 1; i < 641; i = i + 1) begin
				data[i] <= 0;
			end
		end 
		else begin
			for (i = 0; i < 640; i = i + 1) begin
				data[i + 1] <= data[i];
			end
		end
	end

	always @(posedge clk) begin
		if (!rst_n) begin
			delay_cnt <= 0;
		end
		else begin
			    delay_cnt <= delay_cnt + 1;
		end
	end

	
	assign o_data = data[delaylap];
endmodule