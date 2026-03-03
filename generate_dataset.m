%% DL-NOMA-CSK System - Two-Vehicle Dataset Generation
%
% File: generate_dataset.m
%
% Description:
%   Generates training and validation datasets for the DL-NOMA-CSK
%   demodulator with two vehicles. For each symbol, TWO samples:
%     - Stage 1: Composite signal features → label = V1 bit
%     - Stage 2: Perfect SIC residual      → label = V2 bit
%
%   Perfect SIC: subtract the TRUE faded V1 signal from composite.
%
% Feature tensor: 2 x beta
%   Row 1: Re{r(t)}         time-domain features
%   Row 2: |FFT(r(t))|^2    spectral-domain features
%
% Output:
%   dataset/train_data_2user.mat  (train dataset)
%
% Dependencies:
%   - MATLAB R2019b or later
%   - Signal Processing Toolbox
%   - chaosMap.m
%
% Last Updated: 2025


%% Initialization
clc; clear; close all;


fprintf('Start time: %s\n\n', datestr(now));

%% System Parameters
numSymbols      = 500000;
lenSequence     = 64;
valRatio        = 0.2;
snrRangeTrain   = [24, 28];
numUsers        = 2;
alpha = [3/4, 1/4]; 

% Channel configuration
sampleRate        = 10e6;
rayleighPathDelay = [0, 2] / sampleRate;
rayleighPathPower = [1/2, 1/2];

rayleighPathDelay_V2 = [0, 2, 4] / sampleRate;
rayleighPathPower_V2 = [4/7, 2/7, 1/7];

rayChan1 = comm.RayleighChannel( ...
    'SampleRate',       sampleRate, ...
    'PathDelays',       rayleighPathDelay, ...
    'AveragePathGains', 10*log10(rayleighPathPower), ...
    'PathGainsOutputPort', true ...
);

rayChan2 = comm.RayleighChannel( ...
    'SampleRate',       sampleRate, ...
    'PathDelays',       rayleighPathDelay_V2, ...
    'AveragePathGains', 10*log10(rayleighPathPower_V2), ...
    'PathGainsOutputPort', true ...
);

numTotalSamples = 2 * numSymbols;

fprintf('System Configuration:\n');

fprintf('  Symbols           = %d\n', numSymbols);
fprintf('  Total samples     = %d  (Stage1 + Stage2)\n', numTotalSamples);
fprintf('  Spreading (beta)  = %d\n', lenSequence);
fprintf('  Train Eb/N0       = [%d, %d] dB\n', snrRangeTrain(1), snrRangeTrain(2));


%% Output Directory
outputDir = 'dataset';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% Data Generation

trainData  = cell(numTotalSamples, 1);
trainLabel = zeros(numTotalSamples, 1);

progressInterval = max(1, floor(numSymbols / 20));
tic;

for i = 1:numSymbols
    
    if mod(i, progressInterval) == 0
        elapsed = toc;
        eta = elapsed / i * (numSymbols - i);
        fprintf('  [%6d / %6d] %5.1f%%  |  Elapsed: %.0fs  |  ETA: %.0fs\n', ...
            i, numSymbols, i/numSymbols*100, elapsed, eta);
    end
    
    % Random bits
    bit_V1 = randi([0, 1]);
    bit_V2 = randi([0, 1]);
    
    % Generate chaotic sequences
    if bit_V1 == 0
        seq_V1 = chaosMap('logistic', lenSequence, 3.7);
    else
        seq_V1 = chaosMap('cubic', lenSequence, 4);
    end
    
    if bit_V2 == 0
        seq_V2 = chaosMap('logistic', lenSequence, 3.7);
    else
        seq_V2 = chaosMap('cubic', lenSequence, 4);
    end
    
    % Rayleigh fading channels
    [fadedSig_V1, ~] = rayChan1(seq_V1.');
    fadedSig_V1 = fadedSig_V1.';
    
    [fadedSig_V2, ~] = rayChan2(seq_V2.');
    fadedSig_V2 = fadedSig_V2.';
    
    % Superimpose
    compositeSig = sqrt(alpha(1)) * fadedSig_V1 + sqrt(alpha(2)) * fadedSig_V2;
    
    % AWGN
    snr   = snrRangeTrain(1) + (snrRangeTrain(2) - snrRangeTrain(1)) * rand();
    Eb    = sum(abs(compositeSig).^2) / 2 ;
    ebno  = 10^(snr / 10);
    sigma = sqrt(Eb / (ebno * 2));
    noisySig = compositeSig + sigma * (randn(size(compositeSig)) + 1j * randn(size(compositeSig))) / sqrt(2);
    
    % ============ Stage 1: Composite → V1 ============
    idx1 = 2 * i - 1;
    x1 = zeros(2, lenSequence);
    x1(1, :) = real(noisySig);
    x1(2, :) = abs(fft(noisySig)).^2;
    
    trainData{idx1}  = x1;
    trainLabel(idx1) = bit_V1;
    
    % ============ Stage 2: Perfect SIC → V2 ============

    residualSig = noisySig - sqrt(alpha(1)) * fadedSig_V1;
    
    idx2 = 2 * i;
    x2 = zeros(2, lenSequence);
    x2(1, :) = real(residualSig);
    x2(2, :) = abs(fft(residualSig)).^2;
    
    trainData{idx2}  = x2;
    trainLabel(idx2) = bit_V2;

end

elapsed = toc;
fprintf('\nGeneration complete in %.1f seconds.\n', elapsed);
fprintf('Total samples: %d\n\n', numTotalSamples);

%% Split into Training and Validation Sets

numSamples = numTotalSamples;
indices    = randperm(numSamples);
numVal     = floor(valRatio * numSamples);

valIdx   = indices(1:numVal);
trainIdx = indices(numVal+1:end);

valData     = trainData(valIdx);
valLabels   = categorical(trainLabel(valIdx));
trainData   = trainData(trainIdx);
trainLabels = categorical(trainLabel(trainIdx));

%% Save

params = struct();
params.numSymbols         = numSymbols;
params.numTotalSamples    = numTotalSamples;
params.lenSequence        = lenSequence;
params.snrRangeTrain      = snrRangeTrain;
params.valRatio           = valRatio;
params.numUsers           = numUsers;
params.alpha              = alpha;
params.sampleRate         = sampleRate;
params.rayleighPathDelay  = rayleighPathDelay;
params.rayleighPathPower  = rayleighPathPower;

savePath = fullfile(outputDir, 'train_data_2user.mat');
save(savePath, ...
    'trainData', 'trainLabels', 'valData', 'valLabels', ...
    'rayChan1', 'rayChan2', ...
    'params', '-v7.3');

fprintf('Dataset saved to %s\n', savePath);
fprintf('  Training samples:   %d\n', length(trainIdx));
fprintf('  Validation samples: %d\n', numVal);

fprintf('\n========================================\n');
fprintf('  Dataset Generation Done.\n');
fprintf('========================================\n');