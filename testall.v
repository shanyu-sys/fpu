`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:55:35 01/05/2017 
// Design Name: 
// Module Name:    smulation 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module testall(
    );

reg clk,rst;
reg[31:0] instruction;

wire[31:0] out_32;
wire[63:0] out_64;
wire complete,wrong;

top testtop(.clk(clk),
			.instruction(instruction),
			.rst(rst),
			.out_32(out_32),
			.out_64(out_64),
			.complete(complete),
			.wrong(wrong));
                 
initial
begin

clk=0;
rst=0;

#5 instruction = 32'b00111100000000011100000000000000;
#5 instruction = 32'b00111100000000100110010100010001;
#5 instruction = 32'b00111100000000110100001000000000;
#5 instruction = 32'b001111_00000_00100_1101001001000100;
#5 instruction = 32'b001111_00000_00101_1101001001010100;
#5 instruction = 32'b001111_00000_00110_0101001011000100;
#5 instruction = 32'b001111_00000_00111_0101001001111100;
#5 instruction = 32'b001111_00000_01000_0101001111100100;
#5 instruction = 32'b001111_00000_10101_0101001101000100;
#5 instruction = 32'b001111_00000_10110_1101001001010100;
#5 instruction = 32'b001111_00000_10111_0010010001011010;
#5 instruction = 32'b001111_00000_11000_1010101010101110;

#5   instruction = 32'b010001_10000_00001_00010_01001_000010;
#100 instruction = 32'b010001_10000_00011_00100_01010_000010;
#100 instruction = 32'b010001_00001_00101_00110_01011_000010;
#100 instruction = 32'b010001_00001_00111_01000_01100_000010;
#100 instruction = 32'b0;

/*

#5 instruction=32'b00111100000001011010010000001000; //5
#5 instruction=32'b00110100101001100000000000000000; //6

#5 instruction=32'b00111100000001110010001000001000; //7
#5 instruction=32'b00110100111010000000000000000000; //8

#5 instruction=32'b00111100000010010000001000000000; 
#5 instruction=32'b00110101001010100000000000000010;

#5 instruction=32'b00111100000010111000010000000000;
#5 instruction=32'b00110101011011000000000000000100;

#5 instruction=32'b00111100000011010111111010000000;
#5 instruction=32'b00110101101011100000000000000010;

#5 instruction=32'b00111100000011111100010000000000;
#5 instruction=32'b00110101111100000000000000000100;

#5 instruction=32'b00111100000100011010010001100000;
#5 instruction=32'b00110110001100100000000000000000;
 
#5 instruction=32'b00111100000100110010001001100000;
#5 instruction=32'b00110110011101000000000000000000;

#5   instruction=32'b01000110000001100100010101000010;
#100 instruction=32'b01000110000010100110010110000010;
#100 instruction=32'b01000110000011101000010111000010;
#100 instruction=32'b01000110000100101010011000000010;
*/
#100 $finish;
end
//initial
//$monitor($time,"output float_c=%h yichu=%b", float_c,yichu);
//initial
//begin
//$dumpfile("test1.vcd");
//$dumpvars;
//end
always
begin
#1 clk=~clk;
end

initial
begin
$dumpfile ("test.vcd");
$dumpvars;
end
endmodule
