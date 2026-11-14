function flag = validate(obj)
    arguments (Input)
        obj
    end
    arguments (Output)
        flag (1,1) logical % True when there is nothing to draw on.
    end
    flag = isempty(obj.sct_plt) || ~isgraphics(obj.ax);
end
