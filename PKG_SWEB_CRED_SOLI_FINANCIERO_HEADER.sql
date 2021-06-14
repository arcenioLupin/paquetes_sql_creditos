create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_FINANCIERO AS
PROCEDURE sp_list_resumen
  (
      p_cod_solicitud     VARCHAR2,
      p_cod_cliente       VARCHAR2,
      p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
      p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
      p_fec_solicitud     OUT VARCHAR2,
      p_ret_cursor        OUT SYS_REFCURSOR,
      p_ret_cursor_mat    OUT SYS_REFCURSOR,
      p_ret_esta          OUT NUMBER,
      p_ret_mens          OUT VARCHAR2
  );
PROCEDURE sp_ins_resumen
  (
        --p_cod_mae_eeff NUMBER,
        p_cod_solicitud    VARCHAR2,
        p_cod_cliente VARCHAR2,
        p_val_ano_eeff NUMBER,
        p_cod_mone_eeff VARCHAR2,
        p_val_egyp_vtas_tota	vve_cred_mae_eeff.val_egyp_vtas_tota%TYPE,
        p_val_egyp_cost_vtas_serv	vve_cred_mae_eeff.val_egyp_cost_vtas_serv%TYPE,
        p_val_egyp_util_brut	vve_cred_mae_eeff.val_egyp_util_brut%TYPE,
        p_val_egyp_gast_vtas	vve_cred_mae_eeff.val_egyp_gast_vtas%TYPE,
        p_val_egyp_gast_admi	vve_cred_mae_eeff.val_egyp_gast_admi%TYPE,
        p_val_egyp_otro_ingr_gast	vve_cred_mae_eeff.val_egyp_otro_ingr_gast%TYPE,
        p_val_egyp_util_oper	vve_cred_mae_eeff.val_egyp_util_oper%TYPE,
        p_val_egyp_gast_fina	vve_cred_mae_eeff.val_egyp_gast_fina%TYPE,
        p_val_egyp_ingr_fina	vve_cred_mae_eeff.val_egyp_ingr_fina%TYPE,
        p_val_egyp_part_rela	vve_cred_mae_eeff.val_egyp_part_rela%TYPE,
        p_val_egyp_util_ordi	vve_cred_mae_eeff.val_egyp_util_ordi%TYPE,
        p_val_egyp_ingr_extr_ccja	vve_cred_mae_eeff.val_egyp_ingr_extr_ccja%TYPE,
        p_val_egyp_egre_extr_ccaja	vve_cred_mae_eeff.val_egyp_egre_extr_ccaja%TYPE,
        p_val_egyp_ingr_extr_scja	vve_cred_mae_eeff.val_egyp_ingr_extr_scja%TYPE,
        p_val_egyp_egre_extr_scja	vve_cred_mae_eeff.val_egyp_egre_extr_scja%TYPE,
        p_val_egyp_otro_ingr	vve_cred_mae_eeff.val_egyp_otro_ingr%TYPE,
        p_val_egyp_otro_egre	vve_cred_mae_eeff.val_egyp_otro_egre%TYPE,
        p_val_egyp_util_ante_imp	vve_cred_mae_eeff.val_egyp_util_ante_imp%TYPE,
        p_val_egyp_imp_part	vve_cred_mae_eeff.val_egyp_imp_part%TYPE,
        p_val_egyp_util_perd_neta	vve_cred_mae_eeff.val_egyp_util_perd_neta%TYPE,
        p_val_egyp_var_vtas_tota	vve_cred_mae_eeff.val_egyp_var_vtas_tota%TYPE,
        p_val_egyp_var_cost_vtas_serv	vve_cred_mae_eeff.val_egyp_var_cost_vtas_serv%TYPE,
        p_val_egyp_var_util_brut	vve_cred_mae_eeff.val_egyp_var_util_brut%TYPE,
        p_val_egyp_var_gast_vtas	vve_cred_mae_eeff.val_egyp_var_gast_vtas%TYPE,
        p_val_egyp_var_gast_admi	vve_cred_mae_eeff.val_egyp_var_gast_admi%TYPE,
        p_val_egyp_var_otro_ingr_gast	vve_cred_mae_eeff.val_egyp_var_otro_ingr_gast%TYPE,
        p_val_egyp_var_util_oper	vve_cred_mae_eeff.val_egyp_var_util_oper%TYPE,
        p_val_egyp_var_gast_fina	vve_cred_mae_eeff.val_egyp_var_gast_fina%TYPE,
        p_val_egyp_var_ingr_fina	vve_cred_mae_eeff.val_egyp_var_ingr_fina%TYPE,
        p_val_egyp_var_part_rela	vve_cred_mae_eeff.val_egyp_var_part_rela%TYPE,
        p_val_egyp_var_util_ordi	vve_cred_mae_eeff.val_egyp_var_util_ordi%TYPE,
        p_val_egyp_var_ingr_extr_ccja	vve_cred_mae_eeff.val_egyp_var_ingr_extr_ccja%TYPE,
        p_val_egyp_var_egre_extr_ccaja	vve_cred_mae_eeff.val_egyp_var_egre_extr_ccaja%TYPE,
        p_val_egyp_var_ingr_extr_scja	vve_cred_mae_eeff.val_egyp_var_ingr_extr_scja%TYPE,
        p_val_egyp_var_egre_extr_scja	vve_cred_mae_eeff.val_egyp_var_egre_extr_scja%TYPE,
        p_val_egyp_var_otro_ingr	vve_cred_mae_eeff.val_egyp_var_otro_ingr%TYPE,
        p_val_egyp_var_otro_egre	vve_cred_mae_eeff.val_egyp_var_otro_egre%TYPE,
        p_val_egyp_var_util_ante_imp	vve_cred_mae_eeff.val_egyp_var_util_ante_imp%TYPE,
        p_val_egyp_var_imp_part	vve_cred_mae_eeff.val_egyp_var_imp_part%TYPE,
        p_val_egyp_var_util_perd_neta	vve_cred_mae_eeff.val_egyp_var_util_perd_neta%TYPE,
        p_val_rati_capi_trab	vve_cred_mae_eeff.val_rati_capi_trab%TYPE,
        p_val_rati_dias_exist	vve_cred_mae_eeff.val_rati_dias_exist%TYPE,
        p_val_rati_cobr_clie	vve_cred_mae_eeff.val_rati_cobr_clie%TYPE,
        p_val_rati_pago_prov	vve_cred_mae_eeff.val_rati_pago_prov%TYPE,
        p_val_rati_cicl_oper	vve_cred_mae_eeff.val_rati_cicl_oper%TYPE,
        p_val_rati_pasi_tota_patr	vve_cred_mae_eeff.val_rati_pasi_tota_patr%TYPE,
        p_val_rati_deud_fina_brut	vve_cred_mae_eeff.val_rati_deud_fina_brut%TYPE,
        p_val_rati_deud_fina_estr	vve_cred_mae_eeff.val_rati_deud_fina_estr%TYPE,
        p_val_rati_porc_var_vtas	vve_cred_mae_eeff.val_rati_porc_var_vtas%TYPE,
        p_val_rati_ebitda_anual	vve_cred_mae_eeff.val_rati_ebitda_anual%TYPE,
        p_val_rati_porc_ebitda_vtas	vve_cred_mae_eeff.val_rati_porc_ebitda_vtas%TYPE,
        p_val_rati_porc_roe	vve_cred_mae_eeff.val_rati_porc_roe%TYPE,
        p_val_rati_porc_roa	vve_cred_mae_eeff.val_rati_porc_roa%TYPE,
        p_val_rati_cash_flow	vve_cred_mae_eeff.val_rati_cash_flow%TYPE,
        p_val_rati_porc_cash_flow_vtas	vve_cred_mae_eeff.val_rati_porc_cash_flow_vtas%TYPE,
        p_val_rati_deud_fina_brut_anos	vve_cred_mae_eeff.val_rati_deud_fina_brut_anos%TYPE,
        p_val_rati_deud_fina_estr_anos	vve_cred_mae_eeff.val_rati_deud_fina_estr_anos%TYPE,
        p_val_rati_deud_fina_ebitda	vve_cred_mae_eeff.val_rati_deud_fina_ebitda%TYPE,
        p_val_rati_ebitda	vve_cred_mae_eeff.val_rati_ebitda%TYPE,
        p_val_rati_depr_amor_ejer	vve_cred_mae_eeff.val_rati_depr_amor_ejer%TYPE,
        p_val_rati_divi	vve_cred_mae_eeff.val_rati_divi%TYPE,
        p_val_rati_nro_mese	vve_cred_mae_eeff.val_rati_nro_mese%TYPE,
        p_val_rati_var_depr_amor_ejer	vve_cred_mae_eeff.val_rati_var_depr_amor_ejer%TYPE,
        p_val_rati_var_divi	vve_cred_mae_eeff.val_rati_var_divi%TYPE,
        p_val_ghist_ebitda_anual	vve_cred_mae_eeff.val_ghist_ebitda_anual%TYPE,
        p_val_ghist_cash_flow_anual	vve_cred_mae_eeff.val_ghist_cash_flow_anual%TYPE,
        p_val_bg_ac_caja_bcos	vve_cred_mae_eeff.val_bg_ac_caja_bcos%TYPE,
        p_val_bg_ac_valo_nego	vve_cred_mae_eeff.val_bg_ac_valo_nego%TYPE,
        p_val_bg_ac_clie	vve_cred_mae_eeff.val_bg_ac_clie%TYPE,
        p_val_bg_ac_prov_cobr_dud	vve_cred_mae_eeff.val_bg_ac_prov_cobr_dud%TYPE,
        p_val_bg_ac_cxc_srel	vve_cred_mae_eeff.val_bg_ac_cxc_srel%TYPE,
        p_val_bg_ac_cxc_dive	vve_cred_mae_eeff.val_bg_ac_cxc_dive%TYPE,
        p_val_bg_ac_exist	vve_cred_mae_eeff.val_bg_ac_exist%TYPE,
        p_val_bg_ac_gast_paga_anti	vve_cred_mae_eeff.val_bg_ac_gast_paga_anti%TYPE,
        p_val_bg_ac	vve_cred_mae_eeff.val_bg_ac%TYPE,
        p_val_bg_anc_inve_rela	vve_cred_mae_eeff.val_bg_anc_inve_rela%TYPE,
        p_val_bg_anc_otra_inve	vve_cred_mae_eeff.val_bg_anc_otra_inve%TYPE,
        p_val_bg_anc_cxc_srel	vve_cred_mae_eeff.val_bg_anc_cxc_srel%TYPE,
        p_val_bg_anc_inmu_neto	vve_cred_mae_eeff.val_bg_anc_inmu_neto%TYPE,
        p_val_bg_anc_terr	vve_cred_mae_eeff.val_bg_anc_terr%TYPE,
        p_val_bg_anc_edif	vve_cred_mae_eeff.val_bg_anc_edif%TYPE,
        p_val_bg_anc_maqu	vve_cred_mae_eeff.val_bg_anc_maqu%TYPE,
        p_val_bg_anc_mueb	vve_cred_mae_eeff.val_bg_anc_mueb%TYPE,
        p_val_bg_anc_unid_trans	vve_cred_mae_eeff.val_bg_anc_unid_trans%TYPE,
        p_val_bg_anc_equi_dive	vve_cred_mae_eeff.val_bg_anc_equi_dive%TYPE,
        p_val_bg_anc_depr_acum	vve_cred_mae_eeff.val_bg_anc_depr_acum%TYPE,
        p_val_bg_anc_trab	vve_cred_mae_eeff.val_bg_anc_trab%TYPE,
        p_val_bg_anc_otro_acti	vve_cred_mae_eeff.val_bg_anc_otro_acti%TYPE,
        p_val_bg_anc_intan	vve_cred_mae_eeff.val_bg_anc_intan%TYPE,
        p_val_bg_anc_otro_anc	vve_cred_mae_eeff.val_bg_anc_otro_anc%TYPE,
        p_val_bg_anc	vve_cred_mae_eeff.val_bg_anc%TYPE,
        p_val_bg_tota_acti	vve_cred_mae_eeff.val_bg_tota_acti%TYPE,
        p_val_bg_pc_banc_deud_fina_cp	vve_cred_mae_eeff.val_bg_pc_banc_deud_fina_cp%TYPE,
        p_val_bg_pc_otra_deud_fina_cp	vve_cred_mae_eeff.val_bg_pc_otra_deud_fina_cp%TYPE,
        p_val_bg_pc_deud_lp	vve_cred_mae_eeff.val_bg_pc_deud_lp%TYPE,
        p_val_bg_pc_trib_paga	vve_cred_mae_eeff.val_bg_pc_trib_paga%TYPE,
        p_val_bg_pc_remu_paga	vve_cred_mae_eeff.val_bg_pc_remu_paga%TYPE,
        p_val_bg_pc_prov	vve_cred_mae_eeff.val_bg_pc_prov%TYPE,
        p_val_bg_pc_cxp_srel	vve_cred_mae_eeff.val_bg_pc_cxp_srel%TYPE,
        p_val_bg_pc_cxp_dive	vve_cred_mae_eeff.val_bg_pc_cxp_dive%TYPE,
        p_val_bg_pc	vve_cred_mae_eeff.val_bg_pc%TYPE,
        p_val_bg_pnc_bcos_deud_fina_lp	vve_cred_mae_eeff.val_bg_pnc_bcos_deud_fina_lp%TYPE,
        p_val_bg_pnc_otra_deud_fina_lp	vve_cred_mae_eeff.val_bg_pnc_otra_deud_fina_lp%TYPE,
        p_val_bg_pnc_cxp_srel	vve_cred_mae_eeff.val_bg_pnc_cxp_srel%TYPE,
        p_val_bg_pnc_otro_pnc	vve_cred_mae_eeff.val_bg_pnc_otro_pnc%TYPE,
        p_val_bg_pnc_gana_dife	vve_cred_mae_eeff.val_bg_pnc_gana_dife%TYPE,
        p_val_bg_pnc	vve_cred_mae_eeff.val_bg_pnc%TYPE,
        p_val_bg_tota_pasi	vve_cred_mae_eeff.val_bg_tota_pasi%TYPE,
        p_val_bg_pat_capi	vve_cred_mae_eeff.val_bg_pat_capi%TYPE,
        p_val_bg_pat_cap_adic	vve_cred_mae_eeff.val_bg_pat_cap_adic%TYPE,
        p_val_bg_pat_exce_reva	vve_cred_mae_eeff.val_bg_pat_exce_reva%TYPE,
        p_val_bg_pat_rese	vve_cred_mae_eeff.val_bg_pat_rese%TYPE,
        p_val_bg_pat_resu_acum	vve_cred_mae_eeff.val_bg_pat_resu_acum%TYPE,
        p_val_bg_pat_resu_ejer	vve_cred_mae_eeff.val_bg_pat_resu_ejer%TYPE,
        p_val_bg_pat_otro	vve_cred_mae_eeff.val_bg_pat_otro%TYPE,
        p_val_bg_pat	vve_cred_mae_eeff.val_bg_pat%TYPE,
        p_val_tota_pasi_patr	vve_cred_mae_eeff.val_tota_pasi_patr%TYPE,
        p_val_cdre_acti_pasi_patr	vve_cred_mae_eeff.val_cdre_acti_pasi_patr%TYPE,
        p_val_bg_var_ac_caja_bcos	vve_cred_mae_eeff.val_bg_var_ac_caja_bcos%TYPE,
        p_val_bg_var_ac_valo_nego	vve_cred_mae_eeff.val_bg_var_ac_valo_nego%TYPE,
        p_val_bg_var_ac_clie	vve_cred_mae_eeff.val_bg_var_ac_clie%TYPE,
        p_val_bg_var_ac_prov_cobr_dud	vve_cred_mae_eeff.val_bg_var_ac_prov_cobr_dud%TYPE,
        p_val_bg_var_ac_cxc_srel	vve_cred_mae_eeff.val_bg_var_ac_cxc_srel%TYPE,
        p_val_bg_var_ac_cxc_dive	vve_cred_mae_eeff.val_bg_var_ac_cxc_dive%TYPE,
        p_val_bg_var_ac_exist	vve_cred_mae_eeff.val_bg_var_ac_exist%TYPE,
        p_val_bg_var_ac_gast_paga_anti	vve_cred_mae_eeff.val_bg_var_ac_gast_paga_anti%TYPE,
        p_val_bg_var_ac	vve_cred_mae_eeff.val_bg_var_ac%TYPE,
        p_val_bg_var_anc_inve_rela	vve_cred_mae_eeff.val_bg_var_anc_inve_rela%TYPE,
        p_val_bg_var_anc_otra_inve	vve_cred_mae_eeff.val_bg_var_anc_otra_inve%TYPE,
        p_val_bg_var_anc_cxc_srel	vve_cred_mae_eeff.val_bg_var_anc_cxc_srel%TYPE,
        p_val_bg_var_anc_inmu_neto	vve_cred_mae_eeff.val_bg_var_anc_inmu_neto%TYPE,
        p_val_bg_var_anc_terr	vve_cred_mae_eeff.val_bg_var_anc_terr%TYPE,
        p_val_bg_var_anc_edif	vve_cred_mae_eeff.val_bg_var_anc_edif%TYPE,
        p_val_bg_var_anc_maqu	vve_cred_mae_eeff.val_bg_var_anc_maqu%TYPE,
        p_val_bg_var_anc_mueb	vve_cred_mae_eeff.val_bg_var_anc_mueb%TYPE,
        p_val_bg_var_anc_unid_trans	vve_cred_mae_eeff.val_bg_var_anc_unid_trans%TYPE,
        p_val_bg_var_anc_equi_dive	vve_cred_mae_eeff.val_bg_var_anc_equi_dive%TYPE,
        p_val_bg_var_anc_depr_acum	vve_cred_mae_eeff.val_bg_var_anc_depr_acum%TYPE,
        p_val_bg_var_anc_trab	vve_cred_mae_eeff.val_bg_var_anc_trab%TYPE,
        p_val_bg_var_anc_otro_acti	vve_cred_mae_eeff.val_bg_var_anc_otro_acti%TYPE,
        p_val_bg_var_anc_intan	vve_cred_mae_eeff.val_bg_var_anc_intan%TYPE,
        p_val_bg_var_anc_otro_anc	vve_cred_mae_eeff.val_bg_var_anc_otro_anc%TYPE,
        p_val_bg_var_anc	vve_cred_mae_eeff.val_bg_var_anc%TYPE,
        p_val_bg_var_tota_acti	vve_cred_mae_eeff.val_bg_var_tota_acti%TYPE,
        p_val_bg_var_pc_banc_dfina_cp	vve_cred_mae_eeff.val_bg_var_pc_banc_dfina_cp%TYPE,
        p_val_bg_var_pc_otra_dfina_cp	vve_cred_mae_eeff.val_bg_var_pc_otra_dfina_cp%TYPE,
        p_val_bg_var_pc_deud_lp	vve_cred_mae_eeff.val_bg_var_pc_deud_lp%TYPE,
        p_val_bg_var_pc_trib_paga	vve_cred_mae_eeff.val_bg_var_pc_trib_paga%TYPE,
        p_val_bg_var_pc_remu_paga	vve_cred_mae_eeff.val_bg_var_pc_remu_paga%TYPE,
        p_val_bg_var_pc_prov	vve_cred_mae_eeff.val_bg_var_pc_prov%TYPE,
        p_val_bg_var_pc_cxp_srel	vve_cred_mae_eeff.val_bg_var_pc_cxp_srel%TYPE,
        p_val_bg_var_pc_cxp_dive	vve_cred_mae_eeff.val_bg_var_pc_cxp_dive%TYPE,
        p_val_bg_var_pc	vve_cred_mae_eeff.val_bg_var_pc%TYPE,
        p_val_bg_var_pnc_bcos_dfina_lp	vve_cred_mae_eeff.val_bg_var_pnc_bcos_dfina_lp%TYPE,
        p_val_bg_var_pnc_otra_dfina_lp	vve_cred_mae_eeff.val_bg_var_pnc_otra_dfina_lp%TYPE,
        p_val_bg_var_pnc_cxp_srel	vve_cred_mae_eeff.val_bg_var_pnc_cxp_srel%TYPE,
        p_val_bg_var_pnc_otro_pnc	vve_cred_mae_eeff.val_bg_var_pnc_otro_pnc%TYPE,
        p_val_bg_var_pnc_gana_dife	vve_cred_mae_eeff.val_bg_var_pnc_gana_dife%TYPE,
        p_val_bg_var_pnc	vve_cred_mae_eeff.val_bg_var_pnc%TYPE,
        p_val_bg_var_tota_pasi	vve_cred_mae_eeff.val_bg_var_tota_pasi%TYPE,
        p_val_bg_var_pat_capi	vve_cred_mae_eeff.val_bg_var_pat_capi%TYPE,
        p_val_bg_var_pat_cap_adic	vve_cred_mae_eeff.val_bg_var_pat_cap_adic%TYPE,
        p_val_bg_var_pat_exce_reva	vve_cred_mae_eeff.val_bg_var_pat_exce_reva%TYPE,
        p_val_bg_var_pat_rese	vve_cred_mae_eeff.val_bg_var_pat_rese%TYPE,
        p_val_bg_var_pat_resu_acum	vve_cred_mae_eeff.val_bg_var_pat_resu_acum%TYPE,
        p_val_bg_var_pat_resu_ejer	vve_cred_mae_eeff.val_bg_var_pat_resu_ejer%TYPE,
        p_val_bg_var_pat_otro	vve_cred_mae_eeff.val_bg_var_pat_otro%TYPE,
        p_val_bg_var_pat	vve_cred_mae_eeff.val_bg_var_pat%TYPE,
        p_val_var_tota_pasi_patr 	vve_cred_mae_eeff.val_var_tota_pasi_patr %TYPE,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
  );
      PROCEDURE sp_ins_resumen_maturity
  (
        --p_cod_mae_eeff NUMBER,
        p_cod_solicitud                VARCHAR2,
        p_cod_cliente                  VARCHAR2,
        p_val_matu_ano_proy            NUMBER,
        p_cod_mone_eeff                VARCHAR2,
        p_val_matu_amor_deud_actu      vve_cred_mae_eeff.val_matu_amor_deud_actu%TYPE,
        p_val_matu_amor_deud_nuev      vve_cred_mae_eeff.val_matu_amor_deud_nuev%TYPE,
        p_val_matu_gast_fina_deud_actu vve_cred_mae_eeff.val_matu_gast_fina_deud_actu%TYPE,
        p_val_matu_gast_fina_deud_nuev vve_cred_mae_eeff.val_matu_gast_fina_deud_nuev%TYPE,
        p_val_matu_serv_deud	       vve_cred_mae_eeff.val_matu_serv_deud%TYPE,
        p_val_matu_ebitda_proy	       vve_cred_mae_eeff.val_matu_ebitda_proy%TYPE,
        p_val_matu_cash_flow_proy	   vve_cred_mae_eeff.val_matu_cash_flow_proy%TYPE,
        p_val_matu_fact_ebitda_sdeu   vve_cred_mae_eeff.val_matu_fact_ebitda_sdeu%TYPE,
        p_val_matu_fact_cashf_sdeu	   vve_cred_mae_eeff.val_matu_fact_cashf_sdeu%TYPE,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
  );
/*-----------------------------------------------------------------------------
      Nombre : sp_list_resumen_rango
      Proposito : Lista de informacion financiera en un rango de años.
      Referencias : 
      Parametros :  p_cod_solicitud    
                    p_cod_cliente,
                    p_cod_usua_sid,
                    p_cod_usua_web,
                    p_anio_sup ,
                    p_anio_inf ,
                    p_fec_solicitud 
                                   
      Log de Cambios
        Fecha        Autor          Descripcion
        01/07/2019   avilca     req-87567     Creacion
  ----------------------------------------------------------------------------*/
 PROCEDURE sp_list_resumen_rangos
  (
      p_cod_solicitud     VARCHAR2,
      p_cod_cliente       VARCHAR2,
      p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
      p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
      p_anio_sup          VARCHAR2,
      p_anio_inf          VARCHAR2,
      p_fec_solicitud     OUT VARCHAR2,
      p_ret_cursor        OUT SYS_REFCURSOR,
      p_ret_esta          OUT NUMBER,
      p_ret_mens          OUT VARCHAR2
  );
  
END;
