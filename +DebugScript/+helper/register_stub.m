function c = register_stub(sv_stub, sv_class, opt)
% テスト用のスタブを GUILDA のモデルとして一時的に登録し、片付け用の onCleanup を返す
%
%   c = DebugScript.helper.register_stub("ObserveStub", "controller.test_observe_avr", ...
%           Replace=["s_role = ""local""", "s_role = ""avr"""]);
%   con = gen.add_local_controller("test-observe-avr", parameter=struct(Input="Vfield"));
%
% +DebugScript のクラスとその子は GUILDA.dictionary に載らないため、add_component や
% add_local_controller のキーにならない。スタブ DebugScript.helper.<sv_stub> の写しを
% _GUILDAobject の sv_class (パッケージ名つき) に書き、GUILDA を実行してキーの一覧を作り直す。
% 返した onCleanup が消えるとき (テストが失敗したときも) 写しを消して GUILDA を実行し直す。
%
% 写しでは、クラス名・コンストラクタ名・DebugScript.helper.<sv_stub> を新しい名前に、最初の
% key = "..." を新しいクラス名 ("_" を "-" に。例: test-observe-avr) に置き換える。
% Replace (n x 2 の [前, 後]) と Regexp (n x 2 の [式, 置換]) はその前に、すべての写しに適用する。
    arguments (Input)
        sv_stub   (1,:) string  % DebugScript.helper のスタブのクラス名
        sv_class  (1,:) string  % 登録するクラス名 (パッケージ名つき。sv_stub と同じ数)
        opt.Replace (:,2) string = strings(0,2)  % 写しに適用する文字列の置き換え [前, 後]
        opt.Regexp  (:,2) string = strings(0,2)  % 写しに適用する正規表現の置き換え [式, 置換]
    end
    arguments (Output)
        c  % 消えるときに登録を取り消す onCleanup
    end
    s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    sv_file = strings(size(sv_stub));
    for k = 1:numel(sv_stub)
        sv_part    = split(sv_class(k), ".");
        sv_file(k) = fullfile(s_root, "_GUILDAobject", join("+" + sv_part(1:end-1), filesep), sv_part(end) + ".m");
    end
    c = onCleanup(@() unregister(sv_file));   % 途中で失敗しても書いた写しを消す
    for k = 1:numel(sv_stub)
        sv_part = split(sv_class(k), ".");
        s_name  = sv_part(end);
        str = string(fileread(which("DebugScript.helper." + sv_stub(k))));
        for i = 1:size(opt.Replace, 1)
            str = replace(str, opt.Replace(i,1), opt.Replace(i,2));
        end
        for i = 1:size(opt.Regexp, 1)
            str = regexprep(str, opt.Regexp(i,1), opt.Regexp(i,2));
        end
        % キーは登録するクラス名 ("_" を "-" に)。Constant の key = "..." を持つスタブに限る
        str = regexprep(str, '(\n\s+key\s*=\s*)"[^"]*"', "$1""" + replace(s_name, "_", "-") + """", "once");
        str = replace(str, "DebugScript.helper." + sv_stub(k), sv_class(k));
        str = replace(str, "classdef " + sv_stub(k), "classdef " + s_name);
        str = replace(str, "function obj = " + sv_stub(k) + "(", "function obj = " + s_name + "(");
        writelines(str, sv_file(k));
    end
    rehash
    evalc("GUILDA;");
end

function unregister(sv_file)
    for k = 1:numel(sv_file)
        if isfile(sv_file(k))
            delete(sv_file(k));
        end
    end
    rehash
    evalc("GUILDA;");
end
