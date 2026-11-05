function out = vec2complex(a)
% Convert an interleaved real vector [re1; im1; re2; im2; ...] to a complex vector.
%
% Works column by column for a matrix.
%
% See also tools.complex2vec
    arguments (Input)
        a    % Interleaved real vector or matrix [re1; im1; re2; im2; ...].
    end
    arguments (Output)
        out  % Complex vector or matrix.
    end
out = a(1:2:end,:) + 1j*a(2:2:end,:);
end
