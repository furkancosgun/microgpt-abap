CLASS zcl_micro_gpt_block DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_micro_gpt_module.

    DATA mo_q_proj     TYPE REF TO zcl_micro_gpt_linear.
    DATA mo_k_proj     TYPE REF TO zcl_micro_gpt_linear.
    DATA mo_v_proj     TYPE REF TO zcl_micro_gpt_linear.
    DATA mo_o_proj     TYPE REF TO zcl_micro_gpt_linear.
    DATA mo_mlp_c_fc   TYPE REF TO zcl_micro_gpt_linear.
    DATA mo_mlp_c_proj TYPE REF TO zcl_micro_gpt_linear.

    METHODS constructor
      IMPORTING iv_embedding_dim TYPE i
                iv_std           TYPE f.

ENDCLASS.


CLASS zcl_micro_gpt_block IMPLEMENTATION.
  METHOD constructor.
    mo_q_proj = NEW zcl_micro_gpt_linear( iv_in_dim  = iv_embedding_dim
                                          iv_out_dim = iv_embedding_dim
                                          iv_std     = iv_std ).

    mo_k_proj = NEW zcl_micro_gpt_linear( iv_in_dim  = iv_embedding_dim
                                          iv_out_dim = iv_embedding_dim
                                          iv_std     = iv_std ).

    mo_v_proj = NEW zcl_micro_gpt_linear( iv_in_dim  = iv_embedding_dim
                                          iv_out_dim = iv_embedding_dim
                                          iv_std     = iv_std ).

    mo_o_proj = NEW zcl_micro_gpt_linear( iv_in_dim  = iv_embedding_dim
                                          iv_out_dim = iv_embedding_dim
                                          iv_std     = iv_std ).

    mo_mlp_c_fc = NEW zcl_micro_gpt_linear( iv_in_dim  = iv_embedding_dim
                                            iv_out_dim = 4 * iv_embedding_dim
                                            iv_std     = iv_std ).

    mo_mlp_c_proj = NEW zcl_micro_gpt_linear( iv_in_dim  = 4 * iv_embedding_dim
                                              iv_out_dim = iv_embedding_dim
                                              iv_std     = iv_std ).
  ENDMETHOD.

  METHOD zif_micro_gpt_module~parameters.
    APPEND LINES OF mo_q_proj->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_k_proj->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_v_proj->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_o_proj->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_mlp_c_fc->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_mlp_c_proj->zif_micro_gpt_module~parameters( ) TO rt_parameters.
  ENDMETHOD.

  METHOD zif_micro_gpt_module~zero_gradients.
    mo_q_proj->zif_micro_gpt_module~zero_gradients( ).
    mo_k_proj->zif_micro_gpt_module~zero_gradients( ).
    mo_v_proj->zif_micro_gpt_module~zero_gradients( ).
    mo_o_proj->zif_micro_gpt_module~zero_gradients( ).
    mo_mlp_c_fc->zif_micro_gpt_module~zero_gradients( ).
    mo_mlp_c_proj->zif_micro_gpt_module~zero_gradients( ).
  ENDMETHOD.
ENDCLASS.
