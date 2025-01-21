
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  reg [13:0] 	gray_addr;
output  reg       	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  reg [13:0] 	lbp_addr;
output  reg	lbp_valid;
output  reg [7:0] 	lbp_data;
output  reg	finish;


//----------reg-----------//
reg [13:0] counter;//y,x
reg [3:0] state;
reg [7:0] input_buffer;
reg [7:0] temp_0;
reg [7:0] temp_1;
reg [7:0] temp_3;
reg [7:0] temp_P;
reg [7:0] temp_5;
reg [7:0] temp_6;
reg [7:0] pixel;
reg [7:0] result;
//----------wire-----------//
wire z_in;
wire z_t0;
wire z_t1;
wire z_t3;
wire z_t5;
wire z_t6;

//counter
always @(posedge clk or posedge reset) begin
    if (reset || !gray_ready) counter <= 14'b0;
    else if(counter == 14'd16383) counter <= counter;
    else if(counter[6:0] == 7'b0 || counter[6:0] == 7'd127 || counter[13:7] == 7'b0 || counter[13:7] == 7'd127)
        counter <= counter + 14'd1;
    else if(counter[6:0] == 7'd1 && state == 4'd9) counter <= counter + 14'd1;
    else if(counter[6:0] != 7'd1 && state == 4'd3) counter <= counter + 14'd1;
    else counter <= counter;
end

//state
always @(posedge clk or posedge reset) begin
    if (reset) state <= 4'b0;
    else if(counter == 14'd16383) state <= state + 4'd1;
    else if(counter[6:0] == 7'b0 || counter[6:0] == 7'd127 || counter[13:7] == 7'b0 || counter[13:7] == 7'd127)
        state <= 4'b0;
    else if(counter[6:0] == 7'd1 && state == 4'd9) state <= 4'b0;
    else if(counter[6:0] != 7'd1 && state == 4'd3) state <= 4'b0;
    else state <= state + 4'd1;
end

//gray addr
always @(posedge clk or posedge reset) begin
    if(reset) gray_addr <= 14'd0;
    else if(counter[6:0] == 7'b0) gray_addr <= counter + 14'd1;//pre read next pixel.
    else if(counter[6:0] == 7'd1) 
        case (state)
            4'd0: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] - 7'd1};//0
            4'd1: gray_addr <= {counter[13:7] - 7'd1, counter[6:0]};
            4'd2: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] + 7'd1};
            4'd3: gray_addr <= {counter[13:7], counter[6:0] - 7'd1};
            4'd4: gray_addr <= {counter[13:7], counter[6:0] + 7'd1};
            4'd5: gray_addr <= {counter[13:7] + 7'd1, counter[6:0] - 7'd1};
            4'd6: gray_addr <= {counter[13:7] + 7'd1, counter[6:0]};
            4'd7: gray_addr <= {counter[13:7] + 7'd1, counter[6:0] + 7'd1};
            4'd9: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] + 7'd2};//pre read
            default: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] + 7'd2};
        endcase
    else
        case (state)
            4'd0: gray_addr <= {counter[13:7], counter[6:0] + 7'd1};
            4'd1: gray_addr <= {counter[13:7] + 7'd1, counter[6:0] + 7'd1};
            4'd3: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] + 7'd2};//pre read
            default: gray_addr <= {counter[13:7] - 7'd1, counter[6:0] + 7'd2};
        endcase
end

//gray_requst
always @(posedge clk) begin
    gray_req <= 1'd1;
end

//input buffer
always @(posedge clk or posedge reset) begin
    if(reset) input_buffer <= 8'd0;
    else input_buffer <= gray_data;
