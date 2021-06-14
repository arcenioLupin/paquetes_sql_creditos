create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_SEGURO AS

  PROCEDURE SP_LIST_SOLI_CRED_SEGURO(
   p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  )  AS
  lv_fec_max_simu  VARCHAR2(10);
  lv_fec_min_simu  VARCHAR2(10);
  ln_cod_simu      NUMBER;
  ln_cant_letr_fin NUMBER;
  lv_ind_tip_seg  VARCHAR2(10);
  BEGIN

   -- Obteniendo el código del simulador
    SELECT NVL(MAX(TO_NUMBER(cod_simu)), 0)
            INTO ln_cod_simu
            FROM vve_cred_simu
            WHERE cod_soli_cred = p_cod_soli_cred         
             AND ind_inactivo = 'N';
    -- Obteniendo fechas máxima y mínima del simulador          
      SELECT TO_CHAR(MIN(fec_venc),'dd/mm/yyyy'), TO_CHAR(MAX(fec_venc),'dd/mm/yyyy')
       INTO lv_fec_min_simu,lv_fec_max_simu
       FROM vve_cred_simu_lede
       WHERE cod_simu =  ln_cod_simu
       ORDER BY  fec_venc desc;

   -- Obteniendo el tipo de seguro del simulador
    SELECT ind_tip_seg
            INTO lv_ind_tip_seg
            FROM vve_cred_simu
            WHERE cod_soli_cred = p_cod_soli_cred         
             AND ind_inactivo = 'N';

   -- Obteniendo cantidad de letras del simulador
   --<I Req. 87567 E2.1 ID## AVILCA 30/12/2020>

   /*IF lv_ind_tip_seg = 'TS01' THEN
    SELECT (count(*)/9)
     INTO ln_cant_letr_fin
        FROM vve_cred_simu_lede c             
        INNER JOIN vve_cred_maes_conc_letr p
            ON p.cod_conc_col = c.cod_conc_col 
        WHERE c.cod_simu = ln_cod_simu
        ORDER BY p.num_orden;   
   END IF;

  IF lv_ind_tip_seg = 'TS02' THEN
    SELECT (count(*)/8)
     INTO ln_cant_letr_fin
        FROM vve_cred_simu_lede c             
        INNER JOIN vve_cred_maes_conc_letr p
            ON p.cod_conc_col = c.cod_conc_col 
        WHERE c.cod_simu = ln_cod_simu
        ORDER BY p.num_orden;   
   END IF;*/
   SELECT (cs.can_tota_letr + cs.can_letr_peri_grac) 
    INTO ln_cant_letr_fin
   FROM vve_cred_soli cs 
   WHERE cod_soli_cred = p_cod_soli_cred;
   --<F Req. 87567 E2.1 ID## AVILCA 30/12/2020>
    open p_ret_cursor for
     SELECT sc.IND_TIPO_SEGU,
            sc.NRO_POLI_SEG,
            sc.FEC_INIC_VIGE_POLI,
            sc.FEC_FIN_VIGE_POLI,
            sc.VAL_PORC_TEA_SIGV,
            sc.FEC_PRIM_PAGO_POLI_ENDO,
            sc.FEC_ULTI_PAGO_POLI_ENDO,
            sc.TXT_RUTA_POLI_ENDO,
            sc.TXT_RUTA_FACT,
            sc.VAL_TASA_SEGU,
            lv_fec_min_simu FEC_MIN_SIMU,
            lv_fec_max_simu FEC_MAX_SIMU,
            ln_cant_letr_fin AS CAN_LETR_FIN,
            sc.fec_firm_cont,
            sc.FEC_ACT_POLI,
            sc.cod_cia_seg,--<Req. 87567 E2.1 ID## avilca 30/12/2020>
            sc.fec_firm_cont,--<Req. 87567 E2.1 ID## avilca 05/01/2020>
            sc.ind_resp_apro_tseg

    FROM VVE_CRED_SOLI sc
        INNER JOIN vve_cred_simu si ON sc.cod_soli_cred = si.cod_soli_cred
    WHERE si.COD_SOLI_CRED= p_cod_soli_cred
      AND si.ind_inactivo = 'N';

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_LIST_SOLI_CRED_SEGURO';
  END;

  PROCEDURE SP_LIST_SOLI_CRED_SEGURO_DET(
   p_cod_soli_cred IN vve_cred_soli_even.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  )  AS
  BEGIN
    open p_ret_cursor for
        select (select descripcion from vve_tabla_maes where cod_grupo = '97' and cod_tipo=s.cod_tip_uso_veh) as descripcion, 
        --(select des_tipo_actividad from vve_credito_tipo_actividad where cod_tipo_actividad=g.cod_tipo_actividad) as des_tipo_actividad, 
        g.tipo_actividad as des_tipo_actividad,
        g.nro_placa num_placa_veh, p.num_motor_veh, p.num_chasis, g.can_nro_asie, p.num_pedido_veh,g.cod_garantia
        from vve_pedido_veh p,vve_cred_soli_pedi_veh sp,vve_cred_soli s, vve_cred_maes_gara g
        where p.num_pedido_veh=sp.num_pedido_veh and sp.cod_soli_cred=s.cod_soli_cred and p.num_pedido_veh=g.num_pedido_veh
        and s.cod_soli_cred=p_cod_soli_cred;
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_LIST_SOLI_CRED_SEGURO_DET';

  END ;

  PROCEDURE sp_actu_estado_soli_seg(
    p_cod_soli_cred IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    p_ind_resp_apro_tseg IN vve_cred_soli.ind_resp_apro_tseg%TYPE,
    p_txt_obse_rech_tseg IN vve_cred_soli.txt_obse_rech_tseg%TYPE,
    p_cod_usua_gest_seg IN vve_cred_soli.cod_usua_gest_seg%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )  AS
  BEGIN
    UPDATE VVE_CRED_SOLI
    SET IND_RESP_APRO_TSEG=p_ind_resp_apro_tseg,
        TXT_OBSE_RECH_TSEG=p_txt_obse_rech_tseg,
        COD_USUA_GEST_SEG=p_cod_usua_gest_seg,
        COD_ESTADO = 'ES03'--I Req. 87567 E2.1 ID## avilca 06/10/2020
    WHERE COD_SOLI_CRED=p_cod_soli_cred;
    COMMIT;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR sp_actu_estado_soli_seg';
  END;

  PROCEDURE SP_ACTU_DATOS_SOLI_SEG(
    P_COD_SOLI_CRED IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    P_NRO_POLI_SEG IN vve_cred_soli.NRO_POLI_SEG%TYPE,
    P_FEC_INIC_VIGE_POLI IN VARCHAR2,
    P_FEC_FIN_VIGE_POLI IN VARCHAR2,
    P_FEC_PRIM_PAGO_POLI_ENDO IN VARCHAR2,
    P_FEC_ULTI_PAGO_POLI_ENDO IN VARCHAR2,
    P_TXT_RUTA_POLI_ENDO IN vve_cred_soli.TXT_RUTA_POLI_ENDO%TYPE,
    P_TXT_RUTA_FACT  IN vve_cred_soli.TXT_RUTA_FACT%TYPE,
    P_FEC_ACT_POLI IN VARCHAR2,
    P_COD_USUA_MODI IN vve_cred_soli.COD_USUA_MODI%TYPE,
    P_COD_CIA_SEG IN VARCHAR2,
    P_VAL_PORC_TEA_SIGV IN vve_cred_soli.VAL_TASA_SEGU%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS
  --lv_fec_contrato  DATE;
  lv_fec_contrato_adic  DATE;
  lv_fec_actual  DATE;
  lv_ind_tipo_segu VARCHAR2(5);
  BEGIN

  --I Req. 87567 E2.1 ID## avilca 07/10/2020
  -- Obteniendo tipo de seguro
        SELECT ind_tipo_segu
          INTO lv_ind_tipo_segu
         FROM VVE_CRED_SOLI
         WHERE COD_SOLI_CRED=P_COD_SOLI_CRED;
  --F Req. 87567 E2.1 ID## avilca 07/10/2020

  -- Obteniendo fecha de contrato
         SELECT fec_firm_cont +15
          INTO lv_fec_contrato_adic
         FROM VVE_CRED_SOLI
         WHERE COD_SOLI_CRED=P_COD_SOLI_CRED;

 -- Comparando fecha actual con fecha contrato + 15 dias

        --lv_fec_contrato_adic := lv_fec_contrato +15;
        /*SELECT SYSDATE
        INTO lv_fec_actual
        FROM DUAL;*/
       lv_fec_actual:= TO_DATE(P_FEC_ACT_POLI,'dd/mm/yyyy');  --I Req. 87567 E2.1 ID## avilca 05/01/2021

            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                        'SP_ACTU_DATOS_SOLI_SEG',
                                        NULL,
                                        lv_fec_actual ||' / '||lv_fec_contrato_adic ,
                                        lv_fec_actual ||' / '||lv_fec_contrato_adic ,
                                        lv_fec_actual ||' / '||lv_fec_contrato_adic );

      IF(lv_ind_tipo_segu IS NOT NULL AND P_FEC_ACT_POLI IS NOT NULL) THEN
        IF (lv_fec_actual < lv_fec_contrato_adic ) THEN
                UPDATE VVE_CRED_SOLI
                SET NRO_POLI_SEG=P_NRO_POLI_SEG,
                    --I Req. 87567 E2.1 ID## avilca 13/03/2020
                    FEC_INIC_VIGE_POLI = TO_DATE(P_FEC_INIC_VIGE_POLI,'dd/mm/yyyy'),
                    FEC_FIN_VIGE_POLI= TO_DATE(P_FEC_FIN_VIGE_POLI,'dd/mm/yyyy'),
                    FEC_PRIM_PAGO_POLI_ENDO = TO_DATE(P_FEC_PRIM_PAGO_POLI_ENDO,'dd/mm/yyyy'),
                    FEC_ULTI_PAGO_POLI_ENDO = TO_DATE(P_FEC_ULTI_PAGO_POLI_ENDO,'dd/mm/yyyy'),
                    FEC_ACT_POLI = TO_DATE(P_FEC_ACT_POLI,'dd/mm/yyyy'),
                    --F Req. 87567 E2.1 ID## avilca 13/03/2020
                    TXT_RUTA_POLI_ENDO = P_TXT_RUTA_POLI_ENDO,
                    TXT_RUTA_FACT = P_TXT_RUTA_FACT,
                    COD_ESTADO = 'ES08',
                    COD_USUA_GEST_SEG=P_COD_USUA_MODI,
                    COD_CIA_SEG = P_COD_CIA_SEG,
                    VAL_TASA_SEGU = P_VAL_PORC_TEA_SIGV,
                    IND_SOLI_APRO_TSEG = 'S'

                WHERE COD_SOLI_CRED=P_COD_SOLI_CRED;   
                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';
            ELSE
                p_ret_esta := 2;
                p_ret_mens := 'La fecha actual excedió el plazo de activación de póliza';
       END IF;
    ELSE
                UPDATE VVE_CRED_SOLI
                SET NRO_POLI_SEG=P_NRO_POLI_SEG,
                    --I Req. 87567 E2.1 ID## avilca 13/03/2020
                    FEC_INIC_VIGE_POLI = TO_DATE(P_FEC_INIC_VIGE_POLI,'dd/mm/yyyy'),
                    FEC_FIN_VIGE_POLI= TO_DATE(P_FEC_FIN_VIGE_POLI,'dd/mm/yyyy'),
                    FEC_PRIM_PAGO_POLI_ENDO = TO_DATE(P_FEC_PRIM_PAGO_POLI_ENDO,'dd/mm/yyyy'),
                    FEC_ULTI_PAGO_POLI_ENDO = TO_DATE(P_FEC_ULTI_PAGO_POLI_ENDO,'dd/mm/yyyy'),
                    FEC_ACT_POLI = TO_DATE(P_FEC_ACT_POLI,'dd/mm/yyyy'),
                    --F Req. 87567 E2.1 ID## avilca 13/03/2020
                    TXT_RUTA_POLI_ENDO = P_TXT_RUTA_POLI_ENDO,
                    TXT_RUTA_FACT = P_TXT_RUTA_FACT,
                    COD_ESTADO = 'ES11',
                    COD_USUA_GEST_SEG=P_COD_USUA_MODI,
                    COD_CIA_SEG = P_COD_CIA_SEG,
                    VAL_TASA_SEGU = P_VAL_PORC_TEA_SIGV,
                    IND_SOLI_APRO_TSEG = 'S'

                WHERE COD_SOLI_CRED=P_COD_SOLI_CRED;   
                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';
    END IF;

      EXCEPTION
        WHEN OTHERS THEN
          --p_ret_esta := -1;
         -- p_ret_mens := 'ERROR SP_ACTU_DATOS_SOLI_SEG';
          p_ret_esta := -1;
          p_ret_mens := 'SP_ACTU_DATOS_SOLI_SEG:' || SQLERRM;
         pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_DATOS_SOLI_SEG',
                                          P_COD_USUA_MODI,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL); 
  END;

  PROCEDURE SP_ACTU_PLACA_SOLI_SEG(
    P_COD_GARANTIA IN VVE_CRED_MAES_GARA.COD_GARANTIA%TYPE,
    P_NUM_PLACA_VEH IN VVE_PEDIDO_VEH.NUM_PLACA_VEH %TYPE,
    P_CO_USUARIO_MOD_REG IN VVE_PEDIDO_VEH.CO_USUARIO_MOD_REG%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )  AS

  lv_num_placa  VARCHAR2(15);
  BEGIN

   IF( P_NUM_PLACA_VEH IS NULL OR P_NUM_PLACA_VEH = '') THEN
     lv_num_placa := 'En Trámite';
   ELSE  
     lv_num_placa := P_NUM_PLACA_VEH;
   END IF;

    UPDATE VVE_CRED_MAES_GARA
    SET NRO_PLACA = lv_num_placa,
    COD_USUA_MODI_REGI = P_CO_USUARIO_MOD_REG
    WHERE COD_GARANTIA = P_COD_GARANTIA;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_ACTU_PLACA_SOLI_SEG';
  END;

  PROCEDURE SP_LIST_POLI_SEG(
    P_COD_SOLI_CRED IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    P_NRO_POLI_SEG IN vve_cred_soli.NRO_POLI_SEG%TYPE,
    P_FEC_INIC_VIGE_POLI IN VARCHAR2,
    P_FEC_FIN_VIGE_POLI IN VARCHAR2,
    P_IND_TIPO_SEGU in vve_cred_soli.IND_TIPO_SEGU%TYPE,
    P_COD_CIA_SEG in vve_cred_soli.COD_CIA_SEG%TYPE,
    P_COD_AREA_VTA in vve_cred_soli.COD_AREA_VTA%TYPE,
    P_COD_ESTA_POLI in vve_cred_soli.COD_ESTA_POLI%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )  AS
  BEGIN
    OPEN p_ret_cursor FOR
        SELECT tm.descripcion as des_tipo_seguro,
            cs.nro_poli_seg,
            TO_CHAR(cs.fec_inic_vige_poli,'DD/MM/YYYY') as FEC_INIC_VIGE_POLI,
            TO_CHAR(cs.fec_fin_vige_poli,'DD/MM/YYYY') as FEC_FIN_VIGE_POLI,
            LTRIM(cs.cod_soli_cred, '0') as cod_soli_cred,
            gp.nom_perso as des_cia_seg,
            gav.des_area_vta as des_area_vta,
            TO_CHAR(cs.fec_firm_cont,'DD/MM/YYYY') as fec_firm_cont,
            (SELECT descripcion FROM vve_tabla_maes WHERE cod_tipo = cs.cod_esta_poli) as desEstaPoli
        FROM VVE_CRED_SOLI cs
            INNER JOIN vve_tabla_maes tm
                ON tm.cod_grupo = '90' AND tm.cod_tipo = cs.ind_tipo_segu
            INNER JOIN gen_persona gp
                ON gp.cod_perso = cs.cod_cia_seg
            INNER JOIN gen_area_vta gav
                ON gav.cod_area_vta = cs.cod_area_vta
        WHERE (P_COD_SOLI_CRED IS NULL OR cs.cod_soli_cred like '%'||P_COD_SOLI_CRED||'%')
            AND (P_NRO_POLI_SEG IS NULL OR cs.nro_poli_seg like '%'||P_NRO_POLI_SEG||'%')
            AND (P_IND_TIPO_SEGU IS NULL OR cs.ind_tipo_segu = P_IND_TIPO_SEGU)
            AND (P_FEC_INIC_VIGE_POLI IS NULL OR cs.fec_inic_vige_poli >= TO_DATE(P_FEC_INIC_VIGE_POLI, 'DD/MM/YYYY'))
            AND (P_FEC_FIN_VIGE_POLI IS NULL OR cs.fec_fin_vige_poli <= TO_DATE(P_FEC_FIN_VIGE_POLI, 'DD/MM/YYYY'))
            AND (P_COD_CIA_SEG IS NULL OR cs.cod_cia_seg = P_COD_CIA_SEG)
            AND (P_COD_AREA_VTA IS NULL OR cs.cod_area_vta = P_COD_AREA_VTA)
            AND (P_COD_ESTA_POLI IS NULL OR cs.cod_esta_poli = P_COD_ESTA_POLI)
            AND NRO_POLI_SEG IS NOT NULL;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'ERROR SP_LIST_POLI_SEG';
  END;

 PROCEDURE sp_gen_plantilla_correo_segu
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_txt_correo        VARCHAR2(2000);
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;   
    v_tipo_credito      VARCHAR2(50):= '';
    v_cod_operacion     VARCHAR2(12);
    v_cod_cia_seg       VARCHAR2(8);
    v_nom_cia_seg       VARCHAR2(100);
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

    -- Obtenemos el tipo de crédito,cod compañía aseguradora y cod operación
    SELECT cs.cod_oper_rel,cs.cod_cia_seg,ma.descripcion 
     INTO  v_cod_operacion,v_cod_cia_seg,v_tipo_credito
    FROM VVE_CRED_SOLI cs 
        INNER JOIN vve_tabla_maes ma ON cs.tip_soli_cred = ma.cod_tipo
     WHERE cs.cod_soli_cred= p_cod_soli_cred
     AND ma.cod_grupo = '86';

   -- Obteniendo descripción de compañía aseguradora
     SELECT nom_comercial 
     INTO v_nom_cia_seg
     FROM gen_persona 
     WHERE cod_perso = v_cod_cia_seg;

    -- Obtenemos los correos a Notificar
	  v_query := 'select VVE_CRED_SOLI_PARA.VAL_PARA_CAR from VVE_CRED_SOLI_PARA  where cod_cred_soli_para = ''NOTISEGU''';


    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plantilla_correo_aprob',
                                        NULL,
                                        'error al enviar correo',
                                        v_query,
                                        v_query);


    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;

    v_correos := '';
    v_contador := 1;

   /*  OPEN c_documentos FOR v_query_docu;
        LOOP
            FETCH c_documentos
                INTO v_documento;
            EXIT WHEN c_documentos%NOTFOUND;*/

    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_txt_correo;
      EXIT WHEN c_usuarios%NOTFOUND;

    dbms_output.put_line('3.1');

      IF (v_contador = 1) THEN
        v_correos := v_correos||v_txt_correo;
      ELSE
        v_correos := v_correos||','||v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    END LOOP;
    CLOSE c_usuarios;



    v_asunto := 'Activación Póliza.: ' ||LTRIM(p_cod_soli_cred,'0');


      v_mensaje := '<!DOCTYPE html>
    <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
		<head>
                <title>Divemotor - Activación Póliza</title>
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
				<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
				  <tr>
					<td>
					  <div class="to100" style="display:inline-block;width: 350px">
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Estimados,</p>
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Por favor su apoyo con la colocación de seguro.</p>
						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> '|| v_tipo_credito ||' </p>
						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud :'||LTRIM(p_cod_soli_cred,'0')||'</p>
                        <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de operación :'||v_cod_operacion||'</p>
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Se adjunta factura de venta.</p>
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Se adjunta trama.</p>
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">'||v_nom_cia_seg||'</p>
					  </div>
					</td>
				  </tr>
				</table>
			  </body>
	</html>';

      PKG_SWEB_CRED_SOLI_EVENTO.sp_inse_correo(NULL,--p_num_ficha_vta_veh,
                     v_correos,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'SC',
                     p_ret_correo,
                     p_ret_esta,
                     p_ret_mens);


    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || ' sp_gen_plantilla_correo_aprob';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plantilla_correo_aprob',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);

  END;

   PROCEDURE sp_gen_plantilla_rech_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_obs_rechazo_input IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_txt_correo        VARCHAR2(2000);
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;   
    --v_tipo_credito      VARCHAR2(50):= '';
   -- v_cod_operacion     VARCHAR2(12);
    --v_cod_cia_seg       VARCHAR2(8);
    --v_nom_cia_seg       VARCHAR2(100);
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;


    -- Obtenemos los correos a Notificar
	  v_query := 'select VVE_CRED_SOLI_PARA.VAL_PARA_CAR from VVE_CRED_SOLI_PARA  where cod_cred_soli_para = ''NOTISEGU''';


    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plantilla_rech_tasa',
                                        NULL,
                                        'error al enviar correo',
                                        v_query,
                                        v_query);


    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;

    v_correos := '';
    v_contador := 1;

    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_txt_correo;
      EXIT WHEN c_usuarios%NOTFOUND;

    dbms_output.put_line('3.1');

      IF (v_contador = 1) THEN
        v_correos := v_correos||v_txt_correo;
      ELSE
        v_correos := v_correos||','||v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    END LOOP;
    CLOSE c_usuarios;



    v_asunto := 'RECHAZO TASA MENOR - Nro. Solicitud.: ' ||LTRIM(p_cod_soli_cred,'0');


      v_mensaje := '<!DOCTYPE html>
    <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
		<head>
                <title>Divemotor - Rechazo tasa menor</title>
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
				<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
				  <tr>
					<td>
					  <div class="to100" style="display:inline-block;width: 350px">

						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Se RECHAZÓ tasa menor de la solicitud Nro.:'||LTRIM(p_cod_soli_cred,'0')||'</p>
                        <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">OBS :'||p_obs_rechazo_input||'</p>
					  </div>
					</td>
				  </tr>
				</table>
			  </body>
	</html>';

      PKG_SWEB_CRED_SOLI_EVENTO.sp_inse_correo(NULL,--p_num_ficha_vta_veh,
                     v_correos,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'SC',
                     p_ret_correo,
                     p_ret_esta,
                     p_ret_mens);


    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || ' sp_gen_plantilla_rech_tasa';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plantilla_rech_tasa',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);

  END;

   PROCEDURE sp_gen_plantilla_aprob_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_txt_correo        VARCHAR2(2000);
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;   
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;


    -- Obtenemos los correos a Notificar
	  v_query := 'select VVE_CRED_SOLI_PARA.VAL_PARA_CAR from VVE_CRED_SOLI_PARA  where cod_cred_soli_para = ''NOTISEGU''';


    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plantilla_aprob_tasa',
                                        NULL,
                                        'error al enviar correo',
                                        v_query,
                                        v_query);


    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;

    v_correos := '';
    v_contador := 1;


    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_txt_correo;
      EXIT WHEN c_usuarios%NOTFOUND;

    dbms_output.put_line('3.1');

      IF (v_contador = 1) THEN
        v_correos := v_correos||v_txt_correo;
      ELSE
        v_correos := v_correos||','||v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    END LOOP;
    CLOSE c_usuarios;



    v_asunto := 'APROBACIÓN TASA MENOR - Nro. Solicitud.: ' ||LTRIM(p_cod_soli_cred,'0');


      v_mensaje := '<!DOCTYPE html>
    <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
		<head>
                <title>Divemotor - Rechazo tasa menor</title>
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
				<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
				  <tr>
					<td>
					  <div class="to100" style="display:inline-block;width: 350px">
						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Se APROBÓ tasa menor de la solicitud Nro.:'||LTRIM(p_cod_soli_cred,'0')||'</p>
					  </div>
					</td>
				  </tr>
				</table>
			  </body>
	</html>';

      PKG_SWEB_CRED_SOLI_EVENTO.sp_inse_correo(NULL,--p_num_ficha_vta_veh,
                     v_correos,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'SC',
                     p_ret_correo,
                     p_ret_esta,
                     p_ret_mens);


    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || ' sp_gen_plantilla_aprob_tasa';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plantilla_aprob_tasa',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);

  END;

  PROCEDURE SP_LIST_SOLI_CRED_SEGURO_TRAMA(
   p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  )  AS
  lv_cod_tip_uso_veh  VARCHAR2(5);
  BEGIN
    -- Obteniendo el tipo de uso
      SELECT cod_tip_uso_veh 
       INTO lv_cod_tip_uso_veh
      FROM vve_cred_simu 
      WHERE cod_soli_cred = p_cod_soli_cred
       AND  ind_inactivo = 'N'; --TUV02

    open p_ret_cursor for
        SELECT  csg.cod_gara,
               (CASE WHEN cs.cod_empr ='06' THEN 'DI'  WHEN cs.cod_empr ='09' THEN 'DC' ELSE '' END )contratante,
                gp.nom_comercial,
                gdp.dir_domicilio,
                gp.num_ruc,
                gp.num_telf_movil,
                cmg.txt_ruta_veh,
                cavs.des_agru_veh_seg clase,
                tv.des_tipo_veh tipo_vehiculo, 
                tm.descripcion  uso,
                cmg.txt_marca marca,
                cmg.txt_modelo modelo,
                cmg.val_ano_fab,
                cmg.nro_placa,
                cmg.nro_motor,
                cmg.nro_chasis,
                cmg.can_nro_asie,
                cs.val_prim_seg,
                cs.fec_inic_vige_poli ,
                cs.fec_fin_vige_poli,
                cs.cod_oper_rel,
                cs.val_tasa_segu,
                cs.cod_cia_seg --<Req. 87567 E2.1 ID## avilca 30/12/2020>
        FROM vve_cred_soli_gara csg
             INNER JOIN vve_cred_soli cs ON csg.cod_soli_cred = cs.cod_soli_cred
             INNER JOIN vve_tabla_maes tm ON cs.cod_tip_uso_veh = tm.cod_tipo AND tm.cod_grupo = '97' 
             INNER JOIN vve_cred_maes_gara cmg ON csg.cod_gara = cmg.cod_garantia
             INNER JOIN vve_tipo_veh tv ON cmg.cod_tipo_veh = tv.cod_tipo_veh
             INNER JOIN vve_cred_tipo_veh_agru ctva ON ctva.cod_tipo_veh = cmg.cod_tipo_veh and (ctva.cod_tip_uso = lv_cod_tip_uso_veh OR ctva.cod_tip_uso IS NULL)
             INNER JOIN vve_cred_agru_veh_seg cavs ON ctva.cod_tipo_veh_agru = cavs.cod_agru_veh_seg
             INNER JOIN gen_persona gp ON cs.cod_clie = gp.cod_perso
             INNER JOIN gen_dir_perso gdp ON gp.cod_perso = gdp.cod_perso
        WHERE cs.cod_soli_cred= p_cod_soli_cred
          AND csg.ind_gara_adic = 'N'
        ORDER BY cod_gara desc;
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_LIST_SOLI_CRED_SEGURO_TRAMA';

  END ;

  PROCEDURE SP_LIST_SOLI_CRED_VENC_SEGURO
  (
    p_fec_vencimiento   IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  )
  AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cs.cod_soli_cred, TO_CHAR(cs.fec_firm_cont,'DD/MM/YYYY') as fec_firm_cont, ma.descripcion AS tipo_credito, cs.cod_oper_rel, cs.nro_poli_seg, cs.fec_fin_vige_poli, pe.cod_perso, pe.nom_comercial
      FROM venta.vve_cred_soli cs
        INNER JOIN generico.gen_persona pe ON cs.cod_cia_seg = pe.cod_perso
        INNER JOIN venta.vve_tabla_maes ma ON cs.tip_soli_cred = ma.cod_tipo
      WHERE cs.tip_soli_cred = 'TC01'
        --AND cs.cod_estado = 'ES05'
        AND TO_CHAR(cs.fec_fin_vige_poli, 'DD/MM/YYYY') = p_fec_vencimiento;
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_LIST_SOLI_CRED_SEGURO_TRAMA';
  END;
END PKG_SWEB_CRED_SOLI_SEGURO;