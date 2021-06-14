create or replace PACKAGE VENTA.pkg_sweb_five_mant AS
  /******************************************************************************
     NAME:      PKG_SWEB_FIVE_MANT
     PURPOSE:   Contiene los procedimientos para la gestión de la ficha de venta.
     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        11/05/2017  PHRAMIREZ        Creación del package.
  ******************************************************************************/
  TYPE tr_permiso_pedido IS RECORD(
    num_pedido_veh vve_pedido_veh.num_pedido_veh%TYPE,
    cod_cia        vve_pedido_veh.cod_cia%TYPE,
    cod_prov       vve_pedido_veh.cod_prov%TYPE,
    permiso        VARCHAR2(50),
    valor          VARCHAR2(2),
    mensaje        VARCHAR2(1000));
  TYPE pi_permiso_pedido IS TABLE OF tr_permiso_pedido;
  /********************************************************************************
    Nombre:     SP_GRABAR_FICHA_VENTA
    Proposito:  Registra o modifica la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH        ---> Código de ficha de venta.
                P_COD_CIA                  ---> Código de compañia.
                P_VENDEDOR                 ---> Código del vendedor.
                P_COD_AREA_VTA             ---> Código del área de venta.
                P_COD_FILIAL               ---> Código de filial.
                P_COD_TIPO_FICHA_VTA_VEH   ---> Código de tipo de ficha de venta.
                P_COD_CLIE                 ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH        ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH ---> Código de moneda.
                P_COD_TIPO_PAGO            ---> Código de tipo de pago.
                P_COD_MONEDA_CRED          ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED     ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID             ---> Código del usuario.
                P_RET_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta generado.
                P_RET_ESTA                 ---> Estado del proceso.
                P_RET_MENS                 ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO     ---> Descripción de uso
                                            P_COD_COLOR_VEH   ---> Código del color del vehiculo
  ********************************************************************************/

  PROCEDURE sp_grabar_ficha_venta
  (
    p_num_ficha_vta_veh         IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR2, -- V2.0
    p_cod_color_veh             IN VARCHAR2, --V2.0
    p_ret_num_ficha_vta_veh     OUT vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_INSE_FICHA_VENTA
    Proposito:  Insertar la ficha de venta.
    Referencias:
    Parametros: P_COD_CIA                  ---> Código de compañia.
                P_VENDEDOR                 ---> Código del vendedor.
                P_COD_AREA_VTA             ---> Código del área de venta.
                P_COD_FILIAL               ---> Código de filial.
                P_COD_TIPO_FICHA_VTA_VEH   ---> Código de tipo de ficha de venta.
                P_COD_CLIE                 ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH        ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH ---> Código de moneda.
                P_COD_TIPO_PAGO            ---> Código de tipo de pago.
                P_COD_MONEDA_CRED          ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED     ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID             ---> Código del usuario.
                P_RET_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta generado.
                P_RET_ESTA                 ---> Estado del proceso.
                P_RET_MENS                 ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO     ---> Descripción de uso
                                            P_COD_COLOR_VEH   ---> Código del color del vehiculo
  ********************************************************************************/

  PROCEDURE sp_inse_ficha_venta
  (
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_sucursal              IN vve_ficha_vta_veh.cod_sucursal%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR2, -- V2.0
    p_cod_color_veh             IN VARCHAR2, --V2.0
    p_ret_num_ficha_vta_veh     OUT vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_ACTU_FICHA_VENTA
    Proposito:  Actualizar la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_CIA                   ---> Código de compañia.
                P_VENDEDOR                  ---> Código del vendedor.
                P_COD_AREA_VTA              ---> Código del área de venta.
                P_COD_FILIAL                ---> Código de filial.
                P_COD_SUCURSAL              ---> Código de sucursal.
                P_COD_TIPO_FICHA_VTA_VEH    ---> Código de tipo de ficha de venta.
                P_COD_CLIE                  ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH         ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH  ---> Código de moneda.
                P_VAL_TIPO_CAMBIO_FICHA_VTA ---> Valor de tipo de cambio.
                P_COD_TIPO_PAGO             ---> Código de tipo de pago.
                P_COD_MONEDA_CRED           ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED      ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID              ---> Código del usuario.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO     ---> Descripción de uso
                                            P_COD_COLOR_VEH   ---> Código del color del vehiculo
  ********************************************************************************/

  PROCEDURE sp_actu_ficha_venta
  (
    p_num_ficha_vta_veh         IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_sucursal              IN vve_ficha_vta_veh.cod_sucursal%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR, -- V2.0
    p_cod_color_veh             IN VARCHAR, --V2.0
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_ACTU_ESTADO_FICHA_VENTA
    Proposito:  Actualizar el estado de la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_ESTADO_FICHA_VTA ---> Código del nuevo estado de la ficha de venta.
                P_OBS_ESTADO_FICHA_VTA ---> Observaciones acerca del cambio de estado.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        12/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_actu_estado_ficha_venta
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_estado_ficha_vta IN vve_ficha_vta_veh.cod_estado_ficha_vta_veh%TYPE,
    p_obs_estado_ficha_vta IN vve_ficha_vta_veh_estado.obs_estado_ficha_vta%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR
  );

  /********************************************************************************
    Nombre:     SP_ANUL_FICHA_VENTA
    Proposito:  Anular ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_OBS_ESTADO_FICHA_VTA ---> Observaciones acerca del cambio de estado.
                P_IND_DES              ---> Indicador de desasignación de pedido y proforma S=Si, N=No.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_anul_ficha_venta
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_obs_estado_ficha_vta IN vve_ficha_vta_veh_estado.obs_estado_ficha_vta%TYPE,
    p_ind_des              IN CHAR,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_OBTE_ESTADO_FICHA_VENTA
    Proposito:  Obtener el estado de la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_DES_ESTA         ---> Descripción del estado.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_obte_estado_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cod_esta      OUT vve_estado_ficha_vta.cod_estado_ficha_vta%TYPE,
    p_ret_des_esta      OUT vve_estado_ficha_vta.des_estado_ficha_vta%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_VALI_ACCESO_FICHA_VENTA
    Proposito:  Validar el acceso a una ficha de venta existente.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_vali_acceso_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_VALI_ACCESO_USUARIO_CRM
    Proposito:  Validar el usuario CRM que ingresa a la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_USER_CRM             ---> Usuario CRM
                P_COD_CLIE_SAP         ---> Código Cliente SAP
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_vali_acceso_usuario_crm
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_user_crm          IN VARCHAR2,
    p_cod_clie_sap      IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_ENV_LAFIT
    Proposito:  Se envia solicitud para la revisión de información del cliente por lavado de activos.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
    1.1        04/10/2017  PHRAMIREZ        Se agrego campo OBSERVACION.
  ********************************************************************************/

  PROCEDURE sp_env_lafit
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_observacion       IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_FICHA_VENTA
    Propósito:  Búsqueda de fichas de venta.
    Referencias:
    Parámetros: P_COD_CIA                   ---> Código de Compañia.
                P_COD_AREA_VTA              ---> Código de Área de Venta.
                P_COD_FILIAL                ---> Código de Filial.
                P_COD_VENDEDOR              ---> Código de Vendedor.
                P_COD_CLAUSULA_COMPRA       ---> Código de Clausula de Compra.
                P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_TIPO_FICHA_VTA_VEH    ---> Código de tipo de ficha de venta.
                P_COD_TIPO_PAGO             ---> Código de tipo de pago.
                P_COD_MONEDA_FICHA_VTA_VEH  ---> Código de moneda de ficha de venta.
                P_COD_MONEDA_CRED           ---> Código de moneda de credito.
                P_COD_CLIE                  ---> Código de cliente.
                P_COD_FAMILIA_VEH           ---> Código de familia vehicular.
                P_COD_MARCA                 ---> Código de marca de vehiculo.
                P_COD_BAUMUSTER             ---> Código de modelo de vehiculo.
                P_COD_CONFIG_VEH            ---> Código de configuración.
                P_COD_ESTADO_FICHA_VTA_VEH  ---> Código de estado de ficha de venta.
                P_FEC_FICHA_VTA_VEH_INI     ---> Fecha inicial de busqueda.
                P_FEC_FICHA_VTA_VEH_FIN     ---> Fecha final de busqueda.
                P_NUM_PROF_VEH              ---> Código de proforma.
                P_NUM_PEDIDO_VEH            ---> Código de pedido.
                P_IND_INACTIVO              ---> Indicador de estado del registro S-Inactivo, N-Activo
                P_COD_ADQUISICION           ---> Código de adquisicion
                P_COD_USUA_SID              ---> Código del usuario.
                P_LIMITINF                  ---> Límite inicial de registros.
                P_LIMITSUP                  ---> Límite final de registros.
                P_RET_CURSOR                ---> Resultado de la busqueda.
                P_RET_CANTIDAD              ---> Cantidad total de registros.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.
    REVISIONES:
    Versión    Fecha       Autor            Descripción
    ---------  ----------  ---------------  ------------------------------------
    1.0        16/05/2017  PHRAMIREZ        Creación del procedure.
    1.1        10/07/2017  LVALDERRAMA      Modificación
    1.2        29/09/2017  LVALDERRAMA      Modificación
    1.3        08/08/2018  YGOMEZ           REQ RF86338 - Modificación
    1.4	       02/01/2019  JMORENO          REQ 86298 - Modificación
    --En esta versión se crean estas variables 'v_group,v_where,v_subWhere' para
    --optimizar la consulta de la Ficha de Venta por los siguientes filtros:
      --N° de Pedido, N° de Ficha de Venta y N° de Proforma.
  ********************************************************************************/

  PROCEDURE sp_list_ficha_venta
  (
    p_cod_cia                  IN VARCHAR2,
    p_cod_area_vta             IN VARCHAR2,
    p_cod_filial               IN VARCHAR2,
    p_cod_vendedor             IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_clausula_compra      IN VARCHAR2, --<REQ.86298>
    p_num_ficha_vta_veh        IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_tipo_ficha_vta_veh   IN VARCHAR2,
    p_cod_tipo_pago            IN VARCHAR2,
    p_cod_moneda_ficha_vta_veh IN VARCHAR2,
    p_cod_moneda_cred          IN VARCHAR2,
    p_cod_clie                 IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_familia_veh          IN VARCHAR2,
    p_cod_marca                IN vve_proforma_veh_det.cod_marca%TYPE,
    p_cod_baumuster            IN vve_proforma_veh_det.cod_baumuster%TYPE,
    p_cod_config_veh           IN vve_proforma_veh_det.cod_config_veh%TYPE,
    p_cod_estado_ficha_vta_veh IN VARCHAR2,
    p_fec_ficha_vta_veh_ini    IN VARCHAR2,
    p_fec_ficha_vta_veh_fin    IN VARCHAR2,
    p_num_prof_veh             IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh           IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_inactivo             IN vve_ficha_vta_veh_aut.ind_inactivo%TYPE,
    p_cod_adquisicion          IN VARCHAR2,
    p_cod_zona                 IN VARCHAR2,
    p_fech_cierre_ini          IN VARCHAR2,
    p_fech_cierre_fin          IN VARCHAR2,
    p_cod_usua_sid             IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado             IN VARCHAR2,
    p_limitinf                 IN VARCHAR2,
    p_limitsup                 IN INTEGER,
    p_nom_perso                IN generico.gen_persona.nom_perso%TYPE,
    p_ret_cursor               OUT SYS_REFCURSOR,
    p_ret_cantidad             OUT NUMBER,
    p_ret_esta                 OUT NUMBER,
    p_ret_mens                 OUT VARCHAR2,
    p_cod_sku                  IN vve_pedido_veh.sku_sap%TYPE DEFAULT NULL
  );

  PROCEDURE sp_list_ficha_venta_reporte
  (
    p_cod_cia                  IN VARCHAR2,
    p_cod_area_vta             IN VARCHAR2,
    p_cod_filial               IN VARCHAR2,
    p_cod_vendedor             IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_clausula_compra      IN vve_pedido_veh.cod_clausula_compra%TYPE,
    p_num_ficha_vta_veh        IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_tipo_ficha_vta_veh   IN VARCHAR2,
    p_cod_tipo_pago            IN VARCHAR2,
    p_cod_moneda_ficha_vta_veh IN VARCHAR2,
    p_cod_moneda_cred          IN VARCHAR2,
    p_cod_clie                 IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_familia_veh          IN VARCHAR2,
    p_cod_marca                IN vve_proforma_veh_det.cod_marca%TYPE,
    p_cod_baumuster            IN vve_proforma_veh_det.cod_baumuster%TYPE,
    p_cod_config_veh           IN vve_proforma_veh_det.cod_config_veh%TYPE,
    p_cod_estado_ficha_vta_veh IN VARCHAR2,
    p_fec_ficha_vta_veh_ini    IN VARCHAR2,
    p_fec_ficha_vta_veh_fin    IN VARCHAR2,
    p_num_prof_veh             IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh           IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_inactivo             IN vve_ficha_vta_veh_aut.ind_inactivo%TYPE,
    p_cod_adquisicion          IN VARCHAR2,
    p_cod_zona                 IN VARCHAR2,
    p_fech_cierre_ini          IN VARCHAR2,
    p_fech_cierre_fin          IN VARCHAR2,
    p_cod_usua_sid             IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado             IN VARCHAR2,
    p_limitinf                 IN VARCHAR2,
    p_limitsup                 IN INTEGER,
    p_nom_perso                IN generico.gen_persona.nom_perso%TYPE,
    p_ret_cursor               OUT SYS_REFCURSOR,
    p_ret_cantidad             OUT NUMBER,
    p_ret_esta                 OUT NUMBER,
    p_ret_mens                 OUT VARCHAR2
  );
  /********************************************************************************
    Nombre:     SP_LIST_PROF_FICH_VNTA
    Proposito:  Busqueda de fichas de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_USUA_WEB              ---> Id del usuario.
                P_COD_USUA_SID              ---> Código del usuario.
                P_LIMITINF                  ---> Limite inicial de registros.
                P_LIMITSUP                  ---> Limite final de registros.
                P_RET_CURSOR                ---> Resultado de la busqueda.
                P_RET_CANTIDAD              ---> Cantidad total de registros.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        17/10/2017  MEGUILUZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_prof_fich_vnta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN VARCHAR2,
    p_limitsup          IN INTEGER,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_INSE_CORREO_FICHA_VENTA
    Proposito:  Inserta correo enviado desde ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH ---> Código del solicitud.
                P_DESTINATARIOS     ---> Lista de correos destinatarios.
                P_COPIA             ---> Lista de correos CC.
                P_ASUNTO            ---> Asunto.
                P_CUERPO            ---> Contenido del correo.
                P_CORREOORIGEN      ---> Correo remitente.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0         26/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_inse_correo_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_CORREO_FICHA_VENTA
    Proposito:  Lista de correos a enviar.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_CORREOS       ---> Lista de correos a enviar.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.
  
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0         26/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_list_correo_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_vali_cliente
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia           IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor          IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta      IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_clie          IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_auto_gral
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_aut_ficha_vta IN sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_cod_area_vta      IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  FUNCTION fu_auto_five_usu
  (
    p_cod_usua_sid      sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_aut_ficha_vta sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_num_ficha_vta_veh vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_cia           vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          vve_pedido_veh.cod_prov%TYPE
  ) RETURN VARCHAR2;

  PROCEDURE sp_auto_five_usu
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_aut_ficha_vta IN sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_vali_acti
  (
    p_cod_usua_sid        IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_acti_pedido_veh IN sistemas.usuarios_acti_pedido_veh.cod_acti_pedido_veh%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR2
  );

  PROCEDURE sp_vali_pedi_asig
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_list_cond_pago
  (
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );

  PROCEDURE sp_list_cond_pago_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_actu_cond_pago
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_nur_ficha_vta_pedido IN vve_ficha_vta_pedido_veh.nur_ficha_vta_pedido%TYPE,
    p_tipo_pago            IN vve_ficha_vta_pedido_veh.tipo_pago%TYPE,
    p_con_pago             IN vve_ficha_vta_pedido_veh.con_pago%TYPE,
    p_ind_apl_todo         IN CHAR,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  );

  PROCEDURE sp_list_hist_esta_fich
  (
    p_num_ficha_vta_veh VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_list_dcor
  (
    p_co_usuario IN VARCHAR2,
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  );

  PROCEDURE sp_list_esta_fich
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  );

  /********************************************************************************
      Nombre:     SP_LIST_CORREO_HIST
      Proposito:  Proceso que me permite Obtener los correos a notificar y actualiza la tabla correo Proforma.
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_CORREOS         ---> Cursor con los correos a notificar.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.
  
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         25/10/2017  JVELEZ           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_list_correo_sol_fact(
                                    --P_COD_PLAN_ENTR_VEHI   IN VARCHAR2,
                                    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                    p_ret_correos       OUT SYS_REFCURSOR,
                                    p_ret_esta          OUT NUMBER,
                                    p_ret_mens          OUT VARCHAR2);

  /********************************************************************************
      Nombre:     SP_INSE_NOTIF_HIST
      Proposito:  Proceso que me permite insertar en la tabla Historial de Notificaciones
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_HISTORIAL        ---> Codigo del Historial
                  P_COD_USUA_NOTI       ---> Codigo de usuarios notificados
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.
  
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         25/10/2017  JVELEZ           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_inse_notif_soli_fact(p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                    --P_COD_PLAN_ENTR_VEHI     IN VVE_PLAN_HIST_NOTI.COD_PLAN_ENTR_VEHI%TYPE,
                                    p_id_historial  IN vve_plan_hist_noti.num_plan_entr_hist%TYPE,
                                    p_cod_usua_noti IN VARCHAR2,
                                    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                    p_ret_esta      OUT NUMBER,
                                    p_ret_mens      OUT VARCHAR2);

  /********************************************************************************
      Nombre:     SP_GEN_CORREO
      Proposito:  Proceso que me permite Obtener los correos de los usuarios y generar la plantilla del correo.
      Referencias:
      Parametros: P_COD_REF_PROC     ---> Código de Referencia del proceso.
                  P_TIPO_CORREO      ---> Tipo de Correo.
                  P_DESTINATARIOS    ---> Lista de direcciones de los destinatarios,
                  P_ID_USUARIO       ---> Id del usuario.
                  P_TIPO_REF_PROC    ---> Tipo de Referencia del proceso.
                  P_RET_ESTA         ---> Estado del proceso.
                  P_RET_MENS         ---> Resultado del proceso.
  
      TIPO DE CORREO: 1 Programacion y Reprogramacion, 2 Rechazo de programacion, 3 Anulacion de programacion
                      4 Historial, 5 Aprobacion o Anulacion de pendiente
  
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      2.0         27/10/2017  JFLORESM         Modificación del procedure.
  *********************************************************************************/

  PROCEDURE sp_gen_correo_fv
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_tipo_correo   IN VARCHAR2,
    p_destinatarios IN VARCHAR2,
    p_correos       IN VARCHAR2,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc IN VARCHAR2,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );

  /********************************************************************************
      Nombre:     SP_INSE_CORREO
      Proposito:  Registra en la tabla Correo Proforma
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI ---> Código de la Planificacion.
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
      ---------  ----------  ---------------nse_correo_fv  ------------------------------------
      1.0        18/12/2017  JFLORESM        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_inse_correo_fv
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_destinatarios IN vve_correo_prof.destinatarios%TYPE,
    p_copia         IN VARCHAR2,
    p_asunto        IN vve_correo_prof.asunto%TYPE,
    p_cuerpo        IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen  IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid  IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc IN VARCHAR2,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );

  /********************************************************************************
      Nombre:     SP_LIST_CORREO_HIST
      Proposito:  Proceso que actualiza los correos enviados.
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_CORREOS         ---> Cursor con los correos a notificar.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.
  
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         18/12/2017  JFLOREM           Creación del procedure.
  *********************************************************************************/
  PROCEDURE sp_act_correo_env
  (
    p_cod_ref_proc IN VARCHAR2,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos  OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );

  /********************************************************************************
  Nombre:     SP_REGLAS_NEGOCIO_FV
  Proposito:  Valida las reglas del negocio de la ficha de venta.
  Referencias:
  Parametros: P_COD_AREA_VTA        ---> Código de area de venta.
              P_COD_MARCA           ---> Código de marca.
              P_COD_FAMILIA_VEH     ---> Código de familia.
              P_COD_AUT_AREA_VTA    ---> Código del proceso que se va a ejecutar.
              P_COD_USUARIO         ---> Código de Usuario.
              P_ID_USUARIO          ---> Id de usuario.
              P_RET_ESTA            ---> Estado del proceso.
              P_RET_MENS            ---> Resultado del proceso.
  
  REVISIONES:
  Version    Fecha       Autor            Descripcion
  ---------  ----------  ---------------  ------------------------------------
  1.0         31/01/2018  ARAMOS           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_reglas_negocio_fv
  (
    p_cod_area_vta     IN VARCHAR,
    p_cod_marca        IN VARCHAR,
    p_cod_familia_veh  IN VARCHAR,
    p_cod_aut_area_vta IN VARCHAR,
    p_cod_usuario      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  );

  /********************************************************************************
      Nombre:     SP_REGLAS_NEGOCIO_FV
      Proposito:  Permite la actualización del cliente de la ficha de venta.
      Referencias:
  
  
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         31/01/2018  GARROYO           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_act_clie_five
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_clie          IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  PROCEDURE sp_perm_usua_ficha
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tab_ficha         OUT SYS_REFCURSOR,
    p_tab_proforma      OUT SYS_REFCURSOR,
    p_tab_pedidos       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
    
  );

  FUNCTION sp_fun_str_config_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION sp_fun_str_marca_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION sp_fun_str_pedido_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION sp_fun_str_prof_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2;

END pkg_sweb_five_mant; 
