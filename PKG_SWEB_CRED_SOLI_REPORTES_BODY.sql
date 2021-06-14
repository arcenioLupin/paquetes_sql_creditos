create or replace PACKAGE BODY   VENTA.PKG_SWEB_CRED_SOLI_REPORTES AS

PROCEDURE SP_LIST_CRED_SOLI_VC_COD_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
       -- p_cod_oper          IN vve_cred_soli.cod_oper_rel%type, --no necesario
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
    
    
    BEGIN
     --Lista de Operaciones por cliente
        OPEN p_ret_cursor FOR
            SELECT cod_oper_rel AS cod_oper 
              FROM vve_cred_soli WHERE cod_clie = p_cod_clie--<cod_cliente> 
               AND ind_inactivo = 'N'
             UNION
            SELECT cod_oper FROM arlcop WHERE no_cliente = p_cod_clie--<cod_cliente> 
               AND estado = 'A';

      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';
    END;

PROCEDURE SP_LIST_CRED_SOLI_VC_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
    v_cod_solid_cred        VARCHAR2(20);
    v_cod_cia               vve_cred_soli.cod_empr%type;
    v_nro_operacion         vve_cred_soli.cod_oper_rel%type;
    v_tipo_operacion        VARCHAR2(20);
    v_fecha_otorgamiento    VARCHAR2(20);
    v_fecha_vencimiento     VARCHAR2(20);
    v_plazo_dias            VARCHAR2(20);
    v_tea_porc              VARCHAR2(20);
    v_val_porc_tea_sigv     vve_cred_soli.val_porc_tea_sigv%type;
    v_tea                   arlcop.tea%type;
     --c_oper_cursor           SYS_REFCURSOR;
    --v_txt_clie_oper         SYS_REFCURSOR;
 BEGIN
        v_cod_solid_cred := '';
        v_cod_cia := '';
        v_tipo_operacion := '';
        v_fecha_otorgamiento := '';
        v_tea_porc := '';

        --Obtener codSoliCred y codCia
        BEGIN
            SELECT sc.cod_soli_cred, sc.cod_empr, sc.tip_soli_cred, sc.cod_oper_rel
                INTO v_cod_solid_cred, v_cod_cia, v_tipo_operacion, v_nro_operacion
            FROM vve_cred_soli sc
            WHERE sc.cod_clie = p_cod_clie AND sc.cod_oper_rel IS NOT NULL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_cod_solid_cred := NULL;
                v_cod_cia := NULL;
                v_tipo_operacion := NULL;
        END;

        IF(v_cod_solid_cred IS NOT NULL) THEN
            BEGIN
                SELECT distinct(no_cia) INTO v_cod_cia 
                FROM arlcop
                WHERE no_cliente = TO_CHAR(p_cod_clie);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_cod_cia := NULL;
            END;
        END IF;

        --TIPO_OPERACION
        IF(v_cod_solid_cred IS NOT NULL AND v_tipo_operacion IS NOT NULL) THEN
            BEGIN
                SELECT m.descripcion INTO v_tipo_operacion
                FROM vve_tabla_maes m, vve_cred_soli cs
                WHERE cs.cod_clie = p_cod_clie 
                   AND cs.cod_oper_rel = v_nro_operacion -- IN (v_nro_operacion)
                   AND m.cod_grupo = 86
                   AND m.cod_tipo = cs.tip_soli_cred;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_tipo_operacion := NULL;
            END;
        ELSE 
            BEGIN
                SELECT m.descripcion INTO v_tipo_operacion
                  FROM vve_tabla_maes m 
                 WHERE m.cod_grupo = 86
                   AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07') 
                                FROM arlcop o
                               WHERE o.no_cliente = TO_CHAR(p_cod_clie) 
                                 AND cod_oper = v_nro_operacion -- IN (v_nro_operacion) 
                            );
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_tipo_operacion := NULL;
            END;
        END IF;

        --FECHA_OTORGAMIENTO
        IF(v_cod_solid_cred IS NOT NULL) THEN
            BEGIN 
             SELECT DECODE(fec_apro_inte,NULL,'--',TO_CHAR(fec_apro_inte,'DD/MM/YYYY HH24:MI:SS')) INTO v_fecha_otorgamiento
               FROM vve_cred_soli WHERE cod_clie = p_cod_clie
                AND cod_oper_rel = v_nro_operacion;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_fecha_otorgamiento := NULL;
            END;
        ELSE
            BEGIN 
                SELECT DECODE(fecha_aut_ope,NULL,'--',TO_CHAR(fecha_aut_ope,'DD/MM/YYYY HH24:MI:SS')) INTO v_fecha_otorgamiento
                  FROM arlcop 
                WHERE no_cliente = TO_CHAR(p_cod_clie)
                   AND cod_oper = v_nro_operacion;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_fecha_otorgamiento := NULL;
            END;
        END IF;
        --v_fecha_otorgamiento := NVL(v_fecha_otorgamiento,'--'); 

        --FECHA_VENCIMIENTO
        BEGIN
            SELECT MAX(to_char(f_vence,'DD/MM/YYYY HH24:MI:SS')) fec_vencimiento INTO v_fecha_vencimiento
                   FROM arlcml  
                  WHERE no_cliente = TO_CHAR(p_cod_clie)
                    AND cod_oper = v_nro_operacion
                    AND (v_cod_cia = '' OR v_cod_cia = no_cia) --<cod_empresa de la op o solicitud>
               GROUP BY cod_oper;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_fecha_vencimiento := NULL;
        END;

        --PLAZO DIAS
        BEGIN
            SELECT q.plazo_dias_op||' días' INTO v_plazo_dias from (SELECT (CASE nvl(ind_per_gra,'N')  
                   WHEN 'S' THEN (no_cuotas+1)*fre_pago_dias 
                   WHEN 'N' THEN no_cuotas*fre_pago_dias 
                   END) plazo_dias_op 
            FROM arlcop 
            WHERE cod_oper = v_nro_operacion--<nro_operacion> 
            AND NOT EXISTS (SELECT 1 FROM vve_cred_soli WHERE cod_clie = p_cod_clie AND cod_oper_rel = cod_oper) 
            UNION
            SELECT no_cuotas*fre_pago_dias AS plazo_dias_op 
            FROM arlcop
            WHERE cod_oper = v_nro_operacion--<nro_operacion>  
            AND EXISTS (SELECT 1 FROM vve_cred_soli WHERE cod_clie = p_cod_clie AND cod_oper_rel = cod_oper)) q ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_plazo_dias := NULL;
        END;

       --TEA
       BEGIN
           SELECT sc.val_porc_tea_sigv, o.tea INTO  v_val_porc_tea_sigv, v_tea
                 FROM vve_cred_soli sc, arlcop o
                WHERE sc.cod_oper_rel = o.cod_oper 
                  AND sc.cod_clie = o.no_cliente
                  AND sc.cod_oper_rel = v_nro_operacion
                  AND sc.cod_clie = p_cod_clie;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_val_porc_tea_sigv := NULL;
            v_tea := NULL;
       END;

       IF(v_val_porc_tea_sigv IS NOT NULL AND v_tea IS NOT NULL) THEN
            BEGIN
               SELECT round((v_val_porc_tea_sigv / v_tea),2) INTO  v_tea_porc
                 FROM vve_cred_soli sc, arlcop o
                WHERE sc.cod_oper_rel = o.cod_oper 
                  AND sc.cod_clie = o.no_cliente
                  AND sc.cod_oper_rel = v_nro_operacion
                  AND sc.cod_clie = p_cod_clie; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_tea_porc := NULL;
            END;
        ELSE
          v_tea_porc := '0.00';
        END IF;

        OPEN p_ret_cursor FOR
        SELECT v_cod_cia AS NRO_CIA,
               v_nro_operacion AS NRO_OPERACION,
               v_tipo_operacion AS TIPO_OPERACION,
               v_fecha_otorgamiento AS FEC_OTORGAMIENTO,
               v_fecha_vencimiento AS FEC_VENCIMIENTO,
               v_plazo_dias AS PLAZO_DIAS,
               v_tea_porc AS TEA
        FROM DUAL;

      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRED_SOLI_VC_OPERS:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_CRED_SOLI_VC_OPERS',NULL, 'Error en la consulta'
            , p_ret_mens, NULL);

  END SP_LIST_CRED_SOLI_VC_OPERS;

