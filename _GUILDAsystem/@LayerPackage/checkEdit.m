function flag = checkEdit(obj)
    flag = false; 
    switch obj.editFlag
        case "initialized"
            flag = true;
        case "editted"
            disp('Edit Log')
            disp(obj.editLog)         
            config.warning(config.lang('このクラスにはいくつかの変更が加えられているため、計算時に一貫性がなくなる可能性があります。',...
                               'Some changes have been done to this class. This may cause them to be inconsistent when set up.'))
        case "unset"
            error(config.lang('初期化メソッドが実行されていません。',...
                             'Initialisation method has not been executed.'))
    end
end