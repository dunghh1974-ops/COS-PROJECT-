%% =====================================================================
%% gen_coeff_and_testdata.m
%% Sinh he so bo loc FIR (Linear Phase) + du lieu test (sin + nhieu)
%% Xuat ra file .mem/.hex de ModelSim doc bang $readmemh
%% Yeu cau: MATLAB co Signal Processing Toolbox (ham fir1)
%% =====================================================================
clear; clc;

%% ---------------- Tham so bo loc ----------------
N  = 16;           % so tap (bac bo loc) - PHAI khop parameter N trong Verilog
DW = 16;            % do rong bit fixed-point (Q1.15)
fs = 48000;         % tan so lay mau (Hz)
fc = 6000;          % tan so cat (Hz)

%% ---------------- Sinh he so FIR doi xung pha tuyen tinh ----------------
h = fir1(N-1, fc/(fs/2));      % fir1(order, Wn), order = N-1 -> tra ve N tap

% Kiem tra tinh doi xung (bat buoc de kien truc Pipelined dung duoc Pre-adder)
if max(abs(h - fliplr(h))) > 1e-9
    error('He so KHONG doi xung - kiem tra lai bac loc N');
end

%% ---------------- Chuyen sang fixed-point Q1.15 (16-bit co dau) ----------------
scale = 2^(DW-1);
h_int = round(h * scale);

if any(h_int < -scale) || any(h_int > scale-1)
    error('He so vuot pham vi fixed-point, giam gain hoac tang DW');
end

fprintf('He so FIR (fixed-point Q1.15):\n');
disp(h_int);

%% ---------------- Xuat file he so day du (N dong) - dung cho Nhom 1 (Folded) ----------------
write_hex_file('fir_coeff_full.mem', h_int, DW);

%% ---------------- Xuat file nua dau (N/2 dong, do tinh doi xung) - dung cho Nhom 2 (Pipelined) ----------------
h_half = h_int(1:N/2);
write_hex_file('fir_coeff_half.mem', h_half, DW);

fprintf('Da xuat fir_coeff_full.mem (%d dong) va fir_coeff_half.mem (%d dong)\n', N, N/2);

%% ---------------- Sinh tin hieu test: sin 1kHz + nhieu tan so cao 15kHz ----------------
n_samples = 1000;
t = (0:n_samples-1) / fs;
x = 0.5*sin(2*pi*1000*t) + 0.15*sin(2*pi*15000*t);

x_int = round(x * scale);
if any(x_int < -scale) || any(x_int > scale-1)
    error('Tin hieu test vuot pham vi fixed-point');
end

write_hex_file('test_input.hex', x_int, DW);
fprintf('Da xuat test_input.hex (%d mau)\n', n_samples);
fprintf('Vi du 5 mau dau:\n');
disp(x_int(1:5));

fprintf('\nHOAN TAT. Copy 3 file .mem/.hex vua tao vao thu muc project ModelSim.\n');


%% =====================================================================
%% Ham con: ghi mang so nguyen ra file hex bu 2 (dinh dang $readmemh doc duoc)
%% =====================================================================
function write_hex_file(filename, int_vals, width)
    fid = fopen(filename, 'w');
    if fid == -1
        error('Khong the tao file %s', filename);
    end
    maxval = 2^width;
    for k = 1:length(int_vals)
        v = mod(int_vals(k), maxval);   % chuyen so am sang dang bu 2 khong dau
        fprintf(fid, '%04X\n', v);
    end
    fclose(fid);
end