PROCEDURE SP_LIST_CRED_SOLI_VC_GARAN(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS

 BEGIN
    OPEN p_ret_cursor FOR
    SELECT s.cod_oper_rel AS NRO_OPERACION,
           g.cod_garantia AS NRO_GARANTIA,
           decode(ind_tipo_garantia,'M','Mobiliaria','H','Hipotecaria') AS TIPO_GARANTIA,
           (CASE nvl(sg.ind_gara_adic,'N') 
            WHEN 'N' THEN s.nro_poli_seg WHEN 'S' THEN 'N/A'  END) AS NRO_POLI, 
            (CASE nvl(sg.ind_gara_adic,'N') 
            WHEN 'N' THEN s.cod_esta_poli WHEN 'S' THEN 'N/A' END) AS COD_EST_POLI,
            decode(sg.ind_gara_adic,null,
                  (SELECT descripcion 
                     FROM vve_tabla_maes m 
                    WHERE m.cod_grupo = 109 
                      AND cod_tipo = s.cod_esta_poli),null, null) AS EST_POLI,
           'USD' AS DIVISA,
           g.val_const_gar*0.8 AS VAL_COMERCIAL,
           g.val_realiz_gar AS VAL_REALIZ,
           g.fec_fab_const AS FEC_CONST
           FROM vve_cred_maes_gara g, vve_cred_soli_gara sg, vve_cred_soli s
    WHERE  s.cod_clie = p_cod_clie
    AND s.cod_soli_cred = sg.cod_soli_cred 
    AND sg.cod_gara = g.cod_garantia 
    --AND s.cod_oper_rel = p_cod_oper
    --and s.cod_oper_rel in ( '5621','5783','5785','5890','5892','5990','6166','6418')
    ORDER BY 3;


    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRED_SOLI_VC_GARAN:' || SQLERRM; 
  END SP_LIST_CRED_SOLI_VC_GARAN;


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
) AS
BEGIN
    OPEN p_ret_cursor FOR
        SELECT
            --cs.cod_soli_cred AS nro_solicitud,
            --cs.cod_oper_rel AS cod_operacion,
            --gav.cod_area_vta||'-'|| gav.des_area_vta AS AREA_VENTA,
            gav.des_area_vta AS AREA_VENTA,
            cs.cod_clie AS COD_CLIENTE,
            gp.nom_perso AS NOM_CLIENTE,
            CASE
                WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica'
                ELSE 'Natural'
            END AS TIPO_PERSONA,
            pv.num_ficha_vta_veh AS NRO_FICHA_VENTA,
            sp.can_veh_fin AS NRO_UNIDADES,
            sp.val_vta_tot_fin AS TOTAL_VENTA,
            (
             SELECT descripcion
             FROM vve_tabla_maes
             WHERE cod_grupo = '86' AND cod_tipo = cs.tip_soli_cred
            ) AS TIPO_OPERACION,
            cs.val_ci AS CUOTA_INICIAL,
            cs.val_mon_fin AS MONTO_FINANCIADO,
            cs.can_plaz_mes AS NRO_MESES,
            --zo.cod_zona||'-'|| zo.des_zona AS REGION,
            zo.des_zona AS REGION,
            cs.fec_soli_cred AS FECHA,
            (
             SELECT
                 CASE
                     WHEN veh.des_agru_veh_seg = '' THEN 'N/A'
                     ELSE veh.des_agru_veh_seg
                 END
             FROM vve_cred_maes_gara cmg
             INNER JOIN vve_cred_agru_veh_seg veh ON cmg.cod_tipo_veh = veh.cod_agru_veh_seg
             INNER JOIN vve_cred_soli_gara csg ON csg.cod_gara = cmg.cod_garantia
             WHERE csg.cod_soli_cred = cs.cod_soli_cred
                 AND ROWNUM = 1
            ) AS SEGMENTO,
            (
             SELECT f.nom_filial
             FROM gen_filiales f, vve_proforma_veh p, vve_cred_soli_prof sp, vve_cred_soli s
             WHERE s.cod_soli_cred = sp.cod_soli_cred 
             AND sp.num_prof_veh = p.num_prof_veh
             AND p.cod_filial = f.cod_filial
             AND p.cod_sucursal = f.cod_sucursal
             AND s.cod_soli_cred = cs.cod_soli_cred
             AND ROWNUM = 1
            ) AS SUCURSAL,
            cs.cod_oper_rel AS OP_CRONOGRAMA,
            cs.val_porc_ci AS CUOTA_INICIAL_PORCENTAJE,
            cs.fec_venc_1ra_let AS VENCIMIENTO_PRIMERA_LETRA,
            cs.val_porc_tea_sigv AS TEA_SIN_IGV,
            ADD_MONTHS(cs.fec_venc_1ra_let, (cs.can_plaz_mes -1)) AS VENCIMIENTO_ULTIMA_LETRA,
            (
             SELECT
                 SUM(cmg.val_realiz_gar)
             FROM vve_cred_maes_gara cmg
             INNER JOIN vve_cred_soli_gara csg ON csg.cod_gara = cmg.cod_garantia
             INNER JOIN vve_cred_soli crs ON crs.cod_soli_cred = csg.cod_soli_cred
             WHERE crs.cod_oper_rel = cs.cod_oper_rel
             AND crs.cod_soli_cred = cs.cod_soli_cred
             AND csg.ind_gara_adic = 'S'
            ) AS GARANTIAS_ADICIONALES,
            --,
            --RATIO_COBERTURA,

            CASE
                WHEN cs.val_porc_gast_admi > 0 THEN TO_CHAR(cs.val_porc_gast_admi) || '%'
                ELSE '0'
            END AS GASTOS_ADMINISTRATIVOS,
            (
             SELECT
                CASE
                    WHEN descripcion = 'Divemotor' THEN 'SI'
                    ELSE 'NO'
                END
             FROM vve_tabla_maes
             WHERE cod_grupo = '90' AND cod_tipo = cs.ind_tipo_segu
            ) AS SEGURO_DIVEMOTOR
        FROM gen_persona gp
            INNER JOIN vve_cred_soli cs ON gp.cod_perso = cs.cod_clie
            INNER JOIN gen_area_vta gav ON gav.cod_area_vta = cs.cod_area_vta
            INNER JOIN vve_cred_soli_prof sp ON cs.cod_soli_cred = sp.cod_soli_cred
            INNER JOIN vve_ficha_vta_veh fv ON fv.cod_clie = cs.cod_clie
            INNER JOIN vve_mae_zona_filial zf ON fv.cod_filial = zf.cod_filial
            INNER JOIN vve_ficha_vta_proforma_veh pv ON fv.num_ficha_vta_veh = pv.num_ficha_vta_veh
            INNER JOIN vve_mae_zona zo ON zf.cod_zona = zo.cod_zona
        WHERE fv.cod_clie = cs.cod_clie
            AND sp.num_prof_veh = pv.num_prof_veh
            AND (p_cod_region IS NULL OR zo.cod_zona = p_cod_region) --2 4
            AND (p_cod_area_vta IS NULL OR gav.cod_area_vta = p_cod_area_vta) --001 camiones,003 buses
            AND (p_cod_tipo_oper IS NULL OR cs.tip_soli_cred = p_cod_tipo_oper) --TC02 TC06
            AND (( p_fec_factu_inicio IS NULL AND p_fec_factu_fin IS NULL ) OR
            TRUNC(cs.fec_soli_cred) BETWEEN TO_DATE(p_fec_factu_inicio,'DD/MM/YYYY') AND TO_DATE(p_fec_factu_fin,'DD/MM/YYYY'));

      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRED_SOLI_CO:' || SQLERRM;
  END SP_LIST_CRED_SOLI_CO;

END PKG_SWEB_CRED_SOLI_REPORTES;