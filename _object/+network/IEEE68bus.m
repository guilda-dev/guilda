%% IEEE68bus systrem
% 電力系統のシステム制御工学
% p.253~255
%
% type_generator>> string型:"1axis","2axis","classical","park"のいづれかを指定（デフォルトは1axis）
%

function net = IEEE68bus(type_generator)
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    if nargin<1
        net = network.build(fn);
    else
        net = network.build(fn, type_generator);
    end
end