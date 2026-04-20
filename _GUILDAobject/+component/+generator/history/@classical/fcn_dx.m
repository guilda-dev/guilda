function rvec_dx = fcn_dx(obj, r_time, rvec_x, c_V, rvec_u)
%
% Calculate the differential value of the state
%      
%  ┌------------┐         ┌---┐
%  | Local      |=========|   |
%  | Controller |    →    | C |
%  └------------┘  r_vec  | o |
%                  INPUT  | m |
%  ┌------------┐         | p |
%  |   Bus      |=========|   |
%  └------------┘    →    └---┘         
%                   c_V
%                 VOLTAGE
%
% <Varargin>
%  ・r_time        (1,1) double : time
%  ・rvec_x        (:,1) double : [delta; omega; Eq]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rvec_u        (:,1) double : [Pmech; Vfield]
%
% <Varargout>
%  ・rvec_dx       (:,1) double : d/dt [delta; omega]
%

    % Parameter
    para   = obj.parameter.model;
    omega0 = obj.omega0;
    Xd = para.Xd;
    Xq = para.Xq;
    D  = para.D;
    
    % State
    delta = rvec_x(1);
    omega = rvec_x(2);

    % Input
    Pm    = rvec_u(1);
    Vfd   = rvec_u(2);

    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    % Current
    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Pout = Vq*Iq + Vd*Id;

    % Diff Fcn
    ddelta = omega0 * omega;
    domega = - D*omega - Pout + Pm;
    
    rvec_dx  = [ddelta; domega];

end