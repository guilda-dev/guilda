%% IEEE68bus systrem
% Robust Control in Power Systems
% p.171~178
%
% type_generator>> string型:"1axis","2axis","classical","park"のいづれかを指定（デフォルトは1axis）
%

function net = IEEE68bus_original(type_generator)
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    if nargin<1
        net = network.build(fn);
    else
        net = network.build(fn, type_generator);
    end
end