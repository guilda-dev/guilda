function out = vec2complex(a)
% Convert an interleaved real vector [re1; im1; re2; im2; ...] to a complex vector.
%
% Works column by column for a matrix.
%
% See also tools.complex2vec
out = a(1:2:end,:) + 1j*a(2:2:end,:);
end