function encrypted_audio = Encrypt_FFT(audio_data, key_struct)
    if isrow(audio_data)
        audio_data = audio_data';
    end
    if size(audio_data, 2) > 1
        audio_data = audio_data(:, 1);
    end
    N = length(audio_data);

    % Validate key struct
    if ~isstruct(key_struct) || ~isfield(key_struct, 'seed')
        error('Invalid key_struct. Must contain a .seed field.');
    end
    seed = key_struct.seed;
    rng(seed);

    % FFT
    Y = fft(audio_data);

    % Generate random phase key (half-spectrum only)
    halfN = floor(N/2);
    rand_phase = (rand(halfN,1)*2*pi) - pi;

    % Construct full Hermitian-symmetric phase vector
    phase_key = zeros(N,1);
    phase_key(2:halfN) = rand_phase(2:end);
    phase_key(N-halfN+2:end) = -flip(rand_phase(2:end));

    % Encrypt by phase addition
    encrypted_fft = abs(Y) .* exp(1j*(angle(Y) + phase_key));
    encrypted_audio = real(ifft(encrypted_fft));
end

