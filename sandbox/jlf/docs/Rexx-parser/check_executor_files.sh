#!/bin/bash

incubator=/local/rexx/oorexx/executor/incubator
executor=/local/rexx/oorexx/executor/sandbox/jlf

ABORT=1


# According 'man echo', echo can return >0 if an error occurs.
# I want to ignore this error.
display()
{
    echo "$1"
    true
}

abort()
{
    [[ $ABORT -eq 1 ]] && display "ABORTING" && kill -SIGINT $$
}

validate_argument_EXPECTED_EXIT_STATUS()
{
    case "$EXPECTED_EXIT_STATUS" in
        "error")
            ;;
        "noerror")
            ;;
        *)
            echo "Invalid expected result. Got '$1', expected 'error' or 'noerror'."
            abort;;
    esac
}

check_exit_status()
{
    [[ $EXPECTED_EXIT_STATUS = "error" ]]   && [[ $EXIT_STATUS -ne 0 ]] && display "OK: Expected an error (exit_status = $EXIT_STATUS)" && return
    [[ $EXPECTED_EXIT_STATUS = "error" ]]   && [[ $EXIT_STATUS -eq 0 ]] && display "KO: Expected an error (exit_status = $EXIT_STATUS)" && abort
    [[ $EXPECTED_EXIT_STATUS = "noerror" ]] && [[ $EXIT_STATUS -eq 0 ]] && display "OK: Expected no error (exit_status = $EXIT_STATUS)" && return
    [[ $EXPECTED_EXIT_STATUS = "noerror" ]] && [[ $EXIT_STATUS -ne 0 ]] && display "KO: Expected no error (exit_status = $EXIT_STATUS)" && abort
}

check()
{
    local EXPECTED_EXIT_STATUS=$1
    validate_argument_EXPECTED_EXIT_STATUS

    local FILE=$2

    echo "----------------------------------------"

    echo "$FILE"
    rexx rxcheck -xtr "$FILE"
    EXIT_STATUS=$?

    check_exit_status
}

check noerror $incubator/DocMusings/transformxml/myxmlparser.cls
check noerror $incubator/DocMusings/transformxml/sd2image.rex
check noerror $incubator/DocMusings/transformxml/sdbnfizer.cls
check noerror $incubator/DocMusings/transformxml/sdparser.cls
check noerror $incubator/DocMusings/transformxml/sdtokenizer.cls
check noerror $incubator/DocMusings/transformxml/sdxmlizer.cls
check noerror $incubator/DocMusings/transformxml/transformdir.rex
check noerror $incubator/DocMusings/transformxml/transformfile.rex

check noerror $executor/unicode/scripts/test_convert.rex
check   error $executor/unicode/scripts/dump_encoded.rex
check noerror $executor/unicode/scripts/test_replacement_characters.rex
check noerror $executor/unicode/scripts/list_invalid_utf8.rex
check   error $executor/unicode/scripts/test_encoding_combinations.rex
check   error $executor/unicode/scripts/check_encoding.rex
check noerror $executor/unicode/ooRexx/oodtree.rex
check   error "$executor/unicode/ooRexx/test unicode.rex"
check noerror $executor/unicode/ooRexx/ooRexxTry.rex

check   error $executor/tests/collection/main_array.rex
check noerror $executor/tests/collection/collection_helpers.cls

check   error $executor/tests/extension/functional-test.rex
check   error $executor/tests/extension/doers-samples.rex
check noerror $executor/tests/extension/test_extension_order1.rex
check   error $executor/tests/extension/doers-info.rex
check noerror $executor/tests/extension/test_extension_order3.rex
check noerror $executor/tests/extension/test_extension_order2.rex
check   error $executor/tests/extension/named_arguments-test_with_extensions.rex
check noerror $executor/tests/extension/test_extension_order.rex
check   error $executor/tests/extension/named_arguments-test.rex
check noerror $executor/tests/extension/package-test.rex

check noerror $executor/tests/encoding/test_character_index.rex
check   error $executor/tests/encoding/display_cache.rex
check noerror $executor/tests/encoding/string_literal_encoding/package_utf8.cls
check noerror $executor/tests/encoding/string_literal_encoding/package_utf16be.cls
check noerror $executor/tests/encoding/string_literal_encoding/package_utf32be.cls
check noerror $executor/tests/encoding/string_literal_encoding/package_cp1252.cls
check noerror $executor/tests/encoding/string_literal_encoding/package_byte.cls
check noerror $executor/tests/encoding/string_literal_encoding/package_main.rex

