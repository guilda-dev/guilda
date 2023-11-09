function set_last_time(obj,t)
    % タームの更新ごとに最終時刻を更新　>> fault,input,parallelのset.current_timeメソッドを実行し条件設定を更新
    obj.fault.current_time    = t;
    obj.input.current_time    = t;
    obj.parallel.current_time = t;
end
