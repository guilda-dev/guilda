% I69 AVR の範囲エラー
%
% net.initialize で AVR に必要な出力が [Vap_min, Vap_max] の外にあるとき、
% AVR 自身の ID のエラーになり、値と対処を含む文言が表示されることを確認する。
%
% 実行: runtests("DebugScript.test_I69_avr_range_error")  または  DebugScript.run_all("Features","I69")

%% AVR_ST1 above upper limit
ME = initialize_error(controller.avr.AVR_ST1("avr1", Vap_max=0.1));
check_error(ME, "AVR_ST1", "CAavr1", "(-Inf, 0.1)")

%% AVR_ST1 below lower limit
ME = initialize_error(controller.avr.AVR_ST1("avr1", Vap_min=10));
check_error(ME, "AVR_ST1", "CAavr1", "(10, Inf)")

%% AVR_DC1 above upper limit
ME = initialize_error(controller.avr.AVR_DC1("avr1", Vap_max=0.1));
check_error(ME, "AVR_DC1", "CAavr1", "(-Inf, 0.1)")

%% AVR_DC1 below lower limit
ME = initialize_error(controller.avr.AVR_DC1("avr1", Vap_min=100));
check_error(ME, "AVR_DC1", "CAavr1", "(100, Inf)")

%% AVR within limits initializes
for avr = {controller.avr.AVR_ST1("avr1", Vap_min=-100, Vap_max=100), controller.avr.AVR_DC1("avr1", Vap_min=-100, Vap_max=100)}
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    comp.add_local_controller(avr{1});
    res = DebugScript.helper.quiet(@() net.initialize);
    assert(res.l_success)
end


function ME = initialize_error(avr)
% AVR を付けた系統を initialize し、発生したエラーを返す
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    comp.add_local_controller(avr);
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME), "範囲エラーが発生しなかった")
end

function check_error(ME, str_class, str_tag, str_limits)
% エラーの ID と、文言の機器名・上下限・対処を確認する
    assert(ME.identifier == "GUILDA:" + str_class + ":InvalidValueRange", "ID が " + ME.identifier)
    str = string(ME.message);
    assert(~contains(str, "ID specification"), str)
    assert(contains(str, str_class + " '" + str_tag + "'"), str)
    assert(contains(str, str_limits), str)
    assert(contains(str, "Widen Vap_min and Vap_max"), str)
end
