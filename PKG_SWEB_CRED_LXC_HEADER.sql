create or replace PACKAGE   VENTA.PKG_SWEB_CRED_LXC AS
  /* se define este tipo de cursor para la lista de documentos ingresados por pantalla */
  --  TYPE c_fact_x_op is REF CURSOR; -- select tipo_docu,no_cliente,no_docu,fecha,est_ref,moneda,monto from ARLCRD;   -- est_ref = D (capital)  

  /********************************************************************************
    Nombre:     SP_OBTENER_DATOS_OP
    Proposito:  Obtener los campos para registrar la operación (arlcop).
    Referencias:
    Parametros: PC_NO_CIA           ---> Código de Compañia de Seguro.
                PC_NO_CLIENTE       ---> Código del cliente
                PC_NUM_SOLI         ---> Número de solicitud
                PD_FECHA_INI        ---> Fecha de inicio de la solicitud
                PC_COD_USUA_WEB     ---> Usuario Web
                P_RET_CUR_FACT      ---> Cursor de los documentos asignados a los Op 
                P_RET_CUR_ARLCOP    ---> Cursor con los datos a la tabla arlcop
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        21/01/2018  LRODRIGUEZ        Creación del procedure.
  ********************************************************************************/
  TYPE t_fact_x_op is record (
      tipo_docu       arlcrd.tipo_docu%TYPE,
      grupo           arlcrd.grupo%TYPE,
      no_cliente      arlcrd.no_cliente%TYPE,
      no_docu         arlcrd.no_docu%TYPE,
      cod_oper        arlcrd.cod_oper%TYPE,
      fecha           arlcrd.fecha%TYPE,
      moneda          arlcrd.moneda%TYPE,
      monto           arlcrd.monto%TYPE,
      tipo_cuota      arlcrd.est_ref%TYPE,
      interes         arlcml.intereses%TYPE,
      igv             arlcml.igv%TYPE,
      cod_ref         arlcrd.cod_ref%TYPE,
      est_ref         arlcrd.est_ref%TYPE, -- tipo_cuota de la pantalla
      saldo_anterior  arlcrd.saldo_anterior%TYPE
  );
  TYPE t_fact_arfafe is record (
      no_cia         arfafe.no_cia%type,
      tipo_doc       arfafe.tipo_doc%type,
      no_cliente     arfafe.no_cliente%type,
      no_factu       arfafe.no_factu%type,
      fecha          arfafe.fecha%type,
      moneda         arfafe.moneda%type,
      val_pre_docu   arfafe.val_pre_docu%type
  );
  
  TYPE t_rec_arlcop IS RECORD (
  NO_CIA               ARLCOP.NO_CIA%TYPE,
  COD_OPER             ARLCOP.COD_OPER%TYPE,
  ANO                  ARLCOP.ANO%TYPE,
  MES                  ARLCOP.MES%TYPE,
  GRUPO	               ARLCOP.GRUPO%TYPE,
  NO_CLIENTE	         ARLCOP.NO_CLIENTE%TYPE,
  MODAL_CRED	         ARLCOP.MODAL_CRED%TYPE,
  TIPO_BIEN	           ARLCOP.TIPO_BIEN%TYPE,
  FECHA	               ARLCOP.FECHA%TYPE,
  TEA	                 ARLCOP.TEA%TYPE,
  MON_TASA_IGV	       ARLCOP.MON_TASA_IGV%TYPE,
  MON_TASA_ISC	       ARLCOP.MON_TASA_ISC%TYPE,
  VALOR_ORIGINAL	     ARLCOP.VALOR_ORIGINAL%TYPE,
  MONTO_GASTOS	       ARLCOP.MONTO_GASTOS%TYPE,
  MONTO_FINA	         ARLCOP.MONTO_FINA%TYPE,
  INTERES_PER_GRA	     ARLCOP.INTERES_PER_GRA%TYPE,
  TOTAL_FINANCIAR	     ARLCOP.TOTAL_FINANCIAR%TYPE,
  INTERES_OPER	       ARLCOP.INTERES_OPER%TYPE,
  TOTAL_IGV	           ARLCOP.TOTAL_IGV%TYPE,
  TOTAL_ISC	           ARLCOP.TOTAL_ISC%TYPE,
  MONEDA	             ARLCOP.MONEDA%TYPE,
  TIPO_CAMBIO	         ARLCOP.TIPO_CAMBIO%TYPE,
  PLAZO	               ARLCOP.PLAZO%TYPE,
  NO_CUOTAS	           ARLCOP.NO_CUOTAS%TYPE,
  VCTO_1RA_LET	       ARLCOP.VCTO_1RA_LET%TYPE,
  FRE_PAGO_DIAS	       ARLCOP.FRE_PAGO_DIAS%TYPE,
  DIA_PAGO	           ARLCOP.DIA_PAGO%TYPE,
  TIPO_CUOTA	         ARLCOP.TIPO_CUOTA%TYPE,
  IND_PER_GRA	         ARLCOP.IND_PER_GRA%TYPE,
  IND_PER_GRA_CAP	     ARLCOP.IND_PER_GRA_CAP%TYPE,
  TASA_GRA	           ARLCOP.TASA_GRA%TYPE,
  FRE_GRA	             ARLCOP.FRE_GRA%TYPE,
  MON_CUO_EXT	         ARLCOP.MON_CUO_EXT%TYPE,
  CEXT_ENE	           ARLCOP.CEXT_ENE%TYPE,
  CEXT_FEB	           ARLCOP.CEXT_FEB%TYPE,
  CEXT_MAR	           ARLCOP.CEXT_MAR%TYPE,
  CEXT_ABR	           ARLCOP.CEXT_ABR%TYPE,
  CEXT_MAY	           ARLCOP.CEXT_MAY%TYPE,
  CEXT_JUN	           ARLCOP.CEXT_JUN%TYPE,
  CEXT_JUL	           ARLCOP.CEXT_JUL%TYPE,
  CEXT_AGO	           ARLCOP.CEXT_AGO%TYPE,
  CEXT_SEP	           ARLCOP.CEXT_SEP%TYPE,
  CEXT_OCT	           ARLCOP.CEXT_OCT%TYPE,
  CEXT_NOV	           ARLCOP.CEXT_NOV%TYPE,
  CEXT_DIC	           ARLCOP.CEXT_DIC%TYPE,
  CTA_INTERES_DIFERIDO ARLCOP.CTA_INTERES_DIFERIDO%TYPE,
  CTA_INGRESOS_FINAN	 ARLCOP.CTA_INGRESOS_FINAN%TYPE,
  ESTADO	             ARLCOP.ESTADO%TYPE,
  USUARIO	             ARLCOP.USUARIO%TYPE,
  USUARIO_APRB	       ARLCOP.USUARIO_APRB%TYPE,
  NO_SOLI	             ARLCOP.NO_SOLI%TYPE,
  IND_SOLI	           ARLCOP.IND_SOLI%TYPE,
  SEC_OPER	           ARLCOP.SEC_OPER%TYPE,
  FECHA_INI	           ARLCOP.FECHA_INI%TYPE,
  CUOTA_INICIAL	       ARLCOP.CUOTA_INICIAL%TYPE,
  IND_LB	             ARLCOP.IND_LB%TYPE,
  JUDICIAL	           ARLCOP.JUDICIAL%TYPE,
  TIPO_FACTU	         ARLCOP.TIPO_FACTU%TYPE,
  IND_FACTU	           ARLCOP.IND_FACTU%TYPE,
  IND_UTILIZADO	       ARLCOP.IND_UTILIZADO%TYPE,
  F_ACEPTADA	         ARLCOP.F_ACEPTADA%TYPE,
  F_ANULADA	           ARLCOP.F_ANULADA%TYPE,
  USR_ANULA	           ARLCOP.USR_ANULA%TYPE,
  IND_NU	             ARLCOP.IND_NU%TYPE,
  NUR_SOLI_CRED_DET	   ARLCOP.NUR_SOLI_CRED_DET%TYPE,
  NUM_CORRE_SEGURO	   ARLCOP.NUM_CORRE_SEGURO%TYPE,
  NUM_PEDIDO_VEH	     ARLCOP.NUM_PEDIDO_VEH%TYPE,
  COD_FILIAL	         ARLCOP.COD_FILIAL%TYPE,
  TIPODOCGEN	         ARLCOP.TIPODOCGEN%TYPE,
  FECHA_AUT_OPE	       ARLCOP.FECHA_AUT_OPE%TYPE,
  FECHA_CRE_REG	       ARLCOP.FECHA_CRE_REG%TYPE,
  NUM_PROF_VEH	       ARLCOP.NUM_PROF_VEH%TYPE/*,
  IND_AJUSTE_FECHA	   ARLCOP.IND_AJUSTE_FECHA%TYPE*/
  );
  
  TYPE t_rec_aval is record(
  NO_CIA               ARLCAV.NO_CIA%TYPE,
  COD_OPER             ARLCAV.COD_OPER%TYPE,
  SEC_AVAL             ARLCAV.SEC_AVAL%TYPE,
  NOM_AVAL             ARLCAV.NOM_AVAL%TYPE,
  DIREC_AVAL           ARLCAV.DIREC_AVAL%TYPE,
  LE                   ARLCAV.LE%TYPE,
  TELF_AVAL            ARLCAV.TELF_AVAL%TYPE,
  DES_AVAL             ARLCAV.DES_AVAL%TYPE,
  NO_SOLI              ARLCAV.NO_SOLI%TYPE,
  RUC                  ARLCAV.RUC%TYPE,
  REPRESENTANTE        ARLCAV.REPRESENTANTE%TYPE
  );
  
  TYPE t_rec_gastos IS RECORD (
  NO_CIA               ARLCGO.NO_CIA%TYPE,
  COD_GASTO            ARLCGO.COD_GASTO%TYPE,
  COD_OPER             ARLCGO.COD_OPER%TYPE,
  MONTO                ARLCGO.MONTO%TYPE,
  MONEDA               ARLCGO.MONEDA%TYPE,
  TIPO_CAMBIO          ARLCGO.TIPO_CAMBIO%TYPE,
  SIGNO                ARLCGO.SIGNO%TYPE,
  OBSERVACIONES        ARLCGO.OBSERVACIONES%TYPE,
  NO_DOCU              ARLCGO.NO_DOCU%TYPE,
  IND_FINAN            ARLCGO.IND_FINAN%TYPE
  );
