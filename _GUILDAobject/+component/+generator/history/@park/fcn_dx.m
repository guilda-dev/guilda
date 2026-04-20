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
%  ・rvec_x        (:,1) double : [delta; omega; Eq; Ed; psiq; psid]
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
    Xdpp = para.Xd_pp;
    Xqpp = para.Xq_pp;
    Xls  = para.X_ls;
    D    = para.D;

    % State
    delta = rvec_x(1);
    omega = rvec_x(2);
    Eq    = rvec_x(3);
    Ed    = rvec_x(4);
    psiq  = rvec_x(5);
    psid  = rvec_x(6);

    % Input
    Pm    = rvec_u(1);
    Vfd   = rvec_u(2);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % Current
    terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
    terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);
    Id  = 1/Xdpp * (terminal_q-Vq); 
    Iq  = 1/Xqpp * (Vd-terminal_d);
    Pout =  Vd*Id + Vq*Iq;
    
    % Diff Fcn
    ddelta = omega0 *omega;
    domega = - D*omega - Pout + Pm;
    dpsiq  = -psiq -Ed -(Xqp-Xls)*Iq;
    dpsid  = -psid +Eq -(Xdp-Xls)*Id;
    dEq    = - Eq - (Xd-Xdp)*( Id + (Xdp-Xdpp)/(Xdp-Xls)^2 * dpsid) + Vfd;
    dEd    = - Ed + (Xq-Xqp)*( Iq + (Xqp-Xqpp)/(Xqp-Xls)^2 * dpsiq);

    rvec_dx = [ddelta; domega; dEq; dEd; dpsiq; dpsid];
end