check noerror $executor/tests/retrofit/array_literal_continuation.rex
check noerror $executor/tests/retrofit/method.cls
check noerror $executor/tests/retrofit/method.rex
check noerror $executor/tests/retrofit/main_array_literal.rex
check noerror $executor/tests/retrofit/class.rex

check noerror $executor/samples/benchmark/call-benchmark.rex
check   error $executor/samples/benchmark/doers-benchmark.rex
check   error $executor/samples/benchmark/named_arguments-benchmark.rex
check noerror $executor/samples/benchmark/macrospace_impact.rex
check noerror $executor/samples/benchmark/coactivity-benchmark.rex
check noerror $executor/samples/benchmark/routine_vs_method.rex
check noerror $executor/samples/benchmark/access_variable-benchmark.rex

check   error $executor/samples/pipeline/pipe_extension_test.rex
check   error $executor/samples/pipeline/trailing_whitespaces.rex
check noerror $executor/samples/pipeline/pipe_std_test.rex
check   error $executor/samples/pipeline/grep_sources.rex
check   error $executor/samples/pipeline/one-liners.rex
check   error $executor/samples/pipeline/deadlock1.rex
check noerror $executor/samples/pipeline/pipe_test.rex

check noerror $executor/samples/trace/tiny.cls
check   error $executor/samples/trace/test_trace_block.rex
check noerror $executor/samples/trace/example_clock/clock.rex
check noerror $executor/samples/trace/test_trace.rex
check noerror $executor/samples/trace/tiny.rex

check   error $executor/samples/extension/extension.rex
check noerror $executor/samples/extension/crash.rex
check   error $executor/samples/extension/extensions_test.rex
check   error $executor/samples/extension/Y_combinator.rex
check noerror $executor/samples/extension/std/functional-test-std.rex
check noerror $executor/samples/extension/subclassing_predefined_classes.rex
check noerror $executor/samples/extension/array-zilde.cls
check   error $executor/samples/extension/doers-stress.rex
check   error $executor/samples/extension/_arch/string-with_optim-v2.cls

check noerror "$executor/samples/pipe-Matthé van der Lee/pipe.rex"
check noerror "$executor/samples/pipe-Matthé van der Lee/usepipe.rex"

check noerror $executor/samples/classic_rexx/walter/classic_rexx_regina.rex
check   error $executor/samples/classic_rexx/walter/classic_rexx_executor.rex
check   error $executor/samples/classic_rexx/walter/classic_rexx.rex
check noerror $executor/samples/classic_rexx/runRosettaCode.rex

check noerror $executor/samples/concurrency/multiplier.cls
check   error $executor/samples/concurrency/factorials_generators.rex
check   error $executor/samples/concurrency/backtrack.rex
check noerror $executor/samples/concurrency/generator.rex
check   error $executor/samples/concurrency/coactivity-test.rex
check noerror $executor/samples/concurrency/std/binary_tree-std.cls
check noerror $executor/samples/concurrency/std/multiplier-std.cls
check noerror $executor/samples/concurrency/std/coactivity-test-std.rex
check noerror $executor/samples/concurrency/std/trace-coactivity-test-std.rex
check   error $executor/samples/concurrency/coactivity-stress.rex
check noerror $executor/samples/concurrency/trace-coactivity-test.rex
check   error $executor/samples/concurrency/binary_tree.cls
check noerror $executor/samples/concurrency/guarded_user-defined_method_are_locked.rex
check noerror $executor/samples/concurrency/guarded_predefined_method_are_not_locked.rex
check   error $executor/samples/concurrency/generator-test.rex
check noerror $executor/samples/concurrency/deadlock4.rex
check   error $executor/samples/concurrency/deadlock5.rex
check noerror $executor/samples/concurrency/busy.cls
check   error $executor/samples/concurrency/deadlock2.rex
check noerror $executor/samples/concurrency/deadlock3.rex
check noerror $executor/samples/concurrency/deadlock1.rex

check noerror $executor/samples/mutablebuffer/perf.rex

check noerror $executor/samples/rgf_util2/test.rex

check noerror $executor/samples/gc/testcase1.rex
check noerror $executor/samples/gc/testcase2.rex

check noerror $executor/samples/functional/functional-test.rex
check noerror $executor/samples/functional/functional-v2.rex
check noerror $executor/samples/functional/functional-v1.rex

check   error $executor/packages/pipeline/pipe_extension.cls
check noerror $executor/packages/pipeline/pipe.cls

check   error $executor/packages/executor.rex

check noerror $executor/packages/trace/tracer.rex

