INTERFACE zif_micro_gpt_module
  PUBLIC.

  METHODS parameters
    RETURNING VALUE(rt_parameters) TYPE zcl_micro_gpt_value=>tt_values.

  METHODS zero_gradients.
ENDINTERFACE.
