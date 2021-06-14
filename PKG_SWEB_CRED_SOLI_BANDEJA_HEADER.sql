create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_BANDEJA AS 

   /********************************************************************************
    Nombre:     SP_LIST_CRED_SOLI
    Proposito:  Listar las solicitudes de crédito.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Código de solicitud.
                P_NUM_PROF_VEH      ---> Número de proforma.
                P_FEC_INI           ---> Fecha de creación de solicitud. (Filtro inicial)
                P_FEC_FIN           ---> Fecha de creación de solicitud. (Filtro final)
                P_COD_AREA_VTA      ---> Código de área de venta.
                P_TIP_SOLI_CRED     ---> Tipo de solicitud.
                P_COD_CLIE          ---> Código de cliente.
                P_COD_RESP_FINA     ---> Código de responsable de financiemiento. (Gestor de Finanzas o Gestor de Crédito)
                P_COD_ESTADO        ---> Código de estado de la solicitud.
                P_COD_EMPR          ---> Código de empresa.
                P_COD_ZONA          ---> Código de zona o región.
                P_RUC_CLIENTE       ---> Ruc del Cliente.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_IND_PAGINADO      ---> Indica si se realizara la paginación S:SI, N:NO
                P_LIMITINF          ---> Inicio de regisitros.
                P_LIMITSUP          ---> Fin de registros.
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_CANTIDAD          ---> cantidad de solicitudes que devuelve la lista.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_cred_soli
  (
    p_cod_soli_cred  IN vve_cred_soli.cod_soli_cred%TYPE,
    p_num_prof_veh   IN vve_cred_soli_prof.num_prof_veh%TYPE,       
    p_fec_ini        IN VARCHAR2,
    p_fec_fin        IN VARCHAR2,
    p_cod_area_vta   IN VARCHAR2,   
    p_tip_soli_cred  IN VARCHAR2,
    p_cod_clie       IN vve_cred_soli.cod_clie%TYPE,
    p_cod_pers_soli  IN vve_cred_soli.cod_pers_soli%TYPE,
    p_cod_resp_fina  IN vve_cred_soli.cod_resp_fina%TYPE,
    p_cod_estado     IN vve_cred_soli.cod_estado%TYPE,
    p_cod_empr       IN VARCHAR2,
    p_cod_zona       IN VARCHAR2,    
    p_ruc_cliente    IN VARCHAR2,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado   IN VARCHAR2,
    p_limitinf       IN INTEGER,
    p_limitsup       IN INTEGER,    
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_cantidad       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );
  
  /********************************************************************************
    Nombre:     FN_DESC_SUCU
    Proposito:  Obtiene el nombre de la sucursal.
    Referencias:
    Parametros: P_COD_SUCURSAL     ---> Código de sucursal.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
  
  FUNCTION fn_desc_sucu(
    p_cod_sucursal  IN gen_sucursales.nom_sucursal%TYPE
    ) RETURN VARCHAR2;
 
  /********************************************************************************
    Nombre:     FN_COD_ID_USUA
    Proposito:  Obtiene el cod_id_usuario de un usuario específico.
    Referencias:
    Parametros: P_TXT_USUARIO     ---> Usuario web
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
  
  FUNCTION fn_cod_id_usua(
    p_txt_usuario  IN sis_mae_usuario.txt_usuario%TYPE
    ) RETURN NUMBER;
    
  /********************************************************************************
    Nombre:     FN_DESC_USUARIO
    Proposito:  Obtiene el nombre completo del usuario.
    Referencias:
    Parametros: P_CO_USUARIO     ---> Usuario web
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
  
  FUNCTION fn_nom_usua(
    p_co_usuario  IN usuarios.co_usuario%TYPE
    ) RETURN VARCHAR2;
  
  /********************************************************************************
    Nombre:     FN_DESC_ACTI_ACTU
    Proposito:  Obtiene el nombre de la actividad actual en que se encuentra la solicitud.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_desc_acti_actu(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN VARCHAR2; 
  
  /********************************************************************************
    Nombre:     FN_VTA_TOTAL_FIN
    Proposito:  Obtiene el monto total de vta de los vehículos a financiar
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_vta_total_fin(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN NUMBER; 
  
  /********************************************************************************
    Nombre:     FN_CAN_TOTAL_VEH_FIN
    Proposito:  Obtiene la cantidad total de vehículos a financiar.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_can_total_veh_fin(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN NUMBER; 
  
  /********************************************************************************
    Nombre:     FN_TXT_FECH_ULT_VENC
    Proposito:  Obtiene la fecha de vencimiento de la última letra.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_txt_fech_ult_venc(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN VARCHAR2; 

  /********************************************************************************
    Nombre:     FN_TXT_OTR_COND_SIMU
    Proposito:  Obtiene la observación del simulador
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_txt_otr_cond_simu(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN VARCHAR2; 

  /********************************************************************************
    Nombre:     FN_CAN_GARA
    Proposito:  Obtiene la cantidad de garantías
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/
    
  FUNCTION fn_can_gara(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN NUMBER; 

    
END PKG_SWEB_CRED_SOLI_BANDEJA;