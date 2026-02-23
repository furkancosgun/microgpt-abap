CLASS zcl_micro_gpt_matrix DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_rows TYPE i
                iv_cols TYPE i
                iv_std  TYPE f.

    INTERFACES zif_micro_gpt_matrix.

  PRIVATE SECTION.
    DATA mt_values TYPE zcl_micro_gpt_value=>tt_values.
    DATA mv_rows   TYPE i.
    DATA mv_cols   TYPE i.
ENDCLASS.


CLASS zcl_micro_gpt_matrix IMPLEMENTATION.
  METHOD zif_micro_gpt_matrix~all.
    rt_values = mt_values.
  ENDMETHOD.

  METHOD zif_micro_gpt_matrix~at.
    DATA lv_index TYPE i.

    lv_index = ( iv_row * mv_cols ) + iv_col + 1.

    ro_value = mt_values[ lv_index ].
  ENDMETHOD.

  METHOD zif_micro_gpt_matrix~col.
    DATA lv_index TYPE i.

    DO mv_rows TIMES.
      lv_index = ( ( sy-index - 1 ) * mv_cols ) + iv_col + 1.

      APPEND mt_values[ lv_index ] TO rt_values.
    ENDDO.
  ENDMETHOD.

  METHOD zif_micro_gpt_matrix~row.
    DATA lv_from TYPE i.
    DATA lv_to   TYPE i.

    lv_from = ( iv_row * mv_cols ) + 1.
    lv_to = lv_from + mv_cols - 1.
    APPEND LINES OF mt_values FROM lv_from TO lv_to TO rt_values.
  ENDMETHOD.

  METHOD constructor.
    DATA lv_len TYPE i.
    DATA lv_val TYPE f.
    DATA lo_rnd TYPE REF TO cl_abap_random.

    mv_rows = iv_rows.
    mv_cols = iv_cols.
    lo_rnd = cl_abap_random=>create( seed = 42 ).
    lv_len = mv_rows * mv_cols.

    DO lv_len TIMES.
      lv_val = lo_rnd->float( ) * iv_std.
      APPEND zcl_micro_gpt_value=>scalar( lv_val ) TO mt_values.
    ENDDO.
  ENDMETHOD.

  METHOD zif_micro_gpt_matrix~get_cols.
    rv_cols = mv_cols.
  ENDMETHOD.

  METHOD zif_micro_gpt_matrix~get_rows.
    rv_rows = mv_rows.
  ENDMETHOD.
ENDCLASS.
