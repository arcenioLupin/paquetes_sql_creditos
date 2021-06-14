create or replace PACKAGE       VENTA.PKG_SWEB_CRED_SOLI_SIMULADOR AS

  /********************************************************************************
    Nombre:     SP_LIST_COMP_SEGU
    Proposito:  Listar las compañias de seguro.
    Referencias:
    Parametros: P_COD_CIASEG        ---> Código de Compañia de Seguro.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_comp_segu
  (
    p_cod_ciaseg     IN gen_ciaseg.cod_ciaseg%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_MAES_CONC_LETR
    Proposito:  Listar los conceptos del maestro.
    Referencias:
    Parametros: P_COD_CIASEG        ---> Código de Compañia de Seguro.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_list_maes_conc_letr
  (
    p_cod_conc_col   IN vve_cred_maes_conc_letr.cod_conc_col%TYPE,
    p_ind_conc_oblig IN vve_cred_maes_conc_letr.ind_conc_oblig%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_PROF_APRO
    Proposito:  Listar las proformas aprobadas relacionadas a la misma FV que dió 
                origen a la solicitud de crédito.
    Referencias:
    Parametros: P_NUM_PROF_VEH      ---> Número de la proforma.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_prof_apro
  (
    p_num_prof_veh   IN vve_cred_soli_prof.num_prof_veh%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_OBT_TASA_SEG
    Proposito:  Obtiene la tasa que le corresponde por tipo de vehículo y uso.
    Referencias:
    Parametros: P_COD_CIA           ---> Código de la empresa.
                P_COD_TIPO_VEH      ---> Código del Tipo de Vehículo.
                P_IND_TIP_USO       ---> Indicador del Tipo de uso.
                P_COD_CLIENTE       ---> Código del cliente.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_TASA_SEG          ---> Tasa seguro.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_obt_tasa_seg
  (
    p_cod_cia        IN vve_cred_soli.cod_empr%TYPE,
    p_cod_tipo_veh   IN vve_proforma_veh_det.cod_tipo_veh%TYPE,
    p_ind_tip_uso    IN vve_tabla_maes.cod_tipo%TYPE,
    p_cod_cliente    IN vve_cred_soli.cod_clie%TYPE,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tasa_seg       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_CALC_PRIMA_SEG
    Proposito:  Obtiene la prima del seguro.
    Referencias:
    Parametros: P_TASA_SEG          ---> Tasa del seguro.
                P_PLAZO_MESES       ---> Plazo en meses que debe cubrir el seguro.
                P_MONTO_VTA         ---> Valor del venta de los vehículos financiados.
                P_PORC_IGV          ---> Porcentaje IGV.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_PRIMA_SEG         ---> Prima del seguro.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_calc_prima_seg
  (
    p_tasa_seg       IN vve_cred_soli.val_tasa_segu%TYPE,
    p_plazo_meses    IN vve_cred_soli.can_plaz_mes%TYPE,
    p_monto_vta      IN vve_proforma_veh_det.val_pre_veh%TYPE, -- p.val_pre_veh*p.can_veh
    p_porc_igv       IN NUMBER,
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_prima_seg      OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_GENE_CRONO
    Proposito:  Generar el cronograma.
    Referencias:
    Parametros: P_COD_SIMU          ---> Código del simulador.
                P_COD_GRU_TIP_CRED  ---> Código del grupo del tipo de crédito.
                P_COD_TIP_CRED      ---> Código del tipo de crédito.
                P_MON_VTA           ---> Monto de Venta.
                P_PORC_CUO_INI      ---> Porcentaje de la Cuota Inicial.
                P_PERIODICIDAD      ---> Periodicidad del Crédito.
                P_PRIMA_SEG         ---> Monto de la prima de Seguro Dive.
                P_NRO_CUOTAS        ---> Nro. total de cuotas.
                P_PLAZ_MES          ---> Plazo del crédito en número de meses.
                P_PORC_CB           ---> Porcentaje de la cuota balloon.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_gene_crono
  (
    p_cod_simu           IN vve_cred_simu_gast.cod_simu%TYPE,
    p_cod_gru_tip_cred   IN vve_tabla_maes.cod_grupo%TYPE,
    p_cod_tip_cred       IN vve_tabla_maes.cod_tipo%TYPE,
    p_mon_vta            IN vve_cred_soli_prof.val_vta_tot_fin%TYPE,
    p_porc_cuo_ini       IN vve_cred_soli.val_porc_ci%TYPE,
    p_periodicidad       IN vve_tabla_maes.valor_adic_1%TYPE,
    p_prima_seg          IN vve_cred_soli.val_prim_seg%TYPE,
    p_nro_cuotas         IN vve_cred_soli.can_tota_letr%TYPE,
    p_plaz_mes           IN vve_cred_soli.can_plaz_mes%TYPE,
    p_porc_cb            IN vve_cred_soli.val_porc_cuot_ball%TYPE,
    p_cod_gru_tip_pgra   IN vve_tabla_maes.cod_grupo%TYPE,
    p_cod_tip_pgra       IN vve_tabla_maes.cod_tipo%TYPE,
    p_val_dias_pgra      IN vve_cred_soli.val_dias_peri_grac%TYPE,
    p_val_mon_int_pgra   IN vve_cred_soli.val_int_per_gra%TYPE,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_CUAD_CRONO
    Proposito:  Cuadrar cronograma editado y validar si genera el TIR y TCEA correcto.
    Referencias:
    Parametros: P_COD_SIMU         ---> Código del simulador.
                P_COD_SOLI_CRED    ---> Código de la solicitud de crédito.
                P_NUM_PROF_VEH     ---> Número de la proforma.
                P_ARR_CRONO_MODI   ---> Arreglo de cronograma modificado.
                P_COD_TIPO_OPE     ---> Tipo de operación a realizar C=Cuadrar cuotas,G=Guardar cronograma modificado. 
                P_COD_USUA_SID     ---> Código del usuario.
                P_COD_USUA_WEB     ---> Id del usuario.
                P_RET_CURSOR_ROW   ---> Listado de información del cronograma modificado.   
                P_RET_CURSOR_COL   ---> Listado de las columnas del cronograma.
                P_RET_CURSOR_TOTAL ---> Muestra Totales del cronograma.
                P_RET_CURSOR_PROC  ---> Listado de procesos a realizar en la generación de cronograma. 
                P_RET_ESTA         ---> Estado del proceso.
                P_RET_MENS         ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        18/03/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_cuad_crono
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_arr_crono_modi   IN VVE_TYTA_CRONO,
    p_cod_tipo_ope     IN VARCHAR2, 
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor_row   OUT SYS_REFCURSOR,
    p_ret_cursor_col   OUT SYS_REFCURSOR,
    p_ret_cursor_total OUT SYS_REFCURSOR,
    p_ret_cursor_proc  OUT SYS_REFCURSOR,     
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  );

    /********************************************************************************
    Nombre:     SP_INSE_PARA_PROFORMA
    Proposito:  Registrar proformas asociadas a la ficha de venta y relacionarlas con la solicitud.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Código de la solicitud de crédito.
                P_NUM_PROF_VEH      ---> Número de la proforma.
                P_CAN_VEH_FIN       ---> Cantidad de vehiculos.
                P_VAL_VTA_TOT_FIN   ---> Valor de venta total.   
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_COD_SIMU      ---> Codigo del Simulador.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        19/07/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/    
  PROCEDURE sp_inse_para_proforma
  (
    p_cod_soli_cred      IN vve_cred_soli_prof.cod_soli_cred%TYPE,
    p_num_prof_veh       IN vve_cred_soli_prof.num_prof_veh%TYPE,
    p_can_veh_fin        IN vve_cred_soli_prof.can_veh_fin%TYPE,
    p_val_vta_tot_fin    IN vve_cred_soli_prof.val_vta_tot_fin%TYPE,
    p_ind_registro       IN CHAR,   
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_num_prof_veh   OUT vve_cred_simu.num_prof_veh%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_INSE_PARA_SIMULADOR
    Proposito:  Registrar parametros del simulador.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Código de solicitud de crédito.  
                P_NUM_PROF_VEH      ---> Número de proforma.    
                P_VAL_PORC_CI       ---> Porcentaje de cuota inicial.  
                P_VAL_CI            ---> Valor de cuota inicial. 
                P_VAL_MON_FIN       ---> Valor de monto a financiar. 
                P_VAL_PAG_CONT_CI   ---> Valor de pago al contado de cuota inicial. 
                P_FEC_VENC_1RA_LET  ---> Fecha de vencimiento de la 1ra letra.
                P_COD_PER_CRED_SOL  ---> Código de periodicidad de cuotas. 
                P_CAN_TOT_LET       ---> Cantidad total de letras 
                P_CAN_PLAZ_MESES    ---> Cantidad de plazo en meses
                P_IND_TIP_PER_GRA   ---> Indicador de tipo de periodo de gracia. 
                P_VAL_DIAS_PER_GRA  ---> Valor de dias de periodo de gracia. 
                P_CAN_LET_PER_GRA   ---> Cantidad de letras de periodo de gracia. 
                P_VAL_PORC_TEA_SIGV ---> Valor de porcentaje de TEA. 
                P_VAL_PORC_TEP_SIGV ---> Valor de porcentaje de TEP. 
                P_IND_GPS           ---> Indicador de GPS. 
                P_VAL_PORC_CUO_BAL  ---> Valor de porcentaje cuota baloon.
                P_VAL_CUO_BAL       ---> Valor de cuota baloon. 
                P_IND_TIP_SEG       ---> Indicador de tipo de seguro. 
                P_COD_CIA_SEG       ---> Código de compañia de seguro. 
                P_COD_TIP_USO_VEH   ---> Código de tipo de uso. 
                P_VAL_TASA_SEG      ---> Valor de tasa de seguro. 
                P_VAL_PRIMA_SEG     ---> Valor de prima de seguro. 
                P_COD_TIP_UNIDAD    ---> Código de tipo de unidad. 
                P_VAL_PORC_GAST_ADM ---> Valor de porcentaje gastos administrativos. 
                P_VAL_GAST_ADM      ---> Valor de gastos administrativos. 
                P_VAL_INT_PER_GRA   ---> Valor de interes periodo de gracia. 
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_COD_SIMU      ---> Codigo del Simulador.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        26/12/2018  PHRAMIREZ        Creación del procedure.
    2.0        13/03/2020  AVILCA           Check sin/con interes
  ********************************************************************************/  
  PROCEDURE sp_inse_para_simulador
  (
    p_cod_soli_cred          IN vve_cred_simu.cod_soli_cred%type,    
    p_num_prof_veh           IN vve_cred_simu.num_prof_veh%type,    
    p_val_porc_ci            IN vve_cred_simu.val_porc_ci%type,    
    p_val_ci                 IN vve_cred_simu.val_ci%type,    
    p_val_mon_fin            IN vve_cred_simu.val_mon_fin%type,    
    p_val_pag_cont_ci        IN vve_cred_simu.val_pag_cont_ci%type,    
    p_can_dias_venc_1ra_letr IN vve_cred_simu.can_dias_venc_1ra_letr%type,   
    p_cod_per_cred_sol       IN vve_cred_simu.cod_per_cred_sol%type,    
    p_can_tot_let            IN vve_cred_simu.can_tot_let%type,    
    p_can_plaz_meses         IN vve_cred_simu.can_plaz_meses%type,    
    p_ind_tip_per_gra        IN vve_cred_simu.ind_tip_per_gra%type,    
    p_val_dias_per_gra       IN vve_cred_simu.val_dias_per_gra%type,    
    p_can_let_per_gra        IN vve_cred_simu.can_let_per_gra%type,    
    p_val_porc_tea_sigv      IN vve_cred_simu.val_porc_tea_sigv%type,    
    p_val_porc_tep_sigv      IN vve_cred_simu.val_porc_tep_sigv%type,    
    p_ind_gps                IN vve_cred_simu.ind_gps%type,    
    p_val_porc_cuo_bal       IN vve_cred_simu.val_porc_cuo_bal%type,    
    p_val_cuo_bal            IN vve_cred_simu.val_cuo_bal%type,    
    p_ind_tip_seg            IN vve_cred_simu.ind_tip_seg%type,    
    p_cod_cia_seg            IN vve_cred_simu.cod_cia_seg%type,    
    p_cod_tip_uso_veh        IN vve_cred_simu.cod_tip_uso_veh%type,    
    p_val_tasa_seg           IN vve_cred_simu.val_tasa_seg%type,
    p_val_tasa_ori_seg       IN vve_cred_simu.val_tasa_ori_seg%type,
    p_val_prima_seg          IN vve_cred_simu.val_prima_seg%type,    
    p_cod_tip_unidad         IN vve_cred_simu.cod_tip_unidad%type,        
    p_val_porc_gast_adm      IN vve_cred_simu.val_porc_gast_adm%type,     
    p_val_gast_adm           IN vve_cred_simu.val_gast_adm%type,        
    p_val_int_per_gra        IN vve_cred_simu.val_int_per_gra%type,
    p_cod_moneda             IN vve_cred_simu.cod_moneda%type,
    p_tip_soli_cred          IN vve_cred_soli.tip_soli_cred%TYPE,
    p_txt_otr_cond           IN vve_cred_simu.txt_otr_cond%TYPE,
    p_val_tc                 IN vve_cred_simu.val_tc%TYPE,
    p_val_ind_sin_int        IN vve_cred_simu.ind_pgra_sint%TYPE,--Req. 87567 E2.1 ID## AVILCA
    p_cod_usua_sid           IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web           IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod_simu           OUT vve_cred_simu.cod_simu%TYPE,
    p_ret_esta               OUT NUMBER,
    p_ret_mens               OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_INSE_PARA_GASTO
    Proposito:  Registrar parametros de la sección de gastos en el simulador.
    Referencias:
    Parametros: P_COD_CONC_COL  ---> Código de concepto.
                P_COD_SIMU      ---> Código de Simulador.
                P_VAL_MON_TOTAL ---> Valor del monto total.
                P_IND_FIN       ---> Indicador de capitalizar.
                P_VAL_MON_PER   ---> Valor del monto prorrateado.
                P_COD_USUA_SID  ---> Código del usuario.
                P_COD_USUA_WEB  ---> Id del usuario.
                P_RET_COD_SIMU  ---> Codigo del Simulador.
                P_RET_ESTA      ---> Estado del proceso.
                P_RET_MENS      ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        26/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/    
  PROCEDURE sp_inse_para_gasto
  (
    p_cod_conc_col       IN vve_cred_simu_gast.cod_conc_col%TYPE,
    p_cod_simu           IN vve_cred_simu_gast.cod_simu%TYPE,
    p_val_mon_total      IN vve_cred_simu_gast.val_mon_total%TYPE,
    p_ind_fin            IN vve_cred_simu_gast.ind_fin%TYPE,
    p_val_mon_per        IN vve_cred_simu_gast.val_mon_per%TYPE,
    p_cod_moneda         IN vve_cred_simu_gast.cod_moneda%TYPE,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod_simu_gast  OUT vve_cred_simu_gast.cod_cred_simu_gast%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_CRONO
    Proposito:  Listar el ultimo cronograma de cuotas.
    Referencias:
    Parametros: P_COD_SIMU         ---> Código del simulador.
                P_COD_SOLI_CRED    ---> Código de la solicitud de crédito.
                P_NUM_PROF_VEH     ---> Número de la proforma.
                P_COD_USUA_SID     ---> Código del usuario.
                P_COD_USUA_WEB     ---> Id del usuario.
                P_RET_CURSOR_ROW   ---> Listado de información del cronograma.   
                P_RET_CURSOR_COL   ---> Listado de las columnas del cronograma.
                P_RET_CURSOR_TOTAL ---> Muestra Totales del cronograma.
                P_RET_CURSOR_PROC  ---> Listado de procesos a realizar en la generación de cronograma. 
                P_RET_ESTA         ---> Estado del proceso.
                P_RET_MENS         ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        28/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_list_crono
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor_row   OUT SYS_REFCURSOR,
    p_ret_cursor_col   OUT SYS_REFCURSOR,
    p_ret_cursor_total OUT SYS_REFCURSOR,
    p_ret_cursor_proc  OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_PROPUESTA
    Proposito:  Obtener información de la propuesta de crédito.
    Referencias:
    Parametros: P_COD_SIMU         ---> Código del simulador.
                P_COD_SOLI_CRED    ---> Código de la solicitud de crédito.
                P_NUM_PROF_VEH     ---> Número de la proforma.
                P_COD_USUA_SID     ---> Código del usuario.
                P_COD_USUA_WEB     ---> Id del usuario.
                P_RET_CURSOR       ---> Información de la propuesta de crédito.   
                P_RET_ESTA         ---> Estado del proceso.
                P_RET_MENS         ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        05/03/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/    
  PROCEDURE sp_list_propuesta
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR, 
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_GENE_PLAN_CAMBIO_TASA
    Proposito:  Genera la plantilla de envío de correo cuando se realiza el cambio de tasa de seguro.
    Referencias:
    Parametros: P_COD_SOLI_CRED  ---> Código de la solicitud de crédito.
                P_DESTINATARIOS  ---> Listado de destinatarios.
                P_COD_USUA_SID   ---> Código del usuario.
                P_COD_USUA_WEB   ---> Id del usuario.
                P_RET_ESTA       ---> Estado del proceso.
                P_RET_MENS       ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        05/03/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_gene_plan_cambio_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /********************************************************************************
    Nombre:     SP_LIST_GASTO
    Proposito:  Listar gastos registrados al simulador.
    Referencias:
    Parametros: P_COD_SIMU         ---> Código del simulador.
                P_COD_SOLI_CRED    ---> Código de la solicitud de crédito.
                P_NUM_PROF_VEH     ---> Número de la proforma.
                P_COD_USUA_SID     ---> Código del usuario.
                P_COD_USUA_WEB     ---> Id del usuario.
                P_RET_CURSOR       ---> Listado de gastos asociados al simulador.  
                P_RET_ESTA         ---> Estado del proceso.
                P_RET_MENS         ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        01/04/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  PROCEDURE sp_list_gasto
  (
    p_cod_simu         IN vve_cred_simu.cod_simu%TYPE,
    p_cod_soli_cred    IN vve_cred_simu.cod_soli_cred%TYPE,
    p_num_prof_veh     IN vve_cred_simu.num_prof_veh%TYPE,
    p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  );  

  /********************************************************************************
    Nombre:     FN_PAGO
    Proposito:  Calcula el pago de un préstamo basado en pagos y tasa de interés constante.
    Referencias:
    Parametros: P_TASA    --> Tasa de interés por período del préstamo.   
                P_NUM_PER --> Número total de pagos del préstamo.
                P_VA      --> Valor actual.
                P_VF      --> Valor futuro.
                P_TIPO    --> Es un valor lógico, para pago al inicio del período es 1 
                              para pago al final del período es 0.                 
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        28/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/  
  FUNCTION fn_pago
  (
    p_tasa     IN NUMBER,
    p_num_per  IN NUMBER,   
    p_va       IN NUMBER,
    p_vf       IN NUMBER DEFAULT 0,
    p_tipo     IN NUMBER DEFAULT 0
  ) RETURN NUMBER;

  /********************************************************************************
    Nombre:     FN_VAL_CRED_SIMU_LEDE
    Proposito:  Retorna valor de la tabla de detalle de letras.
    Referencias:
    Parametros: P_COD_SIMU      --> Código de simulador.   
                P_COD_NUME_LETR --> Número de letra.
                P_COD_CONC_COL  --> Código de concepto.            
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        28/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/    
  FUNCTION fn_val_cred_simu_lede 
  (
    p_cod_simu      IN vve_cred_simu_lede.cod_simu%TYPE,
    p_cod_nume_letr IN vve_cred_simu_lede.cod_nume_letr%TYPE,
    p_cod_conc_col  IN vve_cred_simu_lede.cod_conc_col%TYPE
  ) RETURN NUMBER;

  /********************************************************************************
    Nombre:     FN_TIR
    Proposito:  Retorna la tasa interna de retorno de una inversión para una serie de valores
                en efectivo.
    Referencias:
    Parametros: P_TIR_LIST      --> Listado de números para los cuales se desea calcular la tasa
                                    interna de retorno.          
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        18/03/2019  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/    
  FUNCTION fn_tir 
  (
    p_value_list IN vve_tyta_tir_list
  ) RETURN NUMBER;

  PROCEDURE sp_list_tasas
  (
    p_co_cia        IN  arlcin.no_cia%TYPE,
    p_moneda        IN  arlchi.moneda%TYPE,
    p_cod_usua_sid  IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2 
  );
  
END PKG_SWEB_CRED_SOLI_SIMULADOR;