create or replace PACKAGE BODY   VENTA.PKG_SWEB_CRED_SOLI_ACTIVIDAD AS
 PROCEDURE sp_list_acti
 (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_act_actual        OUT vve_cred_maes_acti.des_acti_cred%TYPE,
    p_act_siguiente     OUT vve_cred_maes_acti.des_acti_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
 ) AS
    v_pendiente         vve_cred_soli_acti.cod_cred_soli_acti%TYPE;
    v_pendiente_gen     NUMBER;
 BEGIN
    p_ret_cantidad:= 0;
    v_pendiente:=1000;
    v_pendiente_gen:=1000;
    BEGIN
        SELECT MIN(vc1.cod_cred_soli_acti)
          INTO v_pendiente--, p_act_siguiente
          FROM vve_cred_soli_acti vc1
         WHERE vc1.cod_soli_cred=p_cod_soli_cred
           AND vc1.fec_usua_ejec IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_pendiente:= 1000;
    END;

    p_act_actual := '';
    BEGIN
        SELECT ma.des_acti_cred
          INTO p_act_actual
          FROM vve_cred_soli_acti vc2
    INNER JOIN vve_cred_maes_acti ma
            ON (vc2.cod_acti_cred=ma.cod_acti_cred)
         WHERE vc2.cod_soli_cred=p_cod_soli_cred
           AND vc2.cod_cred_soli_acti = (SELECT MAX(vc1.cod_cred_soli_acti)
                                           FROM vve_cred_soli_acti vc1
                                          WHERE vc1.cod_soli_cred=p_cod_soli_cred
                                            AND vc1.fec_usua_ejec IS NOT NULL);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_act_actual:= '';
    END;

    p_act_siguiente := '';
    BEGIN
        SELECT ma.des_acti_cred
          INTO p_act_siguiente
          FROM vve_cred_soli_acti vc2
    INNER JOIN vve_cred_maes_acti ma
            ON (vc2.cod_acti_cred=ma.cod_acti_cred)
         WHERE vc2.cod_soli_cred=p_cod_soli_cred
           AND vc2.cod_cred_soli_acti = (SELECT MIN(vc1.cod_cred_soli_acti)
                                           FROM vve_cred_soli_acti vc1
                                          WHERE vc1.cod_soli_cred=p_cod_soli_cred
                                            AND vc1.fec_usua_ejec IS NULL);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_act_siguiente:= '';
    END;

    BEGIN
        SELECT MIN(vve.orden)
          INTO v_pendiente_gen
          FROM (SELECT ROWNUM orden,vc1.fec_usua_ejec
                  FROM vve_cred_soli_acti vc1 
                INNER JOIN vve_cred_maes_acti cma 
                    ON vc1.cod_acti_cred=cma.cod_acti_cred
                WHERE vc1.cod_soli_cred=p_cod_soli_cred
                    AND cma.cod_etap_cred IS NULL) vve
         WHERE vve.fec_usua_ejec IS NULL;
         v_pendiente_gen:=v_pendiente_gen-1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_pendiente_gen:= 1000;
    END;


      OPEN p_ret_cursor FOR
    SELECT vc.cod_soli_cred,
           vc.cod_cred_soli_acti,
           vc.cod_acti_cred,
           vc.cod_usua_ejec,
           (CASE WHEN vm.cod_etap_cred IS NOT NULL THEN vc.fec_usua_ejec
            ELSE (CASE WHEN (SELECT COUNT(1)
                               FROM vve_cred_maes_acti ma
                         INNER JOIN vve_cred_soli_acti sa
                                 ON sa.cod_acti_cred=ma.cod_acti_cred
                              WHERE ma.cod_etap_cred = vc.cod_acti_cred
                                AND sa.cod_soli_cred = p_cod_soli_cred
                                AND fec_usua_ejec IS NULL)=0 THEN SYSDATE ELSE NULL END) END) fec_usua_ejec,
           /*vc.fec_usua_ejec,*/
           vc.cod_usua_crea_reg,
           vc.fec_crea_reg,
           vc.cod_usua_modi_reg,
           vc.fec_modi_reg,
           (SELECT cm.des_acti_cred FROM vve_cred_maes_acti cm WHERE cm.cod_acti_cred=vc.cod_acti_cred) AS des_acti_cred,
           v_pendiente AS cod_cred_soli_acti_pend,
           --NVL(vm.cod_etap_cred,vm.cod_acti_cred) AS cod_etap_cred_orden,
           NVL(TO_NUMBER(SUBSTR(vm.cod_etap_cred,2,LENGTH(vm.cod_etap_cred))),TO_NUMBER(SUBSTR(vm.cod_acti_cred,2,LENGTH(vm.cod_acti_cred)))) AS cod_etap_cred_orden,
           vm.cod_etap_cred,
           v_pendiente_gen AS pend_gen,
           (SELECT COUNT(1) 
              FROM vve_cred_rol_activ vcr 
             WHERE vcr.cod_acti_cred=vc.cod_acti_cred
               AND vcr.cod_rol_usuario IN (SELECT r.cod_rol_usuario 
              FROM sistemas.sis_mae_usuario u
             INNER JOIN sistemas.usuarios_rol_usuario r ON (u.txt_usuario=r.co_usuario)
             WHERE txt_usuario=p_cod_usua_sid)) AS CANT_ROLES
      FROM vve_cred_soli_acti vc, vve_cred_maes_acti vm
     WHERE vc.cod_soli_cred=p_cod_soli_cred
       AND vm.cod_acti_cred=vc.cod_acti_cred
       and vc.ind_inactivo = 'N'
  ORDER BY vm.num_orden;--cod_etap_cred_orden,cod_etap_cred desc, cod_cred_soli_acti asc;
     p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
   WHEN OTHERS THEN
      p_ret_esta := -1;
  END sp_list_acti;

 PROCEDURE sp_actu_acti 
 (      
   p_cod_soli_cred   IN   vve_cred_soli.cod_soli_cred%TYPE,
   p_etapa           IN   VARCHAR2, 
   p_acti            IN   VARCHAR2,
   p_cod_usua_sid    IN   sistemas.usuarios.co_usuario%TYPE,
   p_ret_esta        OUT  NUMBER,
   p_ret_mens        OUT  VARCHAR2
  )  
    AS
    v_num_acti       NUMBER :=0;
    v_num_acti_ejec  NUMBER :=0;
    v_tip_soli_cred  VARCHAR2(4);
    v_query1         VARCHAR2(1000);
    v_query2         VARCHAR2(1000);
    BEGIN    

      BEGIN
           v_query1:='';
           v_query2:='';

            UPDATE vve_cred_soli_acti
              SET FEC_USUA_EJEC = sysdate,
                  COD_USUA_EJEC = p_cod_usua_sid
            WHERE
                  COD_SOLI_CRED = p_cod_soli_cred AND 
                  COD_ACTI_CRED = p_acti;

            SELECT tip_soli_cred
             INTO v_tip_soli_cred
            FROM vve_cred_soli
            WHERE cod_soli_cred= p_cod_soli_cred;

        v_query1:= 'SELECT * FROM vve_cred_maes_acti WHERE cod_etap_cred ='''||p_etapa||'''
                      AND IND_'||v_tip_soli_cred||' IN (''S'',''X'')';

        v_query2:= 'SELECT * FROM vve_cred_soli_acti WHERE cod_soli_cred = '''||p_cod_soli_cred||'''
                     AND cod_acti_cred in (
                                           SELECT cod_acti_cred FROM vve_cred_maes_acti 
                                           WHERE cod_etap_cred ='''||p_etapa||'''
                                           AND IND_'||v_tip_soli_cred||' 
                                           IN (''S'',''X'') ) AND fec_usua_ejec IS NOT NULL
                                           ' ;


       EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || v_query1 || ')'
       INTO v_num_acti;

       EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || v_query2 || ')'
       INTO v_num_acti_ejec;

                IF v_num_acti = v_num_acti_ejec THEN        
                     UPDATE vve_cred_soli_acti 
                      SET cod_usua_ejec = p_cod_usua_sid,
                          fec_usua_ejec = SYSDATE
                     WHERE cod_soli_cred = p_cod_soli_cred AND 
                           cod_acti_cred = p_etapa;           
                END IF;

                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO',
                                                    'sp_actu_acti',
                                                    p_cod_usua_sid, v_query1 ||' '|| v_query2,
                                                    p_ret_mens ,
                                                    p_cod_soli_cred);

                p_ret_esta := 1;
                p_ret_mens := 'Se realizó la actualización de la etapa con éxito';


        EXCEPTION     
           WHEN OTHERS THEN
            p_ret_esta := 0;
            p_ret_mens := 'sp_actu_acti:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
                                                'sp_actu_acti',
                                                 p_cod_usua_sid, 
                                                 v_query1 ||' '|| v_query2, 
                                                 p_ret_mens,
                                                 p_cod_soli_cred);
        END;


    END sp_actu_acti;

END PKG_SWEB_CRED_SOLI_ACTIVIDAD; 
