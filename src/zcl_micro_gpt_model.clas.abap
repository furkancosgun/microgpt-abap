CLASS zcl_micro_gpt_model DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_micro_gpt_module.

    DATA mo_tok_emb       TYPE REF TO zcl_micro_gpt_embedding.
    DATA mo_pos_emb       TYPE REF TO zcl_micro_gpt_embedding.
    DATA mo_lm_head       TYPE REF TO zcl_micro_gpt_linear.
    DATA mt_blocks        TYPE STANDARD TABLE OF REF TO zcl_micro_gpt_block.

    DATA mv_num_layers    TYPE i.
    DATA mv_embedding_dim TYPE i.
    DATA mv_num_heads     TYPE i.
    DATA mv_head_dim      TYPE i.
    DATA mv_block_size    TYPE i.

    METHODS constructor
      IMPORTING iv_vocabulary_size TYPE i
                iv_block_size      TYPE i
                iv_embedding_dim   TYPE i
                iv_num_layers      TYPE i
                iv_num_heads       TYPE i.

    METHODS forward
      IMPORTING iv_token_id      TYPE i
                iv_pos_id        TYPE i
                io_cache         TYPE REF TO zcl_micro_gpt_kv_cache
      RETURNING VALUE(rt_logits) TYPE zcl_micro_gpt_value=>tt_values.

  PRIVATE SECTION.
    METHODS compute_attention
      IMPORTING it_q             TYPE zcl_micro_gpt_value=>tt_values
                it_keys          TYPE zcl_micro_gpt_kv_cache=>tt_layer_cache
                it_values        TYPE zcl_micro_gpt_kv_cache=>tt_layer_cache
      RETURNING VALUE(rt_result) TYPE zcl_micro_gpt_value=>tt_values.
ENDCLASS.


