`default_nettype none

parameter IMAGE_SIZE = 64;
parameter L0_OUT     = 8;
parameter L1_OUT     = 10;


module TTNN_TOP 
(
    input  logic clk, rst_l,
    input  logic in_en,
    input  logic in_data,

    output logic [3:0] out_prediction,
    output logic out_ready
);

    /////////////////
    // FRONTEND IMAGE INPUT
    /////////////////

    // Internal latch for holding ingested image
    logic [IMAGE_SIZE-1:0]  image_flat;

    always_ff @(posedge clk) begin
        if (~rst_l) image_flat  <= '0;
        else        image_flat  <= (in_en) ? ({image_flat[IMAGE_SIZE-2:0], in_data}) : (image_flat);
    end


    /////////////////
    // L0 COMPUTATION
    /////////////////

    // L0 weights
    logic [L0_OUT-1:0][IMAGE_SIZE-1:0] l0_weights;
    always_comb begin
        l0_weights[0]   = 64'b0010011110101111110110001001110110000010100000000000100111110111;
        l0_weights[1]   = 64'b1101111010110110011100001111000110110010001001111010010001011010;
        l0_weights[2]   = 64'b1100000110010000000110010110011011100010101110001001110100001111;
        l0_weights[3]   = 64'b1001111100000010100100000111100100111111100011111100001110000000;
        l0_weights[4]   = 64'b0100010110000101010111110111111010111010111111001101000000010001;
        l0_weights[5]   = 64'b1110001110000000011100010111100111011001001110001010101000000111;
        l0_weights[6]   = 64'b1111111101111011100000010100001001101111110101111111100001100010;
        l0_weights[7]   = 64'b1110111011111000110010000100100010001000110010000110111011111110;
    end

    logic [L0_OUT-1:0][IMAGE_SIZE-1:0]          l0_out_vec;
    logic [L0_OUT-1:0][$clog2(IMAGE_SIZE):0]    l0_out_sum;
    logic [L0_OUT-1:0]                          l0_out_activation;
    logic [L0_OUT-1:0][$clog2(IMAGE_SIZE):0]    l0_thresholds;

    always_comb begin
        l0_thresholds[0]    = 'd29;
        l0_thresholds[1]    = 'd35;
        l0_thresholds[2]    = 'd31;
        l0_thresholds[3]    = 'd29;
        l0_thresholds[4]    = 'd32;
        l0_thresholds[5]    = 'd29;
        l0_thresholds[6]    = 'd28;
        l0_thresholds[7]    = 'd34;
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