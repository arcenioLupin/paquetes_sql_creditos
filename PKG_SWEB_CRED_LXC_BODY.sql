create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_LXC AS

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
  ) AS
  lc_modal_cred     arlcop.modal_cred%TYPE;
  lc_grupo          arccmc.grupo%TYPE;
  kc_ref            arlcop.modal_cred%TYPE := 'R';
  r_arlcop          arlcop%ROWTYPE;
  ln_sec_oper       arccmc.num_oper%TYPE;
  sec_op            number(3):=0;
  Begin
    OPEN p_ret_cur_arlcop for 
    SELECT * FROM arlcop WHERE no_cia = pc_no_cia and no_cliente = pc_no_cliente and cod_oper = pc_cod_oper_ori;
    fetch p_ret_cur_arlcop INTO r_arlcop;
   
   -- para Refinanciamiento 
   if lc_modal_cred = kc_ref then
     begin
      select num_oper
      into   ln_sec_oper

      from   arccmc 
      where  no_cia     = r_arlcop.no_cia
        and  grupo      = r_arlcop.grupo
        and  no_cliente = r_arlcop.no_cliente;
            
      select count(*) 
        into sec_op
        from arlcop 
       where instr(cod_oper,ln_sec_oper)>0;
          
           
      pc_cod_oper_ref := trim(to_char(pc_cod_oper_ori,'99999999999'))||'-'||trim(to_char(sec_op,'999'));
      ln_sec_oper := sec_op;
      pc_ret_mens := 'No hay numero de Operacion asignada al cliente en la tabla de parametros';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                  'SP_OBTENER_DATOS_OP',
                                  pc_cod_usua_web,
                                  'Error en la consulta',
                                  pc_ret_mens,
                                  pc_ret_mens);
     end; 
   end if;
  End sp_refrep_op;
  
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
  ) AS
  
  pd_fecha_cont arlcop.fecha%TYPE;
  pd_fecha_ini  arlcop.fecha_ini%TYPE;
  pd_fecha_aut  arlcop.fecha_aut_ope%TYPE;
  
 
  
  
  
  ln_cod_oper       arlcop.cod_oper%TYPE := null;
  kc_ref            arlcop.modal_cred%TYPE := 'R';
  lr_reclet         PKG_SWEB_CRED_LXC.t_table_reclet;
  lr_recaval        PKG_SWEB_CRED_LXC.t_table_arlcav;
  lr_recgast        PKG_SWEB_CRED_LXC.t_table_arlcgo;
  lref_fact         SYS_REFCURSOR;
  lref_aval         SYS_REFCURSOR;
  lref_gastos       SYS_REFCURSOR;
  r_fact            SYS_REFCURSOR;
  ln_mes            arlcop.mes%type;
  ln_ano            arlcop.ano%type;
  lc_modal_cred     arlcop.modal_cred%type;
  lc_moneda         arlcop.moneda%type;
  lc_no_cliente     arlcop.no_cliente%type;
  lc_grupo          arlcop.grupo%type;
  ln_tipo_cambio    arlcop.tipo_cambio%type;
  lc_mon_tasa_igv   arlcop.mon_tasa_igv%type;
  lc_cod_oper       arlcop.cod_oper%type;
  
  
  ve_error EXCEPTION;

  Begin
  
  pd_fecha_cont := TO_DATE(pd1_fecha_cont, 'dd/mm/yyyy');
  pd_fecha_ini  := TO_DATE(pd1_fecha_ini, 'dd/mm/yyyy');
  pd_fecha_aut  := sysdate;
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_guardar_op',
                                        pc_cod_usua_web,
                                        pc_no_cia || '-' ||      
                                        pc_no_cliente || '-' ||          
                                        pc_num_soli || '-' ||            
                                        pc_tipo_cred || '-' ||           
                                        pc_tipo_doc_op || '-' ||         
                                        pd_fecha_cont || '-' ||           
                                        pd_fecha_ini || '-' ||            
                                        pc_tipo_cuota || '-' ||           
                                        pd_fecha_aut || '-' ||             
                                        pc_usuario_aprb || '-' ||        
                                        pc_cod_usua_web,
                                        'antes de setear la tabla p_cur_fact',
                                        pc_num_soli);

    BEGIN
      SELECT cod_oper_rel 
      INTO   ln_cod_oper 
      FROM   vve_cred_soli 
      WHERE  cod_soli_Cred = pc_num_soli  
      AND    cod_empr      = pc_no_cia; 
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_cod_oper := NULL;
    END;

    IF ln_cod_oper IS NULL THEN                                     
        select grupo into lc_grupo from cxc.arccmc where no_cia = pc_no_cia and no_cliente = pc_no_cliente;  
        
        FOR i IN 1 .. p_cur_fact.COUNT
        LOOP
            lr_reclet(i).tipo_docu := p_cur_fact(i).tipo_docu;
            lr_reclet(i).grupo := lc_grupo; --p_cur_fact(i).grupo;
            lr_reclet(i).no_cliente := pc_no_cliente; --p_cur_fact(i).no_cliente;
            lr_reclet(i).no_docu := p_cur_fact(i).no_docu;
            lr_reclet(i).cod_oper := p_cur_fact(i).cod_oper;
            lr_reclet(i).fecha := p_cur_fact(i).fecha;
            lr_reclet(i).moneda := p_cur_fact(i).moneda;
            lr_reclet(i).monto := p_cur_fact(i).monto;
            lr_reclet(i).cod_ref := p_cur_fact(i).cod_ref;
            lr_reclet(i).est_ref := p_cur_fact(i).est_ref;
            lr_reclet(i).saldo_anterior := p_cur_fact(i).saldo_anterior;
            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'sp_guardar_op',
                                            pc_cod_usua_web,
                                            p_cur_fact(i).tipo_docu || '-' ||
                                            lr_reclet(i).no_docu || '-' ||
                                            p_cur_fact(i).moneda || '-' ||
                                            p_cur_fact(i).monto,
                                            'despues de setear el tipo lr_reclet',
                                            pc_num_soli);       
        END LOOP;
     
        OPEN lref_fact FOR
            SELECT * FROM TABLE(lr_reclet);
        
        
        /*Genera el nro de op y registra en arlcop*/
        begin
            sp_crear_arlcop(  pc_no_cia,
                          pc_no_cliente,
                          pc_num_soli,
                          ln_cod_oper,
                          pc_tipo_cred,
                          pc_tipo_doc_op,
                          pd_fecha_cont,
                          pd_fecha_ini,
                          pc_tipo_cuota,
                          pd_fecha_aut,
                          pc_usuario_aprb,
                          pc_cod_usua_web,
                          lref_fact,
                          pn_ret_esta,
                          pc_ret_mens
                          );
           
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'sp_guardar_op - creo arlcop',
                                                pc_cod_usua_web,
                                                'Paso sp_crear_arlcop: COD_OPER' || ' - ' || 
                                                ln_cod_oper,
                                                pc_num_soli,
                                                pc_num_soli); 
        exception 
          when others then 
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'Error consulta',
                                                pc_cod_usua_web,
                                                'Error en sp_guardar_op-sp_crear_arlcop',
                                                pc_num_soli,
                                                pc_num_soli);               
        end;                     
        
        --IF lc_cod_oper IS NOT NULL THEN  
        IF ln_cod_oper IS NOT NULL THEN
          select modal_cred,moneda,no_cliente,grupo,tipo_cambio,mon_tasa_igv,cod_oper  
          into   lc_modal_cred, lc_moneda,lc_no_cliente,lc_grupo, ln_tipo_cambio,lc_mon_tasa_igv,lc_cod_oper 
          from   arlcop 
          where  no_cia = pc_no_cia 
          and    cod_oper = ln_cod_oper;
          
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'Error consulta',
                                                pc_cod_usua_web,
                                                'Error en sp_guardar_op lc_cod_oper IS NOT NULL OP:'||lc_cod_oper||'- ln_cod_oper:'||TO_CHAR(ln_cod_oper),
                                                pc_num_soli,
                                                pc_num_soli);               

        END IF;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'Error consulta',
                                                pc_cod_usua_web,
                                                'Error en sp_guardar_op lc_cod_oper IS  NULL OP:'||lc_cod_oper||'- ln_cod_oper:'||TO_CHAR(ln_cod_oper),
                                                pc_num_soli,
                                                pc_num_soli); 
        
        FOR i IN 1 .. p_cur_fact.COUNT
        LOOP
            lr_reclet(i).tipo_docu := p_cur_fact(i).tipo_docu;
            lr_reclet(i).grupo := lc_grupo; --p_cur_fact(i).grupo;
            lr_reclet(i).no_cliente := pc_no_cliente; --p_cur_fact(i).no_cliente;
            lr_reclet(i).no_docu := p_cur_fact(i).no_docu;
            lr_reclet(i).cod_oper := lc_cod_oper; --p_cur_fact(i).cod_oper;
            lr_reclet(i).fecha := p_cur_fact(i).fecha;
            lr_reclet(i).moneda := p_cur_fact(i).moneda;
            lr_reclet(i).monto := p_cur_fact(i).monto;
            lr_reclet(i).cod_ref := p_cur_fact(i).cod_ref;
            lr_reclet(i).est_ref := p_cur_fact(i).est_ref;
            lr_reclet(i).saldo_anterior := p_cur_fact(i).saldo_anterior;
            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'sp_guardar_op',
                                            pc_cod_usua_web,
                                            p_cur_fact(i).tipo_docu || '-' ||
                                            lr_reclet(i).no_docu || '-' ||
                                            p_cur_fact(i).moneda || '-' ||
                                            p_cur_fact(i).monto,
                                            'despues de setear el tipo lr_reclet',
                                            pc_num_soli);       
        END LOOP;

        
        OPEN lref_fact FOR
            SELECT * FROM TABLE(lr_reclet);
            
        -- Actualiza en arccmd y/o crea registro con validaciones en arlcrd (docs x op)
        begin
          
          sp_crear_arlcrd(pc_no_cia,
                          pc_no_cliente,
                          pc_num_soli,
                          ln_cod_oper,
                          null,
                          pc_tipo_cred,
                          pc_cod_usua_web,
                          lref_fact,
                          --p_cur_fact,
                          pn_ret_esta,
                          pc_ret_mens
                          );
                             
          p_cur_fact_ret := lref_fact;   
          
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_guardar_op',
                                              pc_cod_usua_web,
                                              'Paso sp_crear_arlcrd',
                                              pc_num_soli,
                                              pc_num_soli);
        exception
          when others then
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'Error sp_guardar_op-sp_crear_arlcrd',
                                              pc_cod_usua_web,
                                              'Error sp_crear_arlcrd',
                                              pc_num_soli,
                                              pc_num_soli);
           ROLLBACK;
           --DELETE ARLCOP WHERE COD_OPER = ln_cod_oper AND NO_CIA = pc_no_cia AND NO_CLIENTE = pc_no_cliente;
           --COMMIT; 
        end;
        --Se crea las letras con los datos del simulador y nro de op generada
        begin
          sp_crear_arlcml(pc_no_cia,
                          pc_num_soli,
                          ln_cod_oper,
                          ln_cod_oper,
                          pc_cod_usua_web,
                          pn_ret_esta,
                          pc_ret_mens
                        );
                        
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_guardar_op',
                                              pc_cod_usua_web,
                                              'Paso sp_crear_arlcml',
                                              pc_num_soli,
                                              pc_num_soli);
        exception
          when others then 
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'Error sp_guardar_op-sp_crear_arlcml',
                                              pc_cod_usua_web,
                                              'Error sp_crear_arlcml',
                                              pc_num_soli,
                                              pc_num_soli);
        end;                                      
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'sp_guardar_op',
                                            pc_cod_usua_web,
                                            'Antes de arlcav COD_OPER = ' || ' ' ||ln_cod_oper,
                                            pc_num_soli,
                                            pc_num_soli);
        
        FOR i IN 1 .. p_cur_aval.COUNT
        LOOP
            lr_recaval(i).no_cia := pc_no_cia ;
            lr_recaval(i).cod_oper := lc_cod_oper ;
            lr_recaval(i).sec_aval := p_cur_aval(i).sec_aval ;
            lr_recaval(i).nom_aval := p_cur_aval(i).nom_aval ;
            lr_recaval(i).direc_aval := p_cur_aval(i).direc_aval ;
            lr_recaval(i).le := p_cur_aval(i).le ;
            lr_recaval(i).telf_aval := p_cur_aval(i).telf_aval ;
            lr_recaval(i).des_aval := p_cur_aval(i).des_aval ;
            lr_recaval(i).no_soli := p_cur_aval(i).no_soli ;
            lr_recaval(i).ruc := p_cur_aval(i).ruc ;
            lr_recaval(i).representante := p_cur_aval(i).representante ;
        END LOOP;              
        
        open lref_aval for
        select * from table(lr_recaval);
    --lr_recgast    p_cur_gasto

        begin
          sp_crear_arlcav(pc_no_cia,
                          ln_cod_oper,
                          pc_num_soli,
                          lref_aval,
                          pc_cod_usua_web,
                          pn_ret_esta,
                          pc_ret_mens);
                                                                
          pc_ret_mens := 'Paso sp_crear_arlcav';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_guardar_op',
                                              pc_cod_usua_web,
                                              'Paso sp_crear_arlcav',
                                              pc_ret_mens,
                                              pc_num_soli);
        exception
          when others then
            if lref_aval is null then pc_ret_mens := 'lref_aval is nulo'; end if;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'Error sp_guardar_op-sp_crear_arlcav',
                                              pc_cod_usua_web,
                                              'Error sp_crear_arlcav '||pc_ret_mens,
                                              pc_ret_mens,
                                              pc_num_soli);
        end;               
        
        FOR i IN 1 .. p_cur_gasto.COUNT
        LOOP
            lr_recgast(i).no_cia := p_cur_gasto(i).no_cia ;
            lr_recgast(i).cod_gasto := p_cur_gasto(i).cod_gasto ;
            lr_recgast(i).cod_oper := lc_cod_oper ;
            lr_recgast(i).monto := p_cur_gasto(i).monto ;
            lr_recgast(i).moneda := p_cur_gasto(i).moneda ;
            lr_recgast(i).tipo_cambio := ln_tipo_cambio ;
            lr_recgast(i).signo := 1 ;
            lr_recgast(i).observaciones := 'Factura por prima de seguro' ;
            lr_recgast(i).no_docu := p_cur_aval(i).no_soli ;
            lr_recgast(i).ind_finan := 'N' ;
            
        END LOOP;
        
        open lref_gastos for
        select * from table(lr_recgast);  
      
        begin
            sp_crear_arlcgo(pc_no_cia,
                            ln_cod_oper,
                            pd_fecha_ini,
                            lref_gastos,
                            pc_cod_usua_web,
                            pc_ret_mens,
                            pc_ret_mens);
                            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'sp_guardar_op',
                                                pc_cod_usua_web,
                                                'Paso sp_crear_arlcgo',
                                                pc_num_soli,
                                                pc_num_soli);
        exception 
          when others then
            if lref_gastos is null then pc_ret_mens := 'cur_gastos is nulo'; end if;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                                'Error sp_guardar_op-sp_crear_arlcgo',
                                                pc_cod_usua_web,
                                                'Error sp_crear_arlcgo '||pc_ret_mens,
                                                pc_ret_mens,
                                                pc_num_soli);
        end;    
        
        if ln_cod_oper is not null then 
          sp_act_op_soli(pc_no_cia,
                         pc_num_soli,
                         ln_cod_oper,
                         pc_tipo_cred,
                         pc_cod_usua_web,
                         pn_ret_esta,
                         pc_ret_mens
                         );
                         
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_guardar_op',
                                              pc_cod_usua_web,
                                              'Paso sp_act_op_soli',
                                              pc_num_soli,
                                              pc_num_soli);
        end if;

        pn_ret_esta := 1;
        pc_ret_mens := 'Se guardó correctamente la Operacion LXC';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_guardar_op - se guardo LxC',
                                              pc_cod_usua_web,
                                              'Paso sp_act_op_soli',
                                              pc_ret_mens,
                                              pc_num_soli);   
               -- Atualizando actividades y etapas   
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(pc_num_soli,'E7','A36',pc_cod_usua_web,pn_ret_esta,pc_ret_mens);   
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(pc_num_soli,'E7','A37',pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
    ELSE
        pc_ret_mens := 'Ya existe una operación para esta solicitud';
    END IF;    
    EXCEPTION
        WHEN ve_error THEN
            pn_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_guardar_op', pc_cod_usua_web, 'Error al insertar la Operacion LxC'
            , pc_ret_mens, pc_num_soli);
            ROLLBACK;
        WHEN OTHERS THEN
            pn_ret_esta := -1;
            pc_ret_mens := 'sp_guardar_op:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_guardar_op', pc_cod_usua_web, 'Error al insertar la Operacion LxC'
            , pc_ret_mens, pc_num_soli);
            ROLLBACK;
  
  End sp_guardar_op;

  Procedure sp_obtener_datos_op(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
  pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
  pc_cod_oper       IN      vve_cred_soli.cod_oper_rel%TYPE,
  pc_tipo_doc_op    IN      arlcop.tipo_factu%TYPE,
  pd_fecha_cont     IN      arlcop.fecha%TYPE, -- fecha contrato
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE, -- fecha entrega
  pc_tipo_cuota     IN      arlcop.tipo_cuota%TYPE,
  pd_fecha_aut      IN      arlcop.fecha_aut_ope%TYPE,
  pc_usuario_aprb   IN      arlcop.usuario_aprb%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_rec_cur_fact    IN      SYS_REFCURSOR,
  p_rec_arlcop      OUT     pkg_sweb_cred_lxc.t_rec_arlcop, --arlcop%rowtype,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) AS
  
 -- Cursor c_fact is select tipo_docu,no_cliente,no_docu,fecha,est_ref,moneda,monto from ARLCRD;
  ve_error          EXCEPTION;
  lc_no_cia         arlcop.no_cia%TYPE;
  ln_cod_oper       arccmc.num_oper%TYPE;
  lc_cod_oper       arlcop.cod_oper%TYPE;
  ln_ano            arlcop.ano%TYPE;
  ln_mes            arlcop.mes%TYPE;
  lc_grupo          arlcop.grupo%TYPE; 
  lc_no_cliente     arlcop.no_cliente%TYPE;   -- vve_cred_soli.cod_clie
  lc_modal_cred     arlcop.modal_cred%TYPE;
  ld_fecha          arlcop.fecha%TYPE; -- sysdate
  lc_tipo_cred      vve_cred_soli.tip_soli_cred%TYPE;
  ln_tea            vve_cred_soli.val_porc_tea_sigv%TYPE;
  ln_nro_let_per_gra vve_cred_simu.can_let_per_gra%TYPE;
  lc_periodicidad   vve_cred_soli.cod_peri_cred_soli%TYPE; 
  lc_cod_moneda     vve_cred_soli.cod_mone_soli%TYPE;
  ln_tasa_igv       arcgiv.porcentaje%TYPE;
  ln_tasa_isc       arcgiv.porcentaje%TYPE; -- 0
  ln_valor_ori      arlcop.valor_original%TYPE; -- vve_cred_soli.val_tot_fina = suma (cursor_fact.monto)
  ln_monto_gastos   arlcop.monto_gastos%TYPE; -- vve_cred_simu_gast.val_mon_total (concepto = 8) SOLO EL SEGURO
  ln_monto_fina     arlcop.monto_fina%TYPE; -- vve_cred_soli.val_tot_fina + ln_mon_gast_seg
  ln_int_per_gra    arlcop.interes_per_gra%TYPE; -- vve_cred_soli.VAL_INT_PER_GRA
  ln_tot_fina       arlcop.total_financiar%TYPE; -- vve_cred_soli.val_tot_fina + ln_monto_gastos
  ln_int_oper       arlcop.interes_oper%TYPE; -- suma (vve_cred_simu_lede.val_mon_conc (concepto=4))
  ln_tot_igv        arlcop.total_igv%TYPE; -- vve_cred_soli.val_mon_fin*VAL_PORC_TEA_SIGV*ln_tasa_igv
  ln_tot_isc        arlcop.total_isc%TYPE;  -- 0
  lc_cod_mone       arlcop.moneda%TYPE;  -- vve_cred_soli.cod_mone_soli
  ln_tipo_cambio    arlcop.tipo_cambio%TYPE; -- select Tipo_cambio from arcgtc where clase_cambio = '02' and fecha = sysdate;
  ln_plazo          arlcop.plazo%TYPE; -- vve_tabla_maes.valor_adic_1/12 (cod_grupo = 88)
  ln_nro_cuotas     arlcop.no_cuotas%TYPE; -- vve_cred_soli.can_tota_letr + can_letr_peri_grac
  ld_fec_vto_1ra_let arlcop.vcto_1ra_let%TYPE; -- vve_cred_soli.FEC_VENC_1RA_LET 
  ln_frec_pago_dias arlcop.fre_pago_dias%TYPE; -- 30*vve_tabla_maes.valor_adic_1
  ln_dia_pago       arlcop.dia_pago%TYPE; -- dd (ld_fec_vto_1ra_let) 
  lc_ind_tipo_cuo   arlcop.tipo_cuota%TYPE; -- F = fijo, V=variable
  lc_ind_per_gra    arlcop.ind_per_gra%TYPE; -- si vve_cred_soli.IND_TIPO_PERI_GRAC not null => S, else N
  lc_ind_per_gra_cap arlcop.ind_per_gra_cap%TYPE; -- si lc_ind_per_gra=S => S else N
  ln_tasa_gra       arlcop.tasa_gra%TYPE;  -- ln_tea
  ln_fre_gra        arlcop.fre_gra%TYPE; -- vve_cred_soli.can_dias_ven_1ra_letr ----vve_cred_soli.can_letr_peri_grac*vve_tabla_maes.valor_adic_1*30
  ln_mon_cuo_ext    arlcop.mon_cuo_ext%TYPE; -- NULL
  lc_mon_cuo_ene    arlcop.cext_ene%TYPE; --N
  lc_mon_cuo_feb    arlcop.cext_feb%TYPE; -- N
  lc_mon_cuo_mar    arlcop.cext_mar%TYPE; -- N
  lc_mon_cuo_abr    arlcop.cext_abr%TYPE; -- N
  lc_mon_cuo_may    arlcop.cext_may%TYPE; -- N
  lc_mon_cuo_jun    arlcop.cext_jun%TYPE; -- N
  lc_mon_cuo_jul    arlcop.cext_jul%TYPE; -- N
  lc_mon_cuo_ago    arlcop.cext_ago%TYPE; -- N
  lc_mon_cuo_sep    arlcop.cext_sep%TYPE; -- N
  lc_mon_cuo_oct    arlcop.cext_oct%TYPE; -- N
  lc_mon_cuo_nov    arlcop.cext_nov%TYPE; -- N
  lc_mon_cuo_dic    arlcop.cext_dic%TYPE; -- N
  lc_cta_int_dife   arlcop.cta_interes_diferido%TYPE;
  lc_ingr_fina      arlcop.cta_ingresos_finan%TYPE;
  lc_estado         arlcop.estado%TYPE; -- P
  ld_fec_ini        arlcop.fecha_ini%TYPE; --ld_fec_vto_1ra_let
  ln_val_ci         arlcop.cuota_inicial%TYPE;
  lc_judicial       arlcop.judicial%TYPE; -- N
  lc_ind_nu         arlcop.ind_nu%TYPE; -- N
  lc_cod_filial     arlcop.cod_filial%TYPE; -- vve_proforma_veh.cod_filial
  lc_num_prof_veh   arlcop.num_prof_veh%TYPE;
  lc_tipodocgen     arlcop.tipodocgen%TYPE; -- F
  ln_sec_oper       arlcop.sec_oper%TYPE;
  lc_usuario_aprb   arlcop.usuario_aprb%TYPE; -- parametro
  lc_txt_usua_apro  sis_mae_usuario.txt_usuario%TYPE;
  ld_fec_aut_ope    arlcop.fecha_aut_ope%TYPE; -- parametro
  lc_cod_simu       vve_cred_simu.cod_simu%TYPE; 
  lc_cod_usua_web   sis_mae_usuario.txt_usuario%TYPE;
  kc_clase_cambio   arcgtc.clase_cambio%TYPE:= '02';
  kc_clave_igv      arcgiv.clave%TYPE := '01';
  kc_periodicidad   vve_tabla_maes.cod_grupo_rec%TYPE := 88;
  kc_para_tipo_peri vve_tabla_maes.cod_tipo_rec%TYPE := 'PER';
  kc_tc_directo     vve_cred_soli.tip_soli_cred%TYPE := 'TC01';
  kc_tc_leas        vve_cred_soli.tip_soli_cred%TYPE := 'TC02';
  kc_tc_mutuo       vve_cred_soli.tip_soli_cred%TYPE := 'TC03';
  kc_tc_gbanc       vve_cred_soli.tip_soli_cred%TYPE := 'TC06';
  kc_tc_pv          vve_cred_soli.tip_soli_cred%TYPE := 'TC05';
  kc_tc_ref         vve_cred_soli.tip_soli_cred%TYPE := 'TC07';
  kc_financ         arlcop.modal_cred%TYPE := 'F';
  kc_mutuo          arlcop.modal_cred%TYPE := 'M';
  kc_pv             arlcop.modal_cred%TYPE := 'P';
  kc_ref            arlcop.modal_cred%TYPE := 'R';
  kc_ind_inactivo   vve_cred_simu.ind_inactivo%TYPE := 'N';
  kn_cod_conc_seg   vve_cred_simu_gast.cod_conc_col%TYPE := 8;
  kc_no             varchar2(1) := 'N';
  kc_si             varchar2(1) := 'S';
  kc_cuo_fijo       varchar2(1) := 'F';
  kc_pendiente      arlcop.estado%TYPE := 'P';
  kc_nuevo          arlcop.ind_nu%TYPE := 'N';
  kc_tipo_doc_fact  arlcop.tipodocgen%TYPE := 'F';
  kc_tipo_factu     arlcop.tipo_factu%TYPE := 'T';
  ln_tcred_mutuo    number(5) := 0; 
  kc_tcred_prof_ope vve_cred_soli_para.cod_cred_soli_para%type := 'TIPCREPROFOP';
  --ltyp_fact         VVE_TYTA_DOCU_RELA,
  --lr_fact           PKG_SWEB_CRED_LXC.t_fact_arfafe;
  lr_fact           PKG_SWEB_CRED_LXC.t_fact_x_op;
  ln_suma_fact      arlcop.total_financiar%TYPE :=0;
  kc_concep_inte    vve_cred_maes_conc_letr.cod_conc_col%TYPE := 4;
  kc_concep_igv     vve_cred_maes_conc_letr.cod_conc_col%TYPE := 13;
  kc_ind_nu_ninguno arlcop.ind_nu%TYPE:= 'O';
  lc_modal_cred_new arlcop.modal_cred%TYPE;
  cur_arlcop        sys_refcursor;
  sec_op            NUMBER(3);
  
  lr_t_fact_x_op t_fact_x_op;
  type t_tipo_nu is varray(2) of vve_pedido_veh.ind_nuevo_usado%type;
  c_tipo_n_u     t_tipo_nu;
  
  cursor c_tipo_veh_nuevo_usado is
  select distinct p.ind_nuevo_usado  
    from vve_pedido_veh p, vve_proforma_veh c, 
         vve_proforma_veh_det d, vve_cred_soli_prof sp
   where p.cod_cia        = pc_no_cia 
     and p.num_prof_veh   = c.num_prof_veh 
     and p.cod_cia        = c.cod_cia 
     and c.num_prof_veh   = p.num_prof_veh
     and d.num_prof_veh   = sp.num_prof_veh 
     and sp.cod_soli_cred = pc_num_soli;
  
  BEGIN
    pc_ret_mens := '';
    lc_no_cia   := pc_no_cia;
      
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_obtener_datos_op',
                                        pc_cod_usua_web,
                                        pc_no_cia || ' ' ||
                                        pc_num_soli,
                                        'Entro a sp_obtener_datos_op',
                                        pc_num_soli); 
                                        
       ln_cod_oper := null;
          
       if ln_cod_oper is not null then 
       pc_ret_mens := 'obtuvo nro op en solicitud - oper :'||ln_cod_oper;
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'ln_cod_oper is not null',
                                        pc_ret_mens,
                                        pc_num_soli);
      else 
       pc_ret_mens := 'NO EXISTE NRO OP PARA LA SOLICITUD';
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'ln_cod_oper is null',
                                        pc_ret_mens,
                                        pc_num_soli);
      end if;
    /*
      EXCEPTION
      WHEN NO_DATA_FOUND THEN 
       pc_ret_mens := 'NO EXISTE LA SOLICITUD';
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error en la consulta',
                                        pc_ret_mens,
                                        NULL);
     */

    
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Termino validacion',
                                        pc_ret_mens,
                                        pc_num_soli);

    if ln_cod_oper is null then 
      ln_cod_oper := sf_obtener_nro_op(pc_no_cia,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
      
      lc_cod_oper := trim(to_char(ln_cod_oper,'99999999999'));
      
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        ln_cod_oper,
                                        pc_ret_mens,
                                        pc_num_soli);
      
      BEGIN
        SELECT cod_simu 
          INTO lc_cod_simu 
          FROM vve_cred_simu 
         WHERE cod_soli_cred = pc_num_soli 
           AND ind_inactivo  = kc_ind_inactivo;
        pc_ret_mens := 'se obtuvo cod_simu '||lc_cod_simu;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'SP_OBTENER_DATOS_OP',
                                    pc_cod_usua_web,
                                    'Obteniendo cod_simu',
                                    pc_ret_mens,
                                    pc_num_soli);
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
          pc_ret_mens := 'no se obtuvo cod_simu';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'SP_OBTENER_DATOS_OP',
                                      pc_cod_usua_web,
                                      'Error en la consulta',
                                      pc_ret_mens,
                                      pc_num_soli);
      END;
      
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 1',
                                        pc_ret_mens,
                                        pc_num_soli);
        
      if lc_cod_simu is not null then 
        begin /* Obteniendo el total de gasto por concepto de seguro */
          select nvl(val_mon_total,0) 
          into   ln_monto_gastos 
          from   vve_cred_simu_gast 
          where  cod_simu     = lc_cod_simu 
          and    cod_conc_col = kn_cod_conc_seg 
          and    ind_fin      = kc_si;
          pc_ret_mens := 'se obtuvo gastos por seguro'||TO_CHAR(ln_monto_gastos,'9999999999.99');
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SP_OBTENER_DATOS_OP',
                                          pc_cod_usua_web,
                                          'Error en la consulta',
                                          pc_ret_mens,
                                          pc_num_soli);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
            ln_monto_gastos := 0;
            pc_ret_mens := 'se obtuvo gastos por seguro'||TO_CHAR(ln_monto_gastos,'9999999999.99');
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_num_soli);
        end;
      end if;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 2',
                                        pc_ret_mens,
                                        pc_num_soli);
        
        begin
          select 
            case pc_tipo_cred 
              when kc_tc_directo then kc_financ
              when kc_tc_leas    then kc_mutuo 
              when kc_tc_mutuo   then kc_mutuo 
              when kc_tc_gbanc   then kc_mutuo 
              when kc_tc_pv      then kc_pv
              when kc_tc_ref     then kc_ref
            end modal_cred,
            tip_soli_cred, val_mon_fin valor_ori, val_int_per_gra, val_mon_fin + ln_monto_gastos valor_tot_fin, 
            decode(cod_mone_soli,1,'SOL',2,'DOL'), 
            can_letr_peri_grac, can_tota_letr+can_letr_peri_grac total_cuotas, fec_venc_1ra_let, 
            decode(ind_tipo_peri_grac,null,kc_no,kc_si) ind_per_gra, val_porc_tea_sigv,cod_peri_cred_soli,
            val_ci
          into
            lc_modal_cred, lc_tipo_cred, ln_valor_ori, ln_int_per_gra, ln_monto_fina, lc_cod_mone, ln_nro_let_per_gra,ln_nro_cuotas,
            ld_fec_vto_1ra_let, lc_ind_per_gra, ln_tea, lc_periodicidad, ln_val_ci
          from  vve_cred_soli 
          where cod_soli_cred = pc_num_soli and cod_empr = pc_no_cia;

          pc_ret_mens := 'se obtuvo la data de vve_cred_soli';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_num_soli);
        
        end;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 3',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        lc_modal_cred_new  := lc_modal_cred;
        ln_tot_fina        := ln_monto_fina;
        
        ln_suma_fact       := 0;
        if p_rec_cur_fact is not null then 
          pc_ret_mens := 'Entro al if de la lista de facturas';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error en la consulta',
                                        pc_ret_mens,
                                        pc_num_soli);
    	
          LOOP
            FETCH p_rec_cur_fact  --INTO lr_t_fact_x_op; -- lr_fact
            --INTO ltyp_fact;
            INTO lr_fact;
            EXIT WHEN p_rec_cur_fact%NOTFOUND;
            
            
            --pc_ret_mens := 'la lista de facturas es no null '||lr_fact.no_factu;
            pc_ret_mens := 'la lista de facturas es no null '||lr_fact.no_docu;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'p_rec_cur_fact 1',
                                        pc_ret_mens,
                                        pc_num_soli);            
            
            ln_suma_fact := ln_suma_fact + lr_fact.monto; -- suma lo que se seteo en pantalla
            --ln_suma_fact := ln_suma_fact + lr_fact.val_pre_docu; -- suma lo que se seteo en pantalla
            pc_ret_mens  := 'se obtuvo la suma de las facturas';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SP_OBTENER_DATOS_OP',
                                          pc_cod_usua_web,
                                          'p_rec_cur_fact 2',
                                          pc_ret_mens,
                                          pc_num_soli);
          END LOOP;
          CLOSE p_rec_cur_fact;
        END IF;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 4 - ln_suma_fact: '||to_char(ln_suma_fact,'999999999.99'),
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        IF ln_suma_fact <> ln_valor_ori THEN 
          pn_ret_esta := 1;
          pc_ret_mens := 'El monto ingresado en facturas no coincide con el monto a financiar';
          pc_ret_mens := 'se borra return para las pruebas';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_num_soli);
          --return;
        END IF;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 5',
                                        pc_ret_mens,
                                        pc_num_soli);
        
        if pd_fecha_ini is not null then 
          begin
            select TO_NUMBER(TO_CHAR(pd_fecha_ini,'YYYY'),'9999'),TO_NUMBER(TO_CHAR(pd_fecha_ini,'MM'),'99') 
              into ln_ano,ln_mes 
              from DUAL;
          
            pc_ret_mens := 'obteniendo fechas ln_ano: '||to_char(ln_ano,'9999')||', ln_mes: '||to_char(ln_mes,'99');
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_num_soli);
          end;

          ld_fecha := pd_fecha_ini; -- pd_fecha_ini es la fecha de entrega del veh o fecha de vencimiento en sid Gen. Op.
          
        end if;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 6',
                                        pc_ret_mens,
                                        pc_num_soli);
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'PARAM = ' || pc_no_cia || ' ' ||
                                        pc_num_soli,
                                        pc_ret_mens,
                                        pc_num_soli);
        
        lc_ind_nu := 'O'; -- ninguno (ni nuevo ni usado)
        open c_tipo_veh_nuevo_usado; 
          if SQL%ROWCOUNT = 0  then 
            lc_ind_nu := 'O'; -- ninguno (ni nuevo ni usado)
          elsif SQL%ROWCOUNT = 1 then 
            lc_ind_nu := c_tipo_n_u(1); -- tomará o N (nuevo) o U (usado)
          elsif SQL%ROWCOUNT = 2 then 
            lc_ind_nu := 'A'; -- ambos 
          end if;

        -- Obteniendo el grupo al que pertenece el cliente
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 7',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 7 = ' || pc_no_cia || ' ' ||pc_no_cliente,
                                        pc_ret_mens,
                                        pc_num_soli);
        
        begin 
          select grupo into lc_grupo from cxc.arccmc where no_cia = pc_no_cia and no_cliente = pc_no_cliente; 
          pc_ret_mens := 'obteniendo LC_GRUPO: '||lc_grupo;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_num_soli);
        end;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 8',
                                        pc_ret_mens,
                                        pc_num_soli);
        
        lc_no_cliente  := pc_no_cliente;
        ln_tasa_isc  := 0;
        ln_tot_isc   := 0;
        lc_ind_per_gra_cap  := lc_ind_per_gra;
        ln_tasa_gra  := ln_tea;
        
        begin
        
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 8 = ' || kc_clase_cambio || ' ' ||
                                        pd_fecha_ini,
                                        pc_ret_mens,
                                        pc_num_soli);
          select tipo_cambio 
          into   ln_tipo_cambio 
          from   arcgtc 
          where  clase_cambio = kc_clase_cambio
          --and    fecha = trunc(pd_fecha_ini);
          and    fecha IN (select MIN(X.fecha) 
                 from (select max(fecha) fecha from arcgtc where  clase_cambio = '02' 
                       union 
                       select trunc(pd_fecha_ini) fecha from dual)X);  
          
          pc_ret_mens := 'se obtiene el tipo de cambio';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'SP_OBTENER_DATOS_OP',
                                      pc_cod_usua_web,
                                      'Entro a consultar Tipo de Cambio',
                                      pc_ret_mens,
                                      pc_num_soli);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
            ln_tipo_cambio := 0;
            pc_ret_mens := 'NO EXISTE TIPO DE CAMBIO PARA LA FECHA ACTUAL Y/O MONEDA';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error en la consulta',
                                        pc_ret_mens,
                                        pc_num_soli);
            -- RETURN; -- DESCOMENTAR DESPUES DE PRUEBAS 
        end;  
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 9',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        begin
          select (porcentaje/100) into ln_tasa_igv from arcgiv where no_cia = pc_no_cia and clave = kc_clave_igv;
          pc_ret_mens := 'se obtiene la tasa de igv';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                  'SP_OBTENER_DATOS_OP',
                                                  pc_cod_usua_web,
                                                  'Error en la consulta',
                                                  pc_ret_mens,
                                                  pc_num_soli);
        end;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 10',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 10 kc_periodicidad = ' || ' ' ||
                                        kc_periodicidad,
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        begin
            select valor_adic_1, valor_adic_2 
              into ln_plazo,ln_frec_pago_dias 
              from vve_tabla_maes 
             where cod_grupo = kc_periodicidad
             and cod_tipo_rec = kc_para_tipo_peri  
             and cod_tipo  = lc_periodicidad;
            pc_ret_mens := 'se obtiene los datos de frecuencia de pago';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                    'SP_OBTENER_DATOS_OP',
                                                    pc_cod_usua_web,
                                                    'Error en la consulta',
                                                    pc_ret_mens,
                                                    pc_num_soli);
        end;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 11',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
        begin
          select nivel_1_id||nivel_2_id||nivel_3_id||nivel_4_id||nivel_5_id,
                 nivel_1_if||nivel_2_if||nivel_3_if||nivel_4_if||nivel_5_if
          into   lc_cta_int_dife,lc_ingr_fina
          from   arlctp
          where  no_cia = pc_no_cia;
          pc_ret_mens := 'se obtiene los datos de cuentas contables lc_cta_int_dife: '||lc_cta_int_dife||' ,lc_ingr_fina: '||lc_ingr_fina ;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_num_soli);
        end;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 12',
                                        pc_ret_mens,
                                        pc_num_soli);
                                        
                                        
        begin
          select p.cod_filial, p.num_prof_veh 
          into   lc_cod_filial, lc_num_prof_veh
          from   vve_proforma_veh p, vve_cred_soli_prof sp 
          where  p.num_prof_veh = sp.num_prof_veh 
          and    sp.cod_soli_cred = pc_num_soli 
          and    p.cod_cia = pc_no_cia
          and rownum = 1; -- cuando son mas de una proforma el usuario solo ingresa 1
          pc_ret_mens := 'se obtiene la filial';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'SP_OBTENER_DATOS_OP',
                                      pc_cod_usua_web,
                                      'Obteniendo filial y proforma',
                                      pc_ret_mens,
                                      pc_num_soli);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
            lc_cod_filial := null;
            pc_ret_mens := 'Error en obtener la filial relacionada a la solicitud';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error en la consulta',
                                        pc_ret_mens,
                                        pc_num_soli);
        end; 
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 13',
                                        pc_ret_mens,
                                        pc_num_soli);
