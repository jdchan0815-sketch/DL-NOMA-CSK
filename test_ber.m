%% DL-NOMA-CSK System - Two-Vehicle BER Testing
%
% File: test_ber.m
%
% Description:
%   Loads the pre-trained DNN demodulator objects from the 
%   dataset generation phase. Evaluates BER for both vehicles
%   using SIC detection with a single DNN across Eb/N0 values.
%
% SIC Detection (single DNN applied at each stage):
%   Stage 1: DNN decodes V1 from composite signal
%   Stage 2: Cancel V1 (perfect SIC), DNN decodes V2 from residual
%
% Input:
%   models/trained_net_2user.mat    (pre-trained DNN model)
%   dataset/train_data_2user.mat    (parameters)
%
% Output:
%   BER curves for V1, V2, and overall + results saved to results
%
% Dependencies:
%   - MATLAB R2019b or later
%   - Deep Learning Toolbox
%   - Signal Processing Toolbox
%   - chaosMap.m
%
% Last Updated: 2025


%% ====================== Load Pre-trained Model ======================
clc; clear; close all;

modelPath = fullfile('models', 'trained_net_2user.mat');
if ~exist(modelPath, 'file')
    error('Model not found: %s\nRun train_dnn.m first.', modelPath);
end

fprintf('Loading model: %s ...\n', modelPath);
loadedModel = load(modelPath, 'net', 'params', 'trainInfo');
net    = loadedModel.net;
params = loadedModel.params;
fprintf('  Validation accuracy was %.2f%%\n\n', loadedModel.trainInfo.valAccuracy);


dataPath = fullfile('dataset', 'train_data_2user.mat');
if ~exist(dataPath, 'file')
    error('Dataset not found: %s\nRun generate_dataset.m first.', dataPath);
end

loadedData = load(dataPath, 'rayChan1', 'rayChan2');
rayChan1 = loadedData.rayChan1;
rayChan2 = loadedData.rayChan2;


%% ====================== System Parameters ======================

lenSequence = params.lenSequence;
alpha       = params.alpha;         
numUsers    = params.numUsers;     

% Test-specific parameters
numTestSymbols = 500000;            % Symbols per SNR point
snrRangeTest   = 0:2:30;           % Test Eb/N0 range (dB)

fprintf('Test Configuration:\n');
fprintf('  Vehicles          = %d\n', numUsers);
fprintf('  Spreading (beta)  = %d\n', lenSequence);
fprintf('  Test symbols      = %d per SNR point\n', numTestSymbols);
fprintf('  SNR range         = [%d : %d : %d] dB\n\n', ...
    snrRangeTest(1), snrRangeTest(2)-snrRangeTest(1), snrRangeTest(end));

%% ====================== BER Simulation ======================

ber_V1    = zeros(1, length(snrRangeTest));
ber_V2    = zeros(1, length(snrRangeTest));
ber_total = zeros(1, length(snrRangeTest));

