CLASS zcl_micro_gpt_trainer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_adam_config,
        learning_rate TYPE f,
        beta1         TYPE f,
        beta2         TYPE f,
        eps           TYPE f,
      END OF ty_adam_config.

    TYPES:
      BEGIN OF ty_train_config,
        num_steps TYPE i,
        log_steps TYPE i,
      END OF ty_train_config.

    METHODS constructor
      IMPORTING io_model        TYPE REF TO zcl_micro_gpt_model
                io_tokenizer    TYPE REF TO zif_micro_gpt_tokenizer
                it_dataset      TYPE zif_micro_gpt_dataset=>tt_string_table
                is_adam_config  TYPE ty_adam_config
                is_train_config TYPE ty_train_config.

    METHODS train.

  PRIVATE SECTION.
    DATA mo_model     TYPE REF TO zcl_micro_gpt_model.
    DATA mo_tokenizer TYPE REF TO zif_micro_gpt_tokenizer.
    DATA mt_dataset   TYPE zif_micro_gpt_dataset=>tt_string_table.
    DATA ms_adam_cfg  TYPE ty_adam_config.
    DATA ms_train_cfg TYPE ty_train_config.
    DATA mo_optimizer TYPE REF TO zif_micro_gpt_optimizer.
ENDCLASS.


CLASS zcl_micro_gpt_trainer IMPLEMENTATION.
  METHOD constructor.
    mo_model = io_model.
    mo_tokenizer = io_tokenizer.
    mt_dataset = it_dataset.
    ms_adam_cfg = is_adam_config.
    ms_train_cfg = is_train_config.
    mo_optimizer = NEW zcl_micro_gpt_optim_adam( iv_lr    = ms_adam_cfg-learning_rate
                                                 iv_beta1 = ms_adam_cfg-beta1
                                                 iv_beta2 = ms_adam_cfg-beta2
                                                 iv_eps   = ms_adam_cfg-eps ).
  ENDMETHOD.

  METHOD train.
    DATA lt_losses     TYPE zcl_micro_gpt_value=>tt_values.
    DATA lo_cache      TYPE REF TO zcl_micro_gpt_kv_cache.
    DATA lt_parameters TYPE zcl_micro_gpt_value=>tt_values.
    DATA lv_step       TYPE i.
    DATA lv_doc_idx    TYPE i.
    DATA lv_doc        TYPE string.
    DATA lt_tokens     TYPE zif_micro_gpt_tokenizer=>tt_tokens.
    DATA lv_n          TYPE i.
    DATA lv_position   TYPE i.
    DATA lv_token_id   TYPE i.
    DATA lv_target_id  TYPE i.
    DATA lt_logits     TYPE zcl_micro_gpt_value=>tt_values.
    DATA lt_log_probs  TYPE zcl_micro_gpt_value=>tt_values.
    DATA lo_total_loss TYPE REF TO zcl_micro_gpt_value.
    DATA lv_lr_decay   TYPE f.
    FIELD-SYMBOLS <fs_lose> LIKE LINE OF lt_losses.

    lt_parameters = mo_model->zif_micro_gpt_module~parameters( ).

    WRITE: / 'Vocab Size:', mo_tokenizer->get_vocab_size( ).
    WRITE: / 'Num Params:', lines( lt_parameters ).
    WRITE: / 'Training started...', ms_train_cfg-num_steps, 'steps.'.

    DO ms_train_cfg-num_steps TIMES.
      lv_step = sy-index.
      CLEAR lt_losses.

      lv_doc_idx = ( ( lv_step - 1 ) MOD lines( mt_dataset ) ) + 1.
      lv_doc = mt_dataset[ lv_doc_idx ].

      lt_tokens = mo_tokenizer->encode( lv_doc ).

      lv_n = lines( lt_tokens ) - 1.
      IF lv_n > mo_model->mv_block_size.
        lv_n = mo_model->mv_block_size.
      ENDIF.
      lo_cache = NEW zcl_micro_gpt_kv_cache( iv_n_layers = mo_model->mv_num_layers ).

      DO lv_n TIMES.
        lv_position = sy-index.
        lv_token_id = lt_tokens[ lv_position ].
        lv_target_id = lt_tokens[ lv_position + 1 ].

        lt_logits = mo_model->forward( iv_token_id = lv_token_id
                                       iv_pos_id   = lv_position - 1
                                       io_cache    = lo_cache ).

        lt_log_probs = zcl_micro_gpt_value=>fused_log_softmax( lt_logits ).

        APPEND lt_log_probs[ lv_target_id + 1 ]->neg( ) TO lt_losses.
      ENDDO.

      lo_total_loss = zcl_micro_gpt_value=>scalar( 0 ).
      LOOP AT lt_losses ASSIGNING <fs_lose>.
        lo_total_loss = lo_total_loss->add( <fs_lose> ).
      ENDLOOP.
      lo_total_loss = lo_total_loss->mul( zcl_micro_gpt_value=>scalar( 1 / CONV f( lv_n ) ) ).

      lo_total_loss->backward( ).

      lv_lr_decay = 1 - ( CONV f( lv_step ) / CONV f( ms_train_cfg-num_steps ) ).
      mo_optimizer->step( it_values   = lt_parameters
                          iv_lr_decay = lv_lr_decay ).

      mo_model->zif_micro_gpt_module~zero_gradients( ).

      IF lv_step <= 5 OR lv_step MOD ms_train_cfg-log_steps = 0.
        WRITE: / 'Step:', lv_step, 'Loss:', lo_total_loss->mv_value.

        cl_progress_indicator=>progress_indicate(
            i_text               = |Step: { lv_step } Loss: { lo_total_loss->mv_value }|
            i_total              = ms_train_cfg-num_steps
            i_processed          = lv_step
            i_output_immediately = abap_true ).
      ENDIF.
    ENDDO.
    WRITE / 'Training completed.'.
  ENDMETHOD.
ENDCLASS.