/*                                               
       -- para Refinanciamiento 
       if lc_modal_cred = kc_ref and pc_cod_oper is not null then
         begin
          select num_oper
          into   ln_cod_oper
          from   arccmc 
          where  no_cia     = pc_no_cia
          and    grupo      = lc_grupo
          and    no_cliente = lc_no_cliente;
            
          select count(*) 
            into sec_op
            from arlcop 
           where instr(cod_oper,ln_cod_oper)>0;
           
          lc_cod_oper := trim(to_char(ln_cod_oper,'99999999999'))||'-'||trim(to_char(sec_op,'999'));
          ln_sec_oper := sec_op;
          pc_ret_mens := 'se obtiene el nro. de op para refinanciamiento';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'SP_OBTENER_DATOS_OP',
                                      pc_cod_usua_web,
                                      'Error en la consulta',
                                      pc_ret_mens,
                                      pc_num_soli);
         end; 
       elsif lc_modal_cred <> kc_ref and pc_cod_oper is null then-- CD, Mutuo/Leasing, PV
         begin
           
           select num_corre_oper 
             into ln_cod_oper 
             from arlctp where no_cia = pc_no_cia;
          
           pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Select ln_cod_oper = '||ln_cod_oper,
                                        pc_ret_mens,
                                        pc_num_soli);
           lc_cod_oper := trim(to_char(ln_cod_oper,'99999999999'));
         end;       
         begin  
           pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Antes del update de arlctp (cod_oper)',
                                        pc_ret_mens,
                                        pc_num_soli);
            update arlctp 
              --set num_corre_oper = (to_number(ln_cod_oper) + 1)
            set    num_corre_oper = ln_cod_oper + 1 
            where  no_cia = pc_no_cia;
            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Despues del update de arlctp (cod_oper): '||to_Char(ln_cod_oper + 1,'999999999999'),
                                        pc_ret_mens,
                                        pc_num_soli);
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               lc_cod_oper := NULL;
               pc_ret_mens := 'Hubo un Problema en el momento de Actualizar Correlativos ..Consulte - II ';
               pkg_sweb_mae_gene.sp_regi_rlog_erro( 'AUDI_ERR',
                                                    'SP_OBTENER_DATOS_OP',
                                                    pc_cod_usua_web,
                                                    'Error en la consulta',
                                                    pc_ret_mens,
                                                    pc_num_soli);
           end;
           begin
             select num_oper
             into   ln_sec_oper
             from   arccmc 
             where  no_cia     = pc_no_cia
             and    grupo      = lc_grupo
             and    no_cliente = lc_no_cliente;
                  
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lc_cod_oper := NULL;
                pc_ret_mens := 'No se encontró numero de operación a asignar';
                pkg_sweb_mae_gene.sp_regi_rlog_erro( 'AUDI_ERR',
                                                     'SP_OBTENER_DATOS_OP',
                                                     pc_cod_usua_web,
                                                     'Error en la consulta',
                                                     pc_ret_mens,
                                                     pc_num_soli);
          end;
       ELSIF pc_cod_oper is not null then 
          lc_cod_oper := pc_cod_oper;
       end if;
 */
       ----****  
       pc_ret_mens:= 'obteniendo la secuencia de operacion: '||ln_sec_oper;
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 14',
                                        pc_ret_mens,
                                        pc_num_soli);
       
       --ln_int_per_gra
       begin
         select sum(nvl(d.val_mon_conc,0)) 
         into   ln_int_per_gra
         from   vve_cred_simu_lede d, vve_cred_simu m, vve_cred_soli s 
         where  s.cod_soli_cred = pc_num_soli 
         and    s.cod_soli_cred = m.cod_soli_cred
         and    m.ind_inactivo  = kc_no 
         and    m.cod_simu      = d.cod_simu 
         and    d.cod_conc_col  in (kc_concep_inte,kc_concep_igv) 
         and    d.cod_nume_letr <= ln_nro_let_per_gra   
         group by (d.cod_simu);
                  
         pc_ret_mens := 'se obtiene el interes e igv del periodo de gracia'||to_char(ln_int_per_gra,'9999999.99');
         pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_num_soli);
       EXCEPTION
         WHEN OTHERS THEN 
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error al obtener el monto de Total de Intereses',
                                        pc_ret_mens,
                                        pc_num_soli);

       end;                                        
       
       -- kc_concep_inte
       begin
         select sum(nvl(d.val_mon_conc,0)) 
         into   ln_int_oper
         from   vve_cred_simu_lede d, vve_cred_simu m, vve_cred_soli s 
         where  s.cod_soli_cred = pc_num_soli 
         and    s.cod_soli_cred = m.cod_soli_cred
         and    m.ind_inactivo  = kc_no 
         and    m.cod_simu      = d.cod_simu 
         and    d.cod_conc_col  = kc_concep_inte 
         and    d.cod_nume_letr > ln_nro_let_per_gra   
         group by (d.cod_simu);
         
                  
         pc_ret_mens := 'se obtiene el monto total de intereses'||to_char(ln_int_oper,'9999999.99');
         pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_num_soli);
       EXCEPTION
         WHEN OTHERS THEN 
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error al obtener el monto de Total de Intereses',
                                        pc_ret_mens,
                                        pc_num_soli);

       end;                                        
       
       -- se obtiene el monto total del igv de la Op.,no incluye igv de periodo de gracia         
       begin
         select sum(nvl(d.val_mon_conc,0)) 
         into   ln_tot_igv
         from   vve_cred_simu_lede d, vve_cred_simu m, vve_cred_soli s 
         where  s.cod_soli_cred = pc_num_soli 
         and    s.cod_soli_cred = m.cod_soli_cred
         and    m.ind_inactivo  = kc_no 
         and    m.cod_simu      = d.cod_simu 
         and    d.cod_conc_col  = kc_concep_igv  
         and    d.cod_nume_letr > ln_nro_let_per_gra 
         group by (d.cod_simu);
         
         pc_ret_mens := 'se obtiene el monto total del igv'||to_char(ln_tot_igv,'9999999.99'); 
         pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_num_soli);
       EXCEPTION
         WHEN OTHERS THEN 
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Error al obtener el monto del IGV',
                                        pc_ret_mens,
                                        pc_num_soli);

       end;
       
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Paso 15',
                                        pc_ret_mens,
                                        pc_num_soli);
       
       ln_fre_gra       := ln_nro_let_per_gra * ln_frec_pago_dias;
       lc_ind_tipo_cuo  := kc_cuo_fijo;
       ln_dia_pago      := ln_frec_pago_dias;
       lc_estado        := kc_pendiente;
       ld_fec_ini       := pd_fecha_cont;
       lc_tipodocgen    := pc_tipo_doc_op;
       lc_usuario_aprb  := pc_usuario_aprb;
       ld_fec_aut_ope   := pd_fecha_aut;
       lc_mon_cuo_ene   := kc_no;
       lc_mon_cuo_feb   := kc_no;
       lc_mon_cuo_mar   := kc_no;
       lc_mon_cuo_abr   := kc_no;
       lc_mon_cuo_may   := kc_no;
       lc_mon_cuo_jun   := kc_no;
       lc_mon_cuo_jul   := kc_no;
       lc_mon_cuo_ago   := kc_no;
       lc_mon_cuo_sep   := kc_no;
       lc_mon_cuo_oct   := kc_no;
       lc_mon_cuo_nov   := kc_no;
       lc_mon_cuo_dic   := kc_no;
       lc_judicial      := kc_no;
       lc_ind_nu        := kc_nuevo;
       ln_mon_cuo_ext   := null;
       --ln_int_oper      := null;
       cur_arlcop       := null;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'COD_OPER GEN' || ' ' || 
                                            ln_cod_oper,
                                            pc_ret_mens,
                                            pc_num_soli);

        
       
       BEGIN
        SELECT cod_id_usua, fec_esta_apro 
        INTO   lc_usuario_aprb, ld_fec_aut_ope 
        FROM   vve_cred_soli_apro 
        WHERE  cod_soli_cred = pc_num_soli  
        AND    est_apro = 'EEA01'
        AND    ind_nivel = (SELECT MAX(ind_nivel) FROM vve_cred_soli_apro WHERE cod_soli_cred = pc_num_soli );
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'obteniendo aprobador y fecha de aprob' || ' ' ||lc_usuario_aprb||'-'||to_char(ld_fec_aut_ope,'dd/mm/yyyy')||' '|| 
                                            ln_cod_oper,
                                            pc_ret_mens,
                                            pc_num_soli);
       EXCEPTION
         WHEN OTHERS THEN
           pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_num_soli);
       END;
       select txt_usuario into lc_txt_usua_apro from sis_mae_usuario where cod_id_usuario = lc_usuario_aprb;
       select txt_usuario into lc_cod_usua_web from sis_mae_usuario where cod_id_usuario = pc_cod_usua_web;       
       
       /*struc aqui*/
       p_rec_arlcop.no_cia         := lc_no_cia;
       p_rec_arlcop.cod_oper       := lc_cod_oper; --ln_cod_oper
       p_rec_arlcop.ano            := ln_ano;
       p_rec_arlcop.mes            := ln_mes;
       p_rec_arlcop.grupo          := lc_grupo;
       p_rec_arlcop.no_cliente     := lc_no_cliente;
       p_rec_arlcop.modal_cred     := lc_modal_cred;
       p_rec_arlcop.tipo_bien      := null;
       p_rec_arlcop.fecha          := trunc(ld_fecha);
       p_rec_arlcop.tea            := ln_tea;
       p_rec_arlcop.mon_tasa_igv   := ln_tasa_igv;
       p_rec_arlcop.mon_tasa_isc   := ln_tasa_isc;
       p_rec_arlcop.valor_original := ln_valor_ori;
       p_rec_arlcop.monto_gastos   := ln_monto_gastos;
       p_rec_arlcop.monto_fina     := ln_monto_fina;
       p_rec_arlcop.interes_per_gra:= ln_int_per_gra;
       p_rec_arlcop.total_financiar:= ln_tot_fina;
       p_rec_arlcop.interes_oper   := ln_int_oper;
       p_rec_arlcop.total_igv      := ln_tot_igv;
       p_rec_arlcop.total_isc      := ln_tot_isc;
       p_rec_arlcop.moneda         := lc_cod_mone;
       p_rec_arlcop.tipo_cambio    := ln_tipo_cambio;
       p_rec_arlcop.plazo          := ln_plazo;
       p_rec_arlcop.no_cuotas      := ln_nro_cuotas;
       p_rec_arlcop.vcto_1ra_let   := trunc(ld_fec_vto_1ra_let);
       p_rec_arlcop.fre_pago_dias  := ln_frec_pago_dias;
       p_rec_arlcop.dia_pago       := ln_dia_pago;
       p_rec_arlcop.tipo_cuota     := pc_tipo_cuota;
       p_rec_arlcop.ind_per_gra    := lc_ind_per_gra;
       p_rec_arlcop.ind_per_gra_cap:= lc_ind_per_gra_cap;
       p_rec_arlcop.tasa_gra       := ln_tasa_gra;
       p_rec_arlcop.fre_gra        := ln_fre_gra;
       p_rec_arlcop.mon_cuo_ext    := ln_mon_cuo_ext;
       p_rec_arlcop.cext_ene       := lc_mon_cuo_ene;
       p_rec_arlcop.cext_feb       := lc_mon_cuo_feb;
       p_rec_arlcop.cext_mar       := lc_mon_cuo_mar;
       p_rec_arlcop.cext_abr       := lc_mon_cuo_abr;
       p_rec_arlcop.cext_may       := lc_mon_cuo_may;
       p_rec_arlcop.cext_jun       := lc_mon_cuo_jun;
       p_rec_arlcop.cext_jul       := lc_mon_cuo_jul;
       p_rec_arlcop.cext_ago       := lc_mon_cuo_ago;
       p_rec_arlcop.cext_sep       := lc_mon_cuo_sep;
       p_rec_arlcop.cext_oct       := lc_mon_cuo_oct;
       p_rec_arlcop.cext_nov       := lc_mon_cuo_nov;
       p_rec_arlcop.cext_dic       := lc_mon_cuo_dic;
       p_rec_arlcop.cta_interes_diferido := lc_cta_int_dife;
       p_rec_arlcop.cta_ingresos_finan   := lc_ingr_fina;
       p_rec_arlcop.estado         := kc_pendiente;
       p_rec_arlcop.usuario	       := lc_cod_usua_web;
       p_rec_arlcop.usuario_aprb   := lc_txt_usua_apro;
       p_rec_arlcop.no_soli        := null;
       p_rec_arlcop.ind_soli       := null;
       p_rec_arlcop.sec_oper       := null;
       p_rec_arlcop.fecha_ini      := trunc(pd_fecha_cont);
       p_rec_arlcop.cuota_inicial  := ln_val_ci;
       p_rec_arlcop.ind_lb         := null;
       p_rec_arlcop.judicial       := null;
       p_rec_arlcop.tipo_factu     := kc_tipo_factu;
       p_rec_arlcop.ind_factu      := kc_si;
       p_rec_arlcop.ind_utilizado  := null;
       p_rec_arlcop.f_aceptada     := null;
       p_rec_arlcop.f_anulada      := null;
       p_rec_arlcop.usr_anula      := null;
       p_rec_arlcop.ind_nu         := lc_ind_nu;
       p_rec_arlcop.nur_soli_cred_det := null;
       p_rec_arlcop.num_pedido_veh    := null;
       p_rec_arlcop.cod_filial        := lc_cod_filial;
       p_rec_arlcop.tipodocgen        := pc_tipo_doc_op;
       p_rec_arlcop.fecha_aut_ope     := trunc(ld_fec_aut_ope);
       p_rec_arlcop.fecha_cre_reg     := sysdate;
       begin
         select instr(val_para_car,pc_tipo_cred) 
         into   ln_tcred_mutuo 
         from   vve_cred_soli_para 
         where  cod_cred_soli_para = kc_tcred_prof_ope ; 
       exception
         when no_data_found then 
           ln_tcred_mutuo := 0;
           pc_ret_mens := 'Error al validar si tipo de crédito es mutuo o leasing';
           pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_num_soli);
       end;
       if ln_tcred_mutuo > 0 then  -- definido asi por backoffice (EFlores)
          p_rec_arlcop.num_prof_veh      := lc_num_prof_veh;
       else 
         p_rec_arlcop.num_prof_veh      := null;
       end if;
       
