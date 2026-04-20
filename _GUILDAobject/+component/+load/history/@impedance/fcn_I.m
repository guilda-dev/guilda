function c_I = fcn_I(~, ~, ~, c_V, rvec_u)
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
%  ・rvec_x        (:,1) double : []
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rvec_u        (:,1) double : [Gload; Bload]
%
% <Varargout>
%  ・c_I           (1,1) double : BUS CURRENT（COMPLEX）

    % Impedance
        Gload = rvec_u(1);
        Bload = rvec_u(2);
        Yload = Gload+1j*Bload;

    % Current
        c_I = Yload*c_V;
end