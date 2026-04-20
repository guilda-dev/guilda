function rv_dx = fcn_dx(~, ~, ~, ~, ~)
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
%
% <Varargout>
%  ・rv_dx    (:,1) double : []
%

 rv_dx  = [];

end