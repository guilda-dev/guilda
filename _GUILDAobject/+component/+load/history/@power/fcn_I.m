function c_I = fcn_I(~, ~, ~, c_V, rv_u)
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
%  ・rv_u        (:,1) double : [Pload; Qload]
%
% <Varargout>
%  ・c_I           (1,1) double : BUS CURRENT（COMPLEX）

    % Impedance
        Pload = rv_u(1);
        Qload = rv_u(2);
        Sload = Pload+1j*Qload;

    % Current
        c_I = conj(Sload/c_V);
end