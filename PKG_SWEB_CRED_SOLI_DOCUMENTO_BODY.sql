create or replace PACKAGE BODY    VENTA.PKG_SWEB_CRED_SOLI_DOCUMENTO AS
  PROCEDURE sp_list_docu_soli
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ind_mancomunado   IN generico.gen_persona.ind_mancomunado%TYPE,
    p_cod_tipo_perso    IN generico.gen_persona.cod_tipo_perso%TYPE,
    p_cod_estado_civil  IN generico.gen_persona.cod_estado_civil%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
      cantidad_registros NUMBER := 0;
  BEGIN
    SELECT COUNT(1)
      INTO cantidad_registros
      FROM vve_cred_fina_docu
     WHERE vve_cred_fina_docu.cod_soli_cred = p_cod_soli_cred; 
    
--    IF cantidad_registros=0 THEN
        INSERT INTO vve_cred_fina_docu
                    (
                    cod_soli_cred,
                    cod_docu_eval,
                    ind_oblig,
                    txt_ruta_doc,
                    fec_emis_doc,
                    fec_reg_docu,
                    cod_usua_crea_reg,
                    fec_modi_reg,
                    cod_usua_modi_reg
                    )
            SELECT  p_cod_soli_cred,
                    cod_docu_eval,
                    (CASE WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='N' AND p_cod_estado_civil='C' 
                    AND cod_docu_eval IN (SELECT column_value FROM TABLE (fn_varchar_to_table((select TRIM(val_para_car) 
                    from vve_cred_soli_para where cod_cred_soli_para = 'DOCOBLIN')))) THEN 'S'   
                          WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='N' AND p_cod_estado_civil='S' THEN ind_oblig_gral 
                          WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='J' THEN ind_oblig_gral
                          WHEN p_cod_estado_civil IS NULL THEN ind_oblig_gral
                          ELSE ind_oblig_gral 
                     END) ind_oblig_gral,
                    NULL,
                    NULL,
                    SYSDATE,
                    p_cod_usua_sid,--p_cod_usua_web,
                    NULL,
                    NULL               
               FROM vve_cred_mae_docu
              WHERE ((p_cod_tipo_perso = 'N' and ind_tipo_docu = 'IN')
                    OR 
                    (p_cod_tipo_perso = 'J' and ind_tipo_docu = 'IJ'))
                and cod_docu_eval not in (select cod_docu_eval from vve_cred_fina_docu where cod_soli_cred = p_cod_soli_cred);
                
                