check noerror $executor/packages/extension/indeterminate.cls
check noerror $executor/packages/extension/package.cls
check   error $executor/packages/extension/stringChunkExtended.cls
check   error $executor/packages/extension/logical.cls
check   error $executor/packages/extension/doers.cls
check   error $executor/packages/extension/array.cls
check noerror $executor/packages/extension/novalue.cls
check noerror $executor/packages/extension/complex.cls
check noerror $executor/packages/extension/file.cls
check noerror $executor/packages/extension/std/functionals-std.cls
check noerror $executor/packages/extension/std/extensions-std.cls
check noerror $executor/packages/extension/std/doers-std.cls
check   error $executor/packages/extension/functionals.cls
check   error $executor/packages/extension/object.cls
check   error $executor/packages/extension/string.cls
check   error $executor/packages/extension/notrace.cls
check noerror $executor/packages/extension/stringChunk.cls
check noerror $executor/packages/extension/infinity.cls
check   error $executor/packages/extension/collection.cls
check   error $executor/packages/extension/text.cls
check noerror $executor/packages/extension/extensions.cls
check noerror $executor/packages/extension/rexxinfo.cls

check   error $executor/packages/encoding/byte_encoding.cls
check   error $executor/packages/encoding/unicodeN_encoding.cls
check   error $executor/packages/encoding/unicode.cls
check   error $executor/packages/encoding/stringIndexer.cls
check   error $executor/packages/encoding/wtf16_encoding.cls
check   error $executor/packages/encoding/wtf8_encoding.cls
check noerror $executor/packages/encoding/cachedStrings.cls
check noerror $executor/packages/encoding/stringEncoding.cls
check   error $executor/packages/encoding/unicode_common.cls
check   error $executor/packages/encoding/unicode8_encoding.cls
check   error $executor/packages/encoding/unicode32_encoding.cls
check   error $executor/packages/encoding/utf8_common.cls
check   error $executor/packages/encoding/encoding.cls
check   error $executor/packages/encoding/unicode16_encoding.cls
check noerror $executor/packages/encoding/optional/ibm-437_encoding.cls
check noerror $executor/packages/encoding/optional/windows-1252_encoding.cls
check noerror $executor/packages/encoding/optional/ibm-1252_encoding.cls
check noerror $executor/packages/encoding/optional/iso-8859-1_encoding.cls
check   error $executor/packages/encoding/utf8_encoding.cls
check noerror $executor/packages/encoding/utf16_encoding.cls
check   error $executor/packages/encoding/byte_common.cls
check   error $executor/packages/encoding/utf32_encoding.cls
check   error $executor/packages/encoding/stringInterface.cls
check   error $executor/packages/encoding/utf16_common.cls

check   error $executor/packages/utilities/dotsymbols.rex
check noerror $executor/packages/utilities/indentedstream.cls

check   error $executor/packages/concurrency/coactivity.cls
check noerror $executor/packages/concurrency/std/coactivity.cls
check noerror $executor/packages/concurrency/activity.cls
check   error $executor/packages/concurrency/generator.cls

check   error $executor/packages/rgf_util2/rgf_util2_wrappers.rex
check noerror $executor/packages/rgf_util2/rgf_util2.rex
check noerror $executor/packages/rgf_util2/official/rgf_util2.rex

check noerror $executor/packages/profiling/profiling.cls

check noerror $executor/packages/procedural/array.cls
check noerror $executor/packages/procedural/dispatcher.cls
check noerror $executor/packages/procedural/bsf.cls
check noerror $executor/packages/procedural/object.cls
check noerror $executor/packages/procedural/string.cls
check noerror $executor/packages/procedural/collection.cls

check noerror $executor/trunk/extensions/csvStream/csvStream.cls
check noerror $executor/trunk/extensions/dateparser/dateparser.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/EventNotification.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/DialogControls.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/UtilityClasses.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/ControlDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/DialogExtensions.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/BaseDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/RcDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/Menu.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/ResDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/CategoryDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/DeprecatedClasses.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/PlainBaseDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/build_ooDialog_cls.rex
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/PropertySheet.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/AnimatedButton.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/UserDialog.cls
check noerror $executor/trunk/extensions/platform/windows/oodialog.wchar/DynamicDialog.cls
check noerror $executor/trunk/extensions/platform/windows/rxwinsys/winsystm.cls
check noerror $executor/trunk/extensions/platform/windows/orxscrpt/security.rex
check noerror $executor/trunk/extensions/platform/windows/orxscrpt/rexx2inc.rex
check noerror $executor/trunk/extensions/platform/windows/ole/orexxole.cls
check noerror $executor/trunk/extensions/rxsock/socket.cls
check noerror $executor/trunk/extensions/rxsock/mime.cls
check noerror $executor/trunk/extensions/rxsock/smtp.cls
check noerror $executor/trunk/extensions/rxsock/streamsocket.cls
check noerror $executor/trunk/extensions/orxncurses/ncurses.cls
check noerror $executor/trunk/extensions/rxregexp/rxregexp.cls
check noerror $executor/trunk/extensions/json/json.cls
check noerror $executor/trunk/extensions/rxftp/rxftp.cls

