`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 10:57:34
// Design Name: 
// Module Name: top_wrapper
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


`timescale 1ns / 1ps

module boolean_systolic_top (
    input clk,             // 100MHz clock
    input [15:0] sw,       // 16 slide switches
    input [3:0] btn,       // Buttons (btn[0] used for global reset)
    output [15:0] led,     // LEDs for feedback
    
    // 7-Segment Display 0 (Right Display)
    output [3:0] D0_AN,
    output [7:0] D0_SEG,
    
    // 7-Segment Display 1 (Left Display)
    output [3:0] D1_AN,
    output [7:0] D1_SEG
);

    wire reset = btn[0]; // Press Button 0 to clear all memory

    // ==========================================
    // 1. Trixie (Lever) Debouncing & Edge Detection
    // ==========================================
    // Mechanical switches "bounce". We need to filter this so 1 flick = 1 pulse.
    reg [1:0] trixie_sync;
    reg trixie_clean, trixie_last;
    reg [19:0] debounce_cnt;

    always @(posedge clk) begin
        trixie_sync <= {trixie_sync[0], sw[0]};
        if (reset) begin
            trixie_clean <= 0;
            debounce_cnt <= 0;
        end else if (trixie_sync[1] == trixie_clean) begin
            debounce_cnt <= 0;
        end else begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt == 20'hFFFFF) trixie_clean <= trixie_sync[1]; // ~10ms wait
        end
        trixie_last <= trixie_clean;
    end

    // Trigger on the FALLING edge (lever pulled down/off)
    wire trixie_trigger = (trixie_last == 1'b1 && trixie_clean == 1'b0);

    // ==========================================
    // 2. Input Memory (Holding the Matrices)
    // ==========================================
    reg [15:0] A00, A01, A10, A11;
    reg [15:0] B00, B01, B10, B11;

    always @(posedge clk) begin
        if (reset) begin
            A00 <= 0; A01 <= 0; A10 <= 0; A11 <= 0;
            B00 <= 0; B01 <= 0; B10 <= 0; B11 <= 0;
        end else if (sw[15] == 1'b0 && trixie_trigger) begin // INPUT MODE
            case (sw[14:13]) // Coordinate Switch
                2'b00: begin A00 <= {10'b0, sw[12:7]}; B00 <= {10'b0, sw[6:1]}; end
                2'b01: begin A01 <= {10'b0, sw[12:7]}; B01 <= {10'b0, sw[6:1]}; end
                2'b10: begin A10 <= {10'b0, sw[12:7]}; B10 <= {10'b0, sw[6:1]}; end
                2'b11: begin A11 <= {10'b0, sw[12:7]}; B11 <= {10'b0, sw[6:1]}; end
            endcase
        end
    end

    // ==========================================
    // 3. Automated Timing Controller (FSM)
    // ==========================================
    // Automatically feeds the array exactly like your testbench did
    reg [3:0] state;
    reg sys_clr;
    reg [15:0] sys_a00, sys_a10, sys_b00, sys_b01;

    localparam S_IDLE  = 4'd0, S_FEED0 = 4'd1, S_FEED1 = 4'd2;
    localparam S_FEED2 = 4'd3, S_WAIT1 = 4'd4, S_WAIT2 = 4'd5;
    localparam S_WAIT3 = 4'd6, S_DONE  = 4'd7;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE:  if (sw[15] == 1'b1) state <= S_FEED0; // Switch to Calculate Mode
                S_FEED0: state <= S_FEED1;
                S_FEED1: state <= S_FEED2;
                S_FEED2: state <= S_WAIT1;
                S_WAIT1: state <= S_WAIT2;
                S_WAIT2: state <= S_WAIT3;
                S_WAIT3: state <= S_DONE;
                S_DONE:  if (sw[15] == 1'b0) state <= S_IDLE;  // Back to Input Mode
                default: state <= S_IDLE;
            endcase
        end
    end

    // Drive the systolic array inputs based on the FSM State
    always @(*) begin
        sys_clr = 0; sys_a00 = 0; sys_a10 = 0; sys_b00 = 0; sys_b01 = 0;
        case (state)
            S_FEED0: begin sys_clr = 1; sys_a00 = A00; sys_b00 = B00; end
            S_FEED1: begin sys_a00 = A01; sys_a10 = A10; sys_b00 = B10; sys_b01 = B01; end
            S_FEED2: begin sys_a10 = A11; sys_b01 = B11; end
        endcase
    end

    // ==========================================
    // 4. Instantiate Your Systolic Array
    // ==========================================
    wire [31:0] C00, C01, C10, C11;
    
    systolic_2x2_true systolic_grid (
        .clk(clk), .reset(reset), .clr_acc_in(sys_clr),
        .a00_in(sys_a00), .a10_in(sys_a10),
        .b00_in(sys_b00), .b01_in(sys_b01),
        .c00(C00), .c01(C01), .c10(C10), .c11(C11)
    );

    // ==========================================
    // 5. Output Display Paging
    // ==========================================
    reg output_page;
    always @(posedge clk) begin
        if (reset || sw[15] == 1'b0) output_page <= 1'b0;
        else if (sw[15] == 1'b1 && trixie_trigger) output_page <= ~output_page;
    end

    // Select which outputs to send to the screen
    wire [13:0] display_left_val  = (output_page == 0) ? C00[13:0] : C10[13:0];
    wire [13:0] display_right_val = (output_page == 0) ? C01[13:0] : C11[13:0];

    // ==========================================
    // 6. Binary to Decimal Converter
    // ==========================================
    wire [15:0] bcd_left, bcd_right;
    bin2bcd conv_left  (.bin(display_left_val),  .bcd(bcd_left));
    bin2bcd conv_right (.bin(display_right_val), .bcd(bcd_right));

    // ==========================================
    // 7. Seven-Segment Multiplexing
    // ==========================================
    reg [16:0] refresh_counter;
    always @(posedge clk) refresh_counter <= refresh_counter + 1;
    
    wire [1:0] digit_select = refresh_counter[16:15];
    
    reg [3:0] current_digit_left, current_digit_right;
    reg [3:0] an_mask;

    always @(*) begin
        case(digit_select)
            2'b00: begin an_mask = 4'b1110; current_digit_left = bcd_left[3:0];   current_digit_right = bcd_right[3:0];   end
            2'b01: begin an_mask = 4'b1101; current_digit_left = bcd_left[7:4];   current_digit_right = bcd_right[7:4];   end
            2'b10: begin an_mask = 4'b1011; current_digit_left = bcd_left[11:8];  current_digit_right = bcd_right[11:8];  end
            2'b11: begin an_mask = 4'b0111; current_digit_left = bcd_left[15:12]; current_digit_right = bcd_right[15:12]; end
        endcase
    end

    assign D1_AN = an_mask;
    assign D0_AN = an_mask;
    
    // Decode digit to 7-segment layout (Active Low)
    function [6:0] decode_7seg(input [3:0] num);
        case(num)
            4'h0: decode_7seg = 7'b1000000;
            4'h1: decode_7seg = 7'b1111001;
            4'h2: decode_7seg = 7'b0100100;
            4'h3: decode_7seg = 7'b0110000;
            4'h4: decode_7seg = 7'b0011001;
            4'h5: decode_7seg = 7'b0010010;
            4'h6: decode_7seg = 7'b0000010;
            4'h7: decode_7seg = 7'b1111000;
            4'h8: decode_7seg = 7'b0000000;
            4'h9: decode_7seg = 7'b0010000;
            default: decode_7seg = 7'b0111111; // Dash if error
        endcase
    endfunction

    // Assign Decoded segments. Bit 7 is the Decimal Point (keep it off/High)
    assign D0_SEG = {1'b1, decode_7seg(current_digit_left)};
    assign D1_SEG = {1'b1, decode_7seg(current_digit_right)};
    // ==========================================
    // 8. LED Feedback (So you know what's happening)
    // ==========================================
    // LED 15 shows Mode. LED 14-13 echoes target coordinate. 
    // LEDs 12-0 echo the inputs so you see what switches are active.
    assign led = sw;

endmodule


// ========================================================
// Helper Module: Converts Binary to 4-Digit Decimal (BCD)
// Uses the Double Dabble algorithm
// ========================================================
module bin2bcd (
    input [13:0] bin,
    output reg [15:0] bcd
);
    integer i;
    always @(bin) begin
        bcd = 0;
        for (i = 13; i >= 0; i = i - 1) begin
            if (bcd[3:0] >= 5)   bcd[3:0]   = bcd[3:0] + 3;
            if (bcd[7:4] >= 5)   bcd[7:4]   = bcd[7:4] + 3;
            if (bcd[11:8] >= 5)  bcd[11:8]  = bcd[11:8] + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
            bcd = {bcd[14:0], bin[i]};
        end
    end
endmodule
