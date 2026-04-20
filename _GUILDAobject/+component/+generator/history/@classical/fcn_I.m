function c_I = fcn_I(obj, r_time, rvec_x, c_V, rvec_u)
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
    Xd = para.Xd;
    Xq = para.Xq;
    
    % State
    delta = rvec_x(1);

    % Input
    Vfd   = rvec_u(2);

    % dq-trans
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    % Current
    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Idq = Iq + 1j*Id;

    c_I   = exp(1j*delta) * conj(Idq);
end