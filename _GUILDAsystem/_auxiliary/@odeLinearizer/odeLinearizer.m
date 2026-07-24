classdef odeLinearizer < auxiliary
   properties (SetAccess=private)
       odeNetwork 
       odeLinearSystem
       odeNonUnitBus (:,1) double = []

       Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = "Kron";

       Kxx (:,:) double = []
       Kxv (:,:) double = []
       Kvx (:,:) double = []
       Kvv (:,:) double = []
       Lvv (:,:) double = []
       
   end
   
   methods
       function obj = odeLinearizer(net, NonUnit, opt)
           arguments
               net 
               NonUnit = tools.vcellfun(@(busi) isempty(busi.a_Component), net.a_Bus);
               opt.Algorithm  {mustBeMember(opt.Algorithm, ["Kron","Feedback", "DAE"])} = "Feedback"
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
           switch obj.Algorithm
               case "Kron"
                   [A,B,C,D,E] = obj.get_LTI_viaKron;
               case "Feedback"
                   [A,B,C,D,E] = obj.get_LTI_viaFeedback;
               case "DAE"
                   [A,B,C,D,E] = obj.get_DAE;
           end

           if nargout == 1
               varargout{1} = obj.odeLinearSystem;
           else
               varargout{1} = A;
               varargout{2} = B;
               varargout{3} = C;
               varargout{4} = D;
               varargout{5} = E;
           end
       end
       
   end
   methods(Access=protected)
       [A, B, C, D, E] = get_DAE(obj)
       [A, B, C, D, E] = get_LTI_viaKron(obj)
       [A, B, C, D, E] = get_LTI_viaFeedback(obj)           
   end
end