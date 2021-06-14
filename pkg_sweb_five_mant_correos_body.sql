create or replace PACKAGE BODY VENTA.pkg_sweb_five_mant_correos IS

  -- Author  : LAQS
  -- Created : 31/01/2018 09:18:12 a.m.
  -- Purpose : procedimientos para envio de correos

  PROCEDURE sp_gen_plantilla_correo_hfdv
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_ambiente          VARCHAR2(100);
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_cliente           VARCHAR(500);
    v_documento         VARCHAR(20);
    v_cod_cli           VARCHAR(20);
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_instancia         VARCHAR(20);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
    v_contador          INTEGER;
    l_correos           vve_correo_prof.destinatarios%TYPE;
  
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ')                   
                  
                  ';
    END IF;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GEN_PLANTILLA_CORREO_HFDV',
                                        NULL,
                                        'Error',
                                        v_query,
                                        p_num_ficha_vta_veh);
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    v_contador := 1;
    l_correos  := '';
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
      IF (v_contador = 1) THEN
        l_correos := l_correos || v_txt_correo;
      ELSE
        l_correos := l_correos || ', ' || v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    
    END LOOP;
    CLOSE c_usuarios;
  
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    v_asunto := p_asunto_input;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola 
                 
                   </span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                 rtrim(v_cliente) ||
                 '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"><a href="' ||
                 url_ficha_venta || 'fichas-venta/' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '" style="color:#0076ff">' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '</a></p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                   
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_filial) ||
                 '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_area_venta) ||
                 '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_cia) ||
                 '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_vendedor) ||
                 '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>
                          
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(p_cuerpo_input) ||
                 '.</p>
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
                            
                        <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_contactos) ||
                 '.</p>
                                </td>                                                            
                              </tr>                             
                              
                        </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                 v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
    sp_inse_correo(p_num_ficha_vta_veh,
                   l_correos,
                   '',
                   v_asunto,
                   v_mensaje,
                   '',
                   p_id_usuario,
                   p_id_usuario,
                   'HF',
                   p_ret_esta,
                   p_ret_mens);
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_HFDV';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_HFDV',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_adjunt
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_ambiente          VARCHAR2(100);
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_cliente           VARCHAR(500);
    v_documento         VARCHAR(20);
    v_cod_cli           VARCHAR(20);
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_instancia         VARCHAR(20);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
    v_contador          INTEGER;
    l_correos           vve_correo_prof.destinatarios%TYPE;
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ')   ';
    END IF;
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    v_contador := 1;
    l_correos  := '';
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
      IF (v_contador = 1) THEN
        l_correos := l_correos || v_txt_correo;
      ELSE
        l_correos := l_correos || ',' || v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    
    END LOOP;
    CLOSE c_usuarios;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Archivos adjuntos .: ' ||
                rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Adjuntos</h1>                            <p style="margin: 0;"><span style="font-weight: bold;"> </span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                 rtrim(v_cliente) ||
                 '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                 url_ficha_venta || 'fichas-venta/' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '" style="color:#0076ff">
                                          ' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                             <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_filial) ||
                 '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_area_venta) ||
                 '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_cia) ||
                 '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_vendedor) ||
                 '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>
                   
                          
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(p_cuerpo_input) ||
                 '.</p>
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
                            
                        <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_contactos) ||
                 '.</p>
                                </td>                                                            
                              </tr>                             
                              
                        </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                 v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
  
    sp_inse_correo(p_num_ficha_vta_veh,
                   l_correos,
                   '',
                   v_asunto,
                   v_mensaje,
                   '',
                   p_id_usuario,
                   p_id_usuario,
                   'AJ',
                   p_ret_esta,
                   p_ret_mens);
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_ADJUNT';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_ADJUNT',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_aequip
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_ambiente          VARCHAR2(100);
    v_query             VARCHAR2(20000);
    c_usuarios          SYS_REFCURSOR;
    v_cliente           VARCHAR(500);
    v_documento         VARCHAR(20);
    v_cod_cli           VARCHAR(20);
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_instancia         VARCHAR(20);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ')';
    END IF;
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
    END LOOP;
    CLOSE c_usuarios;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Equipo adicionales.: ' ||
                rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Solicitud de Equipo Adicional</h1>                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_txt_nombres) ||
                   '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                   rtrim(v_cliente) ||
                   '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                   url_ficha_venta || 'fichas-venta/' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') ||
                   '" style="color:#0076ff">
                                          ' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                    </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                             <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_filial) ||
                   '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_area_venta) ||
                   '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_cia) ||
                   '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_vendedor) ||
                   '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>
                   
                          
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Detalle del Pedido</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(p_cuerpo_input) ||
                   '.</p>
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
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_contactos) ||
                   '.</p>
                                </td>                                                            
                              </tr>                             
                              
                          </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                   v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
    
      sp_inse_correo(p_num_ficha_vta_veh,
                     v_txt_correo,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'EA',
                     p_ret_esta,
                     p_ret_mens);
    
    END LOOP;
    CLOSE c_usuarios;
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_AEQUIP';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_AEQUIP',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  /*--------------------------------------------------------------------------
      Nombre : SP_GEN_PLANTILLA_CORREO_SFACTU
      Proposito : Genera la estructura del correo para los destinatarios.
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor             Descripcion
      17/08/2018   SOPORTELEGADOS    REQ - 86434 Modificacion del amrmado de la estructura para
                   añardir el bloque de Cliente Facturacion, Cliente Propietario y Cliente Usuario.
                   Se creó la variable de entrada p_nombre_entidad. La modificación empieza en la línea
                   1518 hasta 1543.
  
  ----------------------------------------------------------------------------*/

  PROCEDURE sp_gen_plantilla_correo_sfactu
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE DEFAULT NULL,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE DEFAULT NULL,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE DEFAULT NULL
  ) AS
    ve_error EXCEPTION;
    v_asunto  VARCHAR2(2000);
    v_mensaje CLOB;
    -- v_html_head         VARCHAR2(2000);
    v_correoori usuarios.di_correo%TYPE;
    v_ambiente  VARCHAR2(100);
    v_query     VARCHAR2(4000);
    c_usuarios  SYS_REFCURSOR;
    v_cliente   VARCHAR(500);
    v_documento VARCHAR(20);
    v_cod_cli   VARCHAR(20);
    --<REQ-86434>
    v_cod_clie_ped    gen_persona.cod_perso%TYPE;
    v_nom_clie_ped    VARCHAR(500);
    v_cod_propietario VARCHAR(20);
    v_nom_propietario VARCHAR(500);
    v_cod_usuario     VARCHAR(20);
    v_nom_usuario     VARCHAR(500);
    --<REQ-86434>
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
    v_instancia         VARCHAR(20);
    v_contador          INTEGER;
    l_correos           vve_correo_prof.destinatarios%TYPE;
    L_TXT_VALO          VARCHAR2(50) := NULL;
  BEGIN
    SELECT NAME INTO v_instancia FROM v$database;
    L_TXT_VALO := PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó');-- REQ.89449
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producci'||L_TXT_VALO||'n';      
    END IF;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ') AND TXT_CORREO IS NOT NULL';
    END IF;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_QUERY_CORREO',
                                        '',
                                        'OK',
                                        v_query,
                                        p_num_ficha_vta_veh);
  
    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
    END LOOP;
    CLOSE c_usuarios;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    --<REQ-86434>
    /*
     v_cod_clie_ped      VARCHAR(20);
    v_nom_clie_ped      VARCHAR(20);
     */
    BEGIN
      SELECT cod_propietario_veh, cod_usuario_veh, cod_clie
        INTO v_cod_propietario, v_cod_usuario, v_cod_clie_ped
        FROM vve_pedido_veh
       WHERE num_pedido_veh IN
             (SELECT num_pedido_veh
                FROM vve_ficha_vta_pedido_veh
               WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
                 AND cod_cia = p_cod_cia
                 AND cod_prov = p_cod_prov
                 AND num_pedido_veh = p_num_pedido_veh);
    EXCEPTION
      WHEN no_data_found THEN
        v_cod_propietario := NULL;
        v_cod_usuario     := NULL;
    END;
  
    BEGIN
      SELECT nom_perso
        INTO v_nom_propietario
        FROM gen_persona g
       WHERE cod_perso = v_cod_propietario;
    EXCEPTION
      WHEN no_data_found THEN
        v_nom_propietario := NULL;
    END;
  
    BEGIN
      SELECT nom_perso
        INTO v_nom_usuario
        FROM gen_persona g
       WHERE cod_perso = v_cod_usuario;
    EXCEPTION
      WHEN no_data_found THEN
        v_nom_usuario := NULL;
    END;
  
    BEGIN
      SELECT nom_perso
        INTO v_nom_clie_ped
        FROM gen_persona g
       WHERE cod_perso = v_cod_clie_ped;
    EXCEPTION
      WHEN no_data_found THEN
        v_nom_clie_ped := NULL;
    END;
    --<REQ-86434>
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
    v_asunto := 'SOLICITUD DE FACTURACIÓN. FV N°' ||
                lpad(p_num_ficha_vta_veh, 12, '0') || ' N° Pedido ' ||
                rtrim(p_num_pedido_veh);
  
    v_contador := 1;
    l_correos  := '';
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
      IF (v_contador = 1) THEN
        l_correos := l_correos || v_txt_correo;
      ELSE
        l_correos := l_correos || ', ' || v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    
    END LOOP;
    CLOSE c_usuarios;
  
    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">M'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'dulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Solicitud de Facturaci'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'n</h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                 rtrim(v_txt_nombres) ||
                 '</span>, se ha generado una notificaci'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'n dentro del m'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'dulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                 rtrim(v_cliente) ||
                 '</span></p>
                                  </div>

                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> N'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('°')/*F - REQ.89449*/||' de Ficha Venta</p>
                                       <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                 url_ficha_venta || 'fichas-venta/' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '" style="color:#0076ff">
                                          ' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  </div>
                                </td>
                              </tr>
                            </table>


                             <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_filial) ||
                 '.</p>
                                </td>

                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('Á')/*F - REQ.89449*/||'rea de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_area_venta) ||
                 '.</p>
                                </td>

                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compa'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ñ')||PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('í')/*F - REQ.89449*/||'a</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_cia) ||
                 '.</p>
                                </td>

                              </tr>

                            </table>

                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_vendedor) ||
                 '.</p>
                                </td>
                                  <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">N'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('°')/*F - REQ.89449*/||' Pedido</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(p_num_pedido_veh) ||
                 '.</p>
                                </td>
                              </tr>
                           </table>

                           <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                            <tr>
                             <td style="padding: 0;">
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 14px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Cliente Facturaci'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'n</span></p>
                              <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(v_nom_clie_ped) ||
                 '.</p>
                             </td>
                            </tr>
                            <tr>
                             <td style="padding: 0;">
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 14px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Cliente Propietario</span></p>
                              <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(v_nom_propietario) ||
                 '.</p>
                             </td>
                            </tr>
                            <tr>
                             <td style="padding: 0;">
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 14px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Cliente Usuario</span></p>
                              <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(v_nom_usuario) ||
                 '.</p>
                             </td>
                            </tr>
                           </table>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Detalle</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(p_cuerpo_input) ||
                 '.</p>
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

                        <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_contactos) ||
                 '.</p>
                                </td>
                              </tr>

                        </table>

                            <p style="margin: 0; padding-top: 25px;" >La informaci'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'n contenida en este correo electr'||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ó')/*F - REQ.89449*/||'nico es confidencial. Esta dirigida '||/*I - REQ.89449*/PKG_SWEB_FIVE_MANT_CORREOS.FUN_LIST_CARAC_CORR('ú')/*F - REQ.89449*/||'nicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                 v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'SP_GEN_PLANTILLA_CORREO_SFACTU',
                                        NULL,
                                        'Log',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
  
    sp_inse_correo(p_num_ficha_vta_veh,
                   l_correos,
                   '',
                   v_asunto,
                   v_mensaje,
                   '',
                   p_id_usuario,
                   p_id_usuario,
                   'SF',
                   p_ret_esta,
                   p_ret_mens);
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || 'SP_GEN_PLANTILLA_CORREO_SFACTU';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_SFACTU',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_nlafit
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_correoori         usuarios.di_correo%TYPE;
    v_ambiente          VARCHAR2(100);
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_cliente           VARCHAR(500);
    v_documento         VARCHAR(20);
    v_cod_cli           VARCHAR(20);
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    v_txt_nombrecliente VARCHAR(500);
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
    v_instancia         VARCHAR(20);
    v_destinatarios     vve_correo_prof.destinatarios%TYPE;
  BEGIN
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Obtenemos los correos a Notificar
    v_query := '  SELECT DISTINCT 
                 a.cod_id_usuario,
                 a.txt_correo ,
                 a.txt_usuario,
                 a.txt_nombres,
                 a.txt_apellidos
        FROM sistemas.sis_mae_usuario a
       INNER JOIN sistemas.sis_mae_perfil_usuario b
          ON a.cod_id_usuario = b.cod_id_usuario
         AND b.ind_inactivo = ''N''
       INNER JOIN sistemas.sis_mae_perfil_procesos c
          ON b.cod_id_perfil = c.cod_id_perfil
         AND c.ind_inactivo = ''N''
       WHERE c.cod_id_procesos = 66
         AND txt_correo IS NOT NULL
         union
         SELECT DISTINCT 
                 x.cod_id_usuario,
                 x.txt_correo ,
                 x.txt_usuario,
                 x.txt_nombres,
                 x.txt_apellidos
        FROM sistemas.sis_mae_usuario x
        where x.cod_id_usuario=' || p_id_usuario;
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
    v_destinatarios := '';
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos     := v_txt_usuario || ' ' || v_txt_apellidos ||
                         '<br />' || v_contactos;
      v_destinatarios := v_destinatarios || v_txt_correo || ',';
      dbms_output.put_line(v_destinatarios);
    END LOOP;
    CLOSE c_usuarios;
    v_destinatarios := substr(v_destinatarios,
                              1,
                              length(v_destinatarios) - 1);
    dbms_output.put_line(v_destinatarios);
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Pedido de Informe Lavado de Activo  : Ficha ' ||
                lpad(p_num_ficha_vta_veh, 12, '0');
  
    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Notificacion LAFIT</h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola </span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                 rtrim(v_cliente) ||
                 '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                       <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                 url_ficha_venta || 'fichas-venta/' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '" style="color:#0076ff">
                                          ' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                                    
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_filial) ||
                 '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_area_venta) ||
                 '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_cia) ||
                 '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_vendedor) ||
                 '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>
                   
                          
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(p_cuerpo_input) ||
                 '.</p>
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
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_contactos) ||
                 '.</p>
                                </td>                                                            
                              </tr>                             
                              
                        </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                 v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
  
    sp_inse_correo(p_num_ficha_vta_veh,
                   v_destinatarios,
                   '',
                   v_asunto,
                   v_mensaje,
                   '',
                   p_id_usuario,
                   p_id_usuario,
                   'NL',
                   p_ret_esta,
                   p_ret_mens);
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_NLAFIT';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_NLAFIT',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_cestad
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto         VARCHAR2(2000);
    v_mensaje        CLOB;
    v_html_head      VARCHAR2(2000);
    v_correoori      usuarios.di_correo%TYPE;
    v_ambiente       VARCHAR2(100);
    v_query          VARCHAR2(4000);
    c_usuarios       SYS_REFCURSOR;
    v_cliente        VARCHAR(500);
    v_documento      VARCHAR(20);
    v_cod_cli        VARCHAR(20);
    v_usuario_ap_nom VARCHAR(50);
    v_dato_usuario   VARCHAR(50);
  
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
  
    v_cod_id_usuario sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo     sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario    sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres    sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos  sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string        VARCHAR(10);
    url_ficha_venta  VARCHAR(150);
    v_instancia      VARCHAR(20);
    v_cod_estado_ficha_vta_veh VARCHAR(2);
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
    
    --Obteniendo el estado de la ficha de venta
    BEGIN
        SELECT cod_estado_ficha_vta_veh 
         INTO v_cod_estado_ficha_vta_veh
        FROM vve_ficha_vta_veh  
        WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cod_estado_ficha_vta_veh:=NULL;
    END;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL AND p_destinatarios <> '' THEN --<I Req. 87567 E2.1 ID## avilca 19/01/2021>
          
              v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                           FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                         p_destinatarios || ') ';
                         
                         
                     pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                            'SP_GEN_PLANTILLA_CORREO_CESTAD',
                                                            NULL,
                                                            'Error',
                                                            v_query,
                                                            p_num_ficha_vta_veh);
                      
                        -- Obtener url de ambiente 
                        SELECT upper(instance_name) INTO wc_string FROM v$instance;
                        SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                                           '000000064',
                                                                           'SERV_WEB_LINK_' ||
                                                                           wc_string)
                          INTO url_ficha_venta
                          FROM dual;
                      
                        --Obtenemos el correo origen
                        BEGIN
                          SELECT txt_correo
                            INTO v_correoori
                            FROM sistemas.sis_mae_usuario
                           WHERE cod_id_usuario = p_id_usuario;
                        EXCEPTION
                          WHEN OTHERS THEN
                            v_correoori := 'apps@divemotor.com.pe';
                        END;
                      
                        -- Obtener datos de la ficha
                        SELECT cod_clie,
                               pkg_gen_select.func_sel_gen_filial(cod_filial),
                               pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
                               pkg_log_select.func_sel_tapcia(cod_cia),
                               pkg_cxc_select.func_sel_arccve(vendedor),
                               to_date(fec_ficha_vta_veh, 'DD/MM/YY')
                          INTO v_cod_cli,
                               v_desc_filial,
                               v_desc_area_venta,
                               v_desc_cia,
                               v_desc_vendedor,
                               v_fec_ficha_vta_veh
                          FROM vve_ficha_vta_veh
                         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
                      
                        SELECT nvl(num_docu_iden, num_ruc)
                          INTO v_documento
                          FROM gen_persona g
                         WHERE cod_perso = v_cod_cli; --COD_CLIE
                      
                        SELECT nom_perso
                          INTO v_cliente
                          FROM gen_persona g
                         WHERE cod_perso = v_cod_cli; --COD_CLIE
                      
                        -- Obtener datos de usuario quien realizo la accion
                        SELECT (txt_apellidos || ', ' || txt_nombres)
                          INTO v_dato_usuario
                          FROM sistemas.sis_mae_usuario
                         WHERE cod_id_usuario = p_id_usuario;
                      
                        --Asunto del mensaje Historial de ficha de venta Agregar comentario
                      
                        v_asunto := 'Cambio de estado .: ' ||
                                    rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
                      
                        --Contactos
                      
                        OPEN c_usuarios FOR v_query;
                        LOOP
                          FETCH c_usuarios
                            INTO v_cod_id_usuario,
                                 v_txt_correo,
                                 v_txt_usuario,
                                 v_txt_nombres,
                                 v_txt_apellidos;
                          EXIT WHEN c_usuarios%NOTFOUND;
                        
                          v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                                         v_contactos;
                        
                        END LOOP;
                        CLOSE c_usuarios;
                      
                        --Envio de correo
                        OPEN c_usuarios FOR v_query;
                        LOOP
                          FETCH c_usuarios
                            INTO v_cod_id_usuario,
                                 v_txt_correo,
                                 v_txt_usuario,
                                 v_txt_nombres,
                                 v_txt_apellidos;
                          EXIT WHEN c_usuarios%NOTFOUND;
                        
                          v_mensaje := '<!DOCTYPE html>
                              <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
                                  <head>
                                    <title>Divemotor - Entrega de Vehículo</title>
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
                                                    <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                                                  </tr>
                                                </table>
                                              </td>
                                            </tr>
                                          </table>
                    
                                          <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                                            <tr>
                                              <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                                                <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                                                <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Cambio de Estado</h1>
                                                <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                                       rtrim(v_txt_nombres) ||
                                       '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>
                    
                                                <div style="padding: 10px 0;">
                                            
                                                </div>
                    
                                                <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                                                  <tr>
                                                    <td>
                                                      <div class="to100" style="display:inline-block;width: 265px">
                                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                                       rtrim(v_cliente) ||
                                       '</span></p>
                                                      </div>
                                                        
                                                      <div class="to100" style="display:inline-block;width: 110px">
                                                        <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                                           <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                                            <a href="' ||
                                       url_ficha_venta || 'fichas-venta/' ||
                                       lpad(p_num_ficha_vta_veh, 12, '0') ||
                                       '" style="color:#0076ff">
                                                              ' ||
                                       lpad(p_num_ficha_vta_veh, 12, '0') || '
                                                            </a>
                                                          </p>
                                                      </div>
                                                    </td>
                                                  </tr>
                                                </table>
                                                
                                              <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                                                  <tr>
                                                    <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(v_desc_filial) ||
                                       '.</p>
                                                    </td>
                                                    
                                                    <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(v_desc_area_venta) ||
                                       '.</p>
                                                    </td> 
                                                    
                                                     <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(v_desc_cia) ||
                                       '.</p>
                                                    </td>  
                                                                                   
                                                  </tr>                     
                                                  
                                                </table>
                                                
                                              <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                                                  <tr>
                                                    <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(v_desc_vendedor) ||
                                       '.</p>
                                                    </td>                                                            
                                                  </tr>   
                                                                            
                                                  
                                               </table>
                    
                                                <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                                                  <tr>
                                                    <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(p_cuerpo_input) ||
                                       '.</p>
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
                                                
                                           <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                                                  <tr>
                                                    <td style="padding: 0;">
                                                      <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                                      <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                                       rtrim(v_contactos) ||
                                       '.</p>
                                                    </td>                                                            
                                                  </tr>                             
                                                  
                                            </table>
                                           
                                                <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                                              </td>
                                            </tr>
                                          </table>
                                          <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                                            <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                                       v_instancia || '</p>
                                          </div>
                                        </td>
                                      </tr>
                                    </table>
                                  </body>
                              </html>';
                        
                          sp_inse_correo(p_num_ficha_vta_veh,
                                         v_txt_correo,
                                         '',
                                         v_asunto,
                                         v_mensaje,
                                         '',
                                         p_id_usuario,
                                         p_id_usuario,
                                         'SE',
                                         p_ret_esta,
                                         p_ret_mens);
                        
                        END LOOP;
                        CLOSE c_usuarios;
                        
                        
                      
                        p_ret_esta := 1;
                        p_ret_mens := 'Se ejecuto correctamente';
    
     ELSE
           p_ret_esta := 1;
          p_ret_mens := 'Se ejecuto correctamente';
                               
    END IF;
   
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_CESTAD';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_CESTAD',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_bonos
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto         VARCHAR2(2000);
    v_mensaje        CLOB;
    v_html_head      VARCHAR2(2000);
    v_correoori      usuarios.di_correo%TYPE;
    v_ambiente       VARCHAR2(100);
    v_query          VARCHAR2(4000);
    c_usuarios       SYS_REFCURSOR;
    v_cliente        VARCHAR(500);
    v_documento      VARCHAR(20);
    v_cod_cli        VARCHAR(20);
    v_usuario_ap_nom VARCHAR(50);
    v_dato_usuario   VARCHAR(50);
  
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
  
    v_cod_id_usuario sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo     sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario    sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres    sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos  sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string        VARCHAR(10);
    url_ficha_venta  VARCHAR(150);
    v_instancia      VARCHAR(20);
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ')                  
                ';
    END IF;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GEN_PLANTILLA_CORREO_CESTAD',
                                        NULL,
                                        'Error',
                                        v_query,
                                        p_num_ficha_vta_veh);
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Bonos .: ' || rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    --Contactos
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
    END LOOP;
    CLOSE c_usuarios;
  
    --Envio de correo
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">BONOS</h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_txt_nombres) ||
                   '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                   rtrim(v_cliente) ||
                   '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                   url_ficha_venta || 'fichas-venta/' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') ||
                   '" style="color:#0076ff">
                                          ' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_filial) ||
                   '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_area_venta) ||
                   '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_cia) ||
                   '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_vendedor) ||
                   '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(p_cuerpo_input) ||
                   '.</p>
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
                            
                       <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_contactos) ||
                   '.</p>
                                </td>                                                            
                              </tr>                             
                              
                        </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                   v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
    
      sp_inse_correo(p_num_ficha_vta_veh,
                     v_txt_correo,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'BO',
                     p_ret_esta,
                     p_ret_mens);
    
    END LOOP;
    CLOSE c_usuarios;
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_BONOS';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_BONOS',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_gen_plantilla_correo_cfich
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_ambiente          VARCHAR2(100);
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_cliente           VARCHAR(500);
    v_documento         VARCHAR(20);
    v_cod_cli           VARCHAR(20);
    v_usuario_ap_nom    VARCHAR(50);
    v_dato_usuario      VARCHAR(50);
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    url_ficha_venta     VARCHAR(150);
    v_instancia         VARCHAR(20);
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Actualizar Correos
    sp_actualizar_envio('',
                        'FP',
                        p_num_ficha_vta_veh,
                        p_id_usuario,
                        p_ret_esta,
                        p_ret_mens);
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ') 
               
                  ';
    END IF;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plantilla_correo_cfich',
                                        NULL,
                                        'error al enviar correo',
                                        v_query,
                                        v_query);
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
    END LOOP;
    CLOSE c_usuarios;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Asignación de profroma.: ' ||
                rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Creación de Ficha</h1>                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_txt_nombres) ||
                   '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                   rtrim(v_cliente) ||
                   '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                   url_ficha_venta || 'fichas-venta/' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') ||
                   '" style="color:#0076ff">
                                          ' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                    </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                             <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_filial) ||
                   '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_area_venta) ||
                   '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_cia) ||
                   '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_vendedor) ||
                   '.</p>
                                </td>                                                            
                              </tr>   
                              
                                      <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">N° proforma</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                  
                   p_categoria_input ||
                   '.</p>
                                </td>                                                            
                              </tr>                  
                              
                           </table>
                   
                          
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(p_cuerpo_input) ||
                   '.</p>
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
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_contactos) ||
                   '.</p>
                                </td>                                                            
                              </tr>                             
                              
                          </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                   v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
    
      sp_inse_correo(p_num_ficha_vta_veh,
                     v_txt_correo,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'FP',
                     p_ret_esta,
                     p_ret_mens);
    
    END LOOP;
    CLOSE c_usuarios;
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || 'sp_gen_plantilla_correo_cfich';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_AEQUIP',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;
  /*
    PROCEDURE sp_obtener_plantilla
    (
      p_cod_ref_proc  IN VARCHAR2,
      p_tipo_ref_proc IN VARCHAR2,
      p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
      p_ret_correos   OUT SYS_REFCURSOR,
      p_ret_esta      OUT NUMBER,
      p_ret_mens      OUT VARCHAR2
    ) AS
      ve_error EXCEPTION;
    BEGIN
    
      OPEN p_ret_correos FOR
        SELECT a.destinatarios, a.copia, a.asunto, a.cuerpo, a.correoorigen
          FROM vve_correo_prof a
         WHERE a.cod_ref_proc IN (SELECT CASE p_tipo_ref_proc
                                           WHEN 'AD' THEN
                                            p_cod_ref_proc
                                           WHEN 'AF' THEN
                                            p_cod_ref_proc
                                           ELSE
                                            ltrim(p_cod_ref_proc, '0')
                                         END AS fdv
                                    FROM dual)
           AND a.tipo_ref_proc = p_tipo_ref_proc -- SOLICITUD DE FACTURACION
           AND a.ind_enviado = 'N';
    
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTENER_PLANTILLA',
                                          NULL, --P_COD_USUA_SID,
                                          p_tipo_ref_proc,
                                          p_ret_mens,
                                          p_cod_ref_proc);
    
      p_ret_esta := 1;
      p_ret_mens := 'Se ejecuto correctamente';
    EXCEPTION
      WHEN ve_error THEN
        p_ret_esta := 0;
      WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_OBTENER_PLANTILLA:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_OBTENER_PLANTILLA',
                                            NULL, --P_COD_USUA_SID,
                                            'Error',
                                            p_ret_mens,
                                            p_cod_ref_proc);
    END;
  */
  PROCEDURE sp_gen_plantilla_correo_aprbon
  (
    p_num_ficha_vta_veh IN vve_plan_entr_hist.cod_plan_entr_vehi%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_idevento_input    IN VARCHAR2,
    p_categoria_input   IN VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto         VARCHAR2(2000);
    v_mensaje        CLOB;
    v_html_head      VARCHAR2(2000);
    v_correoori      usuarios.di_correo%TYPE;
    v_ambiente       VARCHAR2(100);
    v_query          VARCHAR2(4000);
    c_usuarios       SYS_REFCURSOR;
    v_cliente        VARCHAR(500);
    v_documento      VARCHAR(20);
    v_cod_cli        VARCHAR(20);
    v_usuario_ap_nom VARCHAR(50);
    v_dato_usuario   VARCHAR(50);
  
    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
  
    v_cod_id_usuario sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo     sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario    sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres    sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos  sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string        VARCHAR(10);
    url_ficha_venta  VARCHAR(150);
    v_instancia      VARCHAR(20);
  BEGIN
  
    SELECT NAME INTO v_instancia FROM v$database;
  
    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;
  
    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ')                  
                ';
    END IF;
  
    -- Obtener url de ambiente 
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;
  
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
  
    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nvl(num_docu_iden, num_ruc)
      INTO v_documento
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    SELECT nom_perso
      INTO v_cliente
      FROM gen_persona g
     WHERE cod_perso = v_cod_cli; --COD_CLIE
  
    -- Obtener datos de usuario quien realizo la accion
  
    v_asunto := 'Bonos .: ' || rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
  
    --Asunto del mensaje Historial de ficha de venta Agregar comentario
  
    v_asunto := 'Bonos .: ' || rtrim(ltrim(to_char(p_num_ficha_vta_veh)));
  
    --Contactos
  
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_contactos := v_txt_usuario || ' ' || v_txt_apellidos || '<br />' ||
                     v_contactos;
    
    END LOOP;
    CLOSE c_usuarios;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GEN_PLANTILLA_CORREO_CESTAD',
                                        NULL,
                                        'ok1',
                                        v_query,
                                        p_num_ficha_vta_veh);
  
    --Envio de correo
    OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;
    
      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">BONOS</h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_txt_nombres) ||
                   '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">
                        
                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                   rtrim(v_cliente) ||
                   '</span></p>
                                  </div>
                                    
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                   url_ficha_venta || 'fichas-venta/' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') ||
                   '" style="color:#0076ff">
                                          ' ||
                   lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_filial) ||
                   '.</p>
                                </td>
                                
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_area_venta) ||
                   '.</p>
                                </td> 
                                
                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_cia) ||
                   '.</p>
                                </td>  
                                                               
                              </tr>                     
                              
                            </table>
                            
                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_desc_vendedor) ||
                   '.</p>
                                </td>                                                            
                              </tr>   
                                                        
                              
                           </table>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(p_cuerpo_input) ||
                   '.</p>
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
                            
                       <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_contactos) ||
                   '.</p>
                                </td>                                                            
                              </tr>                             
                              
                        </table>
                       
                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                   v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';
    
      sp_inse_correo(p_num_ficha_vta_veh,
                     v_txt_correo,
                     '',
                     v_asunto,
                     v_mensaje,
                     '',
                     p_id_usuario,
                     p_id_usuario,
                     'AV',
                     p_ret_esta,
                     p_ret_mens);
    
    END LOOP;
    CLOSE c_usuarios;
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_PLANTILLA_CORREO_APRBON';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_PLANTILLA_CORREO_APRBON',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    
  END;

  PROCEDURE sp_obtener_plantilla
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_tipo_ref_proc IN VARCHAR2,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos   OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    ve_query VARCHAR2(20000);
  BEGIN
  
    ve_query := 'SELECT a.cod_correo_prof,
             a.destinatarios,
             a.copia,
             a.asunto,
             a.cuerpo,
             a.correoorigen
        FROM vve_correo_prof a
       WHERE a.cod_ref_proc IN (SELECT CASE ''' ||
                p_tipo_ref_proc || '''
                                         WHEN ''DA'' THEN
                                          ''' ||
                p_cod_ref_proc || '''
                                         WHEN ''SE'' THEN
                                           ltrim(''' ||
                p_cod_ref_proc || ''', ''0'')
                                         ELSE
                                          ltrim(''' ||
                p_cod_ref_proc || ''', ''0'')
                                       END AS fdv
                                  FROM dual)
         AND a.tipo_ref_proc = ''' || p_tipo_ref_proc ||
                ''' -- SOLICITUD DE FACTURACION
         AND a.ind_enviado = ''N''';
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_OK',
                                        'SP_OBTENER_PLANTILLA_OK',
                                        NULL, --P_COD_USUA_SID,
                                        p_tipo_ref_proc,
                                        ve_query,
                                        p_cod_ref_proc);
    OPEN p_ret_correos FOR ve_query;
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_OBTENER_PLANTILLA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTENER_PLANTILLA',
                                          NULL, --P_COD_USUA_SID,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_ref_proc);
  END;
 
 --<I Req. 87567 E2.1 ID## avilca 15/01/2021> 
 PROCEDURE sp_obtener_plant_prof
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_tipo_ref_proc IN VARCHAR2,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos   OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    ve_query VARCHAR2(20000);
  BEGIN
  
    ve_query := 'SELECT a.cod_correo_prof,
             a.destinatarios,
             a.copia,
             a.asunto,
             a.cuerpo,
             a.correoorigen
        FROM vve_correo_prof a
       WHERE a.cod_ref_proc IN (SELECT CASE ''' ||
                p_tipo_ref_proc || '''
                                         WHEN ''PS'' THEN
                                          ''' ||
                p_cod_ref_proc || '''
                                         ELSE
                                          ltrim(''' ||
                p_cod_ref_proc || ''', ''0'')
                                       END AS fdv
                                  FROM dual)
         AND a.tipo_ref_proc = ''' || p_tipo_ref_proc ||
                ''' -- SOLICITUD DE FACTURACION
         AND a.ind_enviado = ''N''';
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_OK',
                                        'SP_OBTENER_PLANTILLA_OK',
                                        NULL, --P_COD_USUA_SID,
                                        p_tipo_ref_proc,
                                        ve_query,
                                        p_cod_ref_proc);
    OPEN p_ret_correos FOR ve_query;
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_OBTENER_PLANTILLA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTENER_PLANTILLA',
                                          NULL, --P_COD_USUA_SID,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_ref_proc);
  END;
