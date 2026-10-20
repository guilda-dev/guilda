function sys = get_sys(obj, opt)
% <@Desc>
% Computes the linearized state-space model of the entire power network.
% <@Role>
% Linearize
% <@Abst>
% Creates an odeLinearizer and returns the LTI model for the network.
% <@Signatures>
% [
%   "sys = net.get_sys()",
%   "sys = net.get_sys(Algorithm=\"Feedback\")"
% ]
% <@varargin>
% [
%   {
%     "Name": "Algorithm",
%     "Type": "string scalar",
%     "Description": "Linearization algorithm: \"Kron\" or \"Feedback\".",
%     "Required": false,
%     "Default": "\"Feedback\""
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "sys",
%     "Type": "ss",
%     "Description": "Linearized state-space model of the power network."
%   }
% ]
    arguments
        obj 
        opt.Algorithm (1,1) {mustBeMember(opt.Algorithm, ["Kron", "Feedback"])} = "Feedback" 
    end
    lin = odeLinearizer(obj, 7, "Algorithm", opt.Algorithm);
    sys = lin.get_sys;
end