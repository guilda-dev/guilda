function [is_match, is_match_A, is_match_B, is_match_C, is_match_D] = test_get_sys(net, name_mat, is_perfect, tol)
    if nargin<4 || isempty(tol)
        tol = 1e-10;
    end
    if nargin<3 || isempty(is_perfect)
        is_perfect = true;
    end
    if nargin<2 || isempty(name_mat)
        name_mat = strcat(net.Tag, '.mat');
    end
    if ~contains(name_mat, '.mat')
        name_mat = strcat(name_mat, '.mat');
    end
    path_mat = fullfile(pwd,'_GUILDAsystem','+test_script','mat');
    
    if ~exist(fullfile(path_mat,name_mat),'file')
        error(strcat("Test data doesn't exist (mat name: ", name_mat, ")"));
    end

    load(fullfile(path_mat, name_mat), 'A_past', 'B_past', 'C_past', 'D_past');

    sys = net.get_sys();
    if is_perfect
        is_match_A = isequal(sys.A, A_past);
        is_match_B = isequal(sys.B, B_past);
        is_match_C = isequal(sys.C, C_past);
        is_match_D = isequal(sys.D, D_past);
    else
        is_match_A = all(all((A_past-sys.A)<tol));
        is_match_B = all(all((B_past-sys.B)<tol));
        is_match_C = all(all((C_past-sys.C)<tol));
        is_match_D = all(all((D_past-sys.D)<tol));
    end
    is_match = is_match_A & is_match_B & is_match_C & is_match_D;
end