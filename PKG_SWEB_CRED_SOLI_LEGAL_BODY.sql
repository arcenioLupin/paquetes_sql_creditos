create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_LEGAL IS
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
        select gs.cod_solcre,s.cod_soli_cred,gs.nro_expediente,ge.descripcion,
        a.nombre, p.nom_perso,(case p.cod_tipo_perso when 'J' then 'JURÍDICA' when 'N' then 'NATURAL' end) AS TIPOPERSONA,
        gs.fecha_revision, gs.fecha_caduca
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
        and (p_cod_soli_cred is null or s.cod_soli_cred like '%'||p_cod_soli_cred||'%')
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
            OPEN p_ret_cursor FOR
              SELECT cod_docleg,descripcion,'N' ind_oblig 
              FROM gen_documento_legal
              WHERE cod_titdoc = p_ord_titdoc;
              p_ret_esta := 1;
              p_ret_mens := 'La consulta se realizó de manera exitosa';
        
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
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg     IN  gen_documento_legal.COD_DOCLEG%TYPE,
    p_ind_oblig         IN  vve_cred_fina_docu.ind_oblig%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    UPDATE vve_cred_fina_docu
    SET IND_OBLIG=p_ind_oblig
    WHERE cod_docu_eval=(select cod_docu_eval from vve_cred_mae_docu where cod_docleg=p_cod_docleg)
    AND COD_SOLI_CRED=(select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre);
    COMMIT;
    p_ret_mens := 'Se actualizó el chklist con exito';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_LEGALES:' || SQLERRM;
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
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg     IN  gen_documento_legal.cod_docleg%TYPE,
    p_ind_oblig         IN  vve_cred_soli_gara_docu.ind_oblig%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    UPDATE vve_cred_soli_gara_docu
    SET IND_OBLIG=p_ind_oblig
    WHERE cod_docu_eval=(select cod_docu_eval from vve_cred_mae_docu where cod_docleg=p_cod_docleg)
    AND COD_SOLI_CRED=(select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre);
    COMMIT;
    p_ret_mens := 'Se actualizó el chklist con exito';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_GARA:' || SQLERRM;
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
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_docleg     IN  gen_documento_legal.cod_docleg%TYPE,
    p_ind_oblig         IN  vve_cred_mae_aval_docu.ind_oblig%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS
  BEGIN
    UPDATE vve_cred_mae_aval_docu
    SET IND_OBLIG=p_ind_oblig
    WHERE cod_docu_eval=(select cod_docu_eval from vve_cred_mae_docu where cod_docleg=p_cod_docleg)
    AND COD_SOLI_CRED=(select cod_soli_cred from vve_cred_soli where cod_solcre_legal=p_cod_solcre);
    COMMIT;
    p_ret_mens := 'Se actualizó el chklist con exito';
    p_ret_esta := 1;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTUALIZAR_CHK_DOC_AVAL:' || SQLERRM;
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
        SELECT a.cod_tipope,a.cod_opeleg, a.descripcion
        FROM gen_operacion_legal a,gen_tipo_operacion b,
        gen_plantilla_operacion c,
        gen_estructura_operacion d, 
        gen_solicitud_credito e
        WHERE a.cod_tipope=b.cod_tipope
        AND a.cod_tipope=c.cod_tipope
        AND c.cod_estope=d.cod_estope 
        AND e.cod_estope=d.cod_estope
        AND b.cod_natope<>'FSJ'
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
 04/03¡4/2019   MGRASSO  
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
 04/03¡4/2019   MGRASSO  
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
  BEGIN
    IF p_cod_ddorev = 0 THEN
        select max(cod_ddorev)+1 into p_cod_ddorev_out from gen_ddocumento_revision;
        Insert into gen_ddocumento_revision values(p_cod_ddorev_out,p_cod_docrev,
        p_cod_opeleg,p_cod_tipope,p_ind_conforme,sysdate,p_cod_usuario,sysdate,p_cod_usuario,'N');
        COMMIT;
        p_cod_docrev_out := p_cod_docrev;
        p_ret_mens := 'Se registró el documento a revisar';
        p_ret_esta := 1;   
    ELSE
        UPDATE gen_ddocumento_revision
         SET cod_opeleg = p_cod_opeleg,
             cod_tipope = p_cod_tipope,
             ind_conforme = p_ind_conforme,
             fec_modi_reg = sysdate,
             cod_usuario_modi = p_cod_usuario
         WHERE
             cod_ddorev = p_cod_ddorev AND
             cod_docrev = p_cod_docrev;
        COMMIT;
        p_cod_docrev_out := p_cod_docrev;
        p_cod_ddorev_out := p_cod_ddorev;
        p_ret_mens := 'Se registró el documento a revisar';
        p_ret_esta := 1;     
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGISTRA_DOCUMENTO_REVISION:' || SQLERRM;
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
     07/05/2019   AVILCA         Se modifica para que inserte y actualice
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
  BEGIN
    select max(cod_solcre)+1 into p_cod_solcre from gen_solicitud_credito;
    Insert Into gen_solicitud_credito (cod_solcre,cod_estope,no_cia,cod_estleg,nro_expediente,cod_clie,fecha_solcre,fecha_revision,fecha_caduca,fec_crea_reg,cod_usuario_crea,fec_modi_reg,cod_usuario_modi,ind_inactivo)
    values (p_cod_solcre,p_cod_estope,p_no_cia,p_cod_estleg,p_nro_expediente,p_cod_clie,p_fecha_solcre,p_fecha_revision,p_fecha_caduca,sysdate,p_cod_usuario,sysdate,p_cod_usuario,'N');
    COMMIT;
    p_ret_mens := 'Se registró la solicitud legal';
    p_ret_esta := 1;
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
     select g.cod_garantia,g.COD_PERS_PROP, p.cod_tipo_perso, p.nom_perso, g.txt_marca,g.txt_modelo, g.nro_placa,g.val_ano_fab
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
     and ind_tipo_garantia='M';
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
                              WHERE  cod_natope='GM')
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
     29/04/2019   AVILCA  
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
     select g.cod_garantia,g.COD_PERS_PROP, p.cod_tipo_perso, p.nom_perso,p.ape_paterno,p.ape_materno,p.nom_1,p.nom_2, g.txt_direccion
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
     and ind_tipo_garantia='H';
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
        SELECT alcv.nom_aval nom_fiador,
        CASE (SELECT instr(alcv.nom_aval,'/')FROM dual) WHEN 0 THEN 'I' ELSE 'C' END tipo_fianza,
        'D' tipo_doc,
        CASE (SELECT instr(alcv.nom_aval,'/')FROM dual) WHEN 0 THEN 'I' ELSE 'C' END parentesco,
        alcv.le doi,
        alcv.cod_oper
        /*(select cod_tipope from gen_documento_revision
        where cod_solcre=127 and ind_inactivo='N') cod_tipope*/
        FROM lxc.arlcav alcv
        INNER JOIN vve_cred_soli csl ON
        alcv.cod_oper = csl.cod_oper_rel
        WHERE csl.cod_solcre_legal = p_cod_solcre;
        p_ret_mens := 'La consulta se realizó correctamente!';
        p_ret_esta := 1;
        EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'SP_LISTAR_FIANZAS_SOLIDARIAS:' || SQLERRM;
  END; 
  
  
