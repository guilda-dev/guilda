function sct_hessian = pack_hessian(obj, H, R)
% Split the Hessian over [x; theta; V] into the blocks of get_hessian and add the names.
%
% Shared by the get_hessian overrides: H is (n_x+2) x (n_x+2), ordered [x; theta; V],
% with the rows of theta and V the Jacobian of w_dev = -[P; Q/V]; R is n_x x n_x.
%
% See also get_hessian
    arguments (Input)
        obj
        H (:,:) double  % Hessian (or port-balance Jacobian) over [x; theta; V].
        R (:,:) double  % Matrix R of dx/dt = -R (Hxx x + Hxv v).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName.
    end
    n_x = numel(obj.sv_x);
    ix = 1:n_x;
    iv = n_x + (1:2);
    sv_port = ["theta";"V"];
    if ~isempty(obj.a_Bus)
        sv_port = reshape(string(obj.a_Bus.attach_tag(sv_port)), [], 1);
    end
    sv_x = strings(0,1);
    if n_x > 0
        sv_x = reshape(string(obj.attach_tag(reshape(string(obj.sv_x), [], 1))), [], 1);
    end
    sct_hessian = struct("Hxx", H(ix,ix), "Hxv", H(ix,iv), "Hvx", H(iv,ix), "Hvv", H(iv,iv), ...
                         "R", reshape(R, n_x, n_x), "StateName", sv_x, "PortName", sv_port);
end
