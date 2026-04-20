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
%  ・rvec_x        (:,1) double : [delta; omega; Eq]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rvec_u        (:,1) double : [Pmech; Vfield]
%
% <Varargout>
%  ・c_I           (1,1) double : BUS CURRENT（COMPLEX）

    % Parameter
    para   = obj.parameter.model;
    Xdp  = para.Xd_p;
    Xq   = para.Xq;

    % State
    delta = rvec_x(1);
    Eq    = rvec_x(3);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    % Current
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xq  * (Vd);
    Idq = Iq + 1j*Id;

    c_I = exp(1j*delta) * conj(Idq);
end