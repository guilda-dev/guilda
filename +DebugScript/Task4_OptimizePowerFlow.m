% 2-2 最適潮流計算 ( https://www.notion.so/dev-GUILDA-ver-3-12f6b8dd2f7980ef9a17f3dbebd7f30f?source=copy_link )

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