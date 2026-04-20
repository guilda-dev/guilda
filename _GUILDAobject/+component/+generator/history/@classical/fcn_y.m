function rvec_y = fcn_y(~, r_time, rvec_x, c_V) 
%
% 機器の出力変数を計算
%
%        ┌---┐       
%        | C |                 ┌------------┐
%        | o |=================| Local      |
%        | m |        →        | Controller |
%        | p |  rvec_y:output  └------------┘
%        └---┘         
%                　　　 
%
% <Varargin>
%  ・r_time        (1,1) double : time
%  ・rvec_x        (:,1) double : [delta; omega; Eq]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%
% <Varargout>
%  ・rvec_y        (:,1) double : [omega; Vabs]
    
    % State
    omega = rvec_x(2);

    % Voltage
    Vabs  = abs(c_V);

    rvec_y = [omega; Vabs];
end