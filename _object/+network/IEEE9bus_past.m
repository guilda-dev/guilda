%% IEEE9bus systrem
% GUILDAの前身となるシミュレータで使用していたモデル
%
% type_generator>> string型:"1axis","classical"のいづれかを指定（デフォルトは1axis）
%

function net = IEEE9bus_past(type_generator)
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    if nargin<1
        net = network.build(fn);
    else
        net = network.build(fn, type_generator);
    end
end