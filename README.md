
This repository provides the core implementation of the DNN-based demodulator proposed in:

# Dual-Domain Deep Learning-Assisted NOMA-CSK Systems for Secure and Efficient Vehicular Communications
 Tingting Huang, Jundong Chen, Huanqiang Zeng, Guofa Cai, and Georges Kaddoum
 
 *IEEE Transactions on Communications*, 2026.

The code demonstrates the key techniques of the proposed DL-NOMA-CSK scheme, including dual-domain feature extraction, chaotic shift keying modulation, and the DNN demodulator architecture under multipath Rayleigh fading channels.

---

## System Overview

Binary symbols are modulated onto two chaotic maps:

| Bit | Map | Equation |
|-----|-----|----------|
| 0 | Logistic | $x_k = 3.7\, x_{k-1}(1 - x_{k-1})$ |
| 1 | Cubic | $x_k = 4x_{k-1}^3 - 3x_{k-1}$ |

The receiver extracts a $2 \times \beta$ dual-domain feature tensor from each received signal:
- **Row 1 (Time domain):** $\text{Re}\{r(t)\}$
- **Row 2 (Frequency domain):** $|\mathcal{F}\{r(t)\}|^2$

## DNN Architecture

```
Input (2 × β)
  → Conv1D(32, k=3) → BN → ReLU
  → Conv1D(32, k=6) → BN → ReLU
  → Multi-Head Self-Attention (8 heads, d_h = 64)
  → Global Average Pooling
  → FC(64) → ReLU → Dropout(0.2)
  → FC(2) → Softmax → {0, 1}
```

---

## Requirements

- MATLAB R2023b or later
- Deep Learning Toolbox
- Signal Processing Toolbox

---

## Repository Structure

```
DL-NOMA-CSK/
├── chaosMap.m              % Chaotic sequence generator
├── generate_dataset.m      % Step 1: Generate training dataset
├── train_dnn.m             % Step 2: Train the DNN
├── test_ber.m              % Step 3: Evaluate BER
├── dataset/
│   └── train_data.mat      % Pre-generated dataset
├── models/
│   └── trained_net.mat     % Pre-trained model weights
└── results/                % BER curves (auto-generated)
```

---

## Quick Start

### ▶ Step 1: Test BER with Pre-trained Model (Recommended Start)

Use this if you want to quickly reproduce the BER results. The repository includes a pre-trained model in `models/`. Simply run:

```matlab
test_ber
```

This will:
1. Load the pre-trained DNN from `models/trained_net.mat`
2. Simulate transmission over Rayleigh fading + AWGN at $E_b/N_0 \in [0, 30]$ dB
3. Plot the BER curve and save results to `results/`

---

### ▶ Step 2: Re-train the DNN Model

Use this if you want to modify the network architecture or hyperparameters. A pre-generated dataset is provided in `dataset/`. Run:

```matlab
train_dnn
```

This will:
1. Load training data from `dataset/train_data.mat`
2. Build and train the DNN demodulator
3. Save the trained model to `models/trained_net.mat` (replaces existing)

You can then run `test_ber` to evaluate the re-trained model.

Key hyperparameters (editable in `train_dnn.m`):

| Parameter | Default | Description |
|-----------|---------|-------------|
| `numFilters` | 32 | Convolutional filters |
| `kSize` | 3 | Kernel size |
| `numHeads` | 8 | Self-attention heads |
| `attDim` | 64 | Attention dimension |
| `maxEpochs` | 20 | Training epochs |
| `miniBatchSize` | 1024 | Mini-batch size |
| `initialLR` | 1e-3 | Initial learning rate |

---

### ▶ Step 3: Regenerate the Dataset

Use this if you want to change channel parameters or the spreading factor. Run:

```matlab
generate_dataset
```

This will:
1. Generate chaotic modulated symbols and pass through multipath Rayleigh fading
2. Add AWGN at random $E_b/N_0 \in [24, 28]$ dB
3. Extract dual-domain features and save to `dataset/train_data.mat` (replaces existing)

You can then run `train_dnn` → `test_ber` for the full pipeline.

Key parameters (editable in `generate_dataset.m`):

| Parameter | Default | Description |
|-----------|---------|-------------|
| `numTrainSymbols` | 500,000 | Total training samples |
| `lenSequence` | 64 | Spreading factor ($\beta$) |
| `snrRangeTrain` | [24, 28] dB | Training $E_b/N_0$ range |

---

## Scope

This repository is a **minimal demo** intended to showcase the core contributions of the proposed scheme:

- Dual-domain feature extraction (time + frequency)
- DNN demodulator architecture (Conv + Self-Attention + GAP)
- Chaotic shift keying modulation (Logistic / Cubic maps)

The demo uses a **2-vehicle uplink scenario** under multipath Rayleigh fading with **perfect CSI** and a **shared pseudo-random number generator (PRNG)** assumed at both training and deployment stages, enabling ideal SIC signal reconstruction consistent with the primary simulation setting in the paper. 

Other simulation configurations presented in the paper — including larger user counts ($N > 2$), different spreading factors, V2I channel models, and imperfect CSI scenarios — can be reproduced by extending this codebase.

The SIC procedure follows Algorithm 1 and the power allocation follows Eq. (5); both use standard PD-NOMA techniques and are not the focus of this repository.

---

## Citation

If you find this code useful, please cite our paper:

```bibtex
@article{huang2026dlnomacsk,
  title   = {Dual-Domain Deep Learning-Assisted NOMA-CSK Systems for Secure and Efficient Vehicular Communications},
  author  = {Huang, Tingting and Chen, Jundong and Zeng, Huanqiang and Cai, Guofa and Kaddoum, Georges},
  journal = {IEEE Transactions on Communications},
  year    = {2026},
  doi     = {}
}
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Contact

For questions or issues, please open a [GitHub Issue](../../issues) or contact: JDchan0815@163.com
