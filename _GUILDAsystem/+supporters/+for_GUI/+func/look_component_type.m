function idx = look_component_type(net)

idx.generator = tools.vcellfun(@(b) contains(class(b.component), 'generator'), net.a_bus);

idx.load = tools.vcellfun(@(b) contains(class(b.component), 'load'), net.a_bus);
                          
idx.non_unit = tools.vcellfun(@(b) contains(class(b.component), 'component_empty'),net.a_bus);

idx.has_state = tools.vcellfun(@(b) b.component.get_nx ~=0 ,net.a_bus);

idx.bus_PV = tools.vcellfun(@(b) isa(b,'bus_PV'),net.a_bus);
idx.bus_PQ = tools.vcellfun(@(b) isa(b,'bus_PQ'),net.a_bus);
idx.bus_slack = tools.vcellfun(@(b) isa(b,'bus_slack'),net.a_bus);
%%コンポーネント名ごとのインデックスを作成
class_names = tools.vcellfun(@(b) {class(b.component)},net.a_bus);
class_names = unique(class_names);
f = @(w) strrep(w,'.','___');
for i = 1:numel(class_names)
    idx.(f(class_names{i})) = tools.vcellfun(@(b) strcmp(class(b.component), class_names{i}), net.a_bus);
end

idx.all_bus = true(numel(net.a_bus),1);

end
