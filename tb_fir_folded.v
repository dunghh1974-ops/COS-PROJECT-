// =====================================================================
// tb_fir_folded.v - Testbench chay tren ModelSim
// Nap test_input.hex, dua tung mau vao DUT, cho valid_out, ghi ra file
// =====================================================================
`timescale 1ns/1ps

module tb_fir_folded;

    localparam N  = 16;
    localparam DW = 16;
    localparam ACC_W = 2*DW + 5;
    localparam NUM_SAMPLES = 1000;   // phai khop so mau trong test_input.hex

    reg                     clk;
    reg                     rst_n;
    reg                     valid_in;
    reg  signed [DW-1:0]    x_in;
    wire                    valid_out;
    wire signed [ACC_W-1:0] y_out;

    // ---- Instance DUT ----
    fir_folded #(.N(N), .DW(DW), .ACC_W(ACC_W)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (valid_out),
        .y_out     (y_out)
    );

    // ---- Sinh clock 100MHz (chu ky 10ns) ----
    always #5 clk = ~clk;

    // ---- Nap du lieu test tu file hex ----
    reg [DW-1:0] mem_in [0:NUM_SAMPLES-1];
    integer fout;
    integer k;

    initial begin
        clk   = 0;
        rst_n = 0;
        valid_in = 0;
        x_in  = 0;

        $readmemh("test_input.hex", mem_in);
        fout = $fopen("out_folded.txt", "w");

        // reset 2 chu ky
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        for (k = 0; k < NUM_SAMPLES; k = k + 1) begin
            // dua mau vao trong 1 chu ky
            @(negedge clk);
            x_in     = mem_in[k];
            valid_in = 1;
            @(negedge clk);
            valid_in = 0;

            // cho FSM xu ly xong N chu ky roi moi lay ket qua
            wait (valid_out === 1'b1);
            $fwrite(fout, "%0d\n", y_out);
            @(negedge clk); // tranh doc trung lap valid_out cua cung 1 mau
        end

        $fclose(fout);
        $display("HOAN TAT mo phong Folded - %0d mau da xu ly.", NUM_SAMPLES);
        $finish;
    end

    // ---- (tuy chon) dump waveform de xem tren ModelSim ----
    initial begin
        $dumpfile("fir_folded.vcd");
        $dumpvars(0, tb_fir_folded);
    end

endmodule
