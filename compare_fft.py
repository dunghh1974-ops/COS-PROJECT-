# =====================================================================
# BUOC 3 - CHAY TREN GOOGLE COLAB (SAU KHI DA CO KET QUA TU MODELSIM)
# Upload 2 file "out_folded.txt" va "out_pipelined.txt" (moi dong 1 so
# nguyen y_out duoc Testbench ghi ra) roi chay script nay de ve pho FFT
# =====================================================================
import numpy as np
import matplotlib.pyplot as plt

# Neu chay tren Colab, dung dong duoi de upload file truoc:
try:
    from google.colab import files
    print("Hay chon 2 file: out_folded.txt va out_pipelined.txt")
    uploaded = files.upload()
except ImportError:
    pass  # chay local thi bo qua, dam bao 2 file da co san trong thu muc

y_folded    = np.loadtxt("out_folded.txt")
y_pipelined = np.loadtxt("out_pipelined.txt")

# Chuan hoa ve cung do dai (kien truc Pipelined co the co vai mau tre do latency)
n = min(len(y_folded), len(y_pipelined))
y_folded    = y_folded[:n]
y_pipelined = y_pipelined[:n]

Y1 = np.abs(np.fft.fft(y_folded))
Y2 = np.abs(np.fft.fft(y_pipelined))

Y1_db = 20 * np.log10(Y1 / (np.max(Y1) + 1e-12) + 1e-12)
Y2_db = 20 * np.log10(Y2 / (np.max(Y2) + 1e-12) + 1e-12)

plt.figure(figsize=(9, 5))
plt.plot(Y1_db, label="Folded", linewidth=1.5)
plt.plot(Y2_db, "--", label="Pipelined", linewidth=1.5)
plt.xlabel("Frequency bin")
plt.ylabel("Magnitude (dB)")
plt.title("So sanh dap ung pho: Folded vs Pipelined")
plt.legend()
plt.grid(True, alpha=0.3)
plt.savefig("fft_compare.png", dpi=150)
plt.show()

# Sai so trung binh giua 2 dap ung (cang gan 0 cang chung to 2 kien truc
# cho ra cung dap ung loc, chi khac ve mat phan cung)
mae = np.mean(np.abs(Y1_db - Y2_db))
print(f"Sai so trung binh giua 2 dap ung pho: {mae:.4f} dB")
if mae < 1.0:
    print(">> Ket luan: 2 kien truc cho ra dap ung loc GAN NHU GIONG NHAU (dat yeu cau).")
else:
    print(">> Canh bao: sai lech dang ke - kiem tra lai do rong bit / do tre pipeline / offset mau.")
