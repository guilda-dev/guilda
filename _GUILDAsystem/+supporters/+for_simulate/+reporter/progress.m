classdef progress < handle

    properties(SetAccess=protected)
        mode
        OutputFcn
    end

    properties(Dependent,Access=protected)
        tlim
    end

    properties(Access=protected)
        parent
        simulating

        dialog
        
        last_warn

        percent
        sampling_period;
        last_time;
    end
    
    methods
        function obj = progress(parent, mode)
            obj.mode = mode;
            obj.parent = parent;
            
            obj.simulating = false;
            obj.last_time  = obj.tlim(1);
            obj.sampling_period = ( obj.tlim(end) - obj.tlim(1) )/100;
        end

        function out = get.tlim(obj)
            out = obj.parent.time;
        end

        function set_OutputFcn(obj)
            switch obj.mode
                case 'dialog'
                    obj.OutputFcn = @obj.Fcn_dialog;
                case 'disp'
                    obj.OutputFcn = @obj.Fcn_disp;
                case 'none'
                    obj.OutputFcn = @(t,y,flag) false;
            end
        end

        function f = Fcn_dialog(obj,t,~,flag)
            f = false;
            if strcmp(flag, 'done') 
                if obj.percent == 1
                    delete(obj.dialog)
                end
                return
            elseif ~obj.simulating && strcmp(flag, 'init')
                obj.dialog = waitbar(0,'','Name','Simulation in progress...');
                obj.simulating = true;

            else
                if ~isgraphics(obj.dialog)
                    obj.parent.ToBestop = true;
                    delete(obj.dialog)
                    return
                end
                if numel(t)==1
                    if (t-obj.last_time) >= obj.sampling_period || t == obj.tlim(end)
                        obj.last_time = t;
                        obj.percent = (t-obj.tlim(1))/(obj.tlim(end)-obj.tlim(1));
                        waitbar(obj.percent,obj.dialog,sprintf('Time: %0.2f(s) / %0.2f(s)',t,obj.tlim(end)))
                    end
                end
            end

        end

        function f = Fcn_disp(obj,t,~,flag)
            f = false;
            if strcmp(flag, 'done')
                return
            elseif ~obj.simulating && strcmp(flag, 'init')
                fprintf('\n Simulation Start !!\n')
                obj.disp_init
            else
                [~,wid] = lastwarn;
                if ~strcmp(obj.last_warn,wid)
                    obj.disp_init
                end
                per = floor( (t-obj.tlim(1))/(obj.tlim(end)-obj.tlim(1))*100 );
                if per > obj.percent
                    if per == 100
                        fprintf(repmat('>',[1,max(per-obj.percent,0)]))
                        disp('|')
                    else
                        fprintf(repmat('>',[1,per-obj.percent]))
                        obj.percent = per;
                    end
                end
            end
        end
        
        
        function disp_init(obj)
            disp(' ')
            t0 = [num2str( obj.tlim(1)  ),'s'];
            te = [num2str( obj.tlim(end)),'s'];
            nw = numel(t0) + numel(te);
            disp([t0,repmat(' ',[1,101-nw]),te])
            disp(['|',repmat(' ',[1,13-nw]),tools.harrayfun(@(i)[num2str(i),'%       '],10:10:90),' |'])
            disp(['|',repmat('-',[1,9]),repmat('o---------',[1,9]),'|'])
            fprintf('|')
            
            obj.simulating = true;
            obj.percent    = 1;
            [~,obj.last_warn] = lastwarn;
        end

    end
end