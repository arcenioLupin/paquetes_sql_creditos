create or replace PACKAGE       VENTA.PKG_SWEB_CRED_SOLI AS

  /********************************************************************************
    Nombre:     SP_INSE_CRED_SOLI
    Proposito:  Insertar la solicitud de crédito.
    Referencias:
    Parametros: P_COD_CLIE          ---> Código del Cliente.
                P_TIP_SOLI_CRED     ---> Tipo de Crédito.
                P_VAL_MON_FIN       ---> Monto a Financiar.
                P_CAN_PLAZ_MES      ---> Plazo del credito expresado en meses.
                P_TXT_OBSE_CREA     ---> Observaciones de registro.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_COD_SOLI_CRED ---> Código de ficha de venta generado.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        28/11/2018  PHRAMIREZ        Creación del procedure.
    2.0        25/03/2020  AVILCA           Modificación para guardar plazo factura crédito
  ********************************************************************************/

  PROCEDURE sp_inse_cred_soli
  (
        p_cod_clie            IN                    vve_cred_soli.cod_clie%TYPE,
        p_tip_soli_cred       IN                    vve_cred_soli.tip_soli_cred%TYPE,
        p_cod_mone_soli       IN                    vve_cred_soli.cod_mone_soli%TYPE,
        p_cod_banco           IN                    vve_cred_soli.cod_banco%TYPE,
        p_cod_estado          IN                    vve_cred_soli.cod_estado%TYPE,
        p_val_mon_fin         IN                    vve_cred_soli.val_mon_fin%TYPE,
        p_can_plaz_mes        IN                    vve_cred_soli.can_plaz_mes%TYPE,
        p_txt_obse_crea       IN                    vve_cred_soli.txt_obse_crea%TYPE,
        p_cod_res_fina        IN                    VARCHAR2,
        p_num_telf_movil      IN                    VARCHAR2,
        p_num_tele_fijo_ejec  IN                    vve_cred_soli.num_tele_fijo_ejec%TYPE,
        p_cod_sucursal        IN                    vve_cred_soli.cod_sucursal%TYPE,
        p_cod_filial          IN                    vve_cred_soli.cod_filial%TYPE,
        p_cod_area_venta      IN                    vve_cred_soli.cod_area_vta%TYPE,
        p_cod_vendedor        IN                    vve_cred_soli.vendedor%TYPE,
        p_cod_zona            IN                    vve_cred_soli.cod_zona%TYPE,
        p_dir_correo          IN                    VARCHAR2,
        p_num_prof_veh        IN                    VARCHAR2,
        p_val_vta_tot_fin     IN                    vve_cred_soli_prof.val_vta_tot_fin%TYPE,
        p_flag_registro       IN                    VARCHAR2,
        p_cod_empr            IN                    vve_cred_soli.cod_empr%TYPE,
        p_can_dias_fact_cred  IN                    VARCHAR2, /** Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/  
        p_cod_usua_sid        IN                    sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web        IN                    sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cod_soli_cred   OUT                   vve_cred_soli.cod_soli_cred%TYPE,
        p_ret_esta            OUT                   NUMBER,
        p_ret_mens            OUT                   VARCHAR2
    );


  /********************************************************************************
    Nombre:     SP_UPDATE_CRED_SOLI
    Proposito:  Actualizar solicitud de credito.
    Referencias:
    Parametros: P_COD_SOLI_CRED          ---> Código del Cliente.
                P_COD_PERSO              ---> Tipo de Crédito.
                P_NUM_TELF_MOVIL         ---> Monto a Financiar.
                P_DIR_CORREO             ---> Plazo del credito expresado en meses.
                P_COD_USUA_SID           ---> Código del usuario.
                P_RET_ESTA               ---> Id del usuario.
                P_RET_MENS               ---> Código de ficha de venta generado.


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        18/12/2018  MBARDALES        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_update_cred_soli
    (
        p_cod_zona              IN vve_cred_soli.cod_zona%TYPE,
        p_cod_area_vta          IN vve_cred_soli.cod_area_vta%TYPE,
        p_vendedor              IN vve_cred_soli.vendedor%TYPE,
        p_cod_filial            IN vve_cred_soli.cod_filial%TYPE,
        p_cod_sucursal          IN vve_cred_soli.cod_sucursal%TYPE,
        p_cod_soli_cred         IN vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_estado            IN vve_cred_soli.cod_estado%TYPE,
        p_cod_perso             IN VARCHAR2,
        p_num_prof_veh          IN VARCHAR2,
        p_num_telf_movil        IN VARCHAR2,
        p_dir_correo            IN VARCHAR2,
        p_obse_crea             IN VARCHAR2,
        p_tip_soli_cred         IN VARCHAR2,
        p_cod_resp_fina         IN VARCHAR2,
        p_can_plaz_mes          IN vve_cred_soli.can_plaz_mes%TYPE,
        p_cod_moneda_prof       IN VARCHAR2,
        p_val_vta_tot_fin       IN vve_cred_soli_prof.val_vta_tot_fin%TYPE,
        p_txt_obse_gest_banc    IN vve_cred_soli.txt_obse_gest_banc%TYPE,
        p_cod_esta_gest_banc    IN vve_cred_soli.cod_esta_gest_banc%TYPE,
        p_flag_actualiza        IN VARCHAR2,
        p_ven_factura           IN VARCHAR2, 
        p_cod_banco             IN VARCHAR2, --Req. 87567 E1 ID 27 AVILCA 01/07/2020 
        p_telf_fijo             IN VARCHAR2, --Req. 87567 E1 ID 27 AVILCA 01/07/2020 
        p_cod_usua_sid          IN sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta              OUT NUMBER,
        p_ret_mens              OUT VARCHAR2
    );

  /********************************************************************************
    Nombre:     SP_LIST_CRED_SOLI
    Proposito:  Listar las solicitudes de crédito.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Código de solicitud.
                P_FEC_SOLI_CRED     ---> Fecha de creación de solicitud.
                P_COD_AREA_VTA      ---> Código de área de venta.
                P_TIP_SOLI_CRED     ---> Tipo de solicitud.
                P_COD_CLIE          ---> Código de cliente.
                P_COD_RESP_FINA     ---> Código de responsable de financiemiento.
                P_COD_ESTADO        ---> Código de estado de la solicitud.
                P_COD_EMPR          ---> Código de empresa.
                P_COD_ZONA          ---> Código de zona o región.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_IND_PAGINADO      ---> Indica si se realizara la paginación S:SI, N:NO
                P_LIMITINF          ---> Inicio de regisitros.
                P_LIMITSUP          ---> Fin de registros.
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        28/11/2018  PHRAMIREZ        Creación del procedure.
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

  PROCEDURE sp_list_proforma
  (
    p_cod_clie        IN                VARCHAR2,
    p_num_prof_veh 	  IN 				VARCHAR2,
    p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor      OUT               SYS_REFCURSOR,
    p_ret_esta        OUT               NUMBER,
    p_ret_mens        OUT               VARCHAR2
  );

  PROCEDURE sp_actu_gest_banc 
  (
    p_cod_soli_cred             IN          vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_banco                 IN          vve_cred_soli.cod_banco%TYPE,
    p_val_mont_fin              IN          vve_cred_soli.val_mon_fin%TYPE,
    p_cod_mone_soli             IN          vve_cred_soli.cod_mone_soli%TYPE,    
    p_val_mont_sol_gest_banc    IN          vve_cred_soli.val_mont_sol_gest_banc%TYPE,        
    p_val_porc_gest_banc        IN          vve_cred_soli.val_porc_gest_banc%TYPE,    
    p_fec_ingr_gest_banc        IN          VARCHAR2,                    
    p_fec_ingr_ries_gest_banc   IN          VARCHAR2,        
    p_fec_aprob_cart_ban        IN          VARCHAR2,   
    p_fec_resu_gest_banc        IN          VARCHAR2,  
    p_cod_esta_gest_banc        IN          vve_cred_soli.cod_esta_gest_banc%TYPE,
    p_txt_obse_gest_banc        IN          vve_cred_soli.txt_obse_gest_banc%TYPE,
    p_cod_usua_sid              IN          sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta                  OUT         NUMBER,
    p_ret_mens                  OUT         VARCHAR2
  );

  PROCEDURE sp_list_vehiculos
  (
    p_cod_soli_cred   IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_ind_consulta    IN                VARCHAR2,
    p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor      OUT               SYS_REFCURSOR,
    p_ret_esta        OUT               NUMBER,
    p_ret_mens        OUT               VARCHAR2
  );

  PROCEDURE sp_inse_soli_veh
  (
    p_cod_soli_cred      IN     vve_cred_soli_pedi_veh.cod_soli_cred%TYPE,
    p_cod_cia            IN     vve_cred_soli_pedi_veh.cod_cia%TYPE,
    p_cod_prov           IN     vve_cred_soli_pedi_veh.cod_prov%TYPE,
    p_num_pedido_veh     IN     vve_cred_soli_pedi_veh.num_pedido_veh%TYPE,
    p_txt_ruta_veh       IN     vve_cred_soli_pedi_veh.txt_ruta_veh%TYPE,
    p_can_asientos       IN     vve_cred_soli_pedi_veh.can_asientos%TYPE,
    p_cod_usua_sid       IN     sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta           OUT    NUMBER,
    p_ret_mens           OUT    VARCHAR2
  );

  PROCEDURE sp_actu_indi_vehiculo
  (
    p_num_pedido_veh     IN     vve_cred_soli_pedi_veh.num_pedido_veh%TYPE,
    p_indicativo         IN     VARCHAR2, 
    p_cod_usua_sid       IN     sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta           OUT    NUMBER,
    p_ret_mens           OUT    VARCHAR2
  );

  PROCEDURE sp_inse_info_sbs
  (
    p_cod_clasif_sbs_clie             IN      vve_cred_soli_isbs.cod_clasif_sbs_clie%TYPE,       
    p_cod_clasif_sbs_repr             IN      vve_cred_soli_isbs.cod_clasif_sbs_repr%TYPE,
    p_cod_persona_clie                IN      vve_cred_soli_isbs.cod_persona_clie%TYPE,
    p_cod_persona_repr                IN      vve_cred_soli_isbs.cod_persona_repr%TYPE,
    p_cod_ries_dive_clie              IN      vve_cred_soli_isbs.cod_ries_dive_clie%TYPE,
    p_cod_ries_dive_repr              IN      vve_cred_soli_isbs.cod_ries_dive_repr%TYPE,
    p_cod_soli_cred                   IN      vve_cred_soli_isbs.cod_soli_cred%TYPE,
    p_ind_cond_ruc_clie               IN      vve_cred_soli_isbs.ind_cond_ruc_clie%TYPE,
    p_ind_cond_ruc_repr               IN      vve_cred_soli_isbs.ind_cond_ruc_repr%TYPE,
    p_txt_link_sbs_clie               IN      vve_cred_soli_isbs.txt_link_sbs_clie%TYPE,
    p_txt_link_sbs_repr               IN      vve_cred_soli_isbs.txt_link_sbs_repr%TYPE,
    p_val_deud_actu_clie              IN      vve_cred_soli_isbs.val_deud_actu_clie%TYPE,
    p_val_deud_actu_repr              IN      vve_cred_soli_isbs.val_deud_actu_repr%TYPE,    
    p_val_deud_cier_ano_actu_clie     IN      vve_cred_soli_isbs.val_deud_cier_ano_actu_clie%TYPE,
    p_val_deud_cier_ano_actu_repr     IN      vve_cred_soli_isbs.val_deud_cier_ano_actu_repr%TYPE,
    p_val_deud_cier_ano_ante_clie     IN      vve_cred_soli_isbs.val_deud_cier_ano_ante_clie%TYPE,
    p_val_deud_cier_ano_ante_repr     IN      vve_cred_soli_isbs.val_deud_cier_ano_ante_repr%TYPE,
    p_val_deud_venci_clie             IN      vve_cred_soli_isbs.val_deud_venci_clie%TYPE,
    p_val_deud_venci_repr             IN      vve_cred_soli_isbs.val_deud_venci_repr%TYPE,
    p_val_impa_clie                   IN      vve_cred_soli_isbs.val_impa_clie%TYPE,
    p_val_impa_repr                   IN      vve_cred_soli_isbs.val_impa_repr%TYPE,
    p_val_prot_sin_regu_clie          IN      vve_cred_soli_isbs.val_prot_sin_regu_clie%TYPE,
    p_val_prot_sin_regu_repr          IN      vve_cred_soli_isbs.val_prot_sin_regu_repr%TYPE,
    p_val_prot_regu_clie              IN      vve_cred_soli_isbs.val_prot_regu_clie%TYPE,
    p_val_prot_regu_repr              IN      vve_cred_soli_isbs.val_prot_regu_repr%TYPE,
    p_cod_usua_sid                    IN      sistemas.usuarios.co_usuario%TYPE,  
    p_cod_cred_soli_sbs               OUT     vve_cred_soli_isbs.cod_cred_soli_sbs%TYPE,
    p_ret_esta                        OUT     NUMBER,
    p_ret_mens                        OUT     VARCHAR2
  );

  PROCEDURE sp_list_info_sbs
  (
    p_cod_soli_cred   IN                vve_cred_soli_isbs.cod_soli_cred%TYPE,
    p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor      OUT               SYS_REFCURSOR,
    p_ret_esta        OUT               NUMBER,
    p_ret_mens        OUT               VARCHAR2
  );



  PROCEDURE sp_datos_hist_oper
    (
        p_cod_oper        IN                VARCHAR2,
        p_cod_clie        IN                vve_cred_soli.cod_clie%TYPE,
        p_no_cia          IN                VARCHAR2,
        p_cod_usua_sid    IN 			    sistemas.usuarios.co_usuario%TYPE,
        p_ret_cursor      OUT               SYS_REFCURSOR,
        p_ret_esta        OUT               NUMBER,
        p_ret_mens        OUT               VARCHAR2
    );

  PROCEDURE sp_list_cred_soli_reso_cred
  (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_fec_venc_1ra_let    IN                VARCHAR2,
    p_fec_apro_clie       IN                VARCHAR2,
    p_txt_info_adic       IN                vve_cred_soli.txt_info_adic%TYPE,
    p_txt_info_oper       IN                vve_cred_soli.txt_info_oper%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_fec_contrato        IN                VARCHAR2,
    p_plazo_fact_cred     IN                VARCHAR2,/**Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
	p_monto_financiar     IN                vve_cred_soli.val_mon_fin%TYPE,/**Req. 87567 E2.1 ID: 309 - avilca 14/04/2021 **/
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
  );

  PROCEDURE sp_list_resu_reso_cred
  (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
  );

  PROCEDURE sp_inse_cred_soli_aprob
  (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_num_prof_veh        IN                vve_cred_soli_prof.num_prof_veh%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
  );

  PROCEDURE sp_actu_cred_soli_aprob
  (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_valor_estado        IN                VARCHAR2,
    p_txt_coment          IN                VARCHAR2,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web        IN                sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
  );

  PROCEDURE sp_list_formato_recon_deuda
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2  
  );
  
  PROCEDURE sp_list_formato_leasing
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2  
  ); 

  PROCEDURE sp_list_formato_mutuo
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2  
  );  

  /********************************************************************************
    Nombre:     SP_PERM_USUA_SOLCRE
    Proposito:  Accede a los permisos asignados a los usuarios que utilizan el 
                módulo de gestión de créditos.
    Referencias:
    Parametros: P_COD_SOLI_CRED ---> Código de solicitud.
                P_COD_USUA_SID  ---> Código del usuario.
                P_COD_USUA_WEB  ---> Id del usuario.
                P_RET_CURSOR    ---> Listado de permisos asignados.
                P_RET_ESTA      ---> Estado del proceso.
                P_RET_MENS      ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        27/06/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_list_perm_usua_solcre
  (
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid  IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR
  );  

  PROCEDURE sp_list_roles
  (
    p_cod_rol           IN  VARCHAR2,
    p_cod_rol_jef_fi    IN  VARCHAR2,
    p_num_prof_veh      IN  VARCHAR2,
    p_cod_clie          IN  VARCHAR2,
    p_cod_zona          IN  VARCHAR2,
    p_cod_filial        IN  VARCHAR2,
    p_cod_area_vta      IN  VARCHAR2,    
    p_flag_busq         IN  VARCHAR2,
    p_flag_edit         IN  VARCHAR2,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  FUNCTION fn_list_proforma 
  (
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_ind_todos     IN CHAR
  ) RETURN SYS_REFCURSOR;


  PROCEDURE sp_inse_cred_soli_hist
  (
    p_cod_soli_cred     IN  vve_cred_soli_hist.cod_soli_cred%TYPE,
    p_val_lc_actu       IN  vve_cred_soli_hist.val_lc_actual%TYPE,
    p_fec_plaz          IN  VARCHAR2,    
    p_val_lc_util       IN  vve_cred_soli_hist.val_lc_util%TYPE,  
    p_val_dven_dc       IN  vve_cred_soli_hist.VAL_MONT_DVEN_DC%TYPE, 
    p_val_dven_di       IN  vve_cred_soli_hist.VAL_MONT_DVEN_DI%TYPE, 
    p_val_porc_dc       IN  vve_cred_soli_hist.VAL_PORC_DVEN_DC%TYPE, 
    p_val_porc_di       IN  vve_cred_soli_hist.VAL_PORC_DVEN_DI%TYPE, 
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod           OUT VARCHAR2, 
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  

  PROCEDURE sp_inse_cred_hist_ope
  (
    p_cod_cred_soli_hist    IN  vve_cred_hist_ope.cod_cred_soli_hist%TYPE,
    p_cod_soli_cred         IN  vve_cred_hist_ope.cod_soli_cred%TYPE,
    p_cod_cia               IN  vve_cred_hist_ope.cod_cia%TYPE,
    p_cod_tip_cred          IN  vve_cred_hist_ope.cod_tip_cred%TYPE,    
    p_cod_oper              IN  vve_cred_hist_ope.cod_oper%TYPE, 
    p_cod_moneda            IN  vve_cred_hist_ope.cod_moneda%TYPE, 
    p_val_monto_cred        IN  vve_cred_hist_ope.val_monto_cred%TYPE, 
    p_can_letras            IN  vve_cred_hist_ope.can_letras%TYPE, 
    p_val_tea               IN  vve_cred_hist_ope.val_tea%TYPE, 
    p_val_saldo             IN  vve_cred_hist_ope.val_saldo%TYPE, 
    p_fec_ult_venc          IN  VARCHAR2, 
    p_cod_estado_op         IN  vve_cred_hist_ope.cod_estado_op%TYPE, 
    p_fec_emi_op            IN  VARCHAR2, 
    p_val_porc_ci           IN  vve_cred_hist_ope.val_porc_ci%TYPE, 
    p_val_val_gar           IN  vve_cred_hist_ope.val_val_gar%TYPE, 
    p_val_porc_rat_gar      IN  vve_cred_hist_ope.val_porc_rat_gar%TYPE, 
    p_cod_clie              IN  vve_cred_hist_ope.cod_clie%TYPE, 
    p_dias_max_venc         IN  vve_cred_hist_ope.DIAS_MAX_VENC%TYPE,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
    p_dias_venc_prom        IN  vve_cred_hist_ope.DIAS_VENC_PROM%TYPE,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
    p_cod_usua_sid          IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod               OUT VARCHAR2, 
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
  );

  --ECUBAS <I>89642
  PROCEDURE sp_list_motivos_aprobacion
  ( 
    p_cod_soli_cred   IN                vve_cred_hist_ope.cod_soli_cred%TYPE,
    p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor      OUT               SYS_REFCURSOR,
    p_ret_esta        OUT               NUMBER,
    p_ret_mens        OUT               VARCHAR2
  );
  --ECUBAS <F>89642
  --<I Req. 87567 E2.1 ID:9 AVILCA 12/05/2020>
   PROCEDURE sp_list_param_solcre
  (
    p_cod_param         IN  VARCHAR2,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  --<F Req. 87567 E2.1 ID:9 AVILCA 12/05/2020>  

   --<I Req. 87567 E2.1 ID:9 AVILCA 10/02/2021>
     PROCEDURE sp_list_clie_creditos
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

    PROCEDURE sp_list_clie_movimientos
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
 --<F Req. 87567 E2.1 ID:9 AVILCA 10/02/2021>
END PKG_SWEB_CRED_SOLI;