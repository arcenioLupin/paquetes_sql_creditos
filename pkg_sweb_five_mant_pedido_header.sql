create or replace PACKAGE VENTA.pkg_sweb_five_mant_pedido AS

  PROCEDURE sp_list_pedi_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  PROCEDURE sp_list_pedi_pedi_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  /*-----------------------------------------------------------------------------
      Nombre : sp_list_pedi_usocolr_fv
      Proposito : Lista los colores del pedido de la ficha de venta
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor               Descripcion
      28/09/2018   SOPORTELEGADOS      REQ 86868 Lista ordenado los colores de los pedidos
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_pedi_usocolr_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  PROCEDURE sp_list_pedi_vali_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  PROCEDURE sp_list_pedi_trac_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  PROCEDURE sp_list_pedi_fact_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_grabar_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_ind_inactivo         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_vendedor             IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  PROCEDURE sp_inse_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  PROCEDURE sp_actu_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_ind_inactivo         IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  PROCEDURE sp_obte_info_fact
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_anul_pedido_veh
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_motivo           IN VARCHAR2,
    p_observa_desasigna    IN VARCHAR2,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  PROCEDURE sp_actu_asig_defi
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_tipo_ref_proc        IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_ind_asig_def         IN VARCHAR2,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_vendedor             IN VARCHAR2,
    p_cod_filial           IN VARCHAR2,
    p_cod_propietario      IN VARCHAR2,
    p_id_usuario           IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_correo           IN VARCHAR2,
    p_fechacompromiso      IN VARCHAR2,
    p_fechaasidef          IN VARCHAR2,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  /*--------------------------------------------------------------------------
      Nombre : SP_LIST_SOLI_FACT
      Proposito : Obtiene información de solicitud de facturación
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   LVALDERRAMA   Creacion
      07/12/2017   BFPALACIOS    Modificacion
    06/08/2018   SOPORTELEGADOS REQ-86491 Modificacion el armado del cursor p_ret_cursor
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_SOLI_FACT
     Proposito : registra la solicitud de facturacion de un pedido
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     22/06/2017   LVALDERRAMA   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_doc_fact      IN vve_ficha_vta_pedido_veh.cod_doc_fact%TYPE,
    p_ind_sol_fact      IN vve_ficha_vta_pedido_veh.ind_sol_fact%TYPE,
    p_obs_facturacion   IN vve_ficha_vta_pedido_veh.obs_facturacion%TYPE,
    p_tipo_sol_fact     IN vve_ficha_vta_pedido_veh.tipo_sol_fact%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario        IN vve_soli_fact_vehi.cod_usuario_crea%TYPE,
    --P_COD_ID_USUARIO        IN sistemas.usuarios.co_usuario%TYPE,
    -- SE AÑADE PARA INSRRTAR UNA NUEVA SOLICITUD DE FACTURACION
    --P_COD_SOLI_FACT_VEHI    IN VVE_SOLI_FACT_VEHI.COD_SOLI_FACT_VEHI%TYPE,
    p_cod_cia           IN vve_soli_fact_vehi.cod_cia%TYPE,
    p_cod_prov          IN vve_soli_fact_vehi.cod_prov%TYPE,
    p_cod_perso_dir     IN vve_soli_fact_vehi.cod_perso_dir%TYPE,
    p_num_reg_dir       IN vve_soli_fact_vehi.num_reg_dir%TYPE,
    p_cod_tipo_pago     IN vve_soli_fact_vehi.cod_tipo_pago%TYPE,
    p_cod_tipo_soli     IN vve_soli_fact_vehi.cod_tipo_soli%TYPE,
    p_cod_entidad_finan IN vve_soli_fact_vehi.cod_entidad_finan%TYPE,

    p_obs_sol_facturacion  IN vve_soli_fact_vehi.obs_sol_facturacion%TYPE,
    p_ind_inactivo         IN VARCHAR2, --IN VVE_SOLI_FACT_VEHI.IND_INACTIVO%TYPE,
    p_nur_ficha_vta_pedido IN vve_soli_fact_vehi.nur_ficha_vta_pedido%TYPE,
    p_ret_codigo_solicitud OUT NUMBER,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_CLI_CONTACTO
     Proposito : registra contacto de un cliente de facturacion
     Referencias :
     Parametros :P_COD_CONTACTO    ---> codigo de contacto
                 P_COD_CLIENTE     ---> codigo de cliente
                 P_NOM_COMPLETO    ---> nombre completo de contacto
                 P_DIR_CORREO      ---> direccion de correo de contacto
                 P_IND_INACTIVO    ---> indicador de inactivo
                 P_COD_USUA_SID    ---> codigo de usuario
     Log de Cambios
     Fecha        Autor         Descripcion
     22/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
     Nombre : SP_INSE_CLI_CONTACTO
     Proposito : Inserta contactos asociado a un cliente de facturacion
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     23/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_inse_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
     Nombre : SP_ACTU_CLI_CONTACTO
     Proposito : Actualiza los pedidos pertenecientes a la ficha
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     23/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_actu_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_SOLI_FACT_TRAN
     Proposito : registra la solicitud de facturacion de un pedido en tránsito
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     07/07/2017   AVILCA        Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_soli_fact_tran
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia           IN vve_ficha_vta_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_ficha_vta_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_id_usuario    IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  FUNCTION f_valida_ped_entregado(p_num_ficha_vta_veh vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE)
    RETURN BOOLEAN;

  FUNCTION fun_valida_cliente_pedido
  (
    p_cod_cia        arcgmc.no_cia%TYPE,
    p_cod_prov       v_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh v_pedido_veh.num_pedido_veh%TYPE,
    p_men_sal        OUT VARCHAR2
  ) RETURN BOOLEAN;

  PROCEDURE sp_list_pedi
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_obtener_info_fact
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_list_est_soli_cred
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  );

  PROCEDURE sp_list_docu_fact
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  );

  /********************************************************************************
    Nombre:     FUN_PED_MODELO
    Proposito:  retorna la descripcion del modelo de un pedido
    Referencias:
    Parametros: P_COD_AREA_VTA      ---> codigo del area de venta
                P_IND_NUEVO_USADO   ---> indicador si es nuevo o usado
                P_COD_FAMILIA_VEH   ---> codigo de familia.
                P_COD_MARCA         ---> Código marca.
                P_COD_BAUMUSTER     ---> codigo baumuster.
                P_COD_CONFIG_VEH    ---> codigo configuracion.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        17/07/2017  LVALDERRAMA        Creación del procedure.
  ********************************************************************************/
  FUNCTION fun_ped_modelo
  (
    p_cod_area_vta    vve_pedido_veh.cod_area_vta%TYPE,
    p_ind_nuevo_usado vve_pedido_veh.ind_nuevo_usado%TYPE,
    p_cod_familia_veh vve_pedido_veh.cod_familia_veh%TYPE,
    p_cod_marca       vve_pedido_veh.cod_marca%TYPE,
    p_cod_baumuster   vve_pedido_veh.cod_baumuster%TYPE,
    p_cod_config_veh  vve_pedido_veh.cod_config_veh%TYPE
  ) RETURN VARCHAR2;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_FACT_FICHA_VENTA
      Proposito : Lista de todos los pedidos de facturacion
      Referencias :
      Parametros :
          P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_RET_CURSOR        ---> Lista de pedidos.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
        21/11/2017   ARAMOS     Modificacion

  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_fact_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN VARCHAR2,
    p_limitsup          IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
      Nombre : SP_GRABAR_FACT_FICHA_VENTA
      Proposito : Lista de todos los pedidos de facturacion
      Referencias :
      Parametros :
                  P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_NUM_PROF_VEH      ---> Número de proforma.
                  P_NUM_PEDIDO_VEH    ---> Número de pedido.
                  COD_CLIE            ---> Codigo de usuario facturacion.
                  COD_PROPIETARIO_VEH ---> Codigo de usuario propietario.
                  COD_USUARIO_VEH     ---> Codigo de usuario usuario.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
        21/11/2017   ARAMOS     Modificacion

  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_fact_ficha_venta
  (
    p_num_ficha_vta_veh   IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh        IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh      IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie            IN vve_ficha_vta_pedido_veh.cod_perso_dir%TYPE,
    p_cod_propietario_veh IN vve_ficha_vta_pedido_veh.cod_perso_prop%TYPE,
    p_cod_usuario_veh     IN vve_ficha_vta_pedido_veh.cod_perso_usu%TYPE,
    p_id_usuario          IN vve_ficha_vta_pedido_veh.cod_perso_prop%TYPE,
    p_cod_usuario         IN vve_ficha_vta_pedido_veh.cod_perso_usu%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR
  );

  /********************************************************************************
      Nombre:     SP_INSE_CORREO_SOLI_FACTURACION
      Proposito:  Registra en la tabla Correo las solicitudes de facturacion
      Referencias:
      Parametros: P_NUM_FICHA_VTA_VEH  ---> Numero de ficha de venta.
                  P_DESTINATARIOS      ---> correo destinatario.
                  P_COPIA              ---> Lista de correos CC.
                  P_ASUNTO             ---> Asunto.
                  P_CUERPO             ---> Contenido del correo.
                  P_CORREOORIGEN       ---> Correo remitente.
                  P_COD_USUA_SID       ---> Código del usuario.
                  P_COD_USUA_WEB       ---> Id del usuario.
                  P_RET_ESTA           ---> Estado del proceso.
                  P_RET_MENS           ---> Resultado del proceso.
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0        12/12/2017  BPALACIOS        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_inse_correo_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
      Nombre:     SP_GEN_CORREO_SOLI_FACT
      Proposito:  Proceso que me permite Obtener los correos de los usuarios y generar la plantilla del correo.
      Referencias:
      Parametros: P_NUM_FICHA_VTA_VEH   ---> Numero de Ficha de Venta
                  P_NUM_PEDIDO_VEH      ---> Numero de Pedido
                  P_TIPO_CORREO         ---> Tipo de Correo.
                  P_DESTINATARIOS       ---> Lista de direcciones de los destinatarios,
                  P_ID_USUARIO          ---> Id del usuario.
                  P_TIPO_REF_PROC       ---> Tipo de Referencia del proceso.
                  P_COD_PER_DIR         ---> Codigo Personal de Direccion.
                  P_DIRECCION           ---> Direccion de la empresa.
                  P_CONTACTOS_ADIC      ---> Contactos Adicionales.
                  P_DOCUMENTO           ---> Factura o Boleta.
                  P_TIPO_SOLI           ---> Tipo de solicitud.
                  P_TIPO_PAGO           ---> Tipo de pago.
                  P_NOMBRE_ENTIDAD      ---> Nombre de le entidad.
                  P_OBSERVACIONES       ---> Observaciones
                  P_NOMBRE_CLIENTE      ---> Nombre del cliente.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      TIPO DE CORREO: 1 Solicitud Facturacion

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         01/12/2017  BPALACIOS       Genera la plantilla y lo guarda
                                              para enviar en el cuerpo del correo.
  *********************************************************************************/

  PROCEDURE sp_gen_correo_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_tipo_correo       IN VARCHAR2,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_cod_per_dir       IN VARCHAR2, -- OBTENGO NOMBRE, RUC, DNI DEL CLIENTE
    p_direccion         IN VARCHAR2,
    p_contactos_adic    IN VARCHAR2,
    p_documento         IN VARCHAR2,
    p_tipo_soli         IN VARCHAR2,
    p_tipo_pago         IN VARCHAR2,
    p_nombre_entidad    IN VARCHAR2,
    p_observaciones     IN VARCHAR2,

    p_nombre_cliente IN VARCHAR2,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  FUNCTION fn_cod_moneda_prof(p_num_prof_veh VARCHAR) RETURN VARCHAR2;

  FUNCTION fn_val_pre_veh(p_num_prof_veh VARCHAR) RETURN NUMBER;

  PROCEDURE sp_alerta_correo_warrant
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie          IN VARCHAR2,
    p_tipo_ref_proc     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_alerta_correo_line_up
  (
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE DEFAULT NULL
  );

  PROCEDURE sp_solic_desaduanaje
  (
    p_num_ficha_vta_veh   IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_area_vta        IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_cia             IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov            IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh      IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie            IN vve_pedido_veh.cod_clie%TYPE,
    p_cod_propietario_veh IN vve_pedido_veh.cod_propietario_veh%TYPE,
    p_tipo_prof_veh       IN vve_proforma_veh.tip_prof_veh%TYPE,
    p_tipo_ref_proc       IN VARCHAR2,
    p_cod_usua_sid        IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR2
  );

  PROCEDURE sp_list_pedi_asig(

                              p_num_ficha_vta_veh    IN VARCHAR2,
                              p_num_prof_veh         IN VARCHAR2,
                              p_num_pedido_veh       IN vve_pedido_veh.num_pedido_veh%TYPE,
                              p_num_chasis           IN vve_pedido_veh.num_chasis%TYPE,
                              p_cod_ubica_pedido_veh IN vve_pedido_veh.cod_ubica_pedido_veh%TYPE,
                              p_cod_situ_pedido      IN vve_pedido_veh.cod_situ_pedido%TYPE,
                              p_sku_sap              IN vve_config_veh.sku_sap%TYPE,
                              p_num_placa_veh        IN vve_pedido_veh.num_placa_veh%TYPE,
                              p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
                              p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                              p_lim_infe             NUMBER,
                              p_lim_supe             NUMBER,
                              p_tab                  OUT SYS_REFCURSOR,
                              p_tot_regi             OUT NUMBER,
                              p_ret_esta             OUT NUMBER,
                              p_ret_mens             OUT VARCHAR);

  /********************************************************************************
      Nombre:     SP_LISTA_MOTIVO_DESASIGNACION
      Proposito:  Proceso que lista los motivos de desasignacion.
      Referencias:
      Parametros: P_COD_AREA_VTA  ---> Código de Referencia del proceso.
                  P_RET_CURSOR          ---> lista de items.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         26/01/2018  LAQS           Creación del procedure.
  *********************************************************************************/
  PROCEDURE sp_lista_motivo_desasignacion
  (
    p_cod_area_vta VARCHAR2,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
     Nombre : FN_FACT_TRANSITO_FV
     Proposito : Valida si los pedidos de la ficha estan en estado en transito.
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     06/02/2018   ARAMOS        Creacion
  ----------------------------------------------------------------------------*/

  FUNCTION fn_fact_transito_fv
  (
    p_cod_cia               vve_ficha_vta_pedido_veh.cod_cia%TYPE,
    p_cod_prov              vve_ficha_vta_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh        vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_estado_pedido_veh vve_pedido_veh.cod_estado_pedido_veh%TYPE
  ) RETURN NUMBER;

  /*PROCEDURE sp_list_pedi_fifo
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh         IN vve_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh       IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_num_chasis           IN vve_pedido_veh.num_chasis%TYPE,
    p_cod_ubica_pedido_veh IN vve_pedido_veh.cod_ubica_pedido_veh%TYPE,
    p_cod_situ_pedido      IN vve_pedido_veh.cod_situ_pedido%TYPE,
    p_sku_sap              IN vve_config_veh.sku_sap%TYPE,
    p_num_placa_veh        IN vve_pedido_veh.num_placa_veh%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_lim_infe             NUMBER,
    p_lim_supe             NUMBER,
    p_tab                  OUT SYS_REFCURSOR,
    p_tot_regi             OUT NUMBER,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR
  );*/

  PROCEDURE sp_envia_correo_autorizacion
  (
    p_auto_env          IN VARCHAR2,
    p_auto_apro         IN VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_pedido_veh.cod_filial%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_fec_usuario_aut   IN DATE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_envia_correo_vendedor
  (
    p_mail              IN usuarios.di_correo%TYPE,
    p_nombre            IN VARCHAR2,
    p_vendedor          IN VARCHAR2,
    p_jefe              IN VARCHAR2,
    p_asunto            IN VARCHAR2,
    p_mensaje           IN VARCHAR2,
    p_auto_env          IN VARCHAR2,
    p_auto_apro         IN VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_pedido_veh.cod_filial%TYPE,
    p_cod_tipo_pago     IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE

  );
  /*-----------------------------------------------------------------------------
      Nombre : SP_HIS_FECHA_COMPROMISO
      Proposito : Movimiento de pedidos, numero de documento y ventas,historial del pedido
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_mantenimiento_hist
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_pedido_veh    IN VARCHAR2,
    p_cod_cia           IN VARCHAR2,
    p_cod_prov          IN VARCHAR2,
    p_tipodocumento     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cursor_mov        OUT SYS_REFCURSOR,
    p_cursor_doc        OUT SYS_REFCURSOR,
    p_cursor_hist       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
        Nombre : SP_HIS_FECHA_COMPROMISO
        Proposito : MANTENIMIENTO AREAS
        Referencias :
        Parametros :
        Log de Cambios
        Fecha        Autor         Descripcion
        15/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/

  PROCEDURE sp_inserupdate_areas
  (
    p_cod_chek     VARCHAR2,
    p_cod_area_vta VARCHAR2,
    p_ind_inactivo VARCHAR2,
    p_ind_default  VARCHAR2,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  );
  /*-----------------------------------------------------------------------------
      Nombre : SP_HIS_FECHA_COMPROMISO
      Proposito : historial de fecha de compromiso
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_his_fecha_compromiso
  (
    p_num_ficha_vta_veh     IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_nur_aut_ficha_vta_veh IN VARCHAR2,
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_uno              IN VARCHAR2,
    p_tipo_dos              IN VARCHAR2,
    p_num_pedido_veh        IN VARCHAR2,
    p_cod_cia               IN VARCHAR2,
    p_cod_prov              IN VARCHAR2,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
      Nombre : sp_lista_areaVenta
      Proposito : lista de areas
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_lista_areaventa
  (
    p_cod_chek     VARCHAR2,
    p_cod_area_vta VARCHAR2,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  );

  FUNCTION fn_co_usuario_jefe
  (
    p_vendedor     IN VARCHAR2,
    p_cod_area_vta IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial   IN vve_pedido_veh.cod_filial%TYPE
  ) RETURN VARCHAR2;

  FUNCTION fn_fecha_compromiso(p_proforma IN VARCHAR2) RETURN DATE;

  /*-----------------------------------------------------------------------------
      Nombre : FN_IND_DESADUANAJE
      Proposito : Retorna el indice de envio de correo
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      20/03/2018   ARAMOS         Creacion
  ----------------------------------------------------------------------------*/

  FUNCTION fn_ind_desaduanaje
  (
    p_cod_cia        IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov       IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh IN vve_pedido_veh.num_pedido_veh%TYPE
  ) RETURN NUMBER;

  /*-----------------------------------------------------------------------------
      Nombre : SP_GRABAR_VVE_SOLI_FACT_CONT
      Proposito : Graba los contactos de Solicitud de Facturacions
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      13/04/2018   ARAMOS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_vve_soli_fact_cont
  (
    p_txt_nombre         IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_txt_correo         IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_cod_soli_fact_vehi IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_cod_usuario_crea   IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR

  );

  /*--------------------------------------------------------------------------
    Nombre : SP_REG_PEDIDO_VEH_SITU
    Proposito : Registro de situacion del vehiculo
    Referencias :
    Parametros :
    Log de Cambios
      Fecha        Autor         Descripcion
      18/04/2018   PHRAMIREZ     Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_reg_pedido_veh_situ
  (
    p_cod_cia          IN vve_pedido_veh_situ.cod_cia%TYPE,
    p_cod_prov         IN vve_pedido_veh_situ.cod_prov%TYPE,
    p_num_pedido_veh   IN vve_pedido_veh_situ.num_pedido_veh%TYPE,
    p_cod_situ_pedido  IN vve_pedido_veh_situ.cod_situ_pedido%TYPE,
    p_fec_situ_pedido  IN vve_pedido_veh_situ.fec_situ_pedido%TYPE,
    p_cod_tipo_docu    IN vve_pedido_veh_situ.cod_tipo_docu%TYPE,
    p_num_docu         IN vve_pedido_veh_situ.num_docu%TYPE,
    p_obs_situ_pedido  IN vve_pedido_veh_situ.obs_situ_pedido%TYPE,
    p_cod_usuario_crea IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------------------------------
    Nombre : sp_mail_alert_preasig_lineup
    Proposito : Enviar alertas a los Jefes de Venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor              Descripcion
    24/11/2019   SOPORTELEGADOS     Creacion
  -------------------------------------------------------------------------------------------------------*/

  PROCEDURE sp_mail_alert_jefeventas(p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                         p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
                                         p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
                                         p_co_usuario        IN sistemas.usuarios.co_usuario%TYPE,
                                         p_cod_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                         p_ret_esta          OUT NUMBER,
                                         p_ret_mens          OUT VARCHAR2);


   /*--------------------------------------------------------------------------
    Nombre : sp_correo_facturacion_pedido
    Proposito : Estructura de correo de Facturacion
    Referencias :
    Parametros :
    Log de Cambios
      Fecha        Autor         Descripcion
      31/10/2018   FGRANDEZ     Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_correo_facturacion_pedido
  (
    P_COD_COMPANIA        IN VARCHAR2,
    P_COD_PROVEEDOR       IN VARCHAR2,
    P_PEDIDO              IN VARCHAR2,
    P_DESTINATARIOS       IN VARCHAR2,
    P_COPIA              IN VARCHAR2,
    P_MENSAJE             IN VARCHAR2,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ) ;

END pkg_sweb_five_mant_pedido;
