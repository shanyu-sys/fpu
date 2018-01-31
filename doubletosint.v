`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 13:42:27
// Design Name: 
// Module Name: doubletosint
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


module doubletosint(
         input_a,
        clk,
        rst,
        en,
		complete,
        output_z);

  input     clk;
  input     rst;
  input     en;

  input     [63:0] input_a;
  output    [31:0] output_z;
  	output complete;
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

  reg [31:0] a_m, z;
  reg [63:0] a;
  reg [11:0] a_e;
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
        a_m[31:0] <= {1'b1, a[51 : 21]};
        a_e <= a[62 : 52] - 1023;
        a_s <= a[63];
		guard <= a[20];
		round_bit <= a[19];
		sticky <=a[18];
		state <= special_cases;
      end

      special_cases:
      begin
	  //if a is denormalise or 0,return 0
	  //if a_e < -1,return 0
        if ($signed(a_e) < -1) 
		begin
          z <= 0;
          state <= put_z;
        end 
		//if a_e>31,return the maximum or the minimum
		else if ($signed(a_e) >= 31)
		begin
          z <= a_s? 32'h80000000:32'h7FFFFFFF;
          state <= put_z;
        end 
		// a_e<31 && a_e >=-1
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
		if(a_m[31])
		begin
			z <= a_s?32'h80000000:32'h7FFFFFFF;
		end
		else 
		begin
			z<= a_s?-a_m:a_m;
		end
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
