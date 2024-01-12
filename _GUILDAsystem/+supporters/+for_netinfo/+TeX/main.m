function main(net,data,path)

    if nargin<2 || isempty(data)
        data = net.information('do_report',false);
    end

    if nargin<3 || isempty(path)
        path = uigetdir;
    end
    time_text = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    subpath = [fullfile(path,'Texfile'),time_text];
    mkdir(subpath)
    mkdir(fullfile(subpath,'data'))

    fullpath = mfilename("fullpath");
    template_path = [ fullpath(1:end-4),'tex_template/'];
    copyfile( [template_path,'main.tex'], subpath)
    copyfile( [template_path,'latexmkrc'], subpath)

    % Graph plot
        figsz = 800;
        fig = figure('Visible','off','Position',[0,0,figsz,0.8*figsz]);

        g = supporters.for_graph.map(net,gca);
        g.initialize;

        cellfun(@(b) set(b,'marker', 'none' ), g.a_bus)
        cellfun(@(b) set(b,'Label' , []     ), g.a_bus)
        
        is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), net.a_bus);
        cellfun(@(c) set(c,'marker', 's'), g.a_component( is_empty));
        cellfun(@(c) set(c,'size'  , 10  ), g.a_component( is_empty));
        cellfun(@(c) set(c,'size'  , 15  ), g.a_component(~is_empty));
        cellfun(@(c) set(c,'ZData' , 0  ), g.a_component);
        cellfun(@(c) set(c,'Label' , [c.object.Tag,num2str(c.number)] ), g.a_component)

        cellfun(@(b) set(b,'width',1     ), g.a_branch)
        cellfun(@(b) set(b,'color',[0.5,0.5,0.5]), g.a_branch)
        cellfun(@(b) set(b,'width',0.1   ), g.a_busline(~is_empty))
        cellfun(@(b) set(b,'style','none'), g.a_busline(is_empty))
        
        g.Graph.NodeLabelColor = [0,0,0];
        g.Graph.NodeFontSize = 8;
        g.remove_margin;

        g.XLim = 'auto';
        g.YLim = 'auto';
        title('Power System Graph')

        drawnow

        fig.PaperUnits = "points";
        fig.PaperSize = figsz*[1,0.45];
        
    saveas(fig,fullfile(subpath,'data','network_graph'),'png')
    saveas(fig,fullfile(subpath,'data','network_graph'),'epsc')
    close(fig)

    [a_Tag{1},~,idx_Tag{1}] = unique(tools.cellfun(@(b) b.component.Tag, net.a_bus),'stable');
    [a_Tag{2},~,idx_Tag{2}] = unique(tools.cellfun(@(b) class(b.component), net.a_bus),'stable');
    text_data = {'Graph Node Label', 'Component class'};
    for i = 1:2
        text_data{i} =['\underline{\textbf{',text_data{i},'}}\\',newline,...
                        tools.harrayfun(@(j) ['$\cdot$',replace(a_Tag{i}{j},'_','\_'),' : ',num2str(find(idx_Tag{i}'==j)),'\\',newline],1:numel(a_Tag{i})),...
                       '\\',newline];
    end
    writelines(horzcat(text_data{:}),fullfile(subpath,'data','graph.tex'))

    
    % bus
    text_data = supporters.for_netinfo.TeX.table2tex(removevars(data.bus,["Vequilibrium","Iequilibrium"]));
    writelines(text_data,fullfile(subpath,'data','bus.tex'))

    % branch
    text_data = supporters.for_netinfo.TeX.table2tex(data.branch);
    writelines(text_data,fullfile(subpath,'data','brnch.tex'))

    Tabfunc = @(f) {data.(f), data.parameter.(f), data.x_equilibrium.(f)};
    
    % component
    a_cls = tools.cellfun(@(b) b.component, net.a_bus);
    var   = Tabfunc('component');
    text_data = supporters.for_netinfo.TeX.getTeX_eachClass( a_cls, var{:}, data.u_equilibrium.component);
    writelines(text_data,fullfile(subpath,'data','component.tex'))

    % local controller
    a_cls = net.a_controller_local;
    var   = Tabfunc('controller_local');
    text_data = supporters.for_netinfo.TeX.getTeX_eachClass( a_cls, var{:});

    writelines(text_data,fullfile(subpath,'data','controller_local.tex'))


    % global controller
    a_cls = net.a_controller_global;
    var   = Tabfunc('controller_global');
    text_data = supporters.for_netinfo.TeX.getTeX_eachClass( a_cls, var{:});

    writelines(text_data,fullfile(subpath,'data','controller_global.tex'))


    zip([path,filesep,'GUILDAreport',time_text,'.zip'],subpath)
    rmdir(subpath,'s')
end



