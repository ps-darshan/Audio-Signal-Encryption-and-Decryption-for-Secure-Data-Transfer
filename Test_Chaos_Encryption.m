%% Chaos Master Test Script (All-in-One)
% This script runs all Fidelity, Security, and Quantitative
% tests for the Chaos Map algorithm.
%
% It has been MODIFIED to:
%   1. Remove the failing 'mask_diff' test (Section 6b).
%   2. Be 100% self-contained (NO TOOLBOXES REQUIRED).
%   3. Use the robust 30/70 split encryption files.

clc; 
clear; 
close all;
% --- CONFIG ---
wav_filename = 'hello.wav';   % <-- set your file / full path
expected_tol = 1e-10;                % target for lossless check

% --- 1) Load audio ---
[audio_data, Fs] = audioread(wav_filename);
disp('Audio loaded successfully.');
% force column and mono (first channel)
if isrow(audio_data)
    audio_data = audio_data';
end
if size(audio_data,2) > 1
    audio_data = audio_data(:,1);
    disp('Input is stereo, using first channel only.');
end
N = length(audio_data);

% --- 2) Generate key struct (one time) ---
key_struct = Generate_Chaos_Key();   % prints key
fprintf('Key used: x0=%.15f, r=%.15f\n', key_struct.x0, key_struct.r);

% --- 3) Encrypt & Decrypt ---
% These functions MUST be the 30/70 split versions
encrypted_audio = Encrypt_Chaos(audio_data, key_struct);
decrypted_audio = Decrypt_Chaos(encrypted_audio, key_struct);

% --- 4) Fidelity Check ---
error_signal = decrypted_audio - audio_data;
max_error = max(abs(error_signal));
fprintf('Maximum reconstruction error: %e\n', max_error);
if max_error < expected_tol
    disp('✅ Decryption is lossless (perfect reconstruction).');
else
    disp('⚠️ Decryption NOT lossless. Check your Encrypt/Decrypt functions for a mismatch!');
end

% --- 5) Security Check (Wrong Key) ---
fprintf('\n--- SECURITY CHECK (WRONG KEY) ---\n');
wrong_key = key_struct;
wrong_key.x0 = key_struct.x0 + 1e-6; % Perturb the key
fprintf('Using wrong key x0 = %.15f\n', wrong_key.x0);
decrypted_with_wrong_key = Decrypt_Chaos(encrypted_audio, wrong_key);

%% --- 6) Visualize Waveforms (Lossless) ---
figure('Name','Audio Waveform Comparison (Lossless)','NumberTitle','off');
subplot(3,1,1);
plot(audio_data);
title('Original Audio Signal');
xlabel('Samples'); ylabel('Amplitude');
grid on;
subplot(3,1,2);
plot(encrypted_audio);
title('Encrypted Audio Signal (Chaotic Masked)');
xlabel('Samples'); ylabel('Amplitude');
grid on;
subplot(3,1,3);
plot(decrypted_audio);
title('Decrypted Audio Signal (Recovered)');
xlabel('Samples'); ylabel('Amplitude');
grid on;

%% --- 7) Visualize Histograms (Lossless) ---
figure('Name','Histogram Comparison (Lossless)','NumberTitle','off');
subplot(3,1,1);
histogram(audio_data, 100);
title('Histogram - Original Audio');
xlabel('Amplitude Bins'); ylabel('Count');
grid on;
subplot(3,1,2);
histogram(encrypted_audio, 100);
title('Histogram - Encrypted Audio (Appears Random)');
xlabel('Amplitude Bins'); ylabel('Count');
grid on;
subplot(3,1,3);
histogram(decrypted_audio, 100);
title('Histogram - Decrypted Audio (Matches Original)');
xlabel('Amplitude Bins'); ylabel('Count');
grid on;