--    END IF;
    OPEN p_ret_cursor FOR
    SELECT  cod_soli_cred,
            cod_docu_eval,
            ind_oblig,
            txt_ruta_doc,
            rownum||') '||(SELECT des_docu_eval FROM vve_cred_mae_docu d WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
            fec_emis_doc,
            fec_reg_docu,
            cod_usua_crea_reg,
            cod_usua_crea_reg cod_usua_web,
            fec_modi_reg,
            cod_usua_modi_reg,
            (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) FROM vve_cred_mae_docu m WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
      FROM  vve_cred_fina_docu f
     WHERE  f.cod_soli_cred = p_cod_soli_cred;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizÃ³ de manera exitosa';
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
  
  PROCEDURE sp_act_docu_soli 
  (
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc         IN VARCHAR2,
    p_operacion            IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   ) AS
    ret_cursor                SYS_REFCURSOR;
    ret_cursor_vigencia       SYS_REFCURSOR;
    v_cod_docu_eval           vve_cred_fina_docu.cod_docu_eval%TYPE;
    v_documentos_obligatorios VARCHAR2(200);
    v_documentos_vigencia     VARCHAR2(200);
    p_ret_adve                VARCHAR2(500);  
    v_estado_vigente          VARCHAR2(500);
    v_estado_evaluacion       VARCHAR2(500);
  BEGIN
     v_estado_vigente:='ES02';
     v_estado_evaluacion:='ES03';
     IF p_operacion='A' THEN   
         UPDATE vve_cred_fina_docu
            SET txt_ruta_doc = p_txt_ruta_doc,
                fec_emis_doc = TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'),
                fec_modi_reg = SYSDATE,
                cod_usua_modi_reg = p_cod_usua_sid
          WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval;
     END IF;
     IF p_operacion='E' THEN
         UPDATE vve_cred_fina_docu
            SET txt_ruta_doc = NULL,
                fec_emis_doc = NULL,
                fec_modi_reg = SYSDATE,
                cod_usua_modi_reg = p_cod_usua_sid
          WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval;
     END IF;
    COMMIT;
      v_documentos_obligatorios := '';
      OPEN ret_cursor FOR
    SELECT vve_cred_fina_docu.cod_docu_eval
      FROM vve_cred_fina_docu
     WHERE cod_soli_cred = p_cod_soli_cred
       AND vve_cred_fina_docu.ind_oblig = 'S'
       AND vve_cred_fina_docu.txt_ruta_doc IS NULL;
      LOOP
        FETCH ret_cursor
         INTO v_cod_docu_eval;
         EXIT WHEN ret_cursor%NOTFOUND;  
         IF v_documentos_obligatorios='' OR v_documentos_obligatorios IS NULL THEN
            v_documentos_obligatorios:= v_cod_docu_eval;
         ELSE
            v_documentos_obligatorios:=v_documentos_obligatorios||','||v_cod_docu_eval;
         END IF;
      END LOOP;
    CLOSE ret_cursor;
    v_documentos_vigencia :='';
    OPEN ret_cursor_vigencia FOR
    SELECT vve_cred_fina_docu.cod_docu_eval
      FROM vve_cred_fina_docu INNER JOIN vve_cred_mae_docu
        ON vve_cred_fina_docu.cod_docu_eval=vve_cred_mae_docu.cod_docu_eval
     WHERE cod_soli_cred = p_cod_soli_cred
       AND vve_cred_fina_docu.ind_oblig = 'S'
       AND TRUNC(vve_cred_fina_docu.fec_emis_doc + vve_cred_mae_docu.val_dias_vig)<TRUNC(SYSDATE)
       AND vve_cred_fina_docu.txt_ruta_doc IS NOT NULL;
      LOOP
        FETCH ret_cursor_vigencia
         INTO v_cod_docu_eval;
         EXIT WHEN ret_cursor_vigencia%NOTFOUND;  
         IF v_documentos_vigencia='' OR v_documentos_vigencia IS NULL THEN
            v_documentos_vigencia:= v_cod_docu_eval;
         ELSE
            v_documentos_vigencia:=v_documentos_vigencia||','||v_cod_docu_eval;
         END IF;
      END LOOP;
    CLOSE ret_cursor_vigencia;
    p_ret_adve := '';   
    IF v_documentos_obligatorios IS NOT NULL THEN
        p_ret_adve := 'Documentos Obligatorios Faltantes: '||v_documentos_obligatorios||'.';
    END IF;

    IF v_documentos_vigencia IS NOT NULL THEN
        p_ret_adve := p_ret_adve||'Documentos Subidos fuera de fecha de vigencia: '||v_documentos_vigencia||'.';    
    END IF;
    --ACTUALIZACION DE ESTADOS CUANDO YA SE COMPLETO LOS DOCUMENTOS ADJUNTOS
    IF v_documentos_obligatorios IS NULL AND v_documentos_vigencia IS NULL THEN
       -- Actualizando fecha de ejecuciÃ³n de actividad    
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A5',p_cod_usua_sid,p_ret_esta,p_ret_mens);  
        
        UPDATE VVE_CRED_SOLI s
           SET s.cod_estado = v_estado_evaluacion
         WHERE s.COD_SOLI_CRED = p_cod_soli_cred 
           AND s.cod_estado = v_estado_vigente;            
    END IF;
    
    
    p_ret_mens := 'El documento se actualizo con Ã©xito.'||p_ret_adve;
    p_ret_esta := 1;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_SEG_SOL_EXCEP:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_act_docu_soli',
                                          'sp_act_docu_soli',
                                          'Error al actualizar el documento',
                                          p_ret_mens,
                                          p_cod_soli_cred);
      ROLLBACK;
  END sp_act_docu_soli;
  
  
  /*-----------------------------------------------------------------------------
  Nombre : SP_LIST_DOCU_GENERAL
  Proposito : Listado de documentos por tipo de proceso
  Referencias : Para adjuntar archivos al registro
  Parametros : [
    p_tipo_docu         -> Flag tipo proceso (Garantia: G / Aval: A)
    p_cod_proceso       -> codigo de garantia,aval,etc
    p_ind_tipo_docu     -> AN,AJ
    p_cod_soli_cred     -> Codigo de la solicitud credito
    p_ind_mancomunado   ->
    p_cod_tipo_perso    -> Codigo Tipo de Persona: N,J(Natural,Juridica)
    p_cod_estado_civil  -> Codito Estado Civil: S,C(Soltero, Casado/Conviviente)
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    08/03/2019   jaltamirano   Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_docu_general
  ( --Inicio Proceso Garantia
    p_tipo_docu         IN VARCHAR2,
    p_cod_proceso       IN VARCHAR2,
    p_ind_tipo_docu     IN vve_cred_mae_docu.ind_tipo_docu%TYPE,
    --Fin Proceso Garantia
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ind_mancomunado   IN generico.gen_persona.ind_mancomunado%TYPE,
    p_cod_tipo_perso    IN generico.gen_persona.cod_tipo_perso%TYPE,
    p_cod_estado_civil  IN generico.gen_persona.cod_estado_civil%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
      v_cantidad_registros NUMBER := 0;
      v_txt_usuario sistemas.usuarios.co_usuario%type;
  BEGIN
  
    IF (p_tipo_docu='G') THEN  --documentos GARANTIAS
        SELECT COUNT(1) INTO v_cantidad_registros FROM vve_cred_soli_gara_docu
                       WHERE vve_cred_soli_gara_docu.cod_soli_cred = p_cod_soli_cred 
                         AND cod_gara = p_cod_proceso;
         
        --IF v_cantidad_registros=0 THEN
            INSERT INTO vve_cred_soli_gara_docu(
                        cod_item_docu,cod_gara,cod_soli_cred,cod_docu_eval,ind_oblig,txt_ruta_doc,fec_doc,
                        fec_reg_docu,cod_usua_crea_reg,fec_modi_reg,cod_usua_modi_reg
                        )
               SELECT  SEQ_CRED_SOLI_GARA_DOCU.NEXTVAL cod_item_docu, 
                        p_cod_proceso,p_cod_soli_cred,cod_docu_eval,ind_oblig_gral,NULL,NULL,
                        SYSDATE,p_cod_usua_sid,NULL,NULL               
                   FROM vve_cred_mae_docu
                  WHERE ind_tipo_docu = p_ind_tipo_docu
                  AND   cod_docu_eval not in (select cod_docu_eval from vve_cred_soli_gara_docu where cod_soli_cred = p_cod_soli_cred);
                   
            COMMIT;            
        --END IF;
        
        OPEN p_ret_cursor FOR
        SELECT  TO_CHAR(cod_item_docu) cod_item_docu,--
                cod_gara cod_proceso,
                cod_soli_cred,
                cod_docu_eval,
                ind_oblig,
                txt_ruta_doc,
                cod_docu_eval||') '||(SELECT des_docu_eval FROM vve_cred_mae_docu d WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
                fec_doc fec_emis_doc,
                fec_reg_docu,
                cod_usua_crea_reg cod_usua_web,fec_modi_reg,cod_usua_modi_reg,
                (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) FROM vve_cred_mae_docu m WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
          FROM  vve_cred_soli_gara_docu f
         WHERE  f.cod_soli_cred = p_cod_soli_cred
           AND  f.cod_gara = p_cod_proceso;
           
    ELSIF (p_tipo_docu = 'A') THEN--documentos AVAL
    
   
    
        SELECT COUNT(1) INTO v_cantidad_registros FROM vve_cred_mae_aval_docu
                       WHERE cod_soli_cred = p_cod_soli_cred 
                         AND cod_per_aval = p_cod_proceso; 
                         
--        IF v_cantidad_registros=0 THEN
            INSERT INTO vve_cred_mae_aval_docu(
                        cod_docu_eval,cod_soli_cred,cod_per_aval,ind_tip_pers_aval,ind_est_civil,ind_oblig,txt_ruta_doc,fec_doc,
                        fec_reg_docu,cod_usua_crea_reg,fec_modi_reg,cod_usua_modi_reg
                        )
                 SELECT cod_docu_eval,p_cod_soli_cred,p_cod_proceso,p_cod_tipo_perso,p_cod_estado_civil,ind_oblig_gral,NULL,NULL,
                        SYSDATE,p_cod_usua_sid,NULL,NULL
                   FROM vve_cred_mae_docu
                  WHERE ind_tipo_docu = p_ind_tipo_docu
                  AND   cod_docu_eval not in (select cod_docu_eval from vve_cred_mae_aval_docu where cod_soli_cred = p_cod_soli_cred  and cod_per_aval = p_cod_proceso );
                   
            COMMIT;            
--        END IF;
        
     
     
            OPEN p_ret_cursor FOR
            SELECT  '0'||rownum cod_item_docu,
                    cod_per_aval cod_proceso,
                    cod_soli_cred,
                    cod_docu_eval,     
                    ind_oblig,
                    txt_ruta_doc,
                    cod_docu_eval||') '||(SELECT des_docu_eval FROM vve_cred_mae_docu d WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
                    fec_doc fec_emis_doc,
                    fec_reg_docu,
                    cod_usua_crea_reg cod_usua_web,fec_modi_reg,cod_usua_modi_reg,
                    (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) FROM vve_cred_mae_docu m WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
              FROM  vve_cred_mae_aval_docu f
             WHERE  f.cod_soli_cred = p_cod_soli_cred
               AND  f.cod_per_aval = p_cod_proceso
               --AND  f.ind_est_civil = p_cod_estado_civil;
               AND (p_cod_estado_civil is null or f.ind_est_civil = p_cod_estado_civil); 
     
     
      
    END IF;
    
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizÃ³ de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_list_docu_general:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_docu_general', p_cod_usua_sid, 'Error en la consulta', p_ret_mens, NULL);

  END;
  
  
    /*-----------------------------------------------------------------------------
  Nombre : SP_ACT_DOCU_GENERAL
  Proposito : Actualizacion de documentos por tipo de proceso
  Referencias : Para adjuntar archivos al proceso
  Parametros : [
    p_tipo_docu         -> Flag tipo proceso (Garantia: G / Aval: A)
    p_cod_proceso       -> codigo de garantia,aval,etc
    p_cod_docu_eval     -> codigo del documento
    p_cod_soli_cred     -> codigo de la solicitud credito
    p_txt_ruta_doc      -> ruta del documento en firebase
    p_fec_emis_doc      -> fecha de adjunto
    p_operacion         -> actualizar/eliminar
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    08/03/2019   jaltamirano   Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_act_docu_general 
  (
    p_tipo_docu            IN VARCHAR2,
    p_cod_proceso          IN VARCHAR2,
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc         IN VARCHAR2,
    p_operacion            IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   ) AS
    ret_cursor                SYS_REFCURSOR;
    ret_cursor_vigencia       SYS_REFCURSOR;
    v_cod_docu_eval           vve_cred_fina_docu.cod_docu_eval%TYPE;
    v_documentos_obligatorios VARCHAR2(200);
    v_documentos_vigencia     VARCHAR2(200);
    p_ret_adve                VARCHAR2(500);  
  BEGIN
    IF (p_tipo_docu = 'G') THEN
            IF p_operacion='A' THEN --ACTUALIZA  
                 UPDATE vve_cred_soli_gara_docu
                    SET txt_ruta_doc = p_txt_ruta_doc, fec_doc = TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'), fec_modi_reg = SYSDATE, cod_usua_modi_reg = p_cod_usua_sid
                  WHERE cod_soli_cred = p_cod_soli_cred AND cod_docu_eval = p_cod_docu_eval AND cod_gara = p_cod_proceso;
             END IF;
             IF p_operacion='E' THEN --ELIMINA
                 UPDATE vve_cred_soli_gara_docu
                    SET txt_ruta_doc = NULL, fec_modi_reg = SYSDATE, fec_doc = NULL, cod_usua_modi_reg = p_cod_usua_sid
                  WHERE cod_soli_cred = p_cod_soli_cred AND cod_docu_eval = p_cod_docu_eval AND cod_gara = p_cod_proceso;
             END IF;
        COMMIT;
          v_documentos_obligatorios := '';
          OPEN ret_cursor FOR
                SELECT cod_docu_eval FROM vve_cred_soli_gara_docu 
                 WHERE cod_soli_cred = p_cod_soli_cred AND cod_gara = p_cod_proceso AND ind_oblig = 'S' AND txt_ruta_doc IS NULL;
                  LOOP
                    FETCH ret_cursor
                     INTO v_cod_docu_eval;
                     EXIT WHEN ret_cursor%NOTFOUND;  
                     IF v_documentos_obligatorios='' OR v_documentos_obligatorios IS NULL THEN
                        v_documentos_obligatorios:= v_cod_docu_eval;
                     ELSE
                        v_documentos_obligatorios:=v_documentos_obligatorios||','||v_cod_docu_eval;
                     END IF;
                  END LOOP;
          CLOSE ret_cursor;
          v_documentos_vigencia :='';
          OPEN ret_cursor_vigencia FOR
                SELECT gd.cod_docu_eval FROM vve_cred_soli_gara_docu gd INNER JOIN vve_cred_mae_docu md ON gd.cod_docu_eval = md.cod_docu_eval
                 WHERE gd.cod_soli_cred = p_cod_soli_cred 
				   AND gd.cod_gara = p_cod_proceso 
				   AND gd.ind_oblig = 'S' 
				   AND TRUNC(gd.fec_doc + md.val_dias_vig)<TRUNC(SYSDATE) AND gd.txt_ruta_doc IS NOT NULL;
                  LOOP
                    FETCH ret_cursor_vigencia
                     INTO v_cod_docu_eval;
                     EXIT WHEN ret_cursor_vigencia%NOTFOUND;  
                     IF v_documentos_vigencia='' OR v_documentos_vigencia IS NULL THEN
                        v_documentos_vigencia:= v_cod_docu_eval;
                     ELSE
                        v_documentos_vigencia:=v_documentos_vigencia||','||v_cod_docu_eval;
                     END IF;
                  END LOOP;
          CLOSE ret_cursor_vigencia;
		  
    ELSIF (p_tipo_docu = 'A') THEN
                    IF p_operacion='A' THEN --ACTUALIZA  
                         UPDATE vve_cred_mae_aval_docu
                            SET txt_ruta_doc = p_txt_ruta_doc, fec_doc = TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'), fec_modi_reg = SYSDATE, cod_usua_modi_reg = p_cod_usua_sid
                          WHERE cod_soli_cred = p_cod_soli_cred AND cod_docu_eval = p_cod_docu_eval AND cod_per_aval = p_cod_proceso;
                     END IF;
                     IF p_operacion='E' THEN --ELIMINA
                         UPDATE vve_cred_mae_aval_docu
                            SET txt_ruta_doc = NULL, fec_modi_reg = SYSDATE, fec_doc = NULL, cod_usua_modi_reg = p_cod_usua_sid
                          WHERE cod_soli_cred = p_cod_soli_cred AND cod_docu_eval = p_cod_docu_eval AND cod_per_aval = p_cod_proceso;
                     END IF;
                COMMIT;		
                  v_documentos_obligatorios := '';
                  OPEN ret_cursor FOR
                        SELECT cod_docu_eval FROM vve_cred_mae_aval_docu 
                         WHERE cod_soli_cred = p_cod_soli_cred AND cod_per_aval = p_cod_proceso AND ind_oblig = 'S' AND txt_ruta_doc IS NULL;
                          LOOP
                            FETCH ret_cursor
                             INTO v_cod_docu_eval;
                             EXIT WHEN ret_cursor%NOTFOUND;  
                             IF v_documentos_obligatorios='' OR v_documentos_obligatorios IS NULL THEN
                                v_documentos_obligatorios:= v_cod_docu_eval;
                             ELSE
                                v_documentos_obligatorios:=v_documentos_obligatorios||','||v_cod_docu_eval;
                             END IF;
                          END LOOP;
                  CLOSE ret_cursor;
                  v_documentos_vigencia :='';
                  OPEN ret_cursor_vigencia FOR
                        SELECT ad.cod_docu_eval FROM vve_cred_mae_aval_docu ad INNER JOIN vve_cred_mae_docu md ON ad.cod_docu_eval = md.cod_docu_eval
                         WHERE ad.cod_soli_cred = p_cod_soli_cred 
                           AND ad.cod_per_aval = p_cod_proceso 
                           AND ad.ind_oblig = 'S' 
                           AND TRUNC(ad.fec_doc + md.val_dias_vig)<TRUNC(SYSDATE) AND ad.txt_ruta_doc IS NOT NULL;
                          LOOP
                            FETCH ret_cursor_vigencia
                             INTO v_cod_docu_eval;
                             EXIT WHEN ret_cursor_vigencia%NOTFOUND;  
                             IF v_documentos_vigencia='' OR v_documentos_vigencia IS NULL THEN
                                v_documentos_vigencia:= v_cod_docu_eval;
                             ELSE
                                v_documentos_vigencia:=v_documentos_vigencia||','||v_cod_docu_eval;
                             END IF;
                          END LOOP;
                  CLOSE ret_cursor_vigencia;
              
    END IF;
    
    p_ret_adve := '';   
    IF v_documentos_obligatorios IS NOT NULL THEN
    p_ret_adve := 'Documentos Obligatorios Faltantes: '||v_documentos_obligatorios||'.';
    END IF;
    
    IF v_documentos_vigencia IS NOT NULL THEN
    p_ret_adve := p_ret_adve||'Documentos Subidos fuera de fecha de vigencia: '||v_documentos_vigencia||'.';    
    END IF;
    
    p_ret_mens := 'El documento se actualizo con Ã©xito.'||p_ret_adve;
    p_ret_esta := 1;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACT_DOCU_GENERAL_EXCEP:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_act_docu_general',
                                          'sp_act_docu_general',
                                          'Error al actualizar el documento',
                                          p_ret_mens,
                                          p_cod_soli_cred);
      ROLLBACK;
  END sp_act_docu_general;

END PKG_SWEB_CRED_SOLI_DOCUMENTO; 