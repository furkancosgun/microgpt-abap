CLASS zcl_micro_gpt_tokenizer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING it_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.

    INTERFACES zif_micro_gpt_tokenizer.

  PRIVATE SECTION.
    TYPES ty_char TYPE c LENGTH 1.
    TYPES:
      BEGIN OF ty_ch_to_id,
        ch TYPE ty_char,
        id TYPE i,
      END OF ty_ch_to_id.

    TYPES:
      BEGIN OF ty_id_to_ch,
        id TYPE i,
        ch TYPE ty_char,
      END OF ty_id_to_ch.

    DATA mt_ch_to_id   TYPE HASHED TABLE OF ty_ch_to_id WITH UNIQUE KEY ch.
    DATA mt_id_to_ch   TYPE HASHED TABLE OF ty_id_to_ch WITH UNIQUE KEY id.
    DATA mv_vocab_size TYPE i.
    DATA mv_bos_token  TYPE i.
ENDCLASS.


CLASS zcl_micro_gpt_tokenizer IMPLEMENTATION.
  METHOD zif_micro_gpt_tokenizer~decode.
    FIELD-SYMBOLS <fs_token> LIKE LINE OF it_tokens.
    FIELD-SYMBOLS <fs_map>   LIKE LINE OF mt_id_to_ch.

    LOOP AT it_tokens ASSIGNING <fs_token>.
      IF <fs_token> = mv_bos_token.
        CONTINUE.
      ENDIF.
      ASSIGN mt_id_to_ch[ id = <fs_token> ] TO <fs_map>.
      IF sy-subrc = 0.
        rv_text = rv_text && <fs_map>-ch.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_micro_gpt_tokenizer~encode.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_chr TYPE ty_char.
    FIELD-SYMBOLS <fs_map> LIKE LINE OF mt_ch_to_id.

    APPEND mv_bos_token TO rt_tokens.

    lv_len = strlen( iv_text ).
    WHILE lv_pos < lv_len.
      lv_chr = iv_text+lv_pos(1).
      ASSIGN mt_ch_to_id[ ch = lv_chr ] TO <fs_map>.
      IF sy-subrc = 0.
        APPEND <fs_map>-id TO rt_tokens.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.

    APPEND mv_bos_token TO rt_tokens.
  ENDMETHOD.

  METHOD zif_micro_gpt_tokenizer~get_bos_token.
    rv_token = mv_bos_token.
  ENDMETHOD.

  METHOD zif_micro_gpt_tokenizer~get_vocab_size.
    rv_size = mv_vocab_size + 1. "+BOS
  ENDMETHOD.

  METHOD constructor.
    DATA lt_sorted TYPE SORTED TABLE OF ty_char WITH UNIQUE KEY table_line.
    DATA lv_idx    TYPE i.
    DATA lv_len    TYPE i.
    DATA lv_pos    TYPE i.
    DATA lv_chr    TYPE ty_char.
    FIELD-SYMBOLS <fs_dataset> LIKE LINE OF it_dataset.
    FIELD-SYMBOLS <fs_char>    TYPE ty_char.

    LOOP AT it_dataset ASSIGNING <fs_dataset>.
      lv_len = strlen( <fs_dataset> ).
      lv_pos = 0.
      WHILE lv_pos < lv_len.
        lv_chr = <fs_dataset>+lv_pos(1).
        INSERT lv_chr INTO TABLE lt_sorted.
        lv_pos = lv_pos + 1.
      ENDWHILE.
    ENDLOOP.

    LOOP AT lt_sorted ASSIGNING <fs_char>.
      lv_idx = sy-tabix - 1.
      INSERT VALUE #( ch = <fs_char>
                      id = lv_idx ) INTO TABLE mt_ch_to_id.
      INSERT VALUE #( id = lv_idx
                      ch = <fs_char> ) INTO TABLE mt_id_to_ch.
    ENDLOOP.

    mv_vocab_size = lines( lt_sorted ).
    mv_bos_token  = mv_vocab_size.
  ENDMETHOD.
ENDCLASS.
