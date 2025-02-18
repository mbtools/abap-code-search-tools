"! <p class="shorttext synchronized">Factory to create matchers</p>
CLASS zcl_adcoset_matcher_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Creates matcher for the given type and pattern</p>
    CLASS-METHODS create_matcher
      IMPORTING
        !type         TYPE zif_adcoset_ty_global=>ty_matcher_type
        pcre_settings TYPE zif_adcoset_ty_global=>ty_pcre_regex_settings OPTIONAL
        !pattern      TYPE zif_adcoset_ty_global=>ty_pattern
        ignore_case   TYPE abap_bool                                     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zif_adcoset_pattern_matcher
      RAISING
        zcx_adcoset_no_matcher
        cx_sy_regex.

    "! <p class="shorttext synchronized">Creates matchers from pattern range</p>
    CLASS-METHODS create_matchers
      IMPORTING
        pattern_config TYPE zif_adcoset_ty_global=>ty_pattern_config
      RETURNING
        VALUE(result)  TYPE zif_adcoset_pattern_matcher=>ty_ref_tab
      RAISING
        zcx_adcoset_static_error.

  PRIVATE SECTION.
    CLASS-DATA pcre_supported TYPE abap_bool VALUE abap_undefined.
ENDCLASS.


CLASS zcl_adcoset_matcher_factory IMPLEMENTATION.
  METHOD create_matcher.
    result = SWITCH #( type

                       WHEN zif_adcoset_c_global=>c_matcher_type-posix_regex THEN
                         NEW zcl_adcoset_posix_regex_matchr( pattern     = pattern
                                                             ignore_case = ignore_case )

                       WHEN zif_adcoset_c_global=>c_matcher_type-pcre THEN
                         NEW zcl_adcoset_pcre_matcher( pattern     = pattern
                                                       settings    = pcre_settings
                                                       ignore_case = ignore_case )

                       WHEN zif_adcoset_c_global=>c_matcher_type-substring THEN
                         NEW zcl_adcoset_substring_matcher( pattern     = pattern
                                                            ignore_case = ignore_case )

                       ELSE
                         THROW zcx_adcoset_no_matcher( ) ).
  ENDMETHOD.

  METHOD create_matchers.
    LOOP AT pattern_config-patterns ASSIGNING FIELD-SYMBOL(<pattern>).
      TRY.
          result = VALUE #( BASE result
                            ( create_matcher( type          = pattern_config-matcher_type
                                              pattern       = <pattern>
                                              pcre_settings = pattern_config-pcre_settings
                                              ignore_case   = pattern_config-ignore_case ) ) ).
        CATCH zcx_adcoset_no_matcher
              cx_sy_regex INTO DATA(matcher_error).
          RAISE EXCEPTION TYPE zcx_adcoset_static_error
            EXPORTING previous = matcher_error.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
