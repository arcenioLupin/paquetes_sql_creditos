create or replace PACKAGE  VENTA.PKG_SWEB_CRED_SOLI_AVAL AS
PROCEDURE sp_list_aval
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
PROCEDURE sp_list_aval_histo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );  
  
PROCEDURE sp_ins_aval
  (
     p_cod_soli_cred      vve_cred_soli_even.cod_soli_cred%TYPE,
     p_cod_per_aval       vve_cred_mae_aval.cod_per_aval%TYPE,
     p_ind_tipo_persona   vve_cred_mae_aval.ind_tipo_persona%TYPE,
     p_ind_estado_civil   vve_cred_mae_aval.ind_esta_civil%TYPE,
     p_cod_rela_aval      vve_cred_mae_aval.cod_rela_aval%TYPE,
     p_cod_moneda         vve_cred_mae_aval.cod_moneda%TYPE,
     p_val_monto_fianza   vve_cred_mae_aval.val_monto_fianza%TYPE,
     p_txt_direccion      vve_cred_mae_aval.txt_direccion%TYPE,
     p_cod_distrito       vve_cred_mae_aval.cod_distrito%TYPE,
     p_cod_provincia      vve_cred_mae_aval.cod_provincia%TYPE,
     p_cod_departamento   vve_cred_mae_aval.cod_departamento%TYPE,
     p_cod_empr           vve_cred_mae_aval.cod_empr%TYPE,
     p_cod_pais           vve_cred_mae_aval.cod_pais%TYPE,
     p_cod_zona           vve_cred_mae_aval.cod_zona%TYPE,
     p_txt_nomb_pers      vve_cred_mae_aval.txt_nomb_pers%TYPE,
     p_txt_apel_pate_pers vve_cred_mae_aval.txt_apel_pate_pers%TYPE,
     p_txt_apel_mate_pers vve_cred_mae_aval.txt_apel_mate_pers%TYPE,
     p_cod_per_rel_aval   vve_cred_mae_aval.cod_per_rel_aval%TYPE,
     p_txt_doi            vve_cred_mae_aval.txt_doi%TYPE,
     p_ava_histo          VARCHAR2,
     p_cod_tipo_otor      vve_cred_mae_aval.cod_tipo_otor%TYPE,
     p_txt_telefono       vve_cred_mae_aval.txt_telefono%TYPE,
     p_flag_coprop_eli    VARCHAR2,
     p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_cod_per_aval_ret   OUT VARCHAR2,
     p_ret_esta           OUT NUMBER,
     p_ret_mens           OUT VARCHAR2
  );
  
  PROCEDURE sp_eli_aval_soli
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_tipo              IN VARCHAR2,
     p_list_aval_vig     IN VARCHAR2,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_listado_paises(
    p_cod_cia          IN VARCHAR2,
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
  
  PROCEDURE sp_eli_by_aval
  (
     p_cod_soli_cred     IN vve_cred_soli_aval.cod_soli_cred%TYPE,
     p_cod_per_aval      IN vve_cred_mae_aval.cod_per_aval%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  );


END PKG_SWEB_CRED_SOLI_AVAL;