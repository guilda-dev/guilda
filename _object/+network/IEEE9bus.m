function net = IEEE9bus()
    fn = fullfile(pwd,'_GUILDA','_object','+network','IEEE9bus');
    net = network.build(fn);
end