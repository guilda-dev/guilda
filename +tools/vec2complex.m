function out = vec2complex(a)
out = a(1:2:end,:) + 1j*a(2:2:end,:);
end