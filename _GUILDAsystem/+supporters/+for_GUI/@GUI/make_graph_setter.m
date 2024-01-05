function make_graph_setter(app,data)
    %各busのgraph設定tableに関して
    if nargin<2
        data = app.net.information('do_report',false);
    end
    variable = unique(data.component{:,'class'});
    %idx = simulation.net_info.look_component_type(app.net);
    %variable = fieldnames(idx);
    var1 = false(size(variable));
    var1(1:3) = true;
    prior = (1:size(variable,1))';
    color = cell(size(variable));
    color(:) = {'k'};
    num = numel(variable);
    if num>1
        color{1} = '#D95319';   
        if num>2
            color{2} = '#0072BD';
            if num>3
                color{3} = '#7E2F8E';
            end
        end
    end
    
    shape = cell(size(variable));
    shape(:) = {'o'};
    shape{1} = 'o';         shape{2} = 's';         shape{3} = 'o';
    n_bus = numel(app.net.a_bus);
    Size = ones(size(variable));
    Size(1) = round(90/sqrt(n_bus));
    Size(2) = round(60/sqrt(n_bus));
    Size(3) = round(45/sqrt(n_bus));
    Size = string(Size);
    temp = cell(size(Size));
    temp(:) = {Size{:}};
    Size = temp;
    app.graph_properties_table.Data = table(var1,variable,color,shape,Size,prior);
end

%{

    temp = cell(size(Size));
    temp(:) = {size{:}};
%}