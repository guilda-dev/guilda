function out = complex2vec(a)
% Convert a complex vector to the interleaved real vector [re1; im1; re2; im2; ...].
%
% See also tools.vec2complex, tools.complex2matrix
    arguments (Input)
        a    % Complex vector.
    end
    arguments (Output)
        out  % Interleaved real column vector [re1; im1; re2; im2; ...].
    end
out = zeros(numel(a)*2, 1);
out(1:2:end,:) = real(a);
out(2:2:end,:) = imag(a);
end
