create or replace PACKAGE  VENTA.pkg_sweb_five_mant_correos IS

  -- Author  : LAQS
  -- Created : 31/01/2018 09:18:12 a.m.
  -- Purpose : procedimientos para envio de correos

  PROCEDURE sp_gen_plantilla_correo_hfdv
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_adjunt
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_aequip
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /*--------------------------------------------------------------------------
      Nombre : SP_GEN_PLANTILLA_CORREO_SFACTU
      Proposito : Genera la estructura del correo para los destinatarios.
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor             Descripcion
      17/08/2018   SOPORTELEGADOS    REQ - 86434 Modificacion del amrmado de la estructura para
                   añardir el bloque de Cliente Facturacion, Cliente Propietario y Cliente Usuario.
                   Se creó la variable de entrada p_nombre_entidad. La modificación empieza en la línea
                   1518 hasta 1543.

  ----------------------------------------------------------------------------*/

  PROCEDURE sp_gen_plantilla_correo_sfactu
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE DEFAULT NULL,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE DEFAULT NULL,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE DEFAULT NULL
  );

  PROCEDURE sp_gen_plantilla_correo_nlafit
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_cestad
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_bonos
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_aprbon
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_obtener_plantilla
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_tipo_ref_proc IN VARCHAR2,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos   OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );

  PROCEDURE sp_actualizar_envio
  (
    p_cod_correo_prof   IN VARCHAR2,
    p_tipo_ref_proc     IN VARCHAR2,
    p_num_ficha_vta_veh IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_gen_plantilla_correo_cfich
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_CORREO
    Proposito : registra la plantilla de los correos
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    31/01/2018     LAQS      creacion de correos  
  ----------------------------------------------------------------------------*/

  PROCEDURE sp_inse_correo
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_CORREOS_LAFIT
    Proposito : lista de correos lafit
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    08/02/2018     LAQS      creacion de correos  
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_correos_lafit
  (
    p_ret_correos OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  );

  PROCEDURE sp_corro_auto
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    x_auto_env          VARCHAR2,
    x_auto_apro         VARCHAR2,

    x_fec_usuario_aut DATE,
    p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    --  p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
  /*-----------------------------------------------------------------------------
    Nombre : fun_obt_plant_correo
    Proposito :  Obtiene la Platilla de Correo 
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    13/05/2019     ASALAS        REQ-88210 Correo Automatico GPS 
  ----------------------------------------------------------------------------*/
  FUNCTION fun_obt_plant_correo(p_cod_plan_reg NUMBER) RETURN CLOB;

  /*-----------------------------------------------------------------------------
    Nombre      : FUN_LIST_CARAC_CORR
    Proposito   :  Obtiene la Platilla de Correo 
    Referencias :
    Parametros  :
    Log de Cambios
    Fecha          Autor          Descripcion
    30/04/2020  Soporte Legados   REQ.89449 - Cambia el valor del carácter de las
                                  tildes al código ascii.  
  ----------------------------------------------------------------------------*/  
  FUNCTION FUN_LIST_CARAC_CORR (P_VAL_CARA IN VARCHAR2) RETURN VARCHAR2;

END pkg_sweb_five_mant_correos; 