--       p_rec_arlcop.ind_ajuste_fecha  := null;

 /*      
       open cur_arlcop for
       select 
          lc_no_cia,
          ln_cod_oper,
          ln_ano,
          ln_mes,
          lc_grupo,
          lc_no_cliente,
          lc_modal_cred,
          null, -- tipo bien
          pd_fecha_cont,
          ln_tea,
          ln_tasa_igv,
          ln_tasa_isc,
          ln_valor_ori,
          ln_monto_gastos,
          ln_monto_fina,
          ln_int_per_gra,
          ln_tot_fina,
          ln_int_oper,
          ln_tot_igv,
          ln_tot_isc,
          lc_cod_mone,
          ln_tipo_cambio,
          ln_plazo,
          ln_nro_cuotas,
          ld_fec_vto_1ra_let,
          ln_frec_pago_dias,
          ln_dia_pago,
          lc_ind_tipo_cuo,
          lc_ind_per_gra,
          lc_ind_per_gra_cap,
          ln_tasa_gra,
          ln_fre_gra,
          null,
          lc_mon_cuo_ene,
          lc_mon_cuo_feb,
          lc_mon_cuo_mar,
          lc_mon_cuo_abr,
          lc_mon_cuo_may,
          lc_mon_cuo_jun,
          lc_mon_cuo_jul,
          lc_mon_cuo_ago,
          lc_mon_cuo_sep,
          lc_mon_cuo_oct,
          lc_mon_cuo_nov,
          lc_mon_cuo_dic,
          lc_cta_int_dife,
          lc_ingr_fina,
          lc_estado,
          pc_cod_usua_web, --lc_usuario,
          lc_usuario_aprb,
          null,
          null,
          ln_sec_oper,
          pd_fecha_ini,
          null,
          null,
          lc_judicial,
          null,
          null,
          null,
          null,
          null,
          null,
          lc_ind_nu,
          null,
          null,
          null,
          lc_cod_filial,
          lc_tipodocgen,
          ld_fec_aut_ope,
          trunc(sysdate),
          null,
          null --lc_ind_ajuste_fecha
       from dual;
        
       IF cur_arlcop IS NOT NULL THEN 
         fetch cur_arlcop into p_r_arlcop;
       END IF;
*/
       pc_ret_mens := 'se inserta en arlcop';
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SP_OBTENER_DATOS_OP',
                                          pc_cod_usua_web,
                                          'p_rec_arlcop.no_cia: '||p_rec_arlcop.no_cia||
                                          ', p_rec_arlcop.cod_oper: '||p_rec_arlcop.cod_oper,
                                          pc_ret_mens,
                                          pc_num_soli);
