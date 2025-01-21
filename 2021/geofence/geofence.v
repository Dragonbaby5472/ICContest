module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

//------------reg-------------//
reg [19:0] item;
reg [19:0] detector[5:0];
reg [4:0] counter;
reg result;
//-----------wire------------//
wire [19:0] point1;
reg [19:0] point2;
reg [19:0] point3;
reg [19:0] point4;
wire is_positive;
//----------module-----------//
Cross cr(.point1(point1), .point2(point2), .point3(point3), .point4(point4), .is_positive(is_positive));

//counter
always @(posedge clk or posedge reset) begin
    if(reset) counter <= 5'd0;
    else if(valid) counter <= 5'd0;
    else counter <= counter + 5'd1;
end

//point
assign point1 = counter < 5'd14 ? detector[0] : item;
always @(*) begin
    case(counter)
    5'd4: point2 = detector[1];
    5'd5: point2 = detector[2];
    5'd6: point2 = detector[3];
    5'd7: point2 = detector[4];
    5'd8: point2 = detector[1];
    5'd9: point2 = detector[2];
    5'd10: point2 = detector[3];
    5'd11: point2 = detector[1];
    5'd12: point2 = detector[2];
    5'd13: point2 = detector[1];
    5'd14: point2 = detector[0];
    5'd15: point2 = detector[1];
    5'd16: point2 = detector[2];
    5'd17: point2 = detector[3];
    5'd18: point2 = detector[4];
    5'd19: point2 = detector[5];
    default point2 = detector[1];
    endcase
end
always @(*) begin
    case(counter)
    5'd14: point3 = detector[0];
    5'd15: point3 = detector[1];
    5'd16: point3 = detector[2];
    5'd17: point3 = detector[3];
    5'd18: point3 = detector[4];
    5'd19: point3 = detector[5];
    default point3 = detector[0];
    endcase
end
always @(*) begin
    case(counter)
    5'd4: point4 = detector[2];
    5'd5: point4 = detector[3];
    5'd6: point4 = detector[4];
    5'd7: point4 = detector[5];
    5'd8: point4 = detector[2];
    5'd9: point4 = detector[3];
    5'd10: point4 = detector[4];
    5'd11: point4 = detector[2];
    5'd12: point4 = detector[3];
    5'd13: point4 = detector[2];
    5'd14: point4 = detector[1];
    5'd15: point4 = detector[2];
    5'd16: point4 = detector[3];
    5'd17: point4 = detector[4];
    5'd18: point4 = detector[5];
    5'd19: point4 = detector[0];
    default point4 = detector[2];
    endcase
end

//item
always @(posedge clk or posedge reset) begin
    if(reset) item <= 20'd0;
    else if(counter == 5'd0) item <= {Y, X};
end

//detector
integer i;
always @(posedge clk or posedge reset) begin
    if(reset) 
        for(i = 0; i < 6; i = i + 1)
            detector[i] <= 20'd0;
    else begin
        //0
        detector[0] <= counter == 5'd1 ? {Y, X} : detector[0];
        //1
        case (counter)
            5'd2: detector[1] <= {Y, X};
            5'd4: detector[1] <= is_positive ? detector[1]: detector[2];
            5'd8: detector[1] <= is_positive ? detector[1]: detector[2];
            5'd11: detector[1] <= is_positive ? detector[1]: detector[2];
            5'd13: detector[1] <= is_positive ? detector[1]: detector[2];
            default: detector[1] <= detector[1];
        endcase
        //2
        case (counter)
            5'd3: detector[2] <= {Y, X};
            5'd4: detector[2] <= is_positive ? detector[2]: detector[1];
            5'd5: detector[2] <= is_positive ? detector[2]: detector[3];
            5'd8: detector[2] <= is_positive ? detector[2]: detector[1];
            5'd9: detector[2] <= is_positive ? detector[2]: detector[3];
            5'd11: detector[2] <= is_positive ? detector[2]: detector[1];
            5'd12: detector[2] <= is_positive ? detector[2]: detector[3];
            5'd13: detector[2] <= is_positive ? detector[2]: detector[1];
            default: detector[2] <= detector[2];
        endcase
        //3
        case (counter)
            5'd4: detector[3] <= {Y, X};
            5'd5: detector[3] <= is_positive ? detector[3]: detector[2];
            5'd6: detector[3] <= is_positive ? detector[3]: detector[4];
            5'd9: detector[3] <= is_positive ? detector[3]: detector[2];
            5'd10: detector[3] <= is_positive ? detector[3]: detector[4];
            5'd12: detector[3] <= is_positive ? detector[3]: detector[2];
            default: detector[3] <= detector[3];
        endcase
        //4
        case (counter)
            5'd5: detector[4] <= {Y, X};
            5'd6: detector[4] <= is_positive ? detector[4]: detector[3];
            5'd7: detector[4] <= is_positive ? detector[4]: detector[5];
            5'd10: detector[4] <= is_positive ? detector[4]: detector[3];
            default: detector[4] <= detector[4];
        endcase
        //5
        case (counter)
            5'd6: detector[5] <= {Y, X};
            5'd7: detector[5] <= is_positive ? detector[5]: detector[4];
            default: detector[5] <= detector[5];
        endcase
    end
end

//result
always @(posedge clk or posedge reset) begin
    if(reset) result <= 1'd0;
    else if(counter == 5'd14) result <= is_positive;
    else result <= result;
end

//valid
always @(posedge clk or posedge reset) begin
    if(reset) valid <= 1'd0;
    else if(valid) valid <= ~valid;
    else if(counter == 5'd20) valid <= 1'd1;
    else if(counter > 5'd14) valid <= is_positive == result ? 1'd0 : 1'd1;
    else valid <= valid;
end

//is_inside
always @(posedge clk or posedge reset) begin
    if(reset) is_inside <= 1'd0;
    else if(valid) is_inside <= 1'd0;
    else if(counter == 5'd20) is_inside <= 1'd1;
    else is_inside <= is_inside;
end


endmodule

module Cross (
    input [19:0] point1,
    input [19:0] point2,
    input [19:0] point3,
    input [19:0] point4,
    output is_positive
);
//big small or minus?
wire [10:0] vectorA [1:0];
wire [10:0] vectorB [1:0];
assign vectorA[0] = {1'd0, point2[9:0]} - {1'd0, point1[9:0]};
assign vectorA[1] = {1'd0, point2[19:10]} - {1'd0, point1[19:10]};
assign vectorB[0] = {1'd0, point4[9:0]} - {1'd0, point3[9:0]};
assign vectorB[1] = {1'd0, point4[19:10]} - {1'd0, point3[19:10]};
assign is_positive = $signed({{11{vectorA[0][10]}}, vectorA[0]}*{{11{vectorB[1][10]}}, vectorB[1]}) > 
                     $signed({{11{vectorB[0][10]}}, vectorB[0]}*{{11{vectorA[1][10]}}, vectorA[1]})? 1'd1 : 1'd0;
    
endmodule
