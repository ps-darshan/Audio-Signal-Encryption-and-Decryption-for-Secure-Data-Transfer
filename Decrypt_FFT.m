function decrypted_audio = Decrypt_FFT(encrypted_audio, key_struct)
    if isrow(encrypted_audio)
        encrypted_audio = encrypted_audio';
    end
    if size(encrypted_audio, 2) > 1
        encrypted_audio = encrypted_audio(:, 1);
    end
    N = length(encrypted_audio);

    if ~isstruct(key_struct) || ~isfield(key_struct, 'seed')
        error('Invalid key_struct. Must contain a .seed field.');
    end
    seed = key_struct.seed;
    rng(seed);

    % FFT
    EncY = fft(encrypted_audio);

    % Regenerate identical Hermitian-symmetric phase key
    halfN = floor(N/2);
    rand_phase = (rand(halfN,1)*2*pi) - pi;
    phase_key = zeros(N,1);
    phase_key(2:halfN) = rand_phase(2:end);
    phase_key(N-halfN+2:end) = -flip(rand_phase(2:end));

    % Decrypt by subtracting phase key
    decrypted_fft = abs(EncY) .* exp(1j*(angle(EncY) - phase_key));
    decrypted_audio = real(ifft(decrypted_fft));
end
