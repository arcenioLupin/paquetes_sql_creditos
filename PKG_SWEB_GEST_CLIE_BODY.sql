create or replace PACKAGE BODY  VENTA.PKG_SWEB_GEST_CLIE AS
/******************************************************************************
   NAME:    PKG_SWEB_CLIENTE
   PURPOSE: Contiene procedimientos para la gestion de clientes. 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        21/09/2016  ACRUZ            1. Created this package.
******************************************************************************/



/*-----------------------------------------------------------------------------
Nombre : SP_LIST_CLIE
Proposito : Lista de clientes para la selección en  filtros 
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  05/08/2016   ACRUZ      Creacion
  12/06/2017   LVALDERRAMA      MODIFICACION
                                -SP_LIST_CLIE  se agrego tipo persona  <v1>
  16/10/2017   PHRAMIREZ        REQ 84289 - Registro de Oportunidad - CRM            
  14/11/2019  PBALVIN          Afinamiento de Código  
----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_CLIE
  (
    P_CADENAB     IN VARCHAR,
    P_DOC         IN VARCHAR,
    P_COD_CLIENTE IN VARCHAR,
    P_LIMITINF    IN VARCHAR,
    P_LIMITSUP    IN INTEGER,
    L_CURSOR      OUT SYS_REFCURSOR,
    L_CANTIDAD    OUT VARCHAR
  ) AS
  L_QUERY     VARCHAR2(5000) DEFAULT '';
  wc_sql_2    VARCHAR2(5000) DEFAULT '';
  wc_sql_3    VARCHAR2(5000) DEFAULT '';
  wc_parcial  VARCHAR2(5000) DEFAULT '';
  v_nom_perso gen_persona .nom_perso%TYPE;

  v_sql_pagi VARCHAR2(4000);
  v_sql_base VARCHAR2(4000);
  v_sql_tota VARCHAR2(4000);

BEGIN
  v_nom_perso := TRANSLATE(TRIM(upper(P_CADENAB)), 'ÁÉÍÓÚ', 'AEIOU');
  --<I-v1>
  v_sql_base  := '
  SELECT PER.cod_perso cod_clie, PER.NOM_PERSO nom_clie ,PER.NUM_DOCU_IDEN dni, PER.NUM_RUC ruc, 
  --<I 84289>
  DECODE(SUBSTR(MC.COD_CLIE_SAP,4,7),NULL,SUBSTR(MP.COD_CLIE_SAP,4,7),SUBSTR(MC.COD_CLIE_SAP,4,7)) AS COD_CLIE_SAP, 
  --<F 84289>
  row_number() over(order by PER.NOM_PERSO) rm,
  PER.COD_TIPO_PERSO persona 
  FROM GEN_PERSONA PER
  --<I 84289>
  LEFT JOIN CXC_MAE_CLIE MC
     ON MC.COD_CLIE = PER.cod_perso  
  LEFT JOIN CXC_CLIE_PROS MP
       ON MP.COD_CLIE_PROS = PER.cod_perso     
  --<F 84289>
  WHERE NVL(PER.IND_INACTIVO, ''N'') = ''N'' '; --<F-v1>
  IF P_CADENAB IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) ||
                  ' AND TRANSLATE(UPPER(PER.NOM_PERSO), ''ÁÉÍÓÚ'', ''AEIOU'')  LIKE ' ||
                  '''%' || v_nom_perso || '%''';
  END IF;
  IF P_DOC IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) || ' AND ( PER.NUM_RUC = ''' || P_DOC ||
                  ''' OR PER.NUM_DOCU_IDEN = ''' || P_DOC || ''')';
  END IF;

  IF P_COD_CLIENTE IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) || ' and PER.cod_perso = ''' ||
                  P_COD_CLIENTE || '''';
  END IF;
   --<I-pbalvin>
  --v_sql_tota := 'select count(*) from (' || v_sql_base || ')';
    v_sql_tota := 'select count(1) from (' || v_sql_base || ')';
   --<F-pbalvin>
  EXECUTE IMMEDIATE v_sql_tota
    INTO L_CANTIDAD;


  --<I-v1>
  --<I 84289>
  v_sql_pagi := 'SELECT cod_clie, nom_clie, dni, ruc, COD_CLIE_SAP, rm, persona   
   FROM ( ' || v_sql_base || ') WHERE RM BETWEEN ' ||
                P_LIMITINF || ' AND ' || P_LIMITSUP || '';--<F 84289>--<F-v1>

  OPEN L_CURSOR FOR v_sql_pagi;

END SP_LIST_CLIE;

/*-----------------------------------------------------------------------------
Nombre : fu_vali_tipo_clie
Proposito : función que valida si la persona esta registrado como cliente: 
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  03/10/2016   ACRUZ         81303-E3 Creacion
----------------------------------------------------------------------------*/
--<I-81303-E3>
FUNCTION fu_vali_tipo_clie(
  p_cod_clie VARCHAR2
  ) RETURN NUMBER IS
  v_ind VARCHAR2(1);