end
//pixel
always @(posedge clk or posedge reset) begin
    if(reset) result <= 8'd0;
    else if(counter[6:0] == 7'b0 || counter[6:0] == 7'd127 || counter[13:7] == 7'b0 || counter[13:7] == 7'd127)
        pixel <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd1)
        pixel <= input_buffer;
    else if(state == 4'd0)
        pixel <= temp_P;
    else pixel <= pixel;
end
//z function
assign z_in = (input_buffer >= pixel) ? 1 : 0;
assign z_t0 = (temp_0 >= temp_P) ? 1 : 0;
assign z_t1 = (temp_1 >= temp_P) ? 1 : 0;
assign z_t3 = (temp_3 >= temp_P) ? 1 : 0;
assign z_t5 = (temp_5 >= temp_P) ? 1 : 0;
assign z_t6 = (temp_6 >= temp_P) ? 1 : 0;
integer i;
//result
always @(posedge clk or posedge reset) begin
    if(reset) result <= 8'd0;
    else if(counter[6:0] == 7'b0 || counter[6:0] == 7'd127 || counter[13:7] == 7'b0 || counter[13:7] == 7'd127)
        result <= 8'd0;
    else if(counter[6:0] == 7'd1)
    /*
        case (state)
            4'd2: result <= {7'd0, z_in};
            4'd3: result <= result + {6'd0, z_in, 1'd0};
            4'd4: result <= result + {5'd0, z_in, 2'd0};
            4'd5: result <= result + {4'd0, z_in, 3'd0};
            4'd6: result <= result + {3'd0, z_in, 4'd0};
            4'd7: result <= result + {2'd0, z_in, 5'd0};
            4'd8: result <= result + {1'd0, z_in, 6'd0};
            4'd9: result <= result + {z_in, 7'd0};
            default: result <= result;
        endcase
        */
        for(i = 0; i <= 7; i = i + 1)
            if(i[4:0] == state - 4'd2)
                result[i] = z_in;
            else result[i] <= result[i];
    else 
        case (state)
            4'd0: begin
                result[0] <= z_t0;
                result[1] <= z_t1;
                result[2] <= result[2];
                result[3] <= z_t3;
                result[4] <= result[4];
                result[5] <= z_t5;
                result[6] <= z_t6;
                result[7] <= result[7];
            end
            4'd1: begin
                result[0] <= result[0];
                result[1] <= result[1];
                result[2] <= z_in;
                result[3] <= result[3];
                result[4] <= result[4];
                result[5] <= result[5];
                result[6] <= result[6];
                result[7] <= result[7];
            end
            4'd2:begin
                result[0] <= result[0];
                result[1] <= result[1];
                result[2] <= result[2];
                result[3] <= result[3];
                result[4] <= z_in;
                result[5] <= result[5];
                result[6] <= result[6];
                result[7] <= result[7];
            end
            4'd3:begin
                result[0] <= result[0];
                result[1] <= result[1];
                result[2] <= result[2];
                result[3] <= result[3];
                result[4] <= result[4];
                result[5] <= result[5];
                result[6] <= result[6];
                result[7] <= z_in;
            end
            default: result <= result;
        endcase
end

//temp reg 0
always @(posedge clk or posedge reset) begin
    if(reset) temp_0 <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd3) temp_0 <= input_buffer;
    else if(state == 4'd0) temp_0 <= temp_1;
    else temp_0 <= temp_0;
end
//temp reg 1
always @(posedge clk or posedge reset) begin
    if(reset) temp_1 <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd4) temp_1 <= input_buffer;
    else if(state == 4'd1) temp_1 <= input_buffer;
    else temp_1 <= temp_1;
end
//temp reg 3
always @(posedge clk or posedge reset) begin
    if(reset) temp_3 <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd1) temp_3 <= input_buffer;
    else if(state == 4'd0) temp_3 <= temp_P;
    else temp_3 <= temp_3;
end
//temp reg P
always @(posedge clk or posedge reset) begin
    if(reset) temp_P <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd6) temp_P <= input_buffer;
    else if(state == 4'd2) temp_P <= input_buffer;
    else temp_P <= temp_P;
end
//temp reg 5
always @(posedge clk or posedge reset) begin
    if(reset) temp_5 <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd8) temp_5 <= input_buffer;
    else if(state == 4'd0) temp_5 <= temp_6;
    else temp_5 <= temp_5;
end
//temp reg 6
always @(posedge clk or posedge reset) begin
    if(reset) temp_6 <= 8'd0;
    else if(counter[6:0] == 7'd1 && state == 4'd9) temp_6 <= input_buffer;
    else if(state == 4'd3) temp_6 <= input_buffer;
    else temp_6 <= temp_6;
end
//lbp
always @(posedge clk or posedge reset) begin
    if(reset) lbp_addr <= 14'd0;
    else lbp_addr <= counter - 14'd1;
end
always @(posedge clk or posedge reset)begin
    if(reset) lbp_valid <= 1'd0;
    else if(state == 4'd0) lbp_valid <= 1'd1;
    else lbp_valid <= 1'd0;
end
always @(posedge clk or posedge reset)begin
    if(reset) lbp_data <= 7'd0;
    else lbp_data <= result;
end
always @(posedge clk or posedge reset) begin
    if(reset) finish <= 1'd0;
    else if(counter == 14'd16383 && state == 4'd4) finish <= 1'd1;
    else finish <= finish;
end

endmodule

