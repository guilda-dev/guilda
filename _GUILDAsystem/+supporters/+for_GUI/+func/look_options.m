function look_options(options,net)

[is_gen,is_dynamic,~,~]=func.search_idx_component(net);
is_gen = is_gen|is_dynamic;
nx_gen = zeros(sum(is_gen)+1,1);
nx_gen(1) = 0;
for itr = 2:numel(is_gen)+1
    nx_gen(itr) = nx_gen(itr-1) + net.bus{itr-1}.component.get_nx();
end
para_word = {'δ','Δω','E','Vfd','ξ1','ξ2','ξ3'}; 

if isfield(options, 'x_init')
    disp(' ')
    diff_xss = options.x_init-net.x_ss;
    idx_nx_change = find(diff_xss);
    if numel(idx_nx_change)~=0
        for itr = 1:numel(idx_nx_change)
            idx_bus_change = find(nx_gen<idx_nx_change(itr));
            idx_bus_change = idx_bus_change(end);
            idx_para_change = idx_nx_change(itr)-nx_gen(idx_bus_change);
            disp(['bus',num2str(idx_bus_change),':',para_word{idx_para_change},'を',num2str(diff_xss(idx_nx_change(itr)))])
        end
        disp('だけずらした初期値')
    else
        disp('状態xの初期値は平衡点のまま')
    end
    disp(' ')
else
    disp('状態xの初期値は平衡点のまま')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'V_init')
    disp(' ')
    diff_Vss = options.V_init-net.V_ss;
    if sum(diff_Vss)~=0
        for itr = 1:2:numel(diff_Vss)
            diff_bus_itr = diff_Vss(itr)+1j*diff_Vss(itr+1);
            if diff_bus_itr~=0
            disp(['bus',num2str((itr+1)/2),'のVを',num2str(diff_bus_itr)])
            end
        end
        disp('だけずらした初期値')
    else
        disp('Vの初期値は平衡点のまま')
    end
    disp(' ')
else
    disp('Vの初期地は平衡点のまま')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'I_init')
    disp(' ')
    diff_Iss = options.I_init-net.I_ss;
    if sum(diff_Iss)~=0
        for itr = 1:2:numel(diff_Iss)
            diff_bus_itr = diff_Iss(itr)+1j*diff_Iss(itr+1);
            if diff_bus_itr~=0
            disp(['bus',num2str((itr+1)/2),'のIを',num2str(diff_bus_itr)])
            end
        end
        disp('だけずらした初期値')
    else
        disp('Iの初期値は平衡点のまま')
    end
    disp(' ')
else
    disp('Iの初期値は平衡点のまま')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'xk_init')
    disp('コントローラの初期条件の読み取りは未実装 orz ')
else
    disp('コントローラの初期設定なし')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'xkg_init')
    disp('グローバルコントローラの初期条件の読み取りは未実装 orz ')
else
    disp('グローバルコントローラの初期設定なし')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'fault')
    if numel(options.fault)~=0
        disp(' ')
        disp('地絡')
        for itr = 1:numel(options.fault)
            if numel(options.fault{itr}{2})==1
                disp(['bus',num2str(options.fault{itr}{2}(1)),':',num2str(options.fault{itr}{1}(1)),'~',num2str(options.fault{itr}{1}(2)),'秒で発生']);
            else
                for itr2 = 1:numel(options.fault{itr}{2})
                    disp(['bus',num2str(options.fault{itr}{2}(itr2)),':',num2str(options.fault{itr}{1}(1)),'~',num2str(options.fault{itr}{1}(2)),'秒で発生']);
                end
            end
        end
    else
        disp('地絡なし')
    end
else
    disp('地絡なし')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(options, 'linear')
    disp(' ')
    if options.linear 
        disp('線形シミュレーション')
    end
else
    disp(' ')
    disp('非線形シミュレーション')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end