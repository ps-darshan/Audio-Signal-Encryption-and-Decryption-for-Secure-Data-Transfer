%% main_fft_audio_encryption.m (with MSE, PSNR, Entropy)
%  This script is now fully self-contained and requires NO toolboxes.
clc; clear; close all;
% --- CONFIG ---
wav_filename = 'Alert.wav';   % Your input file
expected_tol = 1e-10;                % tolerance for reconstruction check

% --- 1) Load audio ---
[audio_data, Fs] = audioread(wav_filename);
disp('Audio loaded successfully.');
% Force column, mono
if isrow(audio_data)
    audio_data = audio_data';
end
if size(audio_data, 2) > 1
    audio_data = audio_data(:, 1);
    disp('Stereo input detected. Using first channel only.');
end
N = length(audio_data);

% --- 2) Generate encryption key ---
key_struct.seed = 12345;   % main key (user-defined)
fprintf('Key seed used: %d\n', key_struct.seed);

% --- 3) Encrypt & Decrypt ---
encrypted_audio = Encrypt_FFT(audio_data, key_struct);
decrypted_audio = Decrypt_FFT(encrypted_audio, key_struct);

% --- 4) Check reconstruction error (Fidelity Check 1) ---
error_signal = decrypted_audio - audio_data;
max_error = max(abs(error_signal));
fprintf('Maximum reconstruction error: %e\n', max_error);
if max_error < expected_tol
    disp('✅ Decryption is lossless (perfect reconstruction).');
else
    disp('⚠️ Decryption NOT lossless.');
end

%% --- 5) Security check (wrong key) ---
fprintf('\n--- RUNNING SECURITY CHECK (WRONG KEY) ---\n');
wrong_key = key_struct;
wrong_key.seed = key_struct.seed + 1;  % small change in seed
fprintf('Using wrong key seed = %d\n', wrong_key.seed);
decrypted_wrong = Decrypt_FFT(encrypted_audio, wrong_key);
disp('Security check tests complete.');

%% %%% --- ADDED SECTION: CALCULATE ALL METRICS --- %%%
fprintf('\n--- CALCULATING QUANTITATIVE METRICS ---\n');

% --- A) Fidelity Metrics (Original vs. Correctly Decrypted) ---
mse_fidelity = my_mse(audio_data, decrypted_audio);
psnr_fidelity = my_psnr(audio_data, decrypted_audio);

% --- B) Security Metrics (Original vs. Encrypted) ---
mse_security_enc = my_mse(audio_data, encrypted_audio);
psnr_security_enc = my_psnr(audio_data, encrypted_audio);

% --- C) Wrong Key Metrics (Original vs. Wrongly Decrypted) ---
mse_security_wrong = my_mse(audio_data, decrypted_wrong);
psnr_security_wrong = my_psnr(audio_data, decrypted_wrong);

% --- D) Entropy Metrics ---
% Convert signals to uint8 (0-255) for entropy calculation
original_uint8 = uint8((audio_data + 1) * 127.5);
encrypted_uint8 = uint8((encrypted_audio + 1) * 127.5);
decrypted_wrong_uint8 = uint8((decrypted_wrong + 1) * 127.5);

% Calculate Entropy
ent_original = my_entropy(original_uint8);
ent_encrypted = my_entropy(encrypted_uint8);
ent_wrong_key = my_entropy(decrypted_wrong_uint8);

fprintf('All metrics calculated.\n');


%% --- 6) Lossless verification plots (like your example) ---
figure('Name','Lossless Audio Waveform Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
plot(audio_data, 'b');
title('Original Audio Signal');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,2);
plot(encrypted_audio, 'b');
title('Encrypted Audio Signal (FFT Phase Encrypted)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,3);
plot(decrypted_audio, 'b');
title('Decrypted Audio Signal (Recovered with Correct Key)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
sgtitle('Lossless Audio Waveform Comparison');
% --- Histogram comparison for lossless check ---
figure('Name','Lossless Histogram Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
histogram(audio_data,100,'FaceColor','b');
title('Histogram - Original Audio'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,2);
histogram(encrypted_audio,100,'FaceColor','b');
title('Histogram - Encrypted Audio (FFT Phase Randomized)'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,3);
histogram(decrypted_audio,100,'FaceColor','b');
title('Histogram - Decrypted Audio (Recovered)'); xlabel('Amplitude'); ylabel('Count'); grid on;
sgtitle('Lossless Histogram Comparison');

%% --- 7) Security check (wrong key) plots ---
% --- Audio waveform comparison (3-subplot style) ---
figure('Name','Security Audio Waveform Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
plot(audio_data, 'b');
title('Original Audio Signal');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,2);
plot(encrypted_audio, 'b');
title('Encrypted Audio Signal (FFT Phase Encrypted)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
subplot(3,1,3);
plot(decrypted_wrong, 'b');
title('Decrypted Audio Signal (Wrong Key)');
xlabel('Samples'); ylabel('Amplitude'); grid on;
sgtitle('Security Audio Waveform Comparison');
% --- Histogram comparison (3-subplot style) ---
figure('Name','Security Histogram Comparison','NumberTitle','off','Position',[100 100 900 700]);
subplot(3,1,1);
histogram(audio_data,100,'FaceColor','b');
title('Histogram - Original Audio'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,2);
histogram(encrypted_audio,100,'FaceColor','b');
title('Histogram - Encrypted Audio (FFT Phase Randomized)'); xlabel('Amplitude'); ylabel('Count'); grid on;
subplot(3,1,3);
histogram(decrypted_wrong,100,'FaceColor','b');
title('Histogram - Decrypted Audio (Wrong Key)'); xlabel('Amplitude'); ylabel('Count'); grid on;
sgtitle('Security Histogram Comparison');

disp('All plots generated.');

%% %%% --- ADDED SECTION: FINAL METRICS REPORT --- %%%
% This table prints all the results to the command window
% for Person 4 to copy into the final report.
disp(' ');
disp('================================================================');
disp('         FINAL METRICS: FFT PHASE SCRAMBLE');
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


%% %%% --- ADDED SECTION: HELPER FUNCTIONS --- %%%
% These functions must be at the end of the script

function E = my_entropy(signal_uint8)
    % Calculates the Shannon entropy of a uint8 signal
    % This version uses base MATLAB 'histcounts' and NO toolboxes.
    
    % Get histogram counts for 256 bins (for uint8 data from 0 to 255)
    [counts, ~] = histcounts(signal_uint8, 256, 'BinLimits', [0, 255], 'BinMethod', 'integer');
    
    total = sum(counts);
    
    % Calculate probability of each bin
    P = counts / total;
    
    % Remove zero probabilities (log2(0) is -Inf)
    P(P == 0) = [];
    
    % Calculate entropy: E = -sum(P * log2(P))
    E = -sum(P .* log2(P));
end

function mse = my_mse(A, B)
    % Calculates the Mean Squared Error between two signals A and B
    if size(A) ~= size(B)
        error('Signals must be the same size for MSE.');
    end
    err = A - B;
    squared_err = err .^ 2;
    mse = mean(squared_err, 'all');
end

function psnr = my_psnr(A, B)
    % Calculates the Peak Signal-to-Noise Ratio between two signals A and B
    % Assumes the peak signal value (MAX_I) is 1.0 
    % (since original audio is in range [-1, 1], peak val is 1)
    
    mse_val = my_mse(A, B);
    
    if mse_val == 0
        psnr = Inf; % Perfect reconstruction
    else
        peakval = 1; % Our signal's peak amplitude is 1
        psnr = 10 * log10(peakval^2 / mse_val);
    end
end

