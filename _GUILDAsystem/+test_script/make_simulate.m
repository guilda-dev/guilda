%%% 入力/地絡応答の一致を確認するためのテストデータ作成スクリプト
%%% 使い方の例：
%%%     net = network.IEEE68bus;
%%%     test_script.make_simulate(net);

function make_simulate(net, name_mat)
    if nargin<2
        name_mat = strcat('simulate_', net.Tag, '.mat');
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
                prompt = 'Enter new mat name:'; % MATLABのバグで動かない
                dlgtitle = 'change mat name';
                fieldsize = [1 50];
                definput = {'simulate_.mat'};
                name_mat = inputdlg(prompt,dlgtitle,fieldsize,definput);
        end
        if ~contains(name_mat, '.mat')
            name_mat = strcat(name_mat, '.mat');
        end
    end

    setting = struct();
    setting.sampling_time = 0.01;
    setting.time = 0:setting.sampling_time:10;
    setting.u = randn(numel(setting.time),2)*0.001;
    setting.uidx = 1;
    setting.fault = {{[1,1.1], 1}};

    out = struct();
    out_input = net.simulate(setting.time, setting.uidx, setting.u, 'sampling_time', setting.sampling_time);
    out.input = data_transfer(out_input);
    out_fault = net.simulate(setting.time, 'fault', setting.fault, 'sampling_time', setting.sampling_time);
    out.fault = data_transfer(out_fault);

    if iscell(name_mat)
        name_mat = name_mat{:};
    end
    save(fullfile(path_mat, name_mat),'setting','out');
end

function data_out = data_transfer(data_in)
    data_out = struct();
    data_out.X = data_in.X;
    data_out.V = data_in.V;
    data_out.I = data_in.I;
end