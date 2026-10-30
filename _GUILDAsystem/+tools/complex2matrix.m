function out = complex2matrix(a)
% Convert a complex matrix to its real 2x2-block form.
%
% Each element a + jb of `a` becomes the block [a, -b; b, a], so that the real form of
% y = A*x is complex2vec(y) = complex2matrix(A) * complex2vec(x).
%
% See also tools.complex2vec, tools.vec2complex
    r = real(a);
    c = imag(a);
    out = zeros(size(r, 1)*2, size(r, 2)*2);
    out(1:2:end, 1:2:end) = r;
    out(2:2:end, 1:2:end) = c;
    out(1:2:end, 2:2:end) = -c;
    out(2:2:end, 2:2:end) = r;
end