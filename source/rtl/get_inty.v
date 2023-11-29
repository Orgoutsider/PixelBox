function [7:0] get_inty;
	input [6:0] scaler_ctrl_height_2d;
	case (scaler_ctrl_height_2d)
		0:  get_inty = 8'd1;//720
		1:  get_inty = 8'd1;//700
		2:  get_inty = 8'd1;
		3:  get_inty = 8'd1;
		4:  get_inty = 8'd1;
		5:  get_inty = 8'd1;//620
		6:  get_inty = 8'd1;
		7:  get_inty = 8'd1;
		8:  get_inty = 8'd1;
		9:  get_inty = 8'd1;
		10: get_inty = 8'd1;//520
		11: get_inty = 8'd1;
		12: get_inty = 8'd1;
		13: get_inty = 8'd1;
		14: get_inty = 8'd1;
		15: get_inty = 8'd1;//420
		16: get_inty = 8'd1;//400
		17: get_inty = 8'd1;//380
		18: get_inty = 8'd2;//360
		19: get_inty = 8'd2;//340
		20: get_inty = 8'd2;//320
		21: get_inty = 8'd2;
		22: get_inty = 8'd2;
		23: get_inty = 8'd2;
		24: get_inty = 8'd3;//240
		25: get_inty = 8'd3;//220
		26: get_inty = 8'd3;//200
		27: get_inty = 8'd4;//180
		28: get_inty = 8'd4;//160
		29: get_inty = 8'd5;//140
		30: get_inty = 8'd6;//120
		31: get_inty = 8'd7;//100
		32: get_inty = 8'd9;//80
		33: get_inty = 8'd12;//60
		34: get_inty = 8'd18;
		35: get_inty = 8'd36;//20
		36: get_inty = 8'd18;
		37: get_inty = 8'd12;
		38: get_inty = 8'd9;
		39: get_inty = 8'd7;
		40: get_inty = 8'd6;//120
		41: get_inty = 8'd5;
		42: get_inty = 8'd4;
		43: get_inty = 8'd4;
		44: get_inty = 8'd3;
		45: get_inty = 8'd3;//220
		46: get_inty = 8'd3;
		47: get_inty = 8'd2;
		48: get_inty = 8'd2;
		49: get_inty = 8'd2;
		50: get_inty = 8'd2;//320
		51: get_inty = 8'd2;
		52: get_inty = 8'd2;
		53: get_inty = 8'd1;
		54: get_inty = 8'd1;
		55: get_inty = 8'd1;//420
		56: get_inty = 8'd1;
		57: get_inty = 8'd1;
		58: get_inty = 8'd1;
		59: get_inty = 8'd1;
		60: get_inty = 8'd1;//520
		61: get_inty = 8'd1;
		62: get_inty = 8'd1;
		63: get_inty = 8'd1;
		64: get_inty = 8'd1;
		65: get_inty = 8'd1;//620
		66: get_inty = 8'd1;
		67: get_inty = 8'd1;
		68: get_inty = 8'd1;
		69: get_inty = 8'd1;
		70: get_inty = 8'd1;//720
	endcase
endfunction