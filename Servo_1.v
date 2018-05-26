`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: modified from stated examples by Rod
// 
// Create Date: 12.03.2018 16:50:58
// Design Name: 
// Module Name: Servo_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: code below based on http://www.fpga4fun.com/RCServos.html
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// TEST of Git Repo
// 2nd Test of Github and Git

//Clock is 100MHz
// code below based on http://www.fpga4fun.com/RCServos.html
module RCServo(
    input clk,
    //RxD,
    input Fast_CCW,
    input Slow_CCW,
    input Slow_CW,
    input Fast_CW,
    output RCServo_pulse,
    output reg LED,
    output reg LED1,
    output reg LED2,
    output reg LED3
    );
    
    reg [7:0] RxD_data_reg = 8'h80;

    ////////////////////////////////////////////////////////////////////////////
    //Instatiate a debouncer for Fast_CCW input
    wire F_CCW_clean;
    wire F_CCW_state;
    wire F_CCW_up;
    
    wire S_CCW_clean;
    wire S_CCW_state;
    wire S_CCW_up;
    
    wire S_CW_clean;
    wire S_CW_state;
    wire S_CW_up;
    
    wire F_CW_clean;
    wire F_CW_state;
    wire F_CW_up;
  
    //Instatiate a debouncer for Fast_CCW input
    PushButton_Debouncer db_Fast_CCW(
        .clk    (clk),
        .PB     (Fast_CCW),
        .PB_state   (F_CCW_state),
        .PB_down    (F_CCW_clean),
        .PB_up      (F_CCW_up)
    );
    //Instatiate a debouncer for Slow_CCW input
    PushButton_Debouncer db_Slow_CCW(
            .clk    (clk),
            .PB     (Slow_CCW),
            .PB_state   (S_CCW_state),
            .PB_down    (S_CCW_clean),
            .PB_up      (S_CCW_up)
        );
    //Instatiate a debouncer for Slow_CW input
    PushButton_Debouncer db_Slow_CW(
                .clk    (clk),
                .PB     (Slow_CW),
                .PB_state   (S_CW_state),
                .PB_down    (S_CW_clean),
                .PB_up      (S_CW_up)
            );
    //Instatiate a debouncer for Fast_CW input
    PushButton_Debouncer db_Fast_CW(
                .clk    (clk),
                .PB     (Fast_CW),
                .PB_state   (F_CW_state),
                .PB_down    (F_CW_clean),
                .PB_up      (F_CW_up)
            );    
 
    always @(posedge clk) begin
    
        if (F_CCW_clean == 1) begin
          if (RxD_data_reg < 8'hDF)
            RxD_data_reg <= RxD_data_reg +8'h20;
          else
            RxD_data_reg = 8'hFF;         
        end
        
        if (S_CCW_clean == 1) begin
          if (RxD_data_reg <8'hFF)
            RxD_data_reg <= RxD_data_reg +8'h01;
          else
            RxD_data_reg = 8'hFF;       
        end
        
        if (S_CW_clean == 1) begin
          if (RxD_data_reg >8'h01)
            RxD_data_reg <= RxD_data_reg -8'h01;
          else
            RxD_data_reg = 8'h00;         
        end        
        
        if (F_CW_clean == 1)begin
          if (RxD_data_reg >8'h20)
            RxD_data_reg <= RxD_data_reg -8'h20;
          else 
            RxD_data_reg = 8'h00;
        end        
    end
       
    always @(posedge clk) LED <= F_CCW_state;
    always @(posedge clk) LED1 <= S_CCW_state;
    always @(posedge clk) LED2 <= S_CW_state;
    always @(posedge clk) LED3 <= F_CW_state;  
      
    ////////////////////////////////////////////////////////////////////////////
    // divide the clock
    parameter ClkDiv = 392;
    
    reg [9:0] ClkCount;
    reg ClkTick;
    always @(posedge clk) ClkTick <= (ClkCount==ClkDiv-2);
    always @(posedge clk) if(ClkTick) ClkCount <= 0; else ClkCount <= ClkCount + 1;
    
    ////////////////////////////////////////////////////////////////////////////
    reg [11:0] PulseCount;
    always @(posedge clk) if(ClkTick) PulseCount <= PulseCount + 1;
    
    // make sure the RCServo_position is stable while the pulse is generated
    reg [7:0] RCServo_position;
    always @(posedge clk) if(PulseCount==0) RCServo_position <= RxD_data_reg;
    
    reg RCServo_pulse;
    always @(posedge clk) RCServo_pulse <= (PulseCount < {4'b0001, RCServo_position});

endmodule

//code below from http://www.fpga4fun.com/Debouncer2.html
module PushButton_Debouncer(
    input clk,
    input PB,  // "PB" is the glitchy, asynchronous to clk, active low push-button signal

    // from which we make three outputs, all synchronous to the clock
    output reg PB_state,  // 1 as long as the push-button is active (down)
    output PB_down,  // 1 for one clock cycle when the push-button goes down (i.e. just pushed)
    output PB_up   // 1 for one clock cycle when the push-button goes up (i.e. just released)
    );

    // First use two flip-flops to synchronize the PB signal the "clk" clock domain
    reg PB_sync_0;  always @(posedge clk) PB_sync_0 <= ~PB;  // invert PB to make PB_sync_0 active high
    reg PB_sync_1;  always @(posedge clk) PB_sync_1 <= PB_sync_0;
    
    // Next declare a 16-bits counter
    reg [15:0] PB_cnt;

    // When the push-button is pushed or released, we increment the counter
    // The counter has to be maxed out before we decide that the push-button state has changed
    
    wire PB_idle = (PB_state==PB_sync_1);
    wire PB_cnt_max = &PB_cnt;	// true when all bits of PB_cnt are 1's
    
    always @(posedge clk)
    if(PB_idle)
        PB_cnt <= 0;  // nothing's going on
    else
    begin
        PB_cnt <= PB_cnt + 16'd1;  // something's going on, increment the counter
        if(PB_cnt_max) PB_state <= ~PB_state;  // if the counter is maxed out, PB changed!
    end
    
    assign PB_down = ~PB_idle & PB_cnt_max & ~PB_state;
    assign PB_up   = ~PB_idle & PB_cnt_max &  PB_state;
endmodule


