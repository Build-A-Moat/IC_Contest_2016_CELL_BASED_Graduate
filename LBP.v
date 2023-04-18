
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
    input   	clk;
    input   	reset;
    output  [13:0] 	gray_addr;
    output         	gray_req;
    input   	gray_ready;
    input   [7:0] 	gray_data;
    output  [13:0] 	lbp_addr;
    output  	lbp_valid;
    output  [7:0] 	lbp_data;
    output  	finish;

    reg [13:0] gray_addr, lbp_addr;
    reg gray_req, lbp_valid, finish;
    reg [7:0] lbp_data;

    parameter high = 1'd1;
    parameter low = 1'd0;

    parameter IDLE = 3'd0;
    parameter CENTRAL = 3'd1;
    parameter AROUND = 3'd2;
    parameter WRITE = 3'd3;
    parameter FINISH = 3'd4;

    reg [2:0]cur_state, next_state;
    reg [3:0] counter;
    wire [3:0] counter_m;
    assign counter_m = counter - 1'd1;

    reg [6:0] x, y;
    wire [6:0] x_m, x_p, y_m, y_p;
    assign x_m = x - 7'd1;
    assign x_p = x + 7'd1;
    assign y_m = y - 7'd1;
    assign y_p = y + 7'd1;

    reg [13:0] central_addr;
    wire [13:0] a0_addr, a1_addr, a2_addr, a3_addr, a4_addr, a5_addr, a6_addr, a7_addr;
    //  0 1 2
    //  3 c 4
    //  5 6 7
    assign a0_addr = {y_m, x_m};
    assign a1_addr = {y_m, x};
    assign a2_addr = {y_m, x_p};

    assign a3_addr = {y, x_m};
    assign a4_addr = {y, x_p};

    assign a5_addr = {y_p, x_m};
    assign a6_addr = {y_p, x};
    assign a7_addr = {y_p, x_p};

    reg [7:0] central_data;

    always @(posedge clk or posedge reset) begin
        if (reset) cur_state <= IDLE;
        else cur_state <= next_state;
    end
    
    always @(*) begin
        case (cur_state)
        IDLE : 
        begin
            if (gray_ready == high) next_state <= CENTRAL;
            else next_state <= IDLE;
        end
        CENTRAL : 
        begin
            next_state <= AROUND;
        end
        AROUND : 
        begin
            if (counter == 4'd8) next_state <= WRITE;
            else next_state <= AROUND;
        end
        WRITE : 
        begin
            if (central_addr == 14'd16254) next_state <= FINISH;
            else next_state <= CENTRAL;
        end
        FINISH : 
        begin
            next_state <= FINISH;
        end
        default: next_state <= IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) x <= 7'd1;
        else if (next_state == WRITE && x == 7'd126) x <= 7'd1;
        else if (next_state == WRITE) x <= x + 7'd1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) y <= 7'd1;
        else if (next_state == WRITE && x == 7'd126) y <= y + 7'd1;
    end

    always @(posedge clk or posedge reset) begin
        if(reset) counter <= 4'd0;
        else if(next_state == AROUND) counter <= counter + 4'd1;
        else if(cur_state == WRITE) counter <= 4'd0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) central_addr <= 14'd129;
        else if (next_state == CENTRAL) central_addr <= {y, x};
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) gray_addr <= 14'd0;
        else if (next_state == CENTRAL) gray_addr <= {y, x};
        else if (next_state == AROUND) begin
            case(counter)
            4'd0 : gray_addr <= a0_addr;
            4'd1 : gray_addr <= a1_addr;
            4'd2 : gray_addr <= a2_addr;
            4'd3 : gray_addr <= a3_addr;
            4'd4 : gray_addr <= a4_addr;
            4'd5 : gray_addr <= a5_addr;
            4'd6 : gray_addr <= a6_addr;
            4'd7 : gray_addr <= a7_addr;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) gray_req <= low;
        else if (next_state == CENTRAL || next_state == AROUND) gray_req <= high;
        else gray_req <= low;
    end

    always @(posedge clk or posedge reset or posedge reset) begin
        if (reset) lbp_valid <= low;
        else if (next_state == WRITE) lbp_valid <= high;
        else lbp_valid <= low;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) lbp_addr <= 14'd0;
        else if (next_state == WRITE) lbp_addr <= central_addr;
    end


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lbp_data <= 8'd0;
            central_data <= 8'd0;
        end
        else if (cur_state == CENTRAL) central_data <= gray_data;
        else if (cur_state == AROUND) 
        begin
            if (gray_data >= central_data) lbp_data <= lbp_data + (8'd1 << counter_m);
        end
        else if (cur_state == WRITE) lbp_data <= 8'd0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) finish <= low;
        else if (cur_state == FINISH) finish <= high;
        else  finish <= low;
    end
endmodule