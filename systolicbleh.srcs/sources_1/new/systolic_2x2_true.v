`timescale 1ns/1ps

module systolic_2x2_true (
    input clk,
    input reset,
    input clr_acc_in,       
    
    // Input A (feed to left column, flows right)
    input [15:0] a00_in,
    input [15:0] a10_in,
    
    // Input B (feed to top row, flows down)
    input [15:0] b00_in,
    input [15:0] b01_in,
    
    // Outputs (accumulated results from each PE)
    output [31:0] c00,
    output [31:0] c01,
    output [31:0] c10,
    output [31:0] c11
);

    // Internal wires for spatial data movement
    wire [15:0] a01, a11;
    wire [15:0] b10, b11;

    // Internal wires for control signal movement
    wire clr_a_00_to_01, clr_b_00_to_10;
    wire clr_b_01_to_11, clr_a_10_to_11;

    // PE[0][0] - Top-Left
    pe_systolic pe00 (
        .clk(clk), .reset(reset),
        .clr_acc_in(clr_acc_in), 
        .clr_acc_out_a(clr_a_00_to_01), .clr_acc_out_b(clr_b_00_to_10),
        .in_a(a00_in), .in_b(b00_in),
        .out_a(a01),   .out_b(b10),
        .acc(c00)
    );

    // PE[0][1] - Top-Right
    pe_systolic pe01 (
        .clk(clk), .reset(reset),
        .clr_acc_in(clr_a_00_to_01), 
        .clr_acc_out_a(), .clr_acc_out_b(clr_b_01_to_11),
        .in_a(a01),       .in_b(b01_in),
        .out_a(),         .out_b(b11),
        .acc(c01)
    );

    // PE[1][0] - Bottom-Left
    pe_systolic pe10 (
        .clk(clk), .reset(reset),
        .clr_acc_in(clr_b_00_to_10), 
        .clr_acc_out_a(clr_a_10_to_11), .clr_acc_out_b(),
        .in_a(a10_in),                  .in_b(b10),
        .out_a(a11),                    .out_b(),
        .acc(c10)
    );

    // PE[1][1] - Bottom-Right
    pe_systolic pe11 (
        .clk(clk), .reset(reset),
        .clr_acc_in(clr_a_10_to_11), // Token arrives from the left
        .clr_acc_out_a(), .clr_acc_out_b(),
        .in_a(a11),       .in_b(b11),
        .out_a(),         .out_b(),
        .acc(c11)
    );

endmodule
