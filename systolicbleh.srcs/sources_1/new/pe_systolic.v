`timescale 1ns/1ps

module pe_systolic (
    input clk,
    input reset,
    input clr_acc_in,       
    input [15:0] in_a,
    input [15:0] in_b,
    output reg clr_acc_out_a,  // Pass control Right
    output reg clr_acc_out_b,  // Pass control Down
    output reg [15:0] out_a,
    output reg [15:0] out_b,
    output reg [31:0] acc
);

    wire [31:0] mult_result = in_a * in_b;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc           <= 32'b0;
            out_a         <= 16'b0;
            out_b         <= 16'b0;
            clr_acc_out_a <= 1'b0;
            clr_acc_out_b <= 1'b0;
        end else begin
            // Forward data to neighbors (1-cycle delay)
            out_a <= in_a;
            out_b <= in_b;
            
            // Forward control token to neighbors (1-cycle delay)
            clr_acc_out_a <= clr_acc_in;
            clr_acc_out_b <= clr_acc_in;
            
            // MAC: Multiply and accumulate or reset
            if (clr_acc_in) begin
                acc <= mult_result; 
            end else begin
                acc <= acc + mult_result; 
            end
        end
    end

endmodule
