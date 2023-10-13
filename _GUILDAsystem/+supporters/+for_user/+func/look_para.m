function out = look_para(net,draw)
%引数に与えられたネットワークのモデルのパラメータを調べる用の関数
if nargin<2
    draw = true;
end

%パラメータの抽出
idx = supporters.for_user.func.look_component_type(net);
class_names = tools.vcellfun(@(b) {class(b.component)},net.a_bus);
%num_has_state_bus = sum(idx.has_state);
num_all_bus = numel(idx.has_state);
pidx = tools.vcellfun(@(b) isprop(b.component,'parameter'),net.a_bus);
plist = [supporters.for_user.func.look_gen_parameter_list(net),{'dammy'}];
get_para = @(comp)  [comp.parameter,...
                      table(nan(1,numel(plist)-size(comp.parameter,2)),...
                            'VariableNames',plist(~ismember(plist,comp.parameter.Properties.VariableNames)))];
gen_para        = arrayfun(@(b) get_para(net.a_bus{b}.component),find(pidx),'UniformOutput',false);
gen_para        = [table(find(pidx),class_names(pidx),'VariableName',{'bus_idx','model'}),vertcat(gen_para{:})];
out.gen_para    = gen_para(:,1:end-1);

Vss_para        = tools.vcellfun(@(b) b.V_equilibrium, net.a_bus);
Iss_para        = tools.vcellfun(@(b) b.I_equilibrium, net.a_bus);
PQss_para       = Vss_para .* conj(Iss_para);
out.flow_para   = table((1:num_all_bus)',class_names,...
                                real(PQss_para),imag(PQss_para),...
                                abs(Vss_para),angle(Vss_para),...
                                abs(Iss_para),angle(Iss_para),...
                                'VariableNames',{'bus_idx','model','P','Q','Vabs','Vangle','Iabs','Iangle'});

x_idx_name = supporters.for_user.func.look_state_list(net);
equilibrium = array2table(zeros(0,2+numel(x_idx_name)),"VariableNames",[{'bus_idx','model'},x_idx_name]);
for i = find(idx.has_state).'
    x_idx_name_busi = net.a_bus{i}.component.get_state_name;
    x_st = net.a_bus{i}.component.x_equilibrium.';
    non_idx_name_busi = x_idx_name(~ismember(x_idx_name,x_idx_name_busi));
    equilibrium_i = [table(i,class_names(i),'VariableNames',{'bus_idx','model'}),...
                    array2table([x_st,nan(1,numel(non_idx_name_busi))],'VariableNames',[x_idx_name_busi,non_idx_name_busi])];
    equilibrium = vertcat(equilibrium,equilibrium_i);
end
out.x_equilibrium = equilibrium;


branch_field = {'from','to','x','y','tap','phase'};
branch = array2table(zeros(0,1+numel(branch_field)),'VariableNames',[{'type'},branch_field]);
for i = 1:numel(net.a_branch)
    fn = fieldnames(net.a_branch{i}).';
    non_fn = branch_field(~ismember(branch_field,fn));
    lack_ele = array2table(nan(1,numel(non_fn)),'VariableNames',non_fn);
    adata = cell(1,numel(fn));
    for j = 1:numel(fn)
        adata{j} = net.a_branch{i}.(fn{j});
    end
    branch_i = [cell2table([{class(net.a_branch{i})},adata],'VariableNames',[{'type'},fn]),lack_ele];
    branch = vertcat(branch,branch_i);
end
out.branch = branch;
if draw
    disp('ブランチのパラメータ')
    disp(out.branch)
    disp('潮流状態')
    disp(out.flow_para)
    disp('発電機のパラメータ')
    disp(out.gen_para)
    disp('状態の平衡点')
    disp(out.x_equilibrium)
end

end