BEGIN  
  BEGIN
    SELECT 1 ind_clie
    INTO v_ind
    FROM gen_persona p, cxc_mae_clie m
    WHERE p.cod_perso = m.cod_clie
      AND nvl(m.ind_inactivo,'N') = 'N'
      AND p.cod_perso = p_cod_clie;
  EXCEPTION
    WHEN OTHERS THEN
      v_ind := 0;

  END;
  RETURN    v_ind;
END;
--<f-81303-E3  >


  /*-----------------------------------------------------------------------------
  Nombre : sp_lis_enti_fina
  Proposito : Lista las entidades para el financiamiento.
  Referencias : 
  Parametros :
  Log de Cambios
    Fecha        Autor         Descripcion
    03/10/2016   acruz         req- 81303-E3     Creacion
  ----------------------------------------------------------------------------*/
  --<I-81303-E3>   
  PROCEDURE sp_list_enti_fina (
     p_ret_curs           OUT SYS_REFCURSOR
    ,p_ret_esta           OUT NUMBER
    ,p_ret_mens           OUT VARCHAR2 
    ) AS
  BEGIN
    OPEN p_ret_curs FOR 
      SELECT p.nom_perso nombre , p.cod_perso id
      FROM gen_persona p, cxp_prov_giros g
      WHERE p.cod_perso = g.cod_prov 
        AND g.cod_giro_perso = '012'
      ORDER BY 1;
    p_ret_esta :=1;
    p_ret_mens := 'Consulta ejecutado de forma exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta :=-1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_ERROR',
                                          'sp_list_enti_fina',
                                          null,
                                          'Error ',
                                          p_ret_mens,
                                          null);
  END;
  --<F-81303-E3>  
/*-----------------------------------------------------------------------------
  Nombre : sp_cliente_sap
  Proposito : Obtiene el codigo del cliente sid a partir del cliente sap.
  Referencias : 
  Parametros :
  Log de Cambios
    Fecha        Autor         Descripcion
    21/12/2016   garroyo         req- 81303-E3     Creacion
  ----------------------------------------------------------------------------*/
  --<I-81303-E3>   
PROCEDURE sp_cliente_sap
(
  p_Cod_Clie_Sap IN Cxc_Mae_Clie.Cod_Clie_Sap%TYPE,
  p_cod_clie_sid OUT vve_proforma_veh.cod_clie%TYPE,
  p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
  p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_esta     OUT NUMBER,
  p_Ret_mens     OUT VARCHAR2
) AS
  ve_error EXCEPTION;
BEGIN

  IF p_Cod_Clie_Sap IS NOT NULL THEN
    BEGIN
      SELECT cod_clie
        INTO p_cod_clie_sid
        FROM Cxc_Mae_Clie
       WHERE cod_clie_sap IS NOT NULL
         AND cod_clie_sap = p_Cod_Clie_Sap;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          SELECT cod_clie_pros
            INTO p_cod_clie_sid
            FROM Cxc_Clie_Pros
           WHERE cod_clie_sap IS NOT NULL
             AND cod_clie_sap = p_Cod_Clie_Sap;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            p_Ret_mens := 'Cliente SAP-CRM no registrado en el SID.';
            p_cod_clie_sid := NULL;
             RAISE ve_error;
          WHEN TOO_MANY_ROWS THEN
            p_Ret_mens :='Cliente SAP-CRM duplicado en el SID.';
            p_cod_clie_sid := NULL;
             RAISE ve_error;
        END;
      WHEN TOO_MANY_ROWS THEN
        p_Ret_mens :=  'Cliente SAP-CRM duplicado en el SID.';
        p_cod_clie_sid := NULL;
         RAISE ve_error;
    END;

  ELSE
        p_Ret_mens :=  'El código del cliente sap no puede ser vacio';
        p_cod_clie_sid := NULL;
        RAISE ve_error;
  END IF;

  p_Ret_mens := 'Consulta exitosa';
  p_ret_esta := 1;
EXCEPTION
  WHEN ve_error THEN
    p_ret_esta := 0;
  WHEN OTHERS THEN

    p_ret_esta := -1;
    p_Ret_mens := 'sp_cliente_sap:' || SQLERRM;
    pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_ERROR',
                                        'sp_cliente_sap',
                                        p_cod_usua_sid,
                                        'Error',
                                        p_Ret_mens,
                                        NULL);