--<F Req. 87567 E2.1 ID## avilca 15/01/2021>

  PROCEDURE sp_actualizar_envio
  (
    p_cod_correo_prof   IN VARCHAR2,
    p_tipo_ref_proc     IN VARCHAR2,
    p_num_ficha_vta_veh IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN
  
    IF p_tipo_ref_proc = 'DA' OR p_tipo_ref_proc = 'PS' THEN--<Req. 87567 E2.1 ID## AVILCA 15/01/2021>
    
      UPDATE vve_correo_prof a
         SET a.ind_enviado         = 'S',
             a.cod_id_usuario_modi = p_id_usuario,
             a.fec_modi_reg        = SYSDATE
       WHERE a.cod_ref_proc = p_num_ficha_vta_veh
         AND a.tipo_ref_proc = p_tipo_ref_proc
            --AND A.COD_CORREO_PROF = P_COD_CORREO_PROF
         AND a.ind_enviado = 'N';
    ELSE 
      UPDATE vve_correo_prof a
         SET a.ind_enviado         = 'S',
             a.cod_id_usuario_modi = p_id_usuario,
             a.fec_modi_reg        = SYSDATE
       WHERE a.cod_ref_proc IN
             (SELECT to_number(p_num_ficha_vta_veh) FROM dual)
         AND a.tipo_ref_proc = p_tipo_ref_proc
            --AND A.COD_CORREO_PROF = P_COD_CORREO_PROF
         AND a.ind_enviado = 'N';
    
    END IF;
    /*
            UPDATE vve_correo_prof a
           SET a.ind_enviado         = 'S',
               a.cod_id_usuario_modi = p_id_usuario,
               a.fec_modi_reg        = SYSDATE
    -     WHERE a.cod_ref_proc IN
               (SELECT to_number(p_num_ficha_vta_veh) FROM dual)
           AND a.tipo_ref_proc = p_tipo_ref_proc
              --AND A.COD_CORREO_PROF = P_COD_CORREO_PROF
           AND a.ind_enviado = 'N';
           */
    COMMIT;
  
    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_ENVIO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTUALIZAR_ENVIO',
                                          NULL, --P_COD_USUA_SID,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_CORREO
    Proposito : registra la plantilla de los correos
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    31/01/2018     LAQS      creacion de correos  
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_inse_correo
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_correo vve_correo_prof.cod_correo_prof%TYPE;
  BEGIN

    --<I - REQ.89338 - SOPORTE LEGADOS - 05/05/2020>
    /*
    BEGIN
      SELECT MAX(cod_correo_prof) INTO v_cod_correo FROM vve_correo_prof;
    EXCEPTION
      WHEN OTHERS THEN
        v_cod_correo := 0;
    END;
  
    v_cod_correo := v_cod_correo + 1;
    */
    SELECT VVE_CORREO_PROF_SQ01.NEXTVAL INTO V_COD_CORREO FROM DUAL;
    --<F - REQ.89338 - SOPORTE LEGADOS - 05/05/2020>

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       p_num_ficha_vta_veh,
       p_tipo_ref_proc,
       p_destinatarios,
       p_copia,
       p_asunto,
       p_cuerpo,
       p_correoorigen,
       'N',
       'N',
       SYSDATE,
       p_cod_usua_web);
  
    COMMIT;
  
    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_INSE_CORREO',
                                        p_cod_usua_sid,
                                        'Error',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CORREO',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
    Nombre : SP_CORREOS_LAFIT
    Proposito : lista de correos lafit
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    08/02/2018     LAQS      creacion de correos  
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_correos_lafit
  (
    p_ret_correos OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN
    OPEN p_ret_correos FOR
      SELECT di_correo, initcap(nombre1 || ' ' || paterno) des_usuario
        FROM usuarios_rol_usuario a, usuarios b
       WHERE cod_rol_usuario = '015'
         AND b.co_usuario = a.co_usuario;
  
    /*  UNION
    
    SELECT 'phyluis@gmail.com' di_correo, 'LUIS' des_usuario FROM DUAL;*/
  
    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CORREO',
                                          '015',
                                          'Error',
                                          p_ret_mens,
                                          '');
  END;
  /*-----------------------------------------------------------------------------
    Nombre : sp_corro_auto
    Proposito : graba los correos relacionados a autorizacion
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    08/02/2018     LAQS      creacion de correos  
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_corro_auto
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    x_auto_env          VARCHAR2,
    x_auto_apro         VARCHAR2,
    
    x_fec_usuario_aut DATE,
    p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS
  
    wc_des_area_vta             gen_area_vta.des_area_vta%TYPE;
    wc_des_filial               gen_filiales.nom_filial%TYPE;
    wc_des_aut_ficha_vta        VARCHAR2(60);
    wc_mail                     usuarios.di_correo%TYPE;
    wc_asunto                   VARCHAR2(100);
    wc_mensaje                  CLOB; --
    wc_nombre                   VARCHAR2(100);
    wc_vendedor                 VARCHAR2(30);
    vn_val_tot_equipo_local_veh vve_prof_equipo_local_veh.val_tot_equipo_local_veh%TYPE;
    vn_porce                    NUMBER;
    w_contador                  NUMBER;
    w_contador_cont             NUMBER;
    w_flag_ped                  NUMBER;
    v_contador                  INTEGER;
    l_destinatarios             vve_correo_prof.destinatarios%TYPE;
    v_cod_correo                vve_correo_prof.cod_correo_prof%TYPE;
    l_cod_id_procesos           sistemas.sis_mae_procesos.cod_id_procesos%TYPE;
  
    --Equipos Locales
    CURSOR equipo_local(cnum_prof_veh VARCHAR2) IS
      SELECT el.des_equipo_local_veh,
             decode(nvl(pel.ind_cortesia, 'N'),
                    'N',
                    (pel.val_equipo_local_veh * pel.can_equipo_local_veh),
                    0) val_equipo_local_veh,
             decode(nvl(pel.ind_cortesia, 'N'), 'N', pel.porcentaje, 0) porcentaje,
             decode(nvl(pel.ind_cortesia, 'N'), 'N', pel.precio, 0) precio,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        (pel.val_equipo_local_veh *
                                        pel.can_equipo_local_veh),
                                        0),
                                 '999,999,990.99'))) cval_equipo_local_veh,
             ltrim(rtrim(to_char(pel.can_equipo_local_veh, '999,999,990'))) ccan_equipo_local_veh,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.porcentaje,
                                        0),
                                 '999,999,990.99'))) cporcentaje,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.monto_desc,
                                        0),
                                 '999,999,990.99'))) cmonto_desc,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.precio,
                                        0),
                                 '999,999,990.99'))) cprecio
        FROM venta.vve_prof_equipo_local_veh pel,
             venta.vve_equipo_local_veh      el
       WHERE pel.cod_equipo_local_veh = el.cod_equipo_local_veh
         AND pel.num_prof_veh = cnum_prof_veh;
    --Equipos Especiales
    CURSOR equipo_especial(cnum_prof_veh VARCHAR2) IS
      SELECT ee.des_equipo_esp_veh,
             (pee.val_precio_compra * pee.can_equipo_esp_veh) val_precio_compra,
             pee.porcentaje,
             pee.precio,
             ltrim(rtrim(to_char((pee.val_precio_compra *
                                 pee.can_equipo_esp_veh),
                                 '999,999,990.99'))) cval_precio_compra,
             ltrim(rtrim(to_char(pee.can_equipo_esp_veh, '999,999,990'))) ccan_equipo_esp_veh,
             ltrim(rtrim(to_char(pee.porcentaje, '999,999,990.99'))) cporcentaje,
             ltrim(rtrim(to_char(pee.monto_desc, '999,999,990.99'))) cmonto_desc,
             ltrim(rtrim(to_char(pee.precio, '999,999,990.99'))) cprecio
        FROM venta.vve_proforma_equipo_esp_veh pee,
             venta.vve_equipo_esp_veh          ee
       WHERE pee.cod_equipo_esp_veh = ee.cod_equipo_esp_veh
         AND pee.num_prof_veh = cnum_prof_veh;
    --
    npre_veh    vve_proforma_veh_det.val_pre_config_veh%TYPE := 0;
    npor_veh    vve_proforma_veh_det.porcentaje%TYPE := 0;
    ntot_veh    vve_proforma_veh_det.precio%TYPE := 0;
    npre_loc    vve_prof_equipo_local_veh.precio%TYPE := 0;
    nprecio_loc vve_prof_equipo_local_veh.precio%TYPE := 0;
    ntot_loc    vve_prof_equipo_local_veh.precio%TYPE := 0;
    npre_esp    vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    nprecio_esp vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    ntot_esp    vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    nprecio     vve_proforma_veh_det.precio%TYPE := 0;
  
    nporcentaje NUMBER := 0;
  
    ntotal vve_proforma_veh_det.precio%TYPE := 0;
    --
    nexiste_local    NUMBER := 0;
    nexiste_especial NUMBER := 0;
  
    --v_num_prof_veh vve_ficha_vta_pedido_veh.num_prof_veh%TYPE;
  
    uno_cod_filial        vve_ficha_vta_veh.cod_filial%TYPE;
    uno_cod_area_vta      vve_ficha_vta_veh.cod_area_vta%TYPE;
    uno_cod_clie          vve_ficha_vta_veh.cod_clie%TYPE;
    uno_vendedor          vve_ficha_vta_veh.vendedor%TYPE;
    uno_txt_cod_clie      gen_persona.nom_perso%TYPE;
    uno_cod_tipo_perso    gen_persona.cod_tipo_perso%TYPE;
    uno_num_ruc           gen_persona.num_ruc%TYPE;
    uno_num_docu_iden     gen_persona.num_docu_iden%TYPE;
    uno_num_telf_movil    gen_persona.num_telf_movil%TYPE;
    uno_obs_ficha_vta_veh vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE;
    ve_error EXCEPTION;
  BEGIN
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'sp_corro_auto',
                                        p_cod_usua_sid,
                                        'Paso 1',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
  
    SELECT a.cod_filial,
           a.cod_area_vta,
           a.cod_clie,
           a.obs_ficha_vta_veh,
           a.vendedor
      INTO uno_cod_filial,
           uno_cod_area_vta,
           uno_cod_clie,
           uno_obs_ficha_vta_veh,
           uno_vendedor
      FROM vve_ficha_vta_veh a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
  
    SELECT nom_perso,
           cod_tipo_perso,
           num_ruc,
           num_docu_iden,
           cod_area_telf_movil || '-' || num_telf_movil
      INTO uno_txt_cod_clie,
           uno_cod_tipo_perso,
           uno_num_ruc,
           uno_num_docu_iden,
           uno_num_telf_movil
      FROM gen_persona
     WHERE cod_perso = uno_cod_clie;
  
    -- Nombre de la Filial
  
    ---corregir
    BEGIN
      SELECT nom_filial
        INTO wc_des_filial
        FROM generico.gen_filiales
       WHERE cod_filial = uno_cod_filial;
    EXCEPTION
      WHEN no_data_found THEN
        wc_des_filial := NULL;
    END;
  
    -- Nombre del Area de Venta
    --corrrgir
    BEGIN
      SELECT des_area_vta
        INTO wc_des_area_vta
        FROM generico.gen_area_vta
       WHERE cod_area_vta = uno_cod_area_vta;
    EXCEPTION
      WHEN no_data_found THEN
        wc_des_area_vta := 'Area de venta no existe';
    END;
  
    --DESCRIPCION AUTORIZACION APROBADA 
  
    BEGIN
      SELECT des_aut_ficha_vta
        INTO wc_des_aut_ficha_vta
        FROM venta.vve_aut_ficha_vta
       WHERE cod_aut_ficha_vta = x_auto_apro;
    EXCEPTION
      WHEN OTHERS THEN
        wc_des_aut_ficha_vta := NULL;
    END;
  
    -- Datos del usuario conectado
    BEGIN
    
      SELECT lower(a.txt_correo),
             initcap(a.txt_nombres || ' ' || a.txt_nombres)
        INTO wc_mail, wc_nombre
        FROM sis_mae_usuario a
       WHERE a.cod_id_usuario = p_cod_usua_web;
    EXCEPTION
      WHEN no_data_found THEN
        wc_mail   := 'codisa-naf@divemotor.com.pe';
        wc_nombre := 'Sistema SIDWEB';
      
    END;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'sp_corro_auto',
                                        p_cod_usua_sid,
                                        'Paso 2',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    IF p_num_ficha_vta_veh IS NOT NULL THEN
      wc_asunto := 'Autorización ' || wc_des_aut_ficha_vta ||
                   ' a la Ficha de Venta Nro. ' || p_num_ficha_vta_veh;
    
      wc_mensaje := 'Se ha Autorizado una Ficha de Venta en la Filial ' ||
                    wc_des_filial || ' (' || uno_cod_filial ||
                    '): <br><br>' || '<table style="FONT: 9pt Arial"> 
                <tr>
                 <td><b>Nº Ficha</b></td>
                 <td>' || ':</td><td><b>' ||
                    p_num_ficha_vta_veh || '</b></td>
                </tr>
                <tr>
                 <td> Area de Venta </td>
                 <td>' || ':</td><td>' ||
                    wc_des_area_vta || '</td>
                </tr>
                <tr>
                 <td> Autorización </td>
                 <td>' || ':</td><td>' ||
                    wc_des_aut_ficha_vta || '</td>
                </tr>                
                <tr>
                 <td> Usuario </td>
                 <td>' || ':</td><td>' || wc_nombre ||
                    '</td>
                </tr>                
                <tr>
                 <td>Fecha </td>
                 <td>' || ':</td><td>' ||
                    to_char(x_fec_usuario_aut, 'dd/mm/yyyy hh24:mi:ss') ||
                    '</td>
                </tr>
                <tr>
                 <td>Cliente </td>
                 <td>' || ':</td><td>' || uno_cod_clie ||
                    '   ' || uno_txt_cod_clie ||
                    '</td>
                </tr>                                                                
                <tr>
                 <td valign="top">Observaciones </td>
                 <td valign="top">' || ':</td><td>' ||
                    REPLACE(uno_obs_ficha_vta_veh, chr(10), '<br>') ||
                    '</td>
                </tr>
               </table>';
    
      w_contador      := 0;
      w_contador_cont := 0;
      --w_flag_pend     := 0;
      --  w_flag_ped      := 0;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                          'sp_corro_auto',
                                          p_cod_usua_sid,
                                          'Paso 3',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      FOR i IN (SELECT pc.num_prof_veh,
                       pc.cod_tipo_importacion,
                       ti.des_tipo_importacion,
                       pd.cod_familia_veh,
                       fv.des_familia_veh,
                       pd.cod_marca,
                       gm.nom_marca,
                       pd.cod_baumuster,
                       bm.des_baumuster,
                       pd.cod_config_veh,
                       decode(pc.tip_prof_veh,
                              '2',
                              bm.des_baumuster,
                              cv.des_config_veh) des_config_veh,
                       pd.cod_tipo_veh,
                       vt.des_tipo_veh,
                       pd.can_veh,
                       pd.val_vta_veh,
                       pd.val_pre_veh,
                       pd.can_veh * pd.val_pre_veh total,
                       
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') ||
                       to_char((nvl(pd.val_pre_oferta_veh,
                                    pd.val_pre_config_veh) +
                               nvl(pd.val_pre_equipo_local_desc, 0) +
                               nvl(pd.val_pre_equipo_esp_desc, 0)),
                               '99,999,999.99') precio,
                       (nvl(pd.val_pre_oferta_veh, pd.val_pre_config_veh) +
                       nvl(pd.val_pre_equipo_local_desc, 0) +
                       nvl(pd.val_pre_equipo_esp_desc, 0)) preci,
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') ||
                       to_char((nvl(pd.val_pre_config_veh, 0) +
                               nvl(pd.val_pre_equipo_local_veh, 0) +
                               nvl(pd.val_pre_equipo_esp_veh, 0)),
                               '99,999,999.99') precio_lista,
                       (nvl(pd.val_pre_config_veh, 0) +
                       nvl(pd.val_pre_equipo_local_veh, 0) +
                       nvl(pd.val_pre_equipo_esp_veh, 0)) precio_list,
                       fv.des_familia_veh || ' ' || gm.nom_marca || ' ' ||
                       bm.des_baumuster || ' ' || cv.des_config_veh || ' ' ||
                       vt.des_tipo_veh wc_vehiculo,
                       nvl(pd.val_pre_config_veh, 0) npre_veh,
                       pd.porcentaje npor_veh,
                       pd.precio ntot_veh,
                       ltrim(rtrim(to_char((pd.val_pre_config_veh),
                                           '999,999,990.99'))) wc_val_pre_config_veh,
                       ltrim(rtrim(to_char(pd.can_veh, '999,999,990'))) wc_can_veh,
                       ltrim(rtrim(to_char(pd.porcentaje, '999,999,990.99'))) wc_porcentaje,
                       ltrim(rtrim(to_char(pd.monto_desc, '999,999,990.99'))) wc_monto_desc,
                       ltrim(rtrim(to_char(pd.precio, '999,999,990.99'))) wc_precio
                  FROM venta.vve_proforma_veh           pc,
                       venta.vve_proforma_veh_det       pd,
                       venta.vve_ficha_vta_proforma_veh f,
                       venta.vve_tipo_importacion       ti,
                       venta.vve_familia_veh            fv,
                       generico.gen_marca               gm,
                       venta.vve_baumuster              bm,
                       venta.vve_config_veh             cv,
                       venta.vve_tipo_veh               vt,
                       venta.vve_ficha_vta_veh          fvv
                --                
                 WHERE pc.num_prof_veh = pd.num_prof_veh(+)
                   AND pc.num_prof_veh = f.num_prof_veh(+)
                   AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
                   AND fvv.num_ficha_vta_veh = f.num_ficha_vta_veh
                   AND f.num_prof_veh = pc.num_prof_veh
                   AND nvl(f.ind_inactivo, 'N') = 'N'
                   AND pc.cod_tipo_importacion = ti.cod_tipo_importacion(+)
                   AND pd.cod_familia_veh = fv.cod_familia_veh(+)
                   AND pd.cod_marca = gm.cod_marca(+)
                      
                   AND pd.cod_familia_veh = bm.cod_familia_veh(+)
                   AND pd.cod_marca = bm.cod_marca(+)
                   AND pd.cod_baumuster = bm.cod_baumuster(+)
                      
                   AND pd.cod_familia_veh = cv.cod_familia_veh(+)
                   AND pd.cod_marca = cv.cod_marca(+)
                   AND pd.cod_baumuster = cv.cod_baumuster(+)
                   AND pd.cod_config_veh = cv.cod_config_veh(+)
                      
                   AND pd.cod_tipo_veh = vt.cod_tipo_veh(+)
                   AND nvl(ti.ind_inactivo, 'N') = 'N'
                   AND nvl(fv.ind_inactivo, 'N') = 'N'
                   AND nvl(bm.ind_inactivo, 'N') = 'N'
                   AND nvl(cv.ind_inactivo, 'N') = 'N'
                   AND nvl(vt.ind_inactivo, 'N') = 'N')
      LOOP
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                            'sp_corro_auto',
                                            p_cod_usua_sid,
                                            'Paso 4',
                                            p_ret_mens,
                                            p_num_ficha_vta_veh);
        BEGIN
          SELECT SUM(nvl(val_tot_equipo_local_veh, 0))
            INTO vn_val_tot_equipo_local_veh
            FROM vve_prof_equipo_local_veh
           WHERE num_prof_veh = i.num_prof_veh
             AND nvl(ind_cortesia, 'N') = 'S';
        EXCEPTION
          WHEN OTHERS THEN
            vn_val_tot_equipo_local_veh := 0;
        END;
        vn_porce := round(((nvl(i.precio_list, 0) -
                          (nvl(i.preci, 0) -
                          nvl(vn_val_tot_equipo_local_veh, 0))) /
                          i.precio_list) * 100,
                          2);
        npre_veh := i.npre_veh;
        ntot_veh := i.ntot_veh;
      
        wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                                    <tr>
                                      <td colspan="2"><b>Proforma(s) :</b></td>
                                    <td></td><td></td>
                              </tr>';
      
        wc_mensaje := wc_mensaje || '
                   <tr>
                     <td>;;;</td>
                         <td>Proforma </td>
                         <td>' || ':</td><td>' ||
                      i.num_prof_veh || '</td>
                   </tr>               
                   <tr>
                         <td>;;;</td>
                         <td>Familia </td>
                         <td>' || ':</td><td>' ||
                      i.des_familia_veh || '</td>
                       </tr>
                       <tr>
                         <td>;;;</td>
                         <td>Marca </td>
                         <td>' || ':</td><td>' ||
                      i.nom_marca || '</td>
                       </tr>
                       <tr>
                         <td>;;;</td>
                         <td>Modelo </td>
                         <td>' || ':</td><td>' ||
                      i.des_config_veh || '</td>
                       </tr>
                       <tr>
                         <td>;;;</td>
                         <td>Nro. Unidades </td>
                         <td>' || ':</td><td>' ||
                      i.can_veh || '</td>
                       </tr>
                       <tr>
                         <td>;;;</td>
                         <td>Precio Unitario </td>
                         <td>' || ':</td><td>' ||
                      i.precio || '</td>
                       </tr>' ||
                      '<tr>
                         <td>;;;</td>
                         <td>Precio Lista </td>
                         <td>' || ':</td><td>' ||
                      i.precio_lista || '</td>
                       </tr>
                       <tr>
                         <td>;;;</td>
                         <td>% Dscto </td>
                         <td>' || ':</td><td>' ||
                      to_char(vn_porce, '99990.99') ||
                      '%</td>
                       </tr>';
        wc_mensaje := wc_mensaje || '</table>';
      
        IF x_auto_env = '02' THEN
          --Existe Equipo Local
          BEGIN
            SELECT COUNT(1)
              INTO nexiste_local
              FROM venta.vve_prof_equipo_local_veh pel,
                   venta.vve_equipo_local_veh      el
             WHERE pel.cod_equipo_local_veh = el.cod_equipo_local_veh
               AND pel.num_prof_veh = i.num_prof_veh;
          EXCEPTION
            WHEN no_data_found THEN
              nexiste_local := 0;
          END;
          --Existe Equipo Especial
          BEGIN
            SELECT COUNT(*)
              INTO nexiste_especial
              FROM venta.vve_proforma_equipo_esp_veh pee,
                   venta.vve_equipo_esp_veh          ee
             WHERE pee.cod_equipo_esp_veh = ee.cod_equipo_esp_veh
               AND pee.num_prof_veh = i.num_prof_veh;
          EXCEPTION
            WHEN no_data_found THEN
              nexiste_especial := 0;
          END;
          --
          wc_mensaje := wc_mensaje ||
                        '<table border="0" cellpadding="0" cellspacing="1" bgcolor="#CC9933" style="FONT: 9pt Arial">
                               <tr>
                                 <td colspan="2" 
                                 style="text-align: center; width: 263px; background-color: rgb(204, 204, 204); font-weight: bold;">ITEM</td>
                                 <td
                                   style="text-align: center; width: 106px; background-color: rgb(204, 204, 204); font-weight: bold;">Cantidad</td>
                                   <td
                                     style="text-align: center; width: 115px; background-color: rgb(204, 204, 204); font-weight: bold;">Precio Lista
                                   (Unidades)</td>
                                   <td
                                     style="text-align: center; width: 100px; background-color: rgb(204, 204, 204); font-weight: bold;">% Descuento</td>
                                   <td
                                     style="text-align: center; width: 123px; background-color: rgb(204, 204, 204); font-weight: bold;">Precio Venta
                                   </td>
                                 </tr>
                                 <tr bgcolor="#FFFFFF">
                                 <td colspan="2" style="width: 263px;">' ||
                        i.wc_vehiculo ||
                        '</td>
                                 <td style="width: 106px; text-align: center;">' || 1 ||
                        '</td>
                                 <td style="width: 115px; text-align: right;">' ||
                        i.wc_val_pre_config_veh ||
                        '</td>
                                 <td style="width: 100px; text-align: right;">' ||
                        i.wc_porcentaje ||
                        '</td>
                                 <td style="width: 123px; text-align: right;">' ||
                        i.wc_precio || '</td>
                               </tr>';
          --Equipos Locales 
          wc_mensaje := wc_mensaje || '
                                 <tr bgcolor="#FFFFFF" style="font-weight: bold;">
                                 <td colspan="6" style="width: 263px;">Equipo
                                 Local</td>
                               </tr>';
          IF nexiste_local IS NOT NULL AND nexiste_local <> 0 THEN
            FOR rcur IN equipo_local(i.num_prof_veh)
            LOOP
              wc_mensaje := wc_mensaje || '
                                       <tr bgcolor="#FFFFFF">
                                     <td colspan="2" style="width: 263px;">' ||
                            rcur.des_equipo_local_veh ||
                            '</td>
                                           <td style="width: 106px; text-align: center;">' ||
                            rcur.ccan_equipo_local_veh ||
                            '</td>
                                               <td style="width: 115px; text-align: right;">' ||
                            rcur.cval_equipo_local_veh ||
                            '</td>
                                               <td style="width: 100px; text-align: right;">' ||
                            rcur.cporcentaje ||
                            '</td>
                                               <td style="width: 123px; text-align: right;">' ||
                            rcur.cprecio ||
                            '</td>
                                           </tr>';
              npre_loc   := npre_loc + rcur.val_equipo_local_veh;
              ntot_loc   := ntot_loc + rcur.precio;
            END LOOP;
            IF nvl(npre_loc, 0) = 0 THEN
              wc_mensaje := wc_mensaje || '
                                         <tr>
                                           <td colspan="3" 
                                           style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                           style="font-weight: bold;">Total Equipo Local</span></td>
                                           <td
                                           style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(npre_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                           <td
                                           style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                            '</td>
                                           <td
                                           style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(ntot_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                         </tr>';
            ELSE
              wc_mensaje := wc_mensaje || '
                                         <tr>
                                       <td colspan="3" 
                                             style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                             style="font-weight: bold;">Total Equipo Local</span></td>
                                             <td
                                             style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(npre_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                             <td
                                             style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(100 - ((ntot_loc * 100) /
                                                    npre_loc),
                                                    0),
                                                '999,999,990.99'))) ||
                            '</td>
                                             <td
                                             style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(ntot_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                           </tr>';
            END IF;
          ELSE
            wc_mensaje := wc_mensaje || '
                                     <tr bgcolor="#FFFFFF">
                                 <td colspan="2" style="width: 263px;">' ||
                          'NO TIENE EQUIPOS LOCALES' ||
                          '</td>
                                   <td style="width: 106px; text-align: center;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990'))) ||
                          '</td>
                                   <td style="width: 115px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                   <td style="width: 100px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                   <td style="width: 123px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                 </tr>
                                     <tr>
                                   <td colspan="3" 
                                     style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                     style="font-weight: bold;">Total Equipo Local</span></td>
                                     <td
                                     style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td
                                     style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td
                                     style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                   </tr>';
          END IF;
          --Equipos Especiales
          wc_mensaje := wc_mensaje || '
                               <tr bgcolor="#FFFFFF" style="font-weight: bold;">
                               <td colspan="6" style="width: 263px;">Equipo
                               Especial</td>
                             </tr>';
          IF nexiste_especial IS NOT NULL AND nexiste_especial <> 0 THEN
            FOR rcur IN equipo_especial(i.num_prof_veh)
            LOOP
              wc_mensaje := wc_mensaje || '
                                       <tr bgcolor="#FFFFFF">
                                         <td colspan="2" style="width: 263px;">' ||
                            rcur.des_equipo_esp_veh ||
                            '</td>
                                         <td style="width: 106px; text-align: center;">' ||
                            rcur.ccan_equipo_esp_veh ||
                            '</td>
                                         <td style="width: 115px; text-align: right;">' ||
                            rcur.cval_precio_compra ||
                            '</td>
                                         <td style="width: 100px; text-align: right;">' ||
                            rcur.cporcentaje ||
                            '</td>
                                         <td style="width: 123px; text-align: right;">' ||
                            rcur.cprecio ||
                            '</td>
                                       </tr>';
              npre_esp   := npre_esp + rcur.val_precio_compra;
              ntot_esp   := ntot_esp + rcur.precio;
            END LOOP;
            IF nvl(npre_esp, 0) = 0 THEN
              wc_mensaje := wc_mensaje || '
                                       <tr>
                                         <td colspan="3" 
                                         style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                         style="font-weight: bold;">Total Equipo Especial</span></td>
                                         <td
                                         style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(npre_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                         <td
                                         style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                            '</td>
                                         <td
                                         style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(ntot_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                       </tr>';
            ELSE
              wc_mensaje := wc_mensaje || '
                                       <tr>
                                     <td colspan="3" 
                                         style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                         style="font-weight: bold;">Total Equipo Especial</span></td>
                                         <td
                                         style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(npre_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                         <td
                                         style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(100 - ((ntot_esp * 100) /
                                                    npre_esp),
                                                    0),
                                                '999,999,990.99'))) ||
                            '</td>
                                         <td
                                         style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(ntot_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                                       </tr>';
            END IF;
          ELSE
            wc_mensaje := wc_mensaje || '
                                     <tr bgcolor="#FFFFFF">
                                     <td colspan="2" tyle="width: 263px;">' ||
                          'NO TIENE EQUIPOS ESPECIALES' ||
                          '</td>
                                     <td style="width: 106px; text-align: center;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990'))) ||
                          '</td>
                                     <td style="width: 115px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td style="width: 100px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td style="width: 123px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                   </tr>
                                   <tr>
                                     <td colspan="3" 
                                     style="width: 263px; background-color: rgb(204, 204, 204);"><span
                                     style="font-weight: bold;">Total Equipo Especial</span></td>
                                     <td
                                     style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td
                                     style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                     <td
                                     style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                                   </tr>';
          END IF;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                              'sp_corro_auto',
                                              p_cod_usua_sid,
                                              'Paso 5',
                                              p_ret_mens,
                                              p_num_ficha_vta_veh);
          nprecio := nvl((nvl(npre_veh, 0) + nvl(npre_loc, 0) +
                         nvl(npre_esp, 0)),
                         0);
          IF (nvl(npre_veh, 0) + nvl(npre_loc, 0) + nvl(npre_esp, 0)) = 0 THEN
            nporcentaje := 0;
          ELSE
            nporcentaje := nvl((100 -
                               nvl((((nvl(ntot_veh, 0) + nvl(ntot_loc, 0) +
                                    nvl(ntot_esp, 0)) * 100) /
                                    (nvl(npre_veh, 0) + nvl(npre_loc, 0) +
                                    nvl(npre_esp, 0))),
                                    0)),
                               0);
          END IF;
          ntotal      := nvl((nvl(ntot_veh, 0) + nvl(ntot_loc, 0) +
                             nvl(ntot_esp, 0)),
                             0);
          wc_mensaje  := wc_mensaje || '
                               <tr  style="font-weight: bold;">
                               <td colspan="3" 
                               style="width: 263px; background-color: rgb(204, 204, 204);"><span
                               style="font-weight: bold;">TOTAL PROFORMA</span></td>
                               <td
                               style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(nprecio, '999,999,990.99'))) ||
                         '</td>
                               <td
                               style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(nporcentaje, '999,999,990.99'))) ||
                         '</td>
                               <td
                               style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(ntotal, '999,999,990.99'))) ||
                         '</td>
                             </tr>
                             </table><br>';
          npre_veh    := 0;
          npor_veh    := 0;
          ntot_veh    := 0;
          npre_loc    := 0;
          nprecio_loc := 0;
          ntot_loc    := 0;
          npre_esp    := 0;
          nprecio_esp := 0;
          ntot_esp    := 0;
          nprecio     := 0;
          nporcentaje := 0;
          ntotal      := 0;
        END IF;
      
      END LOOP;
    
      ---------------------------
      --Destinatarios
      -------------------------------
      --obtenemos correo de vendedorer 
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                          'sp_corro_auto',
                                          p_cod_usua_sid,
                                          'Paso 6',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      BEGIN
        SELECT su.txt_correo
          INTO wc_vendedor
          FROM cxc.arccve v
         INNER JOIN cxc.arccve_acceso a
            ON v.vendedor = a.vendedor
         INNER JOIN usuarios u
            ON u.co_usuario = a.co_usuario
         INNER JOIN sis_mae_usuario su
            ON u.co_usuario = su.txt_usuario
         WHERE v.vendedor = uno_vendedor
           AND nvl(v.ind_inactivo, 'N') = 'N'
           AND a.ind_crear = 'S'
           AND nvl(a.ind_inactivo, 'N') = 'N';
      EXCEPTION
        WHEN OTHERS THEN
          wc_vendedor := NULL;
      END;
      v_contador := 1;
    
      ---
      IF x_auto_apro = '01' THEN
        l_cod_id_procesos := 61;
      END IF;
      IF x_auto_apro = '02' THEN
        l_cod_id_procesos := 62;
      END IF;
      IF x_auto_apro = '12' THEN
        l_cod_id_procesos := 63;
      END IF;
      FOR i IN (SELECT DISTINCT a.txt_correo
                  FROM sistemas.sis_mae_usuario a
                 INNER JOIN sistemas.sis_mae_perfil_usuario b
                    ON a.cod_id_usuario = b.cod_id_usuario
                   AND b.ind_inactivo = 'N'
                 INNER JOIN sistemas.sis_mae_perfil_procesos c
                    ON b.cod_id_perfil = c.cod_id_perfil
                      
                   AND c.ind_inactivo = 'N'
                   AND c.ind_recibe_correo = 'S'
                 INNER JOIN sis_view_usua_marca um
                    ON um.cod_id_usuario = a.cod_id_usuario
                   AND um.cod_area_vta = uno_cod_area_vta
                 INNER JOIN sis_view_usua_filial uf
                    ON uf.cod_filial = uno_cod_filial
                   AND uf.cod_id_usuario = a.cod_id_usuario
                 WHERE c.cod_id_procesos = l_cod_id_procesos
                   AND txt_correo IS NOT NULL)
      LOOP
      
        IF (v_contador = 1) THEN
          l_destinatarios := l_destinatarios || i.txt_correo;
        ELSE
          l_destinatarios := l_destinatarios || ',' || i.txt_correo;
        END IF;
        v_contador := v_contador + 1;
      END LOOP;
    
      --<I - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>
      /*
      BEGIN
        SELECT MAX(cod_correo_prof) INTO v_cod_correo FROM vve_correo_prof;
      EXCEPTION
        WHEN OTHERS THEN
          v_cod_correo := 0;
      END;
    
      v_cod_correo := v_cod_correo + 1;
      */
      SELECT VVE_CORREO_PROF_SQ01.NEXTVAL INTO V_COD_CORREO FROM DUAL;
      --<F - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>
    
      INSERT INTO vve_correo_prof
        (cod_correo_prof,
         cod_ref_proc,
         tipo_ref_proc,
         destinatarios,
         copia,
         asunto,
         cuerpo,
         correoorigen,
         ind_enviado,
         ind_inactivo,
         fec_crea_reg,
         cod_id_usuario_crea)
      VALUES
        (v_cod_correo,
         p_num_ficha_vta_veh,
         'AF',
         wc_mail || ',' || l_destinatarios,
         wc_vendedor,
         wc_asunto,
         wc_mensaje,
         NULL,
         'N',
         'N',
         SYSDATE,
         p_cod_usua_web);
    
    END IF;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'sp_corro_auto',
                                        p_cod_usua_sid,
                                        'Paso 8',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_corro_auto',
                                          '015',
                                          'Error',
                                          p_ret_mens,
                                          '');
  END;

  /*-----------------------------------------------------------------------------
    Nombre : fun_obt_plant_correo
    Proposito :  Obtiene la Platilla de Correo 
    Referencias :
    Parametros :
    Log de Cambios
    Fecha          Autor         Descripcion
    13/05/2019     ASALAS        REQ-88210 Correo Automatico GPS 
  ----------------------------------------------------------------------------*/
  FUNCTION fun_obt_plant_correo(p_cod_plan_reg NUMBER) RETURN CLOB IS
    v_valor CLOB;
  BEGIN
    BEGIN
      SELECT a.txt_cabe_pla || a.txt_deta_pla
        INTO v_valor
        FROM sis_maes_plan a
       WHERE a.cod_plan_reg = p_cod_plan_reg;
    
    EXCEPTION
      WHEN OTHERS THEN
        v_valor := NULL;
      
    END;
  
    RETURN v_valor;
  
  END fun_obt_plant_correo;

  /*-----------------------------------------------------------------------------
    Nombre      : FUN_LIST_CARAC_CORR
    Proposito   :  Obtiene la Platilla de Correo 
    Referencias :
    Parametros  :
    Log de Cambios
    Fecha          Autor          Descripcion
    30/04/2020  Soporte Legados   REQ.89449 - Cambia el valor del carácter de las
                                  tildes al código ascii.  
  -----------------------------------------------------------------------------*/  
  FUNCTION FUN_LIST_CARAC_CORR (P_VAL_CARA IN VARCHAR2) RETURN VARCHAR2 IS
    L_TXT_VALO VARCHAR2(50);
  BEGIN
    BEGIN
      SELECT DECODE(GLD.VAL_ADI1, NULL, GLD.VAL_ADI2,GLD.VAL_ADI1)
        INTO L_TXT_VALO
        FROM GEN_LVAL     GL,
             GEN_LVAL_DET GLD
       WHERE GL.NO_CIA  = GLD.NO_CIA
         AND GL.COD_VAL = GLD.COD_VAL
         AND NVL(GL.IND_INACTIVO, 'N') = 'N'
         AND NVL(GLD.IND_INACTIVO, 'N') = 'N'
         AND GL.NO_CIA      = '00'
         AND GL.COD_VAL     = 'LSTCAREX'
         AND GLD.DES_VALDET = P_VAL_CARA;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        L_TXT_VALO := NULL;
      WHEN OTHERS THEN
        L_TXT_VALO := NULL;
    END;
    RETURN L_TXT_VALO;
  END;  

END pkg_sweb_five_mant_correos;
