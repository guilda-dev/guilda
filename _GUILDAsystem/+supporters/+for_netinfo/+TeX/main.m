function main(net,data,path)

    fig = figure('Visible','off','WindowState','maximized');
    if nargin<2 || isempty(data)
        data = net.information('do_report',false,'plot_graph',gca);
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

    
    saveas(fig,fullfile(subpath,'data','network_graph'),'epsc')
    close(fig)
    
    text_data = supporters.for_netinfo.TeX.table2tex(data.bus);
    writelines(text_data,fullfile(subpath,'data','bus.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.branch);
    writelines(text_data,fullfile(subpath,'data','brnch.txt'))

    % component
    text_data = supporters.for_netinfo.TeX.table2tex(data.component);
    writelines(text_data,fullfile(subpath,'data','component.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.parameter.component);
    writelines(text_data,fullfile(subpath,'data','component_parameter.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.x_equilibrium.component);
    writelines(text_data,fullfile(subpath,'data','component_equilibrium.txt'));

    text_data = supporters.for_netinfo.TeX.get_component_dynamics(net);
    writelines(text_data,fullfile(subpath,'data','component_dynamics.txt'))


    % local controller
    text_data = supporters.for_netinfo.TeX.table2tex(data.controller_local);
    writelines(text_data,fullfile(subpath,'data','controller_local.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.parameter.controller_local);
    writelines(text_data,fullfile(subpath,'data','controller_local_parameter.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.x_equilibrium.controller_local);
    writelines(text_data,fullfile(subpath,'data','controller_local_equilibrium.txt'))


    % global controller
    text_data = supporters.for_netinfo.TeX.table2tex(data.controller_global);
    writelines(text_data,fullfile(subpath,'data','controller_global.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.parameter.controller_global);
    writelines(text_data,fullfile(subpath,'data','controller_global_parameter.txt'))

    text_data = supporters.for_netinfo.TeX.table2tex(data.x_equilibrium.controller_global);
    writelines(text_data,fullfile(subpath,'data','controller_global_equilibrium.txt'))


    zip([path,filesep,'GUILDAreport',time_text,'.zip'],subpath)
    
    rmdir(subpath,'s')
end



