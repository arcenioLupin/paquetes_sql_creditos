create or replace PACKAGE  VENTA.PKG_SWEB_CRED_SOLI_MANT_AGRUP AS

PROCEDURE SP_LIST_AGRUP_TASAS_VEHI (
    p_cod_cia           IN vve_cred_agru_veh_seg.no_cia%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%type,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%type,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN INTEGER,
    p_limitsup          IN INTEGER,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
);

PROCEDURE SP_LIST_DETAIL_BY_AGRUP (
    p_cod_agru_veh_seg  IN  vve_cred_agru_veh_seg.cod_agru_veh_seg%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
);

PROCEDURE SP_ACT_AGRUP
(
    p_cod_agru_veh_seg  IN vve_cred_agru_veh_seg.cod_agru_veh_seg%TYPE,
    p_des_agru_veh_seg  IN vve_cred_agru_veh_seg.des_agru_veh_seg%TYPE,
    p_val_tasa_brut     IN vve_cred_agru_veh_seg.val_tasa_brut%TYPE,
    p_val_gross_up      IN vve_cred_agru_veh_seg.val_gross_up%TYPE,
    p_val_tasa_final    IN vve_cred_agru_veh_seg.val_tasa_final%TYPE,
    p_no_cia            IN vve_cred_agru_veh_seg.no_cia%TYPE,
    p_ind_inactivo      IN vve_cred_agru_veh_seg.ind_inactivo%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
);

  PROCEDURE SP_ACT_DETALLE
  (
    p_cod_tipo_veh_agru IN vve_cred_tipo_veh_agru.cod_tipo_veh_agru%TYPE,
    p_cod_tipo_veh      IN vve_cred_tipo_veh_agru.cod_tipo_veh%TYPE,
    p_cod_agru_veh_seg  IN vve_cred_tipo_veh_agru.cod_agru_veh_seg%TYPE,
    p_cod_tipo_uso      IN vve_cred_tipo_veh_agru.cod_tip_uso%TYPE,
    p_ind_inactivo      IN vve_cred_tipo_veh_agru.ind_inactivo%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

END PKG_SWEB_CRED_SOLI_MANT_AGRUP;