create or replace PACKAGE  VENTA.PKG_SWEB_CRED_SOLI_MANT_CLIE AS

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CLIENTES
      Proposito : Lista de informacion de los cliente.
      Referencias : 
      Parametros : p_cod_clie, 
                   p_nom_perso,
                   p_cod_tipo_perso,
                   p_cod_tipo_docu_iden,
                   p_num_dni,
                   p_num_ruc,
                   p_cod_area_telf_movil,
                   p_num_telf_movil,
                   p_ind_inactivo,
                   p_cod_usua_sid,
                   p_cod_usua_web,
                   p_ind_paginado,
                   p_limitinf,
                   p_limitsup
                   
                   
      Log de Cambios
        Fecha        Autor          Descripcion
        16/04/2019   jaltamirano    req-87567     Creacion
  ----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_CLIENTES(
    p_tipo_cred             IN vve_cred_soli.tip_soli_cred%type,
    p_cod_soli_cred         IN vve_cred_soli.cod_soli_cred%type,
    p_cod_clie              IN gen_persona.cod_perso%type,
    p_cod_clie_sap          IN VARCHAR2,
    p_nom_perso             IN gen_persona.nom_perso%type,
    p_cod_tipo_perso        IN gen_persona.cod_tipo_perso%type,
    p_cod_tipo_docu_iden    IN gen_persona.cod_tipo_docu_iden%type,
    p_num_dni               IN gen_persona.num_docu_iden%type,
    p_num_ruc               IN gen_persona.num_ruc%type,
    p_cod_area_vta          IN gen_area_vta.cod_area_vta%type,
    p_cod_filial            IN gen_filial.cod_filial%type,
    p_cod_zona              IN vve_mae_zona.cod_zona%type,
    p_cod_cia               IN gen_mae_sociedad.cod_cia%type,
    p_cod_pais              IN gen_mae_pais.cod_id_pais%type,
    p_cod_depa              IN gen_filial.cod_dpto%type,
    p_cod_prov              IN gen_filial.cod_provincia%type,
    p_cod_dist              IN gen_filial.cod_distrito%type,
    p_cod_esta_soli         IN vve_cred_soli.cod_estado%type,
    p_cod_esta_clie         IN gen_persona.ind_inactivo%type,           
    
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%type,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%type,
    p_ind_paginado          IN VARCHAR2,
    p_limitinf              IN INTEGER,
    p_limitsup              IN INTEGER,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_cantidad          OUT NUMBER,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
);

PROCEDURE SP_LIST_COD_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN VARCHAR2,
        p_cod_tipo_oper     IN VARCHAR2,
        p_cod_mone          IN VARCHAR2,
        p_estado            IN VARCHAR2,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

PROCEDURE SP_LIST_OPERS(
    p_cod_clie          IN vve_cred_soli.cod_clie%type,
    p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
);

PROCEDURE SP_LIST_GARAN(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_tipo_cred         VARCHAR2,
        p_esta_gara         VARCHAR2,
        p_tipo_gara         IN vve_cred_maes_gara.ind_tipo_garantia%type,
        p_marca_gara        VARCHAR2,
        p_num_soli_cred     VARCHAR2,
        p_anio_fab          VARCHAR2,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
);

PROCEDURE SP_ACT_GARANTIA
  (
     p_cod_soli_cred     IN vve_cred_soli_aval.cod_soli_cred%TYPE,
     p_cod_gara          IN vve_cred_maes_gara.cod_garantia%TYPE,
     p_cod_clie          IN vve_cred_maes_gara.cod_cliente%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
);

 /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_TODOS_CLIENTE
      Proposito : Lista de informacion de los clientes.
      Referencias : 
      Parametros : p_nom_clie, 
                   p_cod_usua_sid,
                   p_cod_usua_web,
                   p_ind_paginado,
                   p_limitinf,
                   p_limitsup
                   
                   
      Log de Cambios
        Fecha        Autor          Descripcion
        10/09/2020   AVILCA          Creacion
  ----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_TODOS_CLIENTE(
    p_nom_clie              IN cxc_mae_clie.nom_clie%type,    
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%type,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_cantidad          OUT NUMBER,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
);

/* -- STORE PROCEDURES LISTADO PAIS, DEPARTAMENTO, PROVINCIA, DISTRITO Req. Obs Consulta Cliente MBardales 16/10/2020 */

  PROCEDURE sp_listado_paises(
    p_cod_cia           IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_listado_departamentos(
    p_cod_pais          IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_listado_provincias
  (
    p_cod_depa          IN gen_mae_departamento.cod_id_departamento%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_listado_distritos
  (
    p_cod_prov          IN gen_mae_distrito.cod_id_provincia%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );  

END PKG_SWEB_CRED_SOLI_MANT_CLIE;