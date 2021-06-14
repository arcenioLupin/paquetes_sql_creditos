create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_SOLI_LEGAL IS

/*-----------------------------------------------------------------------------
    Nombre : sp_listar_sol_legal
    Proposito : Lista todas las solicitudes de legal 
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     12/03/2019   MGRASSO  
     17/01/2020   AVILCA         Req. 87567 E2.1 ID:119 
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_SOL_LEGAL
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_nro_expediente    IN gen_solicitud_credito.nro_expediente%TYPE,
    p_nom_perso         IN gen_persona.nom_perso%TYPE,
    p_cod_estleg        IN gen_estado_legal.cod_estleg%TYPE,
    p_no_cia            IN arcgmc.no_cia%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
        select gs.cod_solcre,
            s.cod_soli_cred,
            gs.nro_expediente,
            ge.descripcion,
            a.nombre, 
            p.nom_perso,
            (case p.cod_tipo_perso when 'J' then 'JURÍDICA' when 'N' then 'NATURAL' end) AS TIPOPERSONA,
            TO_CHAR(gs.fecha_revision, 'DD/MM/YYYY') AS fecha_revision, 
            TO_CHAR(gs.fecha_caduca, 'DD/MM/YYYY') AS fecha_caduca
        from gen_solicitud_credito gs
        inner join vve_cred_soli s
        on s.cod_solcre_legal=gs.cod_solcre
        inner join gen_persona p
        on gs.cod_clie=p.cod_perso
        inner join arcgmc a
        on gs.no_cia=a.no_cia
        inner join gen_estado_legal ge
        on ge.cod_estleg=gs.cod_estleg
        where gs.ind_inactivo ='N' and a.ind_regi_visi = 'S'
        and (p_cod_soli_cred is null or s.cod_soli_cred like '%'||p_cod_soli_cred)--Req. 87567 E2.1 ID:119 
        and (p_cod_solcre is null or gs.cod_solcre like '%'||p_cod_solcre||'%')
        and (p_nro_expediente is null or gs.nro_expediente like '%'||p_nro_expediente||'%')
        and (p_nom_perso is null or p.nom_perso like '%'||p_nom_perso||'%')
        and (p_cod_estleg is null or gs.cod_estleg = p_cod_estleg)
        and (p_no_cia is null or gs.no_cia = p_no_cia);
        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listar_sol_legal:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOC_LEGALES
    Proposito : Lista documentos legales
    Referencias : 
    Parametros :
 Log de Cambios 
      Fecha        Autor         Descripcion
     15/03/2019   MGRASSO  
	 13/01/2020   AVILCA        Modificación mostrar todos los docs 
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOC_LEGALES
  (
    p_cod_solcre    IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ord_titdoc    IN  gen_titulo_documento.ord_titdoc%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS 
  v_num_checks NUMBER :=0;
  BEGIN
        SELECT count(f.ind_oblig)
         INTO v_num_checks
        FROM gen_documento_legal l,vve_cred_fina_docu f, vve_cred_mae_docu d
        WHERE l.ind_inactivo='N' 
        and l.cod_titdoc in
        (select cod_titdoc 
        from gen_titulo_documento a
        where ord_titdoc=p_ord_titdoc)
        and l.cod_docleg = d.cod_docleg
        and f.cod_docu_eval = d.cod_docu_eval 
        and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
        and d.ind_inactivo = 'N'
        order by l.cod_docleg;
        
        IF v_num_checks = 0 THEN
           OPEN p_ret_cursor FOR
              SELECT cod_docleg,descripcion,'N' ind_oblig 
              FROM gen_documento_legal
              WHERE cod_titdoc = p_ord_titdoc;
              p_ret_esta := 1;
              p_ret_mens := 'La consulta se realizó de manera exitosa';
        ELSE
             OPEN p_ret_cursor FOR
                SELECT l.cod_docleg,l.descripcion,f.ind_oblig 
                FROM gen_documento_legal l,vve_cred_fina_docu f, vve_cred_mae_docu d
                WHERE l.ind_inactivo='N' 
                and l.cod_titdoc in
                (select cod_titdoc 
                from gen_titulo_documento a
                where ord_titdoc=p_ord_titdoc)
                and l.cod_docleg = d.cod_docleg
                and f.cod_docu_eval = d.cod_docu_eval 
                and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
                and d.ind_inactivo = 'N'
                order by cod_docleg;
                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';
        
        END IF;
        
 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_DOC_LEGALES:' || SQLERRM;
  END;

/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOC_GARANTIA
    Proposito : Lista documentos garantias
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     15/03/2019   MGRASSO  
     13/01/2020   AVILCA         Modificación listar todos los docs
     17/01/2020   LR             Modificación listar todos los docs
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOC_GARANTIA
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ord_titdoc    IN  gen_titulo_documento.ord_titdoc%TYPE,
    p_ind_tipo_docu IN vve_cred_mae_docu.ind_tipo_docu%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  v_num_checks NUMBER :=0;
  v_cant_gara  NUMBER :=0; --<E2.1 ID 224 LR 17.01.2020>
  BEGIN
        SELECT  count(f.ind_oblig) 
        INTO v_num_checks
        FROM gen_documento_legal l,vve_cred_soli_gara_docu f, vve_cred_mae_docu d
        WHERE l.ind_inactivo='N' 
        and l.cod_titdoc in
        (select cod_titdoc 
        from gen_titulo_documento a
        where ord_titdoc=p_ord_titdoc)
        and l.cod_docleg = d.cod_docleg
        and f.cod_docu_eval = d.cod_docu_eval 
        and d.ind_tipo_docu = p_ind_tipo_docu
        and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
        order by l.cod_docleg;
        
        IF v_num_checks = 0 THEN
            select count(sg.cod_gara)  
            into v_cant_gara 
            from vve_cred_soli_gara sg, vve_cred_maes_gara mg 
            where sg.cod_soli_cred IN (select s.cod_soli_cred from vve_cred_soli s where s.cod_solcre_legal = p_cod_solcre) 
            and   sg.cod_gara = mg.cod_garantia 
            and   sg.ind_gara_adic = 'S' 
            and   mg.ind_tipo_garantia = decode(p_ord_titdoc,5,'M',4,'H');

            OPEN p_ret_cursor FOR
              --<I E2.1 ID 224 LR 17.01.2020>
              /*SELECT cod_docleg,descripcion,'N' ind_oblig 
              FROM gen_documento_legal
              WHERE cod_titdoc = p_ord_titdoc;
              p_ret_esta := 1;
              p_ret_mens := 'La consulta se realizó de manera exitosa';*/
              SELECT  l.cod_docleg,l.descripcion,decode(v_cant_gara,0,'N',d.ind_oblig_gral) ind_oblig 
              FROM    gen_documento_legal l, vve_cred_mae_docu d
              WHERE   l.ind_inactivo='N' 
              and     l.cod_titdoc in
                                  (select cod_titdoc 
                                   from   gen_titulo_documento a
                                   where  ord_titdoc = p_ord_titdoc)
              and l.cod_docleg = d.cod_docleg 
              and d.ind_tipo_docu = p_ind_tipo_docu
              order by l.cod_docleg;

              p_ret_esta := 1;
              p_ret_mens := 'La consulta se realizó de manera exitosa';
              --<F E2.1 ID 224 LR 17.01.2020>
        ELSE
             OPEN p_ret_cursor FOR
                SELECT  l.cod_docleg,l.descripcion,f.ind_oblig 
                FROM gen_documento_legal l,vve_cred_soli_gara_docu f, vve_cred_mae_docu d
                WHERE l.ind_inactivo='N' 
                and l.cod_titdoc in
                (select cod_titdoc 
                from gen_titulo_documento a
                where ord_titdoc=p_ord_titdoc)
                and l.cod_docleg = d.cod_docleg
                and f.cod_docu_eval = d.cod_docu_eval 
                and d.ind_tipo_docu = p_ind_tipo_docu
                and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
                order by l.cod_docleg;
                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';     
        END IF;    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_DOC_GARANTIA:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
        Nombre : SP_LISTAR_DOC_AVALES
        Proposito : Lista documentos avales
        Referencias : 
        Parametros :
        Log de Cambios 
          Fecha        Autor         Descripcion
         15/03/2019   MGRASSO  
		 13/01/2020   AVILCA         Modificación listar todos los docs
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOC_AVALES
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ord_titdoc    IN  gen_titulo_documento.ord_titdoc%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
    v_num_checks NUMBER :=0;
    BEGIN
    
        SELECT  COUNT(f.ind_oblig)
         INTO v_num_checks
        FROM gen_documento_legal l,vve_cred_mae_aval_docu f, vve_cred_mae_docu d
        WHERE l.ind_inactivo='N' 
        and l.cod_titdoc in
        (select cod_titdoc 
        from gen_titulo_documento a
        where ord_titdoc=p_ord_titdoc)
        and l.cod_docleg = d.cod_docleg
        and f.cod_docu_eval = d.cod_docu_eval 
        and d.ind_tipo_docu = 'AN'
        and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
        order by l.cod_docleg;
        
        IF v_num_checks = 0 THEN
            OPEN p_ret_cursor FOR
              SELECT cod_docleg,descripcion,'N' ind_oblig 
              FROM gen_documento_legal
              WHERE cod_titdoc = p_ord_titdoc;
              p_ret_esta := 1;
              p_ret_mens := 'La consulta se realizó de manera exitosa';
        ELSE
            OPEN p_ret_cursor FOR
                SELECT  l.cod_docleg,l.descripcion,f.ind_oblig
                FROM gen_documento_legal l,vve_cred_mae_aval_docu f, vve_cred_mae_docu d
                WHERE l.ind_inactivo='N' 
                and l.cod_titdoc in
                (select cod_titdoc 
                from gen_titulo_documento a
                where ord_titdoc=p_ord_titdoc)
                and l.cod_docleg = d.cod_docleg
                and f.cod_docu_eval = d.cod_docu_eval 
                and d.ind_tipo_docu = 'AN'
                and f.cod_soli_cred = (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre)
                order by cod_docleg;
                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';
        
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_DOC_AVALES:' || SQLERRM;
  END;

