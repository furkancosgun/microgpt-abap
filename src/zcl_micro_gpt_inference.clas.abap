CLASS zcl_micro_gpt_inference DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_inference_result TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    METHODS constructor
      IMPORTING io_model     TYPE REF TO zcl_micro_gpt_model
                io_tokenizer TYPE REF TO zif_micro_gpt_tokenizer.

    METHODS generate
      IMPORTING iv_prefix        TYPE string
                iv_temperature   TYPE f DEFAULT '0.5'
                iv_samples       TYPE i DEFAULT 20
      RETURNING VALUE(rt_result) TYPE tt_inference_result.

  PRIVATE SECTION.
    DATA mo_model     TYPE REF TO zcl_micro_gpt_model.
    DATA mo_tokenizer TYPE REF TO zif_micro_gpt_tokenizer.
ENDCLASS.


CLASS zcl_micro_gpt_inference IMPLEMENTATION.
  METHOD constructor.
    mo_model = io_model.
    mo_tokenizer = io_tokenizer.
  ENDMETHOD.

  METHOD generate.
    DATA lv_sample_idx        TYPE i.
    DATA lo_inf_cache         TYPE REF TO zcl_micro_gpt_kv_cache.
    DATA lv_token_id          TYPE i.
    DATA lv_sample_text       TYPE string.
    DATA lt_prefix_tokens     TYPE zif_micro_gpt_tokenizer=>tt_tokens.
    DATA lv_actual_prefix_len TYPE i.
    DATA lv_current_position  TYPE i.
    DATA lt_logits            TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_probs             TYPE zcl_micro_gpt_value=>tt_values.
    DATA lv_next              TYPE i.
    DATA lv_random_value      TYPE f.
    DATA lv_cumulative_prob   TYPE f.
    DATA lv_max_prob          TYPE f.
    DATA lo_random            TYPE REF TO cl_abap_random.
    FIELD-SYMBOLS <fs_logit> LIKE LINE OF lt_logits.
    FIELD-SYMBOLS <fs_prob>  LIKE LINE OF lt_probs.

    WRITE: / '--- Inference with prefix:', iv_prefix, '---'.

    lo_random = cl_abap_random=>create( seed = 42 ).

    DO iv_samples TIMES.
      lv_sample_idx = sy-index.
      lo_inf_cache = NEW zcl_micro_gpt_kv_cache( iv_n_layers = mo_model->mv_num_layers ).
      lv_sample_text = iv_prefix.

      lv_current_position = 0.

      IF iv_prefix IS INITIAL.
        lv_token_id = mo_tokenizer->get_bos_token( ).
      ELSE.
        lt_prefix_tokens = mo_tokenizer->encode( iv_prefix ).
        lv_actual_prefix_len = lines( lt_prefix_tokens ) - 1.

        DO lv_actual_prefix_len - 1 TIMES.
          mo_model->forward( iv_token_id = lt_prefix_tokens[ sy-index ]
                             iv_pos_id   = lv_current_position
                             io_cache    = lo_inf_cache ).
          lv_current_position = lv_current_position + 1.
        ENDDO.

        lv_token_id = lt_prefix_tokens[ lv_actual_prefix_len ].
      ENDIF.

      DO mo_model->mv_block_size TIMES.
        IF lv_current_position >= mo_model->mv_block_size.
          EXIT.
        ENDIF.

        lt_logits = mo_model->forward( iv_token_id = lv_token_id
                                       iv_pos_id   = lv_current_position
                                       io_cache    = lo_inf_cache ).

        IF iv_temperature > 0.
          LOOP AT lt_logits ASSIGNING <fs_logit>.
            <fs_logit>->mv_value = <fs_logit>->mv_value / iv_temperature.
          ENDLOOP.
        ENDIF.

        lt_probs = zcl_micro_gpt_value=>fused_softmax( lt_logits ).

        IF iv_temperature > 0.
          lv_random_value = lo_random->float( ).
          lv_next = mo_tokenizer->get_bos_token( ).
          lv_cumulative_prob = 0.
          LOOP AT lt_probs ASSIGNING <fs_prob>.
            lv_cumulative_prob = lv_cumulative_prob + <fs_prob>->mv_value.
            IF lv_random_value <= lv_cumulative_prob.
              lv_next = sy-tabix - 1.
              EXIT.
            ENDIF.
          ENDLOOP.
        ELSE.
          lv_next = mo_tokenizer->get_bos_token( ).
          lv_max_prob = '-99999'.
          LOOP AT lt_probs ASSIGNING <fs_prob>.
            IF <fs_prob>->mv_value > lv_max_prob.
              lv_max_prob = <fs_prob>->mv_value.
              lv_next = sy-tabix - 1.
            ENDIF.
          ENDLOOP.
        ENDIF.

        IF lv_next = mo_tokenizer->get_bos_token( ).
          EXIT.
        ENDIF.

        lv_token_id = lv_next.
        lv_sample_text = lv_sample_text && mo_tokenizer->decode( VALUE #( ( lv_token_id ) ) ).
        lv_current_position = lv_current_position + 1.
      ENDDO.

      APPEND lv_sample_text TO rt_result.

      WRITE: / 'Sample', lv_sample_idx, ':', lv_sample_text.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
