`default_nettype none

parameter IMAGE_SIZE = 64;
parameter L0_OUT     = 16;
parameter L1_OUT     = 10;


module TTNN_TOP 
(
    input  logic clk, rst_l,
    input  logic [7:0] in_byte,
    input  logic [2:0] in_addr,
    input  logic in_en,

    output logic [3:0] out_prediction,
    output logic out_ready
);

    /////////////////
    // FRONTEND IMAGE INPUT
    /////////////////

    // Internal latch for holding ingested image
    logic [7:0][7:0]        image, image_next;
    logic [IMAGE_SIZE-1:0]  image_flat;

    always_comb begin
        image_next = image;
        if (in_en) image_next[in_addr] = in_byte; 
    end

    assign image_flat = image;

    always_ff @(posedge clk) begin
        if (~rst_l) image   <= '0;
        else        image   <= image_next;
    end


    /////////////////
    // L0 COMPUTATION
    /////////////////

    // L0 weights
    logic [L0_OUT-1:0][IMAGE_SIZE-1:0] l0_weights;
    always_comb begin
        l0_weights[0]   = 64'b1001101110101110111111101010011100010110000000010001001100100001;
        l0_weights[1]   = 64'b0111011010000000100100111111110110111111101111010010000000011000;
        l0_weights[2]   = 64'b1001100110011111000011011000011011100110110001111100000000010000;
        l0_weights[3]   = 64'b0000000010000000100110110100011101000000011110011101111101001111;
        l0_weights[4]   = 64'b1010001110011001000100010110001111101111111101111001100111100000;
        l0_weights[5]   = 64'b1100100111110011000011100000000001011101111111000101001100101001;
        l0_weights[6]   = 64'b1011111111111011100010001101111111010111010011100100000011100000;
        l0_weights[7]   = 64'b0010010010010101011110010111110111010001110110000100100100001001;
        l0_weights[8]   = 64'b0111101101111110111000001100011001100010111100010110110001110111;
        l0_weights[9]   = 64'b1111011100111111000010101000100000101000101100110001111101010111;
        l0_weights[10]  = 64'b0110110110101101010110011100111101001000010000001101110101100011;
        l0_weights[11]  = 64'b0011000110001111111111100011111100111100111111001000000110001011;
        l0_weights[12]  = 64'b0000000111010001101001110100011001111110011110111111011001000001;
        l0_weights[13]  = 64'b0011100011101110010111111000000000011000011111110110011010111100;
        l0_weights[14]  = 64'b0111110000101110010101000111000011110000001001110110011100111100;
        l0_weights[15]  = 64'b1010101000110110011101111111001010100011010001011100110011111000;
    end

    logic [L0_OUT-1:0][IMAGE_SIZE-1:0]          l0_out_vec;
    logic [L0_OUT-1:0][$clog2(IMAGE_SIZE):0]    l0_out_sum;
    logic [L0_OUT-1:0]                          l0_out_activation;
    logic [L0_OUT-1:0][$clog2(IMAGE_SIZE):0]    l0_thresholds;

    always_comb begin
        l0_thresholds[0]    = 'd33;
        l0_thresholds[1]    = 'd33;
        l0_thresholds[2]    = 'd31;
        l0_thresholds[3]    = 'd29;
        l0_thresholds[4]    = 'd27;
        l0_thresholds[5]    = 'd31;
        l0_thresholds[6]    = 'd29;
        l0_thresholds[7]    = 'd32;
        l0_thresholds[8]    = 'd31;
        l0_thresholds[9]    = 'd32;
        l0_thresholds[10]   = 'd28;
        l0_thresholds[11]   = 'd31;
        l0_thresholds[12]   = 'd30;
        l0_thresholds[13]   = 'd36;
        l0_thresholds[14]   = 'd38;
        l0_thresholds[15]   = 'd32;
    end
    always_comb begin
        for (int i = 0; i < L0_OUT; i++) l0_out_vec[i] = ~(l0_weights[i] ^ image_flat);

        for (int i = 0; i < L0_OUT; i++) begin
            l0_out_sum[i] = 'd0;
            for (int j = 0; j < IMAGE_SIZE; j++) l0_out_sum[i] += l0_out_vec[i][j];
        end

        for (int i = 0; i < L0_OUT; i++) l0_out_activation[i] = l0_out_sum[i] >= l0_thresholds[i];
    end


    /////////////////
    // L1 COMPUTATION
    /////////////////

    logic [L0_OUT-1:0] l0_out_activation_rev;
    always_comb begin
        for (int i = 0; i < L0_OUT; i++)
            l0_out_activation_rev[i] = l0_out_activation[L0_OUT-1-i];
    end

    // L1 weights
    logic [L1_OUT-1:0][L0_OUT-1:0] l1_weights;
    always_comb begin
        l1_weights[0] = 16'b1011100010111011;
        l1_weights[1] = 16'b0101110101110000;
        l1_weights[2] = 16'b0001010111101110;
        l1_weights[3] = 16'b0010011001100110;
        l1_weights[4] = 16'b0111111110111000;
        l1_weights[5] = 16'b0100101111100011;
        l1_weights[6] = 16'b0101100011001010;
        l1_weights[7] = 16'b1110111011111000;
        l1_weights[8] = 16'b0100010111011110;
        l1_weights[9] = 16'b1010001000110011;
    end

    logic [L1_OUT-1:0][L0_OUT-1:0]          l1_out_vec;
    logic [L1_OUT-1:0][$clog2(L0_OUT):0]    l1_out_sum;
    always_comb begin
        for (int i = 0; i < L1_OUT; i++) l1_out_vec[i] = ~(l1_weights[i] ^ l0_out_activation_rev);

        for (int i = 0; i < L1_OUT; i++) begin
            l1_out_sum[i] = 'd0;
            for (int j = 0; j < L0_OUT; j++) l1_out_sum[i] += l1_out_vec[i][j];
        end
    end


    /////////////////
    // PREDICTION
    /////////////////

    logic [$clog2(L0_OUT):0] out_prediction_sum;
    always_comb begin
        out_prediction_sum  = l1_out_sum[0];
        out_prediction      = 'd0;
        out_ready           = ~in_en;

        for (int i = 0; i < L1_OUT; i++) begin
            if (l1_out_sum[i] > out_prediction_sum) begin
                out_prediction_sum  = l1_out_sum[i];
                out_prediction      = i;
            end
            else begin
                out_prediction_sum  = out_prediction_sum;
                out_prediction      = out_prediction;
            end
        end
    end
endmodule: TTNN_TOP