--  TYPE t_table_reclet IS TABLE OF t_fact_x_op INDEX BY PLS_INTEGER; --BINARY_INTEGER
--  TYPE t_table_arlcop IS TABLE OF t_rec_arlcop INDEX BY PLS_INTEGER;
--  TYPE t_table_arlcav IS TABLE OF t_rec_aval   INDEX BY PLS_INTEGER;
--  TYPE t_table_arlcgo IS TABLE OF t_rec_gastos INDEX BY PLS_INTEGER;

  TYPE t_table_reclet IS TABLE OF t_fact_x_op INDEX BY BINARY_INTEGER; --BINARY_INTEGER
  TYPE t_table_arlcop IS TABLE OF t_rec_arlcop INDEX BY BINARY_INTEGER;
  TYPE t_table_arlcav IS TABLE OF t_rec_aval   INDEX BY BINARY_INTEGER;
  TYPE t_table_arlcgo IS TABLE OF t_rec_gastos INDEX BY BINARY_INTEGER;

  
  Procedure sp_refrep_op (
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_cod_oper_ori   IN      arlcop.cod_oper%TYPE,
  pc_cod_oper_ref   OUT     arlcop.cod_oper%TYPE,
  pd_fecha_ini      IN      vve_cred_soli.fec_venc_1ra_let%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_cur_fact    IN OUT  SYS_REFCURSOR,
  p_ret_cur_arlcop  OUT     SYS_REFCURSOR,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  
  Procedure sp_guardar_op(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_tipo_doc_op    IN      arlcop.tipo_factu%TYPE,
  pd1_fecha_cont    IN      varchar2, -- fecha contrato
  pd1_fecha_ini     IN      varchar2, -- fecha de entrega
  pc_tipo_cuota     IN      arlcop.tipo_cuota%TYPE,
  pd1_fecha_aut     IN      varchar2,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_cur_fact        IN      VVE_TYTA_DOCU_RELA,
  p_cur_aval        IN      VVE_TYTA_AVAL,
  p_cur_gasto       IN      VVE_TYTA_GASTOS,
  p_cur_fact_ret    OUT     SYS_REFCURSOR,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );

/*  Procedure sp_nueva_op(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_tipo_doc_op    IN      arlcop.tipo_factu%TYPE,
  pd_fecha_cont     IN      arlcop.fecha%TYPE,
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE,
  pc_tipo_cuota     IN      arlcop.tipo_cuota%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_cur_fact    IN OUT  SYS_REFCURSOR,
  p_ret_cur_arlcop  OUT     SYS_REFCURSOR,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
*/  

  /* Obtiene los datos para registrar la operación */
  Procedure sp_obtener_datos_op(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_cod_oper       IN      vve_cred_soli.cod_oper_rel%TYPE,
  pc_tipo_doc_op    IN      arlcop.tipo_factu%TYPE,
  pd_fecha_cont     IN      arlcop.fecha%TYPE,
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE,
  pc_tipo_cuota     IN      arlcop.tipo_cuota%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_rec_cur_fact    IN      SYS_REFCURSOR,
  p_rec_arlcop      OUT     pkg_sweb_cred_lxc.t_rec_arlcop, --arlcop%rowtype,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  /*
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pd_fecha_ini      IN      vve_cred_soli.fec_venc_1ra_let%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_cur_fact    IN      SYS_REFCURSOR,
  p_r_arlcop        OUT     arlcop%rowtype,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
*/
  /* Obtiene el nro de op y actualiza en la tabla de correlativos por empresa */
  Function sf_obtener_nro_op(
  pc_no_cia         IN      arlcop.no_cia%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) return NUMBER;
  
  /* Crear letras */
  Procedure sp_crear_arlcml(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE, -- Nro de solicitud evaluado
    pn_cod_oper_ori   IN      arlcop.cod_oper%TYPE, -- nro_op original
    pn_cod_oper_ref   IN      arlcop.cod_oper%TYPE, -- nro_op del refinanciamiento/reprog.
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  );

  /* Crear cxc */  
  Procedure sp_crear_arccmd(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_moneda         IN      arlcop.moneda%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  pc_grupo          IN      arlcop.grupo%TYPE,
  pn_tipo_cambio    IN      arlcop.tipo_cambio%TYPE,
  pn_porc_igv       IN      arlcop.mon_tasa_igv%TYPE,
  p_ret_cur_fact    IN OUT SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  
  /* Seteando las facturas de vta o letras de la Op*/
  Procedure sp_crear_arlcrd(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
    pc_cod_oper_ori   IN      arlcop.cod_oper%TYPE,
    pc_cod_oper_ref   IN      arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cur_fact    IN OUT  SYS_REFCURSOR,
    --p_cur_fact        IN      VVE_TYTA_DOCU_RELA,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  );
  
  Procedure sp_crear_arlcav(
  pc_no_cia         IN      arlcav.no_cia%TYPE,
  pc_cod_oper       IN      arlcav.cod_oper%TYPE,
  pc_cod_soli       IN      arlcav.no_soli%TYPE,
  p_ret_cur_aval    IN      SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  
  Procedure sp_crear_arlcgo(
  pc_no_cia         IN      arlcgo.no_cia%TYPE,
  pc_cod_oper       IN      arlcgo.cod_oper%TYPE,
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE,
  p_ret_cur_gasto    IN      SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );

  /*Actualizando nro de operación en la solicitud*/
  Procedure sp_act_op_soli(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
    pc_cod_oper       IN      arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
    ); 
    
  /*Verficar si existe el documento en el sid */
  Function sf_verifica_existe_doc(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_rec_fact        IN      PKG_SWEB_CRED_LXC.t_fact_x_op,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN ;

  /* Creación de la operación y demás datos necesarios para la migración a SAP */
  Procedure sp_crear_arlcop(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pn_cod_oper       IN OUT  arlcop.cod_oper%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_tipo_doc_op    IN      arlcop.tipo_factu%TYPE,
  pd_fecha_cont     IN      arlcop.fecha%TYPE,
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE,
  pc_tipo_cuota     IN      arlcop.tipo_cuota%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_cur_fact    IN      SYS_REFCURSOR,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  
  Function sf_valida_usua_ope(
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    cod_acti_pedi_veh IN      usuarios_acti_pedido_veh.cod_acti_pedido_veh%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN;
  
  Procedure sp_obtener_data_op(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
    pn_cod_oper       IN OUT  arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
    
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cur_oper    OUT     SYS_REFCURSOR,
    p_ret_cur_fact    OUT     SYS_REFCURSOR,
    p_ret_cur_letr    OUT     SYS_REFCURSOR,
    p_ret_cur_gast    OUT     SYS_REFCURSOR,
    p_ret_cur_aval    OUT     SYS_REFCURSOR,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  );
  Function sf_obtener_tasa_igv(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN NUMBER ;
  
  Function sf_valida_tipo_docu(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  pc_no_cliente     IN      arlcop.no_cliente%TYPE,
  pc_moneda         IN      arlcop.moneda%TYPE,
  p_rec_fact        IN OUT  PKG_SWEB_CRED_LXC.t_fact_x_op,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN;
  
  Function sf_valida_no_docu(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  p_rec_fact        IN OUT  PKG_SWEB_CRED_LXC.t_fact_x_op,
  --p_rec_fact        IN OUT  VVE_TYPE_DOCU_RELA_ITEM,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN;
  
  Procedure sp_valida_vcto_letra(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  p_rec_fact        IN OUT  PKG_SWEB_CRED_LXC.t_fact_x_op,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  );
  
  Procedure sp_obt_doclet_arlcrd(
  pc_no_cia        IN  arlcml.no_cia%TYPE,
  pc_grupo         IN  arlcml.grupo%TYPE,
  pc_cod_oper_ori  IN  arlcml.cod_oper%TYPE,
  pc_no_cliente    IN  arlcml.no_cliente%TYPE,
  pn_nro_letras    IN  NUMBER,
  pc_moneda        IN  arlcop.moneda%TYPE,
  pc_tipo_cambio   IN  arlcop.tipo_cambio%TYPE,
  p_cur_docletras  OUT SYS_REFCURSOR,
  pc_cod_usua_web  IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta      OUT NUMBER,
  pc_ret_mens      OUT VARCHAR2
  );

  Procedure sp_obt_doc_letras(
  pc_no_cia        IN  arlcml.no_cia%TYPE,
  pc_grupo         IN  arlcml.grupo%TYPE,
  pc_cod_oper_ori  IN  arlcml.cod_oper%TYPE,
  pc_no_cliente    IN  arlcml.no_cliente%TYPE,
  pc_moneda        IN  arlcop.moneda%TYPE,
  pc_tipo_cambio   IN  arlcop.tipo_cambio%TYPE,
  p_cur_docletras  OUT SYS_REFCURSOR,
  pc_cod_usua_web  IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta      OUT NUMBER,
  pc_ret_mens      OUT VARCHAR2
  );
  
  Function sp_valida_doc_gast(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_cod_gasto      IN      arcctd.tipo%TYPE,
  pc_observ         OUT     arcctd.descripcion%TYPE,
  pc_tipo_mov       OUT     arcctd.tipo_mov%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN;

  Procedure sp_eliminar_op(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
    pn_cod_oper       IN OUT  arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE
    );

END PKG_SWEB_CRED_LXC; 