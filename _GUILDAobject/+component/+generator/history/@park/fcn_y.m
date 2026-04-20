function y = fcn_y(obj, ~, rvec_x, c_V)
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
%  ・rvec_x        (:,1) double : [delta; omega; Eq; Ed; psiq; psid]
%  ・c_V           (1,1) double : BUS VOLTAGE（COMPLEX）
%
% <Varargout>
%  ・rvec_y        (:,1) double : [omega; Efd; Vabs]

    % Parameter
    para   = obj.parameter.model;
    Xd   = para.Xd;
    Xdp  = para.Xd_p;
    Xdpp = para.Xd_pp;
    Xls  = para.X_ls;

    % State
    delta = rvec_x(1);
    omega = rvec_x(2);
    Eq    = rvec_x(3);
    psid  = rvec_x(6);

    % dq-trans
    Vq  = real( exp(1j*delta) * conj(c_V) );
    
    % Current
    terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
    Id  = 1/Xdpp * (terminal_q-Vq);
    
    % Diff Fcn
    dpsid  = -psid +Eq -(Xdp-Xls)*Id;
    Efd    = Eq + (Xd-Xdp)*( Id + (Xdp-Xdpp)/(Xdp-Xls)^2 * dpsid);

    % Voltage
    Vabs = abs(c_V);

    y = [omega; Efd; Vabs];
end