create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_EVENTO AS
  PROCEDURE sp_inse_cred_soli_even 
  (
    p_cod_item_even_refe   IN vve_cred_soli_even.cod_item_even_refe%TYPE,
    p_cod_soli_cred        IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_txt_asun             IN vve_cred_soli_even.txt_asun%TYPE,
    p_txt_comen            IN vve_cred_soli_even.txt_comen%TYPE,
    p_list_cod_usu         IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,  
    p_ret_cod_item_even    OUT vve_cred_soli_even.cod_item_even%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   ) AS
  c_usuarios                SYS_REFCURSOR;
  v_cod_id_usuario          sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
  v_txt_correo              sistemas.sis_mae_usuario.txt_correo %TYPE;
  v_txt_usuario             sistemas.sis_mae_usuario.txt_usuario %TYPE;
  v_txt_nombres             sistemas.sis_mae_usuario.txt_nombres %TYPE;
  v_txt_apellidos           sistemas.sis_mae_usuario.txt_apellidos %TYPE;
  v_cod_cred_soli_even_dest vve_cred_soli_even_dest.cod_cred_soli_even_dest%TYPE;
  BEGIN
    BEGIN
        SELECT NVL(MAX(COD_ITEM_EVEN),0)+1 
        INTO p_ret_cod_item_even
        FROM vve_cred_soli_even;
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_cod_item_even := -1;
    END;

    INSERT INTO vve_cred_soli_even 
    (
        cod_item_even,
        cod_item_even_refe,
        cod_soli_cred,
        txt_asun,
        txt_comen,
        cod_usuario
     ) 
     VALUES 
     (
        p_ret_cod_item_even,
        p_cod_item_even_refe,
        p_cod_soli_cred,
        p_txt_asun,
        p_txt_comen,
        p_cod_usua_sid
     );

     OPEN c_usuarios FOR
   SELECT column_value 
     FROM table(fn_varchar_to_table(p_list_cod_usu));
    LOOP
        FETCH c_usuarios
         INTO v_cod_id_usuario;

         EXIT WHEN c_usuarios%NOTFOUND;  

         SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
           INTO v_cod_id_usuario, v_txt_correo, v_txt_usuario, v_txt_nombres, v_txt_apellidos
           FROM sistemas.sis_mae_usuario
          WHERE COD_ID_USUARIO = v_cod_id_usuario;

         SELECT NVL(MAX(cod_cred_soli_even_dest),0)+1
           INTO v_cod_cred_soli_even_dest
           FROM vve_cred_soli_even_dest;

         INSERT INTO vve_cred_soli_even_dest 
         (
            txt_corre_dest,
            cod_cred_soli_even_dest,
            cod_item_even,
            cod_id_usuario
         ) VALUES 
         (
            v_txt_correo,
            v_cod_cred_soli_even_dest,
            p_ret_cod_item_even,
            v_cod_id_usuario
         );



    END LOOP;
    CLOSE c_usuarios;

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'El evento se registro con éxito';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_cod_item_even := -1;
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_SEG_SOL_EXCEP:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'PROC_INS_CRED_SOLI_EVEN',
                                          'PROC_INS_CRED_SOLI_EVEN',
                                          'Error al actualizar la solicitud',
                                          p_ret_mens,
                                          p_cod_soli_cred);
      ROLLBACK;
  END sp_inse_cred_soli_even;

  FUNCTION fu_list_cred_soli_dest
  (
    p_cod_item_even IN vve_cred_soli_even.cod_item_even%TYPE
  )
  RETURN VARCHAR2 AS
  v_txt_mensaje_evento VARCHAR(25000):=''; 
  v_contactos          VARCHAR(25000):='';
  c_cod_id_usuario    SISTEMAS.SIS_MAE_USUARIO.COD_ID_USUARIO%TYPE;
  v_cod_id_usuario    SISTEMAS.SIS_MAE_USUARIO.COD_ID_USUARIO%TYPE;
  v_txt_correo        SISTEMAS.SIS_MAE_USUARIO.TXT_CORREO%TYPE;
  v_txt_usuario       SISTEMAS.SIS_MAE_USUARIO.TXT_USUARIO%TYPE;
  v_txt_nombres       SISTEMAS.SIS_MAE_USUARIO.TXT_NOMBRES%TYPE;
  V_Txt_Apellidos     SISTEMAS.SIS_MAE_USUARIO.TXT_APELLIDOS%TYPE;
  v_count_dest        NUMBER:=0;
  c_usuarios          SYS_REFCURSOR;
  BEGIN
    OPEN c_usuarios FOR
    SELECT vve_cred_soli_even_dest.cod_id_usuario
      FROM vve_cred_soli_even_dest
     WHERE vve_cred_soli_even_dest.cod_item_even = p_cod_item_even;
    LOOP
        FETCH c_usuarios
        INTO c_cod_id_usuario;
        EXIT WHEN c_usuarios%NOTFOUND;

        SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
        INTO v_cod_id_usuario, v_txt_correo, v_txt_usuario, v_txt_nombres, v_txt_apellidos
        FROM sistemas.sis_mae_usuario
        WHERE cod_id_usuario = c_cod_id_usuario; 

        IF V_COUNT_DEST = 0 THEN
            v_contactos := v_txt_nombres || ' ' || v_txt_apellidos ;
        ELSE 
            v_contactos := v_txt_nombres || ' ' || v_txt_apellidos || ', ' ||
                           v_contactos;
        END IF;
        v_count_dest:= v_count_dest + 1;
    END LOOP;
    CLOSE c_usuarios;
    v_txt_mensaje_evento := v_txt_mensaje_evento || '<br>Notificados ' ||v_contactos;
    return v_txt_mensaje_evento;
  END fu_list_cred_soli_dest;

  PROCEDURE sp_list_cred_soli_even 
    (
        p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
        p_fec_item_even_ini IN VARCHAR2,
        p_fec_item_even_fin IN VARCHAR2,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ind_paginado      IN VARCHAR2,
        p_limitinf          IN INTEGER,
        p_limitsup          IN INTEGER, 
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) 
    AS
    ln_limitinf   NUMBER := 0;
    ln_limitsup   NUMBER := 0;
    ret_cursor_filtro  SYS_REFCURSOR;
    v_cod_item_even  vve_cred_soli_even.cod_item_even%TYPE;
    v_cod_item_even_list   VARCHAR2(500);
    v_query                VARCHAR2(200);
  BEGIN
    IF p_ind_paginado = 'N' OR p_ind_paginado IS NULL THEN
        SELECT COUNT(1) INTO ln_limitsup FROM vve_cred_soli_even;
    ELSE
        ln_limitinf := p_limitinf - 1;
        ln_limitsup := p_limitsup;
    END IF;
    -- TAREA: Se necesita implantación para PROCEDURE PKG_SWEB_CRED_SOLI_EVENTO.proc_sel_cred_soli_even
      v_cod_item_even_list := '';
      OPEN p_ret_cursor FOR
     SELECT cod_item_even_refe,
            cod_soli_cred,
            txt_asun,
            txt_comen,
            cod_item_even,
            fu_list_cred_soli_dest(cod_item_even) as notificados,
            fec_item_even,
            cod_usuario FROM (SELECT cod_item_even_refe,
                                     cod_soli_cred,
                                     txt_asun,
                                     txt_comen,
                                     cod_item_even,
                                     fu_list_cred_soli_dest(cod_item_even) as notificados,
                                     fec_item_even,
                                     cod_usuario
                                FROM vve_cred_soli_even
                               WHERE cod_item_even IN (SELECT cod_item_even
                                                         FROM vve_cred_soli_even
                                                        WHERE cod_soli_cred = p_cod_soli_cred
                                                          AND cod_item_even_refe IS NULL
                                                          AND (
                                                                (p_fec_item_even_ini IS NULL AND p_fec_item_even_fin IS NULL) 
                                                           OR (TO_DATE(p_fec_item_even_ini,'DD/MM/YYYY')<=TRUNC(fec_item_even) 
                                                          AND TRUNC(fec_item_even)<=TO_DATE(p_fec_item_even_fin,'DD/MM/YYYY'))
                                                               )  ORDER BY fec_item_even DESC
                                                        OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY)
                              UNION 
                             SELECT cod_item_even_refe,
                                    cod_soli_cred,
                                    txt_asun,
                                    txt_comen,
                                    cod_item_even,
                                    fu_list_cred_soli_dest(cod_item_even) as notificados,
                                    fec_item_even,
                                    cod_usuario 
                               FROM vve_cred_soli_even
                         START WITH cod_item_even_refe IN (SELECT cod_item_even
                                                         FROM vve_cred_soli_even
                                                        WHERE cod_soli_cred = p_cod_soli_cred
                                                          AND cod_item_even_refe IS NULL
                                                          AND (
                                                                (p_fec_item_even_ini IS NULL AND p_fec_item_even_fin IS NULL) 
                                                           OR (TO_DATE(p_fec_item_even_ini,'DD/MM/YYYY')<=TRUNC(fec_item_even) 
                                                          AND TRUNC(fec_item_even)<=TO_DATE(p_fec_item_even_fin,'DD/MM/YYYY'))
                                                               ) ORDER BY fec_item_even DESC
                                                        OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY) 
                   CONNECT BY PRIOR cod_item_even = cod_item_even_refe) ORDER BY fec_item_even DESC;
    /*************************************/
        SELECT COUNT(1) INTO p_ret_cantidad
                        FROM (SELECT cod_item_even_refe,
                                     cod_soli_cred,
                                     txt_asun,
                                     txt_comen,
                                     cod_item_even,
                                     fu_list_cred_soli_dest(cod_item_even) as notificados,
                                     fec_item_even,
                                     cod_usuario
                                FROM vve_cred_soli_even
                               WHERE cod_item_even IN (SELECT cod_item_even
                                                         FROM vve_cred_soli_even
                                                        WHERE cod_soli_cred = p_cod_soli_cred
                                                          AND cod_item_even_refe IS NULL
                                                          AND (
                                                                (p_fec_item_even_ini IS NULL AND p_fec_item_even_fin IS NULL) 
                                                           OR (TO_DATE(p_fec_item_even_ini,'DD/MM/YYYY')<=TRUNC(fec_item_even) 
                                                          AND TRUNC(fec_item_even)<=TO_DATE(p_fec_item_even_fin,'DD/MM/YYYY'))
                                                               ))) ORDER BY fec_item_even DESC;
    /*************************************/
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CRED_SOLI',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);   
  END sp_list_cred_soli_even;

  PROCEDURE sp_gen_plantilla_correo_even
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN VARCHAR2,
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
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_dato_usuario      VARCHAR(50);
    v_desc_vendedor     VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

    -- Actualizar Correos
    /*
    PKG_SWEB_FIVE_MANT_CORREOS.sp_actualizar_envio('',
                        'FP',
                        p_num_ficha_vta_veh,
                        p_id_usuario,
                        p_ret_esta,
                        p_ret_mens);
    */
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
    v_correos := '';
    v_contador := 1;
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
        v_correos := v_correos||v_txt_correo;
      ELSE
        v_correos := v_correos||','||v_txt_correo;
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

    -- Obtener datos de la ficha
    /*
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
    */
    -- Obtener datos de usuario quien realizo la accion
    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;

    --Asunto del mensaje Historial de ficha de venta Agregar comentario

    v_asunto := 'Asignación de solicitud.: ' ||p_cod_soli_cred;

    /*OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;*/

      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Evento de Solicitud de Crédito</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Solicitud de Crédito.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Eventos de Solicitud de Crédito</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Creación de Evento</h1>                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_contactos) ||
                   '</span>, se ha generado una notificación dentro del módulo de Solicitud de Crédito:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud de Crédito</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        ' ||p_cod_soli_cred||'
                                    </p>
                                  </div>
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

      sp_inse_correo(NULL,--p_num_ficha_vta_veh,
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

    /*END LOOP;
    CLOSE c_usuarios;*/

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || 'sp_gen_plantilla_correo_cfich';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plantilla_correo_even',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);

  END;

  ---------------------------------------------------------------
  PROCEDURE sp_gen_plantilla_correo_aprob
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN VARCHAR2,
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
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_dato_usuario      VARCHAR(50);
    v_desc_vendedor     VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    gen_persona.cod_perso%TYPE;
    v_txt_correo        gen_persona.dir_correo%TYPE;
    v_txt_nombres       gen_persona.nom_perso%TYPE;
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;
    c_documentos        SYS_REFCURSOR;
    v_list_docu         VARCHAR(9000);
    v_query_docu        VARCHAR(4000);
    v_cod_tipo_perso    VARCHAR(2);    
    v_cod_estado_civil  VARCHAR(2);
    v_conteo            INTEGER;
    v_documento         VARCHAR(4000);  
    v_cod_clie          VARCHAR2(8);

  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

    -- Actualizar Correos
    /*
    PKG_SWEB_FIVE_MANT_CORREOS.sp_actualizar_envio('',
                        'FP',
                        p_num_ficha_vta_veh,
                        p_id_usuario,
                        p_ret_esta,
                        p_ret_mens);
    */
    -- Obtenemos los correos a Notificar

    SELECT cod_clie INTO v_cod_clie 
    FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

    IF v_cod_clie IS NOT NULL THEN
    dbms_output.put_line('1');
      v_query := 'SELECT COD_PERSO, DIR_CORREO, NOM_PERSO FROM GEN_PERSONA WHERE COD_PERSO IN (''' ||
                 v_cod_clie || ''') ';
    END IF;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plantilla_correo_aprob',
                                        NULL,
                                        'error al enviar correo',
                                        v_query,
                                        v_query);

    -- Listado de documentos
    v_conteo := 0;

    SELECT cod_tipo_perso, nvl(cod_estado_civil, 'S') INTO v_cod_tipo_perso, v_cod_estado_civil FROM 
    vve_cred_soli c INNER JOIN gen_persona g ON (c.cod_clie = cod_perso)
    WHERE cod_soli_cred = p_cod_soli_cred;

    IF v_cod_tipo_perso = 'J' THEN
        v_query_docu := 'select des_docu_eval from vve_cred_mae_docu where ind_tipo_docu = ''IJ'' ';
    ELSE 
        IF v_cod_estado_civil = 'C' THEN
            v_query_docu := 'select des_docu_eval from vve_cred_mae_docu where ind_tipo_docu = ''IN'' and ind_oblig_gral = ''N'' ';
        ELSE 
            v_query_docu := 'select des_docu_eval from vve_cred_mae_docu where ind_tipo_docu = ''IN'' and ind_oblig_gral = ''S'' ';
        END IF;
    END IF;

    dbms_output.put_line('2');

    OPEN c_documentos FOR v_query_docu;
        LOOP
            FETCH c_documentos
                INTO v_documento;
            EXIT WHEN c_documentos%NOTFOUND;

            v_conteo := v_conteo + 1;   

            v_list_docu := '* ' || v_documento || '<br />' ||
                           v_list_docu;
        END LOOP;
    CLOSE c_documentos;

    dbms_output.put_line('3');

    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;

    dbms_output.put_line('3.0');

    v_correos := '';
    v_contador := 1;

    dbms_output.put_line('3333');

    OPEN c_usuarios FOR v_query;
    dbms_output.put_line('3.1.1');
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_nombres;
      EXIT WHEN c_usuarios%NOTFOUND;

    dbms_output.put_line('3.1');

      v_contactos := v_txt_nombres || '<br />' ||
                     v_contactos;
      IF (v_contador = 1) THEN
        v_correos := v_correos||v_txt_correo;
      ELSE
        v_correos := v_correos||','||v_txt_correo;
      END IF;
      v_contador := v_contador + 1;
    END LOOP;
    CLOSE c_usuarios;

    dbms_output.put_line('4');

    /*BEGIN
      SELECT dir_correo
        INTO v_correoori
        FROM gen_persona
       WHERE cod_perso = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN

    END;*/

    v_correoori := 'apps@divemotor.com.pe';

    -- Obtener datos de la ficha
    /*
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
    */
    -- Obtener datos de usuario quien realizo la accion

    dbms_output.put_line('5');

    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;

    dbms_output.put_line('6');

    --Asunto del mensaje Historial de ficha de venta Agregar comentario

    v_asunto := 'Aprobación de solicitud.: ' ||p_cod_soli_cred;

    /*OPEN c_usuarios FOR v_query;
    LOOP
      FETCH c_usuarios
        INTO v_cod_id_usuario,
             v_txt_correo,
             v_txt_usuario,
             v_txt_nombres,
             v_txt_apellidos;
      EXIT WHEN c_usuarios%NOTFOUND;*/

      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Evento de Solicitud de Crédito</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Solicitud de Crédito.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Eventos de Solicitud de Crédito</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Creación de Evento</h1>                            
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                   rtrim(v_contactos) ||
                   '</span>, se ha generado una notificación dentro del módulo de Solicitud de Crédito:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud de Crédito</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        ' ||p_cod_soli_cred||'
                                    </p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Listado de Documentos</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                   rtrim(v_list_docu) ||
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

      sp_inse_correo(NULL,--p_num_ficha_vta_veh,
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

    /*END LOOP;
    CLOSE c_usuarios;*/

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
  ---------------------------------------------------------

  PROCEDURE sp_gen_plant_correo_soli_apro
  (
    p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_clie          IN      vve_cred_soli.cod_clie%TYPE,
    p_id_usuario        IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT     NUMBER,
    p_ret_esta          OUT     NUMBER,
    p_ret_mens          OUT     VARCHAR2
  ) AS
    ve_error            EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_dato_usuario      VARCHAR(50);
    v_desc_vendedor     VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    gen_persona.cod_perso%TYPE;
    v_txt_correo        gen_persona.dir_correo%TYPE;
    v_txt_nombres       gen_persona.nom_perso%TYPE;
    wc_string           VARCHAR(10);
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;
    c_documentos        SYS_REFCURSOR;
    v_list_docu         VARCHAR(9000);
    v_query_docu        VARCHAR(4000);
    v_cod_tipo_perso    VARCHAR(2);    
    v_cod_estado_civil  VARCHAR(2);
    v_conteo            INTEGER;
    v_documento         VARCHAR(4000);            
  BEGIN

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;


    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_gen_plant_correo_soli_apro',
                                        NULL,
                                        'SOLI APRO',
                                        v_query,
                                        v_query);

    -- Listado de documentos
    v_conteo := 0;

    SELECT cod_tipo_perso, nvl(cod_estado_civil, 'S') INTO v_cod_tipo_perso, v_cod_estado_civil FROM 
    vve_cred_soli c INNER JOIN gen_persona g ON (c.cod_clie = cod_perso)
    WHERE cod_soli_cred = p_cod_soli_cred;

    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;


    v_correoori := 'apps@divemotor.com.pe';

    dbms_output.put_line('5');

    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;

    dbms_output.put_line('6');

    SELECT nom_perso, dir_correo INTO v_contactos, v_correos FROM gen_persona WHERE cod_perso = p_cod_clie;  

    --Asunto del mensaje Historial de ficha de venta Agregar comentario

    v_asunto := 'Aprobación de solicitud.: ' ||p_cod_soli_cred;

      v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Solicitar Aprobación</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Solicitud de Crédito.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Solicitud de Aprobación</h1>                           
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola '  
                    || rtrim(v_contactos) ||
                   '</span>, se ha generado una notificación dentro del módulo de Solicitud de Crédito:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud de Crédito</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        ' ||p_cod_soli_cred||'
                                    </p>
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

                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> Por definir.</p>
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

      sp_inse_correo(NULL,--p_num_ficha_vta_veh,
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
  ---------------------------------------------------------


 PROCEDURE sp_gen_plant_correo_apro_usu
  (
    p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_clie          IN      vve_cred_soli.cod_clie%TYPE,
    p_estado            IN      VARCHAR2,
    p_observacion       IN      VARCHAR2,
    p_id_usuario        IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT     NUMBER,
    p_ret_esta          OUT     NUMBER,
    p_ret_mens          OUT     VARCHAR2
  ) AS
    ve_error            EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_dato_usuario      VARCHAR(50);
    v_desc_vendedor     VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_cod_id_usuario    gen_persona.cod_perso%TYPE;
    v_txt_correo        gen_persona.dir_correo%TYPE;
    v_txt_nombres       gen_persona.nom_perso%TYPE;
    v_instancia         VARCHAR(20);
    v_correos           VARCHAR(2000);
    v_contador          INTEGER;
    c_documentos        SYS_REFCURSOR;
    v_list_docu         VARCHAR(9000);
    v_query_docu        VARCHAR(4000);
    v_cod_tipo_perso    VARCHAR(2);    
    v_cod_estado_civil  VARCHAR(2);
    v_conteo            INTEGER;
    v_documento         VARCHAR(4000); 
    v_nom_banco         VARCHAR2(200);
    v_nom_marca         VARCHAR2(200);
    v_ind_nivel         NUMBER;
    v_cod_id_usua       NUMBER;
    v_envio_correo      VARCHAR2(1);
    v_url_solcre        VARCHAR2(50);
    v_fecha_aprobacion_cliente vve_cred_soli.fec_apro_clie%TYPE;
    v_nom_perso               gen_persona.nom_perso%TYPE;

    v_descripcion             VARCHAR2(200);
    v_val_porc_ci             NUMERIC(5,2);
    v_val_ci                  NUMERIC(10,2);
    v_val_mon_fin             NUMERIC(10,2);
    v_can_plaz_mes            NUMERIC(5,0);
    v_nro_letras              NUMERIC(5,0);
    v_can_dias_venc_prim_letr NUMERIC(5,0);
    v_val_porc_tea_sigv       NUMERIC(10,7);
    v_seguro                  VARCHAR2(3);
    v_seguro_deta             VARCHAR2(30);
    v_gps                     VARCHAR2(3);
    v_gps_deta                VARCHAR2(50);
    v_val_gast_admi           NUMERIC(12,3);
 --   v_nro_soli                vve_Cred_soli.cod_soli_cred%type;


  BEGIN
    SELECT UPPER(instance_name) INTO v_instancia FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       v_instancia)  
    INTO v_url_solcre
    FROM dual;

    SELECT nom_perso INTO v_nom_perso
    FROM gen_persona
    WHERE cod_perso = p_cod_clie;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

    -- Listado de documentos
    v_conteo := 0;    
    v_correoori := 'apps@divemotor.com.pe';    
    v_envio_correo := 'S';

    SELECT MIN(ind_nivel) INTO v_ind_nivel FROM vve_cred_soli_apro 
    WHERE cod_soli_cred = p_cod_soli_cred AND cod_id_usua = p_id_usuario
    AND est_apro = 'EEA04';


      SELECT 
                distinct UPPER(tc.descripcion) as descripcion, -- Tipo de crédito
                s.val_porc_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_mon_fin as mont_cred, -- Monto crédito: vve_cred_soli.val_mon_fin + vve_cred_soli.val_prim_seg 
                s.can_plaz_mes, -- Plazo (meses): vve_cred_soli.can_plaz_mes
                si.can_let_per_gra + si.can_tot_let as nro_letras, -- Nro letras: tomar las del simulador y las letras de periodo de gracia
                s.can_dias_venc_1ra_letr as can_dias_venc_prim_letr, -- Venc. 1ra letra: del vve_cred_soli.can_dias_venc_1ra_let        
                s.val_porc_tea_sigv, -- TEA(s/igv): vve_cred_soli.val_porc_tea_sigv
                decode(s.ind_tipo_segu, 'TS01', 'SI','NO') AS seguro,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR','ENDOSADO') AS seguro_deta,
                decode(s.ind_gps, 'S', 'SI', 'NO') AS gps,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR', '-') AS gps_deta, 
                s.val_gasto_admi as val_gast_admi
        INTO    v_descripcion,v_val_porc_ci,v_val_ci,v_val_mon_fin,v_can_plaz_mes,v_nro_letras,v_can_dias_venc_prim_letr,
                     v_val_porc_tea_sigv,v_seguro,v_seguro_deta,v_gps,v_gps_deta,v_val_gast_admi

        FROM    vve_cred_soli s 
                INNER JOIN gen_persona g on (g.cod_perso = s.cod_clie)
                INNER JOIN vve_cred_soli_prof p on (s.cod_soli_cred = p.cod_soli_cred)
                INNER JOIN vve_proforma_veh pv on (p.num_prof_veh = pv.num_prof_veh)
                INNER JOIN vve_proforma_veh_det pd on (pv.num_prof_veh = pd.num_prof_veh)
                INNER JOIN gen_marca gm on (pd.cod_marca = gm.cod_marca)
                LEFT JOIN vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
                INNER JOIN vve_cred_simu si ON (s.cod_soli_cred = si.cod_soli_cred AND si.ind_inactivo = 'N')
                INNER JOIN gen_mae_sociedad ms ON (s.cod_empr = ms.cod_cia)
                INNER JOIN gen_area_vta gav ON gav.cod_area_vta = s.cod_area_vta
                where s.cod_soli_cred = p_cod_soli_cred;

    IF p_estado = 'APRO' THEN
        BEGIN
            select cod_id_usua into v_cod_id_usua from vve_cred_soli_apro 
            where cod_soli_cred = p_cod_soli_cred and ind_nivel = v_ind_nivel + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN 
              v_cod_id_usua := 0;
               v_envio_correo := 'N';
               p_ret_esta := 2; -- ultimo nivel
            WHEN OTHERS THEN
                v_cod_id_usua := 0;
                v_envio_correo := 'N';
        END;      

        IF v_envio_correo = 'S' THEN
            select 
            u.txt_nombres||' '||u.txt_apellidos, u.txt_correo
            into 
            v_contactos, v_correos
            from vve_cred_soli_apro sp,sis_mae_usuario u, sis_mae_perfil_usuario up, sis_mae_perfil p
            where sp.cod_soli_cred = p_cod_soli_cred
            and u.cod_id_usuario = v_cod_id_usua
            and sp.cod_id_usua = up.cod_id_usuario
            and up.cod_id_usuario = u.cod_id_usuario  
            and p.cod_id_perfil = up.cod_id_perfil
            and rownum <= 1;         
        END IF;   
    ELSE     
        IF (v_ind_nivel = 1 and p_estado = 'RECH') THEN             
            v_envio_correo := 'N';
        ELSIF (v_ind_nivel > 1 and p_estado = 'RECH') THEN
            BEGIN
                SELECT cod_id_usua into v_cod_id_usua FROM vve_cred_soli_apro 
                WHERE cod_soli_cred = p_cod_soli_cred AND ind_nivel = v_ind_nivel-1; --cod_crit_apro = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_envio_correo := 'N';
                    p_ret_mens := 'Usted no tiene autorización para envíar correos al siguiente nivel';
                    RAISE ve_error;
            END; 
        ELSE
            BEGIN
                SELECT cod_id_usua  into v_cod_id_usua FROM vve_cred_soli_apro 
                WHERE cod_soli_cred = p_cod_soli_cred AND cod_crit_apro = 1;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_envio_correo := 'N';
                    p_ret_mens := 'Usted no tiene autorización para envíar correos al siguiente nivel';
                    RAISE ve_error;
            END;     
        END IF;

        if v_envio_correo = 'S' and v_cod_id_usua != 0 then -- ID282 LRodriguez - Error en aprobaciones
          select 
          u.txt_nombres||' '||u.txt_apellidos, u.txt_correo
          into 
          v_contactos, v_correos
          from sis_mae_usuario u 
          where u.cod_id_usuario = v_cod_id_usua;    
        end if;    -- ID282 LRodriguez - Error en aprobaciones
    END IF;



    --Asunto del mensaje Historial de ficha de venta Agregar comentario

    v_asunto := 'Aprobación de solicitud.: ' ||LTRIM(p_cod_soli_cred,'0') || ' - ' || TRIM(v_nom_perso);

    IF p_estado = 'RECH' THEN

        v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Solicitar Aprobación(RECHAZO)</title>
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
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Gestión de Créditos</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Solicitud de Aprobación</h1>                           
                            <br />
                            <p style="margin: 0; text-align:center;"><span style="font-weight: bold;">'|| TRIM(v_nom_perso)||'</span></p>
                            <br />
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola '  
                    || rtrim(v_contactos) ||
                   '</span>, tiene una solicitud de crédito RECHAZADA.</p>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>                                
                                  <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Solicitud de Crédito</p>                                  
                                   <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        ' ||p_cod_soli_cred||'
                                    </p>                                     
                                  </div>
                                </td>
                              </tr>
                            </table>

                            <table width="100%">
                                <br />
                                <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; ">
                                ' || p_observacion || '
                                </p>
                            </table>

                            <p align="justify" style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Está dirigida únicamente para el uso individual. Si recibiste este correo por error, hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';

    ELSE--aprobado

       IF v_envio_correo = 'S' THEN

            v_mensaje := '<!DOCTYPE html>
              <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
                  <head>
                    <title>Divemotor - Solicitar Aprobación</title>
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
                                    <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Gestión de Créditos</td>
                                  </tr>
                                </table>
                              </td>
                            </tr>
                          </table>

                          <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;"> 
                            <tr>
                              <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                                <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Solicitud de Aprobación</h1>                           
                                <br />
                                <p style="margin: 0; text-align:center;"><span style="font-weight: bold;">'|| TRIM(v_nom_perso)||'</span></p>
                                <br />
                                <p style="margin: 0;"><span style="font-weight: bold;">Hola '  
                        || rtrim(v_contactos) ||
                       '</span>, tiene una solicitud de crédito pendiente de aprobación.</p>
                       <br />
                       <p>Se adjunta archivo de Resumen Ejecutivo.</p> 

                                <div style="padding: 10px 0;">

                                </div>

                                <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px;  margin: 0;"> Nº de Solicitud de Crédito: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px;  margin: 0;">
                                            ' ||p_cod_soli_cred||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px;  margin: 0;"> Tipo de Crédito: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; margin: 0;">
                                            ' ||v_descripcion||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Cuota inicial (US$): </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_val_porc_ci||'%'|| ' (US$' ||v_val_ci||')
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                 <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Monto Crédito (US$): </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_val_mon_fin||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Plazo (meses): </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_can_plaz_mes||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>                                  
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Nro de Letras: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_nro_letras||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                 <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Vcto. 1era letra (días): </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_can_dias_venc_prim_letr||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                 <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> TEA (sin IGV): </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_val_porc_tea_sigv||'%'||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Seguro vehículo: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_seguro|| '-'||v_seguro_deta||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                  <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> GPS: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_gps||'-'||v_gps_deta||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                <tr>
                                    <td>                                    
                                      <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Gastos admin.: </p>     
                                    </td>
                                    <td>
                                      <div class="to100" style="display:inline-block;width: 110px">
                                        <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                            ' ||v_val_gast_admi||'
                                        </p>
                                      </div>
                                    </td>
                                  </tr>
                                </table>
                                <table width="100%">
                                    <br />
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; ">
                                    ' || p_observacion || '
                                    </p>
                                    <br />
                                </table>                                
                                <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;">
                                    <tr>
                                      <td style="padding: 0;">
                                        <a href="' || v_url_solcre || 'resolucion/creditos/aprobacion/solicitud-credito?solicitud='||p_cod_soli_cred||'=aprobado" target="_blank" style="padding: 15px;border-radius: 5px; background-color: #0076ff;text-align:center;  color: #ffffff; display: block; font-family: helvetica, arial, sans-serif; font-size: 14px; text-decoration: none; font-weight: bold;">Aprobar</a>
                                      </td>
                                    </tr>
                                    <tr>
                                      <td style="padding: 5px;">
                                        </td>
                                    </tr>
                                    <tr>
                                      <td style="padding: 0;">
                                        <a href="' || v_url_solcre || 'resolucion/creditos/aprobacion/solicitud-credito?solicitud='||p_cod_soli_cred||'=rechazado" target="_blank" style="padding: 13px;border-radius: 5px; border: 2px solid #0076ff;text-align:center;color: #0076ff; display: block; font-family: helvetica, arial, sans-serif; font-size: 14px; text-decoration: none; font-weight: bold;">Rechazar</a>
                                      </td>
                                    </tr>
                                </table>                                

                                <p align="justify" style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Está dirigida únicamente para el uso individual. Si recibiste este correo por error, hacer caso omiso a la solicitud.</p>
                              </td>
                            </tr>
                          </table>
                          <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                            <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID</p>
                          </div>
                        </td>
                      </tr>
                    </table>
                  </body>
              </html>';

        END IF;

    END IF;
    if v_envio_correo = 'S' and v_cod_id_usua != 0 then -- ID282 LRodriguez - Error en aprobaciones
         sp_inse_correo(
                    p_cod_soli_cred,
                     v_correos,
                     '',
                     v_asunto,
                     v_mensaje,
                     v_correoori,
                     p_id_usuario,
                     p_id_usuario,
                     'SC',
                     p_ret_correo,
                     p_ret_esta,
                     p_ret_mens);   
     end if;    -- ID282 LRodriguez - Error en aprobaciones              
         p_ret_esta := 1;
         p_ret_mens := 'Se ejecuto correctamente';

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plant_correo_apro_usu',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);      
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM || ' sp_gen_plant_correo_apro_usu';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_gen_plant_correo_apro_usu',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_soli_cred);

  END;


  ---------------------------------------------------------

  PROCEDURE sp_inse_correo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_correo vve_correo_prof.cod_correo_prof%TYPE;
  BEGIN

    BEGIN
      SELECT MAX(cod_correo_prof) INTO v_cod_correo FROM vve_correo_prof;
    EXCEPTION
      WHEN OTHERS THEN
        v_cod_correo := 0;
    END;

    v_cod_correo := v_cod_correo + 1;
    p_ret_correo := v_cod_correo;
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
       p_cod_soli_cred,
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
                                        p_cod_soli_cred);
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
                                          p_cod_soli_cred);
  END;

  PROCEDURE sp_obtener_plantilla
  (
    p_cod_cor_prof  IN vve_correo_prof.cod_correo_prof%TYPE,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos   OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    ve_query VARCHAR2(20000);
  BEGIN

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_OK',
                                        'SP_OBTENER_PLANTILLA_OK',
                                        NULL, --P_COD_USUA_SID,
                                        'SC',
                                        NULL,
                                        p_cod_cor_prof);
   OPEN p_ret_correos FOR 
   SELECT a.cod_correo_prof,
          a.destinatarios,
          a.copia,
          a.asunto,
          a.cuerpo,
          a.correoorigen
     FROM vve_correo_prof a
    WHERE a.cod_correo_prof = p_cod_cor_prof;
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
                                          p_cod_cor_prof);
  END;

  PROCEDURE sp_actualizar_envio
  (
    p_cod_cor_prof      IN vve_correo_prof.cod_correo_prof%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN

    UPDATE vve_correo_prof a
       SET a.ind_enviado         = 'S',
           a.cod_id_usuario_modi = p_id_usuario,
           a.fec_modi_reg        = SYSDATE
     WHERE a.cod_correo_prof = p_cod_cor_prof
       AND a.ind_enviado = 'N';

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
                                          p_cod_cor_prof);
  END;

  PROCEDURE sp_list_docu_soli
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
    SELECT  cod_docu_eval,
            des_docu_eval,
            ind_inactivo,
            val_dias_vig,
            ind_tipo_docu,
            cod_usua_crea_reg,
            fec_crea_reg
      FROM  vve_cred_mae_docu
     WHERE  ROWNUM<=5;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_list_docu_soli:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_list_docu_soli',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);

  END;

END PKG_SWEB_CRED_SOLI_EVENTO; 
