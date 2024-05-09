classdef Edit_Monitoring < handle
    
    properties(SetAccess=protected)
        index
    end
    
    properties(Access=protected)
        children = {};
        parents  = {};
    end
    
    properties(SetAccess=protected)
        Edit_Log = [];
    end

    methods
        function editted(obj,Tag,Tab)
            if nargin<2
                Tag = '';
            end
            if nargin < 3
                clslist = {'bus','branch','component','controller'};
                clsidx = find(tools.hcellfun(@(c) isa(obj,c), clslist));
                if isempty(clsidx)
                    cls = string(class(obj));
                else
                    cls = string(clslist{clsidx}); 
                end
                idx = obj.index;
                if isempty(idx); idx=nan; end
                Tag = string(Tag);
                Tab = table(cls,idx,Tag);
            end
            obj.Edit_Log = [obj.Edit_Log; Tab];
            try
                cellfun(@(p) p.editted([],Tab), obj.parents);
            catch
            end
        end

        function reflected(obj)
            obj.Edit_Log = [];
            try
                cellfun(@(c) c.reflected, obj.children);
            catch
            end
        end

        function register_index(obj,index)
            obj.index = index;
            cellfun(@(c) c.register_index(index), obj.children);
        end

        function register_parent(obj,varargin)
            obj.set_NewElements('parents',varargin{:})
        end

        function register_child(obj,varargin)
            obj.set_NewElements('children',varargin{:})
        end
    end

    methods(Access = private)
        function set_NewElements(obj,type,data,mode)
            arguments
                obj 
                type 
                data = []; 
                mode = 'stack';
            end
            if isempty(data)
                return
            end

            if iscell(data)
                data = data(:)';
            else
                data = {data};
            end

            if ~all(tools.hcellfun(@(d) isa(d,'base_class.Edit_Monitoring'), data))
                error('The element to be registered must be of "base_class.Edit_Monitoring" class.')
            end

            switch mode
                case 'stack'
                    obj.(type) = [obj.(type),data];
                case 'overwrite'
                    obj.(type) = data;
            end
        end
    end
end