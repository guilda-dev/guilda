%% IEEE68bus systrem
% 電力系統のシステム制御工学
% p.253~255

function net = IEEE68bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end