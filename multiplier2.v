`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/07 08:41:55
// Design Name: 
// Module Name: multiplier2
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

//IEEE Floating Point Multiplier (Single Precision)
//Copyright (C) Jonathan P Dawson 2013
//2013-12-12
module multiplier2 #
(
	parameter integer WIDTH = 32,						//double=64
	parameter integer MANTISSA_WIDTH = 23, 			//double=52:
	parameter integer EXPONENT_WIDTH = 8,				//double=11;
	parameter integer MAX_EXPONENT = 255				//double=2047;
)
(
	input     clk,
	input     rst,
	input     en,
	input     [WIDTH-1:0] input_a,
	input     [WIDTH-1:0] input_b,
	output    [WIDTH-1:0] output_z,
	output complete
);

	reg       [WIDTH-1:0] s_output_z;

	reg       [WIDTH-1:0] a, b, z;
	reg       [MANTISSA_WIDTH:0] a_m, b_m, z_m;
	reg       [EXPONENT_WIDTH+1:0] a_e, b_e, z_e;
	reg       a_s, b_s, z_s;
	reg       guard, round_bit, sticky;
	reg       [MANTISSA_WIDTH*2-1:0] product;
	reg			s_complete;
	reg       [3:0] state;
	parameter start		  = 4'd0,
			unpack        = 4'd1,
			special_cases = 4'd2,
			normalise_a   = 4'd3,
			normalise_b   = 4'd4,
			multiply      = 4'd5,
			ck_m_ofw      = 4'd6,
			normalise     = 4'd7,
		    round         = 4'd8,
			pack          = 4'd9,
			put_z         = 4'd10;
 
  always @(posedge clk)
  begin
if(!en)
          begin
              s_output_z <= 0;
			  s_complete <= 0;
          end
       else
      begin
      if( a == input_a)
      begin
        s_complete <=1;
       end
       else
       s_complete<=0;
    case(state)

        start:
		begin
			a <= input_a;
			b <= input_b;
	//		s_complete <= 0;
			state <= unpack;
		end

		unpack:
		begin
			a_m <= a[MANTISSA_WIDTH-1 : 0];
			b_m <= b[MANTISSA_WIDTH-1 : 0];
			a_e <= a[WIDTH-2 : MANTISSA_WIDTH];
			b_e <= b[WIDTH-2 : MANTISSA_WIDTH];
			a_s <= a[WIDTH-1];
			b_s <= b[WIDTH-1];
			state <= special_cases;
		end

		special_cases:
		begin 
			//if a is NaN or b is NaN return NaN
			if((a_e == MAX_EXPONENT && a_m != 0)||(b_e == MAX_EXPONENT && b_m != 0))
			begin 
				z[WIDTH-1] <= 1;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[MANTISSA_WIDTH-1] <= 1;
				z[MANTISSA_WIDTH-2:0] <= 0;
				state <= put_z;
			end 
			// if a is infinity return infinity
			else if(a_e == MAX_EXPONENT)
			begin
				z[WIDTH-1] <= a_s ^ b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <=put_z;
			end
           //if b is infinity return infinity
			else if(b_e == MAX_EXPONENT)
			begin 
				z[WIDTH-1] <= a_s ^ b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <= put_z;
			end
			//if a is zero return zero
			else if ((a_e == 0) && (a_m == 0)) 
			begin
				z[WIDTH-1] <= a_s ^ b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= 0;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <= put_z;
			end
			//if b is zero return zero
			else if ((b_e == 0) && (b_m == 0)) 
			begin
				z[WIDTH-1] <= a_s ^ b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= 0;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <= put_z;
			end 
			else 
			begin
				//Denormalised Number
				if (a_e == 0) 
				begin
					a_e <= 1;
				end 
				else 
				begin
					a_m[MANTISSA_WIDTH] <= 1;
				end
				//Denormalised Number
				if (b_e == 0) 
				begin
					b_e <= 1;
				end 
				else 
				begin
					b_m[MANTISSA_WIDTH] <= 1;
				end
				state <= normalise_a;
			end
		end

		normalise_a:
		begin
			if (a_m[MANTISSA_WIDTH]) 
			begin
				state <= normalise_b;
			end 
			else 
			begin
				a_m <= a_m << 1;
				a_e <= a_e - 1;
			end
		end

		normalise_b:
		begin
			if (b_m[MANTISSA_WIDTH]) 
			begin
				state <= multiply;
			end 
			else 
			begin
				b_m <= b_m << 1;
				b_e <= b_e - 1;
			end
		end
		//the int digits can be 01,10,11
		multiply:
		begin
			z_s <= a_s ^ b_s;
			z_e <= a_e + b_e-((MAX_EXPONENT+1)/2-1);
			product <= a_m * b_m ;
			state <= ck_m_ofw;
		end
		
		ck_m_ofw:
		begin
			if(product[MANTISSA_WIDTH*2-1])
			begin
				z_m <= product[MANTISSA_WIDTH*2-1:MANTISSA_WIDTH+1];
				guard <= product[MANTISSA_WIDTH];
				round_bit <= product[MANTISSA_WIDTH-1];
				sticky <= (product[MANTISSA_WIDTH-2:0] != 0);
				z_e <= z_e + 1;
			end
			else
			begin
				z_m <= product[MANTISSA_WIDTH*2-2:MANTISSA_WIDTH];
				guard <= product[MANTISSA_WIDTH-1];
				round_bit <= product[MANTISSA_WIDTH-2];
				sticky <= (product[MANTISSA_WIDTH-3:0] != 0);
			end
			state <= normalise;
		end
     
		
		normalise:
         begin
            if (($signed(z_e) < 1) &&($signed(z_e) > (-1-MANTISSA_WIDTH)))
            begin
                z_e <= z_e + 1;
                z_m <= z_m >> 1;
                guard <= z_m[0];
                round_bit <= guard;
                sticky <= sticky | round_bit;
            end 
            else if($signed(z_e)<= (-1-MANTISSA_WIDTH))
            begin
                z_e <= 0;
                z_m <= 0;
                state <= round;
            end
            else
                state <=round;
           end              

		round:
		begin
			if (guard && (round_bit | sticky | z_m[0]))
			begin
				z_m <= z_m + 1;
				if (z_m == 24'hffffff) 
				begin
					z_e <=z_e + 1;
				end
				state <= pack;
			end
			else
			begin
			state <= pack;
			end
		end

        pack:
		begin
		//if overflow occurs, return inf
			if ($signed(z_e) > MAX_EXPONENT-1)
			begin
				z[MANTISSA_WIDTH-1:0] <= 0;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[WIDTH-1] <= z_s;
			end
			//if denormalised,return denormalised
			//if underflow, return 0
			else if(z_e == 1 && z_m[MANTISSA_WIDTH] == 0)
            begin
                z[MANTISSA_WIDTH-1:0] <= z_m[MANTISSA_WIDTH-1:0];
				z[WIDTH-2 : MANTISSA_WIDTH] <= 0;
				z[WIDTH-1] <= z_s;
            end
            else
            begin
                z[MANTISSA_WIDTH-1:0] <= z_m[MANTISSA_WIDTH-1:0];
				z[WIDTH-2 : MANTISSA_WIDTH] <= z_e[EXPONENT_WIDTH-1:0];
				z[WIDTH-1] <= z_s;
            end
			state <= put_z;
		end

		put_z:
		begin
			s_output_z <= z;
			s_complete <= 1;
			state <= start;
		end
		
		default:
		begin
			state <= start;
		end
    endcase

    if (rst == 1) 
		begin
		  state <= start;
		end       

	end
 end 
	assign output_z = s_output_z;
	assign complete = s_complete;

endmodule
