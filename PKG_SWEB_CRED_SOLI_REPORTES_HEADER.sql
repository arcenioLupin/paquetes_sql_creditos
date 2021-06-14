create or replace PACKAGE   VENTA.PKG_SWEB_CRED_SOLI_REPORTES AS

/*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CRED_SOLI_VC_COD_OPERS
      Proposito : Lista de codigos de operaciones por cliente.
      Referencias : 
      Parametros : p_cod_clie, 
                   p_cod_oper --no necesario
      Log de Cambios
        Fecha        Autor          Descripcion
        28/03/2019   jaltamirano    req-87567     Creacion
  ----------------------------------------------------------------------------*/    
PROCEDURE SP_LIST_CRED_SOLI_VC_COD_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        --p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

/*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CRED_SOLI_VC_OPERS
      Proposito : Lista de informacion de todas las operaciones por cliente.
      Referencias : 
      Parametros : p_cod_clie, 
                   p_cod_oper 
      Log de Cambios
        Fecha        Autor          Descripcion
        18/02/2020   jquintanilla    REQ CU-19     Creacion
  ----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_CRED_SOLI_VC_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

/*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CRED_SOLI_VC_GARAN
      Proposito : Lista informacion de las Solicitudes Credito, Reporte VistaCliente.
      Referencias : 
      Parametros : p_cod_clie, 
                   p_cod_oper 
      Log de Cambios
        Fecha        Autor          Descripcion
        18/02/2020   jquintanilla    REQ CU-19     Creacion
  ----------------------------------------------------------------------------*/    
PROCEDURE SP_LIST_CRED_SOLI_VC_GARAN(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

/*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CRED_SOLI_CO
      Proposito : Lista de informacion de los creditos otorgados por cliente.
      Referencias : 
      Parametros : p_cod_region, 
                   p_cod_area_vta,
                   p_cod_tipo_oper,
                   p_fec_factu_inicio,
                   p_fec_factu_fin
      Log de Cambios
        Fecha        Autor          Descripcion
        18/02/2020   jquintanilla    REQ CU-19     Creacion
  ----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_CRED_SOLI_CO(
        p_cod_region        IN vve_mae_zona.cod_zona%type,
        p_cod_area_vta      IN gen_area_vta.cod_area_vta%type,
        p_cod_tipo_oper     IN vve_cred_soli.tip_soli_cred%type,
        p_fec_factu_inicio  IN VARCHAR2,
        p_fec_factu_fin     IN VARCHAR2,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

END PKG_SWEB_CRED_SOLI_REPORTES;