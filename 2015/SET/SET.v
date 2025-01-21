module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;
//-------------reg--------------//
reg [1:0] mode_reg;
reg start;
reg [6:0] point;
reg [2:0] counter;
reg [8:0] distance;
//0:A, 1:B, 2:C
reg [23:0] central_reg;
reg [3:0] radius_reg[2:0];
reg [7:0] radius_sq[2:0];
reg is_contained[2:0];
reg [3:0] sq_input;
//------------wire--------------//
wire [7:0] sq_output;
wire [4:0] center_minus_x[2:0];
wire [4:0] center_minus_y[2:0];
wire [3:0] abs_x[2:0];
wire [3:0] abs_y[2:0];
//-----------module-------------//
Square sqA(.num(sq_input), .result(sq_output));
//central_reg
always @(posedge clk or posedge rst) begin
    if(rst) central_reg <= 24'd0;
    else if(en) begin
        central_reg <= central;
    end
    else central_reg <= central_reg;
end

//radius_reg
always @(posedge clk or posedge rst) begin
    if(rst) begin
        radius_reg[0] <= 4'd0;
        radius_reg[1] <= 4'd0;
        radius_reg[2] <= 4'd0;
    end
    else if(en) begin
        radius_reg[0] <= radius[11:8];
        radius_reg[1] <= radius[7:4];
        radius_reg[2] <= radius[3:0];
    end
    else begin
        radius_reg[0] <= radius_reg[0];
        radius_reg[1] <= radius_reg[1];
        radius_reg[2] <= radius_reg[2];
    end
end

//radius_sq
always @(posedge clk or posedge rst) begin
    if(rst) begin
        radius_sq[0] <= 8'd0;
        radius_sq[1] <= 8'd0;
        radius_sq[2] <= 8'd0;
    end
    else if(!start) 
    case(counter)
        3'd1: begin
            radius_sq[0] <= sq_output;
            radius_sq[1] <= 8'd0;
            radius_sq[2] <= 8'd0;
        end
        3'd2: begin
            radius_sq[0] <= radius_sq[0];
            radius_sq[1] <= sq_output;
            radius_sq[2] <= 8'd0;
        end
        3'd3: begin
            radius_sq[0] <= radius_sq[0];
            radius_sq[1] <= radius_sq[1];
            radius_sq[2] <= sq_output;
        end
        default: begin
            radius_sq[0] <= radius_sq[0];
            radius_sq[1] <= radius_sq[1];
            radius_sq[2] <= radius_sq[2];
        end
    endcase
    else begin
        radius_sq[0] <= radius_sq[0];
        radius_sq[1] <= radius_sq[1];
        radius_sq[2] <= radius_sq[2];
    end
end