CLASS zcl_micro_gpt_model IMPLEMENTATION.
  METHOD constructor.
    CONSTANTS lc_std TYPE f VALUE '0.02'.

    mv_num_layers = iv_num_layers.
    mv_embedding_dim = iv_embedding_dim.
    mv_num_heads = iv_num_heads.
    mv_head_dim   = iv_embedding_dim / iv_num_heads.
    mv_block_size = iv_block_size.

    mo_tok_emb = NEW #( iv_num_embeddings = iv_vocabulary_size
                        iv_embedding_dim  = iv_embedding_dim
                        iv_std            = lc_std ).

    mo_pos_emb = NEW #( iv_num_embeddings = iv_block_size
                        iv_embedding_dim  = iv_embedding_dim
                        iv_std            = lc_std ).

    mo_lm_head = NEW #( iv_in_dim  = iv_embedding_dim
                        iv_out_dim = iv_vocabulary_size
                        iv_std     = lc_std ).

    DO iv_num_layers TIMES.
      APPEND NEW zcl_micro_gpt_block( iv_embedding_dim = iv_embedding_dim
                                      iv_std           = lc_std ) TO mt_blocks.
    ENDDO.
  ENDMETHOD.

  METHOD zif_micro_gpt_module~parameters.
    APPEND LINES OF mo_tok_emb->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_pos_emb->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    APPEND LINES OF mo_lm_head->zif_micro_gpt_module~parameters( ) TO rt_parameters.

    LOOP AT mt_blocks ASSIGNING FIELD-SYMBOL(<fs_block>).
      APPEND LINES OF <fs_block>->zif_micro_gpt_module~parameters( ) TO rt_parameters.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_micro_gpt_module~zero_gradients.
    mo_tok_emb->zif_micro_gpt_module~zero_gradients( ).
    mo_pos_emb->zif_micro_gpt_module~zero_gradients( ).
    mo_lm_head->zif_micro_gpt_module~zero_gradients( ).

    LOOP AT mt_blocks ASSIGNING FIELD-SYMBOL(<fs_block>).
      <fs_block>->zif_micro_gpt_module~zero_gradients( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD forward.
    DATA lt_tok_emb  TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_pos_emb  TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_x        TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_residual TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_queries  TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_keys     TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_values   TYPE zcl_micro_gpt_value=>tt_values.
    DATA lv_i        TYPE i.
    DATA lv_li       TYPE i.
    FIELD-SYMBOLS <fs_block> LIKE LINE OF mt_blocks.
    FIELD-SYMBOLS <fs_key>   LIKE LINE OF io_cache->mt_keys.
    FIELD-SYMBOLS <fs_val>   LIKE LINE OF io_cache->mt_values.
    FIELD-SYMBOLS <fs_v>     LIKE LINE OF lt_x.

    lt_tok_emb = mo_tok_emb->forward( iv_token_id ).
    lt_pos_emb = mo_pos_emb->forward( iv_pos_id ).

    DO mv_embedding_dim TIMES.
      lv_i = sy-index.
      APPEND lt_tok_emb[ lv_i ]->add( lt_pos_emb[ lv_i ] ) TO lt_x.
    ENDDO.
    lt_x = zcl_micro_gpt_layers=>rms_norm( lt_x ).

    LOOP AT mt_blocks ASSIGNING <fs_block>.
      lv_li = sy-tabix.
      lt_residual = lt_x.

      lt_x = zcl_micro_gpt_layers=>rms_norm( lt_x ).
      lt_queries = <fs_block>->mo_q_proj->forward( lt_x ).
      lt_keys = <fs_block>->mo_k_proj->forward( lt_x ).
      lt_values = <fs_block>->mo_v_proj->forward( lt_x ).

      ASSIGN io_cache->mt_keys[ lv_li ] TO <fs_key>.
      APPEND lt_keys TO <fs_key>.
      ASSIGN io_cache->mt_values[ lv_li ] TO <fs_val>.
      APPEND lt_values TO <fs_val>.

      DATA(lt_attn_out) = compute_attention( it_q      = lt_queries
                                             it_keys   = io_cache->mt_keys[ lv_li ]
                                             it_values = io_cache->mt_values[ lv_li ] ).
      lt_x = <fs_block>->mo_o_proj->forward( lt_attn_out ).

      DO lines( lt_x ) TIMES.
        lt_x[ sy-index ] = lt_x[ sy-index ]->add( lt_residual[ sy-index ] ).
      ENDDO.

      lt_residual = lt_x.
      lt_x = zcl_micro_gpt_layers=>rms_norm( lt_x ).
      lt_x = <fs_block>->mo_mlp_c_fc->forward( lt_x ).
      LOOP AT lt_x ASSIGNING <fs_v>.
        <fs_v> = <fs_v>->relu( ).
      ENDLOOP.
      lt_x = <fs_block>->mo_mlp_c_proj->forward( lt_x ).

      DO lines( lt_x ) TIMES.
        lt_x[ sy-index ] = lt_x[ sy-index ]->add( lt_residual[ sy-index ] ).
      ENDDO.
    ENDLOOP.

    rt_logits = mo_lm_head->forward( lt_x ).
  ENDMETHOD.

  METHOD compute_attention.
    DATA lv_scale       TYPE f.
    DATA lt_query_heads TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_attn_logits TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_key_heads   TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_weights     TYPE zcl_micro_gpt_value=>tt_values.
    DATA lv_h           TYPE i.
    DATA lv_hs          TYPE i.
    DATA lv_j           TYPE i.
    DATA lv_t           TYPE i.
    DATA lo_sum         TYPE REF TO zcl_micro_gpt_value.
    FIELD-SYMBOLS <fs_full_key_row> LIKE LINE OF it_keys.
    FIELD-SYMBOLS <fs_full_val_row> LIKE LINE OF it_keys.

    lv_scale = sqrt( CONV f( mv_head_dim ) ).
    rt_result = VALUE #( FOR i = 1 UNTIL i > mv_embedding_dim
                         ( NEW zcl_micro_gpt_value( iv_value = 0 ) ) ).

    DO mv_num_heads TIMES.
      lv_h = sy-index - 1.
      lv_hs = ( lv_h * mv_head_dim ) + 1.

      CLEAR lt_query_heads.
      APPEND LINES OF it_q FROM lv_hs TO ( lv_hs + mv_head_dim - 1 ) TO lt_query_heads.

      CLEAR lt_attn_logits.

      LOOP AT it_keys ASSIGNING <fs_full_key_row>.

        CLEAR lt_key_heads.
        APPEND LINES OF <fs_full_key_row> FROM lv_hs TO ( lv_hs + mv_head_dim - 1 ) TO lt_key_heads.

        DATA(lo_dot) = zcl_micro_gpt_value=>dot_product( it_values_a = lt_query_heads
                                                         it_values_b = lt_key_heads ).

        APPEND lo_dot->mul( zcl_micro_gpt_value=>scalar( 1 / lv_scale ) ) TO lt_attn_logits.
      ENDLOOP.

      lt_weights = zcl_micro_gpt_value=>fused_softmax( lt_attn_logits ).

      DO mv_head_dim TIMES.
        lv_j = sy-index.
        lo_sum = zcl_micro_gpt_value=>scalar( 0 ).

        LOOP AT it_values ASSIGNING <fs_full_val_row>.
          lv_t = sy-tabix.

          lo_sum = lo_sum->add( lt_weights[ lv_t ]->mul( <fs_full_val_row>[ lv_hs + lv_j - 1 ] ) ).
        ENDLOOP.

        rt_result[ lv_hs + lv_j - 1 ] = lo_sum.
      ENDDO.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
