function out = complex2matrix(a)
r = real(a);
c = imag(a);
out = zeros(size(r, 1)*2, size(r, 2)*2);
out(1:2:end, 1:2:end) = r;
out(2:2:end, 1:2:end) = c;
out(1:2:end, 2:2:end) = -c;
out(2:2:end, 2:2:end) = r;
end