module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input            clk;
input            reset;
input      [7:0] chardata;
input            isstring;
input            ispattern;
output reg       match;
output reg [4:0] match_index;
output reg       valid;
//--------parameter---------//
localparam W_HEAD = 8'h5E;//^
localparam W_END = 8'h24;//$
localparam W_ANY = 8'h2E;//.
localparam W_MANY = 8'h2A;//*
localparam W_SPACE = 8'h20;
//----------reg-------------//
reg [4:0] counter;
reg [1:0] mode;
reg [7:0] string_reg [31:0];
reg [7:0] pattern_reg [7:0];
reg [2:0] cp_counter;
reg cp;
reg is_many;
reg [2:0] many_index;
integer i;
//counter
always @(posedge clk or posedge reset) begin
    if(reset) counter <= 5'd0;
    //else if(valid) counter <= 5'd0;
    else if(mode != 2'd0 && isstring) counter <= 5'd1;
    else if(mode != 2'd1 && ispattern) counter <= 5'd1;
    else if(!mode[1] && !isstring && !ispattern) counter <= 5'd0;
    else if(mode[1] && ((pattern_reg[cp_counter] == W_HEAD && counter == 5'd0) || pattern_reg[cp_counter] == W_MANY)) counter <= counter;
    else if(mode[1] && !cp && cp_counter != 3'd0 && pattern_reg[0] == W_ANY && !is_many) counter <= counter;
    else counter <= counter + 5'd1;
end

//mode
always @(posedge clk or posedge reset) begin
    if(reset) mode <= 2'd0;
    else if(isstring && !ispattern) mode <= 2'd0;
    else if(!isstring && ispattern) mode <= 2'd1;
    else if(!isstring && !ispattern) mode <= 2'd2;
    else mode <= mode;
end

//string_reg
always @(posedge clk or posedge reset) begin
    if(reset)
        for(i = 0; i < 32; i = i + 1)begin
            string_reg[i] <= 8'd0;
        end
    else if(isstring) begin
        string_reg[0] <= (counter == 5'd0 || mode != 2'd0) ? chardata : string_reg[0];
        for(i = 1; i < 32; i = i + 1)begin
            if(i == counter) string_reg[i] <= chardata;
            else if(i > counter || mode != 2'd0) string_reg[i] <= 8'd0;
            else string_reg[i] <= string_reg[i];
        end
    end
    else 
        for(i = 0; i < 32; i = i + 1)begin
            string_reg[i] <= string_reg[i];
        end
end

//pattern_reg
always @(posedge clk or posedge reset) begin
    if(reset)
        for(i = 0; i < 8; i = i + 1)begin
            pattern_reg[i] <= 8'd0;
        end
    else if(ispattern) begin
        pattern_reg[0] <= (counter == 5'd0 || mode != 2'd1) ? chardata : pattern_reg[0];
        for(i = 1; i < 32; i = i + 1)begin
            if(i == counter) pattern_reg[i] <= chardata;
            else if(i > counter || mode != 2'd1) pattern_reg[i] <= 8'd0;
            else pattern_reg[i] <= pattern_reg[i];
        end
    end
    else 
        for(i = 0; i < 8; i = i + 1)begin
            pattern_reg[i] <= pattern_reg[i];
        end
end

//cp_counter
always @(posedge clk or posedge reset) begin
    if(reset) cp_counter <= 3'd0;
    else if(valid) cp_counter <= 3'd0;
    else if(is_many && !cp) cp_counter <= many_index;
    else if(cp && mode[1])  cp_counter <= cp_counter + 3'd1;
    else  cp_counter <= 3'd0;
end
//cp
always @(*)begin
    case (pattern_reg[cp_counter])
        W_HEAD: cp = string_reg[counter] == W_SPACE || counter == 5'd0 ? 1'd1 : 1'd0;
        W_END: cp = (string_reg[counter] == W_SPACE || string_reg[counter] == 8'd0) && cp_counter != 3'd0 ? 1'd1 : 1'd0;
        W_ANY: cp = 1'd1;
        W_MANY: cp = 1'd1;
        default: cp = pattern_reg[cp_counter] == string_reg[counter] ? 1'd1 : 1'd0;
    endcase
end
//is_many
always @(posedge clk or posedge reset) begin
    if(reset)is_many <= 1'd0;
    else if(valid) is_many <= 1'd0;
    else if(pattern_reg[cp_counter] == W_MANY) is_many <= 1'd1;
    else  is_many <= is_many;
end
//many_index
always @(posedge clk or posedge reset) begin
    if(reset) many_index <= 3'd0;
    else if(valid) many_index <= 3'd0;
    else if(pattern_reg[cp_counter] == W_MANY) many_index <= cp_counter + 3'd1;
    else  many_index <= many_index;
end
//match_index
always @(posedge clk or posedge reset) begin
    if(reset) match_index <= 5'd31;
    else if(!mode[1]) match_index <= 5'd31;
    else if(cp_counter == 3'd0) match_index <= 5'd31;
    else if(match_index == 5'd31 && pattern_reg[cp_counter - 3'd1] != W_HEAD) match_index <= counter - 5'd1;
    else match_index <= match_index;
end
//match
always @(posedge clk or posedge reset) begin
    if(reset) match <= 1'd0;
    else if(!mode[1]) match <= 1'd0;
    else if(pattern_reg[cp_counter] == 8'd0 || (cp && (string_reg[counter + 5'd1] == 8'd0 || &counter)&& pattern_reg[cp_counter + 3'd1] == W_END)) match <= 1'd1;
    else if(cp_counter == 3'd7 && cp) match <= 1'd1;
    else match <= match;
end
//something wrong
//valid
always @(posedge clk or posedge reset) begin
    if(reset) valid <= 1'd0;
    else if(valid || ispattern || isstring) valid <= 1'd0;
    else if(pattern_reg[cp_counter] == 8'd0 || (string_reg[counter + 5'd1] == 8'd0 && pattern_reg[cp_counter + 3'd1] == W_END)) valid <= 1'd1;
    else if(cp_counter == 3'd7 && cp) valid <= 1'd1;
    else if(mode[1] && (counter == 5'd31 || string_reg[counter] == 8'd0)) valid <= 1'd1;
    else valid <= 1'd0;
end
endmodule
