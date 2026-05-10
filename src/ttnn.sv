`default_nettype none
module TTNN_TOP (
	clk,
	rst_l,
	in_en,
	in_data,
	out_prediction,
	out_ready
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_l;
	input wire in_en;
	input wire in_data;
	output reg [3:0] out_prediction;
	output reg out_ready;
	localparam IMAGE_SIZE = 64;
	reg [63:0] image_flat;
	always @(posedge clk)
		if (~rst_l)
			image_flat <= 1'sb0;
		else
			image_flat <= (in_en ? {image_flat[62:0], in_data} : image_flat);
	localparam L0_OUT = 8;
	reg [511:0] l0_weights;
	always @(*) begin
		if (_sv2v_0)
			;
		l0_weights[0+:64] = 64'b0010011110101111110110001001110110000010100000000000100111110111;
		l0_weights[64+:64] = 64'b1101111010110110011100001111000110110010001001111010010001011010;
		l0_weights[128+:64] = 64'b1100000110010000000110010110011011100010101110001001110100001111;
		l0_weights[192+:64] = 64'b1001111100000010100100000111100100111111100011111100001110000000;
		l0_weights[256+:64] = 64'b0100010110000101010111110111111010111010111111001101000000010001;
		l0_weights[320+:64] = 64'b1110001110000000011100010111100111011001001110001010101000000111;
		l0_weights[384+:64] = 64'b1111111101111011100000010100001001101111110101111111100001100010;
		l0_weights[448+:64] = 64'b1110111011111000110010000100100010001000110010000110111011111110;
	end
	reg [511:0] l0_out_vec;
	reg [55:0] l0_out_sum;
	reg [7:0] l0_out_activation;
	reg [55:0] l0_thresholds;
	always @(*) begin
		if (_sv2v_0)
			;
		l0_thresholds[0+:7] = 'd29;
		l0_thresholds[7+:7] = 'd35;
		l0_thresholds[14+:7] = 'd31;
		l0_thresholds[21+:7] = 'd29;
		l0_thresholds[28+:7] = 'd32;
		l0_thresholds[35+:7] = 'd29;
		l0_thresholds[42+:7] = 'd28;
		l0_thresholds[49+:7] = 'd34;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < L0_OUT; i = i + 1)
				l0_out_vec[i * 64+:64] = ~(l0_weights[i * 64+:64] ^ image_flat);
		end
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < L0_OUT; i = i + 1)
				begin
					l0_out_sum[i * 7+:7] = 'd0;
					begin : sv2v_autoblock_3
						reg signed [31:0] j;
						for (j = 0; j < IMAGE_SIZE; j = j + 1)
							l0_out_sum[i * 7+:7] = l0_out_sum[i * 7+:7] + l0_out_vec[(i * 64) + j];
					end
				end
		end
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < L0_OUT; i = i + 1)
				l0_out_activation[i] = l0_out_sum[i * 7+:7] >= l0_thresholds[i * 7+:7];
		end
	end
	reg [7:0] l0_out_activation_rev;
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_5
			reg signed [31:0] i;
			for (i = 0; i < L0_OUT; i = i + 1)
				l0_out_activation_rev[i] = l0_out_activation[7 - i];
		end
	end
	localparam L1_OUT = 10;
	reg [79:0] l1_weights;
	always @(*) begin
		if (_sv2v_0)
			;
		l1_weights[0+:8] = 16'b1011100010111011;
		l1_weights[8+:8] = 16'b0101110101110000;
		l1_weights[16+:8] = 16'b0001010111101110;
		l1_weights[24+:8] = 16'b0010011001100110;
		l1_weights[32+:8] = 16'b0111111110111000;
		l1_weights[40+:8] = 16'b0100101111100011;
		l1_weights[48+:8] = 16'b0101100011001010;
		l1_weights[56+:8] = 16'b1110111011111000;
		l1_weights[64+:8] = 16'b0100010111011110;
		l1_weights[72+:8] = 16'b1010001000110011;
	end
	reg [79:0] l1_out_vec;
	reg [39:0] l1_out_sum;
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_6
			reg signed [31:0] i;
			for (i = 0; i < L1_OUT; i = i + 1)
				l1_out_vec[i * 8+:8] = ~(l1_weights[i * 8+:8] ^ l0_out_activation_rev);
		end
		begin : sv2v_autoblock_7
			reg signed [31:0] i;
			for (i = 0; i < L1_OUT; i = i + 1)
				begin
					l1_out_sum[i * 4+:4] = 'd0;
					begin : sv2v_autoblock_8
						reg signed [31:0] j;
						for (j = 0; j < L0_OUT; j = j + 1)
							l1_out_sum[i * 4+:4] = l1_out_sum[i * 4+:4] + l1_out_vec[(i * 8) + j];
					end
				end
		end
	end
	reg [3:0] out_prediction_sum;
	always @(*) begin
		if (_sv2v_0)
			;
		out_prediction_sum = l1_out_sum[0+:4];
		out_prediction = 'd0;
		out_ready = ~in_en;
		begin : sv2v_autoblock_9
			reg signed [31:0] i;
			for (i = 0; i < L1_OUT; i = i + 1)
				if (l1_out_sum[i * 4+:4] > out_prediction_sum) begin
					out_prediction_sum = l1_out_sum[i * 4+:4];
					out_prediction = i;
				end
				else begin
					out_prediction_sum = out_prediction_sum;
					out_prediction = out_prediction;
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
