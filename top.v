`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 18:46:17
// Design Name: 
// Module Name: top
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


module top(clk,instruction,rst,out_32,out_64,complete,wrong);
input [31:0] instruction;
input clk,rst;
output [31:0]out_32;
output [63:0]out_64;
output complete;
output wrong;

wire[5:0] opcode;
reg[4:0] ft;
reg[4:0] fs;
reg[4:0] fd;
reg[4:0] format;
reg[5:0] operation;
reg[4:0] rs;
reg[4:0] rt;
reg[15:0] enable;

reg[31:0] mem[31:0];

reg[31:0] s_single_a;
reg[31:0] s_single_b;
wire[31:0] single_a;
wire[31:0] single_b;
reg[63:0] s_double_a;
reg[63:0] s_double_b;
wire[63:0] double_a;
wire[63:0] double_b;

reg s_wrong;
wire wrong;
reg[31:0] s_out_32;
reg[63:0] s_out_64;
wire[31:0] out_32;
wire[63:0] out_64;
reg s_complete;
wire complete;

wire complete1,complete2,complete3,complete4,complete5,complete6,complete7,complete8;
wire complete9,complete10,complete11,complete12,complete13,complete14,complete15,complete16;
wire[31:0] z1,z3,z5,z7,z8,z9,z11,z12,z14,z16;
wire[63:0] z2,z4,z6,z10,z13,z15;


parameter ARITH=6'b010001,LUI=6'b001111,ORI=6'b001101;
parameter ADD=6'b000000,SUB=6'b000001,MUL=6'b000010;
parameter DTOF=6'b000011,DTOSINT=6'b000100,DTOUNSINT=6'b000101;
parameter FTOD=6'b000110,FTOSINT=6'b000111,FTOUNSINT=6'b001000;
parameter SINTTOD=6'b001001,SINTTOF=6'b001010,UNSINTTOD=6'b001011,UNSINTTOF=6'b001100;
parameter SINGLE = 5'b10000,DOUBLE=5'b00001;

assign opcode = instruction[31:26];
always@(instruction or z1 or z2 or z3 or z4 or z5 or z6 or z7 or z8 or z9 or z10 or z11 or z12 or z13 or z14 or z15 or z16)
begin
	if(opcode==LUI)
		begin
		  
			rt = instruction[20:16];
			mem[rt]={instruction[15:0],16'b0};

		end
	else if(opcode == ORI)
		begin
		
			rs = instruction[25:21];
			rt = instruction[20:16];
			mem[rt]={16'b0,instruction[15:0]}|mem[rs];
		
		end
	else if(opcode == ARITH)
		begin
			format = instruction[25:21];
			ft = instruction[20:16];
			fs = instruction[15:11];
			fd = instruction[10:6];
			operation = instruction[5:0];
			enable = 16'b0;
			s_complete = 0;
			case(operation)
			ADD:
			begin
				if(format == SINGLE)
				begin
					enable[0]=1;
					s_single_a = mem[ft];
					s_single_b = mem[fs];
					if(complete1)
					begin
						mem[fd] = z1;
						s_out_32 = z1;
						s_complete = 1;
					end
				end
				else if(format == DOUBLE)
				begin 
					enable[1] = 1;
					s_double_a = {mem[ft],mem[ft+16]};
					s_double_b = {mem[fs],mem[fs+16]};
					if(complete2)
					begin
						mem[fd] = z2[63:32];
						mem[fd+16] = z2[15:11];
						s_out_64 = z2;
						s_complete = 1;
					end
				end
				else 
				begin
					s_wrong = 1;
				end
			end
			
			SUB:
			begin
				if(format == SINGLE)
				begin
					enable[3]=1;
					s_single_a = mem[ft];
					s_single_b = {~mem[fs][31],mem[fs][30:0]};
					if(complete3)
					begin
						mem[fd] = z3;
						s_out_32 = z3;
						s_complete = 1;
					end				
				end
				else if(format == DOUBLE)
				begin 
					enable[4] = 1;
					s_double_a = {mem[ft],mem[ft+16]};
					s_double_b = {~mem[fs][31],mem[fs][31:0],mem[fs+16]};
					if(complete4)
					begin
						mem[fd] = z4[63:32];
						mem[fd+16] = z4[15:11];
						s_out_64 = z4;
						s_complete = 1;
					end
				end
				else 
				begin
					s_wrong = 1;
				end
			end
			
			MUL:
			begin
				if(format == SINGLE)
				begin
					enable[5]=1;
					s_single_a = mem[ft];
					s_single_b = mem[fs];
					if(complete5)
					begin
						mem[fd] = z5;
						s_out_32 = z5;
						s_complete = 1;
					end
				end
				else if(format == DOUBLE)
				begin 
					enable[6] = 1;
					s_double_a = {mem[ft],mem[ft+16]};
					s_double_b = {mem[fs],mem[fs+16]};
					if(complete6)
					begin
						mem[fd] = z6[63:32];
						mem[fd+16] = z6[15:11];
						s_out_64 = z6;
						s_complete = 1;
					end
				end
				else 
				begin
					s_wrong = 1;
				end
			end
			
			DTOF:
			begin
				enable[7]=1;
				s_double_a ={mem[fs],mem[fs+16]};
				if(complete7)
				begin
					mem[fd] = z7;
					s_out_32 = z7;
					s_complete = 1;
				end
			end
			
			DTOSINT: 
			begin
				enable[8]=1;
				s_double_a ={mem[fs],mem[fs+16]};
				if(complete8)
				begin
					mem[fd] = z8;
					s_out_32 = z8;
					s_complete = 1;
				end
			end	
			
			DTOUNSINT: 
			begin
				enable[9]=1;
				s_double_a ={mem[fs],mem[fs+16]};
				if(complete9)
				begin
					mem[fd] = z9;
					s_out_32 = z9;
					s_complete = 1;
				end
			end	
			
			FTOD:
			begin
				enable[10]=1;
				s_single_a = mem[fs];
				if(complete10)
				begin
					mem[fd]=z10[63:32];
					mem[fd+16]=z10[31:0];
					s_out_64 = z10;
					s_complete =1;
				end
			end
			
			FTOSINT:
			begin
				enable[11]=1;
				s_single_a = mem[fs];
				if(complete11)
				begin
					mem[fd]=z11;
					s_out_32 = z11;
					s_complete =1;
				end
			end
			
			FTOUNSINT:
			begin
				enable[12]=1;
				s_single_a = mem[fs];
				if(complete12)
				begin
					mem[fd]=z12;
					s_out_32 = z12;
					s_complete =1;
				end
			end
			
			SINTTOD:
			begin
				enable[13]=1;
				s_single_a = mem[fs];
				if(complete13)
				begin
					mem[fd]=z13[63:32];
					mem[fd+16]=z13[31:0];
					s_out_64 = z13;
					s_complete =1;
				end
			end
			
			SINTTOF:
			begin
				enable[14]=1;
				s_single_a = mem[fs];
				if(complete14)
				begin
					mem[fd]=z14;
					s_out_32 = z14;
					s_complete =1;
				end
			end
			
			UNSINTTOD:
			begin
				enable[15]=1;
				s_single_a = mem[fs];
				if(complete15)
				begin
					mem[fd]=z15[63:32];
					mem[fd+16]=z15[31:0];
					s_out_64 = z15;
					s_complete =1;
				end
			end
			
			UNSINTTOF:
			begin
				enable[0]=1;
				s_single_a = mem[fs];
				if(complete16)
				begin
					mem[fd]=z16;
					s_out_32 = z16;
					s_complete =1;
				end     
			end
				
			default:
			begin
				s_out_32 = 0;
				s_out_64 = 0;
				s_complete =0;
				s_wrong =1;
			end
			endcase
		end
	else
	begin
		s_wrong =1;
	end
end
	
assign wrong = s_wrong;
assign complete = s_complete;
assign single_a = s_single_a;
assign single_b = s_single_b;
assign double_a = s_double_a;
assign double_b = s_double_b;
assign out_32 = s_out_32;
assign out_64 = s_out_64;

 adder2 #(32,23,8,255)
 m1(.clk(clk),.rst(rst),.en(enable[0]),.input_a(single_a),.input_b(single_b),.complete(complete1),.output_z(z1));
 
 adder2 #(64,52,11,2047)
 m2(.clk(clk),.rst(rst),.en(enable[1]),.input_a(double_a),.input_b(double_b),.complete(complete2),.output_z(z2));

  adder2 #(32,23,8,255)
 m3(.clk(clk),.rst(rst),.en(enable[3]),.input_a(single_a),.input_b(single_b),.complete(complete3),.output_z(z3));
 
  adder2 #(64,52,11,2047)
 m4(.clk(clk),.rst(rst),.en(enable[4]),.input_a(double_a),.input_b(double_b),.complete(complete4),.output_z(z4));
 
 multiplier2 #(32,23,8,255)
 m5(.clk(clk),.rst(rst),.en(enable[5]),.input_a(single_a),.input_b(single_b),.complete(complete5),.output_z(z5));
 
  multiplier2 #(64,52,11,2047)
 m6(.clk(clk),.rst(rst),.en(enable[6]),.input_a(double_a),.input_b(double_b),.complete(complete6),.output_z(z6));
 
 doubletofloat m7(.clk(clk),.rst(rst),.en(enable[7]),.input_a(double_a),.complete(complete7),.output_z(z7));
 
 doubletosint m8(.clk(clk),.rst(rst),.en(enable[8]),.input_a(double_a),.complete(complete8),.output_z(z8));
 
 doubletounsint m9(.clk(clk),.rst(rst),.en(enable[9]),.input_a(double_a),.complete(complete9),.output_z(z9));
 
 floattodouble m10(.clk(clk),.rst(rst),.en(enable[10]),.input_a(single_a),.complete(complete10),.output_z(z10));
 
 floattosint m11(.clk(clk),.rst(rst),.en(enable[11]),.input_a(single_a),.complete(complete11),.output_z(z11));
 
 floattounsint m12(.clk(clk),.rst(rst),.en(enable[12]),.input_a(single_a),.complete(complete12),.output_z(z12));
 
 sinttodouble m13(.clk(clk),.rst(rst),.en(enable[13]),.input_a(single_a),.complete(complete13),.output_z(z13));
 
 sinttofloat m14(.clk(clk),.rst(rst),.en(enable[14]),.input_a(single_a),.complete(complete14),.output_z(z14));
 
 unsinttodouble m15(.clk(clk),.rst(rst),.en(enable[15]),.input_a(single_a),.complete(complete15),.output_z(z15));
 
 unsinttofloat m16(.clk(clk),.rst(rst),.en(enable[0]),.input_a(single_a),.complete(complete16),.output_z(z16));
 
 endmodule
