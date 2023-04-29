classdef handleCopyable < matlab.mixin.Copyable

    properties
        Tag
    end

    properties(Access=protected)
        path
        domain
    end

    properties(Access=private)
        log_stash = struct('warnlog',{'test'},'objlog',struct('origin',[],'copy',[]));
        log_handleCopy = struct('warnlog',{'test'},'objlog',struct('origin',[],'copy',[]));
    end

    methods
        function obj = handleCopyable()
            c = class(obj);
            obj.Tag  = c;
            obj.path = c;

            idx = find(c=='.');
            obj.domain = tools.arrayfun(@(i) strrep(c(i:end),'.','_'),[0,idx]+1);

            if contains(c,'.base')
                c = strrep(c,'.base','');
                idx = find(c=='.');
                obj.domain = [obj.domain,tools.arrayfun(@(i) strrep(c(i:end),'.','_'),[0,idx]+1)];
            end
        end

        function [domain, path] = get_path(obj)
            domain  = obj.domain;
            path    = obj.path;
        end
        
        function preview_copylog(obj)
            obj.log_handleCopy.warnlog
            if iscell(obj.log_handleCopy.warnlog)
                cellfun(@(msg) disp(msg), obj.log_handleCopy.warnlog);
            end
            obj.log_stash.warnlog
            if iscell(obj.log_stash.warnlog)
                cellfun(@(msg) disp(msg), obj.log_stash.warnlog);
            end
        end
    end

    methods (Access = protected)

        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
   
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end

        function cp = copyElement(obj)
            cp = copyElement@matlab.mixin.Copyable(obj);
            props = properties(obj);
            for k = 1:length(props)
                info = findprop(obj,props{k});
                if ~info.Dependent
                    try 
                        propi = obj.PropEditor_Get(props{k});
                    catch
                        obj.fwarning(obj,props{k},'GetAccess');
                        break
                    end
                    [clone,ishandle] = obj.propcopy(propi);
                    try
                        cp.PropEditor_Set(props{k},clone);
                    catch
                        if ishandle
                            obj.fwarning(obj,props{k},'SetAccess');
                        end
                    end
                end
            end
            obj.log_handleCopy = obj.log_stash;
            obj.reset_log;
        end
    end

    methods (Access = private)

        function reset_log(obj)
            obj.log_stash = struct('warnlog',{'test'},'objlog',struct('origin',[],'copy',[]));
        end

        function reset_logall(obj)
            obj.reset_log;
            obj.log_handleCopy = struct('warnlog',{'test'},'objlog',struct('origin',[],'copy',[]));
        end

        function [val,ishandle] = propcopy(obj,val)
            ishandle = false;
            if isa(val,'handle')
                check = cellfun(@(h) h==val, {obj.log_stash.objlog.origin},'UniformOutput',false);
                check = vertcat(check{:});
                if any(check)
                    val = obj.log_stash.objlog(check).copy;
                    ishandle = true;
                    return
                elseif any(cellfun(@(c) contains(c,'handleCopyable'),superclasses(val)))
                    val.log_stash = obj.log_stash;
                    clone = val.copyElement;
                    obj.log_stash = val.log_handleCopy;
                    val.reset_logall;
                    clone.reset_logall;
                    ishandle = true;
                elseif isa(val,'matlab.mixin.Copyable')
                    clone = val.copyElement;
                    obj.fwarning(val,[],'mixin');
                    ishandle = true;
                else
                    clone = val;
                    obj.fwarning(val,[],'handle');
                    ishandle = true;
                end
                log.origin = val;
                log.copy = clone;
                obj.log_stash.objlog = [obj.log_stash.objlog ; log];
                val = clone;
            else
                if isa(val,'cell')
                    for i = 1:numel(val)
                        [val{i},flag] = obj.propcopy(val{i});
                        ishandle = ishandle || flag;
                    end
                elseif isa(val,'struct')
                    for i = 1:length(val)
                        f = fieldnames(val(i));
                        for j = 1:length(f)
                            [val(i).(f{j}),flag] = obj.propcopy(val(i).(f{j}));
                            ishandle = ishandle || flag;
                        end
                    end
                elseif isa(val,'tabular')
                    s = size(val);
                    for r = 1:s(1)
                    for v = 1:s(2)
                        [val{r,v},flag] = obj.propcopy(val{r,v});
                        ishandle = ishandle || flag;
                    end
                    end
                elseif isa(val,'dictionary')
                    key = val.keys;
                    for i = 1:length(key)
                        [val(key(i)),flag] = obj.propcopy(val(key(i)));
                        ishandle = ishandle || flag;
                    end
                end
            end
        end

        function obj = fwarning(obj,cl,prop,mode)
            switch mode
                case 'handle'
                    msg = ['This class is a handle that does not support value passing     @',class(cl)];
                case 'mixin'
                    msg = ['If this class has a handle property, it is passed by reference @',class(cl)];
                case 'SetAccess'
                    msg = ['This property does not have SetAccess permission               @',class(cl),' > property "',prop,'"'];
                case 'GetAccess'
                    msg = ['This property does not have GetAccess permission               @',class(cl),' > property "',prop,'"'];
            end
            if ~any(strcmp(obj.log_stash.warnlog, msg))
                warn = warning;
                warning('off','backtrace')
                warning(msg)
                warning(warn)
                obj.log_stash.warnlog = [obj.log_stash.warnlog,{msg}];
            end
        end
   end
end
