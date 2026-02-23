CLASS zcl_micro_gpt_value DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_values    TYPE STANDARD TABLE OF REF TO zcl_micro_gpt_value WITH EMPTY KEY.
    TYPES tt_gradients TYPE STANDARD TABLE OF f WITH EMPTY KEY.

    DATA mv_value    TYPE f.
    DATA mv_gradient TYPE f.

    METHODS constructor
      IMPORTING iv_value     TYPE f            OPTIONAL
                iv_gradient  TYPE f            OPTIONAL
                it_values    TYPE tt_values    OPTIONAL
                it_gradients TYPE tt_gradients OPTIONAL.

    CLASS-METHODS scalar
      IMPORTING iv_value           TYPE f
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS add
      IMPORTING io_other           TYPE REF TO zcl_micro_gpt_value
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS mul
      IMPORTING io_other           TYPE REF TO zcl_micro_gpt_value
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS neg
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS sub
      IMPORTING io_other           TYPE REF TO zcl_micro_gpt_value
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS pow
      IMPORTING iv_exp             TYPE f
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS div
      IMPORTING io_other           TYPE REF TO zcl_micro_gpt_value
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS logv
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS relu
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    METHODS backward.

    METHODS zero_gradient.

    CLASS-METHODS dot_product
      IMPORTING it_values_a        TYPE tt_values
                it_values_b        TYPE tt_values
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_micro_gpt_value.

    CLASS-METHODS fused_softmax
      IMPORTING it_values        TYPE tt_values
      RETURNING VALUE(rt_values) TYPE tt_values.

    CLASS-METHODS fused_log_softmax
      IMPORTING it_values        TYPE tt_values
      RETURNING VALUE(rt_values) TYPE tt_values.

  PRIVATE SECTION.
    DATA mt_values    TYPE tt_values.
    DATA mt_gradients TYPE tt_gradients.
ENDCLASS.


