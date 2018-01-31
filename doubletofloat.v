`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 09:47:39
// Design Name: 
// Module Name: doubletofloat
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


module doubletofloat(
        input_a,
        clk,
        rst,
        en,
		complete,
        output_z);   

	input     clk;
	input     rst;
	input      en;

	input     [63:0] input_a;
	output    [31:0] output_z;
	output complete;
	reg       [31:0] s_output_z;
	reg	 s_complete;
	
	reg [63:0] a;
	reg [31:0] z;
	reg [10:0] z_e;
	reg [23:0] z_m;
	reg guard;
	reg round;
	reg sticky;
	reg       [1:0] state;
	parameter get_a         = 3'd0,
			unpack        = 3'd1,
			denormalise   = 3'd2,
			put_z         = 3'd3;



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
			state <= unpack;
		end

      unpack:
      begin
        z[31] <= a[63];
        state <= put_z;
		//if a_e= 0, return 0
        if (a[62:52] == 0) 
		begin
            z[30:23] <= 0;
            z[22:0] <= 0;
        end 
		//if a_e<1023-127-1,return denormalise
		else if (a[62:52] < 897) 
		begin
            z[30:23] <= 0;
            z_m <= {1'd1, a[51:29]};
            z_e <= a[62:52];
            guard <= a[28];
            round <= a[27];
            sticky <= a[26:0] != 0;
            state <= denormalise;
		end 
		//if a is inf or NaN return inf or NaN
		else if (a[62:52] == 2047) 
		begin
            z[30:23] <= 255;
            z[22:0] <= 0;			//return NaN
            if (a[51:0]) 
			begin
                z[22] <= 1;			//return inf
            end
        end
		//if a_e>1023+127,return inf
		else if (a[62:52] > 1150) 
		begin
            z[30:23] <= 255;
            z[22:0] <= 0;
        end 
		//a_e =normal
		else 
		begin
            z[30:23] <= (a[62:52] - 1023) + 127;
            if (a[28] && (a[27] || a[26:0])) begin
                z[22:0] <= a[51:29] + 1;
            end else begin
                z[22:0] <= a[51:29];
            end
        end
      end

      denormalise:
      begin
        if (z_e == 897 || (z_m == 0 && guard == 0))
		begin
            state <= put_z;
            z[22:0] <= z_m;
            if (guard && (round || sticky)) begin
                z[22:0] <= z_m + 1;
            end
        end 
		else 
		begin
            z_e <= z_e + 1;
            z_m <= {1'd0, z_m[23:1]};
            guard <= z_m[0];
            round <= guard;
            sticky <= sticky | round;
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