END;
--<F-81303-E3>

PROCEDURE sp_lista_cta_banco
(
  p_no_cia       IN vve_cta_banco.no_cia%TYPE,
  p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
  p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_curs     OUT SYS_REFCURSOR,
  p_ret_esta     OUT NUMBER,
  p_Ret_mens     OUT VARCHAR2
) AS
  ve_error EXCEPTION;
BEGIN

  OPEN p_ret_curs for
        SELECT a.cod_cta_banco, a.txt_nombre nom_comercial, a.cod_moneda, a.cta, a.cci
        FROM vve_cta_banco a

       WHERE a.no_cia = p_no_cia
         AND a.ind_inactivo = 'N'
       ORDER BY a.cod_cta_banco asc;


  p_Ret_mens := 'Consulta exitosa';
  p_ret_esta := 1;
EXCEPTION
  WHEN ve_error THEN
    p_ret_esta := 0;
  WHEN OTHERS THEN

    p_ret_esta := -1;
    p_Ret_mens := 'sp_lista_cta_banco:' || SQLERRM;
    pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_ERROR',
                                        'sp_lista_cta_banco',
                                        p_cod_usua_sid,
                                        'Error al consultar',
                                        p_Ret_mens,
                                        NULL);

END;

/*-----------------------------------------------------------------------------
  Nombre : sp_lista_empleado
  Proposito : Lista empleados.

  Referencias :
  Parametros :

  Log de Cambios
    Fecha        Autor         Descripcion
    10/03/2017   avilca         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_lista_empleado
  (
    p_cod_empleado       IN VARCHAR2,
    p_nom_empleado       IN VARCHAR2, 
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_lim_infe       NUMBER,
    p_lim_supe       NUMBER,
    p_tab            OUT SYS_REFCURSOR,
    p_tot_regi       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
    SQL_STMT            VARCHAR2(10000);
    SQL_STMT_PAGINACION VARCHAR2(10000);
    SQL_WHERE_PARAM     VARCHAR2(10000);

    ve_error EXCEPTION;
  BEGIN
    SQL_STMT := '
                 SELECT no_emple,nombreemple
                 FROM v_sygnus_datos_empleados  
                 WHERE  1=1';

    IF nvl(p_cod_empleado, 0) != 0 THEN
      SQL_STMT := SQL_STMT || ' AND no_emple = ''' ||
                  p_cod_empleado || '''';

    END IF;


    IF nvl(p_nom_empleado, 'x') != 'x' THEN
      SQL_STMT := SQL_STMT || ' AND upper(nombreemple) LIKE ''%' ||
                  p_nom_empleado || '%'' ';
    END IF;

    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || SQL_STMT || ')'
      INTO p_tot_regi;

    SQL_STMT_PAGINACION := 'SELECT x.*  FROM ( SELECT ROWNUM fila, a.*      FROM ( ' ||
                           SQL_STMT || ' ) a ) x';
    SQL_STMT_PAGINACION := SQL_STMT_PAGINACION || '
     WHERE fila BETWEEN ' || p_lim_infe ||
                           ' AND ' || p_lim_supe || '';

    OPEN p_tab FOR SQL_STMT_PAGINACION;

    p_Ret_mens := 'Consulta exitosa';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN

      p_ret_esta := -1;
      p_Ret_mens := 'sp_lista_empleado' || SQLERRM || 'SQL:' || SQL_STMT;
      pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_ERROR',
                                          'sp_lista_empleado',
                                          p_cod_usua_sid,
                                          'Listar empleados',
                                          p_Ret_mens,
                                          NULL);
  END;

  /*-----------------------------------------------------------------------------
  Nombre : fu_vali_mail_clie
  Proposito : función que valida si la persona tiene cuenta de correo. 
  Referencias : 
  Parametros :
  Log de Cambios 
    Fecha        Autor         Descripcion
    26/12/2017   MGELDRES         84921 Creacion
  ----------------------------------------------------------------------------*/
  FUNCTION fu_vali_mail_clie(
    p_cod_clie VARCHAR2
    ) RETURN NUMBER is   
    vcorreo varchar2(200);
    v_resp  NUMBER;
  BEGIN
    BEGIN
      SELECT p.dir_correo
      INTO vcorreo
      FROM gen_persona p
      WHERE p.cod_perso = p_cod_clie;
    EXCEPTION
      WHEN OTHERS THEN
        vcorreo := null;
    END;
    IF  LTRIM(RTRIM(vcorreo)) IS NOT NULL THEN
      IF INSTR(LTRIM(RTRIM(vcorreo)),'@')>0 THEN
        v_resp := 1;
      ELSE
        v_resp := 2;        
      END IF;
    ELSE
      v_resp := 0;  
    END IF;
    RETURN  v_resp;      
  END;


    /*-----------------------------------------------------------------------------
  Nombre : SP_LIST_CLIE_ASIG_PEDIDOS
  Proposito : función que valida si la persona tiene cuenta de correo. 
  Referencias : 
  Parametros :
  Log de Cambios 
    Fecha        Autor         Descripcion
    26/12/2017   ARAMOS         84921 Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE SP_LIST_CLIE_ASIG_PEDIDOS
  (
    P_CADENAB     IN VARCHAR,
    P_DOC         IN VARCHAR,
    P_COD_CLIENTE IN VARCHAR,
    P_LIMITINF    IN VARCHAR,
    P_LIMITSUP    IN INTEGER,
    L_CURSOR      OUT SYS_REFCURSOR,
    L_CANTIDAD    OUT VARCHAR
  ) AS
  L_QUERY     VARCHAR2(5000) DEFAULT '';
  wc_sql_2    VARCHAR2(5000) DEFAULT '';
  wc_sql_3    VARCHAR2(5000) DEFAULT '';
  wc_parcial  VARCHAR2(5000) DEFAULT '';
  v_nom_perso gen_persona .nom_perso%TYPE;

  v_sql_pagi VARCHAR2(4000);
  v_sql_base VARCHAR2(4000);
  v_sql_tota VARCHAR2(4000);

BEGIN
  v_nom_perso := TRANSLATE(TRIM(upper(P_CADENAB)), 'ÁÉÍÓÚ', 'AEIOU');
  --<I-v1>
  v_sql_base  := '
  SELECT PER.cod_perso cod_clie, PER.NOM_PERSO nom_clie ,PER.NUM_DOCU_IDEN dni, PER.NUM_RUC ruc, 
  --<I 84289>
  NULL,
  --<F 84289>
  row_number() over(order by PER.NOM_PERSO) rm,
  PER.COD_TIPO_PERSO persona 
  FROM GEN_PERSONA PER
  WHERE NVL(PER.IND_INACTIVO, ''N'') = ''N''
        AND EXISTS (SELECT 1
            FROM CXC.CXC_MAE_CLIE B
           WHERE B.COD_CLIE = PER.COD_PERSO
             AND NVL(B.IND_INACTIVO, ''N'') = ''N'')';


            pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_OK',
                                        'SP_LIST_CLIE_ASIG_PEDIDOS',
                                        P_COD_CLIENTE,
                                        'Error al consultar',
                                        v_sql_base);


  IF P_CADENAB IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) ||
                  ' AND TRANSLATE(UPPER(PER.NOM_PERSO), ''ÁÉÍÓÚ'', ''AEIOU'')  LIKE ' ||
                  '''%' || v_nom_perso || '%''';
  END IF;
  IF P_DOC IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) || ' AND ( PER.NUM_RUC = ''' || P_DOC ||
                  ''' OR PER.NUM_DOCU_IDEN = ''' || P_DOC || ''')';
  END IF;

  IF P_COD_CLIENTE IS NOT NULL THEN
    v_sql_base := v_sql_base || chr(10) || ' and PER.cod_perso = ''' ||
                  P_COD_CLIENTE || '''';
  END IF;

        pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_OK',
                                        'SP_LIST_CLIE_ASIG_PEDIDOS',
                                        P_COD_CLIENTE,
                                        'Error al consultar',
                                        v_sql_base);


  v_sql_tota := 'select count(*) from (' || v_sql_base || ')';
  EXECUTE IMMEDIATE v_sql_tota
    INTO L_CANTIDAD;


  --<I-v1>
  --<I 84289>
  v_sql_pagi := 'SELECT cod_clie, nom_clie, dni, ruc, rm, persona   
   FROM ( ' || v_sql_base || ') WHERE RM BETWEEN ' ||
                P_LIMITINF || ' AND ' || P_LIMITSUP || '';--<F 84289>--<F-v1>

      pkg_sweb_mae_gene.SP_REGI_RLOG_ERRO('AUDI_OK',
                                        'SP_LIST_CLIE_ASIG_PEDIDOS',
                                        P_COD_CLIENTE,
                                        'Error al consultar',
                                        v_sql_pagi);

  OPEN L_CURSOR FOR v_sql_pagi;



END SP_LIST_CLIE_ASIG_PEDIDOS;


END PKG_SWEB_GEST_CLIE; 