function out = generator_2axis(omega,parameter)
    f = parameter.Properties.VariableNames;
    if ismember('T',f) || ~ismember('Tdo',f)
        parameter.Properties.VariableNames(strcmp(f,'T')) = {'Tdo'};
    end
    out = component.generator.two_axis(parameter);
end