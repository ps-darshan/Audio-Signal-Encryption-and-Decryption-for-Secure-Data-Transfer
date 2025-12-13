function encrypted_audio = Encrypt_Chaos(audio_data, key_struct)
    % Encrypts audio by scaling it to 30% and hiding it with a 70%
    % noise mask. This makes the encrypted signal unrecognizable.
    
    % --- 1. Input Validation & Formatting ---
    if isrow(audio_data)
        audio_data = audio_data';
    end
    if size(audio_data, 2) > 1
        audio_data = audio_data(:, 1);
    end
    N = length(audio_data);
    try
        x0 = key_struct.x0;
        r = key_struct.r;
    catch ME
        error('Invalid key_struct. It MUST contain .x0 and .r fields. Error: %s', ME.message);
    end
    
    % --- 2. Generate Chaotic Key Stream ---
    key_stream = zeros(N, 1);
    key_stream(1) = x0;
    for i = 2:N
        % The core logistic map equation
        key_stream(i) = r * key_stream(i-1) * (1 - key_stream(i-1));
    end
    
    % --- 3. Scale Both Audio and Key Stream (30/70 Split) ---
    % We make the audio "quieter" (30%) and the noise "louder" (70%).
    
    % Scale audio to 30%
    audio_scaled = audio_data * 0.3;
    
    % Scale key_stream [0, 1] to [-0.7, 0.7] (70%)
    key_stream_scaled = (key_stream * 1.4) - 0.7; 
    
    % --- 4. Encrypt using Additive Masking ---
    % The 70% noise will now effectively mask the 30% audio.
    encrypted_audio = audio_scaled + key_stream_scaled;
    
    % --- 5. Clipping (Safety Net) ---
    % Max value is 0.3 + 0.7 = 1.0, so no clipping will occur.
    encrypted_audio = max(min(encrypted_audio, 1), -1);
    
end

