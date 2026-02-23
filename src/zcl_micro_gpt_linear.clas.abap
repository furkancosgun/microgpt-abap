CLASS zcl_micro_gpt_linear DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_micro_gpt_module.

    DATA mo_weight TYPE REF TO zif_micro_gpt_matrix.

    METHODS constructor
      IMPORTING iv_in_dim  TYPE i
                iv_out_dim TYPE i
                iv_std     TYPE f.

    METHODS forward
      IMPORTING it_values        TYPE zcl_micro_gpt_value=>tt_values
      RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.
ENDCLASS.


CLASS zcl_micro_gpt_linear IMPLEMENTATION.
  METHOD constructor.
    mo_weight = NEW zcl_micro_gpt_matrix( iv_rows = iv_out_dim
                                          iv_cols = iv_in_dim
                                          iv_std  = iv_std ).
  ENDMETHOD.

  METHOD zif_micro_gpt_module~parameters.
    rt_parameters = mo_weight->all( ).
  ENDMETHOD.

  METHOD zif_micro_gpt_module~zero_gradients.
    FIELD-SYMBOLS <fs_param> TYPE REF TO zcl_micro_gpt_value.

    LOOP AT mo_weight->all( ) ASSIGNING <fs_param>.
      <fs_param>->zero_gradient( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD forward.
    DATA lv_row TYPE i.
    DATA lt_val TYPE zcl_micro_gpt_value=>tt_values.
    DATA lo_dot TYPE REF TO zcl_micro_gpt_value.

    DO mo_weight->get_rows( ) TIMES.
      lv_row = sy-index - 1.
      lt_val = mo_weight->row( lv_row ).
      lo_dot = zcl_micro_gpt_value=>dot_product( it_values_a = lt_val
                                                 it_values_b = it_values ).
      APPEND lo_dot TO rt_values.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
