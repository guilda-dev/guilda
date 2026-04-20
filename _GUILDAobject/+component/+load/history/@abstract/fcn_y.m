function rv_y = fcn_y(~, ~, ~, ~) 
%
% 機器の出力変数を計算
%
%        ┌---┐       
%        | C |                 ┌------------┐
%        | o |=================| Local      |
%        | m |        →        | Controller |
%        | p |  rv_y:output  └------------┘
%        └---┘         
%                　　　 
%
% <Varargout>
%  ・rv_y        (:,1) double : []
    
    rv_y = [];
end