check noerror $executor/trunk/samples/rexxcps.rex
check noerror $executor/trunk/samples/usecomp.rex
check noerror $executor/trunk/samples/pipe.rex
check noerror $executor/trunk/samples/semcls.rex
check noerror $executor/trunk/samples/sfclient.rex
check noerror $executor/trunk/samples/stack.rex
check noerror $executor/trunk/samples/philfork.rex
check noerror $executor/trunk/samples/usepipe.rex
check noerror $executor/trunk/samples/qdate.rex
check noerror $executor/trunk/samples/scserver.rex
check noerror $executor/trunk/samples/greply.rex
check noerror $executor/trunk/samples/sscclient.rex
check noerror $executor/trunk/samples/guess.rex
check noerror $executor/trunk/samples/unix/api/wpipe2/aspitest2.rex
check noerror $executor/trunk/samples/unix/api/wpipe3/aspitest3.rex
check noerror $executor/trunk/samples/unix/api/callrexx/example.rex
check noerror $executor/trunk/samples/unix/api/callrexx/startrx1.rex
check noerror $executor/trunk/samples/unix/api/callrexx/startrx2.rex
check noerror $executor/trunk/samples/unix/api/callrexx/startrx3.rex
check noerror $executor/trunk/samples/unix/api/callrexx/del_macro.rex
check noerror $executor/trunk/samples/unix/api/callrexx/load_macro.rex
check noerror $executor/trunk/samples/unix/api/callrexx/macros.rex
check noerror $executor/trunk/samples/unix/api/wpipe1/aspitest1.rex
check noerror $executor/trunk/samples/factor.rex
check noerror $executor/trunk/samples/sfserver.rex
check noerror $executor/trunk/samples/native.api/call.example/tooRecursiveTrapped.rex
check noerror $executor/trunk/samples/native.api/call.example/tooRecursiveUnhandled.rex
check noerror $executor/trunk/samples/native.api/call.example/HelloWorld.rex
check noerror $executor/trunk/samples/ktguard.rex
check noerror $executor/trunk/samples/scclient.rex
check noerror $executor/trunk/samples/properties.rex
check noerror $executor/trunk/samples/complex.rex
check noerror $executor/trunk/samples/qtime.rex
check noerror $executor/trunk/samples/ccreply.rex
check noerror $executor/trunk/samples/windows/misc/fileDrop.rex
check noerror $executor/trunk/samples/windows/rexutils/drives.rex
check noerror $executor/trunk/samples/windows/ole/wmi/process.rex
check noerror $executor/trunk/samples/windows/ole/wmi/accounts.rex
check noerror $executor/trunk/samples/windows/ole/wmi/services.rex
check noerror $executor/trunk/samples/windows/ole/wmi/osinfo.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi8.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi1.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi2.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi3.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi7.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi6.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi4.rex
check noerror $executor/trunk/samples/windows/ole/adsi/adsi5.rex
check noerror $executor/trunk/samples/windows/ole/methinfo/main.rex
check noerror $executor/trunk/samples/windows/ole/methinfo/methinfo.cls
check noerror $executor/trunk/samples/windows/ole/apps/samp10.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp04.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp05.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp11.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp07.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp13.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp12.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp06.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp02.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp03.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp01.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp14.rex
check noerror $executor/trunk/samples/windows/ole/apps/MSAccessDemo.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp08.rex
check noerror $executor/trunk/samples/windows/ole/apps/samp09.rex
check noerror $executor/trunk/samples/windows/wsh/print.rex
check noerror $executor/trunk/samples/windows/wsh/call_simpleobjectrexxcom.rex
check noerror $executor/trunk/samples/windows/api/wpipe/wpipe2/apitest2.rex
check noerror $executor/trunk/samples/windows/api/wpipe/wpipe3/apitest3.rex
check noerror $executor/trunk/samples/windows/api/wpipe/wpipe1/apitest1.rex
check noerror $executor/trunk/samples/rexxtry.rex
check noerror $executor/trunk/samples/month.rex
# Next is an ooRexx 4.2 sample which contains an invalid 'leave'.
# This sample has been rewritten in ooRexx 5.
check   error $executor/trunk/samples/makestring.rex

check noerror $executor/trunk/support/portable/setupoorexx.rex
check noerror $executor/trunk/support/portable/createPortable.rex
check noerror $executor/trunk/support/portable/testoorexx.rex
