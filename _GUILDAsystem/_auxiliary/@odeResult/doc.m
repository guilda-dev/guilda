function doc(obj)
    
    fprintf(['\n' ...
    '==================================\n',...
    '    シミュレーション結果の解析ツール   \n',...
    '        DataProcessingクラス       \n',...
    '==================================\n\n'])
    help(class(obj))
    
    disp('応答プロットを表示したい場合')
    disp('------------------------')
    
    disp('● UIを使う場合')
    help([class(obj),'.UIplot'])
    
    disp('● コマンドで実行する場合')
    myhref(obj,'[引数の指定方法]','コマンドでプロットの実行をする場合','plot')

    disp('アニメーションを表示したい場合')
    disp('-------------------------')
    disp('*グラフプロット作成のためpower_networkクラスを引数として要求します')
    
    disp('● UIを使う場合')
    help([class(obj),'.UIanime'])
    
    disp('● コマンドで実行する場合')
    myhref(obj,'[引数の指定方法]','コマンドでプロットの実行をする場合','anime')
    

    disp('シミュレーションの条件設定を表示する場合')
    disp('---------------------------------')
    help([class(obj),'.simulation_condition'])
    fprintf('\n')


    disp('応答結果をcsvファイルとして出力する場合')
    disp('---------------------------------')
    help([class(obj),'.export_csv'])
    fprintf('\n' )

    function myhref(obj,ref,sentence,method)
        disp('ー実行方法ー')
        disp([' >> obj.',method,'();'])
        fprintf([' >> obj.',method,'(Name,Value,...)'])
        fprintf([' <a href="matlab:' ,...
                'disp('' '');',...
                'disp([''',sentence,''']);',...
                'disp(''==================================================='');',...
                'help([''',class(obj),''',''.',method,''']);',...
                'disp(''==================================================='');',...
                'disp('' '');',...
                '">',ref,'</a>\n\n'])
        disp(' ')
    end
    
end