//start
always @(posedge clk or posedge rst) begin
    if(rst) start <= 1'd0;
    else if(!busy)start <= 1'd0;
    else if(counter == 3'd3)start <= 1'd1;
    else start <= start;
end
//busy
always @(posedge clk or posedge rst) begin
    if(rst) busy <= 1'd0;
    else if(en) busy <= 1'd1;
    else if(point[6] && counter == 3'd4) busy <= 1'd0;
    else busy <= busy;
end
//valid
always @(posedge clk or posedge rst) begin
    if(rst) valid <= 1'd0;
    else if(point[6] && counter[1:0] == 2'd3) valid <= 1'd1;
    else valid <= 1'd0;
end

//point
always @(posedge clk or posedge rst) begin
    if(rst) point <= 7'd0;
    else if(!start) point <= 7'd0;
    else if(counter == 3'd5) point <= point + 7'd1;
    else point <= point;
end

//counter 
always @(posedge clk or posedge rst) begin
    if(rst) counter <= 3'd0;
    else if(!busy) counter <= 3'd0;
    else if(!start && counter == 3'd3) counter <= 3'd0;
    else if(counter == 3'd5) counter <= 3'd0;
    else counter <= counter + 3'd1;
end
//counter |center - A/B/C|
assign center_minus_x[0] = {2'd0, point[2:0]} - {1'd0, central_reg[23:20]} + 5'd1;
assign center_minus_x[1] = {2'd0, point[2:0]} - {1'd0, central_reg[15:12]} + 5'd1;
assign center_minus_x[2] = {2'd0, point[2:0]} - {1'd0, central_reg[7:4]} + 5'd1;
assign center_minus_y[0] = {2'd0, point[5:3]} - {1'd0, central_reg[19:16]} + 5'd1;
assign center_minus_y[1] = {2'd0, point[5:3]} - {1'd0, central_reg[11:8]} + 5'd1;
assign center_minus_y[2] = {2'd0, point[5:3]} - {1'd0, central_reg[3:0]} + 5'd1;

assign abs_x[0] = center_minus_x[0][4] ? -center_minus_x[0][3:0] : center_minus_x[0][3:0];
assign abs_x[1] = center_minus_x[1][4] ? -center_minus_x[1][3:0] : center_minus_x[1][3:0];
assign abs_x[2] = center_minus_x[2][4] ? -center_minus_x[2][3:0] : center_minus_x[2][3:0];
assign abs_y[0] = center_minus_y[0][4] ? -center_minus_y[0][3:0] : center_minus_y[0][3:0];
assign abs_y[1] = center_minus_y[1][4] ? -center_minus_y[1][3:0] : center_minus_y[1][3:0];
assign abs_y[2] = center_minus_y[2][4] ? -center_minus_y[2][3:0] : center_minus_y[2][3:0];

//square io
always @(posedge clk or posedge rst) begin
    if(rst) sq_input <= 4'd0;
    else if(!start) sq_input <= radius_reg[counter];
    else sq_input <= ~counter[0] ? abs_x[counter[2:1]] : abs_y[counter[2:1]];
end

//distance
always @(posedge clk or posedge rst) begin
    if(rst) distance <= 9'd0;
    else distance <= counter[0] ? {1'd0, sq_output} : distance + {1'd0, sq_output[6:0]};
end

//is contained
always @(posedge clk or posedge rst) begin
    if(rst)begin
        is_contained[0] <= 1'd0;
        is_contained[1] <= 1'd0;
        is_contained[2] <= 1'd0;
    end
    else 
        case(counter)
        3'd3: begin
            is_contained[0] <= distance <= {1'd0, radius_sq[0]} ? 1'd1: 1'd0;
            is_contained[1] <= 1'd0;
            is_contained[2] <= 1'd0;
        end
        3'd5: begin
            is_contained[0] <= is_contained[0];
            is_contained[1] <= distance <= {1'd0, radius_sq[1]} ? 1'd1: 1'd0;
            is_contained[2] <= 1'd0;
        end
        3'd1: begin
            is_contained[0] <= is_contained[0];
            is_contained[1] <= is_contained[1];
            is_contained[2] <= distance <= {1'd0, radius_sq[2]} ? 1'd1: 1'd0;
        end
        default: begin
            is_contained[0] <= is_contained[0];
            is_contained[1] <= is_contained[1];
            is_contained[2] <= is_contained[2];
        end
        endcase
end

//candidate
always @(posedge clk or posedge rst) begin
    if(rst) candidate <= 1'd0;
    else if(!start) candidate <= 8'd0;
    else if(counter == 3'd2 && point != 6'd0)
        case (mode)
            2'd0: candidate <= is_contained[0] ? candidate + 8'd1 : candidate;
            2'd1: candidate <= is_contained[0] & is_contained[1] ? candidate + 8'd1 : candidate;
            2'd2: candidate <= is_contained[0] ^ is_contained[1] ? candidate + 8'd1 : candidate;
            2'd3: candidate <= (is_contained[0] & is_contained[1] & ~is_contained[2]) | 
                               (is_contained[1] & is_contained[2] & ~is_contained[0]) |
                               (is_contained[2] & is_contained[0] & ~is_contained[1]) ? candidate + 8'd1 : candidate;
            default: candidate <= is_contained[0] ? candidate + 8'd1 : candidate;
        endcase
    else candidate <= candidate;
end

endmodule



module Square (
    input [3:0] num,
    output [7:0] result
);
wire [7:0] temp[3:0];
genvar i;
generate
    for(i = 0; i <= 3; i = i + 1)begin: gener
        assign temp[i] = num[i] ? {{(4-i){1'd0}}, num, {i{1'd0}}} : 8'd0 ;
    end
endgenerate
assign result = temp[0] + temp[1] + temp[2] + temp[3];
endmodule

