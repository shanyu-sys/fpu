`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 10:39:59
// Design Name: 
// Module Name: floattodouble
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


//Integer to IEEE Floating Point Converter (Double Precision)
//Copyright (C) Jonathan P Dawson 2013
//2013-12-12
module floattodouble(
        input_a,
        clk,
        rst,
        en,
		complete,
        output_z);

  input     clk;
  input     rst;
input   en;
  input     [31:0] input_a;
  output    [63:0] output_z;
    output complete;
  reg       [63:0] s_output_z;
   reg	 s_complete;
 
 
  reg       [1:0] state;
  parameter get_a         = 3'd0,
            convert_0     = 3'd1,
            normalise_0   = 3'd2,
            put_z         = 3'd3;

  reg [63:0] z;
  reg [10:0] z_e;
  reg [52:0] z_m;
  reg [31:0] a;

  always @(posedge clk)
  begin
if(!en)
          begin
              s_output_z <= 0;
			  s_complete <= 0;
          end
       else
      begin
    case(state)

      get_a:
      begin
          a <= input_a;
		  s_complete <= 0;
          state <= convert_0;
      end

      convert_0:
      begin
		z[63] <= a[31];
		z[51:0] <= {a[22:0], 29'd0};
		//if a is denormalize,go to normalize;if a is 0,return 0
        if (a[30:23] == 0)
		begin
            if (a[22:0]) 
			begin
                state <= normalise_0;
                z_e <= 897;
                z_m <= {1'd0, a[22:0], 29'd0};
            end
			else
			begin
            z[62:52] <= 0;
			state <= put_z;
			end
        end
		//if a is inf return inf
		else if (a[30:23] == 255) 
		begin
            z[62:52] <= 2047;
			state <= put_z;
        end
		// a is normal
		else
		begin
			z[62:52] <= (a[30:23] - 127) + 1023;
			state <= put_z;
		end
		
        
      end

      normalise_0:
      begin
        if (z_m[52]) begin
          z[62:52] <= z_e;
          z[51:0] <= z_m[51:0];
          state <= put_z;
        end else begin
          z_m <= {z_m[51:0], 1'd0};
          z_e <= z_e - 1;
        end
      end

      put_z:
      begin
        s_output_z <= z;
		s_complete <= 1;
        state <= get_a;
      end

    endcase

    if (rst == 1) begin
      state <= get_a;
     
    end
end
  end
  assign output_z = s_output_z;
   assign complete = s_complete;
 
endmodule
