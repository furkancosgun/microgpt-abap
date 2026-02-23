INTERFACE zif_micro_gpt_optimizer
  PUBLIC.
  METHODS step
    IMPORTING it_values   TYPE zcl_micro_gpt_value=>tt_values
              iv_lr_decay TYPE f.

  METHODS reset.

ENDINTERFACE.
