`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 13:20:35
// Design Name: 
// Module Name: floattounsint
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

module floattounsint(
        input_a,
        clk,
        rst,
        en,
		complete,
        output_z);

  input     clk;
  input     rst;
input en;
  input     [31:0] input_a;
     output complete;
  output    [31:0] output_z;
  reg       [31:0] s_output_z;
   reg	 s_complete;
 
  reg       [2:0] state;
  parameter get_a         = 3'd0,
            special_cases = 3'd1,
            unpack        = 3'd2,
            shift         = 3'd3,
			round 		  = 3'd4,
			pack		  = 3'd5,
            put_z         = 3'd6;

  reg [31:0] a_m, a, z;
  reg [8:0] a_e;
  reg a_s;
	reg guard;
	reg round_bit;
	reg sticky;

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
        a_m[31:8] <= {1'b1, a[22 : 0]};
        a_m[7:0] <= 0;
        a_e <= a[30 : 23] - 127;
        a_s <= a[31];
		guard <= 0;
		round_bit <= 0;
		sticky <=0;
		state <= special_cases;
      end

      special_cases:
      begin
	  //if a is denormalise or 0,return 0
	  //if a_e < -1,return 0
	  //if a_s =1,return 0
        if (a_s||$signed(a_e) < -1) 
		begin
          z <= 0;
          state <= put_z;
        end 
		//if a_e>31,return the maximum 
		else if ($signed(a_e) > 31)
		begin
          z <= 32'hffffffff;
          state <= put_z;
        end 
		// a_e<=31 && a_e >=-1
		else 
		begin
          state <= shift;
        end
      end

      shift:
      begin
        if ($signed(a_e) < 31 )
		begin
          a_e <= a_e + 1;
          a_m <= a_m >> 1;
		  guard <= a_m[0];
		  round_bit <= guard;
		  sticky <= sticky | round_bit;
        end 
		else
		begin
          state <= round;
		end
      end
	  
	  
	  round:
	  begin
		if(guard && (round_bit | sticky))
		begin
			a_m <= a_m + 1;
		end
		state <= pack;
	end
	
	pack:
	begin
		z<= a_m;
		state <= put_z;
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