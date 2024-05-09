classdef plot < handle

    properties
        plt
        graph
        GCF
        power_network
    end

    methods

        function obj = plot(net,graphVisible)
            if nargin <2
                graphVisible = true;
            end

            obj.power_network = net;

            obj.plt = figure('Visible',graphVisible,'Position',[100,100,750,400]);

            subplot('Position',[0,0.06,0.495,0.9])
            obj.graph{1} = supporters.for_graph.map_bus(net);
            
            subplot('Position',[0.25,0.05,0.001,0.001])
            title('\bf{Focus on bus}','FontSize',20,'FontAngle','italic','Color','#7E2F8E')
            
            subplot('Position',[0.505,0.06,0.495,0.9])
            obj.graph{2} = supporters.for_graph.map_component(net);
            
            subplot('Position',[0.75,0.05,0.001,0.001])
            title('\bf{Focus on component}','FontSize',20,'FontAngle','italic','Color','#77AC30')
            sgtitle('\bf{Power Network graph}','FontSize',20,'FontAngle','italic')
            subplot('Position',[0.5,0.1,0.001,0.7])
            axis off
            xline(0,'LineStyle',':','LineWidth',2)

            obj.GCF = gcf;

        end
    end

end