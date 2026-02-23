CLASS zcl_micro_gpt_kv_cache DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_layer_cache TYPE STANDARD TABLE OF zcl_micro_gpt_value=>tt_values WITH EMPTY KEY.

    DATA mt_keys   TYPE STANDARD TABLE OF tt_layer_cache WITH EMPTY KEY.
    DATA mt_values TYPE STANDARD TABLE OF tt_layer_cache WITH EMPTY KEY.

    METHODS constructor IMPORTING iv_n_layers TYPE i.
    METHODS reset.
ENDCLASS.


CLASS zcl_micro_gpt_kv_cache IMPLEMENTATION.
  METHOD constructor.
    DO iv_n_layers TIMES.
      APPEND VALUE tt_layer_cache( ) TO mt_keys.
      APPEND VALUE tt_layer_cache( ) TO mt_values.
    ENDDO.
  ENDMETHOD.

  METHOD reset.
    CLEAR: mt_keys,
           mt_values.
  ENDMETHOD.
ENDCLASS.