/*    ELSE 
      open cur_arlcop for
      select * from arlcop where cod_oper = ln_cod_oper and no_cia = pc_no_cia;
*/    END IF;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SP_OBTENER_DATOS_OP',
                                        pc_cod_usua_web,
                                        'Termino validacion 2',
                                        pc_ret_mens,
                                        pc_num_soli);


    EXCEPTION
      WHEN ve_error THEN
        pn_ret_esta := 1;
        pc_ret_mens := 'Error en obtener algún dato de la arlcop';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_num_soli);
      WHEN OTHERS THEN
        pn_ret_esta := -1;
        pc_ret_mens := substr('PKG_SWEB_CRED_LXC.SP_OBTENER_DATOS_OP: '||SQLERRM,1,500);    
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SP_OBTENER_DATOS_OP',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_num_soli);
  END sp_obtener_datos_Op;

  Function sf_obtener_nro_op(
  pc_no_cia         IN      arlcop.no_cia%TYPE,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) return NUMBER 
  AS
  ln_cod_oper   arlcop.cod_oper%TYPE;
  ve_error      Exception;
  Begin
    begin
      select num_corre_oper 
        into ln_cod_oper 
        from arlctp where no_cia = pc_no_cia;
        
        pn_ret_esta := 1;
     EXCEPTION
        WHEN ve_error THEN
            pn_ret_esta     := 0;
            pc_ret_mens := 'No se encontro numero de operacion a asignar';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                NULL);
        WHEN OTHERS THEN
          pn_ret_esta := -1;
          pc_ret_mens := 'SP_OBTENER_DATOS_OP:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              NULL);    
      end;
      begin  
       update arlctp set num_corre_oper = (to_number(num_corre_oper) + 1)
        where arlctp.no_cia = pc_no_cia;
      Exception
        When ve_error then
            pn_ret_esta     := 0;
            pc_ret_mens := 'Hubo un Problema en el momento de Actualizar Correlativos ..Consulte - II ';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SP_OBTENER_DATOS_OP',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                NULL);
        When OTHERS then
          pn_ret_esta := -1;
          pc_ret_mens := 'SP_OBTENER_DATOS_OP:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SP_OBTENER_DATOS_OP',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              NULL);    
      rollback;
      end;
      RETURN ln_cod_oper;
  end sf_obtener_nro_op;
  
  /* Crear letras */
  Procedure sp_crear_arlcml(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE, -- Nro de solicitud evaluado
    pn_cod_oper_ori   IN      arlcop.cod_oper%TYPE, -- nro_op original
    pn_cod_oper_ref   IN      arlcop.cod_oper%TYPE, -- nro_op del refinanciamiento/reprog.
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
    ) AS
    lc_no_cia                   arlcop.no_cia%TYPE;
    lc_cod_oper                 arlcop.cod_oper%TYPE;
    lc_no_letra                 arlcml.no_letra%TYPE;
    lc_situacion                arlctp.sit_pendiente%TYPE;
    lc_cod_plaza                arlcml.cod_plaza%TYPE;
    lc_grupo                    arlcop.grupo%TYPE;
    lc_no_cliente               arlcop.no_cliente%TYPE;
    lc_no_letra_bco             arlcml.no_letra_bco%TYPE;
    ld_f_generada               arlcop.fecha_ini%TYPE;
    ld_f_aceptada               arlcml.f_aceptada%TYPE;
    ld_f_vence                  vve_cred_simu_lede.fec_venc%TYPE;
    lc_moneda                   arlcop.moneda%TYPE;
    ln_tipo_cambio              arlcop.tipo_cambio%TYPE;
    ln_nro_sec                  arlcml.nro_sec%TYPE;
    ln_monto_inicial            vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 2;
    ln_cuota                    vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 5;
    ln_amortizacion             vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 3;
    ln_intereses                vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 4;
    ln_igv                      vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 13;
    ln_isc                      arlcml.isc%TYPE;
    lc_ind_cuota_ext            arlcml.ind_cuota_ext%TYPE;
    lc_ind_planilla             arlcml.ind_planilla%TYPE;
    lc_observaciones            arlcml.observaciones%TYPE;
    lc_cta_bancaria_garantia    arlcml.cta_bancaria_garantia%TYPE;
    lc_banco                    arlcml.banco%TYPE;
    lc_tc                       arlcml.tc%TYPE;
    lc_sec_oper                 arlcml.sec_oper%TYPE;
    ln_saldo                    vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 2;
    lc_est_vcto                 arlcml.est_vcto%TYPE;
    ln_saldo_igv                vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 13;
    ln_saldo_isc                arlcml.saldo_isc%TYPE;
    ln_saldo_intereses          vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 4;
    ln_saldo_amortizacion       vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 5;
    ld_fecha_cancel             arlcml.fecha_cancel%TYPE;
    lc_cod_relacion             arlcml.cod_relacion%TYPE;
    lc_indi_f                   arlcml.indi_f%TYPE;
    lc_let_dive                 arlcml.let_dive%TYPE;
    lc_ind_fact_lb              arlcml.ind_fact_lb%TYPE;
    ln_igv_lb                   arlcml.igv_lb%TYPE;
    ln_isc_lb                   arlcml.isc_lb%TYPE;
    lc_bandera                  arlcml.bandera%TYPE;
    lc_tipo_factu               arlcml.tipo_factu%TYPE;
    lc_indi_f_ref               arlcml.indi_f_ref%TYPE;
    lc_indi_nc_int              arlcml.indi_nc_int%TYPE;
    ld_f_anulada                arlcml.f_anulada%TYPE;
    lc_ind_cap                  arlcml.ind_cap%TYPE;
    lc_ind_nu                   arlcop.ind_nu%TYPE;
    lc_tb                       arlcml.tb%TYPE;
    lc_ind_cobr_dd              arlcml.ind_cobr_dd%TYPE;
    ln_val_seguro_veh           vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 8 Valor/1.18;
    lc_ind_corto_largo_plazo    arlcml.ind_corto_largo_plazo%TYPE;
    lc_ind_periodo_gracia       arlcop.ind_per_gra%TYPE;
    ln_saldo_seguro_veh         vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 8;
    lc_nur_conta_sap            arlcml.nur_conta_sap%TYPE;
    ln_igv_seguro               vve_cred_simu_lede.val_mon_conc%TYPE; -- cod_conc_col = 8 Valor/1.18*.18;
    ln_ano_conta_sap            arlcml.ano_conta_sap%TYPE;
    --
    ln_no_cuotas                arlcop.no_cuotas%TYPE;
    ln_tasa_igv                 arlcop.mon_tasa_igv%TYPE;
    lc_ind_per_gra              arlcop.ind_per_gra%TYPE;
    lc_cod_simu                 vve_cred_simu.cod_simu%TYPE;
    lc_per_sol                  vve_cred_simu.cod_per_cred_sol%TYPE;
    ln_can_dias_per_gra         vve_cred_simu.val_dias_per_gra%TYPE;
    ln_val_prima_seg            vve_cred_simu.val_prima_seg%TYPE;
    ln_can_let_per_gra          vve_cred_simu.can_let_per_gra%TYPE;
    ln_num_corre_let            arlcnl.correlativo%TYPE;
    ln_ano                      arlcop.ano%TYPE;
    ln_mes                      arlcop.mes%TYPE;
    ld_fecha_ini                arlcop.fecha_ini%TYPE;
    ln_val_mon_fin              vve_cred_simu.val_mon_fin%type; 
    ln_val_int_per_gra          vve_cred_simu.val_int_per_gra%type;
    kn_conc_sald_inic           vve_cred_maes_conc_letr.cod_conc_col%type := 2;
    kn_conc_capi                vve_cred_maes_conc_letr.cod_conc_col%type := 3;
    kn_conc_inte                vve_cred_maes_conc_letr.cod_conc_col%type := 4;
    kn_conc_igv                 vve_cred_maes_conc_letr.cod_conc_col%type := 13;
    kn_conc_segu                vve_cred_maes_conc_letr.cod_conc_col%type := 8;
    kn_conc_cuot                vve_cred_maes_conc_letr.cod_conc_col%type := 5;

    c  arlcop%ROWTYPE;
    l  vve_cred_simu_lede%ROWTYPE;
    
    cursor c_arlcop is 
      select no_cia, cod_oper,grupo,no_cliente,fecha_ini,moneda,tipo_cambio,ind_nu,ind_per_gra,no_cuotas,mon_tasa_igv,ano,mes 
      from   arlcop 
      where  no_cia = pc_no_cia and cod_oper = pn_cod_oper_ori;
    
    cursor c_letras_simu(p_cod_simu VARCHAR2,p_nro_letra NUMBER) is
      select val_mon_conc, fec_venc, cod_conc_col 
      from   vve_cred_simu_lede 
      where  cod_simu = p_cod_simu and cod_nume_letr = p_nro_letra;
    
  Begin
  pc_ret_mens := '1. Inicia sp_crear_arlcml, pn_cod_oper_ori:'||pn_cod_oper_ori;
  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'sp_crear_arlcml',
                                      pc_cod_usua_web,
                                      pn_cod_oper_ori,
                                      pc_ret_mens,
                                      pc_ret_mens); 
                                              
    select (CASE WHEN pn_cod_oper_ref IS NULL THEN cod_oper 
                 ELSE pn_cod_oper_ref 
             END ) co_oper,
           no_cia, grupo,no_cliente,fecha_ini,fecha_ini,moneda,tipo_cambio,
           ind_nu,ind_per_gra,no_cuotas,mon_tasa_igv,ano,mes 
    into   lc_cod_oper,lc_no_cia,lc_grupo,lc_no_cliente,ld_fecha_ini,ld_f_generada,lc_moneda,ln_tipo_cambio,
           lc_ind_nu,lc_ind_per_gra,ln_no_cuotas,ln_tasa_igv,ln_ano,ln_mes
    from   arlcop 
    where  no_cia = pc_no_cia and cod_oper = pn_cod_oper_ori;

    pc_ret_mens := '2. luego del select arlcop, lc_cod_oper:'||lc_cod_oper;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'sp_crear_arlcml',
                                      pc_cod_usua_web,
                                      'arlcop.lc_ind_per_gra: '||lc_ind_per_gra,
                                      pc_ret_mens,
                                      pc_ret_mens); 
  
/*    
    for c in c_arlcop loop
      lc_no_cia               := c.no_cia;
      IF pn_cod_oper_ref IS NULL THEN 
        lc_cod_oper           := c.cod_oper;
      ELSE
        lc_cod_oper           := pn_cod_oper_ref;
      END IF;
      
      lc_grupo                := c.grupo;
      lc_no_cliente           := c.no_cliente;
      ld_f_generada           := c.fecha_ini;
      lc_moneda               := c.moneda;
      ln_tipo_cambio          := c.tipo_cambio;
      lc_ind_nu               := c.ind_nu;
      ln_no_cuotas            := c.no_cuotas;
      lc_ind_per_gra          := c.ind_per_gra;
      ln_tasa_igv             := c.mon_tasa_igv;
      ln_ano                  := c.ano;
      ln_mes                  := c.mes;
      ld_fecha_ini            := c.fecha_ini;
    end loop;
*/
    
    lc_cod_plaza             := null;
    lc_no_letra_bco          := null;
    ld_f_aceptada            := null;
    lc_ind_cuota_ext         := null;
    lc_cta_bancaria_garantia := null;
    lc_banco                 := null;
    lc_tc                    := null;
    lc_sec_oper              := null;
    lc_est_vcto              := null;
    ld_fecha_cancel          := null;
    lc_cod_relacion          := null;
    lc_indi_f                := null;
    lc_let_dive              := null;
    lc_ind_fact_lb           := null;
    ln_igv_lb                := null;
    ln_isc_lb                := null;
    lc_bandera               := null;
    lc_tipo_factu            := null;
    lc_indi_f_ref            := null;
    lc_indi_nc_int           := null;
    ld_f_anulada             := null;
    lc_ind_cap               := null;
    lc_tb                    := null;
    lc_ind_cobr_dd           := null;
    lc_ind_corto_largo_plazo := null;
    lc_nur_conta_sap         := null;
    ln_ano_conta_sap         := null;
    
    ln_isc           := 0;
    lc_ind_planilla  := 'N';
    lc_observaciones := 'NUEVAS LETRAS';
    ln_saldo_isc     := 0;

    begin
      select sit_pendiente 
      into    lc_situacion 
      from    arlctp
      where  arlctp.no_cia = pc_no_cia;
      
      pc_ret_mens := '3.1. sit_pendiente:'||lc_situacion;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'sp_crear_arlcml',
                                          pc_cod_usua_web,
                                          '3.1. sit_pendiente',
                                          pc_ret_mens,
                                          pc_ret_mens); 
    exception
      when no_data_found then 
        pc_ret_mens := '3.2. sit_pendiente no existe';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Error 3.2. sit_pendiente no existe',
                                            pc_ret_mens,
                                            pc_ret_mens); 
    end;
    
    begin
      select cod_simu,cod_per_cred_sol,val_dias_per_gra,can_let_per_gra,val_prima_seg,
             val_mon_fin, val_int_per_gra
      into   lc_cod_simu, lc_per_sol, ln_can_dias_per_gra,ln_can_let_per_gra,ln_val_prima_seg,
             ln_val_mon_fin, ln_val_int_per_gra 
      from   vve_cred_simu 
      where  cod_soli_cred = pc_num_soli 
      and    ind_inactivo = 'N';
      
      pc_ret_mens := '4.1. select vve_cred_simu lc_cod_simu:'||lc_cod_simu;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'sp_crear_arlcml',
                                          pc_cod_usua_web,
                                          '4.1. select vve_cred_simu lc_cod_simu:'||lc_cod_simu,
                                          pc_ret_mens,
                                          pc_ret_mens); 
    exception 
      when others then 
        pc_ret_mens := '4.2. select vve_cred_simu';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Error 4.2. select vve_cred_simu',
                                            pc_ret_mens,
                                            pc_ret_mens); 
    end;
    
    --  ln_saldo_seguro_veh := ln_val_prima_seg/ln_no_cuotas;
    
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcml',
                                        pc_cod_usua_web,
                                        'Numero de cuotas = ' || ln_no_cuotas,
                                        pc_ret_mens,
                                        pc_ret_mens); 
    
    -- seteando nro letra (lc_no_letra)
      Begin
        select correlativo
        into   ln_num_corre_let 
        from   arlcnl
        where  no_cia  = pc_no_cia 
        and    ano      = ln_ano 
        and    mes      = ln_mes;
        
        pc_ret_mens := '5. select correlativo.arlcnl, ln_num_corre_let:'||ln_num_corre_let;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
                    
        update arlcnl
        set    correlativo  = correlativo+1
        where  no_cia      = pc_no_cia 
        and    ano      = ln_ano 
        and    mes      = ln_mes;
        
        pc_ret_mens := '6. update correlativo.arlcnl';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
      Exception
      When no_data_found then
          ln_num_corre_let:=1;
          insert into arlcnl values (pc_no_cia,ln_ano,ln_mes,2);
    End;
                                              
    for i in 1 .. ln_no_cuotas loop
      --***
      begin
        select to_char(ld_fecha_ini,'YYMM')||lpad(ln_num_corre_let,3,'0')||lpad(i,2,'0')||lpad(ln_no_cuotas,2,'0') 
        into   lc_no_letra 
        from dual;
        
        pc_ret_mens := '7. generando nro de letra lc_no_letra:'||lc_no_letra;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
      end;
      ln_nro_sec := i;
    
     -- seteando los montos del cronograma por letra
      for l in c_letras_simu(lc_cod_simu,i) loop
        if (l.cod_conc_col = kn_conc_sald_inic) then  -- saldo inicial kn_conc_sald_inic = 2
          ln_monto_inicial := l.val_mon_conc;
          ld_f_vence       := l.fec_venc;
        end if;
        if (l.cod_conc_col = kn_conc_capi) then -- capital kn_conc_capi = 3
          ln_amortizacion       := l.val_mon_conc;
          ln_saldo_amortizacion := ln_amortizacion;
        end if;
        if (l.cod_conc_col = kn_conc_inte) then -- intereses del capital  kn_conc_inte = 4
          ln_intereses       := l.val_mon_conc;
          ln_saldo_intereses := ln_intereses;
        end if;
        if (l.cod_conc_col = kn_conc_igv) then -- igv del interes capital kn_conc_igv = 13
          ln_igv       := l.val_mon_conc;
          ln_saldo_igv := ln_igv;
        end if;
        if (l.cod_conc_col = kn_conc_segu) then -- gastos por seguro (prima +igv) kn_conc_segu = 8 
          ln_saldo_seguro_veh := l.val_mon_conc;
          ln_val_seguro_veh   := ln_saldo_seguro_veh/(1+ln_tasa_igv);
          ln_igv_seguro       := ln_val_seguro_veh*ln_tasa_igv;
        end if;
        if (l.cod_conc_col = kn_conc_cuot) then -- monto de la cuota o letra kn_conc_cuot = 5
          ln_cuota := l.val_mon_conc;
          ln_saldo := ln_cuota;
        end if;
      end loop;
      
      pc_ret_mens := '8. obteniendo montos x lc_no_letra:'||lc_no_letra||', ln_amortizacion:'||to_char(ln_amortizacion,'999999999.99');
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'sp_crear_arlcml',
                                          pc_cod_usua_web,
                                          'Consulta '||pc_ret_mens,
                                          pc_ret_mens,
                                          pc_ret_mens);
                                          
      -- Seteando el indicador de Periodo de gracia
      if (i<= ln_can_let_per_gra and ln_can_let_per_gra is not null) then 
        pc_ret_mens := '9.0. existe periodo de gracia';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
                                            
        lc_ind_periodo_gracia := lc_ind_per_gra;
        --ln_amortizacion       := ln_intereses;
        --ln_intereses          := 0;
        --ln_igv                := 0;
        lc_ind_periodo_gracia := 'S';
        
        pc_ret_mens := '9.1. existe periodo de gracia ln_amortizacion:'||to_char(ln_amortizacion,'99999999.99');
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
        /*if i = 1 then 
           ln_saldo_amortizacion := ln_val_mon_fin + ln_val_int_per_gra;
        else 
        */  
      else
        lc_ind_periodo_gracia := null;
        pc_ret_mens := '9.2. NO existe periodo de gracia';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sp_crear_arlcml',
                                            pc_cod_usua_web,
                                            'Consulta '||pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
      end if;
      
      -- Insertando en la tabla arlcml, letra por letra
      insert into arlcml 
      values (  lc_no_cia,
                lc_cod_oper,
                lc_no_letra,
                lc_situacion,
                lc_cod_plaza,
                lc_grupo,
                lc_no_cliente,
                lc_no_letra_bco,
                ld_f_generada,
                ld_f_aceptada,
                ld_f_vence,
                lc_moneda,
                ln_tipo_cambio,
                ln_nro_sec,
                ln_monto_inicial,
                ln_cuota,
                ln_amortizacion,
                ln_intereses,
                ln_igv,
                ln_isc,
                lc_ind_cuota_ext,
                lc_ind_planilla,
                lc_observaciones,
                lc_cta_bancaria_garantia,
                lc_banco,
                lc_tc,
                lc_sec_oper,
                ln_saldo ,
                lc_est_vcto,
                ln_saldo_igv,
                ln_saldo_isc,
                ln_saldo_intereses,
                ln_saldo_amortizacion,
                ld_fecha_cancel,
                lc_cod_relacion,
                lc_indi_f,
                lc_let_dive,
                lc_ind_fact_lb,
                ln_igv_lb,
                ln_isc_lb,
                lc_bandera,
                lc_tipo_factu,
                lc_indi_f_ref,
                lc_indi_nc_int,
                ld_f_anulada,
                lc_ind_cap,
                lc_ind_nu,
                lc_tb,
                lc_ind_cobr_dd,
                ln_val_seguro_veh,
                lc_ind_corto_largo_plazo,
                lc_ind_periodo_gracia,
                ln_saldo_seguro_veh,
                lc_nur_conta_sap,
                ln_igv_seguro,
                ln_ano_conta_sap
                );
    end loop;
  --  commit;
  end sp_crear_arlcml;
  
  Procedure sp_crear_arccmd(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
  pc_moneda         IN      arlcop.moneda%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  pc_grupo          IN      arlcop.grupo%TYPE,
  pn_tipo_cambio    IN      arlcop.tipo_cambio%TYPE,
  pn_porc_igv       IN      arlcop.mon_tasa_igv%TYPE,
  p_ret_cur_fact    IN OUT  SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  )
  AS
  lb_existe_docs    boolean := false;
  ln_igv       number;
  ln_subtotal     number;
  lc_no_cta     arccmd.no_cta%type;
  lc_no_docu_sap  arccmd.no_docu_sap%type;
  lc_cod_sunat    arcctd.cod_sunat%type;
  ln_clave       ARCGIV.clave%type := 11;
  kc_ctacble_fs_fr  arccmd.no_cta%TYPE := '012001003000000';
  kc_ctacble_bs_br  arccmd.no_cta%TYPE := '012001004000000';
  kc_fec_cod_sunat  date := to_date('04/05/2009','dd/mm/yyyy');
  v_verifica         number(1);
  c_factura         PKG_SWEB_CRED_LXC.t_fact_x_op;
  c_fact            PKG_SWEB_CRED_LXC.t_fact_x_op;
  ln_porcentaje     arcgiv.porcentaje%type;
  lb_tipo_doc_ok    BOOLEAN := FALSE;
  lb_existe_no_docu BOOLEAN := FALSE;
  p_ret_cur_fact_aux t_table_reclet;
  i number(5);
  Begin
    if p_ret_cur_fact is not null then
      --p_ret_cur_fact_aux := p_ret_cur_fact;
      i:=0;
      LOOP
        IF p_ret_cur_fact%ISOPEN THEN
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                  'sp_crear_arccmd',
                                  pc_cod_usua_web,
                                  '1 sp_crear_arccmd p_ret_cur_fact cursor abierto',
                                  '1 sp_crear_arccmd p_ret_cur_fact cursor abierto',
                                  '1 sp_crear_arccmd p_ret_cur_fact cursor abierto');    
        else 
          --open p_ret_cur_fact;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                  'sp_crear_arccmd',
                                  pc_cod_usua_web,
                                  '2 sp_crear_arccmd p_ret_cur_fact cerrado',
                                  '2 sp_crear_arccmd p_ret_cur_fact cerrado',
                                  '2 sp_crear_arccmd p_ret_cur_fact cerrado');  
        END IF;
            
