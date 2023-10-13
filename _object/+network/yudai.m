function net = yudai()
    fn = fullfile(pwd,'_object','+network','yudai');
    net = network.build(fn);
end