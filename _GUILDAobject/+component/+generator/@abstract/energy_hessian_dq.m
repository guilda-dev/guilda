function H = energy_hessian_dq(x, V, rv_aq, r_Eq, rv_ad, r_Ed, Xd, Xq, K)
% Hessian over [x; theta; V] of the energy function of a synchronous generator.
%
% Shared by the get_hessian overrides of the synchronous generators. The energy function is
%   U = U_int(x) + (Eq - Vq)^2 / (2 Xd) + (Vd - Ed)^2 / (2 Xq),
%   Vq = V cos(delta - theta),  Vd = V sin(delta - theta),
% where delta = x(1), Eq and Ed are the internal voltages behind the reactances Xd and
% Xq (the subtransient ones for park), linear in x with the gradients rv_aq and rv_ad
% (constant Eq for classical: rv_aq = 0), and U_int is quadratic in x with the Hessian K
% (the kinetic term 2*pi*f0*M*omega^2/2 and the internal flux terms). Then dU/ddelta = P
% (Id = (Eq - Vq)/Xd, Iq = (Vd - Ed)/Xq, P = Vd Id + Vq Iq), dU/dtheta = -P and
% dU/dV = -Q/V, and
%   H = blkdiag(K, 0) + (gA gA.' + A HA)/Xd + (gB gB.' + B HB)/Xq
% with A = Eq - Vq, B = Vd - Ed and their gradients gA, gB and Hessians HA, HB over
% [x; theta; V] (HA = -Hessian of Vq, HB = Hessian of Vd, nonzero only in delta, theta, V).
%
% See also component.generator.two_axis.get_hessian
    arguments (Input)
        x     (:,1) double  % States, delta first.
        V     (2,1) double  % [pu] Bus voltage [Vre; Vim].
        rv_aq (1,:) double  % Gradient of Eq with respect to x.
        r_Eq  (1,1) double  % [pu] Eq at the point.
        rv_ad (1,:) double  % Gradient of Ed with respect to x.
        r_Ed  (1,1) double  % [pu] Ed at the point.
        Xd    (1,1) double  % [pu] Reactance behind Eq.
        Xq    (1,1) double  % [pu] Reactance behind Ed.
        K     (:,:) double  % Hessian of U_int over x.
    end
    arguments (Output)
        H (:,:) double  % Hessian over [x; theta; V], (n_x+2) x (n_x+2).
    end
    n_x = numel(x);
    c_V = [1,1j]*V;
    r_V = abs(c_V);
    phi = x(1) - angle(c_V);
    sn  = sin(phi);
    cs  = cos(phi);
    Vd  = r_V*sn;
    Vq  = r_V*cs;

    iv = [1, n_x+1, n_x+2];                 % delta, theta, V
    gVq = zeros(n_x+2,1);  gVq(iv) = [-Vd; Vd; cs];
    gVd = zeros(n_x+2,1);  gVd(iv) = [ Vq; -Vq; sn];
    HVq = zeros(n_x+2);    HVq(iv,iv) = [-Vq, Vq, -sn;  Vq, -Vq, sn; -sn, sn, 0];
    HVd = zeros(n_x+2);    HVd(iv,iv) = [-Vd, Vd,  cs;  Vd, -Vd, -cs; cs, -cs, 0];

    gA = [rv_aq(:); 0; 0] - gVq;
    gB = gVd - [rv_ad(:); 0; 0];
    H  = blkdiag(K, zeros(2)) + (gA*gA.' - (r_Eq - Vq)*HVq)/Xd + (gB*gB.' + (Vd - r_Ed)*HVd)/Xq;
end