/*        FETCH p_ret_cur_fact INTO lr_fact; --lr_fact  PKG_SWEB_CRED_LXC.t_fact_x_op;
        EXIT WHEN p_ret_cur_fact%NOTFOUND;
*/         
          
--      loop 
        FETCH p_ret_cur_fact INTO c_fact ;
        --c_fact := c_factura;
        EXIT WHEN p_ret_cur_fact%NOTFOUND;
        i:=i+1;

        lb_tipo_doc_ok := sf_valida_tipo_docu(pc_no_cia,pc_modal_cred,pc_no_cliente,pc_moneda,c_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
        lb_existe_no_docu := sf_valida_no_docu(pc_no_cia,pc_modal_cred,c_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
        if lb_tipo_doc_ok then 
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arccmd',
                                              pc_cod_usua_web,
                                              '3.1 sp_crear_arccmd lb_tipo_doc_ok = true',
                                              '3.1 sp_crear_arccmd lb_tipo_doc_ok = true',
                                              '3.1 sp_crear_arccmd lb_tipo_doc_ok = true');
         end if;
         
         if lb_existe_no_docu then 
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arccmd',
                                              pc_cod_usua_web,
                                              '3.2 sp_crear_arccmd lb_existe_no_docu = false',
                                              '3.2 sp_crear_arccmd lb_existe_no_docu = false',
                                              '3.2 sp_crear_arccmd lb_existe_no_docu = false');
         end if;
         
        if (lb_tipo_doc_ok and not(lb_existe_no_docu)) then 
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arccmd',
                                              pc_cod_usua_web,
                                              '4 sp_crear_arccmd entro if (lb_tipo_doc_ok and not lb_existe_no_docu)',
                                              '4 sp_crear_arccmd entro if (lb_tipo_doc_ok and not lb_existe_no_docu)',
                                              '4 sp_crear_arccmd entro if (lb_tipo_doc_ok and not lb_existe_no_docu)');
          -- Modalidad Postventa y Mutuos
          if c_fact.tipo_docu in ('FR','BR','FS','BS','MU') and pc_modal_cred in ('P','M') THEN    
            -- Calculo igv
            if c_fact.tipo_docu in ('FR','BR','FS','BS') then
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arccmd',
                                              pc_cod_usua_web,
                                              '5.1 sp_crear_arccmd entro al if de docs post-venta',
                                              '5.1 sp_crear_arccmd entro al if de docs post-venta',
                                              '5.1 sp_crear_arccmd entro al if de docs post-venta');
              ln_subtotal  := c_fact.monto / (1+pn_porc_igv);
              ln_igv       := c_fact.monto - ln_subtotal;
            else
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arccmd',
                                              pc_cod_usua_web,
                                              '5.2 sp_crear_arccmd entro al if de docs mutuos',
                                              '5.2 sp_crear_arccmd entro al if de docs mutuos',
                                              '5.2 sp_crear_arccmd entro al if de docs mutuos');
            ln_subtotal := 0;
            ln_igv := 0;
            end if;
            -- Validar si existe documento para caso PV 
            --lb_existe_docs := sf_verifica_existe_doc(pc_no_cia,pc_cod_usua_web,c_fact,pn_ret_esta,pc_ret_mens);


            if not(lb_existe_no_docu) then   
              null; -- si no existe no hace nada porque lo insertará, continua el flujo. 
              --Si existe el procedimiento sp_verifica_existe_doc sale con el Exception de sf_verifica_existe_doc.    
            end if;
            -- Para el caso de Mutuos obtiene la Cuenta Contable
            if c_fact.tipo_docu = 'MU' then
              Begin
                select nivel_1_mutuo||nivel_2_mutuo||nivel_3_mutuo||nivel_4_mutuo||nivel_5_mutuo
                into   lc_no_cta
                from   arlctp
                where no_cia = pc_no_cia;
              Exception 
                When no_data_found then
                  pn_ret_esta := -1;
                  pc_ret_mens := 'No existe el tipo doc'||sqlerrm;
                  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Error en Cta Cble',
                                                      pc_ret_mens,
                                                      pc_ret_mens);
                When others then 
                  pn_ret_esta := -1;
                  pc_ret_mens := 'Error al buscar Tipo Doc. '||sqlerrm;
                  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Error en Cta Cble',
                                                      pc_ret_mens,
                                                      pc_ret_mens);
              End;
            -- Cuando no es Mutuo ni Post Venta y son Documentos tipo Factura
            elsif c_fact.tipo_docu in ('FR','FS') then
              lc_no_cta := kc_ctacble_fs_fr;
            -- Cuando no es Mutuo ni Post Venta y son Documentos tipo Boleta
            elsif c_fact.tipo_docu in ('BR','BS') then
              lc_no_cta := kc_ctacble_bs_br;
            End if;
            if lc_no_cta = '' or lc_no_cta is null then
              pn_ret_esta := -1;
              pc_ret_mens := 'El documento de referencia no tiene cuenta contable';
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Error en Cta Cble:'||pc_ret_mens,
                                                      pc_ret_mens,
                                                      pc_ret_mens);
            End if;
      
            if c_fact.fecha < kc_fec_cod_sunat then
              begin
                select  cod_sunat
                into    lc_cod_sunat
                from    arcctd
                where    no_cia = pc_no_cia 
                and     tipo   = c_fact.tipo_docu;
                
              pc_ret_mens := 'if c_fact.fecha < kc_fec_cod_sunat';
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Consulta lc_cod_sunat:'||lc_cod_sunat,
                                                      pc_ret_mens,
                                                      pc_ret_mens);
              Exception
                When others then
                  lc_cod_sunat := null;
                  pc_ret_mens := 'if c_fact.fecha < kc_fec_cod_sunat';
                  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                          'sp_crear_arccmd',
                                                          pc_cod_usua_web,
                                                          'Consulta lc_cod_sunat = null',
                                                          pc_ret_mens,
                                                          pc_ret_mens);
              End;
                
              lc_no_docu_sap := lpad(lc_cod_sunat,2,'0')||'-'||lpad(substr(c_fact.no_docu,0,3),5,'0')||'-'||lpad(substr(c_fact.no_docu,5,7),7,'0');
              pc_ret_mens := 'if c_fact.fecha < kc_fec_cod_sunat';
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Consulta lc_no_docu_sap:'||lc_no_docu_sap,
                                                      pc_ret_mens,
                                                      pc_ret_mens);
            else
              lc_no_docu_sap := c_fact.no_docu;
              pc_ret_mens := 'else del if c_fact.fecha < kc_fec_cod_sunat';
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Consulta else lc_no_docu_sap:'||lc_no_docu_sap,
                                                      pc_ret_mens,
                                                      pc_ret_mens);
            End if;
            
            p_ret_cur_fact_aux(i).cod_oper   := c_fact.cod_oper;
            p_ret_cur_fact_aux(i).grupo      := c_fact.grupo;
            p_ret_cur_fact_aux(i).no_cliente := c_fact.no_cliente;
            p_ret_cur_fact_aux(i).tipo_docu  := c_fact.tipo_docu;
            p_ret_cur_fact_aux(i).igv        := c_fact.igv;
            p_ret_cur_fact_aux(i).interes    := c_fact.interes;
            p_ret_cur_fact_aux(i).no_docu    := c_fact.no_docu;
            p_ret_cur_fact_aux(i).saldo_anterior := c_fact.saldo_anterior;
            p_ret_cur_fact_aux(i).monto      := c_fact.monto;
            p_ret_cur_fact_aux(i).fecha      := c_fact.fecha;
            p_ret_cur_fact_aux(i).cod_ref    := c_fact.cod_ref;
            p_ret_cur_fact_aux(i).est_ref    := c_fact.est_ref;

            begin    
            insert into arccmd(
                no_cia,  
                tipo_doc,
                no_docu,
                grupo,
                no_cliente,
                fecha,
                clave, 
                moneda,
                tipo_cambio,
                m_original,
                descuento,
                saldo,
                subtotal,
                total_db,
                total_cr,
                impuestos,
                isc,
                igv,
                estado,
                tipo_pago,
                detalle,
                no_cta,
                user_gen,
                fecha_digitacion,
                ano,
                mes,
                no_docu_sap
              )values(
                pc_no_cia,
                c_fact.tipo_docu,
                c_fact.no_docu,
                pc_grupo,
                pc_no_cliente,
                c_fact.fecha,
                ln_clave,
                c_fact.moneda,
                pn_tipo_cambio,
                c_fact.monto,
                0,
                0,
                ln_subtotal,
                c_fact.monto,
                c_fact.monto,
                ln_igv,
                0,
                ln_igv,
                'D',
                'C',
                'Generado automaticamente por Lxc',
                lc_no_cta,
                pc_cod_usua_web,
                c_fact.fecha,
                to_char(c_fact.fecha,'RRRR'),
                to_char(c_fact.fecha,'MM'),
                lc_no_docu_sap
              ); 
              commit;
              Exception
                When others then
                  pn_ret_esta := 0;
                  pc_ret_mens := 'Error al crear regsitro de cxc. '||sqlerrm;
                  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                      'sp_crear_arccmd',
                                                      pc_cod_usua_web,
                                                      'Error al crear arccmd:'||pc_ret_mens,
                                                      pc_ret_mens,
                                                      pc_ret_mens);
              end;
            end if;
        end if;
      end loop;
     close p_ret_cur_fact;
     open p_ret_cur_fact for select * from table (p_ret_cur_fact_aux);
    end if;
  end sp_crear_arccmd;
  
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
    ) AS
  
    lc_modal_cred         arlcop.modal_cred%TYPE;
    ln_mon_tasa_igv       arlcop.mon_tasa_igv%TYPE;
    lc_no_cia             arlcop.no_cia%TYPE;
    lc_cod_oper           arlcop.cod_oper%TYPE;
    lc_grupo              arlcop.grupo%TYPE;
    lc_no_cliente         arlcop.no_cliente%TYPE;
    lc_tipo_docu          arlcrd.tipo_docu%TYPE;
    lc_no_docu            arlcrd.no_docu%TYPE;
    ln_saldo_anterior     arlcrd.saldo_anterior%TYPE;
    ln_monto              arlcrd.monto%TYPE;
    lc_moneda             arlcrd.moneda%TYPE;
    ln_tipo_cambio        arlcop.tipo_cambio%TYPE;
    ld_fecha              arlcrd.fecha%TYPE;
    lc_cod_ref            arlcrd.cod_ref%TYPE := null;
    lc_est_ref            arlcrd.est_ref%TYPE := null;
    lc_grupo_refe         arlcop.grupo%TYPE := null;
    lc_no_cliente_refe    arlcrd.no_cliente_refe%TYPE := null;
    lr_fact               PKG_SWEB_CRED_LXC.t_fact_x_op;
    err_existe            Exception;
    c                     arlcop%ROWTYPE;
    lb_tipo_doc_ok        BOOLEAN := FALSE;
    lb_existe_no_docu     BOOLEAN := FALSE;
    
    lr_reclet             PKG_SWEB_CRED_LXC.t_table_reclet;
    lref_fact             SYS_REFCURSOR;
    valida                VARCHAR2(10);
/*    
  cursor c_arlcop is 
  select modal_cred,moneda,no_cliente,grupo,tipo_cambio,mon_tasa_igv,cod_oper  
  from   arlcop 
  where  no_cia = pc_no_cia 
  and   ((cod_oper = pc_cod_oper_ref and pc_cod_oper_ref is not null) or
         (cod_oper = pc_cod_oper_ori and pc_cod_oper_ref is null));
*/
  Begin
    
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '0 valores pc_cod_oper_ori: '||pc_cod_oper_ori||', pc_cod_oper_ref:'||pc_cod_oper_ref, 
                                    'revisando parametros de entrada',
                                    'revisando parametros de entrada');
    
    select modal_cred,moneda,no_cliente,grupo,tipo_cambio,mon_tasa_igv,cod_oper  
    into   lc_modal_cred,lc_moneda,lc_no_cliente,lc_grupo,ln_tipo_cambio,ln_mon_tasa_igv,lc_cod_oper
    from   arlcop 
    where  no_cia = pc_no_cia 
    and   ((cod_oper = pc_cod_oper_ref and pc_cod_oper_ref is not null) or
           (cod_oper = pc_cod_oper_ori and pc_cod_oper_ref is null));
    
    IF p_ret_cur_fact IS NOT NULL THEN 
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '1 p_ret_cur_fact is not null and lc_modal_cred:'||lc_modal_cred,
                                    'Entrando al if p_ret_cur_fact not null',
                                    'Entrando al if p_ret_cur_fact not null');  
