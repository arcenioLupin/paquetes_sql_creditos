create or replace PACKAGE BODY       VENTA.PKG_SWEB_CRED_SOLI_SEGURO AS

  PROCEDURE SP_LIST_SOLI_CRED_SEGURO(
   p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  )  AS
  BEGIN
    open p_ret_cursor for
    SELECT IND_TIPO_SEGU,NRO_POLI_SEG,FEC_INIC_VIGE_POLI,FEC_FIN_VIGE_POLI,VAL_PORC_TEA_SIGV,FEC_PRIM_PAGO_POLI_ENDO,
       FEC_ULTI_PAGO_POLI_ENDO,TXT_RUTA_POLI_ENDO
    FROM VVE_CRED_SOLI
    WHERE COD_SOLI_CRED=p_cod_soli_cred;
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
        (select des_tipo_actividad from vve_credito_tipo_actividad where cod_tipo_actividad=g.cod_tipo_actividad) as des_tipo_actividad, 
        p.num_placa_veh, p.num_motor_veh, p.num_chasis, g.can_nro_asie, p.num_pedido_veh
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
        COD_USUA_GEST_SEG=p_cod_usua_gest_seg
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
    P_FEC_INIC_VIGE_POLI IN vve_cred_soli.FEC_INIC_VIGE_POLI%TYPE,
    P_FEC_FIN_VIGE_POLI IN vve_cred_soli.FEC_FIN_VIGE_POLI%TYPE,
    P_FEC_PRIM_PAGO_POLI_ENDO IN vve_cred_soli.FEC_PRIM_PAGO_POLI_ENDO%TYPE,
    P_FEC_ULTI_PAGO_POLI_ENDO IN vve_cred_soli.FEC_ULTI_PAGO_POLI_ENDO%TYPE,
    P_TXT_RUTA_POLI_ENDO IN vve_cred_soli.TXT_RUTA_POLI_ENDO%TYPE,
    P_COD_USUA_MODI IN vve_cred_soli.COD_USUA_MODI%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS
  BEGIN
    UPDATE VVE_CRED_SOLI
    SET NRO_POLI_SEG=P_NRO_POLI_SEG,
        FEC_INIC_VIGE_POLI=P_FEC_INIC_VIGE_POLI,
        FEC_FIN_VIGE_POLI=P_FEC_FIN_VIGE_POLI,
        FEC_PRIM_PAGO_POLI_ENDO=P_FEC_PRIM_PAGO_POLI_ENDO,
        FEC_ULTI_PAGO_POLI_ENDO=P_FEC_ULTI_PAGO_POLI_ENDO,
        TXT_RUTA_POLI_ENDO=P_TXT_RUTA_POLI_ENDO,
        COD_USUA_GEST_SEG=P_COD_USUA_MODI
    WHERE COD_SOLI_CRED=P_COD_SOLI_CRED;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'ERROR SP_ACTU_DATOS_SOLI_SEG';
  END;

  PROCEDURE SP_ACTU_PLACA_SOLI_SEG(
    P_COD_SOLI_CRED IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    P_NUM_PEDIDO_VEH IN VVE_PEDIDO_VEH.NUM_PEDIDO_VEH %TYPE,
    P_NUM_PLACA_VEH IN VVE_PEDIDO_VEH.NUM_PLACA_VEH %TYPE,
    P_CO_USUARIO_MOD_REG IN VVE_PEDIDO_VEH.CO_USUARIO_MOD_REG%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )  AS
  BEGIN
    UPDATE VVE_PEDIDO_VEH
    SET NUM_PLACA_VEH=P_NUM_PLACA_VEH,
    CO_USUARIO_MOD_REG=P_CO_USUARIO_MOD_REG
    WHERE NUM_PEDIDO_VEH=P_NUM_PEDIDO_VEH;
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
    P_FEC_INIC_VIGE_POLI IN vve_cred_soli.FEC_INIC_VIGE_POLI%TYPE,
    P_FEC_FIN_VIGE_POLI IN vve_cred_soli.FEC_FIN_VIGE_POLI%TYPE,
    P_IND_TIPO_SEGU in vve_cred_soli.IND_TIPO_SEGU%TYPE,
    P_COD_CIA_SEG in vve_cred_soli.COD_CIA_SEG%TYPE,
    P_COD_AREA_VTA in vve_cred_soli.COD_AREA_VTA%TYPE,
    P_COD_ESTA_POLI in vve_cred_soli.COD_ESTA_POLI%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )  AS
  BEGIN
    open p_ret_cursor for
    SELECT (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='90' AND COD_TIPO=IND_TIPO_SEGU) as tipoSeguro,
    NRO_POLI_SEG,FEC_INIC_VIGE_POLI,FEC_FIN_VIGE_POLI,COD_SOLI_CRED,(select nom_perso from gen_persona where  cod_perso = P_COD_CIA_SEG ) as companiaSeguro,
    (select des_area_vta from gen_area_vta where cod_area_vta = P_COD_AREA_VTA) as areaVenta
    FROM VVE_CRED_SOLI 
    WHERE (P_COD_SOLI_CRED IS NULL OR COD_SOLI_CRED like '%'||P_COD_SOLI_CRED||'%')
    AND (P_NRO_POLI_SEG IS NULL OR NRO_POLI_SEG like '%'||P_NRO_POLI_SEG||'%') 
    AND (P_IND_TIPO_SEGU IS NULL OR IND_TIPO_SEGU = P_IND_TIPO_SEGU)
    AND (P_FEC_INIC_VIGE_POLI IS NULL OR FEC_INIC_VIGE_POLI>=TO_DATE(P_FEC_INIC_VIGE_POLI, 'DD/MM/YYYY')) 
    AND (P_FEC_FIN_VIGE_POLI IS NULL OR FEC_FIN_VIGE_POLI<=TO_DATE(P_FEC_FIN_VIGE_POLI, 'DD/MM/YYYY'));
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
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

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

/*    OPEN c_documentos FOR v_query_docu;
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
    

    
    v_asunto := 'Activación Póliza.: ' ||p_cod_soli_cred;


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
						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Tipo de Crédito </p>
						<p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud :'||p_cod_soli_cred||'</p>
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Se adjunta trama.</p>
						<p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Nombre de la aseguradora</p>
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

END PKG_SWEB_CRED_SOLI_SEGURO; 