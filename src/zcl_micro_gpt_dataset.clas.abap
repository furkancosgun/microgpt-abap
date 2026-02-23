CLASS zcl_micro_gpt_dataset DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_micro_gpt_dataset.

    CLASS-METHODS create_from_file
      IMPORTING iv_file            TYPE string
      RETURNING VALUE(ro_instance) TYPE REF TO zif_micro_gpt_dataset.

    CLASS-METHODS create_from_string
      IMPORTING iv_string          TYPE string
      RETURNING VALUE(ro_instance) TYPE REF TO zif_micro_gpt_dataset.

    CLASS-METHODS create_from_string_table
      IMPORTING it_string_table    TYPE zif_micro_gpt_dataset=>tt_string_table
      RETURNING VALUE(ro_instance) TYPE REF TO zif_micro_gpt_dataset.

  PRIVATE SECTION.
    METHODS constructor
      IMPORTING it_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.

    DATA mt_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.
ENDCLASS.


CLASS zcl_micro_gpt_dataset IMPLEMENTATION.
  METHOD zif_micro_gpt_dataset~load.
    rt_dataset = mt_dataset.
  ENDMETHOD.

  METHOD create_from_file.
    DATA lt_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.

    cl_gui_frontend_services=>gui_upload( EXPORTING  filename = iv_file
                                                     filetype = 'ASC'
                                          CHANGING   data_tab = lt_dataset
                                          EXCEPTIONS OTHERS   = 1 ).
    ro_instance = create_from_string_table( lt_dataset ).
  ENDMETHOD.

  METHOD create_from_string.
    DATA lt_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.

    SPLIT iv_string AT cl_abap_char_utilities=>newline INTO TABLE lt_dataset.

    ro_instance = create_from_string_table( lt_dataset ).
  ENDMETHOD.

  METHOD create_from_string_table.
    DATA lt_dataset TYPE zif_micro_gpt_dataset=>tt_string_table.
    FIELD-SYMBOLS <fs_dataset> LIKE LINE OF it_string_table.

    lt_dataset = it_string_table.

    LOOP AT lt_dataset ASSIGNING <fs_dataset>.
      <fs_dataset> = condense( <fs_dataset> ).
    ENDLOOP.

    DELETE lt_dataset WHERE table_line IS INITIAL.

    ro_instance = NEW zcl_micro_gpt_dataset( it_dataset = lt_dataset ).
  ENDMETHOD.

  METHOD constructor.
    mt_dataset = it_dataset.
  ENDMETHOD.
ENDCLASS.
