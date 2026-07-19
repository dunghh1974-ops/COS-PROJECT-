// =====================================================================
// fir_pipelined.v
// Kien truc PIPELINED - toi uu thong luong: 8 bo nhan song song + Pre-adder
// (tan dung tinh doi xung h[k]=h[N-1-k]) + cay cong don (Adder Tree).
// Throughput = 1 mau / 1 chu ky clock. Latency co dinh = 5 chu ky.
// =====================================================================
module fir_pipelined #(
    parameter N  = 16,      // so tap bo loc (PHAI la so chan)
    parameter DW = 16       // do rong bit du lieu vao / he so
)(
    input                             clk,
    input                             rst_n,
    input                             valid_in,
    input  signed [DW-1:0]            x_in,
    output                            valid_out,
    output signed [2*DW+3:0]          y_out     // = 36 bit khi DW=16
);

    localparam H = N/2;   // = 8 : so he so doc lap do tinh doi xung

    // ---- Stage 0: thanh ghi dich N mau ngo vao ----
    reg signed [DW-1:0] x_shift [0:N-1];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) x_shift[i] <= 0;
        end else if (valid_in) begin
            x_shift[0] <= x_in;
            for (i = 1; i < N; i = i + 1) x_shift[i] <= x_shift[i-1];
        end
    end

    // ---- ROM he so: chi can H=8 gia tri do tinh doi xung h[k]=h[N-1-k] ----
    reg signed [DW-1:0] h_mem [0:H-1];
    initial $readmemh("fir_coeff_half.mem", h_mem);

    // ---- Stage 1: Pre-adder & Multiplier (Gop lai de dat 5 tang latency) ----
    reg signed [2*DW:0] mult_r [0:H-1];         // 2*DW+1 bit
    always @(posedge clk) begin
        for (i = 0; i < H; i = i + 1)
            mult_r[i] <= (x_shift[i] + x_shift[N-1-i]) * h_mem[i];
    end

    // ---- Stage 2: tang cong dau tien cua Adder Tree (8 -> 4) ----
    reg signed [2*DW+1:0] sum4 [0:3];           // 2*DW+2 bit
    always @(posedge clk) begin
        for (i = 0; i < 4; i = i + 1)
            sum4[i] <= mult_r[2*i] + mult_r[2*i+1];
    end

    // ---- Stage 3: tang cong thu hai (4 -> 2) ----
    reg signed [2*DW+2:0] sum2 [0:1];           // 2*DW+3 bit
    always @(posedge clk) begin
        sum2[0] <= sum4[0] + sum4[1];
        sum2[1] <= sum4[2] + sum4[3];
    end

    // ---- Stage 4: tang cong cuoi cung (2 -> 1) + thanh ghi ngo ra ----
    reg signed [2*DW+3:0] y_r;                  // 2*DW+4 bit
    always @(posedge clk) begin
        y_r <= sum2[0] + sum2[1];
    end
    assign y_out = y_r;

    // ---- Thanh ghi dich tin hieu valid, khop dung do sau pipeline (5 tang) ----
    reg [4:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_pipe <= 5'b0;
        else        valid_pipe <= {valid_pipe[3:0], valid_in};
    end
    assign valid_out = valid_pipe[4];

endmodule
