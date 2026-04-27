classdef odeLinearizer < handle
% <@Desc>
% Linearizer class that computes an approximate linear time-invariant (LTI) model
% from the nonlinear power system ODE around the current operating point.
% Supports Kron reduction and feedback-based linearization algorithms.
% <@Role>
% auxiliary
% <@Constructor>
% odeLinearizer(net, NonUnit, Algorithm="Feedback")
%  i.e.
%  >> lin = odeLinearizer(net)
%  >> lin = odeLinearizer(net, NonUnit, Algorithm="Kron")
%      - net:       PowerNetwork object to linearize
%      - NonUnit:   indices or logical array of non-unit buses (default: buses without components)
%      - Algorithm: linearization algorithm ("Kron" or "Feedback") (default: "Feedback")

   properties (SetAccess=private)

       % <@Desc> PowerNetwork object used as the target for linearization.
       % <@Role> Linearize
       % <@Type> PowerNetwork
       % <@Size> 1x1
       odeNetwork 

       % <@Desc> Cached linearized state-space system.
       % <@Role> Linearize
       % <@Type> ss
       % <@Size> 1x1
       odeLinearSystem

       % <@Desc> Indices of non-unit buses (buses without connected components).
       % <@Role> Linearize
       % <@Type> double
       % <@Size> Nx1
       odeNonUnitBus (:,1) double = []

       % <@Desc> Algorithm used for linearization ("Kron" or "Feedback").
       % <@Role> Linearize
       % <@Type> string
       % <@Size> 1x1
       Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback"])} = "Kron";
   end
   
   methods
       function obj = odeLinearizer(net, NonUnit, opt)
       % <@Desc>
       % Creates an odeLinearizer instance for the given power network.
       % <@Role>
       % Constructor
       % <@Abst>
       % Initialize the linearizer with the network and mark non-unit buses.
       % <@Signatures>
       % [
       %   "obj = odeLinearizer(net)",
       %   "obj = odeLinearizer(net, NonUnit, Algorithm=\"Feedback\")"
       % ]
       % <@varargin>
       % [
       %   {
       %     "Name": "net",
       %     "Type": "PowerNetwork",
       %     "Description": "Power network to linearize.",
       %     "Required": true,
       %     "Default": "-"
       %   },
       %   {
       %     "Name": "NonUnit",
       %     "Type": "logical array or double array",
       %     "Description": "Indices or logical array identifying non-unit buses.",
       %     "Required": false,
       %     "Default": "buses without connected components"
       %   },
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
       %     "Name": "obj",
       %     "Type": "odeLinearizer",
       %     "Description": "Created odeLinearizer instance."
       %   }
       % ]
           arguments
               net 
               NonUnit = tools.vcellfun(@(busi) isempty(busi.a_Component), net.a_Bus);
               opt.Algorithm  {mustBeMember(opt.Algorithm, ["Kron","Feedback"])} = "Feedback"
           end
           obj.odeNetwork = net;
           bus = obj.odeNetwork.a_Bus;

           for i=1:numel(bus)                              
               if ismember(i,NonUnit)
                   bus{i}.l_isNonUnit = true;
                   obj.odeNonUnitBus = [obj.odeNonUnitBus; i];
               end
           end

           obj.Algorithm = opt.Algorithm;
       end

       function varargout = get_sys(obj)
       % <@Desc>
       % Computes the LTI state-space model by the selected linearization algorithm.
       % <@Role>
       % Linearize
       % <@Abst>
       % Returns the linearized system as an ss object or as separate (A,B,C,D) matrices.
       % <@Signatures>
       % [
       %   "sys = obj.get_sys()",
       %   "[A, B, C, D] = obj.get_sys()"
       % ]
       % <@varargin>
       % [
       %   {
       %     "Name": "obj",
       %     "Type": "odeLinearizer",
       %     "Description": "Linearizer instance.",
       %     "Required": true,
       %     "Default": "-"
       %   }
       % ]
       % <@varargout>
       % [
       %   {
       %     "Name": "varargout",
       %     "Type": "ss or double matrix",
       %     "Description": "If nargout==1: ss object. Otherwise: A, B, C, D matrices."
       %   }
       % ]
           switch obj.Algorithm
               case "Kron"
                   [A,B,C,D] = obj.get_LTI_viaKron;
               case "Feedback"
                   [A,B,C,D] = obj.get_LTI_viaFeedback;
           end

           if nargout == 1
               varargout{1} = obj.odeLinearSystem;
           else
               varargout{1} = A;
               varargout{2} = B;
               varargout{3} = C;
               varargout{4} = D;
           end
       end
       
   end
   methods(Access=protected)
       [A, B, C, D] = get_LTI_viaKron(obj)
       [A, B, C, D] = get_LTI_viaFeedback(obj)           
   end
end