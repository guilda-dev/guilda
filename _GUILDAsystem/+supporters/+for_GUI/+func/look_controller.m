function out = look_controller(net)

Name_con_g = tools.vcellfun(@(b) {class(b)},net.a_controller_global);
Name_con_l = tools.vcellfun(@(b) {class(b)},net.a_controller_local);
Name_con   = [Name_con_g;Name_con_l];

idx_observe_con_g = tools.vcellfun(@(b) {b.index_observe},net.a_controller_global);
idx_observe_con_l = tools.vcellfun(@(b) {b.index_observe},net.a_controller_local);
idx_observe       = [idx_observe_con_g;idx_observe_con_l];

idx_input_con_g = tools.vcellfun(@(b) {b.index_input},net.a_controller_global);
idx_input_con_l = tools.vcellfun(@(b) {b.index_input},net.a_controller_local);
idx_input       = [idx_input_con_g;idx_input_con_l];

out = table(Name_con,idx_input,idx_observe);
end