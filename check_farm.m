clc

t = struct;
t.nofarm = out_no_farm.out_data.t;
t.solar1 = out_solar1.out_data.t;
%t.solar2 = out_solar2.out_data.t;
t.solar3 = out_solar3.out_data.t;
t.wind1 = out_wind1.out_data.t;
t.wind2 = out_wind2.out_data.t;
t.wind3 = out_wind3.out_data.t;
%t.PLL045 = out_solar3_PLL_045.out_data.t;
%t.PLL500 = out_solar3_PLL_500.out_data.t;
%t.PLL1000 = out_solar3_PLL_1000.out_data.t;

t = struct2cell(t);

%% 1つの母線に注目して電圧を比較
%{
bus = 7;
value = "abs";

val = struct;
eq  = struct;

if value == "abs"
    val.nofarm = out_no_farm.out_data.V{bus}{:, value};
    val.solar1 = out_solar1.out_data.V{bus}{:, value};
    val.solar2 = out_solar2.out_data.V{bus}{:, value};
    val.solar3 = out_solar3.out_data.V{bus}{:, value};
    val.wind1 = out_wind1.out_data.V{bus}{:, value};
    val.wind2 = out_wind2.out_data.V{bus}{:, value};
    val.wind3 = out_wind3.out_data.V{bus}{:, value};

    eq.nofarm = table2array(out_no_farm.net_data.bus(bus, "Vabs"));
    eq.solar1 = table2array(out_solar1.net_data.bus(bus, "Vabs"));
    eq.solar2 = table2array(out_solar2.net_data.bus(bus, "Vabs"));
    eq.solar3 = table2array(out_solar3.net_data.bus(bus, "Vabs"));
    eq.wind1 = table2array(out_wind1.net_data.bus(bus, "Vabs"));
    eq.wind2 = table2array(out_wind2.net_data.bus(bus, "Vabs"));
    eq.wind3 = table2array(out_wind3.net_data.bus(bus, "Vabs"));
elseif value == "angle"
    val.nofarm = out_no_farm.out_data.V{bus}{:, value};
    val.solar1 = out_solar1.out_data.V{bus}{:, value};
    val.solar2 = out_solar2.out_data.V{bus}{:, value};
    val.solar3 = out_solar3.out_data.V{bus}{:, value};
    val.wind1 = out_wind1.out_data.V{bus}{:, value};
    val.wind2 = out_wind2.out_data.V{bus}{:, value};
    val.wind3 = out_wind3.out_data.V{bus}{:, value};

    eq.nofarm = table2array(out_no_farm.net_data.bus(bus, "Varg"));
    eq.solar1 = table2array(out_solar1.net_data.bus(bus, "Varg"));
    eq.solar2 = table2array(out_solar2.net_data.bus(bus, "Varg"));
    eq.solar3 = table2array(out_solar3.net_data.bus(bus, "Varg"));
    eq.wind1 = table2array(out_wind1.net_data.bus(bus, "Varg"));
    eq.wind2 = table2array(out_wind2.net_data.bus(bus, "Varg"));
    eq.wind3 = table2array(out_wind3.net_data.bus(bus, "Varg"));
else
    disp("エラー")
end

t = struct2cell(t);
val = struct2cell(val);
eq = struct2cell(eq);

for i = 1:7

    val{i} = (val{i} - eq{i})/eq{i};
    plot(t{i}, val{i}, 'LineWidth',2)
    hold on
end

legend("nofarm", "solar1", "solar2", "solar3", "wind1", "wind2", "wind3")
%}

%% 他の同期発電機のΔωの平均をとる
X = struct;

X.nofarm = out_no_farm.out_data.X;
X.solar1 = out_solar1.out_data.X;
%X.solar2 = out_solar2.out_data.X;
X.solar3 = out_solar3.out_data.X;
X.wind1 = out_wind1.out_data.X;
X.wind2 = out_wind2.out_data.X;
X.wind3 = out_wind3.out_data.X;

X = struct2cell(X);

for i = 1:6
    sum = zeros(numel(t{i}, 1));
    for idx = [1,2,3,6,8,9,10,11,12,13,14,15,16]
        sum = sum + (X{i}{idx}{:,'omega'}.^2);
    end

    plot(t{i}, sqrt(sum), 'LineWidth',2);
    hold on
end
legend("nofarm", "solar1", "solar3", "wind1", "wind2", "wind3")


%% PLLの場合
%{
X = struct;

X.noPLL = out_solar3.out_data.X;
X.PLL045 = out_solar3_PLL_045.out_data.X;
X.PLL500 = out_solar3_PLL_500.out_data.X;
X.PLL1000 = out_solar3_PLL_1000.out_data.X;

X = struct2cell(X);

for i = 1:4
    sum = zeros(numel(t{i}, 1));
    for idx = [1,2,3,6,8,9,10,11,12,13,14,15,16]
        sum = sum + (X{i}{idx}{:,'omega'}.^2);
    end

    plot(t{i}, sqrt(sum), 'LineWidth',2);
    hold on
end
legend("noPLL", "K_p=0.45", "K_p=5.00", "K_p=10")
%}