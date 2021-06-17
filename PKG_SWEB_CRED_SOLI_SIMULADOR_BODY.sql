create or replace PACKAGE BODY     VENTA.PKG_SWEB_CRED_SOLI_SIMULADOR AS

  PROCEDURE sp_list_comp_segu
  (
    p_cod_ciaseg     IN gen_ciaseg.cod_ciaseg%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
  BEGIN
     OPEN p_ret_cursor FOR
        SELECT p.nom_perso, c.cod_ciaseg
         FROM gen_ciaseg c
        INNER JOIN gen_persona p
        ON c.cod_ciaseg = p.cod_perso
        WHERE (p_cod_ciaseg is null
            OR c.cod_ciaseg = p_cod_ciaseg)
        ORDER BY p.nom_perso;
           
    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutado de forma exitosa';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_COMP_SEGU:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_COMP_SEGU',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);        
  END sp_list_comp_segu;
  
  PROCEDURE sp_list_maes_conc_letr
  (
    p_cod_conc_col   IN vve_cred_maes_conc_letr.cod_conc_col%TYPE,
    p_ind_conc_oblig IN vve_cred_maes_conc_letr.ind_conc_oblig%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
  BEGIN
     OPEN p_ret_cursor FOR
        SELECT mcl.cod_conc_col,
               mcl.des_conc,
               mcl.ind_conc_oblig
         FROM vve_cred_maes_conc_letr mcl
        WHERE (p_cod_conc_col = 0
            OR mcl.cod_conc_col = p_cod_conc_col)
         AND mcl.ind_conc_oblig = NVL(p_ind_conc_oblig, 'S') 
        ORDER BY mcl.cod_conc_col;
           
    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutada de forma exitosa';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_MAES_CONC_LETR:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_MAES_CONC_LETR',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL); 
  END sp_list_maes_conc_letr;  

  PROCEDURE sp_list_prof_apro
  (
    p_num_prof_veh   IN vve_cred_soli_prof.num_prof_veh%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS

   n_ficha_vta   VVE_FICHA_VTA_PROFORMA_VEH.NUM_FICHA_VTA_VEH%TYPE;
   ve_error      EXCEPTION;
   
  BEGIN
    IF p_num_prof_veh IS NOT NULL THEN 
        SELECT NUM_FICHA_VTA_VEH INTO n_ficha_vta FROM vve_ficha_vta_proforma_veh WHERE NUM_PROF_VEH = p_num_prof_veh;
    END IF;
    
    -- DEVUELVE LA GRILLA DE PROFORMAS APROBADAS QUE PERTENECEN A LA MISMA FICHA DE VENTA DE LA PROF. QUE ORIGINA LA SOLICITU DE CREDITO
    -- EN LA GRILLA DE LA PANTALLA HAY QUE ORDENAR LOS CAMPOS QUE DEVUELVE (NO SE DEBE PINTAR EL NRO DE PEDIDO)
    OPEN p_ret_cursor FOR    
        SELECT  p2.ano_fabricacion_veh,                -- año de fabrica
                a.* 
                FROM (SELECT p.num_prof_veh,           -- nro. proforma
                             f.num_ficha_vta_veh,      -- nro. ficha vta
                             p.cod_familia_veh,        -- familia
                             p.cod_tipo_veh,           -- tipo de vehículo
                             p.cod_marca,              -- marca
                             p.cod_baumuster,          -- modelo
                             p.can_veh,                --cantidad de vehículos
                             p.val_pre_config_veh,     -- precio de vta unitario
                             p.val_pre_veh*p.can_veh,  -- monto total de la operación 
                             p.num_pedido_veh          -- nro. pedido
                        FROM vve_ficha_vta_proforma_veh f
                        INNER JOIN vve_proforma_veh p1 
                        ON f.num_ficha_vta_veh = n_ficha_vta 
                        AND f.num_prof_veh = p1.num_prof_veh
                        AND p1.fec_aprob_prof_veh IS NOT NULL
                        INNER JOIN vve_proforma_veh_det p 
                        ON p1.num_prof_veh = p.num_prof_veh) a 
        LEFT JOIN vve_pedido_veh p2
        ON a.num_prof_veh = p2.num_prof_veh
        AND a.num_pedido_veh = p2.num_pedido_veh;
        
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta     := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_PROF_APRO',
                                            p_cod_usua_sid,
                                            'Error en la consulta',
                                            p_ret_mens,
                                            NULL);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_PROF_APRO_WEB:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_APRO',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);    

  END sp_list_prof_apro;

  PROCEDURE sp_obt_tasa_seg
  (
    p_cod_cia        IN vve_cred_soli.cod_empr%TYPE,
    p_cod_tipo_veh   IN vve_proforma_veh_det.cod_tipo_veh%TYPE,
    p_ind_tip_uso    IN vve_tabla_maes.cod_tipo%TYPE,
    p_cod_cliente    IN vve_cred_soli.cod_clie%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tasa_seg       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
  
  kn_cod_grupo       vve_tabla_maes.cod_grupo%TYPE := 97;
  kc_cod_tipo_urba   vve_tabla_maes.cod_tipo%TYPE := 'TUV01';
  kc_cod_tipo_inte   vve_tabla_maes.cod_tipo%TYPE := 'TUV02';
  kc_tip_clie_dive   vve_tabla_maes.valor_adic_1%TYPE := 'D';
  kc_tip_clie_ext    vve_tabla_maes.valor_adic_1%TYPE := 'E';
  ve_error           EXCEPTION;
  
  BEGIN
    IF (P_COD_CIA IS NOT NULL AND P_COD_TIPO_VEH IS NOT NULL) THEN
      BEGIN  
        SELECT a.val_tasa_final 
        INTO   P_TASA_SEG
        FROM   vve_cred_agru_veh_seg a 
        INNER JOIN vve_cred_tipo_veh_agru t
        ON    a.NO_CIA = P_COD_CIA  
        AND   t.cod_tipo_veh = P_COD_TIPO_VEH 
        AND   t.COD_AGRU_VEH_SEG = a.COD_AGRU_VEH_SEG 
        AND ((t.cod_tip_uso IS NOT NULL AND 
             t.cod_tip_uso = P_IND_TIP_USO AND EXISTS (SELECT 1 FROM vve_tabla_maes m 
                                                        WHERE m.cod_grupo = kn_cod_grupo 
                                                          AND m.cod_tipo IN (kc_cod_tipo_inte,kc_cod_tipo_urba) 
                                                          )
              )
             OR 
             (t.ind_tipo_clie IS NOT NULL AND  
              NOT EXISTS (SELECT 1 FROM vve_tabla_maes m 
                           WHERE m.cod_grupo = kn_cod_grupo 
                             AND (m.cod_tipo = kc_cod_tipo_inte or m.cod_tipo = kc_cod_tipo_urba)  
                             )
             and ((SELECT (CASE WHEN U.COD_ID_USUARIO IS NOT NULL THEN 'D' END ) 
                                                    FROM SISTEMAS.SIS_MAE_USUARIO U, GENERICO.GEN_PERSONA P
                                                    WHERE  RTRIM(P.APE_PATERNO||' '||P.APE_MATERNO) = U.TXT_APELLIDOS 
                                                    AND RTRIM(P.NOM_1||' '||P.NOM_2) = U.TXT_NOMBRES
                                                    AND (p_cod_cliente IS NULL OR P.COD_PERSO = p_cod_cliente)
                   ) = 'D' 
                   or 
                  (SELECT (CASE WHEN U.COD_ID_USUARIO IS NOT NULL THEN 'D' END ) 
                                                    FROM SISTEMAS.SIS_MAE_USUARIO U, GENERICO.GEN_PERSONA P
                                                    WHERE  RTRIM(P.APE_PATERNO||' '||P.APE_MATERNO) = U.TXT_APELLIDOS 
                                                    AND RTRIM(P.NOM_1||' '||P.NOM_2) = U.TXT_NOMBRES
                                                    AND (p_cod_cliente IS NULL OR P.COD_PERSO = p_cod_cliente)
                   ) is null and t.ind_tipo_clie = 'E' )
                )
             OR 
             (t.cod_tip_uso IS NULL and ind_tipo_clie IS NULL)
            );
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                p_tasa_seg := 0;
        END;        
    END IF;
    
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
    
  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_OBT_TASA_SEG',
                                            p_cod_usua_sid,
                                            'Error en la consulta',
                                            p_ret_mens,
                                            NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_OBT_TASA_SEG_WEB:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBT_TASA_SEG',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);    

  END sp_obt_tasa_seg;
  
  PROCEDURE sp_calc_prima_seg
  (
    p_tasa_seg       IN vve_cred_soli.val_tasa_segu%TYPE,
    p_plazo_meses    IN vve_cred_soli.can_plaz_mes%TYPE,
    p_monto_vta      IN vve_proforma_veh_det.val_pre_veh%TYPE, -- p.val_pre_veh*p.can_veh
    p_porc_igv       IN NUMBER,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_prima_seg      OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
  
  kn_cte             NUMBER(10,2) := 1.03;
  
  BEGIN
    p_prima_seg := p_monto_vta*p_tasa_seg*kn_cte*(1+p_porc_igv)*p_plazo_meses/12;
  END sp_calc_prima_seg;
  
  PROCEDURE sp_gene_crono
  (
    p_cod_simu           IN vve_cred_simu_gast.cod_simu%TYPE,
    p_cod_gru_tip_cred   IN vve_tabla_maes.cod_grupo%TYPE,
    p_cod_tip_cred       IN vve_tabla_maes.cod_tipo%TYPE,
    p_mon_vta            IN vve_cred_soli_prof.val_vta_tot_fin%TYPE,
    p_porc_cuo_ini       IN vve_cred_soli.val_porc_ci%TYPE,
    p_periodicidad       IN vve_tabla_maes.valor_adic_1%TYPE,
    p_prima_seg          IN vve_cred_soli.val_prim_seg%TYPE,
    p_nro_cuotas         IN vve_cred_soli.can_tota_letr%TYPE,
    p_plaz_mes           IN vve_cred_soli.can_plaz_mes%TYPE,
    p_porc_cb            IN vve_cred_soli.val_porc_cuot_ball%TYPE,
    p_cod_gru_tip_pgra   IN vve_tabla_maes.cod_grupo%TYPE,
    p_cod_tip_pgra       IN vve_tabla_maes.cod_tipo%TYPE,
    p_val_dias_pgra      IN vve_cred_soli.val_dias_peri_grac%TYPE,
    p_val_mon_int_pgra   IN vve_cred_soli.val_int_per_gra%TYPE,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ) 
  AS
      CURSOR c_cursor IS
        SELECT cod_conc_col,
            0 val_mon_total,
            '' ind_fin,
            0 val_mon_per
        FROM vve_cred_maes_conc_letr
        WHERE ind_conc_oblig = 'S'
        UNION ALL
        SELECT cod_conc_col,
            val_mon_total,
            ind_fin,
            val_mon_per            
        FROM vve_cred_simu_gast 
        WHERE cod_simu = p_cod_simu;  
  
      ln_mon_a_fin              vve_cred_soli.val_mon_fin%TYPE;             -- Monto a financiar (depende del tipo de crédito).
      ln_mon_calc_cuo           vve_cred_soli.val_mon_fin%TYPE;             -- Monto para calcular la cuota (Monto a financiar - cuota balloon)
      kn_grupo_tipo_cred        vve_tabla_maes.cod_grupo%TYPE    := 86;     -- Grupo para Tipos de Crédito.
      kc_cod_tipo_cred_cd       vve_tabla_maes.cod_tipo%TYPE     := 'TC01'; -- Reconocimiento de deuda o crédito directo.
      kc_cod_tipo_cred_cl       vve_tabla_maes.cod_tipo%TYPE     := 'TC02'; -- Reconocimiento de deuda Leasing.
      kc_cod_tipo_cred_cm       vve_tabla_maes.cod_tipo%TYPE     := 'TC03'; -- Crédito mutuo.
      kc_cod_tipo_cred_fc       vve_tabla_maes.cod_tipo%TYPE     := 'TC04'; -- Crédito de Factura al crédito.
      kc_cod_tipo_cred_pv       vve_tabla_maes.cod_tipo%TYPE     := 'TC05'; -- Crédito post-venta.
      kc_cod_tipo_cred_gb       vve_tabla_maes.cod_tipo%TYPE     := 'TC06'; -- Crédito Gestión Bancaria.
      kn_grupo_tipo_pgra        vve_tabla_maes.cod_grupo%TYPE    := 89;     -- Grupo para Tipos de Periodo de Gracia.
      kc_cod_tipo_pgra_p        vve_tabla_maes.cod_tipo%TYPE     := 'PG01'; -- Periodo de gracia parcial.
      kc_cod_tipo_pgra_t        vve_tabla_maes.cod_tipo%TYPE     := 'PG02'; -- Periodo de gracia parcial.
      ln_saldo_inicial          vve_cred_soli.val_mon_fin%TYPE   := 0;
      ln_nro_letr_cuo           vve_cred_soli.can_tota_letr%TYPE := 0;
      ln_mon_cap_cb             vve_cred_soli.val_cuot_ball%TYPE := 0;
      kn_grupo_per_cred_sol     vve_tabla_maes.cod_grupo%TYPE    := 88;     -- Grupo para Periodicidad de Cuotas.
      ln_val_meses_periodo      NUMBER;
      ln_val_dias_periodo       NUMBER;
      ln_val_periodo_finan      NUMBER; 
      ln_fec_vcto               DATE;
      ln_cod_soli_cred          vve_cred_soli.cod_soli_cred%TYPE;
      ln_tip_soli_cred          vve_cred_soli.tip_soli_cred%TYPE;  
      ln_cod_moneda_prof        vve_cred_simu.cod_moneda%TYPE;
      ln_val_ci                 vve_cred_simu.val_ci%TYPE;
      ln_val_pago_cont_ci       vve_cred_simu.val_pag_cont_ci%TYPE;
      ln_fec_venc_1ra_let       vve_cred_simu.fec_venc_1ra_let%TYPE;
      ln_can_dias_venc_1ra_letr vve_cred_simu.can_dias_venc_1ra_letr%TYPE;
      ln_val_porc_tea_sigv      vve_cred_simu.val_porc_tea_sigv%TYPE;
      ln_can_tot_let            vve_cred_simu.can_tot_let%TYPE;
      ln_can_let_per_gra        vve_cred_simu.can_let_per_gra%TYPE;
      ln_ind_gps                vve_cred_simu.ind_gps%TYPE;
      ln_ind_tip_seg            vve_cred_simu.ind_tip_seg%TYPE;
      ln_cod_cia_seg            vve_cred_simu.cod_cia_seg%TYPE;
      ln_cod_tip_uso_veh        vve_cred_simu.cod_tip_uso_veh%TYPE;
      ln_val_tasa_segu          vve_cred_simu.val_tasa_seg%TYPE;
      ln_val_prima_segu_per     vve_cred_simu.val_prima_seg%TYPE;
      ln_cod_tipo_unid          vve_cred_simu.cod_tip_unidad%TYPE;  		
      ln_val_porc_gast_admi 	vve_cred_simu.val_porc_gast_adm%TYPE;
      ln_val_gasto_admi         vve_cred_simu.val_gast_adm%TYPE;
      ln_val_porc_tea_m_sigv    NUMBER;
      ln_val_porc_tea_cigv      NUMBER;
      ln_val_porc_tea_m_cigv    NUMBER;
      ln_tasa_nom_anual_cigv    NUMBER;
      ln_tasa_nom_anual_sigv    NUMBER;
      ln_tasa_nom_m_sigv        NUMBER;
      ln_nro_cuotas             NUMBER;
      ln_val_mon_fin            NUMBER;
      ln_mon_calc               NUMBER;
      ln_val_int                NUMBER;
      ln_sal_ini_cuo            NUMBER := 0;
      ln_amo_cap_cuo            NUMBER := 0;
      ln_val_int_cuo            NUMBER;
      ln_val_igv_cuo            NUMBER;
      ln_sal_fin_cuo            NUMBER;
      ln_mon_calc_letr          NUMBER;
      ln_igv                    NUMBER := 1.18;
      ln_val_capi_cuo_bal       NUMBER;
      ln_val_cuo_bal            NUMBER;
      ln_val_cuo_bal_men        NUMBER;
      lt_tir_value_list         VVE_TYTA_TIR_LIST;
      ln_val_tir                NUMBER;
      ln_val_tcea               NUMBER;
      lv_exists_solcre          CHAR(1) := 'S';
      ln_tmp_sal_fin_cuo        NUMBER := 0;
      ln_dif_cuota              NUMBER;
      lv_ind_pgra_sint          VARCHAR2(2);
      
      lv_fec_max_simu  VARCHAR2(10);
      lv_fec_min_simu  VARCHAR2(10);      
  BEGIN  
    --Obtener los valores de la periodicidad seleccionada
    SELECT 12 / valor_adic_1, 
           valor_adic_2,
           valor_adic_1
    INTO ln_val_meses_periodo, 
         ln_val_dias_periodo,
         ln_val_periodo_finan
    FROM vve_tabla_maes
    WHERE cod_tipo = p_periodicidad
        AND cod_grupo = kn_grupo_per_cred_sol;
    
    --Obtener valores de la tabla de solicitud de crédito
    BEGIN 
        SELECT cod_soli_cred,
               tip_soli_cred
        INTO ln_cod_soli_cred,
             ln_tip_soli_cred
        FROM vve_cred_soli
        WHERE cod_soli_cred = (
            SELECT cod_soli_cred
            FROM vve_cred_simu
            WHERE cod_simu = p_cod_simu
                AND ind_inactivo = 'N'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            lv_exists_solcre := 'N';
    END;    
    
    --Obtener valores de la tabla de parametros del simulador
    SELECT cod_moneda,
           val_ci,
           val_pag_cont_ci,
           fec_venc_1ra_let,
           can_dias_venc_1ra_letr,
           val_porc_tea_sigv,
           val_porc_tep_sigv,  
           can_tot_let,
           can_let_per_gra,
           val_cuo_bal,
           ind_gps,
           ind_tip_seg,
           cod_tip_uso_veh,
           cod_cia_seg,
           val_tasa_seg,
           cod_tip_unidad,
           val_porc_gast_adm,
           val_gast_adm,
           ind_pgra_sint
    INTO ln_cod_moneda_prof, 
         ln_val_ci,
         ln_val_pago_cont_ci,
         ln_fec_venc_1ra_let,
         ln_can_dias_venc_1ra_letr,
         ln_val_porc_tea_sigv,
         ln_val_porc_tea_m_sigv,
         ln_can_tot_let,
         ln_can_let_per_gra,
         ln_val_cuo_bal,
         ln_ind_gps,
         ln_ind_tip_seg,
         ln_cod_tip_uso_veh,
         ln_cod_cia_seg,
         ln_val_tasa_segu,
         ln_cod_tipo_unid,
         ln_val_porc_gast_admi,
         ln_val_gasto_admi,
         lv_ind_pgra_sint
    FROM vve_cred_simu
    WHERE cod_simu = p_cod_simu
        AND ind_inactivo = 'N';
    
    --Actualizar valores en tabla de solicitud de crédito
    IF lv_exists_solcre = 'S' THEN
        UPDATE vve_cred_soli
        SET val_porc_ci = p_porc_cuo_ini,
            val_ci = ln_val_ci,
            val_mon_fin = p_mon_vta,
            val_pago_cont_ci = ln_val_pago_cont_ci,
            fec_venc_1ra_let = ln_fec_venc_1ra_let,
            can_dias_venc_1ra_letr = ln_val_dias_periodo + p_val_dias_pgra,
            cod_peri_cred_soli = p_periodicidad,
            can_tota_letr = p_nro_cuotas,
            can_plaz_mes = p_plaz_mes,
            ind_tipo_peri_grac = p_cod_tip_pgra,
            val_dias_peri_grac = p_val_dias_pgra,
            can_letr_peri_grac = ln_can_let_per_gra,
            val_int_per_gra = p_val_mon_int_pgra,
            val_porc_tea_sigv = ln_val_porc_tea_sigv,
            val_porc_tep_sigv = ln_val_porc_tea_m_sigv,
            ind_gps	= ln_ind_gps,		
            val_porc_cuot_ball = p_porc_cb, 	
            val_cuot_ball = ln_val_cuo_bal,		
            ind_tipo_segu = ln_ind_tip_seg,		
            cod_cia_seg = ln_cod_cia_seg,		
            cod_tip_uso_veh = ln_cod_tip_uso_veh,	
            val_tasa_segu = ln_val_tasa_segu,		
            val_prim_seg = p_prima_seg,		
            cod_tipo_unid = ln_cod_tipo_unid,		
            val_porc_gast_admi = ln_val_porc_gast_admi,
            val_gasto_admi = ln_val_gasto_admi,
            cod_usua_modi = p_cod_usua_sid,
            fec_modi_regi = SYSDATE       
        WHERE cod_soli_cred = ln_cod_soli_cred;
    END IF;        
    
    --Se calculan los valores necesarios para la generación de las cuotas
    ln_mon_a_fin           := p_mon_vta; 
    ln_fec_vcto            := SYSDATE; 
    ln_nro_cuotas          := p_nro_cuotas + ln_can_let_per_gra;
    if ln_val_porc_tea_sigv >0 then 
      ln_val_porc_tea_cigv   := ln_val_porc_tea_sigv * ln_igv;
      ln_val_porc_tea_m_cigv := POWER((1 + ln_val_porc_tea_cigv / 100), (ln_val_meses_periodo / 12)) - 1;
      ln_tasa_nom_anual_cigv := ln_val_porc_tea_m_cigv * ln_val_periodo_finan;
      ln_tasa_nom_anual_sigv := ln_tasa_nom_anual_cigv / ln_igv;
      ln_tasa_nom_m_sigv     := ln_tasa_nom_anual_sigv / ln_val_periodo_finan;     
    elsif  ln_val_porc_tea_sigv is null or ln_val_porc_tea_sigv = 0 then 
      ln_val_porc_tea_cigv   := 0;
      ln_val_porc_tea_m_cigv := 0;
      ln_tasa_nom_anual_cigv := 0;
      ln_tasa_nom_anual_sigv := 0;
      ln_tasa_nom_m_sigv     := 0;
    end if;
    ln_mon_calc            := fn_pago(ln_tasa_nom_m_sigv * ln_igv, ln_can_tot_let, -ln_mon_a_fin);
    ln_val_int             := ln_mon_a_fin * ln_val_porc_tea_m_cigv * (ln_nro_cuotas - p_nro_cuotas);
    ln_val_cuo_bal         := ln_mon_a_fin * (p_porc_cb / 100); 
    ln_val_capi_cuo_bal    := ln_val_cuo_bal / (1 + ln_tasa_nom_m_sigv * ln_igv);  
--**********************
    if ln_val_porc_tea_m_cigv > 0 and p_nro_cuotas >0 then 
       ln_val_cuo_bal_men     := fn_pago(ln_val_porc_tea_m_cigv,CASE WHEN p_nro_cuotas = 1 THEN p_nro_cuotas 
                                                                ELSE p_nro_cuotas - 1 END,-ln_mon_a_fin,ln_val_capi_cuo_bal);
    end if;
--**********************
    ln_val_gasto_admi      := ln_mon_a_fin * (ln_val_porc_gast_admi / 100) * ln_igv;
    ln_val_prima_segu_per  := nvl(p_prima_seg,0) / ln_nro_cuotas;
    
    IF ln_val_prima_segu_per > 0 THEN 
      update vve_cred_soli 
      set val_prim_seg = round(ln_val_prima_segu_per,2)*ln_nro_cuotas
      WHERE cod_soli_cred = ln_cod_soli_cred;
      
      update vve_cred_simu 
      set val_prima_seg  = round(ln_val_prima_segu_per,2)*ln_nro_cuotas 
      where cod_simu = p_cod_simu
      AND ind_inactivo = 'N';
      
      update vve_cred_simu_gast 
      set val_mon_total = round(ln_val_prima_segu_per,2)*ln_nro_cuotas,
          val_mon_per   = ln_val_prima_segu_per
      where cod_simu = p_cod_simu;      
    end if;
    
    if   ln_can_let_per_gra > 0 then 
      update vve_cred_soli 
      set    val_int_per_gra = round(p_val_mon_int_pgra/ln_can_let_per_gra,2)*ln_can_let_per_gra
      WHERE cod_soli_cred = ln_cod_soli_cred;
      
      update vve_cred_simu 
      set    val_int_per_gra = round(p_val_mon_int_pgra/ln_can_let_per_gra,2)*ln_can_let_per_gra 
      where cod_simu = p_cod_simu
      AND ind_inactivo = 'N';
     end if;
    /*pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GENE_CRONO',
                                        p_cod_usua_sid,
                                        'Prueba GC',
                                        ln_mon_a_fin || '|' ||                                     
                                        ln_can_tot_let || '|' ||
                                        ln_mon_calc || '|' ||
                                        NULL); */

    --Inicializa arreglo de valores del TIR
    lt_tir_value_list := VVE_TYTA_TIR_LIST();
    lt_tir_value_list.extend(ln_nro_cuotas + 1);
    --lt_tir_value_list(1) := ln_val_gasto_admi - ln_mon_a_fin; 
    lt_tir_value_list(1) := - ln_mon_a_fin;        

    FOR cuota IN 1..ln_nro_cuotas LOOP
        --Calcular el saldo inicial de la cuota
        IF ln_sal_ini_cuo = 0 THEN
            ln_sal_ini_cuo := ln_mon_a_fin; --Inicializa con el monto a financiar  
        ELSE
            ln_sal_ini_cuo := ln_sal_fin_cuo;
        END IF;
        
        --Calcular el interes de la cuota
        IF ln_can_let_per_gra >= cuota THEN
            ln_val_int_cuo := (ln_val_int / ln_can_let_per_gra) / ln_igv;        
        ELSE
            ln_val_int_cuo := ln_sal_ini_cuo * ln_tasa_nom_m_sigv;            
        END IF;
        
        --Calcular el IGV de la cuota
        ln_val_igv_cuo := ln_val_int_cuo * 0.18;
        
        --Calcular el monto de la cuota
        IF ln_can_let_per_gra >= cuota THEN
              ln_mon_calc_cuo := round(ln_val_int_cuo,2) + round(ln_val_igv_cuo,2) + round(ln_val_prima_segu_per,2);
        ELSE
            IF p_porc_cb > 0 AND cuota < ln_nro_cuotas THEN
                 ln_mon_calc_cuo := round(ln_val_cuo_bal_men,2) + round(ln_val_prima_segu_per,2);
            ELSIF p_porc_cb > 0 AND cuota = ln_nro_cuotas THEN
                 ln_mon_calc_cuo := round(ln_val_cuo_bal,2) + round(ln_val_prima_segu_per,2); 
            ELSE 
               ln_mon_calc_cuo := ln_mon_calc + ln_val_prima_segu_per;
            END IF;
        END IF;
        
        --Se inserta el valor del monto de cada cuota en el arreglo que se utilizara para obtener el TIR
        lt_tir_value_list(CASE WHEN cuota = 1 THEN cuota ELSE cuota + 1 END) := ln_mon_calc_cuo;
    
        --Calcular la amortización de capital de la cuota
        IF ln_can_let_per_gra >= cuota THEN
            ln_amo_cap_cuo := 0;
        ELSE

            ln_amo_cap_cuo := ln_mon_calc - ln_val_igv_cuo - ln_val_int_cuo;
            ln_dif_cuota   := 0;          
            --<I Req. 87567 E2.1 ID 80 AVILCA 25/08/2020>
            ln_dif_cuota   :=  ln_mon_calc_cuo - (round(ln_amo_cap_cuo,2)+round(ln_val_int_cuo,2)+round(ln_val_igv_cuo,2)+round(ln_val_prima_segu_per,2));            
            ln_amo_cap_cuo := ln_amo_cap_cuo+ ln_dif_cuota;
            --<F Req. 87567 E2.1 ID 80 AVILCA 25/08/2020>
            
            if cuota = ln_nro_cuotas then 
              ln_amo_cap_cuo := ln_sal_ini_cuo;              
               --<I Req. 87567 E2.1 ID 80 AVILCA 25/08/2020>
              ln_dif_cuota   := ln_mon_calc_cuo - (round(ln_amo_cap_cuo,2)+round(ln_val_int_cuo,2)+round(ln_val_igv_cuo,2)+round(ln_val_prima_segu_per,2));
              --<F Req. 87567 E2.1 ID 80 AVILCA 25/08/2020>
              ln_val_int_cuo := ln_val_int_cuo + ln_dif_cuota;
            end if;            
        END IF;    
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_GENE_CRONO',
                                            p_cod_usua_sid,
                                            'Prueba Cuota',
                                            (cuota+1) || '|' ||
                                            ln_mon_calc_cuo || '|' ||
                                            ln_val_igv_cuo || '|' ||
                                            ln_val_int_cuo || '|' ||
                                            ln_val_prima_segu_per || '|' ||
                                            (ln_mon_calc_cuo - ln_val_igv_cuo - ln_val_int_cuo - ln_val_prima_segu_per) || '|' ||
                                            NULL);          
        
        --Calcular el monto de la letra incluido el monto del seguro por cuota
        ln_mon_calc_letr := ln_mon_calc_cuo;
            
       --<I Req. 87567 E2.1 ID 77 AVILCA 20/07/2020>
        IF cuota = 1 THEN
        
            ln_fec_vcto := CASE WHEN lv_ind_pgra_sint = 'S' THEN                         
                        ADD_MONTHS(ln_fec_vcto, 2 * ln_val_meses_periodo)  --<I Req. 87567 E2.1 ID 69 AVILCA 24/07/2020>
                       ELSE
                         ADD_MONTHS(ln_fec_vcto, ln_val_meses_periodo)
                       END;        
        ELSE
            ln_fec_vcto := ADD_MONTHS(ln_fec_vcto, ln_val_meses_periodo);
        END IF;
       --<F Req. 87567 E2.1 ID 77 AVILCA 20/07/2020>
        
        
        --Calcular el saldo final de la cuota
        ln_sal_fin_cuo := ln_sal_ini_cuo - ln_amo_cap_cuo;
          
        INSERT INTO vve_cred_simu_letr 
        (
            cod_nume_letr,
            cod_simu,
            val_mont_letr,
            cod_moneda,
            fec_venc,
            fec_giro,
            val_mont_cuo,
            cod_usua_crea_reg,
            fec_crea_reg
        ) 
        VALUES 
        (
            cuota,
            p_cod_simu,
            ln_mon_calc_letr,
            DECODE(ln_cod_moneda_prof, 'SOL', 1, 2),
            ln_fec_vcto,
            SYSDATE,
            ln_mon_calc_cuo,
            p_cod_usua_sid,
            SYSDATE
        );
        
        FOR concepto IN c_cursor
        LOOP
            INSERT INTO vve_cred_simu_lede 
            (
                cod_det_simu,
                cod_nume_letr,
                cod_simu,
                cod_conc_col,
                val_mon_conc,
                fec_venc,
                val_mont_letr,
                cod_usua_crea_reg,
                fec_crea_reg
            ) 
            VALUES 
            (
                seq_vve_cred_simu_lede.nextval,
                cuota,
                p_cod_simu,
                concepto.cod_conc_col,
                CASE concepto.cod_conc_col
                    WHEN 1 THEN (cuota+1)           --Item
                    WHEN 2 THEN ln_sal_ini_cuo  --Saldo Inicial
                    WHEN 3 THEN ln_amo_cap_cuo  --Capital
                    WHEN 4 THEN ln_val_int_cuo  --Interes
                    WHEN 5 THEN ln_mon_calc_cuo --Cuota
                    WHEN 6 THEN ln_sal_fin_cuo  --Saldo Final
                    WHEN 13 THEN ln_val_igv_cuo --IGV
                    ELSE CASE concepto.ind_fin
                            WHEN 'N' THEN concepto.val_mon_per
                            ELSE concepto.val_mon_total
                         END   
                END,
                ln_fec_vcto,
                ln_mon_calc_letr,
                p_cod_usua_sid,
                SYSDATE
            );
        END LOOP;
    END LOOP;
    
    ln_val_tir := pkg_sweb_cred_soli_simulador.fn_tir(lt_tir_value_list);     
    ln_val_tcea := TO_CHAR((POWER((1 + (ln_val_tir / 100)), ln_val_meses_periodo) - 1) * 100, '999999999999D99');
    

    
    --Actualizar TIR y TCEA en la tabla de parametros del simulador
    UPDATE vve_cred_simu
    SET val_tir = ln_val_tir,
        val_tcea = ln_val_tcea
    WHERE cod_simu = p_cod_simu
        AND ind_inactivo = 'N';
        
    -- Obteniendo fechas máxima y mínima del simulador          
      SELECT TO_CHAR(MIN(fec_venc),'dd/mm/yyyy'), TO_CHAR(MAX(fec_venc),'dd/mm/yyyy')
       INTO lv_fec_min_simu,lv_fec_max_simu
       FROM vve_cred_simu_lede
       WHERE cod_simu =  p_cod_simu
       ORDER BY  fec_venc desc;        

    --Actualizar TIR,TCEA y otros parametros  en la tabla de la solicitud de crédito        
    IF lv_exists_solcre = 'S' THEN
        UPDATE vve_cred_soli
        SET val_tir = ln_val_tir,
            val_tcea = ln_val_tcea,
            --//I Req. 87567 E2.1  avilca 25/09/2020
            fec_inic_vige_poli = to_date(lv_fec_min_simu,'dd/mm/yyyy'),
            fec_fin_vige_poli = to_date(lv_fec_max_simu,'dd/mm/yyyy'),
            ind_soli_apro_tseg = 'S',
            cod_usua_gest_seg = p_cod_usua_sid
            --//F Req. 87567 E2.1  avilca 25/09/2020
        WHERE cod_soli_cred = ln_cod_soli_cred;
    END IF;        

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'La generación del cronograma se ha realizado con éxito';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GENE_CRONO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GENE_CRONO',
                                          p_cod_usua_sid,
                                          'Error en al generar cronograma',
                                          p_ret_mens,
                                          NULL);
    ROLLBACK;                                          
  END sp_gene_crono;
  
  PROCEDURE sp_cuad_crono
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_arr_crono_modi   IN VVE_TYTA_CRONO,
    p_cod_tipo_ope     IN VARCHAR2,     
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor_row   OUT SYS_REFCURSOR,
    p_ret_cursor_col   OUT SYS_REFCURSOR,
    p_ret_cursor_total OUT SYS_REFCURSOR,
    p_ret_cursor_proc  OUT SYS_REFCURSOR,    
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS    
    ve_error                EXCEPTION;
    kn_grupo_per_cred_sol   vve_tabla_maes.cod_grupo%TYPE := 88;
    ln_cod_moneda_prof      vve_cred_simu.cod_moneda%TYPE;
    ln_cod_simu             vve_cred_simu.cod_simu%TYPE;
    ln_val_mon_fin          vve_cred_soli.val_mon_fin%TYPE;
    ln_val_prima_seg        vve_cred_soli.val_prim_seg%TYPE;
    ln_val_prima_segu_per   vve_cred_soli.val_prim_seg%TYPE;
    ln_can_let_per_gra      vve_cred_simu.can_let_per_gra%TYPE;
    ln_can_tot_let          vve_cred_simu.can_tot_let%TYPE;
    ln_val_porc_tea_sigv    vve_cred_simu.val_porc_tea_sigv%TYPE;
    lv_cod_per_cred_sol     vve_cred_simu.cod_per_cred_sol%TYPE;
    ln_val_porc_gast_admi 	vve_cred_simu.val_porc_gast_adm%TYPE;
    ln_val_gasto_admi       vve_cred_simu.val_gast_adm%TYPE;
    ln_val_meses_periodo    NUMBER;
    ln_mon_a_fin            NUMBER := 0;
    ln_mon_calc_cuo         NUMBER := 0; 
    ln_sal_ini_cuo          NUMBER := 0;
    ln_amo_cap_cuo          NUMBER := 0;
    ln_val_int_cuo          NUMBER;
    ln_val_igv_cuo          NUMBER;
    ln_sal_fin_cuo          NUMBER;
    ln_igv                  NUMBER := 1.18;
    ln_val_int              NUMBER;
    ln_nro_cuotas           NUMBER;
    ln_val_porc_tea_m_sigv  NUMBER;
    ln_val_porc_tea_cigv    NUMBER;
    ln_val_porc_tea_m_cigv  NUMBER;
    ln_tasa_nom_anual_cigv  NUMBER;
    ln_tasa_nom_anual_sigv  NUMBER;
    ln_tasa_nom_m_sigv      NUMBER;    
    lt_arr_crono_modi       VVE_TYTA_CRONO;
    lt_tir_value_list       VVE_TYTA_TIR_LIST;
    lt_arr_crono_total_modi VVE_TYTA_CRONO_TOTAL;
    ln_val_tir              NUMBER;
    ln_val_tcea             NUMBER;
    ln_val_tir_gen          NUMBER;
    ln_val_tcea_gen         NUMBER;
    ln_tot_mon_fin          NUMBER := 0;
    ln_tot_amortizacion     NUMBER := 0;
    ln_tot_seg_fin          NUMBER := 0;
    ln_tot_interes          NUMBER := 0;
    ln_tot_cuotas           NUMBER := 0;
    lv_sql_concepto         VARCHAR2(1000);
    lc_cursor               SYS_REFCURSOR;
    ln_tot_int_per_gra      NUMBER := 0;
    ln_val_int_per_gra      vve_cred_simu.val_int_per_gra%TYPE;
    ln_tot_val_mon_fin      NUMBER := 0;
    ln_tot_val_prima_seg    NUMBER := 0;
    lv_num_cuotas           VARCHAR2(1000):='';
    ln_cont_cuotas          NUMBER := 0;
    ln_sal_fin_ult_cuota    NUMBER := 0;
    ln_dif_cuota            NUMBER;
    ln_val_int_sum          NUMBER := 0;
    
    TYPE lt_maes_conc_letr  IS RECORD 
    (
        cod_conc_col         vve_cred_maes_conc_letr.cod_conc_col%TYPE,
        des_conc             vve_cred_maes_conc_letr.des_conc%TYPE,
        num_orden            vve_cred_maes_conc_letr.num_orden%TYPE
    );
    lr_maes_conc_letr       lt_maes_conc_letr;
    ln_tmp_sal_fin_cuo      NUMBER := 0;
  BEGIN
    lt_arr_crono_modi := p_arr_crono_modi;
          
    --Obtener valores de la tabla de parametros del simulador
    SELECT cod_simu,
             val_mon_fin,
             val_prima_seg,
             can_let_per_gra,
             can_tot_let,
             val_porc_tea_sigv,
             cod_per_cred_sol,
             val_porc_gast_adm,
             val_tir,
             val_tcea,
             cod_moneda,
             val_int_per_gra
    INTO ln_cod_simu,
         ln_val_mon_fin,
         ln_val_prima_seg,
         ln_can_let_per_gra,
         ln_can_tot_let,
         ln_val_porc_tea_sigv,
         lv_cod_per_cred_sol,
         ln_val_porc_gast_admi,
         ln_val_tir,
         ln_val_tcea,
         ln_cod_moneda_prof,
         ln_val_int_per_gra
    FROM vve_cred_simu
    WHERE (cod_soli_cred = p_cod_soli_cred 
        OR num_prof_veh = p_num_prof_veh
        OR cod_simu = p_cod_simu)
        AND ind_inactivo = 'N';
                      
    lv_sql_concepto := 'SELECT cod_conc_col,
                               des_conc,
                               num_orden
                        FROM vve_cred_maes_conc_letr
                        WHERE ind_conc_oblig = ''S''
                        UNION ALL
                        SELECT mcl.cod_conc_col, 
                               mcl.des_conc,
                               mcl.num_orden
                        FROM vve_cred_simu_gast csg
                        INNER JOIN vve_cred_maes_conc_letr mcl
                            ON mcl.cod_conc_col = csg.cod_conc_col
                        WHERE cod_simu = ' || ln_cod_simu || '
                        ORDER BY num_orden';          
        
    --Obtener los valores de la periodicidad seleccionada
    SELECT 12 / valor_adic_1
    INTO  ln_val_meses_periodo
    FROM  vve_tabla_maes
    WHERE cod_tipo = lv_cod_per_cred_sol
    AND   cod_grupo = kn_grupo_per_cred_sol;        
        
    --Se calculan los valores necesarios para la generación de las cuotas
    ln_mon_a_fin           := ln_val_mon_fin;
    ln_nro_cuotas          := ln_can_tot_let + ln_can_let_per_gra;
    ln_val_porc_tea_cigv   := ln_val_porc_tea_sigv * ln_igv;
    ln_val_porc_tea_m_cigv := POWER((1 + ln_val_porc_tea_cigv / 100), (ln_val_meses_periodo / 12)) - 1;
    ln_tasa_nom_anual_cigv := ln_val_porc_tea_m_cigv * ln_nro_cuotas;
    ln_tasa_nom_anual_sigv := ln_tasa_nom_anual_cigv / ln_igv;
    ln_tasa_nom_m_sigv     := ln_tasa_nom_anual_sigv / ln_nro_cuotas;
    ln_val_int             := ln_mon_a_fin * ln_val_porc_tea_m_cigv * (ln_nro_cuotas - ln_can_tot_let);
    ln_val_gasto_admi      := ln_mon_a_fin * (ln_val_porc_gast_admi / 100) * ln_igv;
    ln_val_prima_segu_per  := ln_val_prima_seg / ln_nro_cuotas;
    
    --Inicializa arreglo de valores del TIR
    lt_tir_value_list := VVE_TYTA_TIR_LIST();
    lt_tir_value_list.extend(ln_nro_cuotas + 1);
    lt_tir_value_list(1) := ln_val_gasto_admi - ln_mon_a_fin;   
    
    IF ln_val_prima_segu_per > 0 THEN 
      ln_val_prima_seg := round(ln_val_prima_segu_per,2)*ln_nro_cuotas;  
    
      UPDATE vve_cred_soli 
      SET val_prim_seg = ln_val_prima_seg 
      WHERE cod_soli_cred = p_cod_soli_cred;
      
      UPDATE vve_cred_simu 
      SET val_prima_seg  = ln_val_prima_seg  
      WHERE cod_simu = p_cod_simu
      AND ind_inactivo = 'N';
      
      UPDATE vve_cred_simu_gast 
      SET val_mon_total = ln_val_prima_seg, 
          val_mon_per   = ln_val_prima_segu_per
      WHERE cod_simu = p_cod_simu;      
    END IF;          

    IF   ln_can_let_per_gra > 0 THEN 
      ln_val_int := round((ln_val_int/ln_can_let_per_gra),2)*ln_can_let_per_gra;
      ln_val_int_per_gra := ln_val_int;
      UPDATE vve_cred_soli 
      SET    val_int_per_gra = ln_val_int 
      WHERE cod_soli_cred = p_cod_soli_cred;
                
       UPDATE vve_cred_simu 
       SET    val_int_per_gra = ln_val_int  
       WHERE  cod_simu     = p_cod_simu
       AND    ind_inactivo = 'N';
     END IF;
    
    FOR i IN 1 .. lt_arr_crono_modi.COUNT
    LOOP
        IF p_cod_tipo_ope = 'CC' THEN
            --Calcular el saldo inicial de la cuota
            IF ln_sal_ini_cuo = 0 THEN
                ln_sal_ini_cuo := lt_arr_crono_modi(i).saldoinicial; --Inicializa con el monto a financiar  
            ELSE
                ln_sal_ini_cuo := ln_sal_fin_cuo;
            END IF;        
            
            --Calcular el interes e IGV de la cuota 
            IF ln_can_let_per_gra >= lt_arr_crono_modi(i).cod_nume_letr THEN
              ln_val_int_cuo := round((ln_val_int / ln_can_let_per_gra),2) / ln_igv;
              ln_val_igv_cuo := round(((ln_val_int / ln_can_let_per_gra)/ ln_igv) * 0.18,2);
            ELSE
              ln_val_int_cuo := ln_sal_ini_cuo * ln_tasa_nom_m_sigv;
              ln_val_igv_cuo := ln_val_int_cuo * 0.18;
            END IF;        
                                
            --Calcular la amortización de capital de la cuota
            IF ln_can_let_per_gra >= lt_arr_crono_modi(i).cod_nume_letr THEN
                ln_amo_cap_cuo := 0;
            ELSE
              ln_amo_cap_cuo := lt_arr_crono_modi(i).cuota - (ln_val_igv_cuo + ln_val_int_cuo + round(ln_val_prima_segu_per,2));
              ln_dif_cuota   := 0;
              ln_dif_cuota   := round(lt_arr_crono_modi(i).cuota - (round(ln_amo_cap_cuo,2)+round(ln_val_int_cuo,2)+round(ln_val_igv_cuo,2)+round(ln_val_prima_segu_per,2)),2);
              ln_amo_cap_cuo := round(ln_amo_cap_cuo + ln_dif_cuota,2);
              if lt_arr_crono_modi(i).cod_nume_letr = ln_nro_cuotas then 
                ln_amo_cap_cuo := ln_sal_ini_cuo;
                ln_dif_cuota   := round(lt_arr_crono_modi(i).cuota,2) - (round(ln_amo_cap_cuo,2)+round(ln_val_int_cuo,2)+round(ln_val_igv_cuo,2)+round(ln_val_prima_segu_per,2));
                ln_val_int_cuo := ln_val_int_cuo + ln_dif_cuota;
              end if;                

            END IF;        

            --Calcular el monto de la cuota
            IF ln_can_let_per_gra >= lt_arr_crono_modi(i).cod_nume_letr THEN
              ln_mon_calc_cuo := round(ln_val_int_cuo,2) + round(ln_val_igv_cuo,2) + round(ln_val_prima_segu_per,2);
            ELSE
              ln_mon_calc_cuo := ln_amo_cap_cuo + round(ln_val_int_cuo,2) + round(ln_val_igv_cuo,2) + round(ln_val_prima_segu_per,2);
            END IF;
            
            ln_sal_fin_cuo := ln_sal_ini_cuo - ln_amo_cap_cuo;        
            lt_arr_crono_modi(i).saldoinicial := ln_sal_ini_cuo;
            lt_arr_crono_modi(i).capital      := ln_amo_cap_cuo;
            lt_arr_crono_modi(i).interes      := round(ln_val_int_cuo,2);
            lt_arr_crono_modi(i).igv          := round(ln_val_igv_cuo,2);
            lt_arr_crono_modi(i).seguro       := round(ln_val_prima_segu_per,2);
            lt_arr_crono_modi(i).cuota        := ln_mon_calc_cuo;
            lt_arr_crono_modi(i).saldofinal   := ln_sal_fin_cuo;   
            
            -- Sumando interes + igv para letras con periodo de gracia
            IF lt_arr_crono_modi(i).capital = 0 THEN
               ln_tot_int_per_gra := ln_tot_int_per_gra + lt_arr_crono_modi(i).interes + lt_arr_crono_modi(i).igv;
            END IF;
            -- Sumando capital de las letras concepto 3
               ln_tot_val_mon_fin := ln_tot_val_mon_fin + lt_arr_crono_modi(i).capital;
            -- Sumando seguro de las letras concepto  8
               ln_tot_val_prima_seg := ln_tot_val_prima_seg + lt_arr_crono_modi(i).seguro;
            -- Capturando cuotas que son menores que el seguro
            IF lt_arr_crono_modi(i).cuota < lt_arr_crono_modi(i).seguro THEN
               IF ln_cont_cuotas = 0 THEN
               lv_num_cuotas := lv_num_cuotas || i;
               ELSE
                lv_num_cuotas := ','|| i;
               END IF;
               ln_cont_cuotas := ln_cont_cuotas + 1;
            END IF;
            -- Obteniendo saldo final de la última cuota
            /*   IF i = lt_arr_crono_modi.COUNT THEN
               ln_sal_fin_ult_cuota := lt_arr_crono_modi(i).saldofinal;
               END IF;
            */
            

        ELSIF p_cod_tipo_ope = 'GC' THEN
            UPDATE vve_cred_simu_letr
            SET    val_mont_letr = lt_arr_crono_modi(i).cuota,
                   val_mont_cuo  = lt_arr_crono_modi(i).cuota,
                   cod_usua_modi_reg = p_cod_usua_sid,
                   fec_modi_reg  = SYSDATE
            WHERE  cod_nume_letr = lt_arr_crono_modi(i).cod_nume_letr 
            AND    cod_simu      = ln_cod_simu;             
            
            OPEN lc_cursor FOR lv_sql_concepto;
            LOOP
                FETCH lc_cursor INTO lr_maes_conc_letr;
                EXIT WHEN lc_cursor%NOTFOUND;                
                    UPDATE vve_cred_simu_lede
                        SET val_mon_conc = CASE lr_maes_conc_letr.cod_conc_col
                            WHEN 1 THEN lt_arr_crono_modi(i).item          --Item
                            WHEN 2 THEN lt_arr_crono_modi(i).saldoinicial  --Saldo Inicial
                            WHEN 3 THEN lt_arr_crono_modi(i).capital       --Capital
                            WHEN 4 THEN lt_arr_crono_modi(i).interes       --Interes
                            WHEN 5 THEN lt_arr_crono_modi(i).cuota         --Cuota
                            WHEN 6 THEN lt_arr_crono_modi(i).saldofinal    --Saldo Final                            
                            WHEN 8 THEN lt_arr_crono_modi(i).seguro        --Seguro                            
                            WHEN 13 THEN lt_arr_crono_modi(i).igv          --IGV  
                        END,
                        val_mont_letr = lt_arr_crono_modi(i).cuota,
                        cod_usua_modi_reg = p_cod_usua_sid,
                        fec_modi_reg = SYSDATE                    
                    WHERE cod_nume_letr = lt_arr_crono_modi(i).cod_nume_letr 
                        AND cod_simu = ln_cod_simu
                        AND cod_conc_col = lr_maes_conc_letr.cod_conc_col;                               
            END LOOP;
            CLOSE lc_cursor;         
        END IF;

        
        ln_tot_mon_fin      := ln_val_mon_fin;
        ln_tot_amortizacion := ln_tot_amortizacion + lt_arr_crono_modi(i).capital;
        ln_tot_seg_fin      := ln_val_prima_seg;
        ln_tot_interes      := ln_tot_interes + lt_arr_crono_modi(i).interes + lt_arr_crono_modi(i).igv;--<I Req. 87567 E2.1 ID## avilca 02/02/2021>
        ln_tot_cuotas       := ln_tot_cuotas + lt_arr_crono_modi(i).cuota;         
    END LOOP;    
  
    OPEN p_ret_cursor_row FOR
        SELECT * FROM TABLE(CAST(lt_arr_crono_modi AS VVE_TYTA_CRONO));    
    
    --Inicializa arreglo de valores de totales
    lt_arr_crono_total_modi := VVE_TYTA_CRONO_TOTAL();
    lt_arr_crono_total_modi.extend(1);
    lt_arr_crono_total_modi(1) := VVE_TYPE_CRONO_TOTAL_ITEM
                                  (
                                    ln_tot_mon_fin,
                                    ln_tot_amortizacion,
                                    ln_tot_seg_fin,
                                    ln_tot_interes,
                                    ln_tot_cuotas
                                  );

    OPEN p_ret_cursor_total FOR
        SELECT * FROM TABLE(CAST(lt_arr_crono_total_modi AS VVE_TYTA_CRONO_TOTAL));

    OPEN p_ret_cursor_col FOR lv_sql_concepto;   
                 
    OPEN p_ret_cursor_proc FOR
        SELECT 'IND_TASA_SEG_DIF' nombre,
               CASE WHEN cs.val_tasa_seg < cs.val_tasa_ori_seg
                THEN 'S'
                ELSE 'N'
               END restrictivo
        FROM vve_cred_simu cs               
        WHERE cs.cod_simu = ln_cod_simu;        

    ln_val_tir_gen := pkg_sweb_cred_soli_simulador.fn_tir(lt_tir_value_list);    
    ln_val_tcea_gen := TO_CHAR((POWER((1 + (ln_val_tir_gen / 100)), ln_val_meses_periodo) - 1) * 100, '999999999999D99');
    
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_CUAD_CRONO',
                                        p_cod_usua_sid,
                                        'Prueba TIR',
                                        ln_val_tir_gen || '|' || ln_val_tir || '|' ||
                                        ln_val_tcea_gen || '|' || ln_val_tcea,
                                        NULL);    
    
	IF p_cod_tipo_ope = 'CC' THEN
		 --Validaciones Cronograma a medida  
		BEGIN
			-- Validación de letras con periodo de gracia      
			 IF ln_val_int_per_gra <> ln_tot_int_per_gra THEN
			   p_ret_mens := 'La suma de las letras con periodo de gracia (interes + igv) no coincide con lo registrado en el simulador'; 
			   RAISE ve_error;
			 END IF; 
				   
			 IF ln_tot_val_mon_fin <> ln_val_mon_fin THEN
				p_ret_mens := 'La suma de la columna de amortizaciones no coincide con el monto financiado'; 
				RAISE ve_error;
			 END IF;
			 
			 IF ln_tot_val_prima_seg <> ln_val_prima_seg THEN
				p_ret_mens := 'La suma de la columna de seguros no coincide con la prima total de seguro'; 
				RAISE ve_error;
			 END IF;     
			 
			 IF ln_cont_cuotas > 0 THEN
				p_ret_mens := 'Las cuotas '||lv_num_cuotas||' no pueden ser menores que el seguro'; 
				RAISE ve_error;
			 END IF; 
			 
			 IF ln_sal_fin_ult_cuota > 0 THEN
				p_ret_mens := 'El saldo final de la última letra debe ser cero'; 
				RAISE ve_error;
			 END IF; 
		END; 
	END IF;
     
    p_ret_esta := 1;
    p_ret_mens := 'La generación del cronograma se ha realizado con éxito';       
    
  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_CUAD_CRONO',
                                            p_cod_usua_sid,
                                            'Error al cuadrar la simulación de cuotas',
                                            p_ret_mens,
                                            p_cod_soli_cred);  
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_CUAD_CRONO:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_CUAD_CRONO',
                                            p_cod_usua_sid,
                                            'Error al cuadrar la simulación de cuotas',
                                            p_ret_mens,
                                            p_cod_soli_cred);        
  END sp_cuad_crono;  
  
  PROCEDURE sp_inse_para_simulador
  (
    p_cod_soli_cred          IN vve_cred_simu.cod_soli_cred%type,    
    p_num_prof_veh           IN vve_cred_simu.num_prof_veh%type,    
    p_val_porc_ci            IN vve_cred_simu.val_porc_ci%type,    
    p_val_ci                 IN vve_cred_simu.val_ci%type,    
    p_val_mon_fin            IN vve_cred_simu.val_mon_fin%type,    
    p_val_pag_cont_ci        IN vve_cred_simu.val_pag_cont_ci%type,    
    p_can_dias_venc_1ra_letr IN vve_cred_simu.can_dias_venc_1ra_letr%type,   
    p_cod_per_cred_sol       IN vve_cred_simu.cod_per_cred_sol%type,    
    p_can_tot_let            IN vve_cred_simu.can_tot_let%type,    
    p_can_plaz_meses         IN vve_cred_simu.can_plaz_meses%type,    
    p_ind_tip_per_gra        IN vve_cred_simu.ind_tip_per_gra%type,    
    p_val_dias_per_gra       IN vve_cred_simu.val_dias_per_gra%type,    
    p_can_let_per_gra        IN vve_cred_simu.can_let_per_gra%type,    
    p_val_porc_tea_sigv      IN vve_cred_simu.val_porc_tea_sigv%type,    
    p_val_porc_tep_sigv      IN vve_cred_simu.val_porc_tep_sigv%type,    
    p_ind_gps                IN vve_cred_simu.ind_gps%type,    
    p_val_porc_cuo_bal       IN vve_cred_simu.val_porc_cuo_bal%type,    
    p_val_cuo_bal            IN vve_cred_simu.val_cuo_bal%type,    
    p_ind_tip_seg            IN vve_cred_simu.ind_tip_seg%type,    
    p_cod_cia_seg            IN vve_cred_simu.cod_cia_seg%type,    
    p_cod_tip_uso_veh        IN vve_cred_simu.cod_tip_uso_veh%type,    
    p_val_tasa_seg           IN vve_cred_simu.val_tasa_seg%type,
    p_val_tasa_ori_seg       IN vve_cred_simu.val_tasa_ori_seg%type,
    p_val_prima_seg          IN vve_cred_simu.val_prima_seg%type,    
    p_cod_tip_unidad         IN vve_cred_simu.cod_tip_unidad%type,        
    p_val_porc_gast_adm      IN vve_cred_simu.val_porc_gast_adm%type,     
    p_val_gast_adm           IN vve_cred_simu.val_gast_adm%type,        
    p_val_int_per_gra        IN vve_cred_simu.val_int_per_gra%type,
    p_cod_moneda             IN vve_cred_simu.cod_moneda%type,
    p_tip_soli_cred          IN vve_cred_soli.tip_soli_cred%TYPE, 
    p_txt_otr_cond           IN vve_cred_simu.txt_otr_cond%TYPE,
    p_val_tc                 IN vve_cred_simu.val_tc%TYPE,
    p_val_ind_sin_int        IN vve_cred_simu.ind_pgra_sint%TYPE,--Req. 87567 E2.1 ID## AVILCA
    p_cod_usua_sid           IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web           IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod_simu           OUT vve_cred_simu.cod_simu%TYPE,
    p_ret_esta               OUT NUMBER,
    p_ret_mens               OUT VARCHAR2
  ) AS  
    ve_error EXCEPTION;
    kn_grupo_per_cred_sol       vve_tabla_maes.cod_grupo%TYPE := 88;     -- Grupo para Periodicidad de Cuotas.
    ln_val_meses_periodo        NUMBER;
    ln_val_dias_periodo         NUMBER;
    ln_can_dias_venc_1ra_letr   NUMBER;
    
  BEGIN
    --Generar nuevo código del simulador
    p_ret_cod_simu := seq_vve_cred_simu.nextval;
  
    --Obtener los valores de la periodicidad seleccionada
    SELECT 12 / valor_adic_1, 
           valor_adic_2
    INTO ln_val_meses_periodo, 
         ln_val_dias_periodo
    FROM vve_tabla_maes
    WHERE cod_tipo = p_cod_per_cred_sol
    AND cod_grupo = kn_grupo_per_cred_sol;
  
    --Calcular los dias de la vencimiento de la primera cuota
    IF p_can_dias_venc_1ra_letr = ln_val_dias_periodo THEN
        ln_can_dias_venc_1ra_letr := p_can_dias_venc_1ra_letr;
    ELSE
        ln_can_dias_venc_1ra_letr := p_can_dias_venc_1ra_letr - ln_val_dias_periodo;
    END IF;    
    
    --Establecer los simuladores anteriores como inactivos
    UPDATE vve_cred_simu
    SET ind_inactivo = 'S'
    WHERE cod_soli_cred = p_cod_soli_cred;
  
    INSERT INTO vve_cred_simu 
    (
        cod_simu,
        cod_soli_cred,
        num_prof_veh,
        ind_aprobado,
        ind_inactivo,
        val_porc_ci,
        val_ci,
        val_mon_fin,
        val_pag_cont_ci,
        fec_venc_1ra_let,
        cod_per_cred_sol,
        can_tot_let,
        can_plaz_meses,
        ind_tip_per_gra,
        val_dias_per_gra,
        can_let_per_gra,
        val_porc_tea_sigv,
        val_porc_tep_sigv,
        ind_gps,
        val_porc_cuo_bal,
        val_cuo_bal,
        ind_tip_seg,
        cod_cia_seg,
        cod_tip_uso_veh,
        val_tasa_seg,
        val_tasa_ori_seg,
        val_prima_seg,
        cod_tip_unidad,
        val_porc_gast_adm,
        val_gast_adm,
        val_int_per_gra,
        cod_usua_crea_reg,
        fec_crea_reg,
        cod_moneda,
        can_dias_venc_1ra_letr,
        tip_soli_cred,
        txt_otr_cond,
        val_tc,
        ind_pgra_sint --Req. 87567 E2.1 ID## AVILCA
    ) 
    VALUES 
    (
        p_ret_cod_simu,
        p_cod_soli_cred,
        p_num_prof_veh,
        'N',
        'N',
        p_val_porc_ci,
        p_val_ci,
        p_val_mon_fin,
        p_val_pag_cont_ci,
        CASE
             WHEN p_val_ind_sin_int = 'S' THEN
                ADD_MONTHS(SYSDATE, 2 * ln_val_meses_periodo)--<I Req. 87567 E2.1 ID 69 AVILCA 25/08/2020>
             ELSE
               ADD_MONTHS(SYSDATE, ln_val_meses_periodo)
        END ,
        p_cod_per_cred_sol,
        p_can_tot_let,
        p_can_plaz_meses,
        p_ind_tip_per_gra,
        p_val_dias_per_gra,
       (CASE p_val_ind_sin_int WHEN 'S' THEN 0 ELSE p_can_let_per_gra END),--Req. 87567 E2.1 ID## AVILCA
        p_val_porc_tea_sigv,
        p_val_porc_tep_sigv,
        p_ind_gps,
        p_val_porc_cuo_bal,
        p_val_cuo_bal,
        p_ind_tip_seg,
        p_cod_cia_seg,
        p_cod_tip_uso_veh,
        p_val_tasa_seg,
        p_val_tasa_ori_seg,
        p_val_prima_seg,
        p_cod_tip_unidad,
        p_val_porc_gast_adm,
        p_val_gast_adm,
        p_val_int_per_gra,
        p_cod_usua_sid,
        SYSDATE,
        DECODE(p_cod_moneda, 'SOL', 1, 2),
        p_can_dias_venc_1ra_letr,--<I Req. 87567 E2.1 ID 69 AVILCA 25/08/2020>
        p_tip_soli_cred,
        p_txt_otr_cond,
        p_val_tc,
        p_val_ind_sin_int --Req. 87567 E2.1 ID## AVILCA
    );
    
    --Actualización de estado de solicitud si se cambia la tasa del seguro
    UPDATE vve_cred_soli
        SET 
        val_tc = p_val_tc,
        COD_ESTADO = CASE WHEN p_val_tasa_seg < p_val_tasa_ori_seg
                            THEN 'ES08' --Pendiente Seguros
                            ELSE 'ES03' --En Evaluación
                         END  
    WHERE cod_soli_cred = p_cod_soli_cred;

    --Registrar la actividad - Parámetros simulador
    IF p_cod_soli_cred IS NOT NULL THEN
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti
        (
            p_cod_soli_cred,
            'E2',
            'A6',
            p_cod_usua_sid,
            p_ret_esta,
            p_ret_mens            
        );
    END IF;
    
    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Los parámetros de simulación se guardaron con éxito';
    
  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_INSE_PARA_SIMULADOR',
                                            p_cod_usua_sid,
                                            'Error al insertar la simulación de cuotas',
                                            p_ret_mens,
                                            p_cod_soli_cred);
        ROLLBACK;  
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_INSE_PARA_SIMULADOR:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_INSE_PARA_SIMULADOR',
                                            p_cod_usua_sid,
                                            'Error al insertar la simulación de cuotas',
                                            p_ret_mens,
                                            p_cod_soli_cred);
      ROLLBACK;        
  END sp_inse_para_simulador;
  
  PROCEDURE sp_inse_para_gasto
  (
    p_cod_conc_col       IN vve_cred_simu_gast.cod_conc_col%TYPE,
    p_cod_simu           IN vve_cred_simu_gast.cod_simu%TYPE,
    p_val_mon_total      IN vve_cred_simu_gast.val_mon_total%TYPE,
    p_ind_fin            IN vve_cred_simu_gast.ind_fin%TYPE,
    p_val_mon_per        IN vve_cred_simu_gast.val_mon_per%TYPE,
    p_cod_moneda         IN vve_cred_simu_gast.cod_moneda%TYPE,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod_simu_gast  OUT vve_cred_simu_gast.cod_cred_simu_gast%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ) AS
  
    ln_can_tot_let      NUMBER;
    ln_can_let_per_gra  NUMBER;
    ln_val_prima_seg    vve_cred_simu.val_prima_seg%type;
  BEGIN
    p_ret_cod_simu_gast := seq_vve_cred_simu_gast.nextval;
  
    --Obtener valores de la tabla de parametros del simulador
    SELECT can_tot_let,
           can_let_per_gra,
           val_prima_seg
    INTO ln_can_tot_let,
         ln_can_let_per_gra,
         ln_val_prima_seg
    FROM vve_cred_simu
    WHERE cod_simu = p_cod_simu
        AND ind_inactivo = 'N';  
  
    INSERT INTO vve_cred_simu_gast 
    (
        cod_cred_simu_gast,
        cod_conc_col,
        cod_simu,
        val_mon_total,
        ind_fin,
        val_mon_per,
        cod_moneda,
        cod_usua_crea_reg,
        fec_crea_reg
    ) 
    VALUES 
    (
        p_ret_cod_simu_gast,
        p_cod_conc_col,
        p_cod_simu,
        ln_val_prima_seg,
        p_ind_fin,
        DECODE(p_ind_fin, 'N', TO_CHAR(p_val_mon_total / (ln_can_tot_let + ln_can_let_per_gra), '999999999999D99'), 0),
        DECODE(p_cod_moneda, 'SOL', 1, 2),
        p_cod_usua_sid,
        SYSDATE
    );
  
    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'La simulación de gastos se guardo con éxito';
    
  EXCEPTION                                        
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_INSE_PARA_GASTO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_PARA_GASTO',
                                          p_cod_usua_sid,
                                          'Error al insertar la simulación de gastos',
                                          p_ret_mens,
                                          p_cod_simu);
      ROLLBACK;  
  END sp_inse_para_gasto;

  PROCEDURE sp_list_crono
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor_row   OUT SYS_REFCURSOR,
    p_ret_cursor_col   OUT SYS_REFCURSOR,
    p_ret_cursor_total OUT SYS_REFCURSOR,
    p_ret_cursor_proc  OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS  
    ln_sql_stmt  VARCHAR2(4000);
    ln_pivot_sql VARCHAR2(4000);
    ln_cod_simu  NUMBER;
  BEGIN
    IF p_cod_simu IS NOT NULL THEN
        ln_cod_simu := p_cod_simu;
    ELSE            
        BEGIN
            SELECT NVL(MAX(TO_NUMBER(cod_simu)), 0)
            INTO ln_cod_simu
            FROM vve_cred_simu
            WHERE (cod_soli_cred = p_cod_soli_cred 
                OR num_prof_veh = p_num_prof_veh)
                AND ind_inactivo = 'N';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_cod_simu := 0;
        END;            
    END IF;    
    
    OPEN p_ret_cursor_col FOR
        SELECT cod_conc_col,
               des_conc,
               num_orden
        FROM vve_cred_maes_conc_letr
        WHERE ind_conc_oblig = 'S'
        UNION ALL
        SELECT mcl.cod_conc_col, 
               mcl.des_conc,
               mcl.num_orden
        FROM vve_cred_simu_gast csg
        INNER JOIN vve_cred_maes_conc_letr mcl
            ON mcl.cod_conc_col = csg.cod_conc_col
        WHERE cod_simu = ln_cod_simu
        ORDER BY num_orden;

    SELECT LISTAGG('''' || des_conc || ''' AS ' || REPLACE(FUN_ELIMINA_CODIGOS(des_conc),' ',''), ',') 
    WITHIN GROUP (ORDER BY cod_conc_col) 
    INTO ln_sql_stmt
    FROM (
        SELECT cod_conc_col,
               des_conc,
               num_orden
        FROM vve_cred_maes_conc_letr
        WHERE ind_conc_oblig = 'S'
        UNION ALL
        SELECT mcl.cod_conc_col, 
               mcl.des_conc,
               mcl.num_orden
        FROM vve_cred_simu_gast csg
        INNER JOIN vve_cred_maes_conc_letr mcl
            ON mcl.cod_conc_col = csg.cod_conc_col
        WHERE cod_simu = ln_cod_simu
        ORDER BY num_orden
    );

    ln_pivot_sql := 'SELECT * FROM
      (
        SELECT p.des_conc,
               c.val_mon_conc,
               TO_NUMBER(c.cod_nume_letr) cod_nume_letr,
               TO_CHAR(TO_DATE(c.fec_venc), ''DD/MM/YYYY'') fec_venc
        FROM vve_cred_simu_lede c             
        INNER JOIN vve_cred_maes_conc_letr p
            ON p.cod_conc_col = c.cod_conc_col 
        WHERE c.cod_simu =  '|| ln_cod_simu ||'
        ORDER BY p.num_orden
      )
      PIVOT
      (
        MAX(val_mon_conc)
        FOR des_conc IN ('|| ln_sql_stmt ||')
      )
      ORDER BY cod_nume_letr';
    
    OPEN p_ret_cursor_row FOR ln_pivot_sql;
    
    OPEN p_ret_cursor_total FOR
        SELECT cs.val_mon_fin tot_mon_fin,
               SUM(DECODE(csd.cod_conc_col,3,csd.val_mon_conc,0)) tot_amortizacion,
               cs.val_prima_seg tot_seg_fin, 
               SUM(CASE csd.cod_conc_col
                  WHEN 4 THEN csd.val_mon_conc
                  WHEN 13 THEN csd.val_mon_conc
               END) tot_interes,
               SUM(DECODE(csd.cod_conc_col,5,csd.val_mon_conc,0)) tot_cuotas   
        FROM vve_cred_simu cs
        INNER JOIN vve_cred_simu_lede csd 
            ON cs.cod_simu = csd.cod_simu
        WHERE cs.cod_simu = ln_cod_simu
            AND csd.cod_conc_col IN (3,4,5,13) --3=Capital,4=Interes,5=Cuota,13=IGV 
        GROUP BY cs.val_mon_fin, cs.val_prima_seg, (cs.val_mon_fin + cs.val_prima_seg);
                 
    OPEN p_ret_cursor_proc FOR
        SELECT 'IND_TASA_SEG_DIF' nombre,
               CASE WHEN cs.val_tasa_seg < cs.val_tasa_ori_seg
                THEN 'S'
                ELSE 'N'
               END restrictivo
        FROM vve_cred_simu cs               
        WHERE cs.cod_simu = ln_cod_simu;

    --Registrar la actividad - Parámetros simulador
    IF p_cod_soli_cred IS NOT NULL THEN
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti
        (
            p_cod_soli_cred,
            'E2',
            'A7',
            p_cod_usua_sid,
            p_ret_esta,
            p_ret_mens            
        );
    END IF;
    
        -- Atualizando actividades y etapas   
    PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A21',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        
    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutada de forma exitosa';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_CRONO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CRONO',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL); 
  END sp_list_crono;
  
  PROCEDURE sp_list_propuesta
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR, 
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS
  BEGIN
    
    OPEN p_ret_cursor FOR
        SELECT pkg_gen_select.func_sel_gen_persona(vcs.cod_clie) cliente, 
            tsc.descripcion tip_soli_cred,
            DECODE(gm.cod_moneda, 1, 'Soles', 'Dólares') nom_moneda,
            gm.des_moneda,
            tuv.descripcion tip_uso_veh,
            --<I Req. 87567 E2.1 ID 77 avilca 20/07/220>
            CASE 
               WHEN vcm.tip_soli_cred = 'TC02' OR vcm.tip_soli_cred = 'TC03' OR vcm.tip_soli_cred = 'TC06' THEN
                   (vcm.val_ci)/(vcm.val_porc_ci/100)--<Req. 87567 E2.1 ID 77 avilca 03/12/2020>
               ELSE
                 vcm.val_mon_fin + vcm.val_ci
               END val_total,  
           --<F Req. 87567 E2.1 ID 77 avilca 20/07/220>               
            vcm.val_ci,
            vcm.val_mon_fin,
            vcm.can_plaz_meses,
            pcs.descripcion per_cred_sol,
            vcm.can_dias_venc_1ra_letr,
            (vcm.can_tot_let + vcm.can_let_per_gra)can_tot_let, --< Req. 87567 E2.1 ID 77 avilca 24/02/2021>
            vcm.val_porc_tea_sigv val_porc_tea,
            vcm.val_int_per_gra,
            vcsl.val_mont_letr,
            vcm.val_cuo_bal,
            vcm.val_gast_adm,
            DECODE(vcm.ind_gps,'S','Incluido','No') ind_gps,
            vcm.txt_otr_cond txt_otr_cond, -- otras condiciones
            fn_val_cred_simu_lede(vcm.cod_simu,vcm.can_let_per_gra + 1,3) cuota_credito, --Capital
            fn_val_cred_simu_lede(vcm.cod_simu,vcm.can_let_per_gra + 1,4) int_1ra_letra, --Interes   
            fn_val_cred_simu_lede(vcm.cod_simu,vcm.can_let_per_gra + 1,5) total_letra,   --Cuota   
            NVL(fn_val_cred_simu_lede(vcm.cod_simu,vcm.can_let_per_gra + 1,8),0) val_seg_letra,  --Seguro
            NVL(csp.can_veh_fin,0) * NVL(pvd.val_pre_veh,0) * 0.18 val_garantia,
            --<I Req. 87567 E2.1 ID 77 avilca 28/12/2020>
            CASE 
               WHEN vcm.tip_soli_cred = 'TC02' OR vcm.tip_soli_cred = 'TC03' OR vcm.tip_soli_cred = 'TC06' THEN
                   'Garantías adicionales'
               ELSE
                 'Mismas unidades'
               END des_garantias,
            CASE 
               WHEN vcm.tip_soli_cred = 'TC02' OR vcm.tip_soli_cred = 'TC03' OR vcm.tip_soli_cred = 'TC06' THEN
                   'Endosado'
               ELSE
                 'Seguro de las unidades contratado a través de Diveimport SA'
               END des_seguros
           --<F Req. 87567 E2.1 ID 77 avilca 28/12/2020>   
        FROM vve_cred_simu vcm
        INNER JOIN vve_cred_simu_letr vcsl
            ON vcsl.cod_simu = vcm.cod_simu 
            AND vcsl.cod_nume_letr = vcm.can_let_per_gra + 1
        LEFT OUTER JOIN vve_cred_soli vcs
            ON vcs.cod_soli_cred = vcm.cod_soli_cred                        
        LEFT OUTER JOIN vve_cred_soli_prof csp
            ON csp.cod_soli_cred = vcm.cod_soli_cred
        LEFT OUTER JOIN vve_proforma_veh_det pvd
            ON pvd.num_prof_veh = csp.num_prof_veh
        LEFT OUTER JOIN vve_tabla_maes tsc 
            ON tsc.cod_grupo = 86 
            AND tsc.cod_tipo = vcs.tip_soli_cred 
                OR tsc.cod_tipo = vcm.tip_soli_cred              
        LEFT OUTER JOIN vve_tabla_maes pcs
            ON pcs.cod_grupo = 88 
            AND pcs.cod_tipo = vcm.cod_per_cred_sol 
        LEFT OUTER JOIN vve_tabla_maes tuv
            ON tuv.cod_grupo = 97 
            AND tuv.cod_tipo = vcm.cod_tip_uso_veh         
        LEFT OUTER JOIN gen_moneda gm
            ON gm.cod_moneda = vcm.cod_moneda
        WHERE (vcm.cod_soli_cred = p_cod_soli_cred 
            OR vcm.num_prof_veh = p_num_prof_veh
            OR vcm.cod_simu = p_cod_simu)
            AND vcm.ind_inactivo = 'N';   
            
   
    -- Atualizando actividades y etapas   
   -- PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A21',p_cod_usua_sid,p_ret_esta,p_ret_mens);
    
    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutada de forma exitosa';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_PROPUESTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROPUESTA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL); 
  END sp_list_propuesta;  
  
  PROCEDURE sp_gene_plan_cambio_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error            EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_dato_usuario      VARCHAR(50);
    v_destinatarios     vve_correo_prof.destinatarios%TYPE;
    v_mensaje           CLOB;
    v_correoori         usuarios.di_correo%TYPE;
  BEGIN    
    --Remitente
    v_correoori := 'apps@divemotor.com.pe';
    
    --Obtener gestor de seguros
    SELECT val_para_car 
        INTO v_destinatarios
    FROM vve_cred_soli_para 
    WHERE cod_cred_soli_para = 'MAILGESTSEG';
    
    --Solicitante
    SELECT (txt_apellidos || ', ' || txt_nombres)
        INTO v_dato_usuario
    FROM sistemas.sis_mae_usuario
    WHERE cod_id_usuario = p_cod_usua_web;

    v_asunto := ' Solicitud de aprobación TASA MENOR - Nro. Solicitud: ' || LTRIM(p_cod_soli_cred,'0');

    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Solicitud de aprobación TASA MENOR</title>
                <meta charset="utf-8">

                <style>
                  div, p, a, li, td { -webkit-text-size-adjust:none; }

                  @media screen and (max-width: 500px) {
                    .mainTable,.mailBody,.to100{
                      width:100% !important;
                    }

                  }
                </style>
                <style>
                  @media screen and (max-width: 500px) {
                    .mailBody{
                      padding: 20px 18px !important
                    }
                    .col3{
                      width: 100%!important
                    }
                  }
                </style>
              </head>
              <body style="background-color: #eeeeee; margin: 0;">
                <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
                  <tr>
                    <td style="padding: 0;">

                      <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                        <tr>
                          <td style="padding: 0;">
                            <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                              <tr style="background-color: #222222;">
                                <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Solicitud de Crédito</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">'||v_asunto||'</h1>
                            <div style="padding: 10px 0;">
                            </div>
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 400px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Validar los datos de la póliza ingresados para la solicitud nro: ' || LTRIM(p_cod_soli_cred,'0') ||'</p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Solicitante</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                   rtrim(v_dato_usuario) ||
                   '</p>
                                </td>
                              </tr>
                            </table>
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';

    pkg_sweb_cred_soli_evento.sp_inse_correo
    (
        p_cod_soli_cred,
        v_destinatarios,
        '',
        v_asunto,
        v_mensaje,
        v_correoori,
        p_cod_usua_sid,
        p_cod_usua_web,
        'TS',
        p_ret_correo,
        p_ret_esta,
        p_ret_mens
    );

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
    
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || ' SP_GENE_PLAN_CAMBIO_TASA';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GENE_PLAN_CAMBIO_TASA',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);
  END sp_gene_plan_cambio_tasa; 
  
  PROCEDURE sp_list_gasto
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS
    ln_cod_simu  NUMBER;
  BEGIN
    IF p_cod_simu IS NOT NULL THEN
        ln_cod_simu := p_cod_simu;
    ELSE
        BEGIN
            SELECT NVL(cod_simu, 0)
            INTO ln_cod_simu
            FROM vve_cred_simu
            WHERE (cod_soli_cred = p_cod_soli_cred 
                OR num_prof_veh = p_num_prof_veh)
                AND ind_inactivo = 'N';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_cod_simu := 0;
        END;
    END IF;       
        
    OPEN p_ret_cursor FOR
        SELECT cmc.cod_conc_col,
               cmc.des_conc,
               csg.val_mon_total,
               csg.val_mon_per,
               DECODE(csg.cod_moneda,1,'SOL','DOL') cod_moneda,
               csg.ind_fin
        FROM vve_cred_simu_gast csg
        INNER JOIN vve_cred_maes_conc_letr cmc
            ON cmc.cod_conc_col = csg.cod_conc_col
        WHERE csg.cod_simu = ln_cod_simu;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutada de forma exitosa';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_GASTO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_GASTO',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);     
  END sp_list_gasto;  

  FUNCTION fn_pago
  (
    p_tasa     IN NUMBER,
    p_num_per  IN NUMBER,   
    p_va       IN NUMBER,
    p_vf       IN NUMBER DEFAULT 0,
    p_tipo     IN NUMBER DEFAULT 0
  ) RETURN NUMBER AS
  BEGIN  
    RETURN (-p_tasa * (p_va * POWER(1 + p_tasa, p_num_per) + p_vf) / ((1 + p_tasa * p_tipo) * 
            (POWER(1 + p_tasa, p_num_per) - 1)));
  END fn_pago;

  FUNCTION fn_val_cred_simu_lede 
  (
    p_cod_simu           IN vve_cred_simu_lede.cod_simu%TYPE,
    p_cod_nume_letr      IN vve_cred_simu_lede.cod_nume_letr%TYPE,
    p_cod_conc_col       IN vve_cred_simu_lede.cod_conc_col%TYPE
  ) RETURN NUMBER AS
    v_val_mon_conc  vve_cred_simu_lede.val_mon_conc%TYPE;
  BEGIN
    SELECT val_mon_conc 
    INTO   v_val_mon_conc
    FROM   vve_cred_simu_lede
    WHERE  cod_simu = p_cod_simu
    AND    cod_nume_letr = p_cod_nume_letr
    AND    cod_conc_col = p_cod_conc_col;
    RETURN v_val_mon_conc;
  END fn_val_cred_simu_lede;

  FUNCTION fn_tir 
  (
    p_value_list IN vve_tyta_tir_list
  ) RETURN NUMBER AS
    l_threshold     NUMBER := 0.005;
    l_guess         NUMBER := l_threshold + 1;
    l_next_guess    NUMBER := 2;
    l_irr           NUMBER := 1;
  BEGIN
    WHILE ABS(l_guess) > l_threshold
        LOOP
            l_guess := 0;
            l_next_guess := 0;
            FOR i IN 1 .. p_value_list.COUNT
            LOOP
                l_guess := l_guess + p_value_list(i)/POWER(1+l_irr/100, i-1);
                l_next_guess := l_next_guess + -i*p_value_list(i)/POWER(1+l_irr/100, i-1);
            END LOOP;
            l_irr := l_irr - l_guess/l_next_guess;
        END LOOP;
    RETURN TO_CHAR(l_irr, '999999999999D999');
  END fn_tir;
  
  PROCEDURE sp_list_tasas
  (
    p_co_cia        IN  arlcin.no_cia%TYPE,
    p_moneda        IN  arlchi.moneda%TYPE,
    p_cod_usua_sid  IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2 
  ) AS
    ve_error EXCEPTION;  
  BEGIN
    OPEN p_ret_cursor FOR
        SELECT a.codigo, 
               a.descripcion, 
               MAX(b.porcentaje) AS porcentaje
        FROM arlcin a, arlchi b
        WHERE a.no_cia = p_co_cia
            AND a.codigo = b.codigo
            AND a.no_cia = b.no_cia
            AND b.moneda = p_moneda
        GROUP BY a.codigo,a.descripcion;
        
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
    
  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
                                            'SP_LIST_TASAS', 
                                            p_cod_usua_sid, 
                                            'Error en la consulta', 
                                            p_ret_mens, 
                                            NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_TASAS:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
                                            'SP_LIST_TASAS', 
                                            p_cod_usua_sid, 
                                            'Error en la consulta', 
                                            p_ret_mens, 
                                            NULL);
  END sp_list_tasas;
  
  PROCEDURE sp_inse_para_proforma
  (
    p_cod_soli_cred      IN vve_cred_soli_prof.cod_soli_cred%TYPE,
    p_num_prof_veh       IN vve_cred_soli_prof.num_prof_veh%TYPE,
    p_can_veh_fin        IN vve_cred_soli_prof.can_veh_fin%TYPE,
    p_val_vta_tot_fin    IN vve_cred_soli_prof.val_vta_tot_fin%TYPE,
    p_ind_registro       IN CHAR,  
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_num_prof_veh   OUT vve_cred_simu.num_prof_veh%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ) AS
    v_can_veh_ori NUMBER :=0;
  BEGIN
    p_ret_num_prof_veh := p_num_prof_veh;
    
   /** I Req. 87567 E2.1 ID:11 - avilca 26/08/2020 **/
    --Obteniendo número de vehículos 
    BEGIN
        SELECT can_veh_fin  INTO v_can_veh_ori
         FROM vve_cred_soli_prof 
        WHERE cod_soli_cred= p_cod_soli_cred
        AND num_prof_veh = p_num_prof_veh;
   EXCEPTION
            WHEN NO_DATA_FOUND THEN  
            v_can_veh_ori := 0;
   END; 
  /** F Req. 87567 E2.1 ID:11 - avilca 26/08/2020 **/
  
    IF p_ind_registro = 'N' THEN
        BEGIN
            /*Eliminando relación entre garantía y solicitud*/
            DELETE FROM vve_cred_soli_gara 
            WHERE cod_gara IN (SELECT cod_garantia 
                               FROM vve_cred_maes_gara 
                               WHERE num_proforma_veh = p_num_prof_veh) 
                AND cod_soli_cred = p_cod_soli_cred;
                               
            /*Eliminando relación entre maestro de garantía y proforma*/
            DELETE FROM vve_cred_maes_gara 
            WHERE num_proforma_veh = p_num_prof_veh;
            
            /*Eliminando relación entre proforma y solicitud*/
            UPDATE vve_cred_soli_prof 
            SET ind_inactivo = 'S'
            WHERE cod_soli_cred = p_cod_soli_cred
                AND num_prof_veh = p_num_prof_veh;
        END;
    ELSIF p_ind_registro = 'S' THEN
        BEGIN
            INSERT INTO vve_cred_soli_prof
            (
                cod_soli_cred,
                num_prof_veh,
                can_veh_fin,
                val_vta_tot_fin,
                cod_usua_crea_reg,
                fec_crea_reg,
                ind_inactivo
            )
            VALUES
            (
                p_cod_soli_cred,
                p_num_prof_veh,
                p_can_veh_fin,
                p_val_vta_tot_fin,
                p_cod_usua_sid,
                SYSDATE,
                'N'
            );
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                UPDATE vve_cred_soli_prof
                SET can_veh_fin = p_can_veh_fin,
                    val_vta_tot_fin = p_val_vta_tot_fin,
                    cod_usua_modi_reg = p_cod_usua_sid,
                    fec_modi_reg = SYSDATE,
                    ind_inactivo = 'N'
                WHERE cod_soli_cred = cod_soli_cred
                    AND num_prof_veh = p_num_prof_veh;
        END;
    END IF;
    
    /** I Req. 87567 E2.1 ID:11 - avilca 26/08/2020 **/
    --Si se cambia el número de vehiculos en la proforma del simulador se elimina los datos
    -- generados en el flujo de caja
    IF v_can_veh_ori <> 0 AND  v_can_veh_ori <> p_can_veh_fin THEN
     DELETE FROM vve_cred_soli_fact_fc
     WHERE cod_soli_cred = p_cod_soli_cred;
    END IF;
    /** F Req. 87567 E2.1 ID:11 - avilca 26/08/2020 **/   
    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'La proforma se guardo con éxito';
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_INSE_PARA_PROFORMA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_PARA_PROFORMA',
                                          p_cod_usua_sid,
                                          'Error al insertar la proforma',
                                          p_ret_mens,
                                          p_cod_soli_cred);
      ROLLBACK; 
  END sp_inse_para_proforma;
  
  
END PKG_SWEB_CRED_SOLI_SIMULADOR;