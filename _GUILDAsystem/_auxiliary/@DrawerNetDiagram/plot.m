function plot(obj, cv_V, ax)
arguments
    obj
    cv_V (:,1) double
    ax (1,1) matlab.graphics.axis.Axes = axes('Parent', figure("Position", [100, 100, 800, 600]))
end
    obj.ax = ax;
    obj.set_V(cv_V);
end
