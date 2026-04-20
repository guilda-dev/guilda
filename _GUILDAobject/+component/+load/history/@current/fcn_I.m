function c_I = fcn_I(~, ~, ~, ~, rv_u)
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
%  ・rv_x        (:,1) double : []
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%  ・rv_u        (:,1) double : [Iabs; Iarg]
%
% <Varargout>
%  ・c_I           (1,1) double : BUS CURRENT（COMPLEX）

    % Input
    Iabs = rv_u(1);
    Iarg = rv_u(2);

    % Current
    c_I = Iabs*exp(1j*Iarg);
end