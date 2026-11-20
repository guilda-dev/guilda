function net = samplemodel()
% ネットワーククラスの定義
    net = PowerNetwork("TestSystem");

% 新規クラスの定義義
    b = cell(9,1);
    l = cell(9,1);
    c = cell(6,1);

    % Busクラスの定
    b{1} = Bus("BUS001");
    b{2} = Bus("BUS002");
    b{3} = Bus("BUS003");
    b{4} = Bus("BUS004");
    b{5} = Bus("BUS005");
    b{6} = Bus("BUS006");
    b{7} = Bus("BUS007");
    b{8} = Bus("BUS008");
    b{9} = Bus("BUS009");

    cellfun( @(bi) net.add_bus(bi), b)
    
    % Branchクラスの定義

    l{1} = branch.pi_transformer("L14");
    net.add_branch(l{1}, ["BUS001","BUS004"] ) %接続する母線の指定はタグで行う

    l{2} = branch.pi_transformer("L27");
    net.add_branch(l{2}, ["BUS002","BUS007"] )

    l{3} = branch.pi_transformer("L39");
    net.add_branch(l{3}, ["BUS003","BUS009"] )

    l{4} = branch.pi("L45");
    net.add_branch(l{4}, { b(4),b{5} } ) %接続する母線の指定はBusクラスのcell配列でもok

    l{5} = branch.pi("L46");
    net.add_branch(l{5}, { b(4),b{6} } )

    l{6} = branch.pi("L57");
    net.add_branch(l{6}, { b(5),b{7} } )

    l{7} = branch.pi("L69");
    net.add_branch(l{7}, [6,9] ) %接続する母線の指定を数字配列[i,j]で行うとnet.a_Bus([i,j])として補完される

    l{8} = branch.pi("L78");
    net.add_branch(l{8}, [7,8] )

    l{9} = branch.pi("L89");
    net.add_branch(l{9}, [8,9] )

    % Componentクラスの定義
    c{1} = Component("Gen001");
    c{2} = Component("Gen002");
    c{3} = Component("Gen003");
    c{4} = Component("Load004");
    c{5} = Component("Load005");
    c{6} = Component("Load006");

    net.a_Bus{1}.add_component(c{1})
    net.a_Bus{2}.add_component(c{2})
    net.a_Bus{3}.add_component(c{3})
    net.a_Bus{5}.add_component(c{4})
    net.a_Bus{6}.add_component(c{5})
    net.a_Bus{8}.add_component(c{6})
end