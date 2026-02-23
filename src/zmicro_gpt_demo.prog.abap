*&---------------------------------------------------------------------*
*& Report zmicro_gpt_demo
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmicro_gpt_demo.

DATA lv_text      TYPE string.
DATA lo_loader    TYPE REF TO zif_micro_gpt_dataset.
DATA lt_dataset   TYPE zif_micro_gpt_dataset=>tt_string_table.
DATA lo_tokenizer TYPE REF TO zif_micro_gpt_tokenizer.
DATA lo_model     TYPE REF TO zcl_micro_gpt_model.
DATA lo_trainer   TYPE REF TO zcl_micro_gpt_trainer.
DATA lo_inference TYPE REF TO zcl_micro_gpt_inference.
DATA lt_result    TYPE STANDARD TABLE OF string WITH EMPTY KEY.

lo_loader = zcl_micro_gpt_dataset=>create_from_file( '/Users/furkancosgun/Downloads/names.txt'  ).
lt_dataset = lo_loader->load( ).

lo_tokenizer = NEW zcl_micro_gpt_tokenizer( lt_dataset ).

lo_model = NEW zcl_micro_gpt_model( iv_vocabulary_size = lo_tokenizer->get_vocab_size( )
                                    iv_block_size      = 16
                                    iv_embedding_dim   = 16
                                    iv_num_layers      = 1
                                    iv_num_heads       = 4 ).

lo_trainer = NEW zcl_micro_gpt_trainer( io_model        = lo_model
                                        io_tokenizer    = lo_tokenizer
                                        it_dataset      = lt_dataset
                                        is_adam_config  = VALUE #( learning_rate = '0.01'
                                                                   beta1         = '0.85'
                                                                   beta2         = '0.99'
                                                                   eps           = '1.0E-8' )
                                        is_train_config = VALUE #( num_steps = 1000
                                                                   log_steps = 1 ) ).

lo_trainer->train( ).

lo_inference = NEW zcl_micro_gpt_inference( io_model     = lo_model
                                            io_tokenizer = lo_tokenizer ).

DO.
  lv_text = ''.

  cl_demo_input=>request( EXPORTING text  = 'Prefix:'
                          CHANGING  field = lv_text ).

  lt_result = lo_inference->generate( iv_prefix      = lv_text
                                      iv_temperature = '0.5'
                                      iv_samples     = 20 ).

  LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).
    cl_demo_input=>add_text( <fs_result> ).
  ENDLOOP.
ENDDO.
