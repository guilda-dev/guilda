function set_equilibrium(obj, V, I)

for i = 1:numel(obj.a_bus)
   obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
end

end


