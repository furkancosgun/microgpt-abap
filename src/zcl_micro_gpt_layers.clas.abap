CLASS zcl_micro_gpt_layers DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS softmax
      IMPORTING it_values        TYPE zcl_micro_gpt_value=>tt_values
      RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.

    CLASS-METHODS rms_norm
      IMPORTING it_values        TYPE zcl_micro_gpt_value=>tt_values
      RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.
ENDCLASS.


CLASS zcl_micro_gpt_layers IMPLEMENTATION.
  METHOD rms_norm.
    CONSTANTS lc_eps TYPE f VALUE '1.0E-5'.
    DATA lv_len  TYPE i.
    DATA lo_sum  TYPE REF TO zcl_micro_gpt_value.
    DATA lo_mean TYPE REF TO zcl_micro_gpt_value.
    DATA lo_eps  TYPE REF TO zcl_micro_gpt_value.
    DATA lo_var  TYPE REF TO zcl_micro_gpt_value.
    DATA lo_rms  TYPE REF TO zcl_micro_gpt_value.
    FIELD-SYMBOLS <fs_value> LIKE LINE OF it_values.

    lv_len = lines( it_values ).

    lo_sum = zcl_micro_gpt_value=>scalar( 0 ).
    LOOP AT it_values ASSIGNING <fs_value>.
      lo_sum = lo_sum->add( <fs_value>->mul( <fs_value> ) ).
    ENDLOOP.

    lo_mean = lo_sum->div( zcl_micro_gpt_value=>scalar( CONV f( lv_len ) ) ).

    lo_eps = zcl_micro_gpt_value=>scalar( lc_eps ).
    lo_var = lo_mean->add( lo_eps ).
    lo_rms = lo_var->pow( CONV f( '-0.5' ) ).

    LOOP AT it_values ASSIGNING <fs_value>.
      APPEND <fs_value>->mul( lo_rms ) TO rt_values.
    ENDLOOP.
  ENDMETHOD.

  METHOD softmax.
    rt_values = zcl_micro_gpt_value=>fused_softmax( it_values ).
  ENDMETHOD.
ENDCLASS.
