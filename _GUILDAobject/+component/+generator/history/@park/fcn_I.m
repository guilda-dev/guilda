function c_I = fcn_I(obj, ~, rvec_x, c_V, ~)
%
% Calculate the current to be sent to the bus
%
%        ┌---┐       
%        | C |                 ┌---┐
%        | o |=================| B |
%        | m |        →        | u |
%        | p |   c_I:current   | s |
%        └---┘                 └---┘
%                　　　     　c_V:Voltage
%
% <Varargin>
%  ・r_time        (1,1) double : time
%  ・rvec_x        (:,1) double : [delta; omega; Eq; Ed; psiq; psid]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rvec_u        (:,1) double : [Pmech; Vfield]
%
% <Varargout>
%  ・c_I           (1,1) double : BUS CURRENT（COMPLEX）

    % Parameter
    para   = obj.parameter.model;
    Xdp  = para.Xd_p;
    Xqp  = para.Xq_p;
    Xdpp = para.Xd_pp;
    Xqpp = para.Xq_pp;
    Xls  = para.X_ls;

    % State
    delta = rvec_x(1);
    Eq    = rvec_x(3);
    Ed    = rvec_x(4);
    psiq  = rvec_x(5);
    psid  = rvec_x(6);

    
    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % Current
    terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
    terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);
    Id  = 1/Xdpp * (terminal_q-Vq); 
    Iq  = 1/Xqpp * (Vd-terminal_d);
    Idq = Iq + 1j*Id;
    c_I   = exp(1j*delta) * conj(Idq);

end