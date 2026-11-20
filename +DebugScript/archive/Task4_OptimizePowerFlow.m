% 4 最適潮流計算

disp("under developping...")
return

% netを作成
DebugScript.Task1_3_LayerStructure;


% % 最適潮流計算
% 
% disp(" ")
% disp(" ")
% disp("ELD OPF")
% disp("===================================")
% result_ELD = net.optimize_power_flow("method","ELD");
% disp("===================================")
% disp(" ")
% disp(" ")
% 
% 
% disp("DC OPF")
% disp("===================================")
% result_DC = net.optimize_power_flow("method","DC");
% disp("===================================")
% disp(" ")
% disp(" ")
% 
% % なんか警告がたくさん出るから一旦警告を表示する
% warning off
% disp("AC OPF")
% disp("===================================")
result_AC = net.optimize_power_flow("method","AC");
% [dataSheet, LMP, Cost] = net.get_LMP("method","AC");
disp("===================================")
warning on