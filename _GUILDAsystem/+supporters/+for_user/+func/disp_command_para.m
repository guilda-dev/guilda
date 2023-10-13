function disp_command_para(net,type,japan_or_English)
if nargin<3
    japan_or_English = '日本語';
end
disp_ = @(var1,var2) disp_jorE(var1,var2,japan_or_English);
disp(' ')
disp('-------------------------------------------------------------------------------')
switch type
    case 'flow'
        disp_('各母線の潮流状態は，','The power flow of each bus can be referenced as follows.')
        disp_('- 電圧:','- Voltage:')
        disp('>>net.a_bus{i}.component.V_equilibrium')
        disp_('- 電流:','- Current:')
        disp('>>net.a_bus{i}.component.I_equilibrium')
        disp_('で参照することができます．潮流状態での有効電力,無効電力はここから求められます．',...
                'The real and reactive power in power flow conditions can be obtained from this data.')
        disp(' ')
        disp_('以下の様にすることで全母線の潮流状態が配列として参照できます．',...
              'The power flow status of all bus lines can be referenced as an array by doing the following.')
        disp('>>V_equilibrium = tools.vcellfun(@(b) b.V_equilibrium, net.a_bus);')
        disp('>>I_equilibrium = tools.vcellfun(@(b) b.I_equilibrium, net.a_bus);')
        disp('>>PQequilibrium = Vss_para .* conj(Iss_para);')
        disp('>>P_equilibrium = real(PQequilibrium);')
        disp('>>Q_equilibrium = imag(PQequilibrium);')

    case 'equilibrium'
        disp_('状態の平衡点は"net.a_bus{i}.component.x_equilibrium"というフィールドに格納されています．',...
              'The equilibrium point of the state is stored in the field "net.a_bus{i}.component.x_equilibrium"')
        idx = supporters.for_user.func.look_component_type(net);
        idx = find(idx.has_state)';
        disp_(['今回の場合，状態を持った母線(発電機母線など)は[',mat2str(idx),']番目の母線になるので，'],...
              ['In this case, the bus with state (e.g. generator bus) is the [',mat2str(idx),']th bus.'])
        disp_('例えば，',...
             ['So, for example, when you run the following, you can get the ewuilibrium point of bus',num2str(idx(1))])
        disp(' ')
        disp(['>>net.a_bus{',num2str(idx(1)),'}.component.x_equilibrium'])
        disp(mat2str(net.a_bus{idx(1)}.component.x_equilibrium.'))
        disp(' ')
        disp_(['とすると',num2str(idx(1)),'番目の母線に接続された機器の状態の平衡点が得られます.'],' ')
        disp_(['このバスは,',class(net.a_bus{idx(1)}.component),'であるため状態は'],...
              ['This bus is,',class(net.a_bus{idx(1)}.component),' so the state is '])
        para = net.a_bus{idx(1)}.component.get_state_name; disp(para)
        disp_(['です．そのため，',num2str(idx(1)),'番目の母線に接続された機器の状態の平衡点は以下と見ることができます．'],...
             ['Therefore, the equilibrium point of bus',num2str(idx(1)),'can be seen as follows.'])
        disp(array2table(net.a_bus{idx(1)}.component.x_equilibrium.','VariableNames',para))

    case 'gen_para'
        disp_('発電機のパラメータは"net.a_bus{i}.component.parameter"というフィールドに格納されています．',...
              'Generator parameters are stored in the field "net.a_bus{i}.component.parameter".')
        idx = supporters.for_user.func.look_component_type(net);
        idx = find(idx.has_state)';
        disp_(['今回の場合，発電機母線は[',mat2str(idx),']番目の母線になるので，'],...
             ['In this case, the generator bus is the [',mat2str(idx),']th bus.'])
        disp_('例えば，',...
             ['For example, when you run as follows, you can get the parameter of machine which connected to bus',num2str(idx(1))])
        disp(['>>net.a_bus{',num2str(idx(1)),'}.component.parameter'])
        disp(net.a_bus{idx(1)}.component.parameter)
        disp_(['とすると',num2str(idx(1)),'番目の母線に接続された機器のパラメータが得られます.'],' ') 

    case 'branch'
        disp_('ブランチの情報は"net.a_branch"に各ブランチごとの情報がcell配列として格納されています．',...
             'Branch information is stored in "net.a_branch" as a cell array for each branch.')
        disp_('branchには,','There are following two types of branches.')
        disp('- branch_pi_transformer')
        disp('- branch_pi')
        disp_('の２種類があり，各クラスのフィールドの値を整理すると以下のようになります．',...
             'The values of the fields for each branch are organized as follows.')
        data = supporters.for_user.func.look_para(net,false);
        disp(data.branch)

end
disp('-------------------------------------------------------------------------------')
disp(' ')

end

function disp_jorE(var1,var2,japan_or_English)
    switch japan_or_English
        case '日本語'
            disp(var1)
        case 'English'
            disp(var2)
    end
end