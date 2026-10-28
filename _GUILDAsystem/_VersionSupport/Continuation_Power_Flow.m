function obj = Continuation_Power_Flow(net,opt)
    opt = namedargs2cell(opt);
    obj = ContinuationPowerFlow(net,opt{:});
end