/*        for c_op in c_arlcop loop
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '2 p_ret_cur_fact is not null y for c_op',
                                    'for c_op in c_arlcop',
                                    'for c_op in c_arlcop');  
                                    
          lc_modal_cred := c.modal_cred;
          lc_moneda     := c.moneda;
          lc_no_cliente := c.no_cliente;
          lc_grupo      := c.grupo;
          ln_tipo_cambio:= c.tipo_cambio;
          ln_mon_tasa_igv:= c.mon_tasa_igv;
          
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '3 Seteando en for c_op '||c.cod_oper||', lc_no_cliente:'||lc_no_cliente ,
                                    'despues de setear cursor c_op',
                                    'for c_op in c_arlcop');
        end loop;
*/
        /*Cuando se trata de un Post-Venta o Mutuo, se inserta en arccmd*/
        IF lc_modal_cred IN ('P','M') THEN
          -- Se inserta en la tabla arccmd (relación entre compañia, cliente y documento)
          pc_ret_mens := pc_no_cia||'-'||lc_no_cliente||'-'||lc_moneda||'-'||lc_modal_cred||
                         '-'||lc_grupo||'-'||ln_tipo_cambio||'-'||ln_mon_tasa_igv;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '2 Entro a if modal_cred in (P,M)'||pc_ret_mens,
                                    pc_ret_mens,
                                    pc_ret_mens);
          sp_crear_arccmd(pc_no_cia,lc_no_cliente,lc_moneda,lc_modal_cred,lc_grupo,ln_tipo_cambio,
                          ln_mon_tasa_igv,p_ret_cur_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
        END IF;
        
        LOOP
          
          IF p_ret_cur_fact%ISOPEN THEN
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '4 p_ret_cur_fact cursor abierto',
                                    '4 p_ret_cur_fact cursor abierto',
                                    '4 p_ret_cur_fact cursor abierto');    
          else 
            --open p_ret_cur_fact;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                    'sp_crear_arlcrd',
                                    pc_cod_usua_web,
                                    '5 p_ret_cur_fact cerrado',
                                    '5 p_ret_cur_fact cerrado',
                                    '5 p_ret_cur_fact cerrado');  
          END IF;
          
          FETCH p_ret_cur_fact INTO lr_fact; --lr_fact  PKG_SWEB_CRED_LXC.t_fact_x_op;
          EXIT WHEN p_ret_cur_fact%NOTFOUND;
         
          lb_tipo_doc_ok    := sf_valida_tipo_docu(pc_no_cia,lc_modal_cred,lc_no_cliente,lc_moneda,lr_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
          lb_existe_no_docu := sf_valida_no_docu(pc_no_cia,lc_modal_cred,lr_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
          --lb_existe_no_docu := sf_valida_no_docu(pc_no_cia,lc_modal_cred,p_cur_fact(i),pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
          if lb_tipo_doc_ok then 
            pc_ret_mens := '5.0.1.lb_tipo_doc_ok is TRUE';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'consulta: '||to_char(lr_fact.saldo_anterior,'99999999999.99'),
                                                pc_ret_mens,
                                                pc_ret_mens);
          end if;
          if lb_existe_no_docu then 
            pc_ret_mens := '5.0.2.lb_existe_no_docu is TRUE';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'consulta: '||to_char(lr_fact.saldo_anterior,'99999999999.99'),
                                                pc_ret_mens,
                                                pc_ret_mens);
          end if; 
           
          if (lb_tipo_doc_ok and lb_existe_no_docu) then 
            lc_no_cia       := pc_no_cia;
            lc_no_cliente   := pc_no_cliente;
            lc_tipo_docu    := lr_fact.tipo_docu;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'lb_tipo_doc_ok and lb_existe_no_docu: '||pc_no_cia||','||lc_no_cliente,
                                                '5.1 sp_crear_arlcrd',
                                                '5.1 sp_crear_arlcrd');
            if (pc_cod_oper_ref is null) then 
              lc_cod_oper     := pc_cod_oper_ori;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'pc_cod_oper_ref is null lc_cod_oper: '||lc_cod_oper,
                                                '5.2 sp_crear_arlcrd',
                                                '5.2 sp_crear_arlcrd');
              
            else 
              lc_cod_oper     := pc_cod_oper_ref;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'pc_cod_oper_ref is not null lc_cod_oper: '||lc_cod_oper,
                                                '5.3 sp_crear_arlcrd',
                                                '5.3 sp_crear_arlcrd');
            end if;
            
            ln_mon_tasa_igv := sf_obtener_tasa_igv(pc_no_cia,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'ln_mon_tasa_igv: '||to_char(ln_mon_tasa_igv,'999999.99'),
                                                '5.4 sp_crear_arlcrd',
                                                '5.4 sp_crear_arlcrd');
                                                    
            -- seteo valores del excel
            lc_no_docu          := lr_fact.no_docu;
            lc_tipo_docu        := lr_fact.tipo_docu;
            ln_saldo_anterior   := lr_fact.monto;
            ln_monto            := lr_fact.monto;
            lc_moneda           := lr_fact.moneda;
            ld_fecha            := lr_fact.fecha;
            lc_cod_ref          := null;
            lc_est_ref          := lr_fact.est_ref;
            lc_grupo_refe       := lc_grupo;
            lc_no_cliente_refe  := lc_no_cliente;
            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'sp_crear_arlcrd',
                                                pc_cod_usua_web,
                                                'lc_no_docu:'||lc_no_docu||',ln_saldo_anterior:'||to_char(ln_saldo_anterior,'9999999.99')||
                                                ',ln_monto:'||to_char(ln_monto,'999999999.99')||',ld_fecha:'||to_char(ld_fecha,'dd/mm/yyyy'),
                                                '5.4 sp_crear_arlcrd',
                                                '5.4 sp_crear_arlcrd');
    
            BEGIN
            insert into arlcrd(
                                no_cia,
                                cod_oper,
                                grupo,
                                no_cliente,
                                tipo_docu,
                                no_docu,
                                saldo_anterior,
                                monto,
                                moneda,
                                tipo_cambio,
                                fecha,
                                cod_ref,
                                est_ref,
                                grupo_refe,
                                no_cliente_refe) 
            values (
                    lc_no_cia,
                    lc_cod_oper,
                    lc_grupo,
                    lc_no_cliente,
                    lc_tipo_docu,
                    lc_no_docu,
                    ln_saldo_anterior,
                    ln_monto,
                    lc_moneda,
                    ln_tipo_cambio,
                    ld_fecha,
                    lc_cod_ref,
                    lc_est_ref,
                    lc_grupo_refe,
                    lc_no_cliente_refe);   
            commit;     
            EXCEPTION
              WHEN OTHERS THEN 
                rollback;
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                    'sp_crear_arlcrd',
                                                    pc_cod_usua_web,
                                                    '6 INSERTO EN ARLCRD: '||lc_tipo_docu||'-'||lc_no_docu,
                                                    '6 INSERTO EN ARLCRD',
                                                    '6 INSERTO EN ARLCRD');
            END;
          END IF;
        END LOOP;
        
        CLOSE p_ret_cur_fact;
    end if;      

  end sp_crear_arlcrd;
  
  Procedure sp_crear_arlcav(
  pc_no_cia         IN      arlcav.no_cia%TYPE,
  pc_cod_oper       IN      arlcav.cod_oper%TYPE,
  pc_cod_soli       IN      arlcav.no_soli%TYPE,
  p_ret_cur_aval    IN      SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  )
  AS
  c_avales          PKG_SWEB_CRED_LXC.t_rec_aval;
  BEGIN
    LOOP
      FETCH p_ret_cur_aval INTO c_avales;
      EXIT WHEN p_ret_cur_aval%NOTFOUND;
      
     pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sp_crear_arlcav',
                                              pc_cod_usua_web,
                                              c_avales.no_cia || ' ' ||
                                              c_avales.cod_oper || ' ' ||
                                              c_avales.sec_aval || ' ' ||
                                              c_avales.nom_aval || ' ' ||
                                              c_avales.direc_aval || ' ' ||
                                              c_avales.le || ' ' ||
                                              c_avales.telf_aval || ' ' ||
                                              c_avales.des_aval,
                                              pc_ret_mens,
                                              pc_ret_mens);
  
     insert into arlcav(no_cia,
                           cod_oper,
                           sec_aval,
                           nom_aval,
                           direc_aval,
                           le,
                           telf_aval,
                           des_aval,
                           no_soli,
                           ruc,
                           representante)
        values (c_avales.no_cia,
                pc_cod_oper,
                c_avales.sec_aval,
                c_avales.nom_aval,
                c_avales.direc_aval,
                c_avales.le,
                c_avales.telf_aval,
                c_avales.des_aval,
                c_avales.no_soli,
                c_avales.ruc,
                c_avales.representante);
      end loop;
      commit;
      
  END sp_crear_arlcav;
  
  Procedure sp_crear_arlcgo(
  pc_no_cia         IN      arlcgo.no_cia%TYPE,
  pc_cod_oper       IN      arlcgo.cod_oper%TYPE,
  pd_fecha_ini      IN      arlcop.fecha_ini%TYPE,
  p_ret_cur_gasto    IN      SYS_REFCURSOR,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  )
  AS
  c_arlcgo          PKG_SWEB_CRED_LXC.t_rec_gastos;
  ln_tipo_cambio    arcgtc.tipo_cambio%type;
  kc_clase_cambio   arcgtc.clase_cambio%TYPE:= '02';
  BEGIN
    begin
          /*select tipo_cambio 
          into   ln_tipo_cambio 
          from   arcgtc 
          where  clase_cambio = kc_clase_cambio 
          and    fecha = trunc(pd_fecha_ini);
          */
          select tipo_cambio 
          into   ln_tipo_cambio 
          from   arcgtc 
          where  clase_cambio = kc_clase_cambio
          --and    fecha = trunc(pd_fecha_ini);
          and    fecha IN (select MIN(X.fecha) 
                 from (select max(fecha) fecha from arcgtc where  clase_cambio = '02' 
                       union 
                       select trunc(pd_fecha_ini) fecha from dual)X);  
          
          pc_ret_mens := 'se obtiene el tipo de cambio';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                      'sp_crear_arlcgo',
                                      pc_cod_usua_web,
                                      'Error en la consulta',
                                      pc_ret_mens,
                                      NULL);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
            ln_tipo_cambio := 0;
            pc_ret_mens := 'NO EXISTE TIPO DE CAMBIO PARA LA FECHA ACTUAL Y/O MONEDA';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcgo',
                                        pc_cod_usua_web,
                                        'Error en la consulta',
                                        pc_ret_mens,
                                        pc_ret_mens);
            -- RETURN; -- DESCOMENTAR DESPUES DE PRUEBAS 
        end;        

    LOOP
      FETCH p_ret_cur_gasto INTO c_arlcgo;
      EXIT WHEN p_ret_cur_gasto%NOTFOUND;
      
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcgo',
                                        pc_cod_usua_web,
                                        c_arlcgo.no_cia || ' ' ||
                                        c_arlcgo.cod_gasto || ' ' ||
                                        c_arlcgo.cod_oper || ' ' ||
                                        c_arlcgo.monto || ' ' ||
                                        c_arlcgo.moneda || ' ' ||
                                        ln_tipo_cambio || ' ' ||
                                        1 || ' ' ||
                                        c_arlcgo.observaciones || ' ' ||
                                        c_arlcgo.no_docu,
                                        pc_ret_mens,
                                        pc_ret_mens);
  
      insert into arlcgo(no_cia,
                         cod_gasto,
                         cod_oper,
                         monto,
                         moneda,
                         tipo_cambio,
                         signo,
                         observaciones,
                         no_docu,
                         ind_finan)
      values (pc_no_cia,
              c_arlcgo.cod_gasto,
              pc_cod_oper,
              c_arlcgo.monto,
              c_arlcgo.moneda,
              ln_tipo_cambio,
              1,
              c_arlcgo.observaciones,
              c_arlcgo.no_docu,
              'N');                 
    end loop;
    commit; 
  END sp_crear_arlcgo;
  
  
  Procedure sp_act_op_soli(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
    pc_cod_oper       IN      arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
    ) AS
    kc_tcred_refi     vve_cred_soli.tip_soli_cred%TYPE := 'TC07';
    lc_cod_oper_ori   vve_cred_soli.cod_oper_rel%TYPE;
  BEGIN
    IF pc_cod_oper IS NOT NULL AND pc_tipo_cred <> kc_tcred_refi THEN
      begin
        update vve_cred_soli
           set cod_oper_rel  = pc_cod_oper 
         where cod_empr      = pc_no_cia 
           and cod_soli_cred = pc_num_soli;
        commit;
      EXCEPTION 
        WHEN OTHERS THEN 
          pn_ret_esta := -1;
          pc_ret_mens := 'ERROR AL ACTUALIZAR - NO SE ENCONTRO SOLICITUD';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'PKG_SWEB_CRED_LXC.SP_ACT_OP_SOLI',
                                              pc_cod_usua_web,
                                              'Error en el update para Financ. <> Ref',
                                              pc_ret_mens,
                                              pc_ret_mens);
      end;
    ELSE 
    	IF pc_cod_oper IS NOT NULL THEN 
         select substr(pc_cod_oper,1,instr(pc_cod_oper,'-')-1) into lc_cod_oper_ori from dual;
      END IF;
      begin
      update vve_cred_soli
         set cod_oper_orig = lc_cod_oper_ori,
             cod_oper_rel  = pc_cod_oper 
       where cod_empr      = pc_no_cia 
         and cod_soli_cred = cod_soli_cred;
      commit;
      EXCEPTION 
        WHEN OTHERS THEN 
          pn_ret_esta := -1;
          pc_ret_mens := 'ERROR AL ACTUALIZAR - NO SE ENCONTRO SOLICITUD';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'PKG_SWEB_CRED_LXC.SP_ACT_OP_SOLI',
                                              pc_cod_usua_web,
                                              'Error en el update para refinanc.',
                                              pc_ret_mens,
                                              pc_ret_mens);
      end;
    END IF;
  END ;
