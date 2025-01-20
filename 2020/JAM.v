module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid 
);
//----------mode-------//
localparam FIND_TOTAL = 2'd0;
localparam COUNT_T = 2'd1;
localparam FIND_NEAR = 2'd2;
localparam FIND_MIN = 2'd3;
integer i;
reg [1:0]mode;
reg [5:0]cc;//total 64 case
reg [2:0]counter;
reg [2:0]pattern[7:0];
reg [2:0]pivot;
reg [2:0]sub_pivot;
reg [9:0]cost;
//mode
always @(posedge CLK or posedge RST) begin
    if(RST) mode <= 2'd0;
    else
        case(mode)
        FIND_TOTAL: mode <= &counter ? COUNT_T : mode;
        COUNT_T: mode <= FIND_NEAR;
        FIND_NEAR: mode <= pattern[pivot] > pattern[pivot + 3'd1] ? FIND_MIN: mode; 
        FIND_MIN: mode <= counter == pivot ? FIND_TOTAL: mode;
        default: mode <= FIND_NEAR;
        endcase
end
//counter
always @(posedge CLK or posedge RST) begin
    if(RST) counter <= 3'd0;
    else
        case(mode)
        FIND_TOTAL: counter <= counter + 3'd1;
        COUNT_T: counter <= 3'd0;
        FIND_NEAR: counter <= 3'd0;
        FIND_MIN: counter <= counter == pivot ? 3'd0: counter + 3'd1;
        default: counter <= 3'd0;
        endcase
end
//cc
always @(posedge CLK or posedge RST) begin
    if(RST) cc <= 6'd0;
    else if(mode == COUNT_T) cc <= cc + 6'd1;
    else cc <= cc;
end
//pivot
always @(posedge CLK or posedge RST) begin
    if(RST) pivot <= 3'd0;
    else if(mode == COUNT_T) pivot <= 3'd0;
    else if(mode == FIND_NEAR) pivot <= pivot + 3'd1;
    else pivot <= pivot;
end
//sub_pivot
always @(posedge CLK or posedge RST) begin
    if(RST) sub_pivot <= 3'd0;
    else if(mode == FIND_MIN) 
        sub_pivot <= pattern[counter] > pattern[pivot] && pattern[counter] < pattern[sub_pivot] ? counter: sub_pivot;
    else sub_pivot <= pivot;//init as pivot so the pivot will never too small to exchange.
end
//pattern
always @(posedge CLK or posedge RST) begin
    if(RST) 
        for (i = 0; i < 8; i = i + 1) begin
            pattern[i] <= 3'd7 - i[3:0];
        end
    else if(mode == FIND_MIN && counter == pivot) 
        for (i = 0; i < 8; i = i + 1) begin
            if(i == pivot)
                pattern[i] <= pattern[sub_pivot];
            else if(i < pivot)
                pattern[i] <= (pivot - i[3:0] - 3'd1) == sub_pivot ? pattern[pivot] : pattern[pivot - i[3:0] - 3'd1];
            else pattern[i] <= pattern[i];
        end
    else 
        for (i = 0; i < 8; i = i + 1) begin
            pattern[i] <= pattern[i];
        end
end
//W
always @(posedge CLK or posedge RST) begin
    if(RST) W <= 3'd0;
    else if(mode == FIND_TOTAL) 
        W <= counter;
    else W <= W;
end
//J
always @(posedge CLK or posedge RST) begin
    if(RST) J <= 3'd0;
    else if(mode == FIND_TOTAL) 
        J <= pattern[counter];
    else J <= J;
end
//cost
always @(posedge CLK or posedge RST) begin
    if(RST) cost <= 10'd0;
    else if(mode == FIND_TOTAL) 
        if(counter == 3'd0) cost <= 10'd0;
        else cost <= cost + Cost;
    else cost <= cost;
end
//MatchCount
always @(posedge CLK or posedge RST) begin
    if(RST) MatchCount <= 3'd0;
    else if(mode == COUNT_T && (Cost + cost) == MinCost)
        MatchCount <= MatchCount + 3'd1; 
    else if(mode == COUNT_T && (Cost + cost) < MinCost)
        MatchCount <= 3'd1; 
    else MatchCount <= MatchCount;
end
//MinCost
always @(posedge CLK or posedge RST) begin
    if(RST) MinCost <= 10'd1023;
    else if(mode == COUNT_T && (Cost + cost) < MinCost)
        MinCost <= (Cost + cost);
    else MinCost <= MinCost;
end
//Valid
always @(posedge CLK or posedge RST) begin
    if(RST) Valid <= 1'd0;
    else if(mode == COUNT_T && {pattern[7], pattern[6], pattern[5], pattern[4], pattern[3], pattern[2], pattern[1], pattern[0]} 
    == {3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0})
        Valid <= 1'd1;
    else Valid <= 1'd0;
end
endmodule
