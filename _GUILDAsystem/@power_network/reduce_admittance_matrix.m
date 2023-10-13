function [Y_reduced, Ymat_reduced, A_reproduce, Amat_reproduce]...
    = reduce_admittance_matrix(obj, Y, index)

n_bus = size(Y, 1);
reduced = false(n_bus, 1);
reduced(setdiff(1:n_bus, index)) = true;

Y11 = Y(~reduced, ~reduced);
Y12 = Y(~reduced, reduced);
Y21 = Y(reduced, ~reduced);
Y22 = Y(reduced, reduced);

Y_reduced = Y11 - Y12*inv(Y22)*Y21;%#ok
Ymat_reduced = tools.complex2matrix(Y_reduced);

A_reproduce = zeros(n_bus, sum(~reduced));
A_reproduce(~reduced, :) = eye(sum(~reduced));
A_reproduce(reduced, :) = -Y22\Y21;
Amat_reproduce = tools.complex2matrix(A_reproduce);
end