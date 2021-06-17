create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_SOLI_DOCUMENTO AS
  /*-----------------------------------------------------------------------------
  Nombre : sp_list_docu_soli
  Proposito : Listado de documentos por solicitud
  Referencias : Para adjuntar archivos al registro
  Parametros : [
    p_cod_soli_cred     -> Codigo de la solicitud credito
    p_cod_docu_eval     -> Codigo de documento adjunto
    p_TXT_DES_ARCHIVO   -> Descripcion de Archivo
    p_ind_mancomunado   ->
    p_cod_tipo_perso    -> Codigo Tipo de Persona: N,J(Natural,Juridica)
    p_cod_estado_civil  -> Codito Estado Civil: S,C(Soltero, Casado/Conviviente)
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    -------     Anonimo        Creado
    15/04/2020  Dante Artica   Modificacion:90028-carga-de-documentos-multiples
    03/07/2020  AVILCA        Modificación: Listando solo documentos activos
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_docu_soli
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    ------I-90028:Dante Artica   
    p_cod_docu_eval     IN vve_cred_fina_docu.cod_docu_eval%TYPE,  
    p_TXT_DES_ARCHIVO   IN vve_cred_fina_docu.TXT_DES_ARCHIVO%TYPE,  
    ------F-90028:Dante Artica   
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
      v_TOTAL NUMBER := 0;
  BEGIN

      ---F--90201--Cambio de estadp
     SELECT count(1)
          INTO cantidad_registros
          FROM vve_cred_fina_docu t
         WHERE t.cod_soli_cred   = p_cod_soli_cred;
      
      IF cantidad_registros=0 THEN
     
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
                    cod_usua_modi_reg,
                    ------I-90028:Dante Artica   
                    COD_SEC_ARCHIVO, 
                    TXT_DES_ARCHIVO 
                    ------F-90028:Dante Artica   
                    )
            SELECT  p_cod_soli_cred,
                    cod_docu_eval,
                    (CASE WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='N' AND p_cod_estado_civil='C' 
                               AND cod_docu_eval IN (SELECT column_value 
                               FROM TABLE (fn_varchar_to_table((select TRIM(val_para_car) 
                               from vve_cred_soli_para where cod_cred_soli_para = 'DOCOBLIN'))))       THEN 'S'   
                          WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='N' AND p_cod_estado_civil='S'  THEN ind_oblig_gral 
                          WHEN ind_tipo_docu='IN' AND p_cod_tipo_perso='J'                             THEN ind_oblig_gral
                          WHEN p_cod_estado_civil IS NULL                                              THEN ind_oblig_gral
                          ELSE ind_oblig_gral 
                     END) ind_oblig_gral,
                    NULL,
                    NULL,
                    SYSDATE,
                    p_cod_usua_sid,--p_cod_usua_web,
                    NULL,
                    NULL,  
                    ------I-90028:Dante Artica 
                    (select count(*)+1 from vve_cred_fina_docu 
                     where cod_soli_cred=p_cod_soli_cred
                     AND cod_docu_eval=p_cod_docu_eval),
                     p_TXT_DES_ARCHIVO   
                    -----F-90028:Dante Artica        
               FROM vve_cred_mae_docu
              WHERE ((p_cod_tipo_perso = 'N' and ind_tipo_docu = 'IN')
                    OR 
                    (p_cod_tipo_perso = 'J' and ind_tipo_docu = 'IJ'))
               ------I-90028:Dante Artica        
                and cod_docu_eval not in (
                                      select cod_docu_eval from vve_cred_fina_docu 
                                      where cod_soli_cred = p_cod_soli_cred
                                      )
                                      
               ------F-90028:Dante Artica   
               and ind_inactivo = 'N';--<Req. 87567 E2.1 ID## AVILCA 02/12/2020>
                
     END IF;
     
  

   
    OPEN p_ret_cursor FOR
    ------I-90201:Dante Artica 
  select 
            f.cod_soli_cred,
            f.cod_docu_eval,
            f.ind_oblig,
            txt_ruta_doc,
            des_docu_eval,
            fec_emis_doc,
            fec_reg_docu,
            cod_usua_crea_reg,
            cod_usua_crea_reg cod_usua_web,
            ------I-90028:Dante Artica  
            --fec_modi_reg,
            --cod_usua_modi_reg,
            NVL(fec_modi_reg,fec_reg_docu) fec_modi_reg,
            NVL(cod_usua_modi_reg,cod_usua_crea_reg) cod_usua_modi_reg, 
            ------F-90028:Dante Artica     
            (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) 
            FROM vve_cred_mae_docu m 
            WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig,
          ------I-90028:Dante Artica         
           COD_SEC_ARCHIVO,   
           TXT_DES_ARCHIVO 
         ------F-90028:Dante Artica   
from (
        select cod_soli_cred,
                    cod_docu_eval,
                    ind_oblig,
                    rownum||') '||
                    (SELECT des_docu_eval
                     FROM vve_cred_mae_docu d 
                    WHERE d.cod_docu_eval=t.cod_docu_eval) des_docu_eval
        from (
                select distinct f.cod_soli_cred,
                              f.cod_docu_eval,
                              f.ind_oblig
                  from vve_cred_fina_docu f
                  inner join vve_cred_mae_docu d on f.cod_docu_eval = d.cod_docu_eval --Req. 87567 E1.1 ID 53 AVILCA 03/07/2020
                  where  
                          d.ind_inactivo = 'N'--Req. 87567 E1.1 ID 53 AVILCA 03/07/2020
                      and f.cod_soli_cred =p_cod_soli_cred
                      order by f.cod_docu_eval
                  ) t
          )  r
inner join vve_cred_fina_docu f 
on r.cod_soli_cred =f.cod_soli_cred 
and  r.cod_docu_eval=f.cod_docu_eval
order by r.cod_docu_eval,f.COD_SEC_ARCHIVO asc;
 ------F-90201:Dante Artica 
  
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
  /*-----------------------------------------------------------------------------
  Nombre : sp_act_docu_soli
  Proposito : Actualizar documentos por solicitud
  Referencias : Para adjuntar archivos al registro
  Parametros : [
    p_cod_docu_eval     -> Codigo de documento adjunto
    p_cod_soli_cred     -> Codigo de la solicitud credito
    p_cod_sec_archivo   -> Secuencia por tipo de documento
    p_TXT_DES_ARCHIVO   -> Descripcion de Archivo
    p_ind_mancomunado   ->
    p_cod_tipo_perso    -> Codigo Tipo de Persona: N,J(Natural,Juridica)
    p_cod_estado_civil  -> Codito Estado Civil: S,C(Soltero, Casado/Conviviente)  p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc      -> Fecha de emison del documento
    p_operacion         -> Codigo de Operacion
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    -------     Anonimo        Creado
    15/04/2020  Dante Artica   Modificacion:90028-carga-de-documentos-multiples
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_act_docu_soli 
  (
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
   ------I-90028:Dante Artica    
    p_cod_sec_archivo     IN vve_cred_fina_docu.cod_sec_archivo%TYPE,  
    p_TXT_DES_ARCHIVO     IN vve_cred_fina_docu.TXT_DES_ARCHIVO%TYPE,  
    ------F-90028:Dante Artica    
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
    ----I--90028:Dante Artica  
    v_cantidad_registros      NUMBER := 0;
    v_cantidad_registros2     NUMBER := 0;
    v_cantidad_registros3     NUMBER := 0;
    v_quedan_archivos         NUMBER := 0;
    v_nuevo_minimo            NUMBER := 0;
    ----F--90028:Dante Artica  
    v_cod_resp_fina   VARCHAR2(100) := '';
  BEGIN
     v_estado_vigente:='ES02';
     v_estado_evaluacion:='ES03';
     
     
     ----I--90201:Dante Artica  
     SELECT count(1)+1 into v_cantidad_registros
     FROM vve_cred_fina_docu
        WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval
            AND TXT_DES_ARCHIVO  = p_TXT_DES_ARCHIVO;
     
      SELECT count(1) into v_cantidad_registros2
      FROM vve_cred_fina_docu
        WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval;  
            
       SELECT count(1) into v_cantidad_registros3 
       FROM vve_cred_fina_docu t 
              WHERE t.cod_soli_cred=p_cod_soli_cred
              AND t.cod_docu_eval=p_cod_docu_eval
              AND txt_ruta_doc is null;    
            
     ----F--90201:Dante Artica  
     IF p_operacion='A' AND v_cantidad_registros > 1 THEN   
      
         UPDATE vve_cred_fina_docu
            SET txt_ruta_doc = p_txt_ruta_doc,
                fec_emis_doc = TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'),
                fec_modi_reg = SYSDATE,
                cod_usua_modi_reg = p_cod_usua_sid,
                ------I-90028:Dante Artica    
               TXT_DES_ARCHIVO  = p_TXT_DES_ARCHIVO
                ------F-90028:Dante Artica    
          WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval
               ------I-90028:Dante Artica    
            AND TXT_DES_ARCHIVO  = p_TXT_DES_ARCHIVO;
               ------F-90028:Dante Artica  
               
               
       ------I-90201:Dante Artica             
       ELSIF p_operacion='A' AND  v_cantidad_registros2='1' AND v_cantidad_registros3='1'  
        THEN 
        UPDATE vve_cred_fina_docu
            SET txt_ruta_doc = p_txt_ruta_doc,
                fec_emis_doc = TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'),
                fec_modi_reg = SYSDATE,
                cod_usua_modi_reg = p_cod_usua_sid,
                TXT_DES_ARCHIVO  = p_TXT_DES_ARCHIVO,
                COD_SEC_ARCHIVO  = '1'
          WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval;
       ------F-90201:Dante Artica  
       ELSIF p_operacion='A' THEN
       ------I-90028:Dante Artica   
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
                    cod_usua_modi_reg,
                    COD_SEC_ARCHIVO, 
                    TXT_DES_ARCHIVO 
                    )
             SELECT  p_cod_soli_cred,
                    cod_docu_eval,
                    ind_oblig_gral,
                    p_txt_ruta_doc,
                    TO_DATE(p_fec_emis_doc,'DD/MM/YYYY'),
                    SYSDATE,
                    p_cod_usua_sid,
                    NULL,
                    NULL,  
                    (select count(*)+1 from vve_cred_fina_docu 
                     where cod_soli_cred=p_cod_soli_cred
                     AND cod_docu_eval=p_cod_docu_eval),
                     p_TXT_DES_ARCHIVO   
            
               FROM vve_cred_mae_docu
              WHERE cod_docu_eval=p_cod_docu_eval;
    
       ------F-90028:Dante Artica   
     END IF;
     
     IF p_operacion='E' 
         ------I-90028:Dante Artica 
         AND v_cantidad_registros = 1 
         AND v_cantidad_registros2 = 1
          ------F-90028:Dante Artica   
      THEN
         UPDATE vve_cred_fina_docu
            SET txt_ruta_doc = NULL,
                fec_emis_doc = NULL,
                fec_modi_reg = SYSDATE,
                cod_usua_modi_reg = p_cod_usua_sid,
                   ------I-90028:Dante Artica  
                cod_sec_archivo='1',
                 TXT_DES_ARCHIVO = NULL
                   ------F-90028:Dante Artica    
          WHERE cod_soli_cred = p_cod_soli_cred
            AND cod_docu_eval = p_cod_docu_eval;
            
            
             ------I-90028:Dante Artica 
      ELSIF p_operacion='E'  THEN
        delete from vve_cred_fina_docu 
               where cod_soli_cred = p_cod_soli_cred
                AND cod_docu_eval =  p_cod_docu_eval
                AND cod_sec_archivo = p_cod_sec_archivo; 
                
         
         ------F-90028:Dante Artica    
     END IF;   

     
     IF p_operacion='E' THEN
       SELECT count(1) into v_quedan_archivos
           from vve_cred_fina_docu 
               where cod_soli_cred = p_cod_soli_cred
                AND cod_docu_eval =  p_cod_docu_eval;
                           
         SELECT min(cod_sec_archivo) INTO v_nuevo_minimo
                 from vve_cred_fina_docu 
                  where cod_soli_cred = p_cod_soli_cred
                   AND cod_docu_eval = p_cod_docu_eval;
                                  
                     
                IF v_quedan_archivos>0 then
                   update vve_cred_fina_docu set cod_sec_archivo='1'
                   WHERE  cod_soli_cred = p_cod_soli_cred
                          AND cod_docu_eval =  p_cod_docu_eval
                          AND cod_sec_archivo =  v_nuevo_minimo;
                     
                end if;    
      END IF;     
           
    COMMIT;
      v_documentos_obligatorios := '';
      OPEN ret_cursor FOR
    SELECT t.cod_docu_eval
      FROM vve_cred_fina_docu t
      INNER JOIN vve_cred_mae_docu md ON md.cod_docu_eval = t.cod_docu_eval--<Req. 87567 E2.1 ID 28 AVILCA 08/09/2020> 
     WHERE t.cod_soli_cred = p_cod_soli_cred
       AND t.ind_oblig = 'S'
       AND t.txt_ruta_doc IS NULL
       AND md.ind_inactivo = 'N';--<Req. 87567 E2.1 ID 28 AVILCA 08/09/2020>
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
    SELECT t.cod_docu_eval
      FROM vve_cred_fina_docu t INNER JOIN vve_cred_mae_docu s
        ON t.cod_docu_eval=s.cod_docu_eval
     WHERE t.cod_soli_cred = p_cod_soli_cred
       AND t.ind_oblig = 'S'
       AND TRUNC(t.fec_emis_doc + s.val_dias_vig)<TRUNC(SYSDATE)
       AND t.txt_ruta_doc IS NOT NULL;
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
    IF (v_documentos_obligatorios='' OR v_documentos_obligatorios IS NULL)  AND (v_documentos_vigencia='' OR v_documentos_vigencia IS NULL) THEN
     pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                          'sp_act_docu_soli',
                                          'sp_act_docu_soli',
                                          ' 1.- Entró al IF para actualizar vve_cred_soli',
                                          p_ret_mens,
                                          p_cod_soli_cred);
   
      -- BEGIN 
            SELECT cod_resp_fina
             INTO v_cod_resp_fina
            FROM  VVE_CRED_SOLI
            WHERE cod_soli_cred = p_cod_soli_cred; 
     /* EXCEPTION
             WHEN NO_DATA_FOUND THEN 
                  v_cod_resp_fina := '';   
      END;     */       
                  
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                          'sp_act_docu_soli',
                                           v_cod_resp_fina,
                                          ' 2.- Después de Obtener v_cod_resp_fina',
                                          p_ret_mens,
                                          p_cod_soli_cred);
        
        UPDATE VVE_CRED_SOLI
           SET
               cod_anal_cred = v_cod_resp_fina,
               fec_inic_anal = to_date(SYSDATE,'DD/MM/YYYY'),
                cod_estado = 'ES03'
         WHERE COD_SOLI_CRED = p_cod_soli_cred;
           --AND s.cod_estado = v_estado_vigente;
         COMMIT;   
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                          'sp_act_docu_soli',
                                          'sp_act_docu_soli',
                                          ' 3.- Después de actualizar VVE_CRED_SOLI',
                                          p_ret_mens,
                                          p_cod_soli_cred);
          
            
    -- F Req. 87567 E2.1 ID 41 avilca 15/06/2020    
           -- Actualizando fecha de ejecución de actividad  
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A5',p_cod_usua_sid,p_ret_esta,p_ret_mens); 
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E1','A4',p_cod_usua_sid,p_ret_esta,p_ret_mens); 
    -- I Req. 87567 E2.1 ID 41 avilca 15/06/2020 
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                          'sp_act_docu_soli',
                                          'sp_act_docu_soli',
                                          ' 4.- Después de actualizar actividades',
                                          p_ret_mens,
                                          p_cod_soli_cred);
    END IF;
    
    
    
    p_ret_mens := 'El documento se actualizo con éxito.'||p_ret_adve;
    p_ret_esta := 1;
    
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
                  AND   cod_docu_eval not in (select cod_docu_eval from vve_cred_soli_gara_docu where cod_soli_cred = p_cod_soli_cred)
                  AND  ind_inactivo = 'N';-- /** I Req. 87567 E2.1 ID:144 - avilca 01/09/2020 **/
                   
            COMMIT;            
        --END IF;
        
        OPEN p_ret_cursor FOR
      -- I Req. 87567 E1.1 ID 53 AVILCA 02/09/2020
        SELECT  TO_CHAR(f.cod_item_docu) cod_item_docu,--
                f.cod_gara cod_proceso,
                f.cod_soli_cred,
                f.cod_docu_eval,
                md.ind_oblig_gral ind_oblig ,-- I Req. 87567 E1.1 ID 53 AVILCA 03/02/2021
                f.txt_ruta_doc,
                f.cod_docu_eval||') '||(SELECT des_docu_eval FROM vve_cred_mae_docu d WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
                f.fec_doc fec_emis_doc,
                f.fec_reg_docu,
                f.cod_usua_crea_reg cod_usua_web,f.fec_modi_reg,f.cod_usua_modi_reg,
                (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) FROM vve_cred_mae_docu m WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
          FROM  vve_cred_soli_gara_docu f,vve_cred_mae_docu md
         WHERE  f.cod_soli_cred = p_cod_soli_cred
           AND  f.cod_gara = p_cod_proceso

           AND  md.ind_tipo_docu = p_ind_tipo_docu
           AND  md.ind_inactivo = 'N'
           AND f.cod_docu_eval = md.cod_docu_eval;
        -- F Req. 87567 E1.1 ID 53 AVILCA 02/09/2020    
    ELSIF (p_tipo_docu = 'A') THEN--documentos AVAL
    
   
    
        SELECT COUNT(1) INTO v_cantidad_registros FROM vve_cred_mae_aval_docu
                       WHERE cod_soli_cred = p_cod_soli_cred 
                         AND cod_per_aval = p_cod_proceso; 
                         
--        IF v_cantidad_registros=0 THEN
            INSERT INTO vve_cred_mae_aval_docu(
                        cod_docu_eval,cod_soli_cred,cod_per_aval,ind_tip_pers_aval,ind_est_civil,ind_oblig,txt_ruta_doc,fec_doc,
                        fec_reg_docu,cod_usua_crea_reg,fec_modi_reg,cod_usua_modi_reg
                        )
                 SELECT cod_docu_eval,p_cod_soli_cred,p_cod_proceso,p_cod_tipo_perso,p_cod_estado_civil,
                        /** I Req. 87567 E2.1 ID:126 - avilca 01/10/2020 **/
                       CASE 
                        WHEN p_ind_tipo_docu = 'AN' AND p_cod_estado_civil = 'C' AND  cod_docu_eval = '24' THEN 
                        'S' 
                       ELSE ind_oblig_gral
                       END,
                        /** I Req. 87567 E2.1 ID:126 - avilca 01/10/2020 **/
                       NULL,NULL,
                        SYSDATE,p_cod_usua_sid,NULL,NULL
                   FROM vve_cred_mae_docu
                  WHERE ind_tipo_docu = p_ind_tipo_docu
                  AND   cod_docu_eval not in (select cod_docu_eval from vve_cred_mae_aval_docu where cod_soli_cred = p_cod_soli_cred  and cod_per_aval = p_cod_proceso )
                  AND ind_inactivo = 'N';-- /** I Req. 87567 E2.1 ID:126 - avilca 28/08/2020 **/
                   
            COMMIT;            
--        END IF;
        
     
     
            OPEN p_ret_cursor FOR
            -- I Req. 87567 E1.1 ID 53 AVILCA 02/09/2020
            SELECT  '0'||rownum cod_item_docu,
                    f.cod_per_aval cod_proceso,
                    f.cod_soli_cred,
                    f.cod_docu_eval,     
                    CASE 
                     WHEN p_ind_tipo_docu = 'AN' AND f.ind_est_civil = 'C' AND f.cod_docu_eval = '24' THEN 
                      'S' 
                     ELSE md.ind_oblig_gral  --  Req. 87567 E1.1 ID 53 AVILCA 04/01/2021
                    END ind_oblig,
                    f.txt_ruta_doc,
                    f.cod_docu_eval||') '||(SELECT des_docu_eval FROM vve_cred_mae_docu d WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
                    f.fec_doc fec_emis_doc,
                    f.fec_reg_docu,
                    f.cod_usua_crea_reg cod_usua_web,f.fec_modi_reg,f.cod_usua_modi_reg,
                    (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) FROM vve_cred_mae_docu m WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
              FROM  vve_cred_mae_aval_docu f,vve_cred_mae_docu md
             WHERE  f.cod_soli_cred = p_cod_soli_cred
               AND  f.cod_per_aval = p_cod_proceso
               AND (p_cod_estado_civil is null or f.ind_est_civil = p_cod_estado_civil)
               AND  md.ind_tipo_docu = p_ind_tipo_docu
               AND  md.ind_inactivo = 'N'
               AND f.cod_docu_eval = md.cod_docu_eval;
        -- F Req. 87567 E1.1 ID 53 AVILCA 02/09/2020
     
      
    END IF;
    
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
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
    
    p_ret_mens := 'El documento se actualizo con éxito.'||p_ret_adve;
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
  
 /*-----------------------------------------------------------------------------
  Nombre : sp_list_docu_soli_combo
  Proposito : Lista tipo de documetos para adjuntar la socilicitud de credito
  Referencias : Para adjuntar archivos al proceso
  Log de Cambios
    Fecha        Autor         Descripcion
    13/04/2019   Dante Artica   Creado
  ----------------------------------------------------------------------------*/ 
  PROCEDURE sp_list_docu_soli_combo
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
     
  BEGIN
     OPEN p_ret_cursor FOR
     SELECT t.cod_soli_cred, 
       t.cod_docu_eval, 
       t.ind_oblig,
       '' txt_ruta_doc,
       rownum||') '|| t.des_docu_eval des_docu_eval,
        null fec_reg_docu,
        null fec_emis_doc,
        null cod_usua_web,
        null fec_modi_reg,
        null cod_usua_modi_reg,
        t.fec_min_vig,
        null COD_SEC_ARCHIVO,
        null TXT_DES_ARCHIVO    
 FROM (SELECT  distinct f.cod_soli_cred,
            f.cod_docu_eval,
            f.ind_oblig,
            (SELECT des_docu_eval 
            FROM vve_cred_mae_docu d 
            WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
            (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) 
            FROM vve_cred_mae_docu m 
            WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
      FROM  vve_cred_fina_docu f
      INNER JOIN vve_cred_mae_docu d on f.cod_docu_eval = d.cod_docu_eval --Req. 87567 E1.1 ID 53 AVILCA 03/07/2020
     WHERE  f.cod_soli_cred = p_cod_soli_cred
       AND d.ind_inactivo = 'N'--Req. 87567 E1.1 ID 53 AVILCA 03/07/2020
     order by cod_docu_eval asc) t;
     
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_list_docu_soli_combo:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_list_docu_soli_combo',
                                          '0',
                                          'Error en la consulta combo',
                                          p_ret_mens,
                                          NULL);

  END;
  /*-----------------------------------------------------------------------------
  Nombre : sp_lista_de_adjuntos_anteriores
  Proposito : Lista de adjuntos anteriores de la solicitud de credito
  Referencias : Para adjuntar archivos al proceso
  Log de Cambios
    Fecha        Autor         Descripcion
    13/04/2019   Dante Artica   Creado
  ----------------------------------------------------------------------------*/ 
  PROCEDURE sp_lista_adjuntos_anteriores
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
     
  BEGIN
     OPEN p_ret_cursor FOR
     SELECT k.cod_soli_cred, 
       k.cod_docu_eval, 
       k.ind_oblig,
       k.txt_ruta_doc,
       rownum||') '|| k.des_docu_eval des_docu_eval,
       k.fec_reg_docu,
       k.fec_emis_doc,
       k.cod_usua_crea_reg cod_usua_web,
       k.fec_modi_reg,
       k.cod_usua_modi_reg,
       k.fec_min_vig,
       k.COD_SEC_ARCHIVO,
       k.TXT_DES_ARCHIVO    
 FROM (
 select cod_soli_cred,cod_docu_eval,ind_oblig,
        txt_ruta_doc,COD_SEC_ARCHIVO,TXT_DES_ARCHIVO,
        fec_reg_docu,fec_emis_doc,cod_usua_crea_reg,
        fec_modi_reg,cod_usua_modi_reg,
        (SELECT des_docu_eval 
            FROM vve_cred_mae_docu d 
            WHERE d.cod_docu_eval=f.cod_docu_eval) des_docu_eval,
         (SELECT TRUNC(SYSDATE)-(m.val_dias_vig) 
            FROM vve_cred_mae_docu m 
            WHERE m.cod_docu_eval = f.cod_docu_eval) fec_min_vig
          from vve_cred_fina_docu f WHERE 
          f.txt_ruta_doc is not null and
          f.cod_soli_cred= (SELECT max(t.cod_soli_cred) FROM vve_cred_soli t WHERE 
          t.cod_clie=(SELECT cod_clie FROM vve_cred_soli t 
          WHERE t.cod_soli_cred=p_cod_soli_cred)
          AND t.cod_soli_cred<>p_cod_soli_cred)
          order by f.cod_docu_eval asc
           ) k;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_list_docu_soli_combo:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_list_docu_soli_combo',
                                          '0',
                                          'Error en la consulta combo',
                                          p_ret_mens,
                                          NULL);

  END;

END PKG_SWEB_CRED_SOLI_DOCUMENTO;