/*
  function sf_validar_documentos(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
    pc_num_soli       IN      vve_cred_soli.cod_soli_cred%TYPE,
    pn_cod_oper       IN      arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cur_fact    IN      SYS_REFCURSOR,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
   ) RETURN BOOLEAN
   AS
   kc_periodicidad   vve_tabla_maes.cod_grupo%TYPE := 88;
   kc_tc_directo     vve_cred_soli.tip_soli_cred%TYPE := 'TC01';
   kc_tc_leas        vve_cred_soli.tip_soli_cred%TYPE := 'TC02';
   kc_tc_mutuo       vve_cred_soli.tip_soli_cred%TYPE := 'TC03';
   kc_tc_gbanc       vve_cred_soli.tip_soli_cred%TYPE := 'TC06';
   kc_tc_pv          vve_cred_soli.tip_soli_cred%TYPE := 'TC05';
   kc_tc_ref         vve_cred_soli.tip_soli_cred%TYPE := 'TC07';
   kc_financ         arlcop.modal_cred%TYPE := 'F';
   kc_mutuo          arlcop.modal_cred%TYPE := 'M';
   kc_pv             arlcop.modal_cred%TYPE := 'P';
   kc_ref            arlcop.modal_cred%TYPE := 'R';
   kc_ind_inactivo   vve_cred_simu.ind_inactivo%TYPE := 'N';
   lc_modal_cred     arlcop.modal_cred%TYPE;
   lc_no_docu        arlcrd.no_docu%TYPE;
   lr_fact           PKG_SWEB_CRED_LXC.t_fact_x_op;
   err_existe        Exception;
   lc_grupo        arccmd.grupo%TYPE;
   lc_cod_ref      arccmd.cod_oper%TYPE;
   
   Begin
    
    begin
      select Case pc_tipo_cred
             When kc_tc_directo then kc_financ
             When kc_tc_leas    then kc_mutuo 
             When kc_tc_mutuo   then kc_mutuo 
             When kc_tc_gbanc   then kc_mutuo 
             When kc_tc_pv      then kc_pv
             When kc_tc_ref     then kc_ref
             end modal_cred
      into   lc_modal_cred       
      from   vve_cred_soli 
      where  cod_empr = pc_no_cia 
      and    cod_soli_cred = pc_num_soli
      and    ind_inactivo  = kc_ind_inactivo;
    Exception 
        When no_data_found then 
          lc_modal_cred := null;
    end;
    
    if p_ret_cur_fact is not null then 
    loop
        fetch p_ret_cur_fact into lr_fact;
        EXIT WHEN p_ret_cur_fact%NOTFOUND;
       -- Validacion de documento. Modalidad: Postventa y Mutuos
        IF lc_modal_cred in ('P','M') and lr_fact.tipo_docu in ('FR','BR','FS','BS','MU') THEN
            if lr_fact.tipo_docu in ('FR','BR','FS','BS') THEN -- si es postventa ('P') 
                lc_no_docu := substr(lr_fact.no_docu,1,3) || lpad(substr( lr_fact.no_docu, 4 ,8),8,'0' );
            end if;  
        else -- si es mutuo ('M')
          begin
                select   grupo,  cod_oper 
                into   lc_grupo,  lc_cod_ref
                from    arccmd 
                where   no_cia       = pc_no_cia         
                and     tipo_doc     = lr_fact.tipo_docu     
                and     no_docu       = lr_fact.no_docu       
                and     no_cliente   = pc_no_cliente    
                and     estado     != 'P'                 
                and     nvl(saldo,0) != 0 ;
          Exception
                When NO_DATA_FOUND then
                    message('Documento no existe verifique !!!!!');
                    raise form_trigger_failure;
                When others then
                    message('Error al validar documento.: '||sqlerrm);
                    raise form_trigger_failure;
          End;
        End if;
    
   end sf_validar_documentos;
*/   
  function sf_verifica_existe_doc(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_rec_fact        IN      PKG_SWEB_CRED_LXC.t_fact_x_op,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
   ) RETURN BOOLEAN 
  AS
  ln_existe     NUMBER(1):=0;
  err_existe      Exception;
  lb_resultado    boolean := false;
  BEGIN
    
  if p_rec_fact.no_docu is not null then 
    begin
      select 1 
      into   ln_existe
      from   arccmd
      where  no_cia      = pc_no_cia      
      and    tipo_doc   = p_rec_fact.tipo_docu    
      and    no_docu    = p_rec_fact.no_docu      
      and    grupo       = p_rec_fact.grupo        
      and    no_cliente = p_rec_fact.no_cliente;        
      
      if ln_existe = 1 then
        pn_ret_esta := 1;
        pc_ret_mens := 'Ya existe el documento de referencia';
        lb_resultado:= true;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'PKG_SWEB_CRED_LXC.SP_VERIFICA_EXISTE_DOC',
                                            pc_cod_usua_web,
                                            'Existe doc '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                            pc_ret_mens,
                                            pc_ret_mens);
      return lb_resultado;
      end if;        
    Exception
      When no_data_found then
        lb_resultado:= false;
      When err_existe then
        pn_ret_esta := -1;
        pc_ret_mens := 'Ya existe el documento de referencia';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'PKG_SWEB_CRED_LXC.SP_VERIFICA_EXISTE_DOC',
                                            pc_cod_usua_web,
                                            'Error en la VALIDACIÓN',
                                            pc_ret_mens,
                                            pc_ret_mens);
      When others then 
        pn_ret_esta := -1;
        pc_ret_mens := 'Error al verificar existencia de doc. ref. ' ||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'PKG_SWEB_CRED_LXC.SP_VERIFICA_EXISTE_DOC',
                                            pc_cod_usua_web,
                                            'Error en la VALIDACIÓN',
                                            pc_ret_mens,
                                            pc_ret_mens);
       return lb_resultado;
     End;
  End if;
  --return lb_resultado;
  End sf_verifica_existe_doc;  

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
  ) AS
  c                 pkg_sweb_cred_lxc.t_rec_arlcop := null;
  ln_cod_oper       arlcop.cod_oper%TYPE;
  Begin
  
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcop',
                                        pc_cod_usua_web,
                                        pc_no_cia || ' - ' ||
                                        pc_num_soli,
                                        pc_num_soli,
                                        pc_num_soli); 
  
     if pn_cod_oper is null then 
       sp_obtener_datos_op(
                          pc_no_cia,
                          pc_no_cliente,
                          pc_num_soli,
                          pc_tipo_cred,
                          pn_cod_oper,
                          pc_tipo_doc_op,
                          pd_fecha_cont,
                          pd_fecha_ini,
                          pc_tipo_cuota,
                          pd_fecha_aut,
                          pc_usuario_aprb,
                          pc_cod_usua_web,
                          p_ret_cur_fact,
                          c,
                          pn_ret_esta,
                          pc_ret_mens);
       
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'sp_crear_arlcop - despues de obtener datos',
                                          pc_cod_usua_web,
                                          'c.no_cia: '||c.no_cia,
                                          pc_num_soli,
                                          pc_num_soli);  
      IF c.no_cia IS NULL THEN 
        dbms_output.put_line('el cursor de c es null');
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcop',
                                        pc_cod_usua_web,
                                        'el cursor de c es null',
                                        pc_num_soli,
                                        pc_num_soli); 
      ELSE
        dbms_output.put_line('devuelve obtener_datos op '||c.no_cia);
        --ln_cod_oper := sf_obtener_nro_op(pc_no_cia,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
        ln_cod_oper := c.cod_oper; 
        pn_cod_oper := c.cod_oper; 
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcop',
                                        pc_cod_usua_web,
                                        'Entrando a insertar en arlcop',
                                        'Entrando a insertar en arlcop',
                                        'Entrando a insertar en arlcop'); 
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'sp_crear_arlcop',
                                        pc_cod_usua_web,
                                        c.ano || ' - ' ||
                                        c.cod_oper || ' - ' ||
                                        c.mes || ' - ' ||
                                        c.no_cia || ' - ' ||
                                        c.tipo_cuota,
                                        'Entrando a insertar en arlcop',
                                        'Entrando a insertar en arlcop');  
                                        
                        
        
        insert into arlcop (select    c.no_cia,
                                      ln_cod_oper,
                                      c.ano,
                                      c.mes,
                                      c.grupo,
                                      c.no_cliente,
                                      c.modal_cred,
                                      c.tipo_bien,
                                      c.fecha,
                                      c.tea,
                                      c.mon_tasa_igv,
                                      c.mon_tasa_isc,
                                      c.valor_original,
                                      c.monto_gastos,
                                      c.monto_fina,
                                      c.interes_per_gra,
                                      c.total_financiar,
                                      c.interes_oper,
                                      c.total_igv,
                                      c.total_isc,
                                      c.moneda,
                                      c.tipo_cambio,
                                      c.plazo,
                                      c.no_cuotas,
                                      c.vcto_1ra_let,
                                      c.fre_pago_dias,
                                      c.dia_pago,
                                      c.tipo_cuota,
                                      c.ind_per_gra,
                                      c.ind_per_gra_cap,
                                      c.tasa_gra,
                                      c.fre_gra,
                                      c.mon_cuo_ext,
                                      c.cext_ene,
                                      c.cext_feb,
                                      c.cext_mar,
                                      c.cext_abr,
                                      c.cext_may,
                                      c.cext_jun,
                                      c.cext_jul,
                                      c.cext_ago,
                                      c.cext_sep,
                                      c.cext_oct,
                                      c.cext_nov,
                                      c.cext_dic,
                                      c.cta_interes_diferido,
                                      c.cta_ingresos_finan,
                                      c.estado,
                                      c.usuario,
                                      c.usuario_aprb,
                                      c.no_soli,
                                      c.ind_soli,
                                      c.sec_oper,
                                      c.fecha_ini,
                                      c.cuota_inicial,
                                      c.ind_lb,
                                      c.judicial,
                                      c.tipo_factu,
                                      c.ind_factu,
                                      c.ind_utilizado,
                                      c.f_aceptada,
                                      c.f_anulada,
                                      c.usr_anula,
                                      c.ind_nu,
                                      c.nur_soli_cred_det,
                                      c.num_corre_seguro,
                                      c.num_pedido_veh,
                                      c.cod_filial,
                                      c.tipodocgen,
                                      c.fecha_aut_ope,
                                      c.fecha_cre_reg,
                                      c.num_prof_veh /*,
                                      c.ind_ajuste_fecha */
                                      from dual);
       
        commit;
        END IF;
    end if;                      
    
  end sp_crear_arlcop;

  Function sf_valida_usua_ope(
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    cod_acti_pedi_veh IN      usuarios_acti_pedido_veh.cod_acti_pedido_veh%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN IS
  kc_acti_entr_veh usuarios_acti_pedido_veh.cod_acti_pedido_veh%TYPE := '0018';
  lb_resultado     BOOLEAN := FALSE;
  lc_co_usuario    usuarios_acti_pedido_veh.co_usuario%type;
  BEGIN
    Begin
      select co_usuario
      into lc_co_usuario
      from usuarios_acti_pedido_veh
      where co_usuario = pc_cod_usua_web 
      and   cod_acti_pedido_veh = kc_acti_entr_veh; -- Aut. Entrega Vehículo
      pn_ret_esta  := 1;
      pc_ret_mens := 'Ya existe la Autorización de Entrega de Vehículo';
      lb_resultado := TRUE;
      Exception
        when no_data_found then
          pn_ret_esta  := 0;
          pc_ret_mens := 'El uuario (Aut. Veh.) no existe';
          lb_resultado := FALSE;
        When others then 
            pn_ret_esta := 1;
            pc_ret_mens := 'Error al verificar usuario ' ||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'PKG_SWEB_CRED_LXC.SF_VALIDA_USUA_OPE',
                                                pc_cod_usua_web,
                                                'Error en la VALIDACIÓN DE GENERACIÓN OP',
                                                pc_ret_mens,
                                                NULL);
     End;   
     RETURN lb_resultado;
  END sf_valida_usua_ope;
  
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
  ) IS 
  kc_esta_op_pend     arlcop.estado%type := 'P';
  r_op                arlcop%rowtype;
  BEGIN
    open p_ret_cur_oper for
     select * from arlcop where cod_oper = pn_cod_oper and no_cia = pc_no_cia and estado = kc_esta_op_pend;
     fetch p_ret_cur_oper into r_op;
     
    open p_ret_cur_fact for 
     select * from arlcrd where cod_oper = pn_cod_oper and no_cia = pc_no_cia and cod_oper = r_op.cod_oper ;
    
    open p_ret_cur_letr for 
     select * from arlcml where cod_oper = pn_cod_oper and no_cia = pc_no_cia and cod_oper = r_op.cod_oper ;
    
    open p_ret_cur_gast for 
     select * from arlcgo where cod_oper = pn_cod_oper and no_cia = pc_no_cia and cod_oper = r_op.cod_oper ;
    
    open p_ret_cur_aval for 
     select * from arlcav where cod_oper = pn_cod_oper and no_cia = pc_no_cia and cod_oper = r_op.cod_oper ;

  END sp_obtener_data_op;
  Function sf_obtener_tasa_igv(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN NUMBER IS
  kn_clave_igv        arcgiv.clave%type := 11;
  ln_porc_igv         arcgiv.porcentaje%type:=0;
  BEGIN
      -- Obtiene el procentaje del IGV
      Begin
        select   porcentaje/100
        into     ln_porc_igv
        from     arcgiv
        where   no_cia = pc_no_cia and 
                clave  = kn_clave_igv;

        pn_ret_esta := 1;
        
        pc_ret_mens := '1.Valida No Docu - entro al select';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'sf_obtener_tasa_igv',
                                            pc_cod_usua_web,
                                            'consulta: '||to_char(ln_porc_igv,'999.99'),
                                            pc_ret_mens,
                                            pc_ret_mens);
      Exception 
        When no_data_found then
          ln_porc_igv := null;
          pn_ret_esta := -1;
          pc_ret_mens := 'Impuesto no existe';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sf_obtener_tasa_igv',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);
        When others then 
          ln_porc_igv := null;
          pn_ret_esta := -1;
          pc_ret_mens := 'Error al buscar impuesto: '||sqlerrm;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'sf_obtener_tasa_igv',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);

      End;

    RETURN ln_porc_igv;
  END sf_obtener_tasa_igv;
  
  Function sf_valida_tipo_docu(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  pc_no_cliente     IN      arlcop.no_cliente%TYPE,
  pc_moneda         IN      arlcop.moneda%TYPE,
  p_rec_fact        IN OUT     PKG_SWEB_CRED_LXC.t_fact_x_op,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN IS
  lb_existe_doc    BOOLEAN := FALSE;
  lc_tipo_docu     arlcrd.tipo_docu%TYPE;
  BEGIN
  pc_ret_mens := 'Modal_Cred: '||pc_modal_cred;
  pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SF_VALIDA_TIPO_DOCU',
                                        pc_cod_usua_web,
                                        'Tipo de documento existe - '||pc_modal_cred,
                                        pc_ret_mens,
                                        pc_ret_mens);
  IF pc_modal_cred NOT IN ('P','M') THEN  
    BEGIN  
      SELECT tipo 
      INTO   lc_tipo_docu 
      FROM   arcctd td
      WHERE  td.no_cia = pc_no_cia  
      AND    td.tipo   = p_rec_fact.tipo_docu;
      
      p_rec_fact.tipo_docu := lc_tipo_docu;
      lb_existe_doc        := TRUE;
      
      pc_ret_mens := 'Tipo de Documento: '||p_rec_fact.tipo_docu;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_TIPO_DOCU',
                                            pc_cod_usua_web,
                                            'Tipo de documento existe',
                                            pc_ret_mens,
                                            pc_ret_mens);
    EXCEPTION
      WHEN no_data_found THEN
      lb_existe_doc := false;
      pn_ret_esta := -1;
      pc_ret_mens := 'Tipo de Documento No Existe o el registro esta en Blanco'||sqlerrm;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SF_VALIDA_TIPO_DOCU',
                                          pc_cod_usua_web,
                                          'Error en la consulta - no existe doc '||p_rec_fact.tipo_docu,
                                          pc_ret_mens,
                                          pc_ret_mens);
    END;
  ELSE
    --Control tipo documento manejados por sap
    --Postventa 
   if pc_modal_cred = 'P' then
      if p_rec_fact.tipo_docu in ('FR','BR','FS','BS') then    
        lb_existe_doc := sf_verifica_existe_doc(pc_no_cia,pc_cod_usua_web,p_rec_fact,pn_ret_esta,pc_ret_mens);
        p_rec_fact.moneda := pc_moneda;
        p_rec_fact.no_cliente := pc_no_cliente;
        lb_existe_doc := true;
      else
        pn_ret_esta := -1;
        pc_ret_mens := 'Tipo de documento no permitido para PostVenta'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_TIPO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_existe_doc := false;
      end if;
    elsif pc_modal_cred = 'M' then--Mutuos
      pc_ret_mens := 'entro al elsif pc_modal_cred = M, Modal_Cred: '||pc_modal_cred;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_TIPO_DOCU',
                                            pc_cod_usua_web,
                                            pc_ret_mens,
                                            pc_ret_mens,
                                            pc_ret_mens);
      if p_rec_fact.tipo_docu in ('MU') then
        pc_ret_mens := 'entro al if p_rec_fact.tipo_docu in (MU), p_rec_fact.tipo_docu: '||p_rec_fact.tipo_docu;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_TIPO_DOCU',
                                              pc_cod_usua_web,
                                              pc_ret_mens,
                                              pc_ret_mens,
                                              pc_ret_mens);
        --lb_existe_doc := sf_verifica_existe_doc(pc_no_cia,pc_cod_usua_web,p_rec_fact,pn_ret_esta,pc_ret_mens); 
        /*if (lb_existe_doc <> true) then 
          pc_ret_mens := 'lb_existe_doc = false';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_TIPO_DOCU',
                                                pc_cod_usua_web,
                                                pc_ret_mens,
                                                pc_ret_mens,
                                                pc_ret_mens);
        end if; 
        */   
        p_rec_fact.moneda := pc_moneda;
        p_rec_fact.no_cliente := pc_no_cliente;      
        lb_existe_doc := true;
      else
        pc_ret_mens := 'entro al else cuando p_rec_fact.tipo_docu <> MU, p_rec_fact.tipo_docu: '||p_rec_fact.tipo_docu;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_TIPO_DOCU',
                                              pc_cod_usua_web,
                                              pc_ret_mens,
                                              pc_ret_mens,
                                              pc_ret_mens);
        pn_ret_esta := -1;
        pc_ret_mens := 'Tipo de documento no permitido para Mutuos'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_TIPO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_existe_doc := false;
      end if;
    end if;
  END IF;
  RETURN lb_existe_doc;
  END sf_valida_tipo_docu;
  
  Function sf_valida_no_docu(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  p_rec_fact        IN OUT  PKG_SWEB_CRED_LXC.t_fact_x_op,
  --p_rec_fact        IN OUT  VVE_TYPE_DOCU_RELA_ITEM,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN IS
  
  lc_indicador      VARCHAR2(2);
  --lc_tipo_docu      VARCHAR2(2);
  xletra            VARCHAR2(20); -- cambio para que acepte letra = LM
  xtb                 VARCHAR2(2);
  WC_EXISTE         VARCHAR2(1);
  ln_cod_oper_ref   arlcrd.cod_ref%TYPE;
  lc_grupo          arlcrd.grupo%TYPE;
  lc_tipo_docu      arlcrd.tipo_docu%TYPE;
  lc_no_factu       arlcrd.no_docu%TYPE;
  lc_no_cliente     arlcrd.no_cliente%TYPE;
  lc_est_ref        arlcrd.est_ref%TYPE;
  ld_fecha          arlcrd.fecha%TYPE;
  ln_monto          arlcrd.monto%TYPE;
  ln_saldo_anterior arlcrd.saldo_anterior%TYPE; 
  lc_moneda         arlcrd.moneda%TYPE; 
  lc_cod_ref        arlcrd.cod_ref%TYPE;
  lb_result         BOOLEAN;
  v_verifica        arccmd.no_docu%type;
  
  BEGIN
  IF p_rec_fact.tipo_docu IS NOT NULL THEN 
    ln_cod_oper_ref   := p_rec_fact.cod_ref;
    lc_grupo          := p_rec_fact.grupo;
    lc_no_factu       := p_rec_fact.no_docu;
    lc_no_cliente     := p_rec_fact.no_cliente;
    lc_tipo_docu      := p_rec_fact.tipo_docu;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                        'SF_VALIDA_NO_DOCU no nulo',
                                        pc_cod_usua_web,
                                        'ln_cod_oper_ref: '||ln_cod_oper_ref||', lc_grupo:'||
                                        lc_grupo||', lc_no_factu:'||lc_no_factu||', lc_no_cliente:'||
                                        lc_no_cliente||', lc_tipo_docu:'||lc_tipo_docu,
                                        pc_ret_mens,
                                        pc_ret_mens);
    -- Validacion de documento. Modalidad: Postventa y Mutuos
    IF pc_modal_cred IN ('P','M') AND p_rec_fact.tipo_docu IN ('FR','BR','FS','BS','MU') THEN
      IF p_rec_fact.tipo_docu IN ('FR','BR','FS','BS') THEN 
        p_rec_fact.no_docu := substr(p_rec_fact.no_docu,1,3) || lpad(substr( p_rec_fact.no_docu, 4 ,8),8,'0' );
        pc_ret_mens := '0.Valida No Docu - docu post-venta p_rec_fact.tipo_docu:'||p_rec_fact.tipo_docu||'- p_rec_fact.no_docu:'||p_rec_fact.no_docu;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'consulta: '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                            pc_ret_mens,
                                            pc_ret_mens);
      END IF;  
      
      begin
        select nvl(no_docu,'0') 
        into  v_verifica
        from arccmd
        where no_cia 	 	= pc_no_cia 		 
        and   tipo_doc 	= p_rec_fact.tipo_docu 	
        and   no_docu  	= p_rec_fact.no_docu 		 
        and   grupo 	 	= p_rec_fact.grupo 			 
        and   no_cliente= p_rec_fact.no_cliente;
      
        pc_ret_mens := '0.Valida No Docu - v_verifica = 0';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'consulta: '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                            pc_ret_mens,
                                            pc_ret_mens);
        if (v_verifica is not null and v_verifica <>'0')then 
           lb_result := TRUE;
        elsif  v_verifica ='0' then
           lb_result := FALSE;
           pc_ret_mens := '0.Valida No Docu - v_verifica <> 0';
           pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_NO_DOCU',
                                              pc_cod_usua_web,
                                              'consulta: '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                              pc_ret_mens,
                                              pc_ret_mens);
        END IF;
      exception 
        when others then 
          lb_result := FALSE;
          pc_ret_mens := 'error al buscar en arccmd';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_NO_DOCU',
                                              pc_cod_usua_web,
                                              'Error consulta: No existe documento '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                              pc_ret_mens,
                                              pc_ret_mens);
      end;
      --sp_valida_vcto_letra(pc_no_cia,pc_modal_cred,p_rec_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
      
    ELSE
      Begin
        select  no_docu,  no_cliente,
                grupo,  cod_oper 
        into    lc_no_factu,  lc_no_cliente,
                lc_grupo,  ln_cod_oper_ref 
        from    arccmd 
        where   no_cia       = pc_no_cia        
        and     tipo_doc     = p_rec_fact.tipo_docu    
        and     no_docu       = p_rec_fact.no_docu      
        and     no_cliente   = p_rec_fact.no_cliente   
        and     estado       != 'P'                
        and     nvl(saldo,0) != 0 ;
        
        p_rec_fact.no_docu := lc_no_factu;
        p_rec_fact.no_cliente := lc_no_cliente;
        p_rec_fact.grupo      := lc_grupo;
        p_rec_fact.cod_ref    := lc_cod_ref;
        
        lb_result := TRUE;
        
        pc_ret_mens := '1.Valida No Docu - entro al select no_docu';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'consulta: '||p_rec_fact.tipo_docu||'-'||p_rec_fact.no_docu,
                                            pc_ret_mens,
                                            pc_ret_mens);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN 
        pn_ret_esta := -1;
        pc_ret_mens := 'Documento no existe verifique !!!!!'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_result := FALSE;
        WHEN OTHERS THEN
        pn_ret_esta := -1;
        pc_ret_mens := 'Error al validar documento.: '||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_result := FALSE;
      END;
    END IF;
    ------

    -- Obtiene clase del documento
    begin
      select   tipo      ,  clase_docu 
      into     lc_tipo_docu  ,  lc_indicador
      from     arcctd
      where    no_cia = pc_no_cia  
      and      tipo   = p_rec_fact.tipo_docu;

      p_rec_fact.tipo_docu := lc_tipo_docu;
      --lb_result := TRUE;
      
      pc_ret_mens := '2.Valida No Docu - entro al select clase doc';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SF_VALIDA_NO_DOCU',
                                          pc_cod_usua_web,
                                          'consulta lc_tipo_docu :'||lc_tipo_docu||', lc_indicador:'||lc_indicador,
                                          pc_ret_mens,
                                          pc_ret_mens);
    exception 
      when others then 
        pc_ret_mens := 'Error al validar Clase documento.: '||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_result := FALSE;
    end;
    -- Obtiene el tipo de documento utilizado para las letras
    begin 
      select   tipo_doc_letras||','||tipo_doc_let_lm -- cambio para LM tenga funcionalidad de letra
      into     xletra 
      from     arlctp 
      where    no_cia = pc_no_cia;
      
      --lb_result := TRUE;
      pc_ret_mens := '3.Valida No Docu - entro al select tipo doc letras';
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SF_VALIDA_NO_DOCU',
                                          pc_cod_usua_web,
                                          'consulta',
                                          pc_ret_mens,
                                          pc_ret_mens);
    exception 
      when others then 
        pc_ret_mens := 'Error al validar TIPO documento LETRAS: '||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        lb_result := FALSE;
    end;
    -----------------
    --Indicador Letra
    IF lc_indicador = 'L' THEN
      pc_ret_mens := '4.Entro al IF de Letras: lc_indicador = L ' ;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                          'SF_VALIDA_NO_DOCU',
                                          pc_cod_usua_web,
                                          'consulta',
                                          pc_ret_mens,
                                          pc_ret_mens);
      IF INSTR(xletra,lc_tipo_docu) > 0 THEN -- cambio para LM tenga funcionalidad de letra
        pc_ret_mens := '4.1.Valida No Docu - entro al IF lc_indicador = L ';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        ---
        --- Es una letra del Cliente y desea refinanciarlo
        --- Saco Valor de la amortizacion del maestro de letras
        --- Para que el valor del igv e intereses vaya como una
        --- Nota de Credito a favor del Cliente en el momento de la actualizacion 
        ---
        --- Selecciono el estado de vencido de la letra en lxc
        ---
        Begin
          select tb into xtb
          from arlcml
          where no_cia     = pc_no_cia         
          and   no_cliente = p_rec_fact.no_cliente  
          and   no_letra   = p_rec_fact.no_docu      
          and   cod_oper   = p_rec_fact.cod_ref       
          and   situacion  not in('PENDI','ANULA');
          
          pc_ret_mens := '5.Valida No Docu - entro al select xtb de arlcml';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_NO_DOCU',
                                              pc_cod_usua_web,
                                              'consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);
           lb_result := TRUE;       
          IF xtb IS NULL THEN 
            pn_ret_esta := -1;
            pc_ret_mens := 'No existe indicador de Truck  a la letra '||p_rec_fact.no_docu||'  '||'Coordinar con el Departamente de Creditos y Cobranzas.'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
          ELSIF xtb ='O' THEN 
            pn_ret_esta := -1;
            pc_ret_mens := 'No existe indicador de Truck  a la letra '||p_rec_fact.no_docu||'  '||'Coordinar con el Departamente de Creditos y Cobranzas.'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
          END IF;
            
        EXCEPTION
          WHEN no_data_found THEN 
            pn_ret_esta := 0;
            pc_ret_mens := 'No existe la letra es el maestro. Coordinar con el Departamente de Creditos y Cobranzas.'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
        END;
          
        Begin
          select nvl(est_vcto,'D'), f_vence 
          into   lc_est_ref, ld_fecha
          from  arlcml 
          where no_cia       = pc_no_cia        
          and    no_letra    = p_rec_fact.no_docu     
          and   no_cliente   = p_rec_fact.no_cliente 
          and    situacion not in ('PENDI','ANULA');
          
          p_rec_fact.cod_ref := lc_est_ref;
          p_rec_fact.fecha   := ld_fecha;
          
          lb_result := TRUE;
          
          pc_ret_mens := '6.Valida No Docu - entro al select de valida vcto de letras';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_NO_DOCU',
                                              pc_cod_usua_web,
                                              'consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);
        Exception 
          when too_many_rows then
            pn_ret_esta := -1;
            pc_ret_mens := 'Se encontro duplicado en Lxc en el momento de seleccionar el estado de la letra'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
          when no_data_found then
            pn_ret_esta := -1;
            pc_ret_mens := 'No Se encontro en Lxc en el momento de seleccionar el estado de la letra'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
          when others then
            pn_ret_esta := -1;
            pc_ret_mens := 'Se encontro un error raro consulte a Computo'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;        
        End;
        
        ---  Valido por vencimiento
        sp_valida_vcto_letra(pc_no_cia,pc_modal_cred,p_rec_fact,pc_cod_usua_web,pn_ret_esta,pc_ret_mens);
      ELSE /* Otro Letra de de cxc */
        Begin
          --***:ocho.est_letra := 'Letra Cxc x Vencer';
          select (Nvl(M_original,0)+ Nvl(Igv,0) + Nvl(Isc,0)),
                 (Nvl(M_original,0)+ Nvl(Igv,0) + Nvl(Isc,0)),
                  fecha_vence, moneda, cod_oper
          into     ln_monto, ln_saldo_anterior, ld_fecha, lc_moneda, lc_cod_ref
          from     arcctd td, arccmd md
          where   td.no_cia     = md.no_cia   
          and     td.tipo       = md.tipo_doc 
          and      md.no_cia     = pc_no_cia        
          and     md.tipo_doc   = p_rec_fact.tipo_docu   
          and     md.no_docu    = p_rec_fact.no_docu     
          and     md.no_cliente = p_rec_fact.no_cliente 
          and     md.estado     != 'P'              
          and     (nvl(md.saldo,0) <> 0 ); 
        
          p_rec_fact.monto         := ln_monto; 
          p_rec_fact.saldo_anterior:= ln_saldo_anterior; 
          p_rec_fact.fecha         := ld_fecha; 
          p_rec_fact.moneda        := lc_moneda; 
          p_rec_fact.cod_ref       := lc_cod_ref;
          
          lb_result := TRUE;
          
          pc_ret_mens := '7.Valida No Docu - entro al select saldo de letras de arlcml';
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_NO_DOCU',
                                              pc_cod_usua_web,
                                              'consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);
        Exception  
          When no_data_found then
            pn_ret_esta := -1;
            pc_ret_mens := 'Registro no existe en Lxc'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);        
            lb_result := FALSE;
          When too_many_rows  then
            pn_ret_esta := -1;
            pc_ret_mens := 'Más de un registro'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
          When others then
            pn_ret_esta := -1;
            pc_ret_mens := 'ERROR OCURRIO'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
             lb_result := FALSE;
        End;
      END IF;
      
    ELSE /* Otro documento de cxc */
      if pc_modal_cred not in ('P','M')then
        pc_ret_mens := '4.Entro al ELSE de Letras: lc_indicador <> L ' ;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_NO_DOCU',
                                            pc_cod_usua_web,
                                            'consulta lc_indicador:'||lc_indicador,
                                            pc_ret_mens,
                                            pc_ret_mens);
        begin
          --***:ocho.est_letra := 'Doc. Cxc x Vencer  ';
          select saldo, saldo, fecha_vence, moneda, cod_oper
          into   ln_monto, ln_saldo_anterior, ld_fecha, lc_moneda, lc_cod_ref
          from   arcctd td, arccmd md
          where  td.no_cia = md.no_cia
            and  td.tipo   = md.tipo_doc
            and  md.no_cia     = pc_no_cia
            and  md.tipo_doc   = p_rec_fact.tipo_docu
            and  md.no_docu    = p_rec_fact.no_docu
            and  md.no_cliente = p_rec_fact.no_cliente
            and  md.estado != 'P'                 
            and  (nvl(md.saldo,0) <> 0 );
            
            --p_rec_fact.monto         := ln_monto; 
            p_rec_fact.saldo_anterior:= ln_saldo_anterior; 
            p_rec_fact.fecha         := ld_fecha; 
            p_rec_fact.moneda        := lc_moneda; 
            p_rec_fact.cod_ref       := lc_cod_ref;
            
            lb_result := TRUE;
            
            pc_ret_mens := '7.Valida No Docu - entro al select Doc. Cxc x Vencer <> letras';
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'consulta p_rec_fact.saldo_anterior:'||TO_CHAR(p_rec_fact.saldo_anterior,'999999999.99'),
                                                pc_ret_mens,
                                                pc_ret_mens);
        exception  
          when no_data_found then
            pn_ret_esta := -1;
            pc_ret_mens := 'Registro no existe en cxc'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
            lb_result := FALSE;
          when others then
            pn_ret_esta := -1;
            pc_ret_mens := 'ERROR OCURRIO'||sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                                'SF_VALIDA_NO_DOCU',
                                                pc_cod_usua_web,
                                                'Error en la consulta',
                                                pc_ret_mens,
                                                pc_ret_mens);
            lb_result := FALSE;
        END;
      END IF;
    END IF;
  END IF;
  RETURN lb_result;
  END SF_VALIDA_NO_DOCU;
  
  Procedure sp_valida_vcto_letra(
  pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
  pc_modal_cred     IN      arlcop.modal_cred%TYPE,
  p_rec_fact        IN OUT  PKG_SWEB_CRED_LXC.t_fact_x_op,
  pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  pn_ret_esta       OUT     NUMBER,
  pc_ret_mens       OUT     VARCHAR2
  ) IS
  lc_est_ref        arlcrd.est_ref%TYPE;
  ld_fecha          arlcrd.fecha%TYPE;
  ln_monto          arlcrd.monto%TYPE;
  ln_saldo_anterior arlcrd.saldo_anterior%TYPE; 
  lc_moneda         arlcrd.moneda%TYPE; 
  lc_cod_ref        arlcrd.cod_ref%TYPE;
  
  BEGIN
    if p_rec_fact.est_ref = 'V' then  --- es Letra Vencida , Valor total de la letra (Capt + Int + Igv + Isc )
      if pc_modal_cred = 'F' then
        pn_ret_esta := -1;
        pc_ret_mens := 'No Se puede financiar una Letra Vencia eliga la Opcion de REFINANCIACION '||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
      End if; 
          
      --***:ocho.est_letra := 'Letra Vencida';
          
      Begin
        select (Nvl(saldo_amortizacion,0) + Nvl(saldo_intereses,0) + Nvl(saldo_igv,0) + Nvl(saldo_isc,0)) + nvl(saldo_seguro_veh,0),
               (Nvl(saldo_amortizacion,0) + Nvl(saldo_intereses,0) + Nvl(saldo_igv,0) + Nvl(saldo_isc,0)) + nvl(saldo_seguro_veh,0),
                f_vence, moneda, cod_oper
