function add_branch(obj,BranchInstance,from,to)
    arguments
        obj 
        BranchInstance (1,1) Branch
        from (1,1) double {mustBeNonnegative,mustBeInteger} = BranchInstance.from;
        to   (1,1) double {mustBeNonnegative,mustBeInteger} = BranchInstance.to;
    end
    assert(all([from,to]~=0), config.lang("接続先の母線番号を指定してください。","specify the bus number."))
    
    BranchInstance.checkParent;
    BranchInstance.belong(obj, numel(obj.Branches)+1 )
    BranchInstance.connect_bus(from,to)
    obj.Branches = [obj.Branches;{BranchInstance}];
    obj.onEdit('add Branch');
end