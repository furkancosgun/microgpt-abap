INTERFACE zif_micro_gpt_tokenizer
  PUBLIC.

  TYPES tt_tokens TYPE STANDARD TABLE OF i WITH EMPTY KEY.

  METHODS encode
    IMPORTING iv_text          TYPE string
    RETURNING VALUE(rt_tokens) TYPE tt_tokens.

  METHODS decode
    IMPORTING it_tokens      TYPE tt_tokens
    RETURNING VALUE(rv_text) TYPE string.

  METHODS get_vocab_size
    RETURNING VALUE(rv_size) TYPE i.

  METHODS get_bos_token
    RETURNING VALUE(rv_token) TYPE i.
ENDINTERFACE.
