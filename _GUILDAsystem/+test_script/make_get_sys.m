%%% 線形化モデルの一致を確認するためのテストデータ作成スクリプト
%%% 使い方の例：
%%%     net = network.IEEE68bus;
%%%     test_script.make_get_sys(net);

function make_get_sys(net, name_mat)
    if nargin<2
        name_mat = strcat('get_sys_', net.Tag, '.mat');
    end

    path_mat = fullfile(pwd,'_GUILDA','_GUILDAsystem','+test_script','mat');
    if ~exist(path_mat,'dir')
        mkdir(path_mat);
    end
    
    if exist(fullfile(path_mat, name_mat), 'file')
        answer = questdlg(['Test data already exists. Do you want to update the test data?', ...
                            'If you want to change mat name, type a new mat name in the command window.'], ...
	                        'Do you want to update?', ...
	                        'Yes','No','Change mat name','No');

        switch answer
            case 'Yes'
            case 'No'
                return
            case 'Change mat name'
                prompt = 'Enter new mat name:';
                dlgtitle = 'change mat name';
                fieldsize = [1 50];
                definput = {'get_sys_.mat'};
                name_mat = inputdlg(prompt,dlgtitle,fieldsize,definput);
        end
        if ~contains(name_mat, '.mat')
            name_mat = strcat(name_mat, '.mat');
        end
    end

    sys = net.get_sys();
    A_past = sys.A;
    B_past = sys.B;
    C_past = sys.C;
    D_past = sys.D;
    
    if iscell(name_mat)
        name_mat = name_mat{:};
    end
    save(fullfile(path_mat, name_mat),'A_past','B_past','C_past','D_past');
end