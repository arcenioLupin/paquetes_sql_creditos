create or replace PACKAGE    VENTA.PKG_SWEB_CRED_SOLI_GARANTIA AS
PROCEDURE sp_list_garantia
  (
    p_cod_soli_cred     IN vve_cred_soli_gara.cod_soli_cred%TYPE,
    p_ind_tipo_garantia IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

PROCEDURE sp_ins_gara_soli
  (
     p_cod_soli_cred        vve_cred_soli_even.cod_soli_cred%TYPE,
     p_cod_garantia         VARCHAR2,
     p_ind_tipo_garantia    VARCHAR2,
     p_ind_tipo_bien        VARCHAR2,
     p_ind_otor             VARCHAR2,
     p_cod_pers_prop        VARCHAR2,
     p_cod_marca            VARCHAR2,
     p_txt_marca            VARCHAR2,
     p_txt_modelo           VARCHAR2,
     p_cod_tipo_veh         VARCHAR2,
     p_nro_motor            VARCHAR2,
     p_txt_carroceria       VARCHAR2,
     p_fec_fab_const        VARCHAR2,
     p_nro_chasis           VARCHAR2,
     p_val_nro_rango        VARCHAR2,
     p_nro_placa            VARCHAR2,
     p_tipo_actividad       VARCHAR2,
     p_val_const_gar        NUMBER,
     p_val_realiz_gar       NUMBER,
     p_cod_of_registral     NUMBER,
     p_val_anos_deprec      VARCHAR2,
     p_cod_moneda           VARCHAR2,
     p_des_descripcion      VARCHAR2,
     p_ind_adicional        VARCHAR2,
     p_num_titulo_rpv       VARCHAR2,
     p_nro_tarj_prop_veh    VARCHAR2,
     p_nro_partida          VARCHAR2,
     p_ind_reg_mob_contratos VARCHAR2,
     p_ind_reg_jur_bien     VARCHAR2,
     p_txt_info_mod_gar     VARCHAR2,
     p_ind_ratifica_gar     VARCHAR2,
     p_val_nvo_monto        NUMBER,
     p_val_nvo_val          NUMBER,
     p_val_mont_otor_hip    NUMBER,
     p_txt_direccion        VARCHAR2,
     p_cod_distrito         VARCHAR2,
     p_cod_provincia        VARCHAR2,
     p_cod_departamento     VARCHAR2,
     p_cod_cliente          VARCHAR2,
     p_nuevo                VARCHAR2,
     p_val_ano_fab          VARCHAR2,
     p_num_pedido_veh       VARCHAR2,
     p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_cod_garantia_out     OUT VARCHAR2,
     p_ret_esta             OUT NUMBER,
     p_ret_mens             OUT VARCHAR2
  );

PROCEDURE sp_list_garantia_histo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
    p_cod_cliente       IN vve_cred_maes_gara.cod_cliente%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

PROCEDURE sp_eli_gara_soli
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
     p_list_gara_vig     IN VARCHAR2,
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

  PROCEDURE sp_eli_by_gara
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
     p_cod_garantia      IN vve_cred_maes_gara.cod_garantia%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  );

  FUNCTION fn_obt_val_const_depr
  (
    p_cod_soli_cred     IN vve_cred_soli_gara.cod_soli_cred%TYPE,
    p_cod_garantia      IN vve_cred_maes_gara.cod_garantia%TYPE,
    p_cod_tipo_veh      IN vve_cred_mae_depr.cod_tipo_veh%TYPE,
    p_tipo_garantia     IN VARCHAR2     
  ) return NUMBER;  

PROCEDURE sp_list_cobergara_fc
    (      
        p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cursor        OUT     SYS_REFCURSOR,
        p_ret_esta          OUT     NUMBER,
        p_ret_mens          OUT     VARCHAR2
    ) ;   

END PKG_SWEB_CRED_SOLI_GARANTIA; 