for iSNR = 1:length(snrRangeTest)
    
    snr_dB = snrRangeTest(iSNR);
    fprintf('Testing Eb/N0 = %2d dB ...', snr_dB);
    
    % Pre-allocate
    testData_V1  = cell(numTestSymbols, 1);     
    testLabel_V1 = zeros(numTestSymbols, 1);
    testLabel_V2 = zeros(numTestSymbols, 1);
    fadedSigs_V1 = zeros(numTestSymbols, lenSequence);
    noisySigs    = zeros(numTestSymbols, lenSequence);
    
    % ============ Generate test signals ============
    for i = 1:numTestSymbols
        
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
        
        % Pass through the Rayleigh channels
        [fadedSig_V1, ~] = rayChan1(seq_V1.');
        fadedSig_V1 = fadedSig_V1.';
        
        [fadedSig_V2, ~] = rayChan2(seq_V2.');
        fadedSig_V2 = fadedSig_V2.';
        
        % Superimpose with power allocation
        compositeSig = sqrt(alpha(1)) * fadedSig_V1 + sqrt(alpha(2)) * fadedSig_V2;
        
        % Add AWGN
        Eb    = sum(abs(compositeSig).^2) / 2;
        ebno  = 10^(snr_dB / 10);
        sigma = sqrt(Eb / (ebno * 2));
        noisySig = compositeSig + sigma * (randn(size(compositeSig)) + 1j * randn(size(compositeSig))) / sqrt(2);
        
        % Stage 1 features 
        x1 = zeros(2, lenSequence);
        x1(1, :) = real(noisySig);
        x1(2, :) = abs(fft(noisySig)).^2;
        
        testData_V1{i}  = x1;
        testLabel_V1(i) = bit_V1;
        testLabel_V2(i) = bit_V2;
        
        % Store for SIC cancellation
        fadedSigs_V1(i, :) = fadedSig_V1;
        noisySigs(i, :)    = noisySig;
    end
    
    % ============ SIC Stage 1: Decode V1 ============
    predictedLabels_V1 = classify(net, testData_V1);
    
    % ============ SIC Stage 2: Cancel V1, then decode V2 ============

    testData_V2 = cell(numTestSymbols, 1);

    for i = 1:numTestSymbols
        
        % SIC cancellation
        residualSig = noisySigs(i, :) - sqrt(alpha(1)) * fadedSigs_V1(i, :);

        x2 = zeros(2, lenSequence);
        x2(1, :) = real(residualSig);
        x2(2, :) = abs(fft(residualSig)).^2;
        testData_V2{i} = x2;
    end
  
    % Use the SAME DNN to decode V2 from residual
    predictedLabels_V2 = classify(net, testData_V2);
    
    % ============ Compute BER ============
    testLabelCat_V1 = categorical(testLabel_V1);
    testLabelCat_V2 = categorical(testLabel_V2);
    
    numErr_V1 = sum(testLabelCat_V1 ~= predictedLabels_V1);
    numErr_V2 = sum(testLabelCat_V2 ~= predictedLabels_V2);
    
    ber_V1(iSNR)    = numErr_V1 / numTestSymbols;
    ber_V2(iSNR)    = numErr_V2 / numTestSymbols;
    ber_total(iSNR) = (numErr_V1 + numErr_V2) / (2 * numTestSymbols);
    
    fprintf(' done.  BER_V1=%.2e (%d)  BER_V2=%.2e (%d)  BER_tot=%.2e\n', ...
        ber_V1(iSNR), numErr_V1, ber_V2(iSNR), numErr_V2, ber_total(iSNR));
end

%% ====================== Floor Zero BER ======================
berFloor = 1e-7;
ber_V1(ber_V1 < 5/numTestSymbols)       = berFloor;
ber_V2(ber_V2 < 5/numTestSymbols)       = berFloor;
ber_total(ber_total < 5/numTestSymbols)  = berFloor;

%% ====================== Plot BER Curves ======================

figure('Name', 'DL-NOMA-CSK 2-User BER', 'Position', [100 100 800 550]);

semilogy(snrRangeTest, ber_V1, '-o', ...
    'LineWidth', 1.5, 'MarkerSize', 7, ...
    'MarkerFaceColor', [0 0.45 0.74], ...
    'Color', [0 0.45 0.74], ...
    'DisplayName', 'V_1');
hold on;

semilogy(snrRangeTest, ber_V2, '-s', ...
    'LineWidth', 1.5, 'MarkerSize', 7, ...
    'MarkerFaceColor', [0.85 0.33 0.10], ...
    'Color', [0.85 0.33 0.10], ...
    'DisplayName', 'V_2');

semilogy(snrRangeTest, ber_total, '-d', ...
    'LineWidth', 1.5, 'MarkerSize', 7, ...
    'MarkerFaceColor', [0.47 0.67 0.19], ...
    'Color', [0.47 0.67 0.19], ...
    'DisplayName', 'Overall');

hold off;
grid on;
set(gca, 'FontSize', 13);
xlabel('E_b/N_0 (dB)', 'FontSize', 14);
ylabel('Bit Error Rate', 'FontSize', 14);
legend('Location', 'southwest', 'FontSize', 11);
ylim([1e-6 1]);
xlim([snrRangeTest(1) snrRangeTest(end)]);
xticks(snrRangeTest);

%% ====================== Save Results ======================

resultsDir = 'results';
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

savePath = fullfile(resultsDir, 'ber_results_2user.mat');
save(savePath, 'snrRangeTest', 'ber_V1', 'ber_V2', 'ber_total', ...
    'params', 'numTestSymbols');
fprintf('\nBER results saved to %s\n', savePath);

figPath = fullfile(resultsDir, 'ber_curve_2user.fig');
savefig(gcf, figPath);
pngPath = fullfile(resultsDir, 'ber_curve_2user.png');
exportgraphics(gcf, pngPath, 'Resolution', 300);
fprintf('Figure saved to %s\n', pngPath);

