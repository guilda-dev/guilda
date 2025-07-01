% DAE:
%   dx/dt = A11*x+A12*x_+B1*u
%   0 = A21*x+A22*x_+B2*u
%   y = C1*x+C2*x_+D*u
% ODE:
%   dx/dt = A_*x+B_*u
%   y = C_*x+D_*u

function [A_, B_, C_, D_] = dae2ode(A11, A12, A21, A22, B1, B2, C1, C2, D)

if nargin<8
    error("Input arguments are missing.");
elseif nargin<9
    D = zeros(size(C1*B1));
end

A_ = A11-A12/A22*A21;
B_ = B1-A12/A22*B2;
C_ = C1-C2/A22*A21;
D_ = D-C2/A22*B2;

end

