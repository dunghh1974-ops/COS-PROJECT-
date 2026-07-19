// =====================================================================
// tb_fir_pipelined.v - Testbench chay tren ModelSim
// Dung CHUNG file test_input.hex voi tb_fir_folded de so sanh cong bang.
// Dua mau vao LIEN TUC moi chu ky (dung tinh chat pipeline).
// =====================================================================
`timescale 1ns/1ps

module tb_fir_pipelined;

    localparam N  = 16;
    localparam DW = 16;
    localparam NUM_SAMPLES = 1000;   // phai khop so mau trong test_input.hex

    reg                       clk;
    reg                       rst_n;
    reg                       valid_in;
    reg  signed [DW-1:0]      x_in;
    wire                      valid_out;
    wire signed [2*DW+3:0]    y_out;

    fir_pipelined #(.N(N), .DW(DW)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (valid_out),
        .y_out     (y_out)
    );

    always #5 clk = ~clk;   // clock 100MHz

    reg [DW-1:0] mem_in [0:NUM_SAMPLES-1];
    integer fout;
    integer k;

    // ---- Kiem tra "rac du lieu": valid_out phai xuat hien dung 5 chu ky
    // sau valid_in tuong ung (do sau pipeline co dinh) ----
    integer last_valid_in_cycle = -1;
    integer cycle_cnt = 0;
    always @(posedge clk) begin
        cycle_cnt = cycle_cnt + 1;
        if (valid_in)  last_valid_in_cycle = cycle_cnt;
        if (valid_out && last_valid_in_cycle != -1) begin
            if ((cycle_cnt - last_valid_in_cycle) != 5)
                $display("[CANH BAO] Latency pipeline lech tai chu ky %0d (do lech = %0d, ky vong 5)",
                          cycle_cnt, cycle_cnt - last_valid_in_cycle);
        end
    end

    initial begin
        clk = 0; rst_n = 0; valid_in = 0; x_in = 0;

        $readmemh("test_input.hex", mem_in);
        fout = $fopen("out_pipelined.txt", "w");

        repeat (2) @(posedge clk);
        rst_n = 1;

        // dua tat ca mau vao LIEN TUC, moi chu ky 1 mau (dac trung pipeline)
        for (k = 0; k < NUM_SAMPLES; k = k + 1) begin
            @(negedge clk);
            x_in     = mem_in[k];
            valid_in = 1;
        end
        @(negedge clk);
        valid_in = 0;

        // cho pipeline xa het du lieu con lai (vai chu ky latency)
        repeat (20) @(negedge clk);

        $fclose(fout);
        $display("HOAN TAT mo phong Pipelined.");
        $finish;
    end

    // ---- Ghi ket qua ra file moi khi valid_out = 1 ----
    always @(posedge clk) begin
        if (valid_out)
            $fwrite(fout, "%0d\n", y_out);
    end

    initial begin
        $dumpfile("fir_pipelined.vcd");
        $dumpvars(0, tb_fir_pipelined);
    end

endmodule
