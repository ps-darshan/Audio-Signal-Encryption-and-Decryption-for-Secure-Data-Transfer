function key_struct = Generate_Chaos_Key()
    % Generates a new, random, secure key struct for chaos encryption.
    %
    % OUTPUT:
    %   key_struct - A struct with two fields:
    %                .x0: A random initial condition (0 to 1).
    %                .r:  A random rate parameter in the chaotic region (3.9 to 4.0).

    disp('Generating new chaotic key...');
    
    % Generate a random initial condition between 0 and 1.
    % rand() provides a 64-bit double-precision number.
    key_struct.x0 = rand();
    
    % Generate a random rate 'r' in the strongly chaotic region.
    % We use the range [3.9, 4.0] for guaranteed chaotic behavior.
    key_struct.r = 3.9 + (4.0 - 3.9) * rand();
    
    fprintf('New Key Generated:\n  x0: %.15f\n  r:  %.15f\n', key_struct.x0, key_struct.r);
end
