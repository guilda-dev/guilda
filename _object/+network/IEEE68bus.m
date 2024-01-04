function net = IEEE68bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end