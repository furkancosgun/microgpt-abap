CLASS zcl_micro_gpt_optim_adam DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_lr    TYPE f DEFAULT '0.01'
                iv_beta1 TYPE f DEFAULT '0.85'
                iv_beta2 TYPE f DEFAULT '0.99'
                iv_eps   TYPE f DEFAULT '1E-8'.

    INTERFACES zif_micro_gpt_optimizer.

  PRIVATE SECTION.
    DATA mv_lr      TYPE f.
    DATA mv_beta1   TYPE f.
    DATA mv_beta2   TYPE f.
    DATA mv_epsilon TYPE f.
    DATA mt_m       TYPE STANDARD TABLE OF f WITH EMPTY KEY.
    DATA mt_v       TYPE STANDARD TABLE OF f WITH EMPTY KEY.
    DATA mv_t       TYPE i.
ENDCLASS.



CLASS ZCL_MICRO_GPT_OPTIM_ADAM IMPLEMENTATION.


  METHOD constructor.
    mv_lr      = iv_lr.
    mv_beta1   = iv_beta1.
    mv_beta2   = iv_beta2.
    mv_epsilon = iv_eps.
  ENDMETHOD.


  METHOD zif_micro_gpt_optimizer~reset.
    CLEAR mt_m.
    CLEAR mt_v.
    mv_t = 0.
  ENDMETHOD.


  METHOD zif_micro_gpt_optimizer~step.
    DATA lv_m     TYPE f.
    DATA lv_v     TYPE f.
    DATA lv_b1    TYPE f.
    DATA lv_b2    TYPE f.
    DATA lv_index TYPE i.
    DATA lv_grad  TYPE f.
    FIELD-SYMBOLS <fs_value> LIKE LINE OF it_values.

    mv_t = mv_t + 1.

    lv_b1 = 1 - ( mv_beta1 ** mv_t ).
    lv_b2 = 1 - ( mv_beta2 ** mv_t ).

    LOOP AT it_values ASSIGNING <fs_value>.
      lv_index = sy-tabix.
      lv_grad = <fs_value>->mv_gradient.

      IF lines( mt_m ) < lv_index.
        APPEND 0 TO mt_m.
        APPEND 0 TO mt_v.
      ENDIF.

      mt_m[ lv_index ] = ( mv_beta1 * mt_m[ lv_index ] ) + ( ( 1 - mv_beta1 ) * lv_grad ).

      mt_v[ lv_index ] = ( mv_beta2 * mt_v[ lv_index ] ) + ( ( 1 - mv_beta2 ) * ( lv_grad ** 2 ) ).

      lv_m = mt_m[ lv_index ] / lv_b1.
      lv_v = mt_v[ lv_index ] / lv_b2.

      <fs_value>->mv_value    = <fs_value>->mv_value - ( mv_lr * iv_lr_decay * lv_m / ( sqrt( lv_v ) + mv_epsilon ) ).
      <fs_value>->mv_gradient = 0.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
