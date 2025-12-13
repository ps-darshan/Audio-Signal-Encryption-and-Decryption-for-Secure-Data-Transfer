function decrypted_audio = Decrypt_Chaos(encrypted_audio, key_struct)
    % Decrypts an audio signal encrypted with the 30/70 scaled chaos method.
    %
    % INPUTS:
    %   encrypted_audio - The encrypted audio signal.
    %   key_struct      - A struct with the EXACT SAME .x0 and .r fields
    %                     used for encryption.
    %
    % OUTPUT:
    %   decrypted_audio - The recovered original audio signal (column vector).
    
    % --- 1. Input Validation & Formatting ---
    if isrow(encrypted_audio)
        encrypted_audio = encrypted_audio'; % Transpose if it's a row
    end
    
    if size(encrypted_audio, 2) > 1
        encrypted_audio = encrypted_audio(:, 1);
    end
    
    N = length(encrypted_audio);
    
    % Validate the key struct
    try
        x0 = key_struct.x0;
        r = key_struct.r;  % <--- CRITICAL BUG FIX (was key_struct.x0)
    catch ME
        error('Invalid key_struct. It MUST contain .x0 and .r fields. Error: %s', ME.message);
    end

    % --- 2. Regenerate the IDENTICAL Chaotic Key Stream ---
    % This is the core of symmetric encryption: the key stream must
    % be perfectly identical to the one used for encryption.
    key_stream = zeros(N, 1);
    key_stream(1) = x0;
    
    for i = 2:N
        % The core logistic map equation
        key_stream(i) = r * key_stream(i-1) * (1 - key_stream(i-1));
    end
    
    % --- 3. Scale Key Stream ---
    % Regenerate the *identical* 70% noise mask
    % Scale key_stream [0, 1] to [-0.7, 0.7]
    key_stream_scaled = (key_stream * 1.4) - 0.7; 
    
    % --- 4. Decrypt by Reversing the Operation (Subtraction) ---
    % This subtraction recovers the 30%-scaled audio
    decrypted_scaled_audio = encrypted_audio - key_stream_scaled;
    
    % --- 5. Restore Original Volume ---
    % We must now amplify the 30% signal back to 100%
    % (Dividing by 0.3 is the same as multiplying by 3.333...)
    decrypted_audio = decrypted_scaled_audio / 0.3; 
    
    % --- 6. Clipping (Good Practice) ---
    % This cleans up any tiny floating-point rounding errors that
    % might push the signal slightly out of the [-1, 1] bounds.
    decrypted_audio = max(min(decrypted_audio, 1), -1);
end