CLASS zcl_micro_gpt_value IMPLEMENTATION.
  METHOD add.
    ro_instance = NEW #( iv_value     = mv_value + io_other->mv_value
                         it_values    = VALUE #( ( me ) ( io_other ) )
                         it_gradients = VALUE #( ( CONV f( 1 ) )
                                                 ( CONV f( 1 ) ) ) ).
  ENDMETHOD.

  METHOD backward.
    TYPES:
      BEGIN OF ty_stack_item,
        value   TYPE REF TO zcl_micro_gpt_value,
        visited TYPE abap_bool,
      END OF ty_stack_item.

    DATA lt_values TYPE STANDARD TABLE OF REF TO zcl_micro_gpt_value.

    DATA lt_visit  TYPE HASHED TABLE OF REF TO zcl_micro_gpt_value WITH UNIQUE KEY table_line.
    DATA lt_stack  TYPE STANDARD TABLE OF ty_stack_item.
    DATA ls_stack  LIKE LINE OF lt_stack.
    DATA lv_stack  TYPE i.
    DATA lv_total  TYPE i.
    DATA lv_child  TYPE i.
    FIELD-SYMBOLS <fs_value> LIKE LINE OF lt_values.
    FIELD-SYMBOLS <fs_child> LIKE LINE OF lt_values.

    lv_stack = 1.
    APPEND VALUE #( value   = me
                    visited = abap_false ) TO lt_stack.

    WHILE lv_stack > 0.
      ls_stack = lt_stack[ lv_stack ].
      DELETE lt_stack INDEX lv_stack.
      lv_stack = lv_stack - 1.

      IF ls_stack-visited = abap_true.
        APPEND ls_stack-value TO lt_values.
        CONTINUE.
      ENDIF.

      INSERT ls_stack-value INTO TABLE lt_visit.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_stack = lv_stack + 1.
      APPEND VALUE #( value   = ls_stack-value
                      visited = abap_true ) TO lt_stack.

      LOOP AT ls_stack-value->mt_values ASSIGNING <fs_value>.
        IF NOT line_exists( lt_visit[ table_line = <fs_value> ] ).
          lv_stack = lv_stack + 1.
          APPEND VALUE #( value   = <fs_value>
                          visited = abap_false ) TO lt_stack.
        ENDIF.
      ENDLOOP.
    ENDWHILE.

    mv_gradient = 1.

    lv_total = lines( lt_values ).

    WHILE lv_total > 0.
      ASSIGN lt_values[ lv_total ] TO <fs_value>.
      lv_total = lv_total - 1.

      LOOP AT <fs_value>->mt_values ASSIGNING <fs_child>.
        lv_child = sy-tabix.
        <fs_child>->mv_gradient = <fs_child>->mv_gradient + ( <fs_value>->mv_gradient * <fs_value>->mt_gradients[
                                                                                            lv_child ] ).
      ENDLOOP.
    ENDWHILE.
  ENDMETHOD.

  METHOD div.
    ro_instance = mul( io_other->pow( -1 ) ).
  ENDMETHOD.

  METHOD dot_product.
    DATA lv_sum       TYPE f.
    DATA lt_values    TYPE tt_values.
    DATA lt_gradients TYPE tt_gradients.
    FIELD-SYMBOLS <fs_value_a> LIKE LINE OF it_values_a.
    FIELD-SYMBOLS <fs_value_b> LIKE LINE OF it_values_b.

    LOOP AT it_values_a ASSIGNING <fs_value_a>.
      ASSIGN it_values_b[ sy-tabix ] TO <fs_value_b>.

      lv_sum = lv_sum + ( <fs_value_a>->mv_value * <fs_value_b>->mv_value ).

      APPEND <fs_value_a> TO lt_values.
      APPEND <fs_value_b> TO lt_values.

      APPEND <fs_value_b>->mv_value TO lt_gradients.
      APPEND <fs_value_a>->mv_value TO lt_gradients.
    ENDLOOP.

    ro_instance = NEW zcl_micro_gpt_value( iv_value     = lv_sum
                                           it_values    = lt_values
                                           it_gradients = lt_gradients ).
  ENDMETHOD.

  METHOD fused_softmax.
    DATA lt_exps      TYPE STANDARD TABLE OF f.
    DATA lt_probs     TYPE STANDARD TABLE OF f.
    DATA lv_exp       TYPE f.
    DATA lv_sum_exp   TYPE f.
    DATA lv_max_val   TYPE f.
    DATA lv_lines     TYPE i.
    DATA lt_gradients TYPE tt_gradients.
    DATA lv_i         TYPE i.
    DATA lv_prob_i    TYPE f.
    DATA lv_j         TYPE i.
    DATA lv_prob_j    TYPE f.
    FIELD-SYMBOLS <fs_value> LIKE LINE OF it_values.

    lv_lines = lines( it_values ).

    IF lv_lines <= 0.
      RETURN.
    ENDIF.

    LOOP AT it_values ASSIGNING <fs_value>.
      IF <fs_value>->mv_value > lv_max_val.
        lv_max_val = <fs_value>->mv_value.
      ENDIF.
    ENDLOOP.

    LOOP AT it_values ASSIGNING <fs_value>.
      lv_exp = exp( <fs_value>->mv_value - lv_max_val ).
      APPEND lv_exp TO lt_exps.
      lv_sum_exp = lv_sum_exp + lv_exp.
    ENDLOOP.

    LOOP AT lt_exps INTO DATA(lv_e).
      APPEND ( lv_e / lv_sum_exp ) TO lt_probs.
    ENDLOOP.

    DO lv_lines TIMES.
      lv_i = sy-index.
      lv_prob_i = lt_probs[ lv_i ].

      CLEAR lt_gradients.
      DO lv_lines TIMES.
        lv_j = sy-index.
        lv_prob_j = lt_probs[ lv_j ].

        IF lv_i = lv_j.
          APPEND ( lv_prob_i * ( 1 - lv_prob_j ) ) TO lt_gradients.
        ELSE.
          APPEND ( -1 * lv_prob_i * lv_prob_j ) TO lt_gradients.
        ENDIF.
      ENDDO.

      APPEND NEW zcl_micro_gpt_value( iv_value     = lv_prob_i
                                      it_values    = it_values
                                      it_gradients = lt_gradients ) TO rt_values.
    ENDDO.
  ENDMETHOD.

  METHOD fused_log_softmax.
    DATA lt_exps        TYPE STANDARD TABLE OF f.
    DATA lt_probs       TYPE STANDARD TABLE OF f.
    DATA lv_exp         TYPE f.
    DATA lv_sum_exp     TYPE f.
    DATA lv_max_val     TYPE f.
    DATA lv_lines       TYPE i.
    DATA lt_gradients   TYPE tt_gradients.
    DATA lv_i           TYPE i.
    DATA lv_prob_i      TYPE f.
    DATA lv_j           TYPE i.
    DATA lv_prob_j      TYPE f.
    DATA lv_log_sum_exp TYPE f.
    FIELD-SYMBOLS <fs_value> LIKE LINE OF it_values.

    lv_lines = lines( it_values ).

    IF lv_lines <= 0.
      RETURN.
    ENDIF.

    LOOP AT it_values ASSIGNING <fs_value>.
      IF <fs_value>->mv_value > lv_max_val.
        lv_max_val = <fs_value>->mv_value.
      ENDIF.
    ENDLOOP.

    LOOP AT it_values ASSIGNING <fs_value>.
      lv_exp = exp( <fs_value>->mv_value - lv_max_val ).
      APPEND lv_exp TO lt_exps.
      lv_sum_exp = lv_sum_exp + lv_exp.
    ENDLOOP.

    lv_log_sum_exp = log( lv_sum_exp ).

    LOOP AT lt_exps INTO DATA(lv_e).
      APPEND ( lv_e / lv_sum_exp ) TO lt_probs.
    ENDLOOP.

    DO lv_lines TIMES.
      lv_i = sy-index.
      lv_prob_i = ( it_values[ lv_i ]->mv_value - lv_max_val ) - lv_log_sum_exp.

      CLEAR lt_gradients.
      DO lv_lines TIMES.
        lv_j = sy-index.
        lv_prob_j = lt_probs[ lv_j ].

        IF lv_i = lv_j.
          APPEND ( 1 - lv_prob_j ) TO lt_gradients.
        ELSE.
          APPEND ( -1 * lv_prob_j ) TO lt_gradients.
        ENDIF.
      ENDDO.

      APPEND NEW zcl_micro_gpt_value( iv_value     = lv_prob_i
                                      it_values    = it_values
                                      it_gradients = lt_gradients ) TO rt_values.
    ENDDO.
  ENDMETHOD.

  METHOD logv.
    ro_instance = NEW zcl_micro_gpt_value( iv_value     = log( mv_value )
                                           it_values    = VALUE #( ( me ) )
                                           it_gradients = VALUE #( ( 1 / mv_value ) ) ).
  ENDMETHOD.

  METHOD mul.
    ro_instance = NEW zcl_micro_gpt_value( iv_value     = mv_value * io_other->mv_value
                                           it_values    = VALUE #( ( me ) ( io_other ) )
                                           it_gradients = VALUE #( ( io_other->mv_value ) ( me->mv_value ) ) ).
  ENDMETHOD.

  METHOD neg.
    ro_instance = mul( scalar( -1 ) ).
  ENDMETHOD.

  METHOD pow.
    ro_instance = NEW zcl_micro_gpt_value( iv_value     = mv_value ** iv_exp
                                           it_values    = VALUE #( ( me ) )
                                           it_gradients = VALUE #( ( iv_exp * ( me->mv_value ** ( iv_exp - 1 ) ) ) ) ).
  ENDMETHOD.

  METHOD scalar.
    ro_instance = NEW zcl_micro_gpt_value( iv_value = iv_value ).
  ENDMETHOD.

  METHOD sub.
    ro_instance = add( io_other->neg( ) ).
  ENDMETHOD.

  METHOD zero_gradient.
    mv_gradient = 0.
  ENDMETHOD.

  METHOD constructor.
    mv_value = iv_value.
    mv_gradient = iv_gradient.
    mt_values = it_values.
    mt_gradients = it_gradients.
  ENDMETHOD.

  METHOD relu.
    ro_instance = NEW zcl_micro_gpt_value(
                          iv_value     = COND #( WHEN me->mv_value > 0 THEN me->mv_value ELSE 0 )
                          it_values    = VALUE #( ( me ) )
                          it_gradients = VALUE #( ( COND #( WHEN me->mv_value > 0 THEN 1 ELSE 0 ) ) ) ).
  ENDMETHOD.
ENDCLASS.