/*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DOCS_FSN
    Proposito : Listar documentos de fianza solidaria PN
    Referencias : 
    Parametros :
  Log de Cambios 
  Fecha        Autor         Descripcion
 09/05/2019   AVILCA  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_DOCS_FSN
  (
    p_cod_solcre  IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_tipope  IN gen_operacion_legal.cod_tipope%TYPE,
    p_ret_cursor  OUT SYS_REFCURSOR,
    p_ret_esta    OUT NUMBER,
    p_ret_mens    OUT VARCHAR2
  )AS
  BEGIN
    open p_ret_cursor for
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
          SELECT * FROM gen_canexo_legal      
          WHERE cod_solcre = p_cod_solcre AND
                cod_tipope = v_cod_tipope;
                
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
    p_cod_canleg        IN  gen_danexo_legal.cod_canleg%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  )AS

  BEGIN     
      open p_ret_cursor for
        
         SELECT glc.cod_danleg,glc.cod_canleg,glc.cod_dtipope,glc.cod_tipope,glc.ind_conforme,glc.observacion,gto.descripcion 
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
               /*
               tc.descripcion TIP_SOLI_CRED,
               tc.cod_tipo cod_tipo_cred
               */
               /*
               'Recon. de Deuda' TIP_SOLI_CRED,
               'TC01' cod_tipo_cred
               */
               /*
               'Recon. de Deuda Leasing' TIP_SOLI_CRED,
               'TC02' cod_tipo_cred
               */
                'Crédito Mutuo' TIP_SOLI_CRED,
                'TC03' cod_tipo_cred
        FROM vve_cred_soli s,vve_tabla_maes tc
        WHERE 
              (s.cod_oper_rel is null or s.cod_oper_rel like '%'||p_cod_oper_rel||'%') 
         AND  (s.cod_soli_cred is null or s.cod_soli_cred like '%'||p_cod_soli_cred||'%')
         AND  s.TIP_SOLI_CRED = tc.cod_tipo
         and cod_oper_rel is not null;        
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
     20/05/2019   AVILCA  
    ----------------------------------------------------------------------------*/
  PROCEDURE SP_ACT_RUTA_ANEXO_CONTRATO
  (

    p_cod_soli_cred      IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_txt_ruta_anex      IN  vve_cred_soli.txt_ruta_anex %TYPE,
    p_txt_ruta_contrato  IN  vve_cred_soli.txt_ruta_contrato %TYPE,
    p_txt_ruta_docs_firm IN  vve_cred_soli.txt_ruta_docs_firm %TYPE,
    p_cod_usuario        IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  )AS

  BEGIN
  
             UPDATE  vve_cred_soli
                SET txt_ruta_anex      = p_txt_ruta_anex,
                    txt_ruta_contrato  = p_txt_ruta_contrato,
                    txt_ruta_docs_firm = p_txt_ruta_docs_firm,
                    cod_usua_modi      = p_cod_usuario,
                    fec_modi_regi      = sysdate
                 WHERE cod_soli_cred = p_cod_soli_cred ;
                COMMIT;

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
    p_cod_oper     IN  arlcrd.cod_oper%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
        SELECT * 
        FROM arlcrd
        WHERE 
              cod_oper = p_cod_oper;        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LISTAR_ANEXOS_FACTURAS:' || SQLERRM;
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
  
    OPEN p_factu_cursor FOR
        SELECT no_docu 
        FROM arlcrd 
        WHERE
              cod_oper = p_cod_oper;        
        
  
    OPEN p_ret_cursor FOR
        SELECT ar.descrip nom_cia,
               gp.nom_comercial nom_banco,
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
                  ,CASE WHEN cs.cod_mone_soli = 1 THEN 'SOL' ELSE 'DOL' END)) FROM DUAL) monto_letras_vm
        FROM vve_cred_soli cs
        INNER JOIN arccct ar on cs.cod_empr = ar.no_cia
        INNER JOIN gen_persona gp on cs.cod_banco = gp.cod_perso 
        INNER JOIN gen_moneda gm on cs.cod_mone_soli = gm.cod_moneda
        WHERE cs.cod_soli_cred = p_cod_soli_cred;        
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
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
  BEGIN
     
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
        cs.can_tota_letr num_letras,
        cs.val_mon_fin monto_financiar,
        cs.val_dias_peri_grac venc_prim_letra
        FROM vve_cred_soli cs
        INNER JOIN gen_persona gp on  cs.cod_clie = gp.cod_perso
        INNER JOIN vve_tabla_maes m ON (m.cod_tipo = cs.cod_peri_cred_soli)
        INNER JOIN gen_moneda gm on ( cs.cod_mone_soli = gm.cod_moneda)
        WHERE cs.cod_soli_cred = p_cod_soli_cred;        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_OBTENER_DATOS_CAB_CRON:' || SQLERRM;
  END;     
END PKG_SWEB_CRED_SOLI_LEGAL; 