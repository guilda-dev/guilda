%% IEEE9bus systrem
% GUILDAの前身となるシミュレータで使用していたモデル

function net = IEEE9bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end