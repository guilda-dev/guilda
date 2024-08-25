%% IEEE68bus systrem
% GUILDAの前身となるシミュレータで使用していたモデル

function net = IEEE68bus_book()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end