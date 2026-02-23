INTERFACE zif_micro_gpt_dataset
  PUBLIC.

  TYPES tt_string_table TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  METHODS load
    RETURNING VALUE(rt_dataset) TYPE tt_string_table.
ENDINTERFACE.
