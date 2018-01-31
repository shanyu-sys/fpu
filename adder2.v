`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/06 19:54:51
// Design Name: 
// Module Name: adder2
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


module adder2 #
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
	reg       [MANTISSA_WIDTH+3:0] a_m, b_m;
	reg       [MANTISSA_WIDTH:0] z_m;
	reg       [EXPONENT_WIDTH:0] a_e, b_e, z_e;
	reg       a_s, b_s, z_s;
	reg       guard, round_bit, sticky;
	reg       [MANTISSA_WIDTH+4:0] sum;
    reg       s_complete;
	reg       [3:0] state;
	parameter start	  = 4'd0,
			unpack        = 4'd1,
			special_cases = 4'd2,
			align         = 4'd3,
			add_m         = 4'd4,
			ck_m_zero	  = 4'd5,
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
	case(state)
		start:
		begin
			a <= input_a;
			b <= input_b;
			s_complete <= 0;
			state <= unpack;
		end
		unpack:
		begin
			a_m <= {a[MANTISSA_WIDTH-1 : 0], 3'd0};
			b_m <= {b[MANTISSA_WIDTH-1 : 0], 3'd0};
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
				z[WIDTH-1] <= a_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <=put_z;
			end
			//if b is infinity return infinity
			else if(b_e == MAX_EXPONENT)
			begin 
				z[WIDTH-1] <= b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[MANTISSA_WIDTH-1:0] <= 0;
				state <= put_z;
			end
			//if a is zero return b
			else if(((a_e == 0)&&(a_m == 0))||((b_e > a_e)&&(b_e - a_e > MANTISSA_WIDTH+2)))
			begin 
				z[WIDTH-1] <= b_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= b_e;
				z[MANTISSA_WIDTH-1:0] <= b[MANTISSA_WIDTH-1:0];
				state <= put_z;
			end
			//if b is zero return a
			else if(((b_e == 0) && (b_m == 0))||((a_e > b_e)&&(a_e - b_e >MANTISSA_WIDTH+2)))
			begin 
				z[WIDTH-1] <= a_s;
				z[WIDTH-2 : MANTISSA_WIDTH] <= a_e;
				z[MANTISSA_WIDTH-1:0] <= a[MANTISSA_WIDTH-1:0];
				state <= put_z;
			end 
			else
			begin
				// denormalised number 
				if(a_e == 0) 
				begin 
					a_e <= 1;
				end 
				else 
				begin 
					a_m[MANTISSA_WIDTH+3] <= 1;
				end
				// denormalised number
				if(b_e == 0)
				begin 
					b_e <= 1;
				end 
				else
				begin
					b_m[MANTISSA_WIDTH+3] <= 1;
				end
				state <= align;
			end
		end

		align:
			begin
				if(a_e > b_e)
				begin
					b_e <= b_e + 1;
					b_m <= b_m >> 1;
					b_m[0] <= b_m[0] | b_m[1];
				end
				else if(a_e < b_e)
				begin
					a_e <= a_e + 1;
					a_m <= a_m >> 1;
					a_m[0] <= a_m[0] | a_m[1];
				end
				else
				begin
					state <= add_m;
				end
			end

		add_m:
            begin
                z_e <= a_e;
                if(a_s == b_s)
                begin
                    sum <= a_m + b_m;
                    z_s <= a_s;
                end
                else 
                begin
                    if(a_m >= b_m)
                    begin
                        sum <= a_m - b_m;
                        z_s <= a_s;
                    end
                    else
                    begin
                        sum <= b_m - a_m;
                        z_s <= b_s;
                    end
                end
                state <= ck_m_zero;
            end

		ck_m_zero:
            begin
                if(sum == 0)
                begin
                    z_m <= 0;
                    z_e <= 0;
                    state <= pack;
                end
                else
                begin
                    state <= ck_m_ofw;
                end
            end

		ck_m_ofw:
            begin
                if(sum[MANTISSA_WIDTH+4])
                begin
                    z_m <= sum[MANTISSA_WIDTH+4:4];
					guard <= sum[3];
					round_bit <= sum[2];
					sticky <= sum[1] | sum[0];
                    z_e <= z_e + 1;
                end
                else 
                begin
                    z_m <= sum[MANTISSA_WIDTH+3:3];
				    guard <= sum[2];
				    round_bit <= sum[1];
				    sticky <= sum[0];
                end
                state <= normalise;
            end

		normalise:
		begin
			if (z_m[MANTISSA_WIDTH] == 0 && z_e >1) 
			begin
				z_e <= z_e - 1;
				z_m <= z_m << 1;
				z_m[0] <= guard;
				guard <= round_bit;
				round_bit <= 0;
			end
			else 
			begin
				state <= round;
			end
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
			if (z_e > MAX_EXPONENT-1)
			begin
				z[MANTISSA_WIDTH-1:0] <= 0;
				z[WIDTH-2 : MANTISSA_WIDTH] <= MAX_EXPONENT;
				z[WIDTH-1] <= z_s;
			end
			//if denormalised,return denormalised
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
