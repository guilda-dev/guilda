%% IEEE9bus systrem
% Power System Dynamics and Stability: With Synchrophasor Measurement and Power System Toolbox
% p.142~144

function net = IEEE9bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end