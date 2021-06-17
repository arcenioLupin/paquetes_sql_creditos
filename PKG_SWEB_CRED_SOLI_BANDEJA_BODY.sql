create or replace PACKAGE BODY       VENTA.PKG_SWEB_CRED_SOLI_BANDEJA AS

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
  ) AS

    ve_error            EXCEPTION;
    ln_limitinf         NUMBER := 0;
    ln_limitsup         NUMBER := 0;
    v_perf_asesor       vve_cred_soli_para.val_para_car%type;
    v_perf_gf           vve_cred_soli_para.val_para_car%type; --<Req 87567 E2.2 LR 01.03.2021>
    v_cod_soli_cred     vve_cred_soli.cod_soli_cred%TYPE;
    v_size_cod_cred     NUMBER(3);
    v_cod_pers_soli     vve_cred_soli.cod_pers_soli%type;  --<Req 87567 E2.2 LR 10.03.2021>

  BEGIN
    IF p_ind_paginado = 'N' THEN
        SELECT COUNT(1)
            INTO ln_limitsup
        FROM vve_cred_soli;    
    ELSE
        ln_limitinf := p_limitinf - 1;
        ln_limitsup := p_limitsup;
    END IF; 

    SELECT val_para_car 
      INTO v_perf_asesor
      FROM vve_cred_soli_para 
     WHERE cod_cred_soli_para = 'ROLPERFASE';

    --<I Req 87567 E2.2 LR 01.03.2021>
    SELECT val_para_car 
      INTO v_perf_gf
      FROM vve_cred_soli_para 
     WHERE cod_cred_soli_para = 'ROLGESCRED'; 
    --<F Req 87567 E2.2 LR 01.03.2021>

    --<I Req 87567 E2.2 LR 10.03.2021>
    IF p_cod_pers_soli IS NOT NULL THEN
        SELECT txt_usuario 
            INTO v_cod_pers_soli  
        FROM sis_mae_usuario 
        WHERE cod_id_usuario = p_cod_pers_soli;
    ELSE
        v_cod_pers_soli := NULL;
    END IF;
    --<F Req 87567 E2.2 LR 10.03.2021>

    IF p_cod_soli_cred IS NOT NULL THEN 
        SELECT LENGTH(cod_soli_cred) INTO v_size_cod_cred FROM vve_cred_soli WHERE ROWNUM=1;
        SELECT lpad(p_cod_soli_cred,v_size_cod_cred,'0') INTO v_cod_soli_cred from dual; -- si se ingresa el nro de solicitud sin ceros a la izquierda, se los agrega
    END IF;

    OPEN p_ret_cursor FOR
       SELECT * 
       FROM
       ( 
          SELECT
               sc.cod_soli_cred,
               sc.txt_obse_crea,
               sc.can_plaz_mes,
               sc.cod_area_vta,
               pkg_sweb_mae_gene.fu_desc_area_vta(sc.cod_area_vta) as des_area_vta, 
               TO_CHAR(sc.fec_soli_cred, 'DD/MM/YYYY') as fec_soli_cred,
               z.des_zona as region,
               z.des_zona as nombre_zona,               
               z.cod_zona as cod_zona,               
               pkg_sweb_cred_soli_bandeja.fn_desc_sucu(pv.cod_sucursal) as nombre_sucursal,
               pv.cod_sucursal as cod_sucursal,
               pkg_gen_select.func_sel_arccve(pv.vendedor) as nombre_vendedor,               
               pv.vendedor as cod_vendedor,  --<Req 87567 E2.2 LR 10.03.2021>sc.cod_pers_soli as cod_vendedor, 
               pkg_sweb_mae_gene.fu_desc_fili(pv.cod_filial) as nombre_filial,               
               pv.cod_filial as cod_filial, 
               sc.cod_clie,
               gp.nom_perso,
               gp.cod_estado_civil,
               gp.cod_tipo_perso,
               CASE
                   WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica'  --<Req 87567 E2.2 LR 10.03.2021>
                   ELSE 'Natural'
               END AS tipo_perso,  
               gp.ind_mancomunado,
               gp.num_docu_iden,
               gp.num_ruc,
               gp.dir_correo,
               gp.num_telf_movil,
               dp.num_telf1 as num_telf1,
               sc.tip_soli_cred,
               pkg_sweb_mae_gene.fu_desc_maes('86',sc.tip_soli_cred) AS des_tipo_soli_cred,
               sc.cod_estado,
               pkg_sweb_mae_gene.fu_desc_maes('86',sc.tip_soli_cred) as descripcion, -- se repite el campo
               upper(pkg_sweb_mae_gene.fu_desc_maes('92',sc.cod_estado)) AS des_estado, -- estado de la solicitud
               TO_CHAR(sc.fec_apro_clie, 'DD/MM/YYYY') AS fec_apro_clie,
               pkg_sweb_cred_soli_bandeja.fn_desc_acti_actu(sc.cod_soli_cred) AS act_actual,
               pkg_sweb_cred_soli_bandeja.fn_cod_id_usua(sc.cod_pers_soli) AS cod_pers_soli,
               pkg_sweb_cred_soli_bandeja.fn_nom_usua(sc.cod_pers_soli) AS des_pers_soli,
               sc.cod_resp_fina,
               pkg_sweb_cred_soli_bandeja.fn_nom_usua(sc.cod_resp_fina) AS des_resp_fina,
               sc.cod_empr,
               cia.nombre AS des_nom_empr,
               pv.num_prof_veh,
               pkg_sweb_cred_soli_bandeja.fn_vta_total_fin(sc.cod_soli_cred) val_vta_tot_fin,
               pv.cod_moneda_prof,
               pkg_gen_select.func_sel_arccve(pv.vendedor) AS vendedor,
               vpv.num_ficha_vta_veh,
               sc.cod_banco,
               sc.val_mon_fin as monto_sol_cred,
               sc.val_mont_sol_gest_banc,    
               sc.val_porc_gest_banc,            
               sc.fec_ingr_gest_banc,                   
               sc.fec_ingr_ries_gest_banc,   
               sc.fec_aprob_cart_ban,         
               sc.fec_resu_gest_banc,     
               sc.cod_esta_gest_banc,       
               sc.txt_obse_gest_banc,      
               DECODE(sc.tip_soli_cred,'TC03','S',DECODE(sc.tip_soli_cred,'TC02','S',DECODE(sc.tip_soli_cred,'TC06','S','N'))) AS ind_pago_contado, --**********
               DECODE(sc.cod_estado,'ES03','S',decode(sc.cod_estado,'ES07','S','N')) AS ind_cred_aprobado, -- **********
               DECODE(sc.tip_soli_cred,'TC04','S','N') AS ind_bloqueo_pestanias,
               DECODE(sc.tip_soli_cred,'TC04','S',decode(sc.cod_estado,'TC05','S','N')) AS ind_cred_vehi,
               DECODE(sc.tip_soli_cred,'TC06','S','N') AS ind_gest_banc,
               CASE 
                    WHEN sc.cod_esta_gest_banc = 'EGB02' THEN 'RI' --Riesgo    
                    WHEN sc.cod_esta_gest_banc = 'EGB03' THEN 'AT' --Aprobado Total
                    WHEN sc.cod_esta_gest_banc = 'EGB04' THEN 'AP' --Aprobado Parcial
                    WHEN sc.cod_esta_gest_banc = 'EGB05' THEN 'RE' --Rechazado
                    ELSE 'IN' --Si es nulo o Ingresado
               END AS esta_gest_banc,     
               pkg_sweb_cred_soli_bandeja.fn_can_total_veh_fin(sc.cod_soli_cred) as can_veh_fin, --<Req 87567 E2.2 LR 10.03.2021> se cambió el procedimiento fn_vta_total_fin a fn_can_total_veh_fin
               pd.val_pre_veh as val_pre_veh,
               (select porcentaje from arcgiv where clave = '01' and no_cia = sc.cod_empr) as igv,       
               (select porcentaje from arcgiv where clave = '03' and no_cia = sc.cod_empr) as ir,
               (select val_para_num from vve_cred_soli_para where cod_cred_soli_para = 'ADEPVEH') as val_para_num, -- años depreciación vehículo
               sc.cod_oper_rel, 
               sc.cod_oper_orig,
               sc.val_porc_ci,
               sc.val_ci,
               sc.val_pago_cont_ci,
               TO_CHAR(sc.fec_venc_1ra_let, 'DD/MM/YYYY') as fecVenc1raLet,
               sc.can_dias_venc_1ra_letr,
               sc.cod_peri_cred_soli,           
               sc.can_tota_letr,
               sc.ind_tipo_peri_grac,
               sc.val_dias_peri_grac,
               sc.can_letr_peri_grac,
               sc.val_int_per_gra,
               sc.val_porc_tea_sigv, 
               sc.val_porc_tep_sigv,
               sc.ind_gps,
               sc.val_porc_cuot_ball,
               sc.val_cuot_ball,
               sc.ind_tipo_segu,
               sc.cod_cia_seg,
               sc.cod_tip_uso_veh,
               sc.val_tasa_segu,
               sc.val_prim_seg,
               sc.cod_tipo_unid,
               sc.val_porc_gast_admi,
               sc.val_gasto_admi,
               ltrim(dp.cod_clie_sap,'0') as cod_clie_sap, -- (select substr(cod_clie_sap, 4, 8) from gen_dir_perso where cod_perso = sc.cod_clie and ind_inactivo = 'N' and ind_dir_defecto = 'S') as cod_clie_sap,
               (select tipo_cambio from arcgtc where clase_cambio = '02' and fecha = trunc(sysdate)) as tipo_cambio,
               case sc.cod_estado 
               when 'ES06' then 'S' 
               else 'N' 
               end ind_cred_recha,
               pkg_sweb_cred_soli_bandeja.fn_txt_fech_ult_venc(sc.cod_soli_cred) as fec_ulti_venc,
               pkg_sweb_cred_soli_bandeja.fn_txt_otr_cond_simu(sc.cod_soli_cred) as txt_otr_cond, -- si vve_cred_simu.txt_otr_cond 
               sc.can_dias_fact_cred,
               sc.txt_obse_jv,
               sc.val_tc,
               pkg_sweb_cred_soli_bandeja.fn_can_gara(sc.cod_soli_cred) as can_gara_soli,  -- **** todas? (estoy poniendo todas como el query anterior, falta validar su funcionalidad, Mobiliarias financiadas? o adicionales?
               sc.ind_resp_apro_tseg
            FROM
               vve_cred_soli sc 
               INNER JOIN vve_cred_soli_prof sp on sp.cod_soli_cred = sc.cod_soli_cred 
                                                   and sp.num_prof_veh in (select max(sp1.num_prof_veh) from vve_cred_soli_prof sp1 where sp1.cod_soli_cred = sc.cod_soli_cred and sp1.ind_inactivo = 'N')
               INNER JOIN vve_ficha_vta_proforma_veh vpv on vpv.num_prof_veh = sp.num_prof_veh  
               INNER JOIN vve_proforma_veh pv on pv.num_prof_veh = vpv.num_prof_veh and pv.cod_cia = sc.cod_empr and vpv.ind_inactivo = 'N' --<Req 87567 E2.2 LR 23.02.2021> se agregó and vpv.ind_inactivo = 'N' 
               INNER JOIN vve_proforma_veh_det pd on pd.num_prof_veh = pv.num_prof_veh 
               INNER JOIN vve_mae_zona_filial zf on zf.cod_filial = pv.cod_filial 
               INNER JOIN vve_mae_zona z on z.cod_zona = zf.cod_zona 
               INNER JOIN gen_persona gp on gp.cod_perso = pv.cod_clie
               INNER JOIN gen_dir_perso dp on dp.cod_perso = gp.cod_perso and dp.ind_inactivo = 'N' and ind_dir_defecto = 'S'
               INNER JOIN arcgmc cia on cia.no_cia = pv.cod_cia 
               INNER JOIN sis_mae_usuario u on u.cod_id_usuario = p_cod_usua_web and u.txt_usuario = p_cod_usua_sid 
               INNER JOIN sis_mae_perfil_usuario pu on u.cod_id_usuario = pu.cod_id_usuario  and pu.ind_inactivo = 'N' 
          WHERE 
           (sc.ind_inactivo is null or sc.ind_inactivo = 'N') 
           and exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'TIPCREDSINPROF' and instr(val_para_car,sc.tip_soli_cred)=0)
           and (p_cod_soli_cred is null or (p_cod_soli_cred is not null and v_cod_soli_cred = sc.cod_soli_cred))
           and (p_fec_ini is null or (p_fec_ini is not null and to_date(p_fec_ini,'dd/mm/yyyy') <= trunc(sc.fec_crea_regi))) 
           and (p_fec_fin is null or (p_fec_fin is not null and to_date(p_fec_fin,'dd/mm/yyyy') >= trunc(sc.fec_crea_regi)))
           and (p_cod_area_vta is null or (p_cod_area_vta is not null and p_cod_area_vta = sc.cod_area_vta)) 
           and (p_tip_soli_cred is null or (p_tip_soli_cred is not null and p_tip_soli_cred = sc.tip_soli_cred))
           and (p_cod_clie is null or (p_cod_clie is not null and p_cod_clie = sc.cod_clie)) 
           and (p_ruc_cliente is null or (p_ruc_cliente is not null and p_ruc_cliente = gp.num_ruc))
           and (p_cod_pers_soli is null or (p_cod_pers_soli is not null and v_cod_pers_soli = sc.cod_pers_soli))
           and (p_cod_resp_fina is null or (p_cod_resp_fina is not null and p_cod_resp_fina = sc.cod_resp_fina))
           and (p_cod_empr is null or (p_cod_empr is not null and p_cod_empr = sc.cod_empr))
           and (p_cod_zona is null or (p_cod_zona is not null and p_cod_zona = z.cod_zona)) 
           and (p_cod_estado is null or (p_cod_estado is not null and p_cod_estado = sc.cod_estado))
           --<I Req 87567 E2.2 LR 01.03.2021>
           and ((pu.cod_id_perfil = v_perf_gf and u.txt_usuario = sc.cod_resp_fina) or (pu.cod_id_perfil <> v_perf_gf)) 
           AND (exists (select 1 from vve_cred_org_cred_vtas ov where (pu.cod_id_perfil <> v_perf_asesor and ov.cod_area_vta = pv.cod_area_vta and ov.cod_filial = pv.cod_filial and ov.cod_zona = zf.cod_zona)  
                                                                         and (((pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is null and ov.co_usuario = p_cod_usua_sid) 
                                                                              or (pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is not null and ov.co_usua_bckp = p_cod_usua_sid))
                                                                              AND ((((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))>1)
                                                                                  and (instr((select pp.val_para_car 
                                                                                            from vve_cred_soli_para pp
                                                                                            where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'PERFDEFAULT'),pp.cod_cred_soli_para)>0 
                                                                                            and   instr(pp.val_para_num,p_cod_usua_web)>0),pu.cod_id_perfil)>0)
                                                                                    )  
                                                                                  OR 
                                                                                   ((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))=1))
                                                                              ))
                   OR (pu.cod_id_perfil = v_perf_asesor and u.txt_usuario = sc.cod_pers_soli)
                   OR (exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'ROLCONSOTR' and instr(val_para_car, pu.cod_id_perfil)>0))
               )
           --<F Req 87567 E2.2 LR 01.03.2021>
           AND (pu.cod_id_perfil in (select pp.val_para_num 
                                    from vve_cred_soli_para pp
                                    where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0 
                                    and   instr(pp.val_para_car,sc.cod_estado)>0)  
                )
    UNION  
    SELECT
           sc.cod_soli_cred,
           sc.txt_obse_crea,
           sc.can_plaz_mes,
           sc.cod_area_vta,
           pkg_sweb_mae_gene.fu_desc_area_vta(sc.cod_area_vta) as des_area_vta, 
           TO_CHAR(sc.fec_soli_cred, 'DD/MM/YYYY') as fec_soli_cred,
           z.des_zona as region,
           z.des_zona as nombre_zona,               
           z.cod_zona as cod_zona,               
           pkg_sweb_cred_soli_bandeja.fn_desc_sucu(sc.cod_sucursal) as nombre_sucursal,
           sc.cod_sucursal as cod_sucursal,
           pkg_gen_select.func_sel_arccve(sc.vendedor) as nombre_vendedor,               
           sc.vendedor as cod_vendedor, --<Req 87567 E2.2 LR 10.03.2021>sc.cod_pers_soli as cod_vendedor, 
           pkg_sweb_mae_gene.fu_desc_fili(sc.cod_filial) as nombre_filial,               
           sc.cod_filial as cod_filial, 
           sc.cod_clie,
           gp.nom_perso,
           gp.cod_estado_civil,
           gp.cod_tipo_perso,
           CASE
               WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica'  --<Req 87567 E2.2 LR 10.03.2021>
               ELSE 'Natural'
           END AS tipo_perso,
           gp.ind_mancomunado,
           gp.num_docu_iden,
           gp.num_ruc,
           gp.dir_correo,
           gp.num_telf_movil,
           dp.num_telf1 as num_telf1,
           sc.tip_soli_cred,
           pkg_sweb_mae_gene.fu_desc_maes('86',sc.tip_soli_cred) AS des_tipo_soli_cred,
           sc.cod_estado,
           pkg_sweb_mae_gene.fu_desc_maes('86',sc.tip_soli_cred) as descripcion, -- se repite el campo
           upper (pkg_sweb_mae_gene.fu_desc_maes('92',sc.cod_estado)) AS des_estado, -- estado de la solicitud
           TO_CHAR(sc.fec_apro_clie, 'DD/MM/YYYY') AS fec_apro_clie,
           pkg_sweb_cred_soli_bandeja.fn_desc_acti_actu(sc.cod_soli_cred) AS act_actual,
           pkg_sweb_cred_soli_bandeja.fn_cod_id_usua(sc.cod_pers_soli) AS cod_pers_soli,
           pkg_sweb_cred_soli_bandeja.fn_nom_usua(sc.cod_pers_soli) AS des_pers_soli,
           sc.cod_resp_fina,
           pkg_sweb_cred_soli_bandeja.fn_nom_usua(sc.cod_resp_fina) AS des_resp_fina,
           sc.cod_empr,
           cia.nombre AS des_nom_empr,
           null as num_prof_veh,
           sc.val_mon_fin as val_vta_tot_fin,
           sc.cod_mone_soli as cod_moneda_prof,
           pkg_gen_select.func_sel_arccve(sc.vendedor) AS vendedor,
           null as num_ficha_vta_veh,
           sc.cod_banco,
           sc.val_mon_fin as monto_sol_cred,
           sc.val_mont_sol_gest_banc,    
           sc.val_porc_gest_banc,            
           sc.fec_ingr_gest_banc,                   
           sc.fec_ingr_ries_gest_banc,   
           sc.fec_aprob_cart_ban,         
           sc.fec_resu_gest_banc,     
           sc.cod_esta_gest_banc,       
           sc.txt_obse_gest_banc,      
           DECODE(sc.tip_soli_cred,'TC03','S',DECODE(sc.tip_soli_cred,'TC02','S',DECODE(sc.tip_soli_cred,'TC06','S','N'))) AS ind_pago_contado, --**********
           DECODE(sc.cod_estado,'ES03','S',decode(sc.cod_estado,'ES07','S','N')) AS ind_cred_aprobado, -- **********
           DECODE(sc.tip_soli_cred,'TC04','S','N') AS ind_bloqueo_pestanias,
           DECODE(sc.tip_soli_cred,'TC04','S',decode(sc.cod_estado,'TC05','S','N')) AS ind_cred_vehi,
           DECODE(sc.tip_soli_cred,'TC06','S','N') AS ind_gest_banc,
           CASE 
                WHEN sc.cod_esta_gest_banc = 'EGB02' THEN 'RI' --Riesgo    
                WHEN sc.cod_esta_gest_banc = 'EGB03' THEN 'AT' --Aprobado Total
                WHEN sc.cod_esta_gest_banc = 'EGB04' THEN 'AP' --Aprobado Parcial
                WHEN sc.cod_esta_gest_banc = 'EGB05' THEN 'RE' --Rechazado
                ELSE 'IN' --Si es nulo o Ingresado
           END AS esta_gest_banc,     
           null as can_veh_fin,
           null as val_pre_veh,
           (select porcentaje from arcgiv where clave = '01' and no_cia = sc.cod_empr) as igv,       
           (select porcentaje from arcgiv where clave = '03' and no_cia = sc.cod_empr) as ir,
           (select val_para_num from vve_cred_soli_para where cod_cred_soli_para = 'ADEPVEH') as val_para_num, -- años depreciación vehículo
           sc.cod_oper_rel, 
           sc.cod_oper_orig,
           sc.val_porc_ci,
           sc.val_ci,
           sc.val_pago_cont_ci,
           TO_CHAR(sc.fec_venc_1ra_let, 'DD/MM/YYYY') as fecVenc1raLet,
           sc.can_dias_venc_1ra_letr,
           sc.cod_peri_cred_soli,           
           sc.can_tota_letr,
           sc.ind_tipo_peri_grac,
           sc.val_dias_peri_grac,
           sc.can_letr_peri_grac,
           sc.val_int_per_gra,
           sc.val_porc_tea_sigv, 
           sc.val_porc_tep_sigv,
           sc.ind_gps,
           sc.val_porc_cuot_ball,
           sc.val_cuot_ball,
           sc.ind_tipo_segu,
           sc.cod_cia_seg,
           sc.cod_tip_uso_veh,
           sc.val_tasa_segu,
           sc.val_prim_seg,
           sc.cod_tipo_unid,
           sc.val_porc_gast_admi,
           sc.val_gasto_admi,
           ltrim(dp.cod_clie_sap,'0') as cod_clie_sap, -- (select substr(cod_clie_sap, 4, 8) from gen_dir_perso where cod_perso = sc.cod_clie and ind_inactivo = 'N' and ind_dir_defecto = 'S') as cod_clie_sap,
           (select tipo_cambio from arcgtc where clase_cambio = '02' and fecha = trunc(sysdate)) as tipo_cambio,
           case sc.cod_estado 
           when 'ES06' then 'S' 
           else 'N' 
           end ind_cred_recha,
           pkg_sweb_cred_soli_bandeja.fn_txt_fech_ult_venc(sc.cod_soli_cred) as fec_ulti_venc,
           pkg_sweb_cred_soli_bandeja.fn_txt_otr_cond_simu(sc.cod_soli_cred) as txt_otr_cond, -- si vve_cred_simu.txt_otr_cond 
           sc.can_dias_fact_cred,
           sc.txt_obse_jv,
           sc.val_tc,
           pkg_sweb_cred_soli_bandeja.fn_can_gara(sc.cod_soli_cred) as can_gara_soli,  -- **** todas? (estoy poniendo todas como el query anterior, falta validar su funcionalidad, Mobiliarias financiadas? o adicionales?
           sc.ind_resp_apro_tseg
        FROM
           vve_cred_soli sc 
           INNER JOIN vve_mae_zona_filial zf on zf.cod_filial = sc.cod_filial and zf.cod_zona = sc.cod_zona 
           INNER JOIN vve_mae_zona z on z.cod_zona = zf.cod_zona 
           INNER JOIN gen_persona gp on gp.cod_perso = sc.cod_clie
           INNER JOIN gen_dir_perso dp on dp.cod_perso = gp.cod_perso and dp.ind_inactivo = 'N' and ind_dir_defecto = 'S'
           INNER JOIN arcgmc cia on cia.no_cia = sc.cod_empr 
           INNER JOIN sis_mae_usuario u on u.cod_id_usuario = p_cod_usua_web and u.txt_usuario = p_cod_usua_sid 
           INNER JOIN sis_mae_perfil_usuario pu on u.cod_id_usuario = pu.cod_id_usuario  and pu.ind_inactivo = 'N' 
      WHERE 
        (sc.ind_inactivo is null or sc.ind_inactivo = 'N') 
       and exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'TIPCREDSINPROF' and instr(val_para_car,sc.tip_soli_cred)>0)
       and (p_cod_soli_cred is null or (p_cod_soli_cred is not null and v_cod_soli_cred = sc.cod_soli_cred))
       and (p_fec_ini is null or (p_fec_ini is not null and to_date(p_fec_ini,'dd/mm/yyyy') <= trunc(sc.fec_crea_regi))) 
       and (p_fec_fin is null or (p_fec_fin is not null and to_date(p_fec_fin,'dd/mm/yyyy') >= trunc(sc.fec_crea_regi)))
       and (p_cod_area_vta is null or (p_cod_area_vta is not null and p_cod_area_vta = sc.cod_area_vta)) 
       and (p_tip_soli_cred is null or (p_tip_soli_cred is not null and p_tip_soli_cred = sc.tip_soli_cred))
       and (p_cod_clie is null or (p_cod_clie is not null and p_cod_clie = sc.cod_clie)) 
       and (p_ruc_cliente is null or (p_ruc_cliente is not null and p_ruc_cliente = gp.num_ruc))
       and (p_cod_pers_soli is null or (p_cod_pers_soli is not null and v_cod_pers_soli = sc.cod_pers_soli))
       and (p_cod_resp_fina is null or (p_cod_resp_fina is not null and p_cod_resp_fina = sc.cod_resp_fina))
       and (p_cod_empr is null or (p_cod_empr is not null and p_cod_empr = sc.cod_empr))
       and (p_cod_zona is null or (p_cod_zona is not null and p_cod_zona = z.cod_zona)) 
       and (p_cod_estado is null or (p_cod_estado is not null and p_cod_estado = sc.cod_estado))
       --<I Req 87567 E2.2 LR 01.03.2021>
       and ((pu.cod_id_perfil = v_perf_gf and u.txt_usuario = sc.cod_resp_fina) or (pu.cod_id_perfil <> v_perf_gf)) 
       AND (exists (select 1 from vve_cred_org_cred_vtas ov where (pu.cod_id_perfil <> v_perf_asesor and ov.cod_area_vta = sc.cod_area_vta and ov.cod_filial = sc.cod_filial and ov.cod_zona = zf.cod_zona)  
                                                                         and (((pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is null and ov.co_usuario = p_cod_usua_sid) 
                                                                              or (pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is not null and ov.co_usua_bckp = p_cod_usua_sid))
                                                                              AND ((((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))>1)
                                                                                  and (instr((select pp.val_para_car 
                                                                                            from vve_cred_soli_para pp
                                                                                            where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'PERFDEFAULT'),pp.cod_cred_soli_para)>0 
                                                                                            and   instr(pp.val_para_num,p_cod_usua_web)>0),pu.cod_id_perfil)>0)
                                                                                    )  
                                                                                  OR 
                                                                                   ((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))=1))
                                                                              ))
                   OR (pu.cod_id_perfil = v_perf_asesor and u.txt_usuario = sc.cod_pers_soli)
                   OR (exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'ROLCONSOTR' and instr(val_para_car, pu.cod_id_perfil)>0))
               )
       --<F Req 87567 E2.2 LR 01.03.2021>
       AND (pu.cod_id_perfil in (select pp.val_para_num 
                                from vve_cred_soli_para pp
                                where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0 
                                and   instr(pp.val_para_car,sc.cod_estado)>0)  
            )
      ) s
        ORDER BY TO_DATE(s.fec_soli_cred, 'DD/MM/YYYY') DESC
        OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY;

   -- p_ret_mens := '1er query';

    SELECT COUNT(1) 
       INTO p_cantidad
       FROM (
         SELECT
            sc.cod_soli_cred 
        FROM
           vve_cred_soli sc 
           INNER JOIN vve_cred_soli_prof sp on sp.cod_soli_cred = sc.cod_soli_cred 
                                                   and sp.num_prof_veh in (select max(sp1.num_prof_veh) from vve_cred_soli_prof sp1 where sp1.cod_soli_cred = sc.cod_soli_cred and sp1.ind_inactivo = 'N')
           INNER JOIN vve_ficha_vta_proforma_veh vpv on vpv.num_prof_veh = sp.num_prof_veh  
           INNER JOIN vve_proforma_veh pv on pv.num_prof_veh = vpv.num_prof_veh and pv.cod_cia = sc.cod_empr  and vpv.ind_inactivo = 'N' --<Req 87567 E2.2 LR 23.02.2021> se agregó and vpv.ind_inactivo = 'N' 
           INNER JOIN vve_proforma_veh_det pd on pd.num_prof_veh = pv.num_prof_veh 
           INNER JOIN vve_mae_zona_filial zf on zf.cod_filial = pv.cod_filial 
           INNER JOIN vve_mae_zona z on z.cod_zona = zf.cod_zona 
           INNER JOIN gen_persona gp on gp.cod_perso = pv.cod_clie
           INNER JOIN gen_dir_perso dp on dp.cod_perso = gp.cod_perso and dp.ind_inactivo = 'N' and ind_dir_defecto = 'S'
           INNER JOIN arcgmc cia on cia.no_cia = pv.cod_cia 
           INNER JOIN sis_mae_usuario u on u.cod_id_usuario = p_cod_usua_web and u.txt_usuario = p_cod_usua_sid 
           INNER JOIN sis_mae_perfil_usuario pu on u.cod_id_usuario = pu.cod_id_usuario  and pu.ind_inactivo = 'N' 
          WHERE 
            (sc.ind_inactivo is null or sc.ind_inactivo = 'N') 
           and exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'TIPCREDSINPROF' and instr(val_para_car,sc.tip_soli_cred)=0)
           and (p_cod_soli_cred is null or (p_cod_soli_cred is not null and v_cod_soli_cred = sc.cod_soli_cred))
           and (p_fec_ini is null or (p_fec_ini is not null and to_date(p_fec_ini,'dd/mm/yyyy') <= trunc(sc.fec_crea_regi))) 
           and (p_fec_fin is null or (p_fec_fin is not null and to_date(p_fec_fin,'dd/mm/yyyy') >= trunc(sc.fec_crea_regi)))
           and (p_cod_area_vta is null or (p_cod_area_vta is not null and p_cod_area_vta = sc.cod_area_vta)) 
           and (p_tip_soli_cred is null or (p_tip_soli_cred is not null and p_tip_soli_cred = sc.tip_soli_cred))
           and (p_cod_clie is null or (p_cod_clie is not null and p_cod_clie = sc.cod_clie)) 
           and (p_ruc_cliente is null or (p_ruc_cliente is not null and p_ruc_cliente = gp.num_ruc))
           and (p_cod_pers_soli is null or (p_cod_pers_soli is not null and v_cod_pers_soli = sc.cod_pers_soli))
           and (p_cod_resp_fina is null or (p_cod_resp_fina is not null and p_cod_resp_fina = sc.cod_resp_fina))
           and (p_cod_empr is null or (p_cod_empr is not null and p_cod_empr = sc.cod_empr))
           and (p_cod_zona is null or (p_cod_zona is not null and p_cod_zona = z.cod_zona)) 
           and (p_cod_estado is null or (p_cod_estado is not null and p_cod_estado = sc.cod_estado))
           --<I Req 87567 E2.2 LR 01.03.2021>
           and ((pu.cod_id_perfil = v_perf_gf and u.txt_usuario = sc.cod_resp_fina) or (pu.cod_id_perfil <> v_perf_gf)) 
           AND (exists (select 1 from vve_cred_org_cred_vtas ov where (pu.cod_id_perfil <> v_perf_asesor and ov.cod_area_vta = pv.cod_area_vta and ov.cod_filial = pv.cod_filial and ov.cod_zona = zf.cod_zona)  
                                                                         and (((pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is null and ov.co_usuario = p_cod_usua_sid) 
                                                                              or (pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is not null and ov.co_usua_bckp = p_cod_usua_sid))
                                                                              AND ((((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))>1)
                                                                                  and (instr((select pp.val_para_car 
                                                                                            from vve_cred_soli_para pp
                                                                                            where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'PERFDEFAULT'),pp.cod_cred_soli_para)>0 
                                                                                            and   instr(pp.val_para_num,p_cod_usua_web)>0),pu.cod_id_perfil)>0)
                                                                                    )  
                                                                                  OR 
                                                                                   ((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))=1))
                                                                              ))
                   OR (pu.cod_id_perfil = v_perf_asesor and u.txt_usuario = sc.cod_pers_soli)
                   OR (exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'ROLCONSOTR' and instr(val_para_car, pu.cod_id_perfil)>0))
               )
           --<F Req 87567 E2.2 LR 01.03.2021>
           AND (pu.cod_id_perfil in (select pp.val_para_num 
                                    from vve_cred_soli_para pp
                                    where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0 
                                    and   instr(pp.val_para_car,sc.cod_estado)>0)  
                )
    UNION  
    SELECT
       sc.cod_soli_cred
     FROM
       vve_cred_soli sc 
       INNER JOIN vve_mae_zona_filial zf on zf.cod_filial = sc.cod_filial and zf.cod_zona = sc.cod_zona 
       INNER JOIN vve_mae_zona z on z.cod_zona = zf.cod_zona 
       INNER JOIN gen_persona gp on gp.cod_perso = sc.cod_clie
       INNER JOIN gen_dir_perso dp on dp.cod_perso = gp.cod_perso and dp.ind_inactivo = 'N' and ind_dir_defecto = 'S'
       INNER JOIN arcgmc cia on cia.no_cia = sc.cod_empr 
       INNER JOIN sis_mae_usuario u on u.cod_id_usuario =p_cod_usua_web  and u.txt_usuario =p_cod_usua_sid  
       INNER JOIN sis_mae_perfil_usuario pu on u.cod_id_usuario = pu.cod_id_usuario  and pu.ind_inactivo = 'N' 
     WHERE 
        (sc.ind_inactivo is null or sc.ind_inactivo = 'N') 
       and exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'TIPCREDSINPROF' and instr(val_para_car,sc.tip_soli_cred)>0)
       and (p_cod_soli_cred is null or (p_cod_soli_cred is not null and v_cod_soli_cred = sc.cod_soli_cred))
       and (p_fec_ini is null or (p_fec_ini is not null and to_date(p_fec_ini,'dd/mm/yyyy') <= trunc(sc.fec_crea_regi))) 
       and (p_fec_fin is null or (p_fec_fin is not null and to_date(p_fec_fin,'dd/mm/yyyy') >= trunc(sc.fec_crea_regi)))
       and (p_cod_area_vta is null or (p_cod_area_vta is not null and p_cod_area_vta = sc.cod_area_vta)) 
       and (p_tip_soli_cred is null or (p_tip_soli_cred is not null and p_tip_soli_cred = sc.tip_soli_cred))
       and (p_cod_clie is null or (p_cod_clie is not null and p_cod_clie = sc.cod_clie)) 
       and (p_ruc_cliente is null or (p_ruc_cliente is not null and p_ruc_cliente = gp.num_ruc))
       and (p_cod_pers_soli is null or (p_cod_pers_soli is not null and v_cod_pers_soli = sc.cod_pers_soli))
       and (p_cod_resp_fina is null or (p_cod_resp_fina is not null and p_cod_resp_fina = sc.cod_resp_fina))
       and (p_cod_empr is null or (p_cod_empr is not null and p_cod_empr = sc.cod_empr))
       and (p_cod_zona is null or (p_cod_zona is not null and p_cod_zona = z.cod_zona)) 
       and (p_cod_estado is null or (p_cod_estado is not null and p_cod_estado = sc.cod_estado))
       --<I Req 87567 E2.2 LR 01.03.2021>
       and ((pu.cod_id_perfil = v_perf_gf and u.txt_usuario = sc.cod_resp_fina) or (pu.cod_id_perfil <> v_perf_gf)) 
       AND (exists (select 1 from vve_cred_org_cred_vtas ov where (pu.cod_id_perfil <> v_perf_asesor and ov.cod_area_vta = sc.cod_area_vta and ov.cod_filial = sc.cod_filial and ov.cod_zona = zf.cod_zona)  
                                                                         and (((pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is null and ov.co_usuario = p_cod_usua_sid) 
                                                                              or (pu.cod_id_perfil = ov.cod_rol_usuario and ov.co_usua_bckp is not null and ov.co_usua_bckp = p_cod_usua_sid))
                                                                              AND ((((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))>1)
                                                                                  and (instr((select pp.val_para_car 
                                                                                            from vve_cred_soli_para pp
                                                                                            where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'PERFDEFAULT'),pp.cod_cred_soli_para)>0 
                                                                                            and   instr(pp.val_para_num,p_cod_usua_web)>0),pu.cod_id_perfil)>0)
                                                                                    )  
                                                                                  OR 
                                                                                   ((select count(pu1.cod_id_perfil) 
                                                                                      from sis_mae_perfil_usuario pu1 
                                                                                      where pu1.cod_id_usuario = p_cod_usua_web 
                                                                                       and pu1.ind_inactivo = 'N' and pu1.cod_id_perfil in (select pp.val_para_num 
                                                                                                                                    from vve_cred_soli_para pp
                                                                                                                                    where instr((select pa.val_para_car from vve_cred_soli_para pa 
                                                                                                                                    where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0))=1))
                                                                              ))
                   OR (pu.cod_id_perfil = v_perf_asesor and u.txt_usuario = sc.cod_pers_soli)
                   OR (exists (select 1 from vve_cred_soli_para where cod_cred_soli_para = 'ROLCONSOTR' and instr(val_para_car, pu.cod_id_perfil)>0))
               )
       --<F Req 87567 E2.2 LR 01.03.2021>
       AND (pu.cod_id_perfil in (select pp.val_para_num 
                                from vve_cred_soli_para pp
                                where instr((select pa.val_para_car from vve_cred_soli_para pa where pa.cod_cred_soli_para = 'BANDESTPERF'),pp.cod_cred_soli_para)>0 
                                and   instr(pp.val_para_car,sc.cod_estado)>0)  
            )
       );

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
                                                'SP_LIST_CRED_SOLI', 
                                                p_cod_usua_sid, 
                                                'Error en la consulta', 
                                                p_ret_mens, 
                                                NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
                                                'SP_LIST_CRED_SOLI', 
                                                p_cod_usua_sid, 
                                                'Error en la consulta', 
                                                p_ret_mens, 
                                                NULL);
  END sp_list_cred_soli;

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
    ) RETURN VARCHAR2 AS 

    v_nom_sucursal  gen_sucursales.nom_sucursal%TYPE;

    BEGIN
         BEGIN
            SELECT nom_sucursal 
            INTO    v_nom_sucursal 
            FROM   gen_sucursales 
            WHERE  cod_sucursal = p_cod_sucursal;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_nom_sucursal := '';
          END;

          RETURN v_nom_sucursal;

    END fn_desc_sucu;

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
    p_txt_usuario    IN sis_mae_usuario.txt_usuario%TYPE
    ) RETURN NUMBER AS
    vn_cod_id_usuario  sis_mae_usuario.cod_id_usuario%TYPE;
    BEGIN
      BEGIN
           SELECT cod_id_usuario 
           INTO vn_cod_id_usuario
           FROM sis_mae_usuario 
           WHERE txt_usuario = p_txt_usuario;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          vn_cod_id_usuario:=-1;
      END;
      RETURN vn_cod_id_usuario;
    END fn_cod_id_usua;

  /********************************************************************************
    Nombre:     FN_NOM_USUARIO
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
    ) RETURN VARCHAR2 AS 
  vc_nom_usuario    VARCHAR2(120);
  BEGIN 
    BEGIN 
      SELECT UPPER(paterno || ' ' || materno || ' ' || nombre1) 
      INTO vc_nom_usuario
      FROM usuarios 
      WHERE co_usuario = p_co_usuario;
    EXCEPTION 
     WHEN NO_DATA_FOUND THEN 
       vc_nom_usuario := '';
    END;

    RETURN vc_nom_usuario;
  END fn_nom_usua;

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
  ) RETURN VARCHAR2 AS 
  vc_des_acti_actu  vve_cred_maes_activ.des_acti_cred%TYPE;
  BEGIN
    BEGIN 
      SELECT x.des_acti_cred 
      INTO vc_des_acti_actu 
      FROM (  SELECT  ma.des_acti_cred, sa.fec_usua_ejec 
                FROM  vve_cred_maes_activ ma
                INNER JOIN vve_cred_soli_acti sa ON ma.cod_acti_cred = sa.cod_acti_cred 
                WHERE sa.cod_soli_cred =  p_cod_soli_cred 
                AND   sa.fec_usua_ejec IS NOT NULL
                ORDER BY 2 DESC ) x 
        WHERE ROWNUM = 1;
   EXCEPTION 
     WHEN NO_DATA_FOUND THEN 
       vc_des_acti_actu := '';
    END;

    RETURN vc_des_acti_actu;
  END fn_desc_acti_actu;

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
  ) RETURN NUMBER AS 
  vn_tota_fin     vve_cred_soli_prof.val_vta_tot_fin%TYPE;
  BEGIN
    BEGIN
      SELECT SUM(val_vta_tot_fin) 
      INTO   vn_tota_fin 
      FROM   vve_cred_soli_prof 
      WHERE  cod_soli_cred = p_cod_soli_cred   
      AND    ind_inactivo = 'N';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vn_tota_fin :=0;
    END;

    RETURN vn_tota_fin;
  END fn_vta_total_fin;

  /********************************************************************************
    Nombre:     FN_CAN_TOTAL_VEH_FIN
    Proposito:  Obtiene el monto total de vta de los vehículos a financiar
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Cód. de la solicitud de crédito.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/02/2021  LURODRIGUEZ        Creación de la función.
  ********************************************************************************/

  FUNCTION fn_can_total_veh_fin(
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE
  ) RETURN NUMBER AS 
  vn_can_tota_veh_fin     vve_cred_soli_prof.val_vta_tot_fin%TYPE;
  BEGIN
    BEGIN
      SELECT SUM(can_veh_fin) 
      INTO   vn_can_tota_veh_fin 
      FROM   vve_cred_soli_prof 
      WHERE  cod_soli_cred = p_cod_soli_cred   
      AND    ind_inactivo = 'N';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vn_can_tota_veh_fin :=0;
    END;

    RETURN vn_can_tota_veh_fin;
  END fn_can_total_veh_fin;

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
  ) RETURN VARCHAR2 AS 
  vc_fec_ult_venc   VARCHAR2(10):= NULL;
  BEGIN
    BEGIN 
      SELECT TO_CHAR(MAX(L.FEC_VENC),'DD/MM/YYYY') 
      INTO   vc_fec_ult_venc 
      FROM   VVE_CRED_SIMU_LETR L 
      INNER JOIN VVE_CRED_SIMU SI ON l.cod_simu = si.cod_simu 
      INNER JOIN VVE_CRED_SOLI S ON s.cod_soli_cred = si.cod_soli_cred and si.ind_inactivo = 'N' 
      WHERE s.cod_soli_cred = p_cod_soli_cred;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
        vc_fec_ult_venc:='';
    END;

    RETURN vc_fec_ult_venc;
  END fn_txt_fech_ult_venc;

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
  ) RETURN VARCHAR2 AS 
  vc_txt_otr_cond       vve_cred_simu.txt_otr_cond%TYPE;
  BEGIN
    BEGIN 
      SELECT si.txt_otr_cond
      INTO   vc_txt_otr_cond 
      FROM   VVE_CRED_SIMU SI 
      INNER JOIN VVE_CRED_SOLI S ON s.cod_soli_cred = si.cod_soli_cred and si.ind_inactivo = 'N' 
      WHERE s.cod_soli_cred = p_cod_soli_cred;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
        vc_txt_otr_cond:='';
    END;

    RETURN vc_txt_otr_cond;
  END fn_txt_otr_cond_simu;

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
  ) RETURN NUMBER AS 
  vn_can_gara     NUMBER(3);
  BEGIN
    BEGIN 
      SELECT COUNT(*) 
      INTO   vn_can_gara
      FROM   vve_cred_soli_gara sg
      WHERE  sg.cod_soli_cred = p_cod_soli_cred  
      AND    ind_inactivo = 'N';
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
        vn_can_gara := 0;
    END;

    RETURN vn_can_gara;
  END fn_can_gara;

END PKG_SWEB_CRED_SOLI_BANDEJA;
