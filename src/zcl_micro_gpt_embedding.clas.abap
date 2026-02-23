CLASS zcl_micro_gpt_embedding DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_micro_gpt_module.

    DATA mo_weight TYPE REF TO zif_micro_gpt_matrix.

    METHODS constructor
      IMPORTING iv_num_embeddings TYPE i
                iv_embedding_dim  TYPE i
                iv_std            TYPE f.

    METHODS forward
      IMPORTING iv_index         TYPE i
      RETURNING VALUE(rt_values) TYPE zcl_micro_gpt_value=>tt_values.
ENDCLASS.


CLASS zcl_micro_gpt_embedding IMPLEMENTATION.
  METHOD constructor.
    mo_weight = NEW zcl_micro_gpt_matrix( iv_rows = iv_num_embeddings
                                          iv_cols = iv_embedding_dim
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
    rt_values = mo_weight->row( iv_index ).
  ENDMETHOD.
ENDCLASS.
