%% IEEE9bus systrem
% Power System Dynamics and Stability: With Synchrophasor Measurement and Power System Toolbox
% p.142~144
%
% type_generator>> string型:"1axis","2axis","classical"のいづれかを指定（デフォルトは1axis）
%

function net = IEEE9bus(type_generator)
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    if nargin<1
        net = network.build(fn);
    else
        net = network.build(fn, type_generator);
    end
end