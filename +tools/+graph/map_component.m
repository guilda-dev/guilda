classdef map_component < tools.graph.map_base

    properties(Access = private)
        idx_component_empty
    end

    methods
        function obj = map_component(net)
            obj@tools.graph.map_base(net)

            obj.function_CompSize    = @M;
            obj.function_BusHeigth   = 0;
            obj.function_CompHeight  = @Height;
            obj.function_BranchColor = @BrP;
            obj.function_BranchWidth = @(br,Vfrom,Vto) abs(1/br.x);
            obj.function_BusLineColor= @BusP;
            obj.function_BusLineWidth= 5;
            
            obj.set_MarkerStyle;
            obj.set_quiver
            obj.set_equilibrium
            
            hold off
            zlim([-1.1,1.1])
            view(180,30)
        end
    end

    methods(Access=private)

        function set_MarkerStyle(obj)
            for i = 1:obj.nbus
                comp = obj.net.a_bus{i}.component;
                nclass = class(comp);
                if contains(nclass,'generator') || contains(nclass,'Generator')
                    obj.Graph.NodeLabel{obj.nbus+i}  = ['Gen',num2str(i)];
                    obj.Graph.Marker{obj.nbus+i} = 'o';
                elseif contains(nclass,'load') || contains(nclass,'Load')
                    obj.Graph.NodeLabel{obj.nbus+i}  = ['Load',num2str(i)];
                    obj.Graph.Marker{obj.nbus+i} = 'v';
                elseif isa(comp,'component_empty')
                    obj.Graph.NodeLabel{obj.nbus+i}  = '';
                    obj.Graph.Marker{obj.nbus+i} = 'none';
                else
                    temp_idx = find(nclass=='.',1,"last");
                    obj.Graph.NodeLabel{obj.nbus+i}  = nclass(temp_idx+1:end);
                    obj.Graph.Marker{obj.nbus+i} = 's';
                end
                obj.Graph.Marker(1:obj.nbus) = {'s'};
                
                if ismember('tag',fieldnames(comp))
                    obj.Graph.NodeLabel{obj.nbus+i}  = [comp.tag,num2str(i)];
                end
            end
        end
    end
end

function out = BrP(br,Vfrom,Vto)
    y = 1/br.x;
    dV = (Vfrom(1)-Vto(1)) + 1j*(Vfrom(2)-Vto(2));
    out = real( dV * conj(y*dV) );
end

function out = BusP(~,V,I)
    out = V(1)*I(1) + V(2)*I(2);
end

function out = M(comp,~,~,~,~,~)
    if contains(class(comp),'generator')
        out = comp.parameter{1,'M'};
    else
        out = nan;
    end
end

function out = Height(comp,~,~,V,I,~)
    if isa(comp,'component_empty')
        out = nan;
    else
        out = 0.5 * sign( V(1)*I(1) + V(2)*I(2));
    end
end