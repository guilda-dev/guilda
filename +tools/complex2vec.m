function out = complex2vec(a)
out = zeros(numel(a)*2, 1);
out(1:2:end,:) = real(a);
out(2:2:end,:) = imag(a);
end