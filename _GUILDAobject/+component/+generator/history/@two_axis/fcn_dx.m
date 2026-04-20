function rvec_dx = fcn_dx(obj, ~, rvec_x, c_V, rvec_u)
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
%  ・rvec_x        (:,1) double : [delta; omega; Eq; Ed]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rvec_u        (:,1) double : [Pmech; Vfield]
%
% <Varargout>
%  ・rvec_dx        (:,1) double : d/dt [delta; omega; Eq]
%

    % Parameter
    para   = obj.parameter.model;
    omega0 = obj.omega0;
    Xd   = para.Xd;
    Xdp  = para.Xd_p;
    Xq   = para.Xq;
    Xqp  = para.Xq_p;
    D    = para.D;

    % State
    delta = rvec_x(1);
    omega = rvec_x(2);
    Eq    = rvec_x(3);
    Ed    = rvec_x(4);

    % Input
    Pm    = rvec_u(1);
    Vfd   = rvec_u(2);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % Current
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xqp  *(Vd-Ed);
    Pout =  Vd*Id + Vq*Iq;
    
    % Diff Fcn
    ddelta = omega0 *omega;
    domega = - D*omega - Pout + Pm;
    dEq    = - Eq - (Xd-Xdp)*Id + Vfd;
    dEd    = - Ed + (Xq-Xqp)*Iq;

    rvec_dx = [ddelta; domega; dEq; dEd];
end