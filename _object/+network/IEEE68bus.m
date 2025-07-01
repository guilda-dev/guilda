%% IEEE68bus systrem
% Robust Control in Power Systems
% p.171~178

function net = IEEE68bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end