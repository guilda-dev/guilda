function [comp, c, net] = stub_component(s_stub, parameter)
% テスト用の機器のスタブを登録し、1 母線の系統に add_component で付けて返す
%
%   [comp, c] = DebugScript.helper.stub_component("BadComponentStub", "equilibrium");
%   flag = comp.validate(false);
%
% 機器は add_component と replace_component でしか作れない (具体クラスのコンストラクタは
% Bus からだけ呼べる) ため、スタブ DebugScript.helper.<s_stub> の写しを
% component.load.stub_<小文字の名前> として登録し (DebugScript.helper.register_stub)、
% そのキーで追加する。スタブのコンストラクタは (タグの番号, parameter, 設定) を受け取る。
% 返した c が消えるとき登録を取り消すので、comp を使い終えるまで c を保持する。
    arguments (Input)
        s_stub    (1,1) string  % DebugScript.helper のスタブのクラス名
        parameter = nan         % add_component の parameter (スタブのコンストラクタの第 2 引数)
    end
    arguments (Output)
        comp  % 追加したスタブの機器
        c     % 消えるときに登録を取り消す onCleanup
        net   % 機器を含む 1 母線の系統
    end
    s_class = "component.load.stub_" + lower(s_stub);
    c = DebugScript.helper.register_stub(s_stub, s_class);
    dic = GUILDA.keymap("Component");
    sv_key = keys(dic);
    s_key = sv_key(values(dic) == s_class);    % key を継承するスタブは親のキーのまま
    net = PowerNetwork();
    bus = net.add_bus();
    comp = bus.add_component(s_key, parameter=parameter);
end
