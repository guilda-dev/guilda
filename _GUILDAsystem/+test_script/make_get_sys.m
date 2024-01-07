function make_get_sys(net)
    name_mat = strcat(net.Tag,'.mat');
    path_mat = fullfile(pwd,'_GUILDAsystem','+test_script','mat');
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
                % prompt = 'Enter new mat name:'; % MATLABのバグで動かない
                % dlgtitle = 'change mat name';
                % fieldsize = [1 50];
                % definput = {'.mat'};
                % name_mat = inputdlg(prompt,dlgtitle,fieldsize,definput); 

                % f = msgbox('Enter a new mat name in the command window'); % MATLABのバグで動かない

                name_mat = input("What is a new mat name?: ","s");
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
    save(fullfile(path_mat, name_mat),'A_past','B_past','C_past','D_past');
end