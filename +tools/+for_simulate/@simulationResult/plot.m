function varargout = plot(obj,varargin)
%ー実行方法ー
%>> obj.plot();
%>> obj.plot(Name,Value,...)
%
%ー引数ー
%・ Name  :'para'
%   　      プロットするパラメータ
%　 Value : V,Vreal,Vimag,Vabs,Vangle
%  　       I,Ireal,Iimag,Iabs,Iangle
% 　        power,P,Q,S
% 　        X,各機器で定義した状態変数名
% 　既定値 : {'X','Vabs','P'}
%
%・ Name  :'bus_idx'
%          プロットする母線番号
%　 Value : double配列で指定
% 　        componentクラスの変数名
% 　        'all_bus'
% 　        'bus_PV','bus_PQ','bus_slack'
% 　既定値 : {'all_bus'}
%
%・ Name  :'legend'
% 　       プロットの凡例の有無
% 　Value : true/false
% 　既定値 : true
%
%・ Name  :'LineWidth'
% 　       プロットの線の太さ
% 　Value : double値
% 　既定値 : 2
%　
%・ Name  :'disp_command'
% 　       実行コマンドの出力
% 　Value : true/false
% 　既定値 : false
%

    set = inputParser;
    set.CaseSensitive = false;
    cellfun(@(field) addParameter(set,field,obj.plot_default.(field)), fieldnames(obj.plot_default));
    parse(set, varargin{:});
    set = set.Results;
        
    %bus_idxで指定されたインデックスの精査
    list.bus  = obj.net_data.className.bus;
    list.comp = strcat('component.' ,obj.net_data.className.mac);
    list.cl   = strcat('controller.',obj.net_data.className.c_l);
    list.cg   = strcat('controller.',obj.net_data.className.c_l);
    set.bus_idx = identify_busidx(set.bus_idx,list);
    set.bus_idx = unique(set.bus_idx,'sorted');
    if numel(set.bus_idx)==0
        disp('No bus')
        return
    end
    temp = ismember(set.bus_idx,1:numel(obj.V));
    if any(~temp)
        disp(['there are not bus which idx are',mat2str(set.bus_idx(~temp)),'.']);
    end
    set.bus_idx = set.bus_idx(temp);

    if ischar(set.para)
        set.para = {set.para};
    end

    data = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,set.para);
    if numel(data)==0
        disp('No parameter')
        varargout = cell(1,nargout);
        return
    end
    if set.para_unique
        [~,idx,~] = unique(arrayfun(@(st)st.title,data,'UniformOutput',false),'stable');
    else
        idx = 1:numel(data);
    end

    
    if set.plot
        plt       = figure();
        colororder(set.colormap)
        t = tiledlayout('flow','TileSpacing','compact');
        data      = data(idx);
        fplot     = @(access,idx) plot(obj.t,access(idx),'LineWidth',set.LineWidth);
        all_idx   = sort(unique(tools.harrayfun(@(idx)reshape(data(idx).bus_idx,1,[]),1:numel(data))));
        command   = tools.harrayfun(@(idx) plot_module(data,idx,all_idx,fplot),1:numel(data));
        if set.legend
            num = numel(obj.net.a_bus);
            bus_idx = all_idx(all_idx<=num);
            all_idx = all_idx - num;
            num = numel(obj.net.a_controller_local);
            cl_idx  = all_idx(all_idx<=num & all_idx>0);
            all_idx = all_idx - num;
            num = numel(obj.net.a_controller_global);
            cg_idx  = all_idx(all_idx<=num & all_idx>0);
            
            wl_bus = tools.arrayfun(@(idx)['bus/mac',   num2str(idx)],bus_idx);
            wl_cl  = tools.arrayfun(@(idx)['con_local' ,num2str(idx)], cl_idx);
            wl_cg  = tools.arrayfun(@(idx)['con_global',num2str(idx)], cg_idx);

            lgd = legend(t.Children(1).Children(end:-1:1),[wl_bus,wl_cl,wl_cg]);
            lgd.Layout.Tile = 'east';
            lgd.NumColumns = ceil(numel(all_idx)/40);
        end
        if set.disp_command
            fprintf(horzcat(command{:}))
        end
        if nargout >0
            varargout{1} = plt;
        end

        if nargout >1
            varargout{2} = t;
        end
    else
        if nargout >0; varargout{1} = []; end
        if nargout >1; varargout{2} = []; end
    end

    if nargout>2
        varargout{3} = data;
    end
end

function out = identify_busidx(data,list)
    switch class(data)
        case 'double'
            out = reshape(data,1,[]);
        case 'cell'
            out = tools.hcellfun(@(idx) identify_busidx(idx,list,data));
        case 'char'
            if ismember(data,{'all_bus','all','all bus'})
                out = 1:numel(list.bus);
            else
                domain = DNS(data);
                switch domain
                    case list.comp
                        out = reshape(find(strcmp(list.comp,data)),1,[]);
                    case list.bus
                        out = reshape(find(strcmp(list.bus ,data)),1,[]);
                    case list.cl
                        out = reshape(find(strcmp(list.cl  ,data)),1,[]) + numel(list.bus);
                    case list.cg
                        out = reshape(find(strcmp(list.cg  ,data)),1,[]) + numel(list.bus) + numel(list.cl);
                    otherwise
                        disp([data,'is not found.'])
                        out =[];
                end
            end
        otherwise
            disp('data_type of set.bus_idx is not supported')
            out =[];
    end
end

function command = plot_module(data,idx,all_idx,fplot)
    tdata = data(idx);
    nexttile
    hold on
    grid on
    for i = all_idx
        if ismember(i,tdata.bus_idx)
            fplot(tdata.access,i);
        else
            plot(nan,nan)
        end
    end
    xlabel('Time(s)')
    title(tdata.title,'FontSize',15)
    hold off
    command = "・"+num2str(idx)+"番目のプロット\n"+...
               ">> hold on \n"+...
               tdata.command+" \n"+....
               ">> xlabel('時刻(t)') \n"+...
               ">> title('"+tdata.title+"') \n\n";
end