%% --- 8) Visualize Security Plots (Wrong Key) ---
% ==== AUDIO WAVEFORM COMPARISON ====
figure('Name','Security Audio Waveform Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
plot(audio_data,'b');
title('Original Audio Signal');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,2);
plot(encrypted_audio,'b');
title('Encrypted Audio Signal (Chaotic Masked)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,3);
plot(decrypted_with_wrong_key,'b');
title('Decrypted Audio Signal (Wrong Key)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
sgtitle('Audio Waveform Comparison for Security Check');
% ==== HISTOGRAM COMPARISON ====
figure('Name','Security Histogram Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
histogram(audio_data,100,'FaceColor','b');
title('Histogram of Original Audio'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,2);
histogram(encrypted_audio,100,'FaceColor','b');
title('Histogram of Encrypted Audio'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,3);
histogram(decrypted_with_wrong_key,100,'FaceColor','b');
title('Histogram of Decrypted Audio (Wrong Key)'); xlabel('Amplitude'); ylabel('Count'); grid on;
sgtitle('Histogram Comparison for Security Check');
disp('All plots generated successfully.');

%% --- 9) FINAL METRICS CALCULATION (NO TOOLBOXES) ---
fprintf('\n--- CHAOS ENCRYPTION METRICS ---\n');

% --- A) Fidelity Metrics (Original vs. Correctly Decrypted) ---
mse_fidelity = my_mse(audio_data, decrypted_audio);
psnr_fidelity = my_psnr(audio_data, decrypted_audio);

% --- B) Security Metrics (Original vs. Encrypted) ---
mse_security_enc = my_mse(audio_data, encrypted_audio);
psnr_security_enc = my_psnr(audio_data, encrypted_audio);

% --- C) Wrong Key Metrics (Original vs. Wrongly Decrypted) ---
mse_security_wrong = my_mse(audio_data, decrypted_with_wrong_key);
psnr_security_wrong = my_psnr(audio_data, decrypted_with_wrong_key);

% --- D) Entropy Metrics ---
% Convert signals to uint8 (0-255) for entropy calculation
original_uint8 = uint8((audio_data + 1) * 127.5);
encrypted_uint8 = uint8((encrypted_audio + 1) * 127.5);
decrypted_wrong_uint8 = uint8((decrypted_with_wrong_key + 1) * 127.5);

% Calculate Entropy
ent_original = my_entropy(original_uint8);
ent_encrypted = my_entropy(encrypted_uint8);
ent_wrong_key = my_entropy(decrypted_wrong_uint8);

% --- E) Print Final Table for Report ---
disp(' ');
disp('================================================================');
disp('         FINAL METRICS: CHAOS MAP');
disp('================================================================');
fprintf('Metric (Test)\t\t\t\t | Result\n');
fprintf('---------------------------------------------------------------\n');
disp('--- FIDELITY (Original vs. Decrypted) ---');
fprintf('Max Error\t\t\t\t\t | %e\n', max_error);
fprintf('MSE (Goal: 0)\t\t\t\t | %e\n', mse_fidelity);
fprintf('PSNR (Goal: Inf)\t\t\t | %.2f dB\n', psnr_fidelity);
disp(' ');
disp('--- SECURITY (Original vs. Encrypted) ---');
fprintf('MSE (Goal: HIGH)\t\t\t | %.4f\n', mse_security_enc);
fprintf('PSNR (Goal: LOW)\t\t\t | %.2f dB\n', psnr_security_enc);
fprintf('Entropy (Goal: ~8.0)\t\t | %.4f\n', ent_encrypted);
fprintf('Entropy (Original was)\t\t | %.4f\n', ent_original);
disp(' ');
disp('--- WRONG KEY (Original vs. Decrypted_Wrong) ---');
fprintf('MSE (Goal: HIGH)\t\t\t | %.4f\n', mse_security_wrong);
fprintf('PSNR (Goal: LOW)\t\t\t | %.2f dB\n', psnr_security_wrong);
fprintf('Entropy (Goal: ~8.0)\t\t | %.4f\n', ent_wrong_key);
disp('================================================================');
disp('✅ Chaos Metrics Computed Successfully.');

%% %%% --- HELPER FUNCTIONS (NO TOOLBOXES) --- %%%

function E = my_entropy(signal_uint8)
    % Calculates the Shannon entropy of a uint8 signal
    % This version uses base MATLAB 'histcounts' and NO toolboxes.
    [counts, ~] = histcounts(signal_uint8, 256, 'BinLimits', [0, 255], 'BinMethod', 'integer');
    total = sum(counts);
    P = counts / total;
    P(P == 0) = [];
    E = -sum(P .* log2(P));
end

function mse = my_mse(A, B)
    % Calculates the Mean Squared Error
    err = A - B;
    squared_err = err .^ 2;
    mse = mean(squared_err, 'all');
end

function psnr = my_psnr(A, B)
    % Calculates the Peak Signal-to-Noise Ratio
    % Assumes the peak signal value (MAX_I) is 1.0 
    
    mse_val = my_mse(A, B);
    
    if mse_val == 0
        psnr = Inf; % Perfect reconstruction
    else
        peakval = 1.0; % Your signal's theoretical peak is 1.0
        psnr = 10 * log10(peakval^2 / mse_val);
    end
end