--        into p_rec_fact.monto, p_rec_fact.saldo_anterior, p_rec_fact.fecha, p_rec_fact.moneda, p_rec_fact.cod_ref
          into ln_monto, ln_saldo_anterior, ld_fecha, lc_moneda, lc_cod_ref
        from arlcml ml
        where ml.no_cia     = pc_no_cia       
        and   ml.no_letra   = p_rec_fact.no_docu     
        and   ml.no_cliente = p_rec_fact.no_cliente 
        and   ml.situacion  not in('PENDI','ANULA') 
        and   (nvl(ml.saldo,0) <>  0 );
        
        p_rec_fact.monto           := ln_monto;
        p_rec_fact.saldo_anterior  := ln_saldo_anterior;
        p_rec_fact.fecha           := ld_fecha;
        p_rec_fact.moneda          := lc_moneda;
        p_rec_fact.cod_ref         := lc_cod_ref;
      Exception  
        When no_data_found then
        pn_ret_esta := -1;
        pc_ret_mens := 'Registro no existe en Lxc'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            NULL);
        When too_many_rows  then
        pn_ret_esta := -1;
        pc_ret_mens := 'Más de un registro'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
        When others then
        pn_ret_esta := -1;
        pc_ret_mens := 'ERROR OCURRIO'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);

      End;
    elsIF p_rec_fact.est_ref = 'D' then    --- esta por vencer ,se generara una nota de Credito de los Int + Imp 
      Begin
        --***:ocho.est_letra := 'Letra x Vencer';
            
        select Nvl(saldo_amortizacion,0),  Nvl(saldo_amortizacion,0)  ,f_vence, moneda, cod_oper
        into ln_monto, ln_saldo_anterior, ld_fecha, lc_moneda, lc_cod_ref
        from arlcml ml
        where ml.no_cia     = pc_no_cia       
        and   ml.no_letra   = p_rec_fact.no_docu     
        and   ml.no_cliente = p_rec_fact.no_cliente 
        and   ml.situacion  not in ('ANULA','PENDI') 
        and   nvl(ml.saldo,0) <> 0 ;

        p_rec_fact.monto           := ln_monto;
        p_rec_fact.saldo_anterior  := ln_saldo_anterior;
        p_rec_fact.fecha           := ld_fecha;
        p_rec_fact.moneda          := lc_moneda;
        p_rec_fact.cod_ref         := lc_cod_ref;
      Exception  
        when no_data_found then
        pn_ret_esta := -1;
        pc_ret_mens := 'Registro no existe en Lxc'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);

        when too_many_rows  then
        pn_ret_esta := -1;
        pc_ret_mens := 'Más de un registro'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);

        when others then
        pn_ret_esta := -1;
        pc_ret_mens := 'ERROR OCURRIO'||sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_VALIDA_VCTO_LETRA',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);

      End;
    End if;
  END sp_valida_vcto_letra;
  
  /*Se obtiene las letras a refinanciar o reprogramar para que sean insertados en el arlcrd*/
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
  ) AS
  ln_Monto               Number;
  xx                   Number;
  numreg               Number(5) := 0;
  xnumero              Number;
  xtotal               Number;
  old_monto            Number;
  lc_tipo_doc_letras   arlctp.tipo_doc_letras%type;
  lr_fact              PKG_SWEB_CRED_LXC.t_fact_x_op;
  t_doclet             PKG_SWEB_CRED_LXC.t_table_reclet;
  
  cursor c_let_arccmd is 
      select a.no_cliente clie,
             a.no_letra  let,
             a.f_vence   ven,
             a.moneda    mon,
             Nvl(a.saldo_amortizacion,0)ori,
             Nvl(a.saldo_intereses,0) int,
             Nvl(a.saldo_igv,0)       igv ,
             Nvl(a.saldo_isc,0)       isc,
             a.cod_oper               ope,
             est_vcto
       from  arlcml a
      where  a.no_cia     = pc_no_cia        
        and  a.grupo      = pc_grupo         
        and  a.cod_oper   = pc_cod_oper_ori  
        and  a.no_cliente = pc_no_cliente    
        -- and  a.saldo     > 0
        and  ((a.saldo > 0) or (nvl(saldo,0) = 0 and a.ind_periodo_gracia = 'S'))
   ORDER BY NO_LETRA;
  
  BEGIN
    begin
    ln_monto    := 0; 
    old_monto   := 0;
    begin 
     select tipo_doc_letras 
     into   lc_tipo_doc_letras 
     from   arlctp 
     where  no_cia = pc_no_cia;
    end;
    
    --t_doclet := PKG_SWEB_CRED_LXC.t_table_reclet();
   -- t_doclet.extend(pn_nro_letras);
    --t_doclet.extend(10);
  	
/*    go_block('NUEVE');
    last_record;     
    xnumero := to_number(:System.Cursor_Record);
    IF Get_Record_Property(xnumero,'NUEVE',STATUS) != 'NEW' THEN
      next_record;
    End if; 
*/    

    lr_fact.tipo_docu := null;
    lr_fact.no_docu   := null;
    lr_fact.fecha     := null;
    lr_fact.moneda    := null;
    lr_fact.monto     := Null;
    lr_fact.cod_ref   := Null;
    lr_fact.no_cliente:= Null;
    for i in c_let_arccmd loop           
      xtotal := i.ori + i.int + i.Igv + i.Isc;
      lr_fact.no_cliente:= i.clie;
      lr_fact.tipo_docu := lc_tipo_doc_letras;
      lr_fact.no_docu   := i.let;
      lr_fact.fecha     := i.ven;
      lr_fact.moneda    := i.mon;
      lr_fact.monto     := xtotal;
      lr_fact.cod_ref   := i.ope;
      lr_fact.est_ref	  := i.est_vcto;
    	---
      --- Total de Documentos Referenciados
      ---
      ln_monto := calcula_cambio(lr_fact.monto,lr_fact.moneda,pc_moneda,pc_tipo_cambio); 
      xx       := nvl(xx,0) + ln_monto; 
      numreg   := numreg + 1; 
      --t_doclet := t_table_reclet();
      --t_doclet(i) :=  lr_fact;
      t_doclet(numreg).tipo_docu := lr_fact.tipo_docu;
      t_doclet(numreg).grupo := lr_fact.grupo;
      t_doclet(numreg).no_cliente := lr_fact.no_cliente;
      t_doclet(numreg).no_docu := lr_fact.no_docu;
      t_doclet(numreg).cod_oper := lr_fact.cod_oper;
      t_doclet(numreg).fecha := lr_fact.fecha;
      t_doclet(numreg).moneda := lr_fact.moneda;
      t_doclet(numreg).monto := lr_fact.monto;
      t_doclet(numreg).interes := 0;
      t_doclet(numreg).igv := 0;
      t_doclet(numreg).cod_ref := lr_fact.cod_ref;
      t_doclet(numreg).est_ref := lr_fact.est_ref;
      t_doclet(numreg).saldo_anterior := lr_fact.saldo_anterior;    
    end loop;
    if numreg = 0 then 
      --msg_alerta ('NO HAY LETRAS PARA PROCESAR  ....!!!');
      NULL;
    end if;

   OPEN p_cur_docletras FOR 
    SELECT    tipo_docu,
              grupo,
              no_cliente,
              no_docu,
              cod_oper,
              fecha,
              moneda,
              monto,
              cod_ref,
              est_ref,
              saldo_anterior
    FROM  TABLE(t_doclet);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --msg_alerta ('NO HAY LETRAS PARA PROCESAR  ....!!!');
      NULL;
    end;
  END sp_obt_doclet_arlcrd;
  
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
  ) AS 
  ln_nro_letras    NUMBER(3):=0;
  BEGIN
    BEGIN
      select COUNT(a.moneda)
      into   ln_nro_letras 
      from   arlcml a
      where  a.no_cia     = pc_no_cia        
        and  a.grupo      = pc_grupo         
        and  a.cod_oper   = pc_cod_oper_ori  
        and  a.no_cliente = pc_no_cliente    
        and  ((a.saldo     > 0) or (nvl(saldo,0) = 0 and a.ind_periodo_gracia = 'S'))
      GROUP BY a.moneda;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       pn_ret_esta := -1;
       pc_ret_mens := 'No existe registros'||sqlerrm;
       pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                            'SF_OBT_DOC_LETRAS',
                                            pc_cod_usua_web,
                                            'Error en la consulta',
                                            pc_ret_mens,
                                            pc_ret_mens);
   END;
  END sp_obt_doc_letras;
  
  Function sp_valida_doc_gast(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_cod_gasto      IN      arcctd.tipo%TYPE,
    pc_observ         OUT     arcctd.descripcion%TYPE,
    pc_tipo_mov       OUT     arcctd.tipo_mov%TYPE,
    pc_cod_usua_web   IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    pn_ret_esta       OUT     NUMBER,
    pc_ret_mens       OUT     VARCHAR2
  ) RETURN BOOLEAN IS
  lb_result        BOOLEAN := FALSE;
  lc_cod_gasto     arcctd.tipo%TYPE;
  BEGIN
    IF pc_cod_gasto IS NOT NULL THEN
     BEGIN
     SELECT tipo,descripcion,tipo_mov
       INTO lc_cod_gasto,pc_observ,pc_tipo_mov
       FROM arcctd a
      WHERE no_cia = pc_no_cia
        AND tipo = pc_cod_gasto
        AND tipo_mov = 'D'
        AND (clase_docu = 'D' 
              /*<I RQ38465> HHUANILO /27-08-2013/ Se Adiciona lval, para que tomar algunas facturas*/
              OR tipo IN (SELECT d.cod_valdet
                          FROM  gen_lval_det d
                          WHERE d.no_cia                = a.no_cia
                          AND   d.cod_val               = 'OPGTO'
                          AND   d.cod_valdet            = a.tipo
                          AND   NVL(d.ind_inactivo,'N') = 'N'
                         ) 
              );
        IF lc_cod_gasto = pc_cod_gasto THEN 
          lb_result := TRUE;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lb_result := FALSE;
          pn_ret_esta := -1;
          pc_ret_mens := 'No existe registros'||sqlerrm;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERR',
                                              'SF_VALIDA_DOC_GAST',
                                              pc_cod_usua_web,
                                              'Error en la consulta',
                                              pc_ret_mens,
                                              pc_ret_mens);

      END;
      RETURN lb_result;
    END IF;  
  END sp_valida_doc_gast;
  
  Procedure sp_eliminar_op(
    pc_no_cia         IN      vve_cred_soli.cod_empr%TYPE,
    pc_no_cliente     IN      vve_cred_soli.cod_clie%TYPE,
    pn_cod_oper       IN OUT  arlcop.cod_oper%TYPE,
    pc_tipo_cred      IN      vve_cred_soli.tip_soli_cred%TYPE
    ) as 
  begin
    null;
  end;
END PKG_SWEB_CRED_LXC; 