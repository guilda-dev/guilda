function [is_match, is_match_A, is_match_B, is_match_C, is_match_D] = test_get_sys(net, name_mat)
    if nargin<2
        name_mat = strcat(net.Tag,'.mat');
    end
    if ~contains(name_mat, '.mat')
        name_mat = strcat(name_mat, '.mat');
    end
    path_mat = fullfile(pwd,'_GUILDA','_GUILDAsystem','+test_script','mat');
    
    if ~exist(fullfile(path_mat,name_mat),'file')
        error(strcat("Test data doesn't exist (mat name: ", name_mat, ")"));
    end

    load(fullfile(path_mat, name_mat), 'A_past', 'B_past', 'C_past', 'D_past');

    sys = net.get_sys();
    is_match_A = isequal(sys.A, A_past);
    is_match_B = isequal(sys.B, B_past);
    is_match_C = isequal(sys.C, C_past);
    is_match_D = isequal(sys.D, D_past);
    is_match = is_match_A & is_match_B & is_match_C & is_match_D;
end