/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_EST_LEGAL
    Proposito : Lista estados legales
    Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 18/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_EST_LEGAL(
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
    select cod_Estleg, descripcion from gen_estado_legal
    order by descripcion asc;
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_EST_LEGAL:' || SQLERRM;
    
  END;
  
/*-----------------------------------------------------------------------------
    Nombre : SP_ACTUALIZAR_CHKLIST_DOC_LEGALES
    Proposito : Actualizar checklist_
    Referencias : 
    Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 19/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_ACTUALIZAR_CHK_DOC_LEGALES
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg   IN  gen_documento_legal.COD_DOCLEG%TYPE,
    p_ind_oblig    IN  vve_cred_fina_docu.ind_oblig%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,   
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
    v_cod_soli_cred     vve_cred_soli.cod_soli_cred%TYPE;
    v_cod_docu_eval     vve_cred_mae_docu.cod_docu_eval%TYPE;    
  BEGIN
    SELECT cod_soli_cred 
    INTO v_cod_soli_cred
    FROM vve_cred_soli 
    WHERE cod_solcre_legal=p_cod_solcre;
    
    SELECT cod_docu_eval 
    INTO v_cod_docu_eval
    FROM vve_cred_mae_docu 
    WHERE cod_docleg=p_cod_docleg
        AND ROWNUM = 1;    
  
    UPDATE vve_cred_fina_docu
        SET IND_OBLIG=p_ind_oblig,
            cod_usua_modi_reg=p_cod_usua_web,
            fec_modi_reg=SYSDATE        
    WHERE cod_docu_eval=v_cod_docu_eval
    AND COD_SOLI_CRED=v_cod_soli_cred;
    
    COMMIT;
    
    p_ret_mens := 'Se actualizó el chklist con éxito';
    p_ret_esta := 1;
    
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_LEGALES:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_ACTUALIZAR_CHK_DOC_LEGALES',
                                                p_cod_usua_sid,
                                                'Error al actualizar checklist documentos legales',
                                                p_ret_mens,
                                                p_cod_solcre);              
            ROLLBACK;
  END;

 /*-----------------------------------------------------------------------------
Nombre : SP_ACTUALIZAR_CHK_DOC_GARA
Proposito : Actualizar checklist
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 19/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_ACTUALIZAR_CHK_DOC_GARA
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg   IN  gen_documento_legal.COD_DOCLEG%TYPE,
    p_ind_oblig    IN  vve_cred_soli_gara_docu.ind_oblig%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,  
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
    v_cod_soli_cred     vve_cred_soli.cod_soli_cred%TYPE;
    v_cod_docu_eval     vve_cred_mae_docu.cod_docu_eval%TYPE;  
  BEGIN
    SELECT cod_soli_cred 
    INTO v_cod_soli_cred
    FROM vve_cred_soli 
    WHERE cod_solcre_legal=p_cod_solcre;
    
    SELECT cod_docu_eval 
    INTO v_cod_docu_eval
    FROM vve_cred_mae_docu 
    WHERE cod_docleg=p_cod_docleg
        AND ROWNUM = 1;  
  
    UPDATE vve_cred_soli_gara_docu
        SET IND_OBLIG=p_ind_oblig,
            cod_usua_modi_reg=p_cod_usua_web,
            fec_modi_reg=SYSDATE
    WHERE cod_docu_eval=v_cod_docu_eval
    AND COD_SOLI_CRED=v_cod_soli_cred;
    
    COMMIT;
    
    p_ret_mens := 'Se actualizó el chklist con éxito';
    p_ret_esta := 1;
    
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_GARA:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_ACTUALIZAR_CHK_DOC_GARA',
                                                p_cod_usua_sid,
                                                'Error al actualizar checklist documentos garantía',
                                                p_ret_mens,
                                                p_cod_solcre);            
          ROLLBACK;
  END;

   /*-----------------------------------------------------------------------------
Nombre : SP_ACTUALIZAR_CHK_DOC_AVAL
Proposito : Actualizar checklist
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 19/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_ACTUALIZAR_CHK_DOC_AVAL
  (
    p_cod_solcre     IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg     IN  gen_documento_legal.COD_DOCLEG%TYPE,
    p_ind_oblig      IN  vve_cred_mae_aval_docu.ind_oblig%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,   
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
    v_cod_soli_cred     vve_cred_soli.cod_soli_cred%TYPE;
    v_cod_docu_eval     vve_cred_mae_docu.cod_docu_eval%TYPE;
  BEGIN   
    SELECT cod_soli_cred 
    INTO v_cod_soli_cred
    FROM vve_cred_soli 
    WHERE cod_solcre_legal=p_cod_solcre;
    
    SELECT cod_docu_eval 
    INTO v_cod_docu_eval
    FROM vve_cred_mae_docu 
    WHERE cod_docleg=p_cod_docleg
        AND ROWNUM = 1;
        
    UPDATE vve_cred_mae_aval_docu
        SET IND_OBLIG=p_ind_oblig,
            cod_usua_modi_reg=p_cod_usua_web,
            fec_modi_reg=SYSDATE
    WHERE cod_docu_eval=v_cod_docu_eval
    AND COD_SOLI_CRED=v_cod_soli_cred;    
          
    COMMIT;
    
    p_ret_mens := 'Se actualizó el chklist con éxito';
    p_ret_esta := 1;
    
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_AVAL:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_ACTUALIZAR_CHK_DOC_AVAL',
                                                p_cod_usua_sid,
                                                'Error al actualizar checklist documentos aval',
                                                p_ret_mens,
                                                p_cod_solcre);            
            ROLLBACK;
  END;

   /*-----------------------------------------------------------------------------
Nombre : SP_ACTUALIZAR_EST_LEGAL
Proposito : Actualizar estado de solicitud legal
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 19/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_ACTUALIZAR_EST_LEGAL
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_estleg     IN  gen_solicitud_credito.cod_estleg%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
        UPDATE gen_solicitud_credito
        SET COD_ESTLEG=p_cod_estleg,
            FEC_MODI_REG=sysdate
        WHERE COD_SOLCRE=p_cod_solcre;
        COMMIT;
    p_ret_mens := 'Se actualizó el estado de la solicitud legal con exito';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_EST_LEGAL:' || SQLERRM;
      ROLLBACK;
  END;
 
   /*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_OPERACION_CLIENTE
Proposito : Listar la operación y cliente
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 22/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_OPERACION_CLIENTE
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
        open p_ret_cursor for
            select gp.nom_perso,top.descripcion
            from gen_plantilla_operacion p, 
            gen_tipo_operacion top, 
            gen_solicitud_credito sc, 
            gen_persona gp
            where p.cod_estope = sc.cod_estope
            and p.ind_inactivo = 'N'  
            and top.cod_tipope = p.cod_tipope
            and gp.cod_perso=sc.cod_clie
            and sc.cod_solcre=p_cod_solcre;
            p_ret_mens := 'La consulta se realizó correctamente!';
            p_ret_esta := 1;
            EXCEPTION
            WHEN OTHERS THEN
              p_ret_esta := -1;
              p_ret_mens := 'SP_LISTAR_OPERACION_CLIENTE:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_PERSONAS_FACULTADAS
Proposito : Listar las personas facultadas
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 22/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_PERSONAS_FACULTADAS
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
        open p_ret_cursor for
            SELECT FDR.CARGO, FDR.NOMBRE, FDR.DOI
            FROM GEN_SOLICITUD_CREDITO SC
            INNER JOIN GEN_DOCUMENTO_REVISION DR
            ON SC.COD_SOLCRE=DR.COD_SOLCRE
            INNER JOIN GEN_FDOCUMENTO_REVISION FDR
            ON DR.COD_DOCREV=FDR.COD_DOCREV
            WHERE SC.COD_SOLCRE=p_cod_solcre;
            p_ret_mens := 'La consulta se realizó correctamente!';
            p_ret_esta := 1;
            EXCEPTION
            WHEN OTHERS THEN
              p_ret_esta := -1;
              p_ret_mens := 'SP_LISTAR_PERSONAS_FACULTADAS:' || SQLERRM;
  END;

/*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_OPERACIONES_PERSONAS
Proposito : Listar las operaciones a revisar por persona
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 22/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_OPERACIONES_PERSONAS
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_tipope        IN gen_operacion_legal.cod_tipope%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        SELECT a.cod_tipope,
            a.cod_opeleg, 
            a.descripcion,
            FN_OBTE_RUTA_DOC(
                (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre),
                a.cod_tipope,
                a.cod_opeleg,
                'RP') txt_ruta_doc
        FROM gen_operacion_legal a,gen_tipo_operacion b,
        gen_plantilla_operacion c,
        gen_estructura_operacion d, 
        gen_solicitud_credito e
        WHERE a.cod_tipope=b.cod_tipope
        AND a.cod_tipope=c.cod_tipope
        AND c.cod_estope=d.cod_estope 
        AND e.cod_estope=d.cod_estope
        AND b.cod_natope = 'FSJ'
        AND e.cod_solcre=p_cod_solcre
        and a.cod_tipope=p_cod_tipope;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_OPERACIONES_PERSONAS:' || SQLERRM;
  END;
  
 /*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_OPERACIONES_LEGALES
Proposito : Listar las operaciones legales según estructura de operación
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 25/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_OPERACIONES_LEGALES
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        select p.cod_tipope, top.descripcion 
        from gen_plantilla_operacion p, gen_tipo_operacion top 
        where p.cod_estope = (select cod_estope from gen_solicitud_credito where cod_Solcre=p_cod_solcre)
        and p.ind_inactivo = 'N'  
        and top.cod_tipope = p.cod_tipope;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_OPERACIONES_LEGALES:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_AVAL_CLIENTE
    Proposito : Listar los avales y clientes asociados a la solicitud de crédito legal
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     26/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_AVAL_CLIENTE
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        select p.cod_perso, nom_perso
        from gen_persona p
        inner join gen_solicitud_credito s
        on p.cod_perso=s.cod_clie
        where s.cod_solcre=p_cod_solcre
        union
        select p.cod_perso, nom_perso
        from gen_persona p
        inner join vve_cred_soli_aval sa
        on p.cod_perso=sa.cod_per_aval
        inner join vve_cred_soli s
        on sa.cod_soli_cred=s.cod_soli_cred
        where s.cod_solcre_legal=p_cod_solcre;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_AVAL_CLIENTE:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_CHK_SINREGISTRO
Proposito : Listar los documentos que son necesarios para la operación legal
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 04/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_CHK_SINREGISTRO
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        select o.cod_opeleg, o.cod_tipope, o.descripcion
        from gen_operacion_legal o, gen_tipo_operacion t, gen_plantilla_operacion p 
        where p.cod_estope = (select cod_estope from gen_solicitud_credito where cod_solcre=p_cod_solcre)
        and t.cod_natope = 'REV' 
        and t.cod_tipope = p.cod_tipope
        and o.cod_tipope = t.cod_tipope;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_CHK_SINREGISTRO:' || SQLERRM;
  END;
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_CHK_CONREGISTRO
    Proposito : Listar los documentos que son necesarios para la operación legal
    Referencias : 
    Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 04/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_CHK_CONREGISTRO
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        SELECT a.cod_docrev,a.cod_ddorev,a.cod_opeleg, a.cod_tipope,'S' utiliza,a.ind_conforme
        FROM gen_ddocumento_revision a, gen_documento_revision b
        WHERE a.cod_docrev=b.cod_docrev 
        AND b.cod_solcre=p_cod_solcre
        AND a.cod_docrev =b.cod_docrev;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_CHK_SINREGISTRO:' || SQLERRM;
  END;
  

  PROCEDURE SP_REGISTRA_OPERACION_LEGAL
  (
    p_cod_docrev        IN  gen_documento_revision.cod_docrev%TYPE,
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_nom_revision      IN  gen_documento_revision.nom_revision%TYPE,
    p_observacion       IN  gen_documento_revision.observacion%TYPE,
    p_cod_tipope        IN  gen_documento_revision.cod_tipope%TYPE,
    p_cod_usuario       IN  gen_documento_revision.cod_usuario_crea%TYPE,
    p_cod_docrev_out    OUT NUMBER,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS 
  BEGIN
    IF p_cod_docrev = 0 THEN
        select max(cod_docrev)+1 into p_cod_docrev_out from gen_documento_revision;
        Insert Into gen_documento_revision values(p_cod_docrev_out,p_cod_solcre,
        p_nom_revision,p_observacion,'N','',p_cod_tipope,sysdate,p_cod_usuario,sysdate,p_cod_usuario,'N');
        COMMIT;
        p_ret_mens := 'Se registró la operación legal';
        p_ret_esta := 1;
     ELSE
         UPDATE gen_documento_revision
         SET nom_revision = p_nom_revision,
             observacion = p_observacion,
             ind_crem = 'N',
             obs_crem = '',
             cod_tipope = p_cod_tipope,
             fec_modi_reg =  sysdate,
             cod_usuario_modi = p_cod_usuario
          WHERE
               cod_docrev = p_cod_docrev
           AND cod_solcre = p_cod_solcre;
         COMMIT;
         p_cod_docrev_out := p_cod_docrev;
         p_ret_mens := 'Se actualizó la operación legal';
         p_ret_esta := 1;
     END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_cod_docrev_out := -1;
            p_ret_esta := -1;
            p_ret_mens := 'SP_REGISTRA_OPERACION_LEGAL:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_REGISTRA_OPERACION_LEGAL',
                                                p_cod_usuario,
                                                'Error al registrar operación legal',
                                                p_ret_mens,
                                                p_cod_solcre);             
        ROLLBACK;
  END;

  PROCEDURE SP_ELIMINA_OPERACION_LEGAL
  (
    p_cod_docrev        IN  gen_documento_revision.cod_docrev%TYPE,
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_usuario       IN  gen_documento_revision.cod_usuario_crea%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS 
  BEGIN

         UPDATE gen_documento_revision
         SET 
             ind_inactivo = 'S',
             fec_modi_reg =  sysdate,
             cod_usuario_modi = p_cod_usuario
          WHERE
               cod_docrev = p_cod_docrev
           AND cod_solcre = p_cod_solcre;
         COMMIT;
         p_ret_mens := 'Se inactivó la operación legal';
         p_ret_esta := 1;

    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ELIMINA_OPERACION_LEGAL:' || SQLERRM;
      ROLLBACK;
  END;
  

  PROCEDURE SP_REGISTRA_PERSONA_FACULTADA
  (
    p_cod_fdorev      IN  gen_fdocumento_revision.cod_fdorev%TYPE,
    p_cod_solcre      IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docrev      IN gen_fdocumento_revision.cod_docrev%TYPE,
    p_cargo           IN gen_fdocumento_revision.cargo%TYPE,
    p_nombre          IN gen_fdocumento_revision.nombre%TYPE,
    p_doi             IN gen_fdocumento_revision.doi%TYPE,
    p_cod_usuario     IN gen_fdocumento_revision.cod_usuario_crea%TYPE,
    p_cod_fdorev_out  OUT NUMBER,
    p_cod_docrev_out  OUT NUMBER,
    p_ret_esta        OUT NUMBER,
    p_ret_mens        OUT VARCHAR2
  )AS
  BEGIN
    IF p_cod_fdorev = 0 THEN
         select max(cod_fdorev)+1 into p_cod_fdorev_out from gen_fdocumento_revision;
         Insert into gen_fdocumento_revision values(p_cod_fdorev_out,p_cod_docrev,
         p_cargo,p_nombre,p_doi,sysdate,p_cod_usuario,sysdate,p_cod_usuario,'N');
        COMMIT;
        p_cod_docrev_out := p_cod_docrev;
        p_ret_mens := 'Se registró la persona facultada';
        p_ret_esta := 1;
    ELSE
        UPDATE gen_fdocumento_revision
        SET cargo = p_cargo,
            nombre = p_nombre,
            doi = p_doi ,
            fec_modi_reg = sysdate,
            cod_usuario_modi = p_cod_usuario
        WHERE
            cod_fdorev = p_cod_fdorev AND
            cod_docrev = p_cod_docrev;
        COMMIT;
        p_cod_docrev_out := p_cod_docrev;
        p_cod_fdorev_out := p_cod_fdorev; 
        p_ret_mens := 'Se registró la persona facultada';
        p_ret_esta := 1;
    
    END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_REGISTRA_PERSONA_FACULTADA:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_REGISTRA_PERSONA_FACULTADA',
                                                p_cod_usuario,
                                                'Error al registrar persona facultada',
                                                p_ret_mens,
                                                p_cod_solcre);        
        ROLLBACK;
  END;


  PROCEDURE SP_REGISTRA_DOCUMENTO_REVISION
  (
    p_cod_ddorev      IN gen_ddocumento_revision.cod_ddorev%TYPE,
    p_cod_solcre      IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docrev      IN gen_ddocumento_revision.cod_docrev%TYPE,
    p_cod_opeleg      IN gen_ddocumento_revision.cod_opeleg%TYPE,
    p_cod_tipope      IN gen_ddocumento_revision.cod_tipope%TYPE,
    p_ind_conforme    IN gen_ddocumento_revision.ind_conforme%TYPE,
    p_cod_usuario     IN gen_ddocumento_revision.cod_usuario_crea%TYPE,
    p_cod_ddorev_out  OUT NUMBER,
    p_cod_docrev_out  OUT NUMBER,
    p_ret_esta        OUT NUMBER,
    p_ret_mens        OUT VARCHAR2
  )AS
  v_cod_ddorev_out NUMBER;
  v_cod_docrev NUMBER;
  BEGIN
  
    IF p_cod_docrev = 0 THEN
         BEGIN
              SELECT cod_docrev INTO v_cod_docrev
              FROM gen_documento_revision
              WHERE cod_solcre= p_cod_solcre;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
               p_cod_ddorev_out := 0;
               p_cod_docrev_out := 0;
               p_ret_mens := 'Primero debe realizar el registro en revisión de poderes';
               p_ret_esta := 2;
           END; 
        ELSE
          v_cod_docrev := p_cod_docrev;
    END IF;
    
    IF p_cod_ddorev = 0 THEN
        SELECT MAX(cod_ddorev)+1 INTO v_cod_ddorev_out FROM gen_ddocumento_revision;
        INSERT INTO gen_ddocumento_revision VALUES(v_cod_ddorev_out,v_cod_docrev,
        p_cod_opeleg,p_cod_tipope,p_ind_conforme,sysdate,p_cod_usuario,sysdate,p_cod_usuario,'N');
        
        p_cod_ddorev_out := v_cod_ddorev_out;
        p_cod_docrev_out := v_cod_docrev;
    ELSE
        UPDATE gen_ddocumento_revision
         SET cod_opeleg = p_cod_opeleg,
             cod_tipope = p_cod_tipope,
             ind_conforme = p_ind_conforme,
             fec_modi_reg = sysdate,
             cod_usuario_modi = p_cod_usuario
         WHERE
             cod_ddorev = p_cod_ddorev AND
             cod_docrev = v_cod_docrev; 
             
             v_cod_ddorev_out := p_cod_ddorev;
             
             p_cod_ddorev_out := v_cod_ddorev_out;
             p_cod_docrev_out := v_cod_docrev;
    END IF;
    
    COMMIT;
    
    p_cod_ddorev_out := v_cod_ddorev_out;
    p_cod_docrev_out := v_cod_docrev;
    p_ret_mens := 'Se registró el documento a revisar';
    p_ret_esta := 1;
    
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_REGISTRA_DOCUMENTO_REVISION:' || SQLERRM;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'SP_REGISTRA_DOCUMENTO_REVISION',
                                                p_cod_usuario,
                                                'Error al registrar documento revisión',
                                                p_ret_mens,
                                                p_cod_solcre);              
        ROLLBACK;
  END;

/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_OPE_LEGAL
    Proposito : Listar las operaciones legales de la solicitud de crédito
    Referencias : 
    Parametros :
    Log de Cambios 
  Fecha        Autor         Descripcion
 04/08/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_OPELEGAL_SOLCRE
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
      open p_ret_cursor for
        select cod_docrev,cod_tipope,nom_revision,observacion from gen_documento_revision
        where cod_solcre=p_cod_solcre and ind_inactivo='N';
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_OPELEGAL_SOLCRE:' || SQLERRM;
  END;
  
               /*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_PERFACULTADA_SOLCRE
Proposito : Listar las persona facultadas de la solicitud de crédito
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 04/11/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_PERFACULTADA_SOLCRE
  (
    p_cod_docrev        IN  gen_fdocumento_revision.cod_docrev%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
    select cod_fdorev,cod_docrev,cargo,nombre,doi from gen_fdocumento_revision
    where cod_docrev=p_cod_docrev and ind_inactivo='N';
    p_ret_mens := 'La consulta se realizó correctamente!';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LISTAR_PERFACULTADA_SOLCRE:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_ESTRUCTURA_OPERACION
    Proposito : Lista estructura de operaciones
    Referencias : 
    Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 12/04/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_ESTRUCTURA_OPERACION(
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
    select cod_estope, descripcion from gen_estructura_operacion where ind_inactivo='N'
    order by descripcion asc;
    p_ret_mens := 'La consulta se realizó correctamente!';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LISTAR_ESTRUCTURA_OPERACION:' || SQLERRM;
  END;
  
/*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_VALIDAR_SOLCRE
Proposito : Listar solicitud de crédito en caso de existir.
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 12/04/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_VALIDAR_SOLCRE
  (
    p_cod_soli_cred        IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
     select s.cod_soli_cred,s.cod_solcre_legal,s.cod_empr as no_cia,s.cod_clie,p.nom_perso,p.cod_tipo_perso,(CASE p.cod_tipo_docu_iden WHEN '001' THEN p.num_docu_iden ELSE p.num_ruc END) num_docu 
     from vve_cred_soli s
     inner join gen_persona p
     on s.cod_clie=p.cod_perso
     where LTRIM(s.cod_soli_cred, '0')=LTRIM(p_cod_soli_cred, '0');
    p_ret_mens := 'La consulta se realizó correctamente!';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LISTAR_VALIDAR_SOLCRE:' || SQLERRM;
  END;

    /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_LEGAL
    Proposito : Registrar Solicitud Legal.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     15/04/2019   MGRASSO  
     17/01/2020   AVILCA         Req. 87567 E2.1, ID:123: Se modifica para que inserte y actualize
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_REGISTRAR_LEGAL
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_estope IN gen_solicitud_credito.cod_estope%TYPE,
    p_cod_estleg IN gen_solicitud_credito.cod_estleg%TYPE,
    p_nro_expediente IN gen_solicitud_credito.nro_expediente%TYPE,
    p_no_cia IN gen_solicitud_credito.no_cia%TYPE,
    p_cod_clie IN gen_solicitud_credito.cod_clie%TYPE,
    p_fecha_solcre IN gen_solicitud_credito.fecha_solcre%TYPE,
    p_fecha_revision IN gen_solicitud_credito.fecha_revision%TYPE,
    p_fecha_caduca IN gen_solicitud_credito.fecha_caduca%TYPE,
    p_cod_usuario IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_cod_solcre OUT NUMBER,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
   v_cod_solcre_legal NUMBER;
   v_cod_solcre_legal_aux NUMBER;
  BEGIN
      SELECT cod_solcre_legal INTO v_cod_solcre_legal
      FROM vve_cred_soli
      WHERE LTRIM(cod_soli_cred, '0')=LTRIM(p_cod_soli_cred, '0');
      
    IF v_cod_solcre_legal IS NULL THEN
        SELECT MAX(cod_solcre)+1 INTO v_cod_solcre_legal_aux FROM gen_solicitud_credito;
        INSERT INTO gen_solicitud_credito (cod_solcre,
                                           cod_estope,
                                           no_cia,
                                           cod_estleg,
                                           nro_expediente,
                                           cod_clie,
                                           fecha_solcre,
                                           fecha_revision,
                                           fecha_caduca,
                                           fec_crea_reg,
                                           cod_usuario_crea,
                                           fec_modi_reg,
                                           cod_usuario_modi,
                                           ind_inactivo)
                                           
                                    values (v_cod_solcre_legal_aux,
                                            p_cod_estope,
                                            p_no_cia,
                                            p_cod_estleg,
                                            p_nro_expediente,
                                            p_cod_clie,
                                            p_fecha_solcre,
                                            p_fecha_revision,
                                            p_fecha_caduca,
                                            sysdate,
                                            p_cod_usuario,
                                            sysdate,
                                            p_cod_usuario,
                                            'N');
    ELSE
                           UPDATE gen_solicitud_credito
                               SET cod_estope = p_cod_estope,
                                   no_cia = p_no_cia,
                                   cod_estleg = p_cod_estleg,
                                   nro_expediente = p_nro_expediente,
                                   cod_clie = p_cod_clie,
                                   fecha_solcre = p_fecha_solcre,
                                   fecha_revision = p_fecha_revision,
                                   fecha_caduca = p_fecha_caduca,
                                   fec_modi_reg = sysdate,
                                   cod_usuario_modi = p_cod_usuario
                                WHERE  cod_solcre = v_cod_solcre_legal;
                                
                                v_cod_solcre_legal_aux := v_cod_solcre_legal;
    END IF;

    COMMIT;
    p_ret_mens := 'Se registró la solicitud legal';
    p_ret_esta := 1;
    p_cod_solcre:= v_cod_solcre_legal_aux;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRAR_LEGAL:' || SQLERRM;
      ROLLBACK;
  END;
  
/*-----------------------------------------------------------------------------
Nombre : SP_ACTUALIZAR_SOLCRE
Proposito : Actualizar la solicitud legal en vve_cred_soli.
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 15/04/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_ACTUALIZAR_SOLCRE
  (
    p_cod_solcre IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    update vve_cred_soli
    set COD_SOLCRE_LEGAL=p_cod_solcre
    where LTRIM(cod_soli_cred, '0')=LTRIM(p_cod_soli_cred, '0');
    COMMIT;
    p_ret_mens := 'Se actualizo la solicitud legal';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_SOLCRE:' || SQLERRM;
      ROLLBACK;
  END;
  
    /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIA_MOBILIARIA
    Proposito : Listar garantía mobiliarias adicionales.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     16/04/2019   MGRASSO  
     15/01/2020   AVILCA        Req. 87567 E2.1
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_GARANTIA_MOBILIARIA
  (
    p_cod_solcre IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        select g.cod_garantia,
                g.cod_pers_prop,
                p.cod_tipo_perso,
                p.nom_perso,
                g.txt_marca,
                g.txt_modelo,
                g.nro_placa,
                g.val_ano_fab
             from vve_cred_soli s
             inner join vve_cred_soli_gara sg
                on s.cod_soli_cred=sg.cod_soli_cred
                and sg.ind_inactivo = 'N'
             inner join vve_cred_maes_gara g
                on sg.cod_gara=g.cod_garantia
                and g.ind_adicional = 'S'
             inner join gen_solicitud_credito sc
                on s.COD_SOLCRE_LEGAL = sc.cod_solcre
             inner join vve_cred_mae_aval a
                on a.cod_per_aval = g.cod_pers_prop
                and a.cod_tipo_otor = 'OG01'
             inner join gen_persona p
                on g.COD_PERS_PROP=p.cod_perso
             where sc.cod_solcre = p_cod_solcre
                and g.ind_tipo_garantia='M'
             union
         select g.cod_garantia,
                g.cod_pers_prop,
                a.ind_tipo_persona cod_tipo_perso,
                decode (a.ind_tipo_persona,'J',a.txt_nomb_pers,a.txt_apel_pate_pers||' '||a.txt_apel_mate_pers||' '||a.txt_nomb_pers) nom_perso,
                g.txt_marca,
                g.txt_modelo,
                g.nro_placa,
                g.val_ano_fab
             from vve_cred_soli s
             inner join vve_cred_soli_gara sg
                on s.cod_soli_cred=sg.cod_soli_cred
                and sg.ind_inactivo = 'N'
             inner join vve_cred_maes_gara g
                on sg.cod_gara=g.cod_garantia
                and g.ind_adicional = 'S'
             inner join gen_solicitud_credito sc
                on s.COD_SOLCRE_LEGAL = sc.cod_solcre
             inner join vve_cred_mae_aval a
                on a.cod_per_aval = g.cod_pers_prop
                and a.cod_tipo_otor in ('OG02','OG03')
             where sc.cod_solcre = p_cod_solcre
                and g.ind_tipo_garantia='M';
     
     p_ret_mens := 'La consulta se realizó correctamente!';
     p_ret_esta := 1;
     
     EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_GARANTIA_MOBILIARIA:' || SQLERRM;
    END;
    
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOCUMENTOS_SOLICITADOS
    Proposito : Listar documentos legales solicitados.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     24/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOCUMENTO_SOLICITADO
  (
    p_cod_solcre  IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor  OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  ) AS
  BEGIN
    open p_ret_cursor for
        SELECT cod_dtipope ,
               cod_tipope ,
               descripcion,
               FN_OBTE_RUTA_DOC(
                    (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre),
                    a.cod_dtipope,
                    NULL,
                    'GM') txt_ruta_doc
        FROM gen_dtipo_operacion a WHERE a.ind_inactivo='N' 
            AND cod_tipope IN(SELECT b.cod_tipope 
                              FROM   gen_tipo_operacion b
                              WHERE  b.cod_natope='GM')
        ORDER BY 1;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LISTAR_DOCUMENTO_SOLICITADO:' || SQLERRM;
  END;
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_GARA_MOB
    Proposito : Registrar garantía mobiliaria.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     25/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_REGISTRAR_GARA_MOB
  (
    p_cod_canleg     IN gen_canexo_legal.cod_canleg%TYPE,
    p_cod_soli_cred  IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_tip_per        IN  gen_canexo_legal.tip_persona%TYPE,
    p_propietario    IN  gen_canexo_legal.propietario%TYPE,
    p_marca          IN  gen_canexo_legal.marca%TYPE,
    p_placa          IN  gen_canexo_legal.placa%TYPE,
    p_modelo         IN  gen_canexo_legal.modelo%TYPE,
    p_anio           IN  gen_canexo_legal.año%TYPE,
    p_tip_bien       IN  gen_canexo_legal.tip_bien%TYPE,
    p_nom_per        IN  gen_canexo_legal.nom_per%TYPE,
    p_appat_per      IN  gen_canexo_legal.appat_per%TYPE,
    p_apmat_per      IN  gen_canexo_legal.apmat_per%TYPE,
    p_nom_conyuge   IN  gen_canexo_legal.nom_conyuge%TYPE,
    p_appat_conyuge IN  gen_canexo_legal.appat_conyuge%TYPE,
    p_apmat_conyuge IN  gen_canexo_legal.apmat_conyuge%TYPE,
    p_tip_doiper     IN gen_canexo_legal.tip_doiper%TYPE,
    p_nro_doiper     IN gen_canexo_legal.nro_doiper%TYPE,
    p_tip_doicon     IN gen_canexo_legal.tip_doicon%TYPE,
    p_nro_doicon     IN gen_canexo_legal.nro_doicon%TYPE,
    p_opi_legal      IN gen_canexo_legal.opi_legal%TYPE,
    p_cod_usuario    IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_cod_canleg_out OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  )AS
  v_cod_tipope NUMBER;
  v_cod_canleg NUMBER :=0;
  BEGIN
  
   SELECT cod_tipope INTO v_cod_tipope
   FROM   gen_tipo_operacion 
   WHERE  cod_natope='GM';
   
             IF p_cod_canleg = 0 THEN
               select max(cod_canleg)+1 into v_cod_canleg from gen_canexo_legal;
                INSERT INTO gen_canexo_legal(
                  cod_canleg,
                  cod_solcre,
                  cod_tipope,
                  tip_persona,
                  propietario,
                  marca,
                  placa,
                  modelo,
                  año,
                  tip_bien,
                  nom_per,
                  appat_per,
                  apmat_per,
                  nom_conyuge,
                  appat_conyuge,
                  apmat_conyuge,
                  tip_doiper,
                  nro_doiper,
                  tip_doicon,
                  nro_doicon,
                  opi_legal,
                  fec_crea_reg,
                  cod_usuario_crea,
                  fec_modi_reg,
                  cod_usuario_modi,
                  ind_inactivo
                )
               VALUES(
                  v_cod_canleg,
                  p_cod_soli_cred,
                  v_cod_tipope,
                  p_tip_per,
                  p_propietario,
                  p_marca,
                  p_placa,
                  p_modelo,
                  p_anio,
                  p_tip_bien,
                  p_nom_per,
                  p_appat_per,
                  p_apmat_per,
                  p_nom_conyuge,
                  p_appat_conyuge,
                  p_apmat_conyuge,
                  p_tip_doiper,
                  p_nro_doiper,
                  p_tip_doicon,
                  p_nro_doicon,
                  p_opi_legal,
                  sysdate,
                  p_cod_usuario,
                  sysdate,
                  p_cod_usuario,
                  'N'
               );
               COMMIT;
                 p_cod_canleg_out := v_cod_canleg;
                 p_ret_mens   := 'Se registró la garantía mobiliaria';
                 p_ret_esta   := 1;
             ELSE
             
                UPDATE gen_canexo_legal
                SET tip_persona = p_tip_per,
                    propietario = p_propietario,
                    marca       = p_marca,
                    placa       = p_placa,
                    modelo      = p_modelo,
                    año         = p_anio,
                    tip_bien    = p_tip_bien,
                    nom_per     = p_nom_per,
                    appat_per   = p_appat_per,
                    apmat_per   = p_apmat_per,
                    nom_conyuge = p_nom_conyuge,
                    appat_conyuge = p_appat_conyuge,
                    apmat_conyuge = p_apmat_conyuge,
                    tip_doiper  = p_tip_doiper,
                    nro_doiper  = p_nro_doiper,
                    tip_doicon = p_tip_doicon,
                    nro_doicon  = p_nro_doicon,
                    opi_legal   = p_opi_legal,
                    fec_modi_reg = sysdate,
                    cod_usuario_modi = p_cod_usuario,
                    ind_inactivo  = 'N'
                 WHERE cod_canleg = p_cod_canleg ;
                COMMIT;
                 p_cod_canleg_out := p_cod_canleg;
                 p_ret_mens   := 'Se registró la garantía mobiliaria';
                 p_ret_esta   := 1;    
             END IF;
    
    EXCEPTION
    WHEN OTHERS THEN
      p_cod_canleg_out := -1;
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRAR_GARA_MOB:' || SQLERRM;
      ROLLBACK;
  END;
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_DOC_LEG_SOL
    Proposito : Registrar documentos legales solicitados.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     25/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_REGISTRAR_DOC_LEG_SOL
  (
    p_cod_canleg     IN  gen_canexo_legal.cod_canleg%TYPE,
    p_cod_danleg     IN  gen_danexo_legal.cod_danleg%TYPE,
    p_cod_dtipope    IN  gen_dtipo_operacion.cod_dtipope%TYPE,
    p_cod_tipope     IN  gen_dtipo_operacion.cod_tipope%TYPE,
    p_ind_conforme   IN  gen_danexo_legal.ind_conforme%TYPE,
    p_observacion    IN  gen_danexo_legal.observacion%TYPE,
    p_cod_usuario    IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_cod_danleg_out OUT NUMBER,  
    p_cod_canleg_out OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  )AS

  v_cod_danleg NUMBER :=0;
  BEGIN
   
             IF p_cod_danleg = 0 THEN
               select max(cod_danleg)+1 into v_cod_danleg from gen_danexo_legal;
                INSERT INTO gen_danexo_legal(
                  cod_danleg,
                  cod_canleg,
                  cod_dtipope,
                  cod_tipope,
                  ind_conforme,
                  observacion,
                  fec_crea_reg,
                  cod_usuario_crea,
                  fec_modi_reg,
                  cod_usuario_modi,
                  ind_inactivo
                )
               VALUES(
                  v_cod_danleg,
                  p_cod_canleg,
                  p_cod_dtipope,
                  p_cod_tipope,
                  p_ind_conforme,
                  p_observacion,
                  sysdate,
                  p_cod_usuario,
                  sysdate,
                  p_cod_usuario,
                  'N'
               );
               COMMIT;
                 p_cod_danleg_out := v_cod_danleg;
                 p_cod_canleg_out := p_cod_canleg;
                 p_ret_mens   := 'Se registró  exitosamente';
                 p_ret_esta   := 1;
             ELSE
             
                UPDATE gen_danexo_legal
                SET ind_conforme = p_ind_conforme,
                    observacion = p_observacion,
                    fec_modi_reg = sysdate,
                    cod_usuario_modi = p_cod_usuario,
                    ind_inactivo  = 'N'
                 WHERE cod_canleg = p_cod_canleg 
                  and cod_danleg = p_cod_danleg;
                COMMIT;
                 p_cod_danleg_out := p_cod_danleg;
                 p_cod_canleg_out := p_cod_canleg;
                 p_ret_mens   := 'Se registró exitosamente';
                 p_ret_esta   := 1;    
             END IF;
    
    EXCEPTION
    WHEN OTHERS THEN
      p_cod_danleg_out := -1;
      p_cod_canleg_out := p_cod_canleg;
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRAR_DOC_LEG_SOL:' || SQLERRM;
      ROLLBACK;
  END;
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIA_HIPOTECARIA
    Proposito : Listar garantía hipotecarias adicionales.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     29/04/2019   AVILCA         creación
     15/01/2020   AVILCA          Req. 87567 E2.1 
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_GARANTIA_HIPOTECARIA
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
         select g.cod_garantia,
                g.COD_PERS_PROP,
                p.cod_tipo_perso, 
                p.nom_perso,
                p.ape_paterno,
                p.ape_materno,
                p.nom_1,
                p.nom_2,
                g.txt_direccion,
                g.ind_tipo_bien
             from vve_cred_soli s 
             inner join vve_cred_soli_gara sg 
             on s.cod_soli_cred=sg.cod_soli_cred
             inner join vve_cred_maes_gara g
             on sg.cod_gara=g.cod_garantia
             inner join gen_solicitud_credito sc
             on s.COD_SOLCRE_LEGAL = sc.cod_solcre
             inner join gen_persona p
             on g.COD_PERS_PROP=p.cod_perso
             where sc.cod_solcre=p_cod_solcre 
             and g.ind_tipo_garantia='H'
             and sg.ind_inactivo = 'N'
        union
          select g.cod_garantia,
                g.COD_PERS_PROP,
                a.ind_tipo_persona cod_tipo_perso,
                 decode (a.ind_tipo_persona,'J',a.txt_nomb_pers,a.txt_apel_pate_pers||' '||a.txt_apel_mate_pers||' '||a.txt_nomb_pers) nom_perso,
                a.txt_apel_pate_pers ape_paterno,
                a.txt_apel_mate_pers ape_materno,
                '' nom_1,
                '' nom_2,
                g.txt_direccion,
                g.ind_tipo_bien
             from vve_cred_soli s 
             inner join vve_cred_soli_gara sg 
             on s.cod_soli_cred=sg.cod_soli_cred
             inner join vve_cred_maes_gara g
             on sg.cod_gara=g.cod_garantia
             inner join gen_solicitud_credito sc
             on s.COD_SOLCRE_LEGAL = sc.cod_solcre
             inner join vve_cred_mae_aval a
                on a.cod_per_aval = g.cod_pers_prop
                and a.cod_tipo_otor in ('OG02','OG03')
             where sc.cod_solcre=p_cod_solcre 
             and g.ind_tipo_garantia='H'
             and sg.ind_inactivo = 'N';	 
		
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
     EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_GARANTIA_HIPOTECARIA:' || SQLERRM;
    END;
    
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIA_HIPO_REG
    Proposito : Listar garantía hipotecarias registradas.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     29/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_GARANTIA_HIPO_REG
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  )AS
   v_cod_tipope NUMBER;
  BEGIN
  
       SELECT cod_tipope INTO v_cod_tipope
       FROM   gen_tipo_operacion 
       WHERE  cod_natope='GH';
   
    open p_ret_cursor for
        SELECT *  FROM gen_canexo_legal      
        where cod_solcre = p_cod_solcre  and 
              cod_tipope = v_cod_tipope;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
     EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_GARANTIA_HIPO_REG:' || SQLERRM;
    END; 
    
    
    
  /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_GARA_HIP
    Proposito : Registrar garantía hipotecaria.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     25/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_REGISTRAR_GARA_HIP
  (
    p_cod_canleg     IN gen_canexo_legal.cod_canleg%TYPE,
    p_cod_soli_cred  IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_tip_per        IN  gen_canexo_legal.tip_persona%TYPE,
    p_propietario    IN  gen_canexo_legal.propietario%TYPE,
    p_ubicacion      IN  gen_canexo_legal.ubi_garantia%TYPE,
    p_area_metro     IN  gen_canexo_legal.area_metro%TYPE,
    p_tip_medida     IN  gen_canexo_legal.tip_medida%TYPE,
    p_par_registral IN  gen_canexo_legal.par_registral%TYPE,
    p_sed_registral  IN  gen_canexo_legal.sed_registral%TYPE,
    p_legal_asiento  IN  gen_canexo_legal.asiento%TYPE,  
    p_tip_bien       IN  gen_canexo_legal.tip_bien%TYPE,
    p_nom_per        IN  gen_canexo_legal.nom_per%TYPE,
    p_appat_per      IN  gen_canexo_legal.appat_per%TYPE,
    p_apmat_per      IN  gen_canexo_legal.apmat_per%TYPE,
    p_nom_conyuge   IN  gen_canexo_legal.nom_conyuge%TYPE,
    p_appat_conyuge IN  gen_canexo_legal.appat_conyuge%TYPE,
    p_apmat_conyuge IN  gen_canexo_legal.apmat_conyuge%TYPE,
    p_tip_doiper     IN gen_canexo_legal.tip_doiper%TYPE,
    p_nro_doiper     IN gen_canexo_legal.nro_doiper%TYPE,
    p_tip_doicon     IN gen_canexo_legal.tip_doicon%TYPE,
    p_nro_doicon     IN gen_canexo_legal.nro_doicon%TYPE,
    p_opi_legal      IN gen_canexo_legal.opi_legal%TYPE,
    p_observacion1   IN gen_canexo_legal.observacion1%TYPE, 
    p_observacion2   IN gen_canexo_legal.observacion2%TYPE, 
    p_cod_usuario    IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_cod_canleg_out OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  )AS
  v_cod_tipope NUMBER;
  v_cod_canleg NUMBER :=0;
  BEGIN
  
   SELECT cod_tipope INTO v_cod_tipope
   FROM   gen_tipo_operacion 
   WHERE  cod_natope='GH';
   
             IF p_cod_canleg = 0 THEN
               select max(cod_canleg)+1 into v_cod_canleg from gen_canexo_legal;
                INSERT INTO gen_canexo_legal(
                  cod_canleg,
                  cod_solcre,
                  cod_tipope,
                  tip_persona,
                  propietario,
                  ubi_garantia,
                  area_metro,
                  tip_medida,
                  par_registral,
                  sed_registral,
                  asiento,                 
                  tip_bien,
                  nom_per,
                  appat_per,
                  apmat_per,
                  nom_conyuge,
                  appat_conyuge,
                  apmat_conyuge,
                  tip_doiper,
                  nro_doiper,
                  tip_doicon,
                  nro_doicon,
                  opi_legal,
                  observacion1,
                  observacion2,
                  fec_crea_reg,
                  cod_usuario_crea,
                  fec_modi_reg,
                  cod_usuario_modi,
                  ind_inactivo
                )
               VALUES(
                  v_cod_canleg,
                  p_cod_soli_cred,
                  v_cod_tipope,
                  p_tip_per,
                  p_propietario,
                  p_ubicacion,
                  p_area_metro,
                  p_tip_medida,
                  p_par_registral,
                  p_sed_registral,
                  p_legal_asiento,
                  p_tip_bien,
                  p_nom_per,
                  p_appat_per,
                  p_apmat_per,
                  p_nom_conyuge,
                  p_appat_conyuge,
                  p_apmat_conyuge,
                  p_tip_doiper,
                  p_nro_doiper,
                  p_tip_doicon,
                  p_nro_doicon,
                  p_opi_legal,
                  p_observacion1,
                  p_observacion2,
                  sysdate,
                  p_cod_usuario,
                  sysdate,
                  p_cod_usuario,
                  'N'
               );
               COMMIT;
                 p_cod_canleg_out := v_cod_canleg;
                 p_ret_mens   := 'Se registró la garantía hipotecaria';
                 p_ret_esta   := 1;
             ELSE
             
                UPDATE gen_canexo_legal
                SET tip_persona = p_tip_per,
                    propietario = p_propietario,
                    ubi_garantia = p_ubicacion ,
                    area_metro = p_area_metro,
                    tip_medida = p_tip_medida,
                    par_registral = p_par_registral,
                    sed_registral = p_sed_registral,
                    asiento = p_legal_asiento,
                    tip_bien    = p_tip_bien,
                    nom_per     = p_nom_per,
                    appat_per   = p_appat_per,
                    apmat_per   = p_apmat_per,
                    nom_conyuge = p_nom_conyuge,
                    appat_conyuge = p_appat_conyuge,
                    apmat_conyuge = p_apmat_conyuge,
                    tip_doiper  = p_tip_doiper,
                    nro_doiper  = p_nro_doiper,
                    tip_doicon = p_tip_doicon,
                    nro_doicon  = p_nro_doicon,
                    opi_legal   = p_opi_legal,
                    observacion1 = p_observacion1,
                    observacion2 = p_observacion2,
                    fec_modi_reg = sysdate,
                    cod_usuario_modi = p_cod_usuario,
                    ind_inactivo  = 'N'
                 WHERE cod_canleg = p_cod_canleg ;
                COMMIT;
                 p_cod_canleg_out := p_cod_canleg;
                 p_ret_mens   := 'Se registró la garantía hipotecaria';
                 p_ret_esta   := 1;    
             END IF;
    
    EXCEPTION
    WHEN OTHERS THEN
      p_cod_canleg_out := -1;
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRAR_GARA_HIP:' || SQLERRM;
      ROLLBACK;
  END;
 
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOCUMENTOS_HIPOTECARIOS
    Proposito : Listar documentos legales hipotecarios solicitados.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     30/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOCUMENTOS_HIP
  (
    p_ret_cursor  OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        SELECT cod_dtipope ,
               cod_tipope ,
               descripcion
        FROM gen_dtipo_operacion WHERE ind_inactivo='N' 
            AND cod_tipope IN(SELECT cod_tipope 
                              FROM   gen_tipo_operacion 
                              WHERE  cod_natope='GH')
        ORDER BY 1;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LISTAR_DOCUMENTOS_HIP:' || SQLERRM;
  END; 
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_FIANZAS_SOLIDARIAS
    Proposito : Listar las fianzas solidarias PN
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     09/05/2019   AVILCA  
     21/01/2020   AVILCA         Req. 87567 E2.1 ID:127
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_FIANZAS_SOLIDARIAS
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
        /*
        SELECT alcv.nom_aval nom_fiador,
        CASE (SELECT instr(alcv.nom_aval,'/')FROM dual) WHEN 0 THEN 'I' ELSE 'C' END tipo_fianza,
        'D' tipo_doc,
        CASE (SELECT instr(alcv.nom_aval,'/')FROM dual) WHEN 0 THEN 'I' ELSE 'C' END parentesco,
        alcv.le doi,
        alcv.cod_oper
        FROM lxc.arlcav alcv
        INNER JOIN vve_cred_soli csl ON
        alcv.cod_oper = csl.cod_oper_rel
        WHERE csl.cod_solcre_legal = p_cod_solcre;*/
       SELECT CASE  
           WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval)is null THEN 'I' 
           WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL01' THEN 'T' 
           WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL02' THEN 'C'
           END tipo_fianza,
           CASE  
           WHEN ma.cod_rela_aval IS NULL THEN 'INDIVIDUAL' 
           WHEN ma.cod_rela_aval = 'RAVAL01' THEN 'COPROPIETARIO' 
           WHEN ma.cod_rela_aval = 'RAVAL02' THEN 'CONYUGE'
           END parentesco,
           ma.txt_nomb_pers||' '||ma.txt_apel_pate_pers||' '||ma.txt_apel_mate_pers nom_fiador,
           ma.txt_doi doi,
           ma.cod_per_aval
        FROM vve_cred_mae_aval ma
        INNER JOIN vve_cred_soli_aval sa 
        ON  sa.cod_soli_cred IN (SELECT s.cod_soli_cred FROM vve_cred_soli s WHERE s.cod_solcre_legal = p_cod_solcre) 
        AND ma.cod_per_aval = sa.cod_per_aval
        AND ma.cod_tipo_otor = 'OG03' 
        AND ma.ind_tipo_persona = 'N' ;
        
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_FIANZAS_SOLIDARIAS:' || SQLERRM;
  END; 
  
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_PROP_AVAL_FSPN
    Proposito : Listar propietarios o avales para fianzas solidarias PN
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     21/01/2020   AVILCA         Req. 87567 E2.1 ID:127
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_PROP_AVAL_FSPN
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_per_aval      IN  vve_cred_mae_aval.cod_per_aval%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor FOR
        SELECT CASE 
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval)is null THEN 'I' 
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL01' THEN 'T' 
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL02' THEN 'C'
               END tipo_fianza,
               CASE  
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval)is null THEN  'INDIVIDUAL' 
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL01' THEN 'COPROPIETARIO' 
                WHEN (select ma2.cod_rela_aval from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) = 'RAVAL02' THEN 'CONYUGE'
               END parentesco,
               ma.txt_nomb_pers nom_fiador_nat,
               ma.txt_apel_pate_pers ape_pat_fia_nat,
               ma.txt_apel_mate_pers ape_mat_fia_nat,
               'D' tipo_doi_fia_nat,
               ma.txt_doi doi_fiador_nat,
               (select ma2.txt_nomb_pers from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) nom_rel_fia_nat,
               (select ma2.txt_apel_pate_pers from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) ape_rel_pat_fia_nat,
               (select ma2.txt_apel_mate_pers from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) ape_rel_mat_fia_nat,
               'D' tipo_doi_rel_fia_nat,
               (select ma2.txt_doi from vve_cred_mae_aval ma2 where ma2.cod_per_rel_aval = ma.cod_per_aval) doi_rel_fia_nat
        from vve_cred_mae_aval ma
        inner join vve_cred_soli_aval sa 
        on  sa.cod_soli_cred in (select s.cod_soli_cred from vve_cred_soli s where s.cod_solcre_legal = p_cod_solcre) 
        and ma.cod_per_aval = p_cod_per_aval
        and ma.cod_per_aval = sa.cod_per_aval
        and ma.cod_tipo_otor = 'OG03' 
        and ma.ind_tipo_persona = 'N';
        
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_PROP_AVAL_FSPN:' || SQLERRM;
  END;  
  
  
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOCS_FSN
    Proposito : Listar documentos de fianza solidaria PN
    Referencias : 
    Parametros :
  Log de Cambios 
  Fecha        Autor         Descripcion
 09/05/2019   AVILCA  
 24/01/2020   AVILCA       Req. 87567 E2.1 ID 127
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOCS_FSN
  (
    p_cod_solcre  IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_tipope  IN gen_operacion_legal.cod_tipope%TYPE,
    p_ret_cursor  OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  )AS
    v_cod_soli_cred VARCHAR(25);
  BEGIN
  
      /*SELECT cod_soli_cred  INTO v_cod_soli_cred
      FROM vve_cred_soli
      WHERE cod_solcre_legal =p_cod_solcre;*/
      
    open p_ret_cursor for
       /* SELECT distinct l.cod_docleg,l.descripcion,f.ind_oblig,f.txt_ruta_doc
            FROM gen_documento_legal l,vve_cred_mae_aval_docu f, vve_cred_mae_docu d
            WHERE l.ind_inactivo='N'
            and l.cod_titdoc in
            (select cod_titdoc
            from gen_titulo_documento a
            where ord_titdoc=6)
            and l.cod_docleg = d.cod_docleg
            and f.cod_docu_eval = d.cod_docu_eval
            and d.ind_tipo_docu = 'AN'
            and f.cod_per_aval = '00001022'
            and f.cod_soli_cred = v_cod_soli_cred
            order by cod_docleg;
            */
            
       SELECT a.cod_tipope,a.cod_opeleg, a.descripcion
        FROM gen_operacion_legal a,gen_tipo_operacion b,
        gen_plantilla_operacion c,gen_estructura_operacion d, gen_solicitud_credito e
        WHERE a.cod_tipope=b.cod_tipope
        AND a.cod_tipope=c.cod_tipope
        AND c.cod_estope=d.cod_estope 
        AND e.cod_estope=d.cod_estope
        AND b.cod_natope ='FSN'
        AND e.cod_solcre=p_cod_solcre;
        --and a.cod_tipope=p_cod_tipope;
        
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_DOCS_FSN:' || SQLERRM;
  END;
  
    /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_FIANZA_SOL_PN
    Proposito : Registrar fianza solidaria PN.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     10/05/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_REGISTRAR_FIANZA_SOL_PN
  (
    p_cod_canleg     IN gen_canexo_legal.cod_canleg%TYPE,
    p_cod_soli_cred  IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_propietario    IN  gen_canexo_legal.propietario%TYPE,
    p_tip_bien       IN  gen_canexo_legal.tip_bien%TYPE,
    p_nom_per        IN  gen_canexo_legal.nom_per%TYPE,
    p_appat_per      IN  gen_canexo_legal.appat_per%TYPE,
    p_apmat_per      IN  gen_canexo_legal.apmat_per%TYPE,
    p_nom_conyuge   IN  gen_canexo_legal.nom_conyuge%TYPE,
    p_appat_conyuge IN  gen_canexo_legal.appat_conyuge%TYPE,
    p_apmat_conyuge IN  gen_canexo_legal.apmat_conyuge%TYPE,
    p_tip_doiper     IN gen_canexo_legal.tip_doiper%TYPE,
    p_nro_doiper     IN gen_canexo_legal.nro_doiper%TYPE,
    p_tip_doicon     IN gen_canexo_legal.tip_doicon%TYPE,
    p_nro_doicon     IN gen_canexo_legal.nro_doicon%TYPE,
    p_opi_legal      IN gen_canexo_legal.opi_legal%TYPE,
    p_observacion1   IN gen_canexo_legal.observacion1%TYPE, 
    p_observacion2   IN gen_canexo_legal.observacion2%TYPE, 
    p_cod_usuario    IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_cod_canleg_out OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  )AS
  v_cod_tipope NUMBER;
  v_cod_canleg NUMBER :=0;
  BEGIN
  
   SELECT cod_tipope INTO v_cod_tipope
   FROM   gen_tipo_operacion 
   WHERE  cod_natope='FSN' AND
          ind_inactivo='N';
   
             IF p_cod_canleg = 0 THEN
               select max(cod_canleg)+1 into v_cod_canleg from gen_canexo_legal;
                INSERT INTO gen_canexo_legal(
                  cod_canleg,
                  cod_solcre,
                  cod_tipope,
                  propietario,      
                  tip_bien,
                  nom_per,
                  appat_per,
                  apmat_per,
                  nom_conyuge,
                  appat_conyuge,
                  apmat_conyuge,
                  tip_doiper,
                  nro_doiper,
                  tip_doicon,
                  nro_doicon,
                  opi_legal,
                  observacion1,
                  observacion2,
                  fec_crea_reg,
                  cod_usuario_crea,
                  fec_modi_reg,
                  cod_usuario_modi,
                  ind_inactivo
                )
               VALUES(
                  v_cod_canleg,
                  p_cod_soli_cred,
                  v_cod_tipope,
                  p_propietario,
                  p_tip_bien,
                  p_nom_per,
                  p_appat_per,
                  p_apmat_per,
                  p_nom_conyuge,
                  p_appat_conyuge,
                  p_apmat_conyuge,
                  p_tip_doiper,
                  p_nro_doiper,
                  p_tip_doicon,
                  p_nro_doicon,
                  p_opi_legal,
                  p_observacion1,
                  p_observacion2,
                  sysdate,
                  p_cod_usuario,
                  sysdate,
                  p_cod_usuario,
                  'N'
               );
               COMMIT;
                 p_cod_canleg_out := v_cod_canleg;
                 p_ret_mens   := 'Se registró la fianza solidaria PN';
                 p_ret_esta   := 1;
             ELSE
             
             UPDATE  gen_canexo_legal
                SET tip_bien    = p_tip_bien,
                    nom_per     = p_nom_per,
                    appat_per   = p_appat_per,
                    apmat_per   = p_apmat_per,
                    nom_conyuge = p_nom_conyuge,
                    appat_conyuge = p_appat_conyuge,
                    apmat_conyuge = p_apmat_conyuge,
                    tip_doiper  = p_tip_doiper,
                    nro_doiper  = p_nro_doiper,
                    tip_doicon = p_tip_doicon,
                    nro_doicon  = p_nro_doicon,
                    opi_legal   = p_opi_legal,
                    observacion1 = p_observacion1,
                    observacion2 = p_observacion2,
                    fec_modi_reg = sysdate,
                    cod_usuario_modi = p_cod_usuario,
                    ind_inactivo  = 'N'
                 WHERE cod_canleg = p_cod_canleg ;
                COMMIT;
                 p_cod_canleg_out := p_cod_canleg;
                 p_ret_mens   := 'Se actualizó la fianza solidaria PN';
                 p_ret_esta   := 1;    
             END IF;
    
    EXCEPTION
    WHEN OTHERS THEN
      p_cod_canleg_out := -1;
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRAR_FIANZA_SOL_PN:' || SQLERRM;
      ROLLBACK;
  END;
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_FSN_REGISTRADAS
    Proposito : Listar las fianzas solidarias PN reqgistradas
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     09/05/2019   AVILCA  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_FSN_REGISTRADAS
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
   v_cod_tipope NUMBER;
   v_num_filas NUMBER;
  BEGIN
       SELECT cod_tipope INTO v_cod_tipope
       FROM gen_tipo_operacion WHERE ind_inactivo='N' and cod_natope='FSN';
     
      open p_ret_cursor for
          SELECT gcl.cod_canleg,
                gcl.cod_solcre,
                gcl.cod_tipope,
                gcl.propietario,
                gcl.opi_legal,
                gcl.observacion1,
                gcl.observacion2,
                gcl.tip_doiper,
                gcl.nro_doiper,
                gcl.nom_per,
                gcl.appat_per,
                gcl.apmat_per,
                gcl.tip_doicon,
                gcl.nro_doicon,
                gcl.nom_conyuge,
                gcl.appat_conyuge,
                gcl.apmat_conyuge,
                gcl.tip_bien,	
                cma.cod_per_aval  
          FROM gen_canexo_legal gcl     
          INNER JOIN vve_cred_mae_aval cma ON gcl.nro_doiper = cma.txt_doi
          WHERE gcl.cod_solcre = p_cod_solcre AND
                gcl.cod_tipope = v_cod_tipope;
                
            p_ret_mens := 'La consulta se realizó correctamente!';
            p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_FIANZAS_SOLIDARIAS:' || SQLERRM;
  END; 
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOCLEGAL_HIP_REG
    Proposito : Listar los documentos legales hipotecarios registrados
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     09/05/2019   AVILCA  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOCLEGAL_HIP_REG
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_canleg   IN  gen_danexo_legal.cod_canleg%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS

  BEGIN     
      open p_ret_cursor for
        
         SELECT glc.cod_danleg,
            glc.cod_canleg,
            glc.cod_dtipope,
            glc.cod_tipope,
            glc.ind_conforme,
            glc.observacion,
            gto.descripcion,
            PKG_SWEB_CRED_SOLI_LEGAL.FN_OBTE_RUTA_DOC(
                (select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre),
                glc.cod_dtipope,
                NULL,
                'GM') txt_ruta_doc           
          FROM GEN_DANEXO_LEGAL glc,gen_dtipo_operacion gto
          WHERE glc.cod_tipope = gto.cod_tipope AND
                glc.cod_dtipope = gto.cod_dtipope AND
                glc.cod_canleg = p_cod_canleg;
                
            p_ret_mens := 'La consulta se realizó correctamente!';
            p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_DOCLEGAL_HIP_REG:' || SQLERRM;
  END; 
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIA_MOB_REG
    Proposito : Listar garantía mobiliarias registradas.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     29/04/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_GARANTIA_MOB_REG
  (
    p_cod_solcre   IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  )AS
   v_cod_tipope NUMBER;
  BEGIN
  
       SELECT cod_tipope INTO v_cod_tipope
       FROM   gen_tipo_operacion 
       WHERE  cod_natope='GM';
   
    open p_ret_cursor for
        SELECT *  FROM gen_canexo_legal      
        where cod_solcre = p_cod_solcre  and 
              cod_tipope = v_cod_tipope;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
     EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_GARANTIA_MOB_REG:' || SQLERRM;
    END; 
   /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_ANEXOS_CONTRATOS
    Proposito : Listar rutas de anexos y contratos asociados a la solicitud de crédito.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     20/05/2019   AVILCA  
    ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_LISTAR_ANEXOS_CONTRATOS
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_oper_rel      IN  vve_cred_soli.cod_oper_rel%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
        SELECT s.txt_ruta_docs_firm,
               s.txt_ruta_contrato,
               s.txt_ruta_anex,
               s.COD_OPER_REL,
               s.cod_soli_cred,
               
               tc.descripcion TIP_SOLI_CRED,
               tc.cod_tipo cod_tipo_cred
               
               /*
               'Recon. de Deuda' TIP_SOLI_CRED,
               'TC01' cod_tipo_cred
               */
               /*
               'Recon. de Deuda Leasing' TIP_SOLI_CRED,
               'TC02' cod_tipo_cred
               
                'Crédito Mutuo' TIP_SOLI_CRED,
                'TC03' cod_tipo_cred*/
        FROM vve_cred_soli s,vve_tabla_maes tc
        WHERE 
              (s.cod_oper_rel is null or s.cod_oper_rel like '%'||p_cod_oper_rel||'%') 
         AND  (s.cod_soli_cred is null or s.cod_soli_cred like '%'||p_cod_soli_cred||'%')
         AND  s.TIP_SOLI_CRED = tc.cod_tipo
         and  s.cod_oper_rel is not null;        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_ANEXOS_CONTRATOS:' || SQLERRM;
  END;  
  
 /*-----------------------------------------------------------------------------
    Nombre : SP_ACTUALIZA_RUTA_ANEXO_CONTRATO
    Proposito : Actualizar ruta de anexos y contratos.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     20/05/2019   AVILCA          Creación
     16/10/2020   AVILCA          Modificación: actualiza vve_cred_soli_legal_docu
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_ACT_RUTA_ANEXO_CONTRATO
  (
    p_cod_soli_cred      IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_url                IN  vve_cred_soli.txt_ruta_anex %TYPE,
    p_tipo_doc           IN  VARCHAR2,
    p_cod_usuario        IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  )AS
  v_txt_ruta_cont VARCHAR2(500):=null;
  v_txt_ruta_anex VARCHAR2(500);
  V_txt_ruta_docs_firm VARCHAR2(500);
  v_cod_legal_docu NUMBER;
  v_cod_clie VARCHAR2(500):= '';
  v_cod_empr VARCHAR2(500):= '';
  BEGIN
      
          SELECT cod_clie,cod_empr 
            INTO v_cod_clie,v_cod_empr
           FROM  vve_cred_soli
           WHERE cod_soli_cred = p_cod_soli_cred ;
           
           
         IF p_tipo_doc = 'C' THEN
           
          BEGIN 
           SELECT txt_ruta_contrato 
            INTO v_txt_ruta_cont
           FROM  vve_cred_soli
           WHERE cod_soli_cred = p_cod_soli_cred;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_txt_ruta_cont:= NULL;
          END;
          
          BEGIN 
           SELECT cod_cred_soli_lega_docu 
            INTO v_cod_legal_docu
           FROM  vve_cred_soli_legal_docu
           WHERE cod_soli_cred = p_cod_soli_cred
           AND cod_tipo_docu_not = 'TDNOT02';
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_cod_legal_docu:= NULL;
          END; 
           
           IF v_txt_ruta_cont IS NULL AND v_cod_legal_docu IS NULL THEN          
           
              INSERT INTO vve_cred_soli_legal_docu (cod_cred_soli_lega_docu,cod_soli_cred,cod_cliente,no_cia,cod_tipo_docu_not,fec_sube_docu,txt_ruta_docu,fec_crea_regi,cod_usua_crea_regi)
              VALUES(SEQ_VVE_CRED_SOLI_LEGAL_DOCU.nextval,p_cod_soli_cred,v_cod_clie,v_cod_empr,'TDNOT02',SYSDATE,p_url,SYSDATE,p_cod_usuario);
              COMMIT;
           ELSE
             UPDATE vve_cred_soli_legal_docu
             SET fec_sube_docu = sysdate,
                 txt_ruta_docu = p_url,
                 fec_modi_regi = sysdate,
                 cod_usua_modi_regi = p_cod_usuario
             WHERE cod_soli_cred = p_cod_soli_cred
             AND cod_tipo_docu_not = 'TDNOT02';  
              COMMIT; 
           END IF;
           
             UPDATE  vve_cred_soli
                SET 
                    txt_ruta_contrato  = p_url,                   
                    cod_usua_modi      = p_cod_usuario,
                    fec_modi_regi      = sysdate,
                    fec_gen_cont       = sysdate,
                    cod_usu_gen_cont   = p_cod_usuario
                 WHERE cod_soli_cred = p_cod_soli_cred ;
                COMMIT;
        END IF;
        
       IF p_tipo_doc = 'A' THEN
       
         BEGIN
            SELECT txt_ruta_anex 
             INTO v_txt_ruta_anex
            FROM  vve_cred_soli
           WHERE cod_soli_cred = p_cod_soli_cred ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_txt_ruta_anex:= NULL;
          END;           
         
        BEGIN   
           SELECT cod_cred_soli_lega_docu 
            INTO v_cod_legal_docu
           FROM  vve_cred_soli_legal_docu
           WHERE cod_soli_cred = p_cod_soli_cred
           AND cod_tipo_docu_not = 'TDNOT01';
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_cod_legal_docu:= NULL;
          END;   
           
           IF v_txt_ruta_anex IS NULL AND v_cod_legal_docu IS NULL THEN          
           
              INSERT INTO vve_cred_soli_legal_docu (cod_cred_soli_lega_docu,cod_soli_cred,cod_cliente,no_cia,cod_tipo_docu_not,fec_sube_docu,txt_ruta_docu,fec_crea_regi,cod_usua_crea_regi)
              VALUES(SEQ_VVE_CRED_SOLI_LEGAL_DOCU.nextval,p_cod_soli_cred,v_cod_clie,v_cod_empr,'TDNOT01',SYSDATE,p_url,SYSDATE,p_cod_usuario);
              COMMIT;
           ELSE
             UPDATE vve_cred_soli_legal_docu
             SET fec_sube_docu = sysdate,
                 txt_ruta_docu = p_url,
                 fec_modi_regi = sysdate,
                 cod_usua_modi_regi = p_cod_usuario
             WHERE cod_soli_cred = p_cod_soli_cred
             AND cod_tipo_docu_not = 'TDNOT01';  
              COMMIT; 
           END IF;
       
       
             UPDATE  vve_cred_soli
                SET 
                    txt_ruta_anex      = p_url,                   
                    cod_usua_modi      = p_cod_usuario,
                    fec_modi_regi      = sysdate,
                    fec_gen_anex       = sysdate,
                    cod_usu_gen_anex   = p_cod_usuario
                 WHERE cod_soli_cred = p_cod_soli_cred ;
                COMMIT;
        END IF;
        IF p_tipo_doc = 'F' THEN
        
        BEGIN
          SELECT txt_ruta_docs_firm 
             INTO v_txt_ruta_docs_firm
            FROM  vve_cred_soli
           WHERE cod_soli_cred = p_cod_soli_cred ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_txt_ruta_docs_firm:= NULL;
        END;           
          
       BEGIN    
           SELECT cod_cred_soli_lega_docu 
            INTO v_cod_legal_docu
           FROM  vve_cred_soli_legal_docu
           WHERE cod_soli_cred = p_cod_soli_cred
           AND cod_tipo_docu_not = 'TDNOT03';  
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_cod_legal_docu:= NULL;
        END;     
           
           IF v_txt_ruta_docs_firm IS NULL AND v_cod_legal_docu IS NULL THEN          
           
              INSERT INTO vve_cred_soli_legal_docu (cod_cred_soli_lega_docu,cod_soli_cred,cod_cliente,no_cia,cod_tipo_docu_not,fec_sube_docu,txt_ruta_docu,fec_crea_regi,cod_usua_crea_regi)
              VALUES(SEQ_VVE_CRED_SOLI_LEGAL_DOCU.nextval,p_cod_soli_cred,v_cod_clie,v_cod_empr,'TDNOT03',SYSDATE,p_url,SYSDATE,p_cod_usuario);
              COMMIT;
           ELSE
             UPDATE vve_cred_soli_legal_docu
             SET fec_sube_docu = sysdate,
                 txt_ruta_docu = p_url,
                 fec_modi_regi = sysdate,
                 cod_usua_modi_regi = p_cod_usuario                 
             WHERE cod_soli_cred = p_cod_soli_cred
             AND cod_tipo_docu_not = 'TDNOT03';  
              COMMIT; 
           END IF;
           
             UPDATE  vve_cred_soli
                SET 
                    txt_ruta_docs_firm    = p_url,                   
                    cod_usua_modi         = p_cod_usuario,
                    fec_modi_regi         = sysdate,
                    fec_gen_docs_firm    = sysdate,
                    cod_usu_gen_docs_firm = p_cod_usuario
                 WHERE cod_soli_cred = p_cod_soli_cred ;
                COMMIT;
        END IF;
                
       p_ret_mens   := 'Se actualizó la ruta del anexo o contrato';
       p_ret_esta   := 1;    
 
    
    EXCEPTION
    WHEN OTHERS THEN

      p_ret_esta := -1;
      p_ret_mens := 'SP_ACT_RUTA_ANEXO_CONTRATO:' || SQLERRM;
      ROLLBACK;
  END;
 
 /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_ANEXOS_FACTURAS
    Proposito : Listar facturas relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     23/05/2019   AVILCA  
 ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_LISTAR_ANEXOS_FACTURAS
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
         SELECT distinct(substr(aff.no_factu,1,4)||'-'||substr(aff.no_factu,5,length(aff.no_factu)-4)) no_docu,
                to_char(aff.fecha, 'DD/MM/YYYY') as fecha, -- MBARDALES CORRECCION PARA CONTRATOS ANEXOS RD MBARDALES
                aff.moneda,aff.val_pre_docu monto 
         FROM ARFAFE aff
          INNER JOIN vve_cred_maes_gara cmg ON aff.no_orden_desc = cmg.num_pedido_veh
          INNER JOIN  vve_cred_soli_gara csg ON csg.cod_gara = cmg.cod_garantia 
         WHERE
              csg.cod_soli_cred = p_cod_soli_cred;
              
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_ANEXOS_FACTURAS:' || SQLERRM;
  END;
  
   /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_ANEXOS_PAGOS
    Proposito : Listar facturas relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     10/02/2020   EBARBOZA  
     26/11/2020   AVILCA          CORRECCIONES COD MONEDA
 ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_LISTAR_ANEXOS_PAGOS
  (
    p_cod_soli_cred     IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
        select 
        gp.nom_perso as desBcoMovi,
        -- MBARDALES CONTRATO ANEXOS 
        case 
        when mtm.cod_tipo_mov = 1 then mtm.txt_desc_tipo_movi || ' / 001' 
        when mtm.cod_tipo_mov = 2 then mtm.txt_desc_tipo_movi || ' / 002'
        when mtm.cod_tipo_mov = 3 then mtm.txt_desc_tipo_movi || ' / 003'
        when mtm.cod_tipo_mov = 4 then mtm.txt_desc_tipo_movi || ' / 004'
        when mtm.cod_tipo_mov = 5 then mtm.txt_desc_tipo_movi || ' / 005'
        when mtm.cod_tipo_mov = 6 then mtm.txt_desc_tipo_movi || ' / 006'
        when mtm.cod_tipo_mov = 7 then mtm.txt_desc_tipo_movi || ' / 007'
        else mtm.txt_desc_tipo_movi
        end as desMovi,
        to_char(csm.fec_movi_pago,'dd/mm/yyyy') as fecMovi,
        gm.des_moneda as nomeMoneda,
        gm.des_larga_moneda as desLargaMoneda,
        csm.val_monto_pago as montoMovi,
        csm.ind_tipo_docu as tipoDocMovi,
        csm.txt_nro_documento as nroDocMovi,
        arc.nombre as desCiaCargo,
        to_char(csm.fec_movi_pago,'dd "de" month "de" yy','nls_date_language=spanish') as desFecMovi,
        letra.letras(pkg_factu_elect.obte_valo_oper('XXX',csm.val_monto_pago),'') as fMontoTexto
        from vve_cred_soli_movi csm
        inner join gen_persona gp on gp.cod_perso = csm.cod_banco
        inner join vve_cred_mae_tipo_movi mtm on mtm.cod_tipo_mov=csm.cod_tipo_movi_pago
        --<I Req. 87567 E2.1 ID## avilca 26/11/2020>
        inner join Gen_moneda gm on gm.cod_moneda = case csm.cod_moneda when 'DOL' THEN '2' ELSE '1' END
        --<F Req. 87567 E2.1 ID## avilca 26/11/2020>
        inner join arcgmc arc on arc.no_cia = csm.cod_empresa_cargo
        
        where csm.cod_soli_cred = p_cod_soli_cred
        group by gp.nom_perso,mtm.cod_tipo_mov,mtm.txt_desc_tipo_movi,csm.fec_movi_pago,
        gm.des_moneda,gm.des_larga_moneda,csm.val_monto_pago,
        csm.ind_tipo_docu,csm.txt_nro_documento,arc.nombre,csm.fec_movi_pago;      
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_ANEXOS_PAGOS:' || SQLERRM;
  END;
  
  
   /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIAS
    Proposito : Listar facturas relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     10/02/2020   EBARBOZA  
 ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_LISTAR_GARANTIAS
  (
    p_cod_soli_cred   IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_ind_tipo_gara   IN  VARCHAR2,
    p_ret_cursor      OUT SYS_REFCURSOR,
    p_ret_esta        OUT NUMBER,
    p_ret_mens        OUT VARCHAR2
  ) AS
  v_tip_soli_cred VARCHAR2(4):= '';
  v_ind_tipo_gara VARCHAR2(1):='';

  BEGIN
  
    SELECT tip_soli_cred INTO v_tip_soli_cred FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;
    
    IF (v_tip_soli_cred = 'TC02') THEN
      v_ind_tipo_gara := 'S';
    ELSE 
      v_ind_tipo_gara := 'N';
    END IF;
  
    OPEN p_ret_cursor FOR
        select 
        count(1) as item, 
        decode(gp.nom_perso,null,'-',gp.nom_perso) as cliente,
        decode(cmg.txt_marca,null,'-',cmg.txt_marca) as marca,
        decode(cmg.txt_modelo,null,'-',cmg.txt_modelo) as modelo,
        decode(vtv.des_tipo_veh,null,'-',vtv.des_tipo_veh) as tipoVeh,
        decode(cmg.nro_motor,null,'-',cmg.nro_motor) as numeroMotor,
        decode(cmg.nro_chasis,null,'-',cmg.nro_chasis) as numeroChasis,
        decode(cmg.nro_placa,null,'-',cmg.nro_placa) as numeroPlaca,
        decode(cmg.val_const_gar,null,0,cmg.val_const_gar) as montoGarantia,
        decode(cmg.val_realiz_gar,null,0,cmg.val_realiz_gar) as montoValorizacion,
        decode(a.val_pre_docu,null,0,a.val_pre_docu) as val_pre_docu,
        decode(gm.des_moneda,null,'-',gm.des_moneda) as nomeMone,
        decode(gm.des_larga_moneda,null,'-',gm.des_larga_moneda) as nomeMoneLargo,
        letra.letras(pkg_factu_elect.obte_valo_oper('XXX',cmg.val_const_gar),'') as montoTexto,
        letra.letras(pkg_factu_elect.obte_valo_oper('XXX',cmg.val_realiz_gar),'') as montoValorizacionTexto,
        -- MBARDALES CONTRATO ANEXOS
        UPPER(mp.des_nombre) as desc_provincia
        from vve_cred_maes_gara cmg
        inner join vve_cred_soli_gara vcs
        on vcs.cod_gara = cmg.cod_garantia
        inner join gen_persona gp
        on gp.cod_perso in cmg.cod_pers_prop and cmg.ind_otor = 'D'
        inner join vve_tipo_veh vtv
        on vtv.cod_tipo_veh = cmg.cod_tipo_veh
        inner join Arfafe a
        on a.no_orden_desc = cmg.num_pedido_veh
        inner join gen_moneda gm
        on gm.cod_moneda  =  (case a.moneda when 'DOL' then 2 when 'SOL' then 1 end)
        -- MBARDALES CONTRATO ANEXOS
        inner join gen_mae_provincia mp
        on mp.cod_id_provincia = cmg.cod_of_registral
        
        --inner join vve_cred_mae_aval cma
        --on cma.cod_per_aval = cmg.cod_pers_prop or cmg.ind_otor in ('F','A')
        
        where vcs.cod_soli_cred = p_cod_soli_cred
        and cmg.ind_tipo_garantia = 'M'
        and vcs.ind_inactivo = 'N'
        and vcs.ind_gara_adic = v_ind_tipo_gara
        
        group by gp.nom_perso,cmg.txt_marca,cmg.txt_modelo,
        vtv.des_tipo_veh,cmg.nro_motor,cmg.nro_chasis,cmg.nro_placa,
        cmg.val_const_gar,cmg.val_realiz_gar,a.val_pre_docu,gm.des_moneda,gm.des_larga_moneda, mp.des_nombre;  

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_GARANTIAS:' || SQLERRM;
    END;
  
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_MOSTRAR_PAGOS_TOTAL
    Proposito : Listar facturas relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     10/02/2020   EBARBOZA  
 ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_MOSTRAR_PAGOS_TOTAL
  (
    p_cod_soli_cred     IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
       select 
        SUM(VAL_MONTO_PAGO) as valMontoCiTotal,
        letra.letras(pkg_factu_elect.obte_valo_oper('XXX',SUM(VAL_MONTO_PAGO)),'dol') as fMontoTextoTotal
        from vve_cred_soli_movi
        where  cod_soli_cred like '%'||p_cod_soli_cred||'%';     
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_MOSTRAR_PAGOS_TOTAL:' || SQLERRM;
  END;
  
 
  PROCEDURE SP_LISTAR_DATOS_ANEXOS
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE, 
    p_cod_oper      IN  arlcrd.cod_oper%TYPE,
    p_factu_cursor  OUT SYS_REFCURSOR,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
  v_txt_marca VARCHAR2(200):='';
  v_txt_modelo VARCHAR2(100):='';
  v_des_tipo_veh  VARCHAR2(100):='';
  v_nro_motor     VARCHAR2(100):='';
  v_nro_chasis   VARCHAR2(100):='';
  v_nro_placa     VARCHAR2(100):='';
  v_monto_gm      NUMBER(10,3) := 90000;
  v_det_leasing1 VARCHAR2(4000):=NULL;
  v_det_list_fact VARCHAR2(4000):=NULL;
  v_det_nota_cred VARCHAR2(4000):=NULL;
  
  BEGIN
     
     BEGIN
     
         SELECT cmg.txt_marca,cmg.txt_modelo,tv.des_tipo_veh,cmg.nro_motor,cmg.nro_chasis,cmg.nro_placa
          INTO  v_txt_marca,v_txt_modelo,v_des_tipo_veh,v_nro_motor,v_nro_chasis,v_nro_placa
         FROM vve_cred_maes_gara cmg
          INNER JOIN vve_cred_soli_gara csg ON cmg.cod_garantia = csg.cod_gara
          INNER JOIN vve_cred_soli cs ON csg.cod_soli_cred  = cs.cod_soli_cred
          INNER JOIN vve_tipo_veh tv on cmg.cod_tipo_veh =tv.cod_tipo_veh
         WHERE cs.cod_soli_cred = p_cod_soli_cred  AND 
              csg.ind_inactivo = 'N' and 
              csg.ind_gara_adic = 'S';
    EXCEPTION
           WHEN TOO_MANY_ROWS THEN 
           v_txt_marca:= '';
           v_txt_modelo:= '';
           v_des_tipo_veh:= '';
           v_nro_motor:= '';
           v_nro_chasis:= '';
           v_nro_placa:= '';
    END;   
       
  
    OPEN p_factu_cursor FOR
        SELECT no_docu 
        FROM arlcrd 
        WHERE
           cod_oper = p_cod_oper;    
    
    -- SE AGREGO LISTA DE DATOS DE LAS GARANTIAS      
    FOR rs IN (select 
           (replace((SELECT UPPER( letra.letras(can_veh_fin, null)) FROM vve_cred_soli_prof where cod_soli_cred = p_cod_soli_cred), '  Y  00/100 SOLES', '')) 
           as can_veh_letras,
           (SELECT '(' || can_veh_fin || ')' FROM vve_cred_soli_prof where cod_soli_cred = p_cod_soli_cred) as can_veh,
           des_tipo_veh, txt_marca, txt_modelo
           from vve_tipo_veh tv 
           inner join vve_cred_maes_gara mg on (tv.cod_tipo_veh = mg.cod_tipo_veh)
           inner join vve_cred_soli_gara sg on (mg.cod_garantia = sg.cod_gara) 
           inner join vve_cred_soli_prof sp on (sp.cod_soli_cred = sg.cod_soli_cred)
           where sg.cod_soli_cred = p_cod_soli_cred) LOOP
           
           IF v_det_leasing1 IS NULL THEN
              v_det_leasing1 := (CASE WHEN trim(rs.can_veh_letras) = 'UNO' THEN 'UN' ELSE rs.can_veh_letras END) || ' ' || rs.can_veh || ' ' || rs.des_tipo_veh || ' ' || rs.txt_marca || ' ' || rs.txt_modelo;
           ELSE 
              v_det_leasing1 := v_det_leasing1 || '' || ', y ' || (CASE WHEN trim(rs.can_veh_letras) = 'UNO' THEN 'UN' ELSE rs.can_veh_letras END) || ' ' || rs.can_veh || ' ' || rs.des_tipo_veh || ' ' || rs.txt_marca || ' ' || rs.txt_modelo;
           END IF;
           
    END LOOP;
    
    dbms_output.put_line(v_det_leasing1);
    
    -- SE AGREGO LISTA DE FACTURAS PARA LEASING
    FOR rs IN (SELECT distinct(substr(aff.no_factu,1,4)||'-'||substr(aff.no_factu,5,length(aff.no_factu)-4)) no_docu
                FROM ARFAFE aff
                INNER JOIN vve_cred_maes_gara cmg ON aff.no_orden_desc = cmg.num_pedido_veh
                INNER JOIN  vve_cred_soli_gara csg ON csg.cod_gara = cmg.cod_garantia 
                WHERE csg.cod_soli_cred = p_cod_soli_cred) LOOP
              
               IF (v_det_list_fact IS NULL) THEN
                  v_det_list_fact := rs.no_docu;
               ELSE 
                  v_det_list_fact := v_det_list_fact || ', ' || rs.no_docu;
               END IF;
    END LOOP;
        
    dbms_output.put_line(v_det_list_fact);
    
    -- SE AGREGO LISTA DE DETALLE DE NOTAS DE CREDITO PARA LEASING
    FOR rs IN (select txt_nro_documento,
        CASE WHEN (sm.cod_moneda = '2' OR sm.cod_moneda = 'DOL') THEN 'USD $' ELSE 'S/.' END AS nome_moneda_docu,
        val_monto_pago, to_char(fec_movi_pago, 'DD') as dia, to_char(fec_movi_pago, 'Month','nls_date_language=spanish') as mes, 
        to_char(TO_DATE(fec_movi_pago), 'YYYY') as anio, a.descrip as comp_nota_cred
        from vve_cred_soli_movi sm 
        inner join vve_cred_soli s on (sm.cod_soli_cred = s.cod_soli_cred)
        inner join arccct a on (a.no_cia = sm.cod_empresa_cargo)
        where cod_tipo_movi_pago = '8' and sm.cod_soli_cred = p_cod_soli_cred order by cod_id_soli_tipm) LOOP
      
        dbms_output.put_line(rs.nome_moneda_docu);
        dbms_output.put_line(rs.dia);
        dbms_output.put_line(rs.mes);
        dbms_output.put_line(rs.anio);
        dbms_output.put_line(rs.comp_nota_cred);
        
        IF (v_det_nota_cred IS NULL) THEN
            v_det_nota_cred := 'N°' || ' ' || rs.txt_nro_documento || ' (' || trim(rs.nome_moneda_docu) || ' ' || to_char(rs.val_monto_pago, '999,999.99') || ') de fecha ' || rs.dia || ' de ' || trim(rs.mes) || ' del ' || rs.anio || ' entendida(s) por ' || rs.comp_nota_cred;
        ELSE 
            v_det_nota_cred := v_det_nota_cred || ', ' || 'N°' || ' ' || rs.txt_nro_documento || ' (' || trim(rs.nome_moneda_docu) || ' ' || to_char(rs.val_monto_pago, '999,999.99') || ') de fecha ' || rs.dia || ' de ' || trim(rs.mes) || ' del ' || rs.anio || ' entendida(s) por ' || rs.comp_nota_cred;
        END IF;
      
    END LOOP;
    
    dbms_output.put_line(v_det_nota_cred);
    
    OPEN p_ret_cursor FOR
        SELECT ar.descrip nom_cia,
               CASE WHEN cs.tip_soli_cred = 'TC01' THEN '' 
               ELSE ( SELECT gp.nom_comercial FROM gen_persona gp WHERE cs.cod_banco = gp.cod_perso ) END nom_banco,
               v_txt_marca marca ,
               v_txt_modelo modelo ,
               v_des_tipo_veh des_tipo_veh,
               v_nro_motor nro_motor,
               v_nro_chasis nro_chasis,
               v_nro_placa nro_placa,
               gm.des_moneda nom_moneda,
               cs.val_ci   monto_ci,
               cs.val_mon_fin monto_fin,
               gm.des_larga_moneda descripcion_moneda,
               (SELECT UPPER( letra.letras(
               cs.val_mon_fin
               ,CASE WHEN cs.cod_mone_soli = 1 THEN 'SOL' ELSE 'DOL' END)) FROM DUAL) monto_letras_fin,
               (SELECT UPPER( letra.letras(
               cs.val_ci
               ,CASE WHEN cs.cod_mone_soli = 1 THEN 'SOL' ELSE 'DOL' END)) FROM DUAL) monto_letras_ci,
               v_monto_gm monto_gm,
               (SELECT UPPER( letra.letras(
               v_monto_gm
               ,CASE WHEN cs.cod_mone_soli = 1 THEN 'SOL' ELSE 'DOL' END)) FROM DUAL) monto_letras_gm,
               (v_monto_gm *0.80) monto_vm,
               (SELECT UPPER( letra.letras(
               (v_monto_gm *0.80)
               ,CASE WHEN cs.cod_mone_soli = 1 THEN 'SOL' ELSE 'DOL' END)) FROM DUAL) monto_letras_vm,
               -- CONTRATO ANEXO LEASING 1 MBARDALES
               v_det_leasing1 as deta_leasing_uno,
               v_det_list_fact as deta_list_fact,
               v_det_nota_cred as deta_nota_cred
                
        FROM vve_cred_soli cs
        INNER JOIN arccct ar on cs.cod_empr = ar.no_cia
        --INNER JOIN gen_persona gp on cs.cod_banco =  gp.cod_perso
        INNER JOIN gen_moneda gm on cs.cod_mone_soli = gm.cod_moneda
        WHERE cs.cod_soli_cred =p_cod_soli_cred;        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_DATOS_ANEXOS:' || SQLERRM;
  END;    
  
 PROCEDURE SP_OBTENER_DATOS_CAB_CRON
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE, 
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_crono     OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    v_sum_letras    NUMBER;
    v_mont_pena     NUMBER;
    v_nro_cuot_grac NUMBER;
    v_lista_cuot_grac VARCHAR(1000);
    v_cod_simu vve_cred_simu.cod_simu%TYPE;
    v_sum_val_mont_letr NUMBER;
    v_count_gara_adic NUMBER;
    v_can_dias_peri_grac_letr VARCHAR(2000);
    v_cod_oper_rel VARCHAR2(12);
    
  BEGIN
  
    SELECT can_letr_peri_grac INTO v_nro_cuot_grac FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;
    SELECT cod_simu INTO v_cod_simu FROM vve_cred_simu WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';
    SELECT SUM(val_mont_letr) INTO v_sum_val_mont_letr FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu;
    SELECT COUNT(*) INTO v_count_gara_adic FROM vve_cred_soli_gara WHERE cod_soli_cred = p_cod_soli_cred AND ind_gara_adic = 'S';
    SELECT cod_oper_rel INTO v_cod_oper_rel FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;
    
    SELECT CASE 
    WHEN can_dias_venc_1ra_letr = 30 THEN 'Treinta días'
    WHEN can_dias_venc_1ra_letr = 60 THEN 'Sesenta días'
    WHEN can_dias_venc_1ra_letr = 90 THEN 'Noventa días'
    WHEN can_dias_venc_1ra_letr = 120 THEN 'Ciento veinte días'
    WHEN can_dias_venc_1ra_letr = 150 THEN 'Ciento cincuenta días'
    WHEN can_dias_venc_1ra_letr = 180 THEN 'Ciento ochenta días'
    WHEN can_dias_venc_1ra_letr = 210 THEN 'Doscientos diez días'
    WHEN can_dias_venc_1ra_letr IS NULL THEN '-'
    END INTO v_can_dias_peri_grac_letr
    FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;
  
    IF (v_count_gara_adic > 0) THEN 
      v_mont_pena := (0.10 * v_sum_val_mont_letr);
    ELSE 
      v_mont_pena := 0.00;
    END IF;
  

    FOR cuotas IN 1..v_nro_cuot_grac LOOP
      IF v_lista_cuot_grac IS NULL THEN
        v_lista_cuot_grac := cuotas;
      ELSE 
        v_lista_cuot_grac := v_lista_cuot_grac || ', ' || cuotas;
      END IF;
    END LOOP;
     
    OPEN p_ret_cursor FOR
        SELECT cs.cod_clie cod_cliente,
        gp.nom_perso cliente,
        cs.val_gasto_admi gastos_admin,
        cs.val_tcea tcea,
        cs.cod_peri_cred_soli cod_perio_letra,
        m.descripcion  perio_letra,
        cs.cod_mone_soli cod_moneda,
        gm.des_larga_moneda moneda ,
        cs.val_porc_tea_sigv tea,
        cs.can_plaz_mes  plazo_meses,
        (select sum(can_tota_letr + can_letr_peri_grac )from vve_cred_soli
        where cod_soli_cred = p_cod_soli_cred) num_cuotas,
        -- cs.can_tota_letr num_letras,
        -- CAMBIO OBS CONTRATOS Y ANEXOS MBARDALES
        (select sum(can_tota_letr + can_letr_peri_grac )from vve_cred_soli
        where cod_soli_cred = p_cod_soli_cred) num_letras,
        cs.val_mon_fin monto_financiar,
        cs.val_dias_peri_grac venc_prim_letra,
        (select v_lista_cuot_grac from dual) AS lista_cuota_grac, 
        (select v_mont_pena from dual) AS monto_penalidad,
        (SELECT can_dias_venc_1ra_letr FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred) AS nro_dias_pago,
        (SELECT v_can_dias_peri_grac_letr FROM dual) AS can_dias_grac_letras
        FROM vve_cred_soli cs
        INNER JOIN gen_persona gp on  cs.cod_clie = gp.cod_perso
        INNER JOIN vve_tabla_maes m ON (m.cod_tipo = cs.cod_peri_cred_soli)
        INNER JOIN gen_moneda gm on ( cs.cod_mone_soli = gm.cod_moneda)
        WHERE cs.cod_soli_cred = p_cod_soli_cred; 
        
    dbms_output.put_line(v_cod_oper_rel);     
        
    OPEN p_ret_crono FOR
        select nro_sec as cod_nume_letra, no_letra as num_letra, monto_inicial as saldo_inicial, amortizacion as capital, intereses as interes, igv as igv, 
        cuota as cuota, decode(val_seguro_veh,null,0,val_seguro_veh) as seguro, decode(igv_seguro,null,0,igv_seguro) as igv_seg_veh, to_char(f_vence, 'DD/MM/YYYY') as fec_venc
        from arlcml where cod_oper = v_cod_oper_rel ORDER BY nro_sec;
    
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_OBTENER_DATOS_CAB_CRON:' || SQLERRM;
  END;
  
  FUNCTION FN_OBTE_RUTA_DOC
  (
    p_cod_soli_cred IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_cod_tipope    IN gen_operacion_legal.cod_tipope%TYPE,
    p_cod_opeleg    IN gen_operacion_legal.cod_opeleg%TYPE,
    p_tip_opc       IN VARCHAR2
  ) RETURN VARCHAR AS
    v_return vve_cred_fina_docu.txt_ruta_doc%TYPE;
  BEGIN
        SELECT CASE 
                    WHEN fd.txt_ruta_doc IS NOT NULL THEN fd.txt_ruta_doc
                    WHEN gd.txt_ruta_doc IS NOT NULL THEN gd.txt_ruta_doc
                    WHEN ad.txt_ruta_doc IS NOT NULL THEN ad.txt_ruta_doc
                    ELSE NULL     
               END
        INTO v_return       
        FROM vve_cred_mae_docu a
        LEFT OUTER JOIN vve_cred_fina_docu fd on
            fd.cod_docu_eval = a.cod_docu_eval and
            fd.cod_soli_cred = p_cod_soli_cred
        LEFT OUTER JOIN vve_cred_soli_gara_docu gd on
            gd.cod_docu_eval = a.cod_docu_eval and
            gd.cod_soli_cred = p_cod_soli_cred
        LEFT OUTER JOIN vve_cred_mae_aval_docu ad on 
            ad.cod_docu_eval = a.cod_docu_eval and
            ad.cod_soli_cred = p_cod_soli_cred
        WHERE (
                p_tip_opc = 'RP' AND EXISTS (
                SELECT 'x'
                FROM gen_documento_legal d, gen_operacion_legal o 
                WHERE o.descripcion = d.descripcion 
                    AND d.cod_docleg = a.cod_docleg 
                    AND o.cod_tipope = p_cod_tipope 
                    AND o.cod_opeleg = p_cod_opeleg)
            ) OR (
                p_tip_opc = 'GM' AND EXISTS (
                SELECT 'x'
                FROM gen_documento_legal d, gen_dtipo_operacion o 
                WHERE o.descripcion = d.descripcion 
                    AND d.cod_docleg = a.cod_docleg 
                    AND o.ind_inactivo='N'
                    AND o.cod_dtipope=p_cod_tipope
                    AND o.cod_tipope IN(
                        SELECT tipe.cod_tipope 
                        FROM   gen_tipo_operacion tipe
                        WHERE  tipe.cod_natope='GM'))                
            );    
    RETURN v_return;
  END FN_OBTE_RUTA_DOC;
  
  

END PKG_SWEB_CRED_SOLI_LEGAL;