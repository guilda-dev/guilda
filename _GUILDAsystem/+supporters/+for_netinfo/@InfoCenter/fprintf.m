function fprintf(obj,lang)
    if nargin<2
        lang = get(0,'Language');
    end
    
    [complist,~,compidx] = unique(obj.data.bus{:,'connected_component'},'stable');
    [lconlist,~,lconidx] = unique(obj.broadcast(@(c)string(class(c)),'cl'),'stable');
    [gconlist,~,gconidx] = unique(obj.broadcast(@(c)string(class(c)),'cg'),'stable');
    if contains(lang,'ja')
        format_disp('送電線のパラメータ'                    ,obj.data.branch)
        format_disp('潮流設定/母線のパラメータ'              ,obj.data.bus)
        cformat_disp('機器のパラメータ'                     ,obj.data.parameter.component            ,complist,compidx)
        cformat_disp('機器の平衡点'                        ,obj.data.x_equilibrium.component        ,complist,compidx)
        cformat_disp('local controllerのパラメータ'        ,obj.data.parameter.controller_local     ,lconlist,lconidx)
        cformat_disp('local controllerの状態の初期値'      ,obj.data.x_equilibrium.controller_local ,lconlist,lconidx)
        cformat_disp('global controllerのパラメータ'       ,obj.data.parameter.controller_global    ,gconlist,gconidx)
        cformat_disp('global controllerの状態の初期値'     ,obj.data.x_equilibrium.controller_global,gconlist,gconidx)
    else
        format_disp('Branch Parameter'                  ,obj.data.branch)
        format_disp('Power Flow / Bus parameter'        ,obj.data.bus)
        cformat_disp('Component Parameter'              ,obj.data.parameter.component            , complist,compidx)
        cformat_disp('Equilibrium Point'                ,obj.data.x_equilibrium.component        , complist,compidx)
        cformat_disp('local controller Parameter'       ,obj.data.parameter.controller_local     , lconlist,lconidx)
        cformat_disp('local controller Initiali States' ,obj.data.x_equilibrium.controller_local , lconlist,lconidx)
        cformat_disp('global controller Parameter'      ,obj.data.parameter.controller_global    , gconlist,gconidx)
        cformat_disp('global controller Initiali States',obj.data.x_equilibrium.controller_global, gconlist,gconidx)
    end
end


function format_disp(title,tab)
    disp(title)
    disp('=======================================')
    disp(tab)
    disp('=======================================')
    fprintf('\n\n\n')
end

function cformat_disp(title,data,namelist,nameidx)%#ok
    disp(title)
    disp('================================')

    if isempty(namelist) || isempty(data)
        disp('No class')
    else
        for i = 1:numel(namelist)
            name = namelist(i);
            disp(">> "+name)
            id = data(nameidx==i,:);
            id = id(:,tools.harrayfun(@(i) any(~isnan(id{:,i})), 1:size(id,2)));
            if isempty(setdiff(id.Properties.VariableNames,'idx'))
                disp('No data')
            else
                disp(id)
            end
            fprintf('\n')
        end
    end
    disp('================================')
    fprintf('\n\n\n')
end