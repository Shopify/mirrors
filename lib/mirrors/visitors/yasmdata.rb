# -*-ruby-*-
#

class VM
  class InstructionSequence
    class Instruction
      InsnID2NO = {
        nop: 0,
        getlocal: 1,
        setlocal: 2,
        getspecial: 3,
        setspecial: 4,
        getinstancevariable: 5,
        setinstancevariable: 6,
        getclassvariable: 7,
        setclassvariable: 8,
        getconstant: 9,
        setconstant: 10,
        getglobal: 11,
        setglobal: 12,
        putnil: 13,
        putself: 14,
        putobject: 15,
        putspecialobject: 16,
        putiseq: 17,
        putstring: 18,
        concatstrings: 19,
        tostring: 20,
        freezestring: 21,
        toregexp: 22,
        newarray: 23,
        duparray: 24,
        expandarray: 25,
        concatarray: 26,
        splatarray: 27,
        newhash: 28,
        newrange: 29,
        pop: 30,
        dup: 31,
        dupn: 32,
        swap: 33,
        reverse: 34,
        reput: 35,
        topn: 36,
        setn: 37,
        adjuststack: 38,
        defined: 39,
        checkmatch: 40,
        checkkeyword: 41,
        trace: 42,
        defineclass: 43,
        send: 44,
        opt_str_freeze: 45,
        opt_newarray_max: 46,
        opt_newarray_min: 47,
        opt_send_without_block: 48,
        invokesuper: 49,
        invokeblock: 50,
        leave: 51,
        throw: 52,
        jump: 53,
        branchif: 54,
        branchunless: 55,
        branchnil: 56,
        getinlinecache: 57,
        setinlinecache: 58,
        once: 59,
        opt_case_dispatch: 60,
        opt_plus: 61,
        opt_minus: 62,
        opt_mult: 63,
        opt_div: 64,
        opt_mod: 65,
        opt_eq: 66,
        opt_neq: 67,
        opt_lt: 68,
        opt_le: 69,
        opt_gt: 70,
        opt_ge: 71,
        opt_ltlt: 72,
        opt_aref: 73,
        opt_aset: 74,
        opt_aset_with: 75,
        opt_aref_with: 76,
        opt_length: 77,
        opt_size: 78,
        opt_empty_p: 79,
        opt_succ: 80,
        opt_not: 81,
        opt_regexpmatch1: 82,
        opt_regexpmatch2: 83,
        opt_call_c_function: 84,
        bitblt: 85,
        answer: 86,
        getlocal_OP__WC__0: 87,
        getlocal_OP__WC__1: 88,
        setlocal_OP__WC__0: 89,
        setlocal_OP__WC__1: 90,
        putobject_OP_INT2FIX_O_0_C_: 91,
        putobject_OP_INT2FIX_O_1_C_: 92,

      }

      def self.id2insn_no(id)
        if InsnID2NO.key? id
          InsnID2NO[id]
        end
      end

      InsnNO2Size = [
        1, # nop => 0
        3, # getlocal => 1
        3, # setlocal => 2
        3, # getspecial => 3
        2, # setspecial => 4
        3, # getinstancevariable => 5
        3, # setinstancevariable => 6
        2, # getclassvariable => 7
        2, # setclassvariable => 8
        2, # getconstant => 9
        2, # setconstant => 10
        2, # getglobal => 11
        2, # setglobal => 12
        1, # putnil => 13
        1, # putself => 14
        2, # putobject => 15
        2, # putspecialobject => 16
        2, # putiseq => 17
        2, # putstring => 18
        2, # concatstrings => 19
        1, # tostring => 20
        2, # freezestring => 21
        3, # toregexp => 22
        2, # newarray => 23
        2, # duparray => 24
        3, # expandarray => 25
        1, # concatarray => 26
        2, # splatarray => 27
        2, # newhash => 28
        2, # newrange => 29
        1, # pop => 30
        1, # dup => 31
        2, # dupn => 32
        1, # swap => 33
        2, # reverse => 34
        1, # reput => 35
        2, # topn => 36
        2, # setn => 37
        2, # adjuststack => 38
        4, # defined => 39
        2, # checkmatch => 40
        3, # checkkeyword => 41
        2, # trace => 42
        4, # defineclass => 43
        4, # send => 44
        2, # opt_str_freeze => 45
        2, # opt_newarray_max => 46
        2, # opt_newarray_min => 47
        3, # opt_send_without_block => 48
        4, # invokesuper => 49
        2, # invokeblock => 50
        1, # leave => 51
        2, # throw => 52
        2, # jump => 53
        2, # branchif => 54
        2, # branchunless => 55
        2, # branchnil => 56
        3, # getinlinecache => 57
        2, # setinlinecache => 58
        3, # once => 59
        3, # opt_case_dispatch => 60
        3, # opt_plus => 61
        3, # opt_minus => 62
        3, # opt_mult => 63
        3, # opt_div => 64
        3, # opt_mod => 65
        3, # opt_eq => 66
        5, # opt_neq => 67
        3, # opt_lt => 68
        3, # opt_le => 69
        3, # opt_gt => 70
        3, # opt_ge => 71
        3, # opt_ltlt => 72
        3, # opt_aref => 73
        3, # opt_aset => 74
        4, # opt_aset_with => 75
        4, # opt_aref_with => 76
        3, # opt_length => 77
        3, # opt_size => 78
        3, # opt_empty_p => 79
        3, # opt_succ => 80
        3, # opt_not => 81
        2, # opt_regexpmatch1 => 82
        3, # opt_regexpmatch2 => 83
        2, # opt_call_c_function => 84
        1, # bitblt => 85
        1, # answer => 86
        2, # getlocal_OP__WC__0 => 87
        2, # getlocal_OP__WC__1 => 88
        2, # setlocal_OP__WC__0 => 89
        2, # setlocal_OP__WC__1 => 90
        1, # putobject_OP_INT2FIX_O_0_C_ => 91
        1, # putobject_OP_INT2FIX_O_1_C_ => 92

      ]

      def self.insn_no2size(ins_no)
        InsnNO2Size[ins_no]
      end
    end
  end
end
