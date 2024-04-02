%%% 入力/地絡応答の一致を確認するためのテストスクリプト
%%% 使い方の例：
%%%     net = network.IEEE68bus;
%%%     test_script.test_simulate(net, name_mat, is_perfect, tol);
%%% name_mat: 比較するmatファイル, is_perfect:　完全一致か否か, tol: 完全一致でないときの許容誤差

function [is_match, is_match_input, is_match_fault] = test_simulate(net, name_mat, is_perfect, tol)
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
    path_mat = fullfile(pwd,'_GUILDA','_GUILDAsystem','+test_script','mat');
    
    if ~exist(fullfile(path_mat, name_mat),'file')
        error(strcat("Test data doesn't exist (mat name: ", name_mat, ")"));
    end

    load(fullfile(path_mat, name_mat), 'setting', 'out');

    out_input = net.simulate(setting.time, setting.uidx, setting.u, 'sampling_time', setting.sampling_time);
    out_fault = net.simulate(setting.time, 'fault', setting.fault, 'sampling_time', setting.sampling_time);
    
    is_match_input = check_match(out.input, out_input, is_perfect, tol);
    is_match_fault = check_match(out.fault, out_fault, is_perfect, tol);
    is_match = is_match_input && is_match_fault;
end

function is_match = check_match(out_old, out_new, is_perfect, tol)
    is_match_X = check_match_(out_old.X, out_new.X, is_perfect, tol);
    is_match_V = check_match_(out_old.V, out_new.V, is_perfect, tol);
    is_match_I = check_match_(out_old.I, out_new.I, is_perfect, tol);
    is_match = is_match_X && is_match_V && is_match_I;
end

function is_match_ = check_match_(out_old_, out_new_, is_perfect, tol)
    a_is_match_ = zeros(numel(out_old_), 1);
    for ii = 1:numel(out_old_)
        if isempty(out_old_{ii}) && isempty(out_new_{ii})
            a_is_match_(ii) = 1;
        else
            out_old = table2array(out_old_{ii});
            out_new = table2array(out_new_{ii});
            out_diff = out_new - out_old;
            if is_perfect
                a_is_match_(ii) = all(all(out_diff==0));
            else
                a_is_match_(ii) = all(all(abs(out_diff)<tol));
            end
        end
    end
    is_match_ = all(a_is_match_);
end