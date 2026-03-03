This repository provides the core implementation of the DNN-based demodulator proposed in:
Dual-Domain Deep Learning-Assisted NOMA-CSK Systems for Secure and Efficient Vehicular Communications
Tingting Huang, Member, IEEE, Jundong Chen, Huanqiang Zeng, Senior Member, IEEE,Guofa Cai, Senior Member, IEEE and Georges Kaddoum, Senior Member, IEEE
IEEE Transactions on Communications, 2026.
The code demonstrates the key techniques of the proposed DL-NOMA-CSK scheme, including dual-domain feature extraction, chaotic shift keying modulation, and the DNN demodulator architecture under multipath Rayleigh fading channels.
System Overview
Requirements
MATLAB R2023b or later
Deep Learning Toolbox
Signal Processing Toolbox
Binary symbols are modulated onto two chaotic maps:
Transmitted Bit	Chaotic Map	Equation
0	Logistic	xk=3.7⋅xk−1(1−xk−1)
1	Cubic	xk=4xk−13−3xk−1
The receiver extracts a 2×β dual-domain feature tensor from each received signal:
Time domain:Re{r(t)}
Frequency domain: |ℱ{r(t)}|2
DNN Architecture
Input (2 × β)
  → Conv1D(32, k=3) → BN → ReLU
  → Conv1D(32, k=6) → BN → ReLU
  → Multi-Head Self-Attention (8 heads, d_h=64)
  → Global Average Pooling
  → FC(64) → ReLU → Dropout(0.2)
  → FC(2) → Softmax → Classification {0, 1}


Repository Structure
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
Quick Start

▶ Step 1: Test BER with Pre-trained Model (Recommended Start)
Use this if you want to quickly reproduce the BER results.
The repository includes a pre-trained model in models/. 
Simply run: test_ber
This will:
1.Load the pre-trained DNN from : models/trained_net.mat
2.Simulate transmission over Rayleigh fading + AWGN at Eb/N0∈[0,30] dB
3.Plot the BER curve and save results to: results/


▶ Step 2: Re-train the DNN Model
Use this if you want to modify the network architecture or hyperparameters.
A pre-generated dataset is provided in dataset/. 
Run: train_dnn
This will:
1.Load training data from: dataset/train_data.mat
2.Build and train the DNN demodulator
3.Save the trained model to:  models/trained_net.mat (replaces existing)
You can then run test_ber to evaluate the re-trained model.
Key hyperparameters (editable in train_dnn.m):
Parameter	Default	Description
numFilters	32	Convolutional filters
kSize	3	Kernel size
numHeads	8	Self-attention heads
attDim	64	Attention dimension
maxEpochs	20	Training epochs
miniBatchSize	1024	Mini-batch size
initialLR	1e-3	Initial learning rate

▶ Step 3: Regenerate the Dataset
Use this if you want to change channel parameters or the spreading factor.
generate_dataset
This will:
Extract dual-domain features and save to dataset/train_data.mat (replaces existing)
You can then run train_dnn → test_ber for a full pipeline.
Key parameters (editable in generate_dataset.m):
Parameter	Default	Description
numTrainSymbols	500,000	Total training samples
lenSequence	64	Spreading factor ($\beta$)
snrRangeTrain	[24, 28] dB	Training $E_b/N_0$ range


Scope of This Repository
This repository is a minimal demo intended to showcase the core contributions of the proposed scheme:
Dual-domain feature extraction (time + frequency)
DNN demodulator architecture (Conv + Self-Attention + GAP)
Chaotic shift keying modulation (Logistic / Cubic maps)
The demo uses a 2-vehicle uplink scenario under multipath Rayleigh fading with perfect CSI and a shared pseudo-random number generator (PRNG) assumed at both training and deployment stages, enabling ideal SIC signal reconstruction consistent with the primary simulation setting in the paper. 
Other simulation configurations presented in the paper — including larger user counts (N > 2), different spreading factors, V2I channel models, and imperfect CSI scenarios — can be reproduced by extending this codebase .
The SIC procedure follows Algorithm 1 and the power allocation follows Eq. (5); both use standard PD-NOMA techniques and are not the focus of this repository.
Citation
If you find this code useful, please cite our paper:
@article{huang2026dlnomacsk,
  title   = {Dual-Domain Deep Learning-Assisted NOMA-CSK Systems for Secure and Efficient Vehicular Communications},
  author  = {Huang, Tingting and Chen, Jundong and Zeng, Huanqiang and Cai, Guofa and Kaddoum, Georges},
  journal = {IEEE Transactions on Communications},
  year    = {2026},
  doi     = {}
}
License
This project is licensed under the MIT License. See LICENSE for details.

Contact
For questions or issues, please open a GitHub Issue or contact: [JDchan0815@163.com]
