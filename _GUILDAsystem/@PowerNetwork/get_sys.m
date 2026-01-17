function sys = get_sys(obj, class_list,target_index)
    arguments
        obj 
        class_list  = {'bus','branch','component'};
        target_index       = tools.hcellfun(@(b) b.index, obj.a_bus);
    end

    % =====>> 旧verの仕様に合わせるための実装
    if islogical(class_list) && index
        class_list = {'bus','branch','component','controllelr'};
    end
    % <<=====
    
    
    % 対象のクラスがclass_listに含まれているかを判定する関数を作成
    % Make function to detect if the given class is included in the class_list.
    isTarget = @(cls) any( tools.hcellfun(@(cls_name) isa(cls,clc_name), class_list) );


    % set data format
    bus  = obj.a_bus;
    bra  = obj.a_branch;
    gcon = obj.a_controller_global;
    sys_bus  = cell(1,numel(bus ));
    sys_bra  = cell(1,numel(bra ));
    sys_gcon = zell(1,numel(gcon));


    % extract system_matrix
    for i = target_index
        busi = bus{i};
        if isTarget(busi)
            sys_bus{i} = busi.get_sys(class_list);
        else
            if isTarget(busi.component)
                disp(config.lang("-> 母線"+i+"が除外されたため機器"+i+"も除外されます。",...
                                "-> As bus "+i+" is excluded, equipment "+i+" is also excluded."))
            end
            if any( tools.hcellfun(@(c) isTarget(c), busi.component.a_controller_local) )
                disp(config.lang("-> 母線"+i+"が除外されたため機器"+i+"に接続されたローカル制御器も除外されます。",...
                                "-> As bus "+i+" is excluded, equipment "+i+" is also excluded."))
            end
        end
    end

    for i = 1:numel(bra)
        bri = bra{i};
        i1 = bri.from;
        i2 = bri.to;
        if isTarget(bri) 
            if all(ismember([i1,i2], bus_index_list))
                sys_bra{i} = bri.get_sys(class_list);
            else
                disp(config.lang("-> 送電線"+i1+"-"+i2,"は接続する母線が除外されているため除外されます。",...
                                "-> Branch "+i1+"-"+i2+" are excluded as the bus to be connected is excluded."))
            end
        end
    end

    for i = 1:numel(gcon)
        gconi = gcon{i};
        if isTarget(gconi)
            sys_gcon{i} = gconi.get_sys();
        end
    end

    sys = blkdiag(sys_bra{:},sys_bus{:},sys_gcon{:});
    sys = sstools.feedback(sys);
    sys = sstools.dae2ode(sys);
end  