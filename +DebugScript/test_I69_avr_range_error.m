% I69 AVR の範囲エラー
%
% net.initialize で AVR に必要な出力が [Vap_min, Vap_max] の外にあるとき、
% AVR 自身の ID のエラーになり、値と対処を含む文言が表示されることを確認する。
%
% 実行: runtests("DebugScript.test_I69_avr_range_error")  または  DebugScript.run_all("Features","I69")

%% AVR_ST1 above upper limit
[ME, avr] = initialize_error("avr-ST1", struct(Vap_max=0.1));
check_error(ME, "AVR_ST1", avr.s_tag, "(-Inf, 0.1)")

%% AVR_ST1 below lower limit
[ME, avr] = initialize_error("avr-ST1", struct(Vap_min=10));
check_error(ME, "AVR_ST1", avr.s_tag, "(10, Inf)")

%% AVR_DC1 above upper limit
[ME, avr] = initialize_error("avr-DC1", struct(Vap_max=0.1));
check_error(ME, "AVR_DC1", avr.s_tag, "(-Inf, 0.1)")

%% AVR_DC1 below lower limit
[ME, avr] = initialize_error("avr-DC1", struct(Vap_min=100));
check_error(ME, "AVR_DC1", avr.s_tag, "(100, Inf)")

%% AVR within limits initializes
for s_key = ["avr-ST1", "avr-DC1"]
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    comp.add_local_controller(s_key, parameter=struct(Vap_min=-100, Vap_max=100));
    res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
    assert(res.l_success)
end


function [ME, avr] = initialize_error(s_key, sct_para)
% AVR を付けた系統を initialize し、発生したエラーと AVR を返す
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller(s_key, parameter=sct_para);
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME), "範囲エラーが発生しなかった")
end

function check_error(ME, s_class, s_tag, s_limits)
% エラーの ID と、文言の機器名・上下限・対処を確認する
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:" + s_class + ":InvalidValueRange", "ID が " + DebugScript.helper.msg_id(ME))
    str = string(ME.message);
    assert(~contains(str, "ID specification"), str)
    assert(contains(str, s_class + " '" + s_tag + "'"), str)
    assert(contains(str, s_limits), str)
    assert(contains(str, "Widen Vap_min and Vap_max"), str)
end
