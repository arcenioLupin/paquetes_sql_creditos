create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_LEGAL IS

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
    p_nro_expediente      IN gen_solicitud_credito.nro_expediente%TYPE,
    p_nom_perso      IN gen_persona.nom_perso%TYPE,
    p_cod_estleg       IN gen_estado_legal.cod_estleg%TYPE,
    p_no_cia           IN arcgmc.no_cia%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
 
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
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ord_titdoc    IN  gen_titulo_documento.ord_titdoc%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
 
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
  );
  
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
  );
  
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
  );
 
/*-----------------------------------------------------------------------------
Nombre : SP_ACTUALIZAR_CHKLIST_DOC_LEGALES
Proposito : Actualizar checklist
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
  );
  
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
  );
  
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
  );
  
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
  );
  
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
  );
 
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
  );
  
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
  );
  
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
  );
  
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
  );
  
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
  );
  
           /*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_CHK_CONREGISTRO
Proposito : Listar los documentos que son necesarios para la operación legal
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 04/08/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LISTAR_CHK_CONREGISTRO
  (
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );


/*-----------------------------------------------------------------------------
Nombre : SP_REGISTRA_OPERACION_LEGAL
Proposito : Registra la operación legal
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 08/04/2019   MGRASSO  
 07/05/2019   AVILCA      Se modifica para que inserte y actualize
----------------------------------------------------------------------------*/
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
  );
    /*-----------------------------------------------------------------------------
        Nombre : SP_ELIMINA_OPERACION_LEGAL
        Proposito : Elimina la operación legal
        Referencias : 
        Parametros :
        Log de Cambios 
          Fecha        Autor         Descripcion
         14/06/2019   AVILCA          Creación
----------------------------------------------------------------------------*/
  PROCEDURE SP_ELIMINA_OPERACION_LEGAL
  (
    p_cod_docrev        IN  gen_documento_revision.cod_docrev%TYPE,
    p_cod_solcre        IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_cod_usuario       IN  gen_documento_revision.cod_usuario_crea%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
  
           /*-----------------------------------------------------------------------------
Nombre : SP_REGISTRA_PERSONA_FACULTADA
Proposito : Registra la persona facultada
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 09/04/2019   MGRASSO  
 07/05/2019   AVILCA         Se modifica para que inserte y actualice
----------------------------------------------------------------------------*/
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
  );
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRA_DOCUMENTO_REVISION
    Proposito : Registra la persona facultada
    Referencias : 
    Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 10/04/2019   MGRASSO  
 07/05/2019   AVILCA      Se modificó para que inserte y actualice 
----------------------------------------------------------------------------*/
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
  );
  
             /*-----------------------------------------------------------------------------
Nombre : SP_LISTAR_OPELEGAL_SOLCRE
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
  );
  
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
  );

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
  );

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
  );
  
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
  );
  
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
  );
  
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
  );
  
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
   ); 
 
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
  ); 
  
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
  ); 
  
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
    p_cod_solcre IN  gen_solicitud_credito.cod_solcre%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
  
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
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_REGISTRAR_GARA_HIP
    Proposito : Registrar garantía hipotecaria.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     29/04/2019   AVILCA  
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
  );
  
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
  );
  
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
  ) ;
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
  );
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
  );
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
  ); 
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
  );
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
  ); 
  
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
  );
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
  );  
      /*-----------------------------------------------------------------------------
    Nombre : SP_ACT_RUTA_ANEXO_CONTRATO
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
    p_url                IN  vve_cred_soli.txt_ruta_anex %TYPE,
    p_tipo_doc           IN  VARCHAR2,
    p_cod_usuario        IN gen_solicitud_credito.cod_usuario_crea%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ); 
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
  );
  
   /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_ANEXOS_PAGOS
    Proposito : Listar pagos relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
/    07/02/2020    EBARBOZA  
 /----------------------------------------------------------------------------*/ 
  
   PROCEDURE SP_LISTAR_ANEXOS_PAGOS
  (
    p_cod_soli_cred     IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  );
  
  /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_GARANTIAS
    Proposito : Listar pagos relacionadas a un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
/    07/02/2020    EBARBOZA  
 /----------------------------------------------------------------------------*/ 
  
  
  PROCEDURE SP_LISTAR_GARANTIAS
  (
    p_cod_soli_cred     IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_ind_tipo_gara     IN  VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  
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
  );
    /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_DATOS_ANEXOS
    Proposito : Listar datos para la impresión de un anexo.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     29/05/2019   AVILCA  
 ----------------------------------------------------------------------------*/ 
  PROCEDURE SP_LISTAR_DATOS_ANEXOS
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE, 
    p_cod_oper      IN  arlcrd.cod_oper%TYPE,
    p_factu_cursor  OUT SYS_REFCURSOR,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );
/*-----------------------------------------------------------------------------
    Nombre : SP_OBTENER_DATOS_CAB_CRON
    Proposito : Obtener datos de cabecera para la impresión del cronograma.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     31/05/2019   AVILCA  
 ----------------------------------------------------------------------------*/  
  PROCEDURE SP_OBTENER_DATOS_CAB_CRON
  (
    p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE, 
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_crono     OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );
  
 /*-----------------------------------------------------------------------------
    Nombre : FN_OBTE_RUTA_DOC
    Proposito : Obtener la ruta del documento sea legal, garantia o aval.
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
      10/12/2019   PHRAMIREZ  
 ----------------------------------------------------------------------------*/
  FUNCTION FN_OBTE_RUTA_DOC
  (
    p_cod_soli_cred IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_cod_tipope    IN gen_operacion_legal.cod_tipope%TYPE,
    p_cod_opeleg    IN gen_operacion_legal.cod_opeleg%TYPE,
    p_tip_opc       IN VARCHAR2
  ) RETURN VARCHAR;
 
END PKG_SWEB_CRED_SOLI_LEGAL;