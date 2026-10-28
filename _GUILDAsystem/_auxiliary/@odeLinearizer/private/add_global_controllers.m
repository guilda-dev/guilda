function [Axx, Bxv, Bxu, Cix, E, str_z] = add_global_controllers(net, str_x, str_u, Axx, Bxv, Bxu, Cix, Diu, E)
% Add the global controllers of net to the linear model of the components (used by Kron and DAE)
%
%   E dx/dt = Axx x + Bxv v + Bxu u,   i = Cix x + ... + Diu u
%   x: component states (names str_x), u: component inputs (names str_u)
%
% Global controller k:  E_k dz_k/dt = A_k z_k + B_k w_k,  y_k = C_k z_k + D_k w_k
%   its inputs w_k are component states (InputName in str_x): w_k = S_k x
%   its outputs y_k add to component inputs (OutputName in str_u): u <- u + T_k y_k
%
% The states z of all controllers are put before x, in the order of a_GlobalController.
% The returned matrices are for [z; x]; Bxu keeps the external input u. str_z: names of z.
    a_GC  = net.a_GlobalController;
    str_z = string.empty(0,1);
    if isempty(a_GC)
        return
    end
    nx = size(Axx,1);
    nv = size(Bxv,2);
    nu = size(Bxu,2);

    Az    = cell(numel(a_GC),1);
    Bzx   = cell(numel(a_GC),1);
    Cuz   = cell(1,numel(a_GC));
    Ez    = cell(numel(a_GC),1);
    str_z = cell(numel(a_GC),1);  %#ok (cell while collecting)
    Dux   = zeros(nu,nx);
    for k = 1:numel(a_GC)
        sysGC = a_GC{k}.get_sys("full",true);
        [lv_w, iw] = ismember(string(sysGC.InputName),  str_x);
        [lv_y, iy] = ismember(string(sysGC.OutputName), str_u);
        if ~all(lv_w) || ~all(lv_y)
            error("GUILDA:odeLinearizer:GlobalControllerPort", ...
                  "The ports of the global controller '%s' are not found in the linearized system.", a_GC{k}.str_tag)
        end
        S = zeros(numel(iw), nx);  S(sub2ind(size(S), 1:numel(iw), iw(:)')) = 1;
        T = zeros(nu, numel(iy));  T(sub2ind(size(T), iy(:)', 1:numel(iy))) = 1;

        Az{k}    = sysGC.A;
        Bzx{k}   = sysGC.B * S;
        Cuz{k}   = T * sysGC.C;
        Dux      = Dux + T * sysGC.D * S;
        Ez{k}    = sysGC.E;
        str_z{k} = string(sysGC.StateName);
    end
    Az    = blkdiag(Az{:});
    Bzx   = vertcat(Bzx{:});
    Cuz   = horzcat(Cuz{:});
    str_z = [string.empty(0,1); vertcat(str_z{:})];
    nz    = size(Az,1);

    Axx = [Az, Bzx; Bxu*Cuz, Axx + Bxu*Dux];
    Bxv = [zeros(nz,nv); Bxv];
    Bxu = [zeros(nz,nu); Bxu];
    Cix = [Diu*Cuz, Cix + Diu*Dux];
    E   = blkdiag(Ez{:}, E);
end
