classdef map_component_for_UI < tools.graph.map_base

    properties(Access = private)
        idx_component_empty
    end

    methods
        function obj = map_component_for_UI(net,ax)
            obj@tools.graph.map_base(net,ax)
            zlim(ax,[-1.3,1.3])
            view(ax,0,35)
            %hold(ax, 'off')

            obj.function_CompHeight     = @Height;
            obj.function_BusSize        = @(obj, V, I)     10;
            obj.function_CompSize       = @(obj,t,x,V,I,u) 20;
            obj.function_BusLineWidth   = @(obj, V, I)     1;
            obj.function_BranchWidth    = @(obj,Vfrom,Vto) 1;
        
            obj.set_equilibrium;

            obj.set_Color_subject2CompType
            obj.set_Marker;
            %obj.remove_nonunit_Line;

            %axis(ax,'off')
        end
    end

    methods(Access=private)

        function set_Marker(obj)
            for i = 1:obj.nbus
                comp = obj.net.a_bus{i}.component;
                nclass = class(comp);
                if contains(nclass,'generator') || contains(nclass,'Generator')
                    obj.Graph.NodeLabel{obj.nbus+i}  = [' Gen',num2str(i)];
                    obj.Graph.Marker{obj.nbus+i} = 'o';
                elseif contains(nclass,'load') || contains(nclass,'Load')
                    obj.Graph.NodeLabel{obj.nbus+i}  = [' Load',num2str(i)];
                    obj.Graph.Marker{obj.nbus+i} = 'v';
                elseif isa(comp,'component_empty')
                    obj.Graph.NodeLabel{obj.nbus+i}  = '';
                    obj.Graph.Marker{obj.nbus+i} = 'none';
                else
                    temp_idx = find(nclass=='.',1,"last");
                    obj.Graph.NodeLabel{obj.nbus+i}  =  [' ',nclass(temp_idx+1:end)];
                    obj.Graph.Marker{obj.nbus+i} = 's';
                end
                obj.Graph.Marker(1:obj.nbus) = {'s'};
                
                if ismember('tag',fieldnames(comp))
                    obj.Graph.NodeLabel{obj.nbus+i}  = [comp.tag,num2str(i)];
                end

                obj.Graph.Marker{i} = 's';
                obj.Graph.NodeFontSize(i+[0,obj.nbus]) = 5;
                obj.Graph.NodeColor(i+obj.nbus,:) = [0.3,0.3,0.3];
            end
        end
% 
%         function set_Marker(obj)
%             for i = 1:obj.nbus
%                 comp = obj.net.a_bus{i}.component;
%                 nclass = class(comp);
%                 obj.Graph.NodeLabel{i}  = '';
%                 if contains(nclass,'generator') || contains(nclass,'Generator')
%                     obj.Graph.NodeLabel{obj.nbus+i}  = ['  Gen',num2str(i)];
%                     obj.Graph.Marker{obj.nbus+i} = 'o';
%                 elseif contains(nclass,'load') || contains(nclass,'Load')
%                     obj.Graph.NodeLabel{obj.nbus+i}  = ['  Load',num2str(i)];
%                     obj.Graph.Marker{obj.nbus+i} = 'v';
%                 elseif isa(comp,'component_empty')
%                     obj.Graph.NodeLabel{obj.nbus+i}  = '';
%                     obj.Graph.Marker{obj.nbus+i} = 'none';
%                 else
%                     obj.Graph.NodeLabel{obj.nbus+i}  = ['  Component',num2str(i)];
%                     obj.Graph.Marker{obj.nbus+i} = 's';
%                 end
%                 
%                 if ismember('tag',fieldnames(comp))
%                     obj.Graph.NodeLabel{obj.nbus+i}  = [comp.tag,num2str(i)];
%                 end
%                 
%                 obj.Graph.Marker{i} = 's';
%                 obj.Graph.NodeFontSize(i+[0,obj.nbus]) = 10;
%                 obj.Graph.NodeColor(i+obj.nbus,:) = [0.3,0.3,0.3];
%             end
%             obj.Graph.MarkerSize    = 15*ones(2*obj.nbus,1);
%         end

        function remove_nonunit_Line(obj)
            obj.Graph.LineStyle(obj.Edge_idx_nonunit) = {'none'};
        end

    end
end


function out = Height(comp,~,~,V,I,~)
    if isa(comp,'component_empty')
        out = nan;
    else
        out = 0.5 * sign( V(1)*I(1) + V(2)*I(2));
    end
end

function out = M(comp,~,~,~,~,~)
    if contains(class(comp),'generator')
        out = comp.parameter{1,'M'};
    else
        out = nan;
    end
end
