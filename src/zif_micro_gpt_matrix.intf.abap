INTERFACE zif_micro_gpt_matrix
  PUBLIC.

  METHODS get_rows
    RETURNING VALUE(rv_rows) TYPE i.

  METHODS get_cols
    RETURNING VALUE(rv_cols) TYPE i.

  METHODS at
    IMPORTING iv_row          TYPE i
              iv_col          TYPE i
    RETURNING VALUE(ro_value) TYPE REF TO zcl_micro_gpt_value.

  METHODS row
    IMPORTING iv_row           TYPE i
    RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.

  METHODS col
    IMPORTING iv_col           TYPE i
    RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.

  METHODS all
    RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.
ENDINTERFACE.
