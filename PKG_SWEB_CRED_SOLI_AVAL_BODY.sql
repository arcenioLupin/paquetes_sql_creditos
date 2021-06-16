create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_SOLI_AVAL AS 

PROCEDURE sp_list_aval
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
         OPEN p_ret_cursor FOR
         SELECT m.cod_per_aval,
                -- E2-1-87567-avilca-06/01/2020- Modficación Avales -Ini
                    CASE m.ind_esta_civil 
                         WHEN 'S' THEN  m.txt_doi
                         WHEN 'C' THEN ( m.txt_doi || '/' || (                          
                                    SELECT cma.txt_doi from vve_cred_mae_aval cma
                                     INNER JOIN vve_cred_soli_aval csa ON cma.cod_per_aval = csa.cod_per_aval
                                     WHERE cma.cod_per_rel_aval=m.cod_per_aval
                                     AND  cma.COD_RELA_AVAL = 'RAVAL02'
                                     AND  csa.ind_inactivo = 'N'
                                    )) 
                          ELSE ( m.txt_doi || '/' || (                          
                                    SELECT crma.txt_doi from vve_cred_mae_aval crma
                                    INNER JOIN vve_cred_soli_aval csa ON crma.cod_per_aval = csa.cod_per_aval
                                     WHERE crma.cod_per_aval=m.cod_per_aval
                                     AND  crma.COD_RELA_AVAL = 'RAVAL01'
                                     AND  csa.ind_inactivo = 'N'
                                    ))
                         END   txt_doi,
                -- E2-1-87567-avilca-06/01/2020- Modficación Avales -Fin
                m.ind_tipo_persona,
                m.ind_esta_civil,
                m.cod_rela_aval,
                m.cod_moneda,
                m.val_monto_fianza,
                m.txt_direccion,
                m.cod_distrito,
                m.cod_provincia,
                m.cod_departamento,
                m.cod_empr,
                m.cod_pais,
                m.cod_zona,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='105' AND valor_adic_1=m.ind_tipo_persona) des_tipo_persona,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='104' AND valor_adic_1=m.ind_esta_civil) des_estado_civil,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='110' AND valor_adic_1=m.ind_esta_civil) des_tipo_rela_aval,
                (SELECT mo.des_moneda AS descripcion FROM gen_moneda mo WHERE mo.cod_moneda=m.cod_moneda) des_moneda,
                --(SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito=cod_distrito) des_distrito,
                ---- E1-1-87567-avilca-07/07/2020- Modficación Avales -Ini
                (SELECT nom_ubigeo as descripcion   
                 FROM gen_ubigeo WHERE cod_dpto = m.cod_departamento and cod_provincia = m.cod_provincia 
                    and cod_distrito = m.cod_distrito)des_distrito,
                --(SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia=cod_provincia) des_provincia,
                 (SELECT nom_ubigeo as descripcion   
                  FROM gen_ubigeo WHERE cod_dpto = m.cod_departamento and cod_provincia = m.cod_provincia 
                    and cod_distrito = '00')des_provincia,
                --(SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento=cod_departamento) des_departamento,
                (SELECT nom_ubigeo as descripcion   
                  FROM gen_ubigeo WHERE cod_dpto = m.cod_departamento and cod_provincia = '00'
                    and cod_distrito = '00')des_departamento,
                '' des_empr, 
                --(SELECT nom_pais AS descripcion FROM gen_pais pa WHERE pa.cod_pais = m.cod_pais) des_pais,
                (SELECT nom_ubigeo as descripcion   
                  FROM gen_ubigeo WHERE cod_dpto = '00' and cod_provincia = '00'
                    and cod_distrito = '00')des_pais,
                ---- E1-1-87567-avilca-07/07/2020- Modficación Avales -Fin    
                '' des_zona, 
                ---- E2-1-87567-avilca-06/01/2020- Modficación Avales -Ini
                CASE m.ind_esta_civil WHEN 'S' THEN ( m.txt_nomb_pers||' '||m.txt_apel_pate_pers||' '||m.txt_apel_mate_pers)
                WHEN 'C' THEN ( m.txt_nomb_pers||' '||m.txt_apel_pate_pers||' '||m.txt_apel_mate_pers||
                 '/'||(SELECT cma.txt_nomb_pers||' '||cma.txt_apel_pate_pers||' '|| cma.txt_apel_mate_pers from vve_cred_mae_aval cma
                             INNER JOIN vve_cred_soli_aval csa ON cma.cod_per_aval = csa.cod_per_aval
                             WHERE cma.cod_per_rel_aval=m.cod_per_aval
                             AND  cma.COD_RELA_AVAL = 'RAVAL02'
                             AND  csa.ind_inactivo = 'N')) 
                ELSE ( m.txt_nomb_pers||' '||m.txt_apel_pate_pers||' '||m.txt_apel_mate_pers ||
                     '/'||(SELECT cma.txt_nomb_pers||' '||cma.txt_apel_pate_pers||' '|| cma.txt_apel_mate_pers from vve_cred_mae_aval cma
                             INNER JOIN vve_cred_soli_aval csa ON cma.cod_per_aval = csa.cod_per_aval
                             WHERE cma.cod_per_aval=m.cod_per_aval
                             AND  csa.ind_inactivo = 'N'
                             )) END  nombre_completo,                                
                -- E2-1-87567-avilca-06/01/2020- Modficación Avales -Fin             
                m.txt_nomb_pers,
                m.txt_apel_pate_pers,
                m.txt_apel_mate_pers,
                m.cod_per_rel_aval,
                m.cod_tipo_otor,
                m.txt_telefono ---- E2-1-87567-avilca-12/11/2020- Modficación Avales
           FROM vve_cred_mae_aval m 
      INNER JOIN vve_cred_soli_aval s
              ON m.cod_per_aval = s.cod_per_aval
            WHERE s.cod_soli_cred = p_cod_soli_cred
              AND (s.ind_inactivo IS NULL OR s.ind_inactivo <> 'S')
              --AND  m.cod_per_rel_aval IS NULL --//Req. 87567 E2.1 ID58 avilca 01/10/2020>
              ORDER BY m.cod_per_aval DESC; -- E2-1-87567-avilca-03/09/2020- Modficación Avales       
  p_ret_esta := 1;
  p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
     WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_aval:' || SQLERRM;
  END;
  
  
  PROCEDURE sp_list_aval_histo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
   
   v_cod_clie  VARCHAR2(10);
  BEGIN
   
    BEGIN
     SELECT cod_clie INTO v_cod_clie
      FROM vve_cred_soli
     WHERE cod_soli_cred = p_cod_soli_cred;
      EXCEPTION
     WHEN NO_DATA_FOUND THEN   
        v_cod_clie:= '1';
     END;
  
    OPEN p_ret_cursor FOR
    --<I Req. 87567 E2.1 ID 125 avilca 31/07/2020>
             SELECT a.cod_per_aval,
                a.txt_doi,
                a.ind_tipo_persona,
                a.ind_esta_civil,
                a.cod_rela_aval,
                a.cod_moneda,
                a.val_monto_fianza,
                a.txt_direccion,
                a.cod_distrito,
                a.cod_provincia,
                a.cod_departamento,
                a.cod_empr,
                a.cod_pais,
                a.cod_zona,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='105' AND valor_adic_1= a.ind_tipo_persona) des_tipo_persona,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='104' AND valor_adic_1= a.ind_esta_civil) des_estado_civil,
                (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='110' AND valor_adic_1= a.ind_esta_civil) des_tipo_rela_aval,
                (SELECT mo.des_moneda AS descripcion FROM gen_moneda mo WHERE mo.cod_moneda= a.cod_moneda) des_moneda,
                 ---- E1-1-87567-avilca-07/07/2020- Modficación Avales -Ini
               -- (SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito = a.cod_distrito) des_distrito,
                (SELECT nom_ubigeo as descripcion   
                 FROM gen_ubigeo WHERE cod_dpto = a.cod_departamento and cod_provincia = a.cod_provincia 
                    and cod_distrito = a.cod_distrito)des_distrito,               
                --(SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia = a.cod_provincia) des_provincia,
                (SELECT nom_ubigeo as descripcion   
                  FROM gen_ubigeo WHERE cod_dpto = a.cod_departamento and cod_provincia = a.cod_provincia 
                    and cod_distrito = '00')des_provincia,               
                --(SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento = a.cod_departamento) des_departamento,
                (SELECT nom_ubigeo as descripcion   
                  FROM gen_ubigeo WHERE cod_dpto = a.cod_departamento and cod_provincia = '00'
                    and cod_distrito = '00')des_departamento,     
                 ---- E1-1-87567-avilca-07/07/2020- Modficación Avales -Fin    
                '' des_empr, 
                --(SELECT nom_pais AS descripcion FROM gen_pais pa WHERE pa.cod_pais = a.cod_pais) des_pais,
                (SELECT pa.des_nombre FROM gen_mae_pais pa, gen_mae_sociedad so WHERE pa.cod_id_pais = so.cod_id_pais 
                    AND so.cod_cia IN (SELECT cod_cia FROM gen_mae_sociedad WHERE cod_id_pais = '001')
                    AND ROWNUM = 1) AS DES_PAIS,
                '' des_zona, 
                a.txt_nomb_pers||' '||a.txt_apel_pate_pers||' '||a.txt_apel_mate_pers nombre_completo,
                a.txt_nomb_pers,
                a.txt_apel_pate_pers,
                a.txt_apel_mate_pers,
                a.cod_per_rel_aval  
        FROM vve_cred_mae_aval a
        WHERE a.cod_per_aval IN
       (SELECT csa.cod_per_aval FROM vve_cred_soli_aval csa
           WHERE csa.cod_soli_cred IN
            (SELECT cs.cod_soli_cred FROM vve_cred_soli cs WHERE cs.cod_clie = v_cod_clie)
        )
        AND a.cod_per_rel_aval IS NULL
          AND 
          NOT EXISTS (SELECT 1 FROM vve_cred_soli_aval sav WHERE sav.cod_per_aval = a.cod_per_aval AND sav.cod_soli_cred = p_cod_soli_cred
          -- MBARDALES REQ. REGISTRO DE AVAL 14/01/21
          AND sav.ind_inactivo = 'N');
     
  p_ret_esta := 1;
  p_ret_mens := 'La consulta se realizó de manera exitosa';
  END sp_list_aval_histo;
  
  PROCEDURE sp_ins_aval
  (
     p_cod_soli_cred      vve_cred_soli_even.cod_soli_cred%TYPE,
     p_cod_per_aval       vve_cred_mae_aval.cod_per_aval%TYPE,
     p_ind_tipo_persona   vve_cred_mae_aval.ind_tipo_persona%TYPE,
     p_ind_estado_civil   vve_cred_mae_aval.ind_esta_civil%TYPE,
     p_cod_rela_aval      vve_cred_mae_aval.cod_rela_aval%TYPE,
     p_cod_moneda         vve_cred_mae_aval.cod_moneda%TYPE,
     p_val_monto_fianza   vve_cred_mae_aval.val_monto_fianza%TYPE,
     p_txt_direccion      vve_cred_mae_aval.txt_direccion%TYPE,
     p_cod_distrito       vve_cred_mae_aval.cod_distrito%TYPE,
     p_cod_provincia      vve_cred_mae_aval.cod_provincia%TYPE,
     p_cod_departamento   vve_cred_mae_aval.cod_departamento%TYPE,
     p_cod_empr           vve_cred_mae_aval.cod_empr%TYPE,
     p_cod_pais           vve_cred_mae_aval.cod_pais%TYPE,
     p_cod_zona           vve_cred_mae_aval.cod_zona%TYPE,
     p_txt_nomb_pers      vve_cred_mae_aval.txt_nomb_pers%TYPE,
     p_txt_apel_pate_pers vve_cred_mae_aval.txt_apel_pate_pers%TYPE,
     p_txt_apel_mate_pers vve_cred_mae_aval.txt_apel_mate_pers%TYPE,
     p_cod_per_rel_aval   vve_cred_mae_aval.cod_per_rel_aval%TYPE,
     p_txt_doi            vve_cred_mae_aval.txt_doi%TYPE,
     p_ava_histo          VARCHAR2,
     p_cod_tipo_otor      vve_cred_mae_aval.cod_tipo_otor%TYPE,
     p_txt_telefono       vve_cred_mae_aval.txt_telefono%TYPE,--// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
     p_flag_coprop_eli    VARCHAR2,
     p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_cod_per_aval_ret   OUT VARCHAR2,
     p_ret_esta           OUT NUMBER,
     p_ret_mens           OUT VARCHAR2
  ) AS
    v_cod_aval_seq   NUMBER(10);
    v_cod_per_aval   vve_cred_mae_aval.cod_per_aval%TYPE;
    v_cod_usua_regi  sis_mae_usuario.txt_usuario%TYPE;
    kc_pais_peru     sis_mae_usuario.cod_id_pais%type := '001';
    v_existe_aval    NUMBER(1);
  
  BEGIN
  
   -- I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
    SELECT txt_usuario INTO v_cod_usua_regi FROM sis_mae_usuario WHERE COD_ID_USUARIO = p_cod_usua_web AND cod_id_pais = kc_pais_peru;
   -- F Req. 87567 E1.1 ID 53 AVILCA 12/11/2020  
    
    IF(p_ava_histo = 'N') THEN
        IF (p_cod_per_aval IS NULL) THEN
            SELECT SEQ_CRED_SOLI_AVAL.NEXTVAL
              INTO v_cod_aval_seq
              FROM DUAL;
           
             SELECT LPAD(v_cod_aval_seq,8,'0')
               INTO v_cod_per_aval
               FROM DUAL;
               
        
            p_cod_per_aval_ret := v_cod_per_aval;
            INSERT INTO vve_cred_mae_aval (
                cod_per_aval,
                ind_tipo_persona,
                ind_esta_civil,
                cod_rela_aval,
                cod_moneda,
                val_monto_fianza,
                txt_direccion,
                cod_distrito,
                cod_provincia,
                cod_departamento,
                cod_empr,
                cod_pais,
                cod_zona,
                txt_nomb_pers,
                txt_apel_pate_pers,
                txt_apel_mate_pers,
                cod_per_rel_aval,
                txt_doi,
                cod_usua_crea_regi,
                fec_crea_regi,
                cod_tipo_otor,
                txt_telefono  --// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
            ) VALUES (
                v_cod_per_aval,
                p_ind_tipo_persona,
                p_ind_estado_civil,
                p_cod_rela_aval,
                p_cod_moneda,
                p_val_monto_fianza,
                p_txt_direccion,
                p_cod_distrito,
                p_cod_provincia,
                p_cod_departamento,
                p_cod_empr,
                p_cod_pais,
                p_cod_zona,
                p_txt_nomb_pers,
                p_txt_apel_pate_pers,
                p_txt_apel_mate_pers,
                p_cod_per_rel_aval,
                p_txt_doi,
                v_cod_usua_regi, --p_cod_usua_web,
                SYSDATE,
                p_cod_tipo_otor,
                p_txt_telefono --// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
            );
            
            INSERT INTO vve_cred_soli_aval (
                cod_soli_cred,
                cod_per_aval,
                ind_inactivo,
                cod_usua_crea_regi,
                fec_crea_regi,
                cod_usua_modi_regi
            ) VALUES (
                p_cod_soli_cred,
                v_cod_per_aval,
                'N',
                v_cod_usua_regi, --p_cod_usua_web,
                SYSDATE,
                NULL
            );
            

        ELSE
             p_cod_per_aval_ret := p_cod_per_aval;
             UPDATE vve_cred_mae_aval
                SET ind_tipo_persona = p_ind_tipo_persona,
                    ind_esta_civil = p_ind_estado_civil,
                    cod_rela_aval = p_cod_rela_aval,
                    cod_moneda = p_cod_moneda,
                    val_monto_fianza = p_val_monto_fianza,
                    txt_direccion = p_txt_direccion,
                    cod_distrito = p_cod_distrito,
                    cod_provincia = p_cod_provincia,
                    cod_departamento = p_cod_departamento,
                    cod_empr = p_cod_empr,
                    cod_pais = p_cod_pais,
                    cod_zona = p_cod_zona,
                    txt_nomb_pers = p_txt_nomb_pers,
                    txt_apel_pate_pers = p_txt_apel_pate_pers,
                    txt_apel_mate_pers = p_txt_apel_mate_pers,
                    txt_doi = p_txt_doi,
                    cod_usua_modi_regi = v_cod_usua_regi,--// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
                    fec_modi_regi = SYSDATE,
                    cod_tipo_otor = p_cod_tipo_otor,
                    txt_telefono = p_txt_telefono --// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
              WHERE cod_per_aval = p_cod_per_aval;
              
              IF (p_flag_coprop_eli = 'S') THEN
                UPDATE vve_cred_soli_aval 
                SET ind_inactivo = 'S'
                WHERE cod_soli_cred = p_cod_soli_cred
                 AND cod_per_aval = p_cod_per_aval;
              
              END IF;

        END IF;
        
    ELSE
        
        -- MBARDALES REQ. REGISTRO AVAL 14/01/2021
        BEGIN 
          SELECT 1 INTO v_existe_aval FROM vve_cred_soli_aval where cod_soli_cred = p_cod_soli_cred and cod_per_aval = p_cod_per_aval and ind_inactivo = 'S';
          EXCEPTION WHEN NO_DATA_FOUND THEN
          v_existe_aval := 0;
        END;
        
        -- MBARDALES REQ. REGISTRO AVAL 14/01/2021
        IF v_existe_aval = 0 THEN 
          INSERT INTO vve_cred_soli_aval (
                  cod_soli_cred,
                  cod_per_aval, 
                  ind_inactivo,
                  cod_usua_crea_regi,
                  fec_crea_regi,
                  cod_usua_modi_regi
              ) VALUES (
                  p_cod_soli_cred,
                  p_cod_per_aval,
                  'N',
                  v_cod_usua_regi,--// I Req. 87567 E1.1 ID 53 AVILCA 12/11/2020
                  SYSDATE,
                  NULL
              );
              
        FOR rs IN (select cod_per_aval from vve_cred_mae_aval where cod_per_rel_aval = p_cod_per_aval) LOOP
              INSERT INTO vve_cred_soli_aval (
                  cod_soli_cred,
                  cod_per_aval, 
                  ind_inactivo,
                  cod_usua_crea_regi,
                  fec_crea_regi,
                  cod_usua_modi_regi
              ) VALUES (
                  p_cod_soli_cred,
                  rs.cod_per_aval,
                  'N',
                  v_cod_usua_regi,
                  SYSDATE,
                  NULL
              );
        END LOOP;
        
        -- MBARDALES REQ. REGISTRO AVAL 14/01/2021
        ELSE 
          UPDATE vve_cred_soli_aval SET ind_inactivo = 'N' where cod_soli_cred = p_cod_soli_cred and cod_per_aval = p_cod_per_aval;
          FOR rs IN (select distinct sa.cod_per_aval from vve_cred_soli_aval sa inner join vve_cred_mae_aval ma on sa.cod_per_aval = ma.cod_per_aval
                    where ma.cod_per_rel_aval = p_cod_per_aval) LOOP
            UPDATE vve_cred_soli_aval SET ind_inactivo = 'N' where cod_soli_cred = p_cod_soli_cred and cod_per_aval = rs.cod_per_aval;
          END LOOP;
        END IF;
        
    END IF;
  
  
    p_ret_mens := 'El aval se actualizo con exito.';
    p_ret_esta := 1;
    -- Actualizando fecha de ejecución de registro y verificando cierre de etapa
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A11',p_cod_usua_sid,p_ret_esta,p_ret_mens); 
    COMMIT;      
  EXCEPTION
    WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'sp_ins_aval:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_ins_aval',
                                              'sp_ins_aval',
                                              SQLERRM,
                                              p_ret_mens,
                                              p_cod_soli_cred);
          ROLLBACK;
  END;
  
  PROCEDURE sp_eli_aval_soli
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_tipo              IN VARCHAR2,
     p_list_aval_vig     IN VARCHAR2,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  ) AS
     v_cursor SYS_REFCURSOR;
     v_cod_garantia VARCHAR2(500);
  BEGIN
    IF p_tipo = '0' THEN
        IF (p_list_aval_vig IS NULL OR p_list_aval_vig='') THEN
            UPDATE vve_cred_soli_aval s
               SET s.ind_inactivo = 'S', s.cod_usua_modi_regi = p_cod_usua_web
             WHERE s.cod_soli_cred = p_cod_soli_cred
               AND EXISTS(SELECT 1 FROM vve_cred_mae_aval m
                           WHERE s.cod_per_aval=m.cod_per_aval
                             AND m.cod_per_rel_aval IS NULL);
              
        ELSE
            UPDATE vve_cred_soli_aval s
               SET s.ind_inactivo = 'S'
             WHERE s.cod_per_aval NOT IN (SELECT column_value FROM table(fn_varchar_to_table(p_list_aval_vig)))
               AND s.cod_soli_cred = p_cod_soli_cred
               AND EXISTS(SELECT 1 FROM vve_cred_mae_aval m 
                           WHERE s.cod_per_aval=m.cod_per_aval
                             AND m.cod_per_rel_aval IS NULL);
              
        END IF;
    ELSE
        IF (p_list_aval_vig IS NULL OR p_list_aval_vig='') THEN
            UPDATE vve_cred_soli_aval s
               SET s.ind_inactivo = 'S'
             WHERE s.cod_soli_cred = p_cod_soli_cred
               AND EXISTS(SELECT 1
                            FROM vve_cred_mae_aval m
                           WHERE s.cod_per_aval=m.cod_per_aval
                             AND m.cod_per_rel_aval IS NOT NULL);
        ELSE
            UPDATE vve_cred_soli_aval s
               SET s.ind_inactivo = 'S'
             WHERE s.cod_per_aval IN (SELECT column_value FROM table(fn_varchar_to_table(p_list_aval_vig)))
               AND s.cod_soli_cred = p_cod_soli_cred
               AND EXISTS(SELECT 1
                            FROM vve_cred_mae_aval m
                           WHERE s.cod_per_aval=m.cod_per_aval
                             AND m.cod_per_rel_aval IS NOT NULL);                             
               
        END IF;
    END IF;
    
    UPDATE vve_cred_soli_aval s
       SET ind_inactivo = 'S'
     WHERE s.cod_per_aval IN (SELECT m.cod_per_aval 
                                FROM vve_cred_mae_aval m
                               WHERE m.cod_per_rel_aval IS NOT NULL 
                                 AND m.cod_per_rel_aval IN (SELECT cod_per_aval
                                                              FROM vve_cred_soli_aval
                                                             WHERE ind_inactivo='S'));
    
  
    COMMIT;     
    p_ret_esta := 1;
    p_ret_mens := 'La transaccion se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_ACTU_SEG_SOL_EXCEP:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_ins_aval',
                                              'sp_ins_aval',
                                              'Error al actualizar el aval',
                                              p_ret_mens,
                                              p_cod_soli_cred);
          ROLLBACK;
  END sp_eli_aval_soli;
  
  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_PAIS
  Proposito : Listar los paises
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_cia -> codigo de la compañía]
  Log de Cambios
    Fecha        Autor         Descripcion
    22/02/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_paises(
    p_cod_cia           IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      --select * from generico.gen_mae_pais;
      SELECT pa.cod_id_pais AS cod_pais, pa.des_nombre AS nom_pais FROM gen_mae_pais pa, gen_mae_sociedad so WHERE pa.cod_id_pais = so.cod_id_pais AND so.cod_cia = p_cod_cia;
      --select * from gen_mae_sociedad;
      --SELECT '001' cod_pais,'PERU' nom_pais FROM DUAL;
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_paises;
  
  
  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_DEPARTAMENTOS
  Proposito : Listar los departamentos
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_pais -> codigo del pais]
  Log de Cambios
    Fecha        Autor         Descripcion
    22/02/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_departamentos(
    p_cod_pais          IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_departamento,des_nombre FROM gen_mae_departamento WHERE cod_id_pais = p_cod_pais ORDER BY cod_id_departamento ASC;
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_departamentos;
  
 /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_PROVINCIAS
  Proposito : Listar los provincias
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_depa -> codigo del departamento]
  Log de Cambios
    Fecha        Autor         Descripcion
    22/02/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_provincias
  (
    p_cod_depa          IN gen_mae_departamento.cod_id_departamento%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_provincia,des_nombre FROM gen_mae_provincia WHERE cod_id_departamento = p_cod_depa ORDER BY cod_id_provincia;

    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_provincias:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_provincias;
  
  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_DISTRITOS
  Proposito : Listar los distritos
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_depa -> codigo del departamento]
               [p_cod_prov -> codigo de la provincia]
  Log de Cambios
    Fecha        Autor         Descripcion
    22/02/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_distritos
  (
    p_cod_prov          IN gen_mae_distrito.cod_id_provincia%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_distrito,des_nombre FROM gen_mae_distrito WHERE cod_id_provincia = p_cod_prov ORDER BY cod_id_distrito ASC;

    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_distritos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_distritos;
  
  /*-----------------------------------------------------------------------------
  Nombre : SP_ELI_BY_AVAL
  Proposito : Eliminar Aval
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_soli_cred -> codigo de la solicitud credito]
               [p_cod_per_aval -> codigo del aval]
  Log de Cambios
    Fecha        Autor         Descripcion
    27/02/2019   jaltamirano   Creacion
    04/09/2020   AVILCA        Modificación
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_eli_by_aval
  (
     p_cod_soli_cred     IN vve_cred_soli_aval.cod_soli_cred%TYPE,
     p_cod_per_aval      IN vve_cred_mae_aval.cod_per_aval%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    UPDATE vve_cred_soli_aval s SET s.ind_inactivo = 'S' 
     WHERE s.cod_soli_cred = p_cod_soli_cred 
       AND s.cod_per_aval IN (SELECT xx.cod_per_aval FROM (
           (SELECT m.cod_per_aval FROM vve_cred_mae_aval m WHERE m.cod_per_aval = s.cod_per_aval 
               AND (m.cod_per_aval = p_cod_per_aval or m.cod_per_rel_aval = p_cod_per_aval)) xx));
        --<I Req. 87567 E2.1 ID 131 avilca 04/09/2020>         
        -- Actualizando fecha de ejecución de registro y verificando cierre de etapa
          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A11',p_cod_usua_sid,p_ret_esta,p_ret_mens); 
        --<F Req. 87567 E2.1 ID 131 avilca 04/09/2020>  
    COMMIT;     
    p_ret_esta := 1;
    p_ret_mens := 'El aval se eliminó con exito.';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
          p_ret_mens := 'SP_ACTU_SEG_SOL_EXCEP:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_eli_by_aval',
                                              'sp_eli_by_aval',
                                              'Error al eliminar el aval',
                                              p_ret_mens,
                                              p_cod_soli_cred);
          ROLLBACK;
  END sp_eli_by_aval;
  
END;