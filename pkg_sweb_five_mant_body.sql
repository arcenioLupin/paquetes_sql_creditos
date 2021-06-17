create or replace PACKAGE BODY VENTA.pkg_sweb_five_mant AS
  /******************************************************************************
     NAME:      PKG_SWEB_FIVE_MANT
     PURPOSE:   Contiene los procedimientos para la gestión de la ficha de venta.
     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        11/05/2017  PHRAMIREZ        Creación del package.
     1.1        08/08/2018  YGOMEZ           REQ RF86338 - Modificación
                --En esta versión se crean estas variables 'v_group,v_where,v_subWhere' para
                --optimizar la consulta de la Ficha de Venta por los siguientes filtros:
                --N° de Pedido, N° de Ficha de Venta y N° de Proforma.
     2.0        17/09/2018  ACRUZ            86531 - Erro FV duplicado      
  ******************************************************************************/

  k_val_s CONSTANT VARCHAR2(1) := 'S';
  /********************************************************************************
    Nombre:     SP_GRABAR_FICHA_VENTA
    Proposito:  Registra o modifica la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH        ---> Código de ficha de venta.
                P_COD_CIA                  ---> Código de compañia.
                P_VENDEDOR                 ---> Código del vendedor.
                P_COD_AREA_VTA             ---> Código del área de venta.
                P_COD_FILIAL               ---> Código de filial.
                P_COD_TIPO_FICHA_VTA_VEH   ---> Código de tipo de ficha de venta.
                P_COD_CLIE                 ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH        ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH ---> Código de moneda.
                P_COD_TIPO_PAGO            ---> Código de tipo de pago.
                P_COD_MONEDA_CRED          ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED     ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID             ---> Código del usuario.
                P_RET_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta generado.
                P_RET_ESTA                 ---> Estado del proceso.
                P_RET_MENS                 ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO
                                            P_COD_COLOR_VEH
                                            y se cambio USER por P_COD_USUA_SID en query                               
  ********************************************************************************/

  PROCEDURE sp_grabar_ficha_venta
  (
    p_num_ficha_vta_veh         IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR2, -- V2.0
    p_cod_color_veh             IN VARCHAR2, --V2.0
    p_ret_num_ficha_vta_veh     OUT vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_tem_mens     VARCHAR2(4000);
    v_tem_retu     NUMBER(10);
    v_des_area_vta gen_area_vta.des_area_vta%TYPE;
    v_cod_sucursal sistemas.usuarios_area_vta_filial.cod_sucursal%TYPE;
    v_nom_clie     v_perso_clie_pros.nom_clie%TYPE;
  BEGIN
    IF p_cod_cia IS NULL THEN
      p_ret_mens := 'Error, Ingrese la compañia';
      RAISE ve_error;
    END IF;

    IF p_vendedor IS NULL THEN
      p_ret_mens := 'Error, Ingrese el vendedor';
      RAISE ve_error;
    END IF;

    IF p_cod_area_vta IS NULL THEN
      p_ret_mens := 'Error, Ingrese el área de venta';
      RAISE ve_error;
    END IF;

    IF p_cod_area_vta IS NOT NULL THEN
      BEGIN
        SELECT b.des_area_vta
          INTO v_des_area_vta
          FROM usuarios_area_vta a, gen_area_vta b
         WHERE a.co_usuario = p_cod_usua_sid
           AND a.cod_area_vta = p_cod_area_vta
           AND nvl(a.ind_inactivo, 'N') = 'N'
           AND b.cod_area_vta = a.cod_area_vta
           AND nvl(b.ind_inactivo, 'N') = 'N';
      EXCEPTION
        WHEN no_data_found THEN
          p_ret_mens := 'Error el área de venta no existe o no se le ha asignado';
          RAISE ve_error;
      END;
    END IF;

    IF p_cod_filial IS NULL THEN
      p_ret_mens := 'Error, Ingrese la filial';
      RAISE ve_error;
    END IF;

    IF p_cod_filial IS NOT NULL THEN
      BEGIN
        SELECT a.cod_sucursal
          INTO v_cod_sucursal
          FROM sistemas.usuarios_area_vta_filial a, generico.gen_filiales b
         WHERE a.co_usuario = p_cod_usua_sid --USER v2.0
           AND a.cod_area_vta = p_cod_area_vta
           AND a.cod_filial = p_cod_filial
           AND nvl(a.ind_inactivo, 'N') = 'N'
           AND b.cod_filial = a.cod_filial;
      EXCEPTION
        WHEN no_data_found THEN
          p_ret_mens := 'Error la filial no existe o no se le ha asignado';
          RAISE ve_error;
      END;
    END IF;

    IF p_cod_tipo_ficha_vta_veh IS NULL THEN
      p_ret_mens := 'Error, Ingrese el tipo de ficha';
      RAISE ve_error;
    END IF;

    IF p_cod_clie IS NULL THEN
      p_ret_mens := 'Error, Ingrese el cliente';
      RAISE ve_error;
    END IF;

    BEGIN
      SELECT nom_clie
        INTO v_nom_clie
        FROM v_perso_clie_pros
       WHERE cod_clie = p_cod_clie;
      --        AND IND_REG = 'C';
    EXCEPTION
      WHEN no_data_found THEN
        p_ret_mens := 'Ingrese un cliente válido, el cliente ingresado no existe!';
        RAISE ve_error;
    END;

    IF p_cod_moneda_ficha_vta_veh IS NULL THEN
      p_ret_mens := 'Error, Ingrese la moneda de ficha de venta';
      RAISE ve_error;
    END IF;

    IF p_cod_tipo_pago IS NULL THEN
      p_ret_mens := 'Error, Ingrese el tipo de pago de ficha de venta';
      RAISE ve_error;
    END IF;

    IF p_cod_tipo_pago = 'P' THEN
      IF p_cod_moneda_cred IS NULL THEN
        p_ret_mens := 'Error, Ingrese la moneda de crédito de ficha de venta';
        RAISE ve_error;
      END IF;
      IF p_val_tipo_cambio_cred IS NULL THEN
        p_ret_mens := 'Error, Ingrese el tipo de cambio de crédito de ficha de venta';
        RAISE ve_error;
      END IF;
    END IF;

    IF p_num_ficha_vta_veh IS NULL THEN
      sp_inse_ficha_venta(p_cod_cia,
                          p_vendedor,
                          p_cod_area_vta,
                          p_cod_filial,
                          v_cod_sucursal,
                          p_cod_tipo_ficha_vta_veh,
                          p_cod_clie,
                          p_obs_ficha_vta_veh,
                          p_cod_moneda_ficha_vta_veh,
                          p_val_tipo_cambio_ficha_vta,
                          p_cod_tipo_pago,
                          p_cod_moneda_cred,
                          p_val_tipo_cambio_cred,
                          p_cod_usua_sid,
                          p_cod_avta_fam_uso, --V2.0
                          p_cod_color_veh, --V2.0
                          p_ret_num_ficha_vta_veh,
                          p_ret_esta,
                          p_ret_mens);
    ELSE
      sp_actu_ficha_venta(p_num_ficha_vta_veh,
                          p_cod_cia,
                          p_vendedor,
                          p_cod_area_vta,
                          p_cod_filial,
                          v_cod_sucursal,
                          p_cod_tipo_ficha_vta_veh,
                          p_cod_clie,
                          p_obs_ficha_vta_veh,
                          p_cod_moneda_ficha_vta_veh,
                          p_val_tipo_cambio_ficha_vta,
                          p_cod_tipo_pago,
                          p_cod_moneda_cred,
                          p_val_tipo_cambio_cred,
                          p_cod_usua_sid,
                          p_cod_avta_fam_uso, --V2.0
                          p_cod_color_veh, --V2.0
                          p_ret_esta,
                          p_ret_mens);
    END IF;

    IF p_ret_esta = -1 OR p_ret_esta = 0 THEN
      RAISE ve_error;
    END IF;

    p_ret_mens := 'La ficha de venta se guardo con exito';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GUARDAR_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al grabar la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GUARDAR_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GUARDAR_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al grabar la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
  END sp_grabar_ficha_venta;

  /********************************************************************************
    Nombre:     SP_INSE_FICHA_VENTA
    Proposito:  Insertar la ficha de venta.
    Referencias:
    Parametros: P_COD_CIA                  ---> Código de compañia.
                P_VENDEDOR                 ---> Código del vendedor.
                P_COD_AREA_VTA             ---> Código del área de venta.
                P_COD_FILIAL               ---> Código de filial.
                P_COD_TIPO_FICHA_VTA_VEH   ---> Código de tipo de ficha de venta.
                P_COD_CLIE                 ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH        ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH ---> Código de moneda.
                P_COD_TIPO_PAGO            ---> Código de tipo de pago.
                P_COD_MONEDA_CRED          ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED     ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID             ---> Código del usuario.
                P_RET_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta generado.
                P_RET_ESTA                 ---> Estado del proceso.
                P_RET_MENS                 ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO
                                            P_COD_COLOR_VEH
               16/02/2018   LAQS            REGISTRO DE EVENTOS NUR PADRE to_number(p_ret_num_ficha_vta_veh) || '.01'
  ********************************************************************************/

  PROCEDURE sp_inse_ficha_venta
  (
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_sucursal              IN vve_ficha_vta_veh.cod_sucursal%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR2, -- V2.0
    p_cod_color_veh             IN VARCHAR2, --V2.0
    p_ret_num_ficha_vta_veh     OUT vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_estado_inicial vve_ficha_vta_veh.cod_estado_ficha_vta_veh%TYPE := 'C';
    v_numero         NUMBER := 0;
  BEGIN
    BEGIN
      SELECT lpad(nvl(MAX(num_ficha_vta_veh), 0) + 1, 12, '0')
        INTO p_ret_num_ficha_vta_veh
        FROM venta.vve_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_num_ficha_vta_veh := '000000000001';
    END;

    --Registra ficha de venta
    INSERT INTO vve_ficha_vta_veh
      (cod_sucursal,
       cod_clie,
       val_tipo_cambio_ficha_vta,
       fec_crea_reg,
       obs_ficha_vta_veh,
       cod_moneda_cred,
       cod_tipo_ficha_vta_veh,
       val_tipo_cambio_cred,
       cod_area_vta,
       cod_tipo_pago,
       vendedor,
       cod_filial,
       co_usuario_crea_reg,
       fec_ficha_vta_veh,
       cod_cia,
       cod_moneda_ficha_vta_veh,
       num_ficha_vta_veh,
       cod_estado_ficha_vta_veh)
    VALUES
      (p_cod_sucursal,
       p_cod_clie,
       p_val_tipo_cambio_ficha_vta,
       SYSDATE,
       p_obs_ficha_vta_veh,
       p_cod_moneda_cred,
       p_cod_tipo_ficha_vta_veh,
       p_val_tipo_cambio_cred,
       p_cod_area_vta,
       p_cod_tipo_pago,
       p_vendedor,
       p_cod_filial,
       p_cod_usua_sid,
       TRUNC(SYSDATE),
       p_cod_cia,
       p_cod_moneda_ficha_vta_veh,
       p_ret_num_ficha_vta_veh,
       v_estado_inicial);

    --Registra estado inicial de ficha de venta
    BEGIN
      INSERT INTO venta.vve_ficha_vta_veh_estado
        (num_ficha_vta_veh,
         nur_ficha_vta_estado,
         cod_estado_ficha_vta,
         fec_estado_ficha_vta,
         obs_estado_ficha_vta,
         co_usuario_crea_reg,
         fec_crea_reg,
         ind_inactivo)
      VALUES
        (p_ret_num_ficha_vta_veh,
         1,
         v_estado_inicial,
         SYSDATE,
         'ESTADO INICIAL DE LA FICHA DE VENTA',
         p_cod_usua_sid,
         SYSDATE,
         'N');
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := '¡ Error en el Registro del Estado Inicial de la Ficha de Venta !';
        RAISE ve_error;
    END;

    --Registro de autorizaciones de ficha de venta
    BEGIN
      IF p_cod_tipo_pago = 'P' THEN
        --P CREDITO
        FOR i IN (SELECT *
                    FROM venta.vve_aut_ficha_vta
                   WHERE ind_aut_ficha_vta IN ('A', 'P')
                     AND nvl(ind_aut_ped, 'N') = 'N'
                     AND nvl(ind_inactivo, 'N') = 'N'
                   ORDER BY num_orden)
        LOOP
          v_numero := v_numero + 1;
          INSERT INTO venta.vve_ficha_vta_veh_aut
            (num_ficha_vta_veh,
             nur_aut_ficha_vta_veh,
             cod_aut_ficha_vta,
             num_orden,
             cod_aprob_ficha_vta_aut,
             co_usuario_crea_reg,
             fec_crea_reg,
             ind_inactivo)
          VALUES
            (p_ret_num_ficha_vta_veh,
             v_numero,
             i.cod_aut_ficha_vta,
             i.num_orden,
             NULL,
             p_cod_usua_sid,
             SYSDATE,
             'N');
        END LOOP;
      ELSE
        FOR i IN (SELECT *
                    FROM venta.vve_aut_ficha_vta
                   WHERE ind_aut_ficha_vta IN ('A')
                     AND nvl(ind_aut_ped, 'N') = 'N'
                     AND nvl(ind_inactivo, 'N') = 'N'
                   ORDER BY num_orden)
        LOOP
          v_numero := v_numero + 1;
          INSERT INTO venta.vve_ficha_vta_veh_aut
            (num_ficha_vta_veh,
             nur_aut_ficha_vta_veh,
             cod_aut_ficha_vta,
             num_orden,
             cod_aprob_ficha_vta_aut,
             co_usuario_crea_reg,
             fec_crea_reg,
             ind_inactivo)
          VALUES
            (p_ret_num_ficha_vta_veh,
             v_numero,
             i.cod_aut_ficha_vta,
             i.num_orden,
             NULL,
             USER,
             SYSDATE,
             'N');
        END LOOP;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := '¡ Error en el Registro de las Autorizaciones de la Ficha de Venta !';
        RAISE ve_error;
    END;

    --Registro de evento inicial de ficha de venta
    BEGIN
      INSERT INTO venta.vve_ficha_vta_veh_evento
        (num_ficha_vta_veh,
         nur_evento_ficha_vta,
         fec_evento_ficha_vta,
         des_evento_ficha_vta,
         txt_mensaje_evento,
         ind_tipo_evento,
         ind_envia_correo,
         co_usuario_envia,
         co_usuario_recibe,
         nur_evento_ficha_vta_padre,
         fec_prox_evento,
         co_usuario_crea_reg,
         fec_crea_reg,
         ind_inactivo)
      VALUES
        (p_ret_num_ficha_vta_veh,
         to_number(p_ret_num_ficha_vta_veh) || '.01',
         SYSDATE,
         'Creación de Ficha de Venta',
         'Ficha de Venta N° ' || lpad(p_ret_num_ficha_vta_veh, 12, '0'),
         '0',
         'N',
         p_cod_usua_sid,
         NULL,
         NULL, --< 86515 accion correctiva>-- to_number(p_ret_num_ficha_vta_veh) || '.01',
         NULL,
         p_cod_usua_sid,
         SYSDATE,
         'N');
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := '¡ Error en el Registro del Evento Raiz !';
        RAISE ve_error;
    END;

    COMMIT;

    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al insertar la ficha de venta',
                                          p_ret_mens,
                                          p_ret_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_INSE_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al insertar la ficha de venta',
                                          p_ret_mens,
                                          p_ret_num_ficha_vta_veh);
      ROLLBACK;
  END sp_inse_ficha_venta;

  /********************************************************************************
    Nombre:     SP_ACTU_FICHA_VENTA
    Proposito:  Actualizar la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_CIA                   ---> Código de compañia.
                P_VENDEDOR                  ---> Código del vendedor.
                P_COD_AREA_VTA              ---> Código del área de venta.
                P_COD_FILIAL                ---> Código de filial.
                P_COD_SUCURSAL              ---> Código de sucursal.
                P_COD_TIPO_FICHA_VTA_VEH    ---> Código de tipo de ficha de venta.
                P_COD_CLIE                  ---> Código del cliente.
                P_OBS_FICHA_VTA_VEH         ---> Observaciones en ficha de venta.
                P_COD_MONEDA_FICHA_VTA_VEH  ---> Código de moneda.
                P_VAL_TIPO_CAMBIO_FICHA_VTA ---> Valor de tipo de cambio.
                P_COD_TIPO_PAGO             ---> Código de tipo de pago.
                P_COD_MONEDA_CRED           ---> Código de moneda de crédito.
                P_VAL_TIPO_CAMBIO_CRED      ---> Valor de tipo de cambio de crédito.
                P_COD_USUA_SID              ---> Código del usuario.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        11/05/2017  PHRAMIREZ        Creación del procedure.
    2.0        14/06/2017  LVALDERRAMA      se agregaron campos
                                            P_COD_AVTA_FAM_USO
                                            P_COD_COLOR_VEH
  ********************************************************************************/

  PROCEDURE sp_actu_ficha_venta
  (
    p_num_ficha_vta_veh         IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia                   IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor                  IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta              IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial                IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_cod_sucursal              IN vve_ficha_vta_veh.cod_sucursal%TYPE,
    p_cod_tipo_ficha_vta_veh    IN vve_ficha_vta_veh.cod_tipo_ficha_vta_veh%TYPE,
    p_cod_clie                  IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_obs_ficha_vta_veh         IN vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE,
    p_cod_moneda_ficha_vta_veh  IN vve_ficha_vta_veh.cod_moneda_ficha_vta_veh%TYPE,
    p_val_tipo_cambio_ficha_vta IN vve_ficha_vta_veh.val_tipo_cambio_ficha_vta%TYPE,
    p_cod_tipo_pago             IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_cod_moneda_cred           IN vve_ficha_vta_veh.cod_moneda_cred%TYPE,
    p_val_tipo_cambio_cred      IN vve_ficha_vta_veh.val_tipo_cambio_cred%TYPE,
    p_cod_usua_sid              IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_avta_fam_uso          IN VARCHAR, -- V2.0
    p_cod_color_veh             IN VARCHAR, --V2.0
    p_ret_esta                  OUT NUMBER,
    p_ret_mens                  OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_correlativo INTEGER;
    v_cod_clie    vve_ficha_vta_veh.cod_clie%TYPE;
  BEGIN
    BEGIN
      SELECT cod_clie
        INTO v_cod_clie
        FROM venta.vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := '¡ No existe la ficha de venta !';
        RAISE ve_error;
    END;

    UPDATE vve_ficha_vta_veh
       SET cod_sucursal              = nvl(p_cod_sucursal, cod_sucursal),
           cod_clie                  = nvl(p_cod_clie, cod_clie),
           val_tipo_cambio_ficha_vta = nvl(p_val_tipo_cambio_ficha_vta,
                                           val_tipo_cambio_ficha_vta),
           obs_ficha_vta_veh         = nvl(p_obs_ficha_vta_veh,
                                           obs_ficha_vta_veh),
           cod_moneda_cred           = nvl(p_cod_moneda_cred,
                                           cod_moneda_cred),
           cod_tipo_ficha_vta_veh    = nvl(p_cod_tipo_ficha_vta_veh,
                                           cod_tipo_ficha_vta_veh),
           val_tipo_cambio_cred      = nvl(p_val_tipo_cambio_cred,
                                           val_tipo_cambio_cred),
           cod_area_vta              = nvl(p_cod_area_vta, cod_area_vta),
           cod_tipo_pago             = nvl(p_cod_tipo_pago, cod_tipo_pago),
           vendedor                  = nvl(p_vendedor, vendedor),
           cod_filial                = nvl(p_cod_filial, cod_filial),
           cod_cia                   = nvl(p_cod_cia, cod_cia),
           cod_moneda_ficha_vta_veh  = nvl(p_cod_moneda_ficha_vta_veh,
                                           cod_moneda_ficha_vta_veh)
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

    COMMIT;

    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al actualizar la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al actualizar la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
  END sp_actu_ficha_venta;

  /********************************************************************************
    Nombre:     SP_ACTU_ESTADO_FICHA_VENTA
    Proposito:  Actualizar el estado de la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_ESTADO_FICHA_VTA ---> Código del nuevo estado de la ficha de venta.
                P_OBS_ESTADO_FICHA_VTA ---> Observaciones acerca del cambio de estado.
                P_IND_DES              ---> Indicador de desasignación de pedido y proforma S=Si, N=No.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        12/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_actu_estado_ficha_venta
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_estado_ficha_vta IN vve_ficha_vta_veh.cod_estado_ficha_vta_veh%TYPE,
    p_obs_estado_ficha_vta IN vve_ficha_vta_veh_estado.obs_estado_ficha_vta%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR
  ) AS
    ve_error EXCEPTION;
    v_cod_estado_ficha_vta_veh vve_ficha_vta_veh.cod_estado_ficha_vta_veh%TYPE;
    v_numero_estado            NUMBER;
    v_num_reg                  NUMBER;
    v_acepta                   NUMBER;
    v_ret_cursor               SYS_REFCURSOR;
    v_can_pedi                 NUMBER;
    
    c_proformas_fv             SYS_REFCURSOR;
    v_query                    VARCHAR2(4000);
    v_num_prof                 VARCHAR2(20);  
    c_cod_solcre                SYS_REFCURSOR;
    v_query_cod_solcre          VARCHAR2(4000);
    v_cod_solcre                VARCHAR2(20);    
    v_correoori       usuarios.di_correo%TYPE;
    v_cont_solcre          INTEGER;
    v_cont_prof_fv         INTEGER; 
    v_cont_cod_solcre      INTEGER; 
    v_num_prof_veh         VARCHAR(200);
    v_cod_estado_solicred  VARCHAR(10);
    v_cod_soli_cred        VARCHAR(25);
    v_asunto_solcre        VARCHAR2(2000);
    v_mensaje_solcre       CLOB;
    v_html_head_solcre     VARCHAR2(2000);
    l_destinatarios_solcre vve_correo_prof.destinatarios%TYPE;
    l_proformas_fv         VARCHAR2(1000); 
    l_cod_solcre_fv        VARCHAR2(2000);
    v_cod_id_usuario  sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_cod_correo      vve_correo_prof.cod_correo_prof%TYPE;
    
  CURSOR c_enviar_mail_solcre IS
    SELECT DISTINCT a.txt_correo
        FROM sistemas.sis_mae_usuario a
       INNER JOIN sistemas.sis_mae_perfil_usuario b
          ON a.cod_id_usuario = b.cod_id_usuario
         AND b.ind_inactivo = 'N'
       INNER JOIN sistemas.sis_mae_perfil_procesos c
          ON b.cod_id_perfil = c.cod_id_perfil
         AND c.ind_inactivo = 'N'
       WHERE c.cod_id_procesos = 124
         AND c.cod_id_perfil IN ('1674694','1674690')
         AND txt_correo IS NOT NULL; 

  BEGIN
    IF p_cod_estado_ficha_vta IS NULL THEN
      p_ret_mens := '¡ Seleccione el Estado a Modificar !';
      RAISE ve_error;
    END IF;

    BEGIN
      SELECT f.cod_estado_ficha_vta_veh
        INTO v_cod_estado_ficha_vta_veh
        FROM venta.vve_ficha_vta_veh f
       WHERE f.num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        v_cod_estado_ficha_vta_veh := NULL;
    END;

    IF v_cod_estado_ficha_vta_veh = p_cod_estado_ficha_vta THEN
      p_ret_mens := '¡ El Nuevo Estado de la Ficha de Venta es igual al Estado Actual, Revise !';
      RAISE ve_error;
    END IF;

    IF upper(v_cod_estado_ficha_vta_veh) != 'I' THEN
      v_acepta := 1;

      IF upper(v_cod_estado_ficha_vta_veh) = 'V' THEN

        IF upper(p_cod_estado_ficha_vta) != 'C' THEN
          v_acepta := 1;
        ELSE
          v_acepta   := 0;
          p_ret_mens := '¡Un estado vigente no puede pasar a un estado creado, revise !';
        END IF;

      ELSIF upper(v_cod_estado_ficha_vta_veh) = 'E' THEN

        IF upper(p_cod_estado_ficha_vta) != 'C' THEN
          v_acepta := 1;
        ELSE
          v_acepta   := 0;
          p_ret_mens := '¡Un estado cerrado no puede pasar a un estado creado, revise !';
        END IF;

      END IF;
    ELSE
      p_ret_mens := 'La ficha de venta ya esta anulada y no se puede cambiar a ningun estado.';
      v_acepta   := 0;
    END IF;

    IF v_acepta = 0 THEN
      RAISE ve_error;
    ELSE
      IF upper(p_cod_estado_ficha_vta) = 'I' THEN
      
       --<I Req. 87567 E2.1 ID## avilca 19/01/2021>
    -- Preparando correo para usuarios de solictud de crédito
    --destinatarios SOLCRE
    
    -- Obteniendo la proformas de la ficha de venta
        v_cont_prof_fv := 1;
        v_query := 'SELECT num_prof_veh FROM vve_ficha_vta_proforma_veh WHERE num_ficha_vta_veh = '''||p_num_ficha_vta_veh||'''
                    AND ind_inactivo = ''N''';
                    
           OPEN c_proformas_fv FOR v_query;        
            LOOP
              FETCH c_proformas_fv
                INTO v_num_prof;
              EXIT WHEN c_proformas_fv%NOTFOUND;
            
                  IF (v_cont_prof_fv = 1) THEN
                    l_proformas_fv := l_proformas_fv || v_num_prof;
                  ELSE
                    l_proformas_fv := l_proformas_fv || ',' || v_num_prof;
                  END IF;
                  v_cont_prof_fv := v_cont_prof_fv + 1;
            END LOOP;
           CLOSE c_proformas_fv;
                    
   -- Obteniendo las solicitudes de las proformas
     
        v_cont_cod_solcre := 1;
        v_query_cod_solcre := 'SELECT cod_soli_cred FROM vve_cred_soli_prof WHERE num_prof_veh IN 
                                      (
                                       SELECT num_prof_veh FROM vve_ficha_vta_proforma_veh WHERE num_ficha_vta_veh = '''||p_num_ficha_vta_veh||'''
                                        AND ind_inactivo = ''N''
                                   )';
                    
           OPEN c_cod_solcre FOR v_query_cod_solcre;
            LOOP
              FETCH c_cod_solcre
                INTO v_cod_solcre;
              EXIT WHEN c_cod_solcre%NOTFOUND;
            
                  IF (v_cont_cod_solcre = 1) THEN
                    l_cod_solcre_fv := l_cod_solcre_fv || LTRIM(v_cod_solcre,'0');
                  ELSE
                    l_cod_solcre_fv := l_cod_solcre_fv || ',' || LTRIM(v_cod_solcre,'0');
                  END IF;
                  v_cont_cod_solcre := v_cont_cod_solcre + 1;
            END LOOP;
            CLOSE c_cod_solcre;   
      --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo, a.cod_id_usuario
        INTO v_correoori, v_cod_id_usuario
        FROM sistemas.sis_mae_usuario a
       WHERE a.txt_usuario = p_cod_usua_sid;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
    
    -- Destinatarios             
    v_cont_solcre := 1;
    FOR c_mail_solcre IN c_enviar_mail_solcre
    LOOP
      IF (v_cont_solcre = 1) THEN
        l_destinatarios_solcre := l_destinatarios_solcre || c_mail_solcre.txt_correo;
      ELSE
        l_destinatarios_solcre := l_destinatarios_solcre || ',' || c_mail_solcre.txt_correo;
      END IF;
      v_cont_solcre := v_cont_solcre + 1;

    END LOOP;
    
    -- Estructura de correo para solicitud de crédito
    
        BEGIN
              SELECT ax.txt_asun_pla, ax.txt_cabe_pla, ax.txt_deta_pla
                INTO v_asunto_solcre, v_html_head_solcre, v_mensaje_solcre
                FROM sis_maes_plan ax
               WHERE ax.cod_plan_reg = 7
                 AND nvl(ax.ind_inac_pla, 'N') = 'N';
         EXCEPTION
          WHEN no_data_found THEN
            v_asunto_solcre    := NULL;
            v_html_head_solcre := NULL;
            v_mensaje_solcre   := NULL;
          WHEN OTHERS THEN
            v_mensaje_solcre   := NULL;
            v_html_head_solcre := NULL;
            v_asunto_solcre   := NULL;
         END;
         
        v_asunto_solcre := REPLACE(v_asunto_solcre, '#ficha_vta#', p_num_ficha_vta_veh);
          
        v_mensaje_solcre := v_html_head_solcre || v_mensaje_solcre;
        
        v_mensaje_solcre := logistica_web.pkg_correo_log.replace_clob(v_mensaje_solcre,
                                                           '#ficha_vta#',
                                                           p_num_ficha_vta_veh);
                                                           
        v_mensaje_solcre := logistica_web.pkg_correo_log.replace_clob(v_mensaje_solcre,
                                                           '#proformas_fv#',
                                                           l_proformas_fv);  
                                                           
        v_mensaje_solcre := logistica_web.pkg_correo_log.replace_clob(v_mensaje_solcre,
                                                           '#codsolcre#',
                                                           l_cod_solcre_fv);                                                             
                                                           
    SELECT VVE_CORREO_PROF_SQ01.NEXTVAL INTO V_COD_CORREO FROM DUAL;

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       LTRIM(p_num_ficha_vta_veh,'0'), --P_COD_PLAN_ENTR_VEHI,
       'SE',
       l_destinatarios_solcre,
       NULL,
       v_asunto_solcre,
       v_mensaje_solcre,
       v_correoori,
       'N',
       'N',
       SYSDATE,
       v_cod_id_usuario);                                                       
                                                           
      --<F Req. 87567 E2.1 ID## avilca 04/11/2020>
      
 
        SELECT COUNT(1)
          INTO v_can_pedi
          FROM vve_ficha_vta_pedido_veh p
         WHERE p.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND nvl(p.ind_inactivo, 'N') = 'N';
        IF v_can_pedi > 0 THEN
          p_ret_mens := 'La FV tiene pedidos asignados. Debe desasignar los pedidos para poder Anular la FV.';
          RAISE ve_error;
        ELSE
          UPDATE venta.vve_ficha_vta_proforma_veh
             SET ind_inactivo        = 'S',
                 co_usuario_inactiva = USER,
                 fec_inactiva        = SYSDATE
           WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
        END IF;
      END IF;

      SELECT nvl(MAX(nur_ficha_vta_estado), 0) + 1
        INTO v_numero_estado
        FROM venta.vve_ficha_vta_veh_estado
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

      INSERT INTO venta.vve_ficha_vta_veh_estado
        (num_ficha_vta_veh,
         nur_ficha_vta_estado,
         cod_estado_ficha_vta,
         fec_estado_ficha_vta,
         obs_estado_ficha_vta,
         co_usuario_crea_reg,
         fec_crea_reg,
         ind_inactivo)
      VALUES
        (p_num_ficha_vta_veh,
         v_numero_estado,
         p_cod_estado_ficha_vta,
         SYSDATE,
         p_obs_estado_ficha_vta,
         p_cod_usua_sid,
         SYSDATE,
         'N');
      UPDATE venta.vve_ficha_vta_veh
         SET cod_estado_ficha_vta_veh = p_cod_estado_ficha_vta
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
      COMMIT;
      p_ret_mens := 'La actualización se realizo con exito';
    END IF;

    p_ret_esta := 1;
    
  

  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_ESTADO_FICHA_VENTA.',
                                          p_cod_usua_sid,
                                          'Actualiza estado de FV',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_ESTADO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_ESTADO_FICHA_VENTA..',
                                          p_cod_usua_sid,
                                          'Actualiza estado de FV',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
  END sp_actu_estado_ficha_venta;

  /********************************************************************************
    Nombre:     SP_OBTE_ESTADO_FICHA_VENTA
    Proposito:  Obtener el estado de la ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_DES_ESTA         ---> Descripción del estado.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_obte_estado_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cod_esta      OUT vve_estado_ficha_vta.cod_estado_ficha_vta%TYPE,
    p_ret_des_esta      OUT vve_estado_ficha_vta.des_estado_ficha_vta%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN
    SELECT b.cod_estado_ficha_vta, b.des_estado_ficha_vta
      INTO p_ret_cod_esta, p_ret_des_esta
      FROM venta.vve_ficha_vta_veh a
     INNER JOIN venta.vve_estado_ficha_vta b
        ON b.cod_estado_ficha_vta = a.cod_estado_ficha_vta_veh
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizo con exito';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTE_ESTADO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al consultar el estado la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_OBTE_ESTADO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTE_ESTADO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al consultar el estado la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_obte_estado_ficha_venta;

  /********************************************************************************
    Nombre:     SP_ANUL_FICHA_VENTA
    Proposito:  Anular ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_OBS_ESTADO_FICHA_VTA ---> Observaciones acerca del cambio de estado.
                P_IND_DES              ---> Indicador de desasignación de pedido y proforma S=Si, N=No.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
    1.1        19/07/2017  LVALDERRAMA      Modificación.
  ********************************************************************************/

  PROCEDURE sp_anul_ficha_venta
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_obs_estado_ficha_vta IN vve_ficha_vta_veh_estado.obs_estado_ficha_vta%TYPE,
    p_ind_des              IN CHAR,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_ncont         NUMBER;
    v_numero_estado NUMBER;
  BEGIN
    IF p_ind_des = 'N' THEN
      SELECT COUNT(1)
        INTO v_ncont
        FROM venta.vve_ficha_vta_pedido_veh a
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND nvl(a.ind_inactivo, 'N') = 'N';

      IF v_ncont > 0 THEN
        p_ret_mens := 'La Ficha de Venta no puede ser anulada por que tiene pedidos asignados .. Verifique';
        RAISE ve_error;
      END IF;
    END IF;

    IF p_ind_des = 'S' THEN
      BEGIN
        UPDATE venta.vve_ficha_vta_proforma_veh
           SET ind_inactivo        = 'S',
               co_usuario_inactiva = p_cod_usua_sid,
               fec_inactiva        = SYSDATE
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

        FOR i IN (SELECT p.cod_cia, p.cod_prov, p.num_pedido_veh
                    FROM venta.vve_pedido_veh           p,
                         venta.vve_ficha_vta_pedido_veh f
                   WHERE p.cod_cia = f.cod_cia
                     AND p.cod_prov = f.cod_prov
                     AND p.num_pedido_veh = f.num_pedido_veh
                     AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
                     AND nvl(f.ind_inactivo, 'N') = 'N')
        LOOP
          --Desasigno pedido
          UPDATE venta.vve_pedido_veh
             SET num_prof_veh              = NULL,
                 cod_clie                  = NULL,
                 cod_propietario_veh       = NULL,
                 cod_usuario_veh           = NULL,
                 vendedor                  = NULL,
                 cod_estado_pedido_veh     = 'A',
                 cod_moneda_vta_pedido_veh = decode(ind_nuevo_usado,
                                                    'N',
                                                    NULL,
                                                    cod_moneda_vta_pedido_veh),
                 val_vta_pedido_veh        = decode(ind_nuevo_usado,
                                                    'N',
                                                    NULL,
                                                    val_vta_pedido_veh)
           WHERE cod_cia = i.cod_cia
             AND cod_prov = i.cod_prov
             AND num_pedido_veh = i.num_pedido_veh;

          DELETE FROM venta.vve_pedido_equipo_local_veh
           WHERE cod_cia = i.cod_cia
             AND cod_prov = i.cod_prov
             AND num_pedido_veh = i.num_pedido_veh;

          DELETE FROM venta.vve_pedido_equipo_esp_adic
           WHERE cod_cia = i.cod_cia
             AND cod_prov = i.cod_prov
             AND num_pedido_veh = i.num_pedido_veh;

          DELETE FROM venta.vve_pedido_equipo_esp_veh
           WHERE cod_cia = i.cod_cia
             AND cod_prov = i.cod_prov
             AND num_pedido_veh = i.num_pedido_veh;
        END LOOP;

        UPDATE venta.vve_ficha_vta_pedido_veh
           SET ind_inactivo        = 'S',
               co_usuario_inactiva = p_cod_usua_sid,
               fec_inactiva        = SYSDATE
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
        p_ret_esta := 1;
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_mens := '¡Error en la desasignación de pedidos de la ficha de venta !';
          RAISE ve_error;
      END;
    END IF;

    IF ((p_ind_des = 'N' AND v_ncont = 0) OR p_ret_esta = 1) THEN
      BEGIN
        SELECT nvl(MAX(nur_ficha_vta_estado), 0) + 1
          INTO v_numero_estado
          FROM venta.vve_ficha_vta_veh_estado
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

        INSERT INTO venta.vve_ficha_vta_veh_estado
          (num_ficha_vta_veh,
           nur_ficha_vta_estado,
           cod_estado_ficha_vta,
           fec_estado_ficha_vta,
           obs_estado_ficha_vta,
           co_usuario_crea_reg,
           fec_crea_reg,
           ind_inactivo)
        VALUES
          (p_num_ficha_vta_veh,
           v_numero_estado,
           'I',
           SYSDATE,
           p_obs_estado_ficha_vta,
           p_cod_usua_sid,
           SYSDATE,
           'N');
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_mens := '¡Error en la anulación de la Ficha de Venta !';
          RAISE ve_error;
      END;

      UPDATE venta.vve_ficha_vta_veh
         SET cod_estado_ficha_vta_veh = 'I'
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

      COMMIT;

      p_ret_esta := 1;
      p_ret_mens := 'La anulación se realizo con exito';
    END IF;

  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ANUL_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al anular la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ANUL_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ANUL_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al anular la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
  END sp_anul_ficha_venta;

  /********************************************************************************
    Nombre:     SP_VALI_ACCESO_FICHA_VENTA
    Proposito:  Validar el acceso a una ficha de venta existente.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_vali_acceso_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    vn_count1      NUMBER;
    vn_count2      NUMBER;
    vn_count3      NUMBER;
    v_cod_area_vta vve_ficha_vta_veh.cod_area_vta%TYPE;
    v_des_area_vta gen_area_vta.des_area_vta%TYPE;
    v_cod_filial   vve_ficha_vta_veh.cod_filial%TYPE;
    v_vendedor     vve_ficha_vta_veh.vendedor%TYPE;
    v_descripcion  arccve.descripcion%TYPE;
    v_cod_clie     vve_ficha_vta_veh.cod_clie%TYPE;
    v_nom_perso    gen_persona.nom_perso%TYPE;
    v_nom_filial   gen_filiales.nom_filial%TYPE;
    v_existe_fv    NUMBER;
  BEGIN
    --Evalúa el número de Ficha de Venta
    BEGIN
      SELECT COUNT(1)
        INTO vn_count1
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        vn_count1 := 0;
    END;

    IF vn_count1 = 0 THEN
      p_ret_mens := 'El número de Ficha no existe.';
      RAISE ve_error;
    END IF;

    --Usuarios por Area de Venta
    BEGIN
      SELECT COUNT(1)
        INTO vn_count1
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND EXISTS
       (SELECT 1
                FROM usuarios_area_vta x
               WHERE x.cod_area_vta = vve_ficha_vta_veh.cod_area_vta
                 AND x.co_usuario = p_cod_usua_sid
                 AND nvl(x.ind_inactivo, 'N') = 'N');
    EXCEPTION
      WHEN OTHERS THEN
        vn_count1 := 0;
    END;

    IF vn_count1 = 0 THEN
      BEGIN
        SELECT a.cod_area_vta, b.des_area_vta
          INTO v_cod_area_vta, v_des_area_vta
          FROM vve_ficha_vta_veh a, gen_area_vta b
         WHERE a.cod_area_vta = b.cod_area_vta
           AND a.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND rownum = 1;
      EXCEPTION
        WHEN OTHERS THEN
          v_cod_area_vta := NULL;
          v_des_area_vta := NULL;
      END;

      IF v_cod_area_vta IS NOT NULL THEN
        p_ret_mens := 'El usuario no tiene acceso al área de venta: ' ||
                      v_des_area_vta || '.';
        RAISE ve_error;
      END IF;
    END IF;

    --Usuarios por Area de Venta - Filial
    --Criterio 1
    BEGIN
      SELECT COUNT(1)
        INTO vn_count1
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND EXISTS
       (SELECT 1
                FROM usuarios_area_vta_filial x1
               WHERE x1.cod_area_vta = vve_ficha_vta_veh.cod_area_vta
                 AND x1.cod_filial = vve_ficha_vta_veh.cod_filial
                 AND x1.co_usuario = p_cod_usua_sid
                 AND nvl(x1.ind_inactivo, 'N') = 'N');
    EXCEPTION
      WHEN OTHERS THEN
        vn_count1 := 0;
    END;

    --Criterio 2
    BEGIN
      SELECT COUNT(1)
        INTO vn_count2
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND vve_ficha_vta_veh.vendedor IN
             (SELECT y.vendedor
                FROM arccve_acceso y
               WHERE y.co_usuario = p_cod_usua_sid
                 AND nvl(y.ind_inactivo, 'N') = 'N');
    EXCEPTION
      WHEN OTHERS THEN
        vn_count2 := 0;
    END;

    --Criterio 3
    BEGIN
      SELECT COUNT(1)
        INTO vn_count3
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND EXISTS (SELECT 1
                FROM gen_perso_vendedor pv, arccve_acceso q
               WHERE pv.cod_perso = vve_ficha_vta_veh.cod_clie
                 AND pv.vendedor = q.vendedor
                 AND nvl(pv.ind_inactivo, 'N') = 'N'
                 AND q.co_usuario = p_cod_usua_sid
                 AND nvl(q.ind_inactivo, 'N') = 'N');
    EXCEPTION
      WHEN OTHERS THEN
        vn_count3 := 0;
    END;

    IF (vn_count1 = 0 OR vn_count2 = 0) AND vn_count3 = 0 THEN
      BEGIN
        SELECT a.cod_clie, b.nom_perso
          INTO v_cod_clie, v_nom_perso
          FROM vve_ficha_vta_veh a, gen_persona b
         WHERE a.cod_clie = b.cod_perso
           AND a.num_ficha_vta_veh = p_num_ficha_vta_veh;
      EXCEPTION
        WHEN OTHERS THEN
          v_cod_clie  := NULL;
          v_nom_perso := NULL;
      END;

      IF vn_count1 = 0 THEN
        BEGIN
          SELECT a.cod_area_vta, a.cod_filial, b.des_area_vta, c.nom_filial
            INTO v_cod_area_vta, v_cod_filial, v_des_area_vta, v_nom_filial
            FROM vve_ficha_vta_veh a, gen_area_vta b, gen_filiales c
           WHERE a.cod_area_vta = b.cod_area_vta
             AND a.cod_filial = c.cod_filial
             AND a.num_ficha_vta_veh = p_num_ficha_vta_veh;
        EXCEPTION
          WHEN OTHERS THEN
            v_cod_area_vta := NULL;
            v_cod_filial   := NULL;
        END;

        IF v_cod_area_vta IS NOT NULL THEN
          p_ret_mens := 'El usuario no tiene acceso al Área/Filial: ' ||
                        chr(13) || v_des_area_vta || ' / ' || v_nom_filial || '.';
          RAISE ve_error;
        END IF;
      END IF;

      IF vn_count2 = 0 THEN
        BEGIN
          SELECT a.vendedor, b.descripcion
            INTO v_vendedor, v_descripcion
            FROM vve_ficha_vta_veh a, arccve b
           WHERE a.vendedor = b.vendedor
             AND a.num_ficha_vta_veh = p_num_ficha_vta_veh;
        EXCEPTION
          WHEN OTHERS THEN
            v_vendedor    := NULL;
            v_descripcion := NULL;
        END;

        IF v_vendedor IS NOT NULL THEN
          p_ret_mens := 'El usuario no tiene acceso al Vendedor: ' ||
                        v_descripcion || '.';
          RAISE ve_error;
        END IF;
      END IF;
    END IF;

    BEGIN
      SELECT COUNT(1)
        INTO v_existe_fv
        FROM vve_ficha_vta_veh a
       WHERE a.num_ficha_vta_veh = lpad(p_num_ficha_vta_veh, 12, '0')
         AND EXISTS
       (SELECT 1
                FROM usuarios_area_vta x
               WHERE x.cod_area_vta = a.cod_area_vta
                 AND x.co_usuario = p_cod_usua_sid
                 AND nvl(x.ind_inactivo, 'N') = 'N')
         AND ((EXISTS (SELECT 1
                         FROM usuarios_area_vta_filial x1
                        WHERE x1.cod_area_vta = a.cod_area_vta
                          AND x1.cod_filial = a.cod_filial
                          AND x1.co_usuario = p_cod_usua_sid
                          AND nvl(x1.ind_inactivo, 'N') = 'N') AND
              a.vendedor IN
              (SELECT y.vendedor
                         FROM arccve_acceso y
                        WHERE y.co_usuario = p_cod_usua_sid
                          AND nvl(y.ind_inactivo, 'N') = 'N')) OR
             (EXISTS (SELECT 1
                         FROM gen_perso_vendedor pv, arccve_acceso q
                        WHERE pv.cod_perso = a.cod_clie
                          AND pv.vendedor = q.vendedor
                          AND nvl(pv.ind_inactivo, 'N') = 'N'
                          AND q.co_usuario = p_cod_usua_sid
                          AND nvl(q.ind_inactivo, 'N') = 'N')));

    EXCEPTION
      WHEN no_data_found THEN
        v_existe_fv := 0;
    END;

    IF nvl(v_existe_fv, 0) = 0 THEN
      p_ret_mens := 'No esta autorizado para visualizar la ficha de venta de otro usuario';
      RAISE ve_error;
    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizo con exito';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_ACCESO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al validar acceso a la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_VALI_ACCESO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_ACCESO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error al validar acceso a la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_vali_acceso_ficha_venta;

  PROCEDURE sp_vali_acceso_usuario_crm
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_user_crm          IN VARCHAR2,
    p_cod_clie_sap      IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_ind_crm  CHAR(2);
    v_ruta     VARCHAR2(100);
    v_cod_clie cxc_mae_clie.cod_clie%TYPE;
  BEGIN

    BEGIN
      SELECT lvd.des_valdet
        INTO v_ind_crm
        FROM gen_lval lv, gen_lval_det lvd
       WHERE lv.no_cia = lvd.no_cia
         AND lv.cod_val = lvd.cod_val
         AND lvd.cod_valdet = 'FICVTA'
         AND lv.cod_val = 'LEGA_CRM';
    EXCEPTION
      WHEN no_data_found THEN
        v_ind_crm := 'NO';
    END;

    BEGIN
      SELECT lvd.des_valdet
        INTO v_ruta
        FROM gen_lval lv, gen_lval_det lvd
       WHERE lv.no_cia = lvd.no_cia
         AND lv.cod_val = lvd.cod_val
         AND lvd.cod_valdet = 'REPORT'
         AND lv.cod_val = 'LEGA_CRM';
    EXCEPTION
      WHEN no_data_found THEN
        v_ruta := NULL;
    END;

    IF p_num_ficha_vta_veh IS NOT NULL AND p_user_crm IS NOT NULL AND
       nvl(v_ind_crm, 'NO') = 'SI' THEN
      IF p_cod_clie_sap IS NOT NULL AND nvl(v_ind_crm, 'NO') = 'SI' THEN
        BEGIN
          SELECT cod_clie
            INTO v_cod_clie
            FROM cxc_mae_clie
           WHERE cod_clie_sap IS NOT NULL
             AND cod_clie_sap = p_cod_clie_sap;
        EXCEPTION
          WHEN no_data_found THEN
            p_ret_mens := 'Cliente SAP-CRM no registrado en el SID.';
            RAISE ve_error;
          WHEN too_many_rows THEN
            p_ret_mens := 'Cliente SAP-CRM duplicado en el SID.';
            RAISE ve_error;
        END;
      END IF;
    ELSIF p_num_ficha_vta_veh IS NOT NULL AND p_user_crm IS NOT NULL AND
          nvl(v_ind_crm, 'NO') = 'NO' THEN
      p_ret_mens := 'No se encuentra habilitado la opcion SAP-CRM.';
      RAISE ve_error;
    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizo con exito';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_ACCESO_USUARIO_CRM',
                                          p_cod_usua_sid,
                                          'Error al validar acceso a usuario CRM',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_VALI_ACCESO_USUARIO_CRM:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_ACCESO_USUARIO_CRM',
                                          p_cod_usua_sid,
                                          'Error al validar acceso a usuario CRM',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_vali_acceso_usuario_crm;

  /********************************************************************************
    Nombre:     SP_ENV_LAFIT
    Proposito:  Se envia solicitud para la revisión de información del cliente por lavado de activos.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH    ---> Código de ficha de venta.
                P_COD_USUA_SID         ---> Código del usuario.
                P_RET_ESTA             ---> Estado del proceso.
                P_RET_MENS             ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        15/05/2017  PHRAMIREZ        Creación del procedure.
    1.1        20/07/2017  LVALDERRAMA      modificacion
  ********************************************************************************/

  PROCEDURE sp_env_lafit
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_observacion       IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_mail          VARCHAR2(50);
    v_asunto        VARCHAR2(150);
    v_mensaje       VARCHAR2(5500);
    v_nombre        VARCHAR2(300);
    v_status_correo NUMBER(1);
    v_correo_user   usuarios.di_correo%TYPE;
    v_destinatarios VARCHAR2(1000);
    v_cod_clie      vve_ficha_vta_veh.cod_clie%TYPE;
    v_nom_perso     gen_persona.nom_perso%TYPE;
    v_des_area_vta  gen_area_vta.des_area_vta%TYPE;
    v_nom_filial    gen_filiales.nom_filial%TYPE;
    CURSOR vc_usu IS
      SELECT DISTINCT a.txt_correo
        FROM sistemas.sis_mae_usuario a
       INNER JOIN sistemas.sis_mae_perfil_usuario b
          ON a.cod_id_usuario = b.cod_id_usuario
         AND b.ind_inactivo = 'N'
       INNER JOIN sistemas.sis_mae_perfil_procesos c
          ON b.cod_id_perfil = c.cod_id_perfil
         AND c.ind_inactivo = 'N'
       WHERE c.cod_id_procesos = 66
         AND txt_correo IS NOT NULL;

  BEGIN
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'SP_ENV_LAFIT',
                                        p_cod_usua_sid,
                                        'Ingreso',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    IF p_num_ficha_vta_veh IS NOT NULL THEN
      SELECT f.cod_clie, p.nom_perso, a.des_area_vta, g.nom_filial
        INTO v_cod_clie, v_nom_perso, v_des_area_vta, v_nom_filial
        FROM vve_ficha_vta_veh f,
             gen_persona       p,
             gen_area_vta      a,
             gen_filiales      g
       WHERE f.cod_clie = p.cod_perso
         AND f.cod_filial = g.cod_filial
         AND f.cod_area_vta = a.cod_area_vta
         AND f.num_ficha_vta_veh = p_num_ficha_vta_veh;

      v_asunto  := 'Pedido de Informe Lavado de Activo  : Ficha  ' ||
                   p_num_ficha_vta_veh;
      v_mensaje := v_mensaje || '<table style="FONT: 8pt Arial">
        <tr>
        <td><b>Cliente</b></td>
        <td>' || ':</td><td>' || v_cod_clie || ' - ' ||
                   v_nom_perso || '</td>
        </tr>
        <tr>
        <td><b> </b></td>
        <td>' || ':</td><td>' || v_des_area_vta || ' - ' ||
                   v_nom_filial || '</td>
        </tr>
        <tr>
        <td valign="top"><b>Comentario</b></td>
        <td valign="top">' || ':' || p_observacion ||
                   '</td>
        <td>' || 'Favor revisar información del cliente' ||
                   '</td>
        </tr>
        </table>';
      v_mensaje := '<table cellpadding=10 width=100% style="clear:both; margin:0.5em auto; border:2px solid #E5D4A1;font: 12px Arial;"><tr><td>' ||
                   v_mensaje || '</td></tr></table>';
      v_mensaje := v_mensaje ||
                   '<br><br><font size="1" color="#FF0000">NOTA: Este mensaje ha sido autogenerado por el Sistema.</font><BR>';
      v_mail    := NULL;

      BEGIN
        SELECT di_correo, initcap(nombre1 || ' ' || paterno)
          INTO v_mail, v_nombre
          FROM usuarios
         WHERE co_usuario = p_cod_usua_sid;
      EXCEPTION
        WHEN no_data_found THEN
          p_ret_mens := 'Error, El usuario ' || p_cod_usua_sid ||
                        ', No Tiene una cuenta de Correo Electrónico';
          RAISE ve_error;
      END;

      FOR i IN vc_usu
      LOOP
        --generico.sp_pkg_enviar_correo.set_to_address(I.DI_CORREO,I.des_usuario);
        v_destinatarios := v_destinatarios || i.txt_correo || ',';
      END LOOP;
    END IF;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'SP_ENV_LAFIT',
                                        p_cod_usua_sid,
                                        'Antes de fin' || v_destinatarios,
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);

    p_ret_esta := 1;
    p_ret_mens := 'La solicitud se realizo con exito';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ENV_LAFIT',
                                          p_cod_usua_sid,
                                          'Error al enviar solicitud',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ENV_LAFIT:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ENV_LAFIT',
                                          p_cod_usua_sid,
                                          'Error al enviar solicitud',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_env_lafit;

  /********************************************************************************
    Nombre:     SP_LIST_FICHA_VENTA
    Propósito:  Búsqueda de fichas de venta.
    Referencias:
    Parámetros: P_COD_CIA                   ---> Código de Compañia.
                P_COD_AREA_VTA              ---> Código de Área de Venta.
                P_COD_FILIAL                ---> Código de Filial.
                P_COD_VENDEDOR              ---> Código de Vendedor.
                P_COD_CLAUSULA_COMPRA       ---> Código de Clausula de Compra.
                P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_TIPO_FICHA_VTA_VEH    ---> Código de tipo de ficha de venta.
                P_COD_TIPO_PAGO             ---> Código de tipo de pago.
                P_COD_MONEDA_FICHA_VTA_VEH  ---> Código de moneda de ficha de venta.
                P_COD_MONEDA_CRED           ---> Código de moneda de credito.
                P_COD_CLIE                  ---> Código de cliente.
                P_COD_FAMILIA_VEH           ---> Código de familia vehicular.
                P_COD_MARCA                 ---> Código de marca de vehiculo.
                P_COD_BAUMUSTER             ---> Código de modelo de vehiculo.
                P_COD_CONFIG_VEH            ---> Código de configuración.
                P_COD_ESTADO_FICHA_VTA_VEH  ---> Código de estado de ficha de venta.
                P_FEC_FICHA_VTA_VEH_INI     ---> Fecha inicial de busqueda.
                P_FEC_FICHA_VTA_VEH_FIN     ---> Fecha final de busqueda.
                P_NUM_PROF_VEH              ---> Código de proforma.
                P_NUM_PEDIDO_VEH            ---> Código de pedido.
                P_IND_INACTIVO              ---> Indicador de estado del registro S-Inactivo, N-Activo
                P_COD_ADQUISICION           ---> Código de adquisicion
                P_COD_USUA_SID              ---> Código del usuario.
                P_LIMITINF                  ---> Límite inicial de registros.
                P_LIMITSUP                  ---> Límite final de registros.
                P_RET_CURSOR                ---> Resultado de la busqueda.
                P_RET_CANTIDAD              ---> Cantidad total de registros.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.
    REVISIONES:
    Versión    Fecha       Autor            Descripción
    ---------  ----------  ---------------  ------------------------------------
    1.0        16/05/2017  PHRAMIREZ        Creación del procedure.
    1.1        10/07/2017  LVALDERRAMA      Modificación
    1.2        29/09/2017  LVALDERRAMA      Modificación
    1.3        08/08/2018  YGOMEZ           REQ RF86338 - Modificación
    1.4        02/01/2019  JMORENO          REQ 86298 - Modificación
    --En esta versión se crean estas variables 'v_group,v_where,v_subWhere' para
    --optimizar la consulta de la Ficha de Venta por los siguientes filtros:
	  --N° de Pedido, N° de Ficha de Venta y N° de Proforma.
    REQ-87227 Se dividió el armado del query para poder sacar el universo de fichas
    de venta antes de realizar todas la uniones.
  ********************************************************************************/
  PROCEDURE sp_list_ficha_venta
  (
    p_cod_cia                  IN VARCHAR2,
    p_cod_area_vta             IN VARCHAR2,
    p_cod_filial               IN VARCHAR2,
    p_cod_vendedor             IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_clausula_compra      IN VARCHAR2, --<REQ.86298>
    p_num_ficha_vta_veh        IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_tipo_ficha_vta_veh   IN VARCHAR2,
    p_cod_tipo_pago            IN VARCHAR2,
    p_cod_moneda_ficha_vta_veh IN VARCHAR2,
    p_cod_moneda_cred          IN VARCHAR2,
    p_cod_clie                 IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_familia_veh          IN VARCHAR2,
    p_cod_marca                IN vve_proforma_veh_det.cod_marca%TYPE,
    p_cod_baumuster            IN vve_proforma_veh_det.cod_baumuster%TYPE,
    p_cod_config_veh           IN vve_proforma_veh_det.cod_config_veh%TYPE,
    p_cod_estado_ficha_vta_veh IN VARCHAR2,
    p_fec_ficha_vta_veh_ini    IN VARCHAR2,
    p_fec_ficha_vta_veh_fin    IN VARCHAR2,
    p_num_prof_veh             IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh           IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_inactivo             IN vve_ficha_vta_veh_aut.ind_inactivo%TYPE,
    p_cod_adquisicion          IN VARCHAR2,
    p_cod_zona                 IN VARCHAR2,
    p_fech_cierre_ini          IN VARCHAR2,
    p_fech_cierre_fin          IN VARCHAR2,
    p_cod_usua_sid             IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado             IN VARCHAR2,
    p_limitinf                 IN VARCHAR2,
    p_limitsup                 IN INTEGER,
    p_nom_perso                IN generico.gen_persona.nom_perso%TYPE,
    p_ret_cursor               OUT SYS_REFCURSOR,
    p_ret_cantidad             OUT NUMBER,
    p_ret_esta                 OUT NUMBER,
    p_ret_mens                 OUT VARCHAR2,
    p_cod_sku                  IN vve_pedido_veh.sku_sap%TYPE DEFAULT NULL
  ) AS
    ve_error EXCEPTION;
    v_estado_vta     VARCHAR2(1);
    v_query          VARCHAR2(10000);
    v_group          VARCHAR2(10000); -- variable que contiene el group by del query
    v_where          VARCHAR2(10000); -- variable que contiene el where del query final
    v_subwhere       VARCHAR2(10000); -- variable que contiene una subparte del where
    v_order          VARCHAR2(10000);
    v_final          VARCHAR2(30000); --<Req.86298>
    v_ind_vendedores NUMBER;
  BEGIN
    v_estado_vta := 'E';
    v_query      := 'SELECT DISTINCT FVF1.*
                     FROM (
                        SELECT FVF.NUM_FICHA_VTA_VEH,
                          FVF.FEC_CREA_REG,
                          FVF.COD_FILIAL,
                          FVF.FEC_FICHA_VTA_VEH,
                          FVF.COD_ESTADO_FICHA_VTA_VEH,
                          FVF.COD_CLIE,
                          FVF.COD_MONEDA_CRED,
                          FVF.COD_MONEDA_FICHA_VTA_VEH,
                          FVF.COD_TIPO_PAGO,
                          FVF.COD_TIPO_FICHA_VTA_VEH,
                          FVF.VENDEDOR,
                          FVF.COD_AREA_VTA,
                          FVF.COD_CIA,
                          FVF.FEC_ENTREGA_APROX,
                          FVF.VAL_TIPO_CAMBIO_CRED,
                          FVF.OBS_FICHA_VTA_VEH,
                          FVF.CO_USUARIO_CREA_REG,
                          FVF.VAL_TIPO_CAMBIO_FICHA_VTA,
                          FVF.COD_SUCURSAL,
                          DECODE(FVF.COD_MONEDA_FICHA_VTA_VEH, ''SOL'', ''SOLES'', ''DOLARES'') DES_MONEDA_FICHA_VTA_VEH,
                          A.COD_ADQUISICION,
                          A.DES_ADQUISICION,
                          O.COD_TIPO_PERSO,
                          DECODE(O.COD_TIPO_PERSO, ''J'', ''Jurídica'', ''Natural'') DES_TIPO_PERSO,
                          O.NUM_RUC,
                          O.NUM_DOCU_IDEN,
                          O.NUM_TELF_MOVIL,
                          O.COD_AREA_TELF_MOVIL,
                          O.NOM_PERSO,
                          PD.COD_MARCA,
                          PD.COD_FAMILIA_VEH,
                          D.DES_ESTADO_FICHA_VTA,
                          TP.DES_TIPO_PAGO,
                          V.DESCRIPCION,
                          T.DES_TIPO_FICHA_VTA_VEH,
                          G.DES_AREA_VTA,
                          L.NOM_FILIAL,
                          S.NOM_SUCURSAL,
                          C.NOMBRE,
                          SP_FUN_CLAUS_COMP_FICHA(FVF.NUM_FICHA_VTA_VEH) CLAUS_COMP,
                          P.SKU_SAP
                        FROM VENTA.VVE_FICHA_VTA_VEH FVF
                          INNER JOIN CXC.ARCCVE V
                          ON FVF.VENDEDOR=V.VENDEDOR
                          INNER JOIN GENERICO.GEN_SUCURSALES S
                          ON FVF.COD_SUCURSAL=S.COD_SUCURSAL
                          INNER JOIN VENTA.ARFAMC C
                          ON FVF.COD_CIA=C.NO_CIA
                          INNER JOIN GENERICO.GEN_FILIALES L
                          ON FVF.COD_FILIAL=L.COD_FILIAL
                          INNER JOIN GENERICO.GEN_AREA_VTA G
                          ON FVF.COD_AREA_VTA=G.COD_AREA_VTA
                          INNER JOIN VENTA.VVE_TIPO_FICHA_VTA_VEH T
                          ON FVF.COD_TIPO_FICHA_VTA_VEH=T.COD_TIPO_FICHA_VTA_VEH
                          INNER JOIN VENTA.VVE_ESTADO_FICHA_VTA D
                          ON FVF.COD_ESTADO_FICHA_VTA_VEH=D.COD_ESTADO_FICHA_VTA
                          INNER JOIN GENERICO.GEN_PERSONA O
                          ON FVF.COD_CLIE=O.COD_PERSO
                          INNER JOIN VENTA.VVE_TIPO_PAGO TP
                          ON FVF.COD_TIPO_PAGO=TP.COD_TIPO_PAGO
                          LEFT OUTER JOIN VENTA.VVE_FICHA_VTA_PROFORMA_VEH FP
                          ON FVF.NUM_FICHA_VTA_VEH = FP.NUM_FICHA_VTA_VEH
                          LEFT OUTER JOIN VENTA.VVE_PROFORMA_VEH_DET PD
                          ON FP.NUM_PROF_VEH = PD.NUM_PROF_VEH
                          LEFT OUTER JOIN VENTA.VVE_FICHA_VTA_PEDIDO_VEH FPV
                          ON FPV.NUM_FICHA_VTA_VEH = FVF.NUM_FICHA_VTA_VEH AND FPV.IND_INACTIVO = ''N''
                          LEFT OUTER JOIN VVE_PEDIDO_VEH P
                          --ON FPV.NUM_PEDIDO_VEH = P.NUM_PEDIDO_VEH --<86338>
                          ON (FPV.NUM_PEDIDO_VEH = P.NUM_PEDIDO_VEH AND FPV.COD_CIA  = p.cod_cia AND FPV.COD_PROV = p.cod_prov )--<86338>
                          LEFT OUTER JOIN VVE_ADQUISICION A
                          ON P.COD_ADQUISICION_PEDIDO_VEH = A.COD_ADQUISICION';
    --<I-RF86338>
    v_subwhere := ' WHERE 1=1 AND';
    --<F-RF86338>

    --<I-RF86338>
    v_group := ' GROUP BY
                                FVF.NUM_FICHA_VTA_VEH,
                                FVF.FEC_CREA_REG,
                                FVF.COD_FILIAL,
                                FVF.FEC_FICHA_VTA_VEH,
                                FVF.COD_ESTADO_FICHA_VTA_VEH,
                                FVF.COD_CLIE,
                                FVF.COD_MONEDA_CRED,
                                FVF.COD_MONEDA_FICHA_VTA_VEH,
                                FVF.COD_TIPO_PAGO,
                                FVF.COD_TIPO_FICHA_VTA_VEH,
                                FVF.VENDEDOR,
                                FVF.COD_AREA_VTA,
                                FVF.COD_CIA,
                                FVF.FEC_ENTREGA_APROX,
                                FVF.VAL_TIPO_CAMBIO_CRED,
                                FVF.OBS_FICHA_VTA_VEH,
                                FVF.CO_USUARIO_CREA_REG,
                                FVF.VAL_TIPO_CAMBIO_FICHA_VTA,
                                FVF.COD_SUCURSAL,
                                A.COD_ADQUISICION,
                                A.DES_ADQUISICION,
                                O.COD_TIPO_PERSO,
                                O.NUM_RUC,
                                O.NUM_DOCU_IDEN,
                                O.NUM_TELF_MOVIL,
                                O.COD_AREA_TELF_MOVIL,
                                O.NOM_PERSO,
                                PD.COD_MARCA,
                                PD.COD_FAMILIA_VEH,
                                D.DES_ESTADO_FICHA_VTA,
                                TP.DES_TIPO_PAGO,
                                V.DESCRIPCION,
                                T.DES_TIPO_FICHA_VTA_VEH,
                                G.DES_AREA_VTA,
                                L.NOM_FILIAL,
                                S.NOM_SUCURSAL,
                                C.NOMBRE,
                                P.SKU_SAP
                     ) FVF1
                     left JOIN vve_ficha_vta_proforma_veh a ON A.NUM_FICHA_VTA_VEH=FVF1.NUM_FICHA_VTA_VEH
                     left JOIN vve_proforma_veh b
                              ON a.num_prof_veh = b.num_prof_veh
                     left JOIN vve_proforma_veh_det c
                              ON a.num_prof_veh = c.num_prof_veh
                     WHERE 1=1 AND ';
    --<F-RF86338>

    SELECT COUNT(1)
      INTO v_ind_vendedores
      FROM sis_view_usua_porg a
     WHERE a.txt_usuario = p_cod_usua_sid
       AND a.ind_acceso_vendedores = 'S';

    --Fecha de Cierre
    IF p_fech_cierre_ini IS NULL AND p_fech_cierre_fin IS NOT NULL THEN
      p_ret_mens := 'Debe ingresar fecha inicial del rango de consulta para Fecha de cierre.';
      RAISE ve_error;
    END IF;

    IF p_fech_cierre_ini IS NOT NULL AND p_fech_cierre_fin IS NULL THEN
      p_ret_mens := 'Debe ingresar fecha final del rango de consulta para Fecha de cierre.';
      RAISE ve_error;
    END IF;

    IF p_nom_perso IS NOT NULL THEN
      v_where := v_where || ' FVF1.NOM_PERSO LIKE ''%' || upper(p_nom_perso) ||
                 '%'' AND ';
    END IF;

    IF p_cod_adquisicion IS NOT NULL THEN
      v_where := v_where ||
                 ' EXISTS (SELECT 1 FROM VENTA.VVE_FICHA_VTA_PEDIDO_VEH FP, VENTA.VVE_PEDIDO_VEH P, VENTA.VVE_ADQUISICION A
                             WHERE FP.NUM_FICHA_VTA_VEH = FVF1.NUM_FICHA_VTA_VEH AND FP.IND_INACTIVO = ''N'' AND
                                   FP.NUM_PEDIDO_VEH = P.NUM_PEDIDO_VEH and FP.cod_cia = P.cod_cia and FP.cod_prov = P.cod_prov AND
                                   P.COD_ADQUISICION_PEDIDO_VEH = A.COD_ADQUISICION AND
                                   FVF1.COD_ADQUISICION IN (' ||
                 p_cod_adquisicion || ')) AND ';
    END IF;

    IF p_cod_zona IS NOT NULL THEN
      v_where := v_where ||
                 ' EXISTS (SELECT 1 FROM VENTA.VVE_MAE_ZONA_FILIAL VMZF WHERE  FVF1.COD_FILIAL = VMZF.COD_FILIAL AND VMZF.COD_ZONA IN (' ||
                 p_cod_zona || ')) AND ';
    END IF;

    IF p_cod_cia IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_CIA IN (' || p_cod_cia || ') AND ';
    END IF;

    IF p_cod_area_vta IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_AREA_VTA IN (' || p_cod_area_vta ||
                 ') AND ';
    END IF;

    IF p_cod_filial IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_FILIAL IN (' || p_cod_filial ||
                 ') AND ';
    END IF;

    IF p_cod_vendedor IS NOT NULL THEN
      v_where := v_where || ' FVF1.VENDEDOR = ''' || p_cod_vendedor ||
                 ''' AND ';
    END IF;

    IF p_cod_clausula_compra IS NOT NULL THEN
      v_where := v_where || ' FVF1.CLAUS_COMP IN (' || p_cod_clausula_compra ||
                 ') --<Req.86298> AND ';
    END IF;

    IF p_num_ficha_vta_veh IS NOT NULL THEN
      --v_where := v_where || ' FVF.NUM_FICHA_VTA_VEH LIKE ''%' || p_num_ficha_vta_veh || ''' AND ';
      v_where := v_where || ' FVF1.NUM_FICHA_VTA_VEH = '|| 'trim(LPAD('''||p_num_ficha_vta_veh||''',12,''0'')) AND ';--<86338>
    END IF;

    IF p_cod_tipo_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_TIPO_FICHA_VTA_VEH IN (' ||
                 p_cod_tipo_ficha_vta_veh || ') AND ';
    END IF;

    IF p_cod_tipo_pago IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_TIPO_PAGO IN (' || p_cod_tipo_pago ||
                 ') AND ';
    END IF;

    IF p_cod_moneda_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_MONEDA_FICHA_VTA_VEH IN (' ||
                 p_cod_moneda_ficha_vta_veh || ') AND ';
    END IF;

    IF p_cod_moneda_cred IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_MONEDA_CRED IN (' ||
                 p_cod_moneda_cred || ') AND ';
    END IF;

    IF p_cod_clie IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_CLIE = ''' || p_cod_clie || ''' AND ';
    END IF;

    IF p_cod_familia_veh IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_FAMILIA_VEH IN (' ||
                 p_cod_familia_veh || ') AND ';
    END IF;

    IF p_cod_marca IS NOT NULL THEN
      v_where := v_where || ' FVF1.COD_MARCA IN (' || p_cod_marca ||
                 ') AND ';
    END IF;

    IF p_cod_baumuster IS NOT NULL THEN
      v_where := v_where || ' FVF1.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH F,
        VENTA.VVE_PROFORMA_VEH P,
        VENTA.VVE_PROFORMA_VEH_DET PD ' ||
                 ' WHERE F.NUM_PROF_VEH=P.NUM_PROF_VEH
          AND P.NUM_PROF_VEH=PD.NUM_PROF_VEH
          AND PD.COD_BAUMUSTER=''' || p_cod_baumuster ||
                 ''') AND ';
    END IF;

    /*REQ-86298*/
    IF p_cod_sku IS NOT NULL THEN
      v_where := v_where || ' FVF1.SKU_SAP = ''' || p_cod_sku || ''' AND ';
    END IF;
    /*REQ-86298*/

    IF p_cod_config_veh IS NOT NULL THEN
      v_where := v_where || ' FVF1.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH F,
        VENTA.VVE_PROFORMA_VEH P,
        VENTA.VVE_PROFORMA_VEH_DET PD ' ||
                 ' WHERE F.NUM_PROF_VEH=P.NUM_PROF_VEH
          AND P.NUM_PROF_VEH=PD.NUM_PROF_VEH
          AND PD.COD_CONFIG_VEH=''' || p_cod_config_veh ||
                 ''') AND ';
    END IF;

    IF p_fec_ficha_vta_veh_ini IS NOT NULL AND p_num_prof_veh IS NULL AND
       p_num_ficha_vta_veh IS NULL AND p_num_pedido_veh IS NULL THEN
      v_where := v_where ||
                 ' (FVF1.FEC_FICHA_VTA_VEH) >= TRUNC( TO_DATE(''' ||
                 p_fec_ficha_vta_veh_ini || ''', ''DD/MM/YYYY'')) AND ';
    END IF;

    IF p_fec_ficha_vta_veh_fin IS NOT NULL AND p_num_prof_veh IS NULL AND
       p_num_ficha_vta_veh IS NULL AND p_num_pedido_veh IS NULL THEN
      v_where := v_where ||
                 ' (FVF1.FEC_FICHA_VTA_VEH) <= TRUNC( TO_DATE(''' ||
                 p_fec_ficha_vta_veh_fin || ''', ''DD/MM/YYYY'')) AND ';
    END IF;

    IF p_num_prof_veh IS NOT NULL THEN
      --<I-RF86338>
      v_subwhere := v_subwhere ||
                    ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH O ' ||
                    ' WHERE O.NUM_FICHA_VTA_VEH=NUM_FICHA_VTA_VEH
          AND O.NUM_PROF_VEH=''' || p_num_prof_veh || '''
          /* I - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
          /*AND NVL(O.IND_INACTIVO,''N'')=''N'') AND*/ 
          AND (O.IND_INACTIVO IS NULL OR O.IND_INACTIVO = ''N'')) AND ';
         /* F - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
      --<F-RF86338>
    END IF;

    IF p_num_pedido_veh IS NOT NULL THEN
      --<I-RF86338>
      v_subwhere := v_subwhere ||
                    ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PEDIDO_VEH P ' ||
                    ' WHERE P.NUM_FICHA_VTA_VEH=NUM_FICHA_VTA_VEH
          AND P.NUM_PEDIDO_VEH=''' || p_num_pedido_veh || '''
          /* I - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
          /*AND NVL(P.IND_INACTIVO,''N'')=''N'') AND*/
          AND (P.IND_INACTIVO IS NULL OR P.IND_INACTIVO = ''N'')) AND ';
          /* F - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
      --<F-RF86338>
    END IF;

    IF p_cod_estado_ficha_vta_veh IS NOT NULL THEN
      --<I-RF86338>
      v_subwhere := v_subwhere || ' FVF.COD_ESTADO_FICHA_VTA_VEH IN (' ||
                    p_cod_estado_ficha_vta_veh || ')';
	--<I-86298>
    ELSIF p_num_pedido_veh IS NOT NULL OR p_num_prof_veh IS NOT NULL THEN
      v_subwhere := v_subwhere || ' 1=1';
    ELSE
    --<F-86298>
      v_subwhere := ' WHERE 1=1';
      --<F-RF86338>
    END IF;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_BUSQUEDA_WHERE',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_where,
                                        NULL);

    IF p_fech_cierre_ini IS NOT NULL AND p_fech_cierre_fin IS NOT NULL THEN

      v_where := v_where ||
                 ' EXISTS(SELECT 1
                           FROM VVE_FICHA_VTA_VEH_ESTADO VVE
                           WHERE VVE.NUM_FICHA_VTA_VEH=FVF1.NUM_FICHA_VTA_VEH
                             AND VVE.COD_ESTADO_FICHA_VTA= ''' ||
                 v_estado_vta ||
                 ''' AND TRUNC(VVE.FEC_ESTADO_FICHA_VTA) >= TRUNC( TO_DATE(''' ||
                 p_fech_cierre_ini ||
                 ''', ''DD/MM/YYYY'' )) AND TRUNC(VVE.FEC_ESTADO_FICHA_VTA) <= TRUNC( TO_DATE(''' ||
                 p_fech_cierre_fin || ''', ''DD/MM/YYYY'' )) ) AND ';
    END IF;
 
    v_where := v_where ||
               ' EXISTS (SELECT 1 FROM sis_view_usua_marca UM WHERE UM.cod_area_vta = B.COD_AREA_VTA AND UM.cod_familia_veh = C.COD_FAMILIA_VEH AND UM.cod_marca = C.COD_MARCA AND UM.txt_usuario=''' ||p_cod_usua_sid || ''') ';

    v_where := v_where || '
          and  EXISTS(select 1 from sis_view_usua_filial uf where uf.cod_filial = fvf1.cod_filial AND uf.txt_usuario=''' || p_cod_usua_sid || ''') ';
    --<F 87227>
    IF v_ind_vendedores = 0 THEN
      v_where := v_where ||
                 'AND (FVF1.VENDEDOR IN (SELECT Y.VENDEDOR FROM ARCCVE_ACCESO Y WHERE Y.CO_USUARIO = ''' ||
                 p_cod_usua_sid ||
                 /* I - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                 ''' AND (Y.IND_INACTIVO IS NULL OR Y.IND_INACTIVO = ''N''))
                     /*AND NVL(Y.IND_INACTIVO, ''N'') = ''N'')*/
                 /* F - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                        OR
                        EXISTS(
                      SELECT 1 FROM gen_perso_vendedor pv, arccve_acceso q
                      WHERE pv.cod_perso = FVF1.cod_clie
                        AND pv.vendedor  = q.vendedor
                        /* I - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                        AND (PV.IND_INACTIVO IS NULL OR PV.IND_INACTIVO = ''N'')
                        /*AND nvl(pv.ind_inactivo,''N'') = ''N''*/
                        /* F - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                        AND Q.CO_USUARIO = ''' ||
                 p_cod_usua_sid || '''
                        /* I - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                        AND (Q.IND_INACTIVO IS NULL OR Q.IND_INACTIVO = ''N'')
                        /*AND NVL(Q.IND_INACTIVO, ''N'') = ''N''*/
                        /* F - SOPORTE LEGADOS - se elimina NVL que ocaciona alto consumo de CPU */
                      )    ) ';

    END IF;

    --<I-RF86338>
    v_query := v_query || v_subwhere || v_group || v_where;
    --<F-RF86338>

    v_order := ' ORDER BY FVF1.FEC_CREA_REG DESC ';
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_BUSQUEDA',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_query,
                                        NULL);

    EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM (' || v_query || ')'
      INTO p_ret_cantidad;

    v_query := v_query || v_order;

    v_final := v_query;

    IF nvl(p_ind_paginado, 'S') = 'S' THEN
      v_final := 'SELECT ROWNUM RM, QY.* FROM (' || v_query ||
                 ') QY
                  WHERE ROWNUM <= ' || p_limitsup || '';
      v_final := 'SELECT /*+ FIRST_ROWS */ distinct /*86487 Problema con varias marcas */ PG.NUM_FICHA_VTA_VEH,
                    PG.NUM_FICHA_VTA_VEH,
                    PG.VENDEDOR,
                    PG.DESCRIPCION,
                    PG.COD_TIPO_FICHA_VTA_VEH,
                    PG.DES_TIPO_FICHA_VTA_VEH,
                    PG.COD_CIA,
                    PG.NOMBRE,
                    PG.COD_AREA_VTA,
                    PG.DES_AREA_VTA,
                    PG.COD_SUCURSAL,
                    PG.NOM_SUCURSAL,
                    PG.COD_FILIAL,
                    PG.NOM_FILIAL,
                    PG.FEC_FICHA_VTA_VEH,
                    PG.COD_CLIE,
                    PG.NOM_PERSO,
                    PG.COD_MONEDA_FICHA_VTA_VEH,
                    PG.VAL_TIPO_CAMBIO_FICHA_VTA,
                    PG.COD_ESTADO_FICHA_VTA_VEH,
                    PG.DES_ESTADO_FICHA_VTA,
                    PG.CO_USUARIO_CREA_REG,
                    PG.FEC_CREA_REG,
                    PG.OBS_FICHA_VTA_VEH,
                    PG.COD_TIPO_PAGO,
                    PG.DES_TIPO_PAGO,
                    PG.COD_MONEDA_CRED,
                    PG.VAL_TIPO_CAMBIO_CRED,
                    PG.FEC_ENTREGA_APROX,
                    PG.COD_ADQUISICION,
                    PG.DES_MONEDA_FICHA_VTA_VEH,
                    PG.COD_TIPO_PERSO,
                    PG.DES_TIPO_PERSO,
                    PG.NUM_RUC,
                    PG.NUM_DOCU_IDEN,
                    PG.NUM_TELF_MOVIL,
                    PG.COD_AREA_TELF_MOVIL,
                    --PG.COD_MARCA,/*86531 comenta linea*/ /*86487 Problema con varias marcas */
                    null cod_marca, --<86531>
                    PG.COD_FAMILIA_VEH,
                    PG.DES_ADQUISICION,
                    SP_FUN_NRO_PROF_FICHA_VTA(PG.NUM_FICHA_VTA_VEH) NRO_PROF,
                    SP_FUN_NRO_PEDIDO_FICHA_VTA(PG.NUM_FICHA_VTA_VEH) PED_ASIG,
                    SP_FUN_PEDIDO_FACT_FICHA_VTA(PG.NUM_FICHA_VTA_VEH) PED_FACT,
                    SP_FUN_ESTADO_PEDIDO_FICHA_VTA(PG.NUM_FICHA_VTA_VEH,''E'') PED_ENTR,
                    PG.CLAUS_COMP,
                    SP_FUN_CLAUS_COMP_DES_FICHA(PG.NUM_FICHA_VTA_VEH) CLAUS_COMP_DES
                  FROM (' || v_final ||
                 ') PG
                  WHERE RM >= ' || p_limitinf || '';
    END IF;
    OPEN p_ret_cursor FOR v_final;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_LIST_FICHA_VENTA',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_final,
                                        NULL);

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realiz¿ de manera exitosa';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_cantidad := 0;
        p_ret_esta     := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

  END sp_list_ficha_venta;

  PROCEDURE sp_list_ficha_venta_reporte
  (
    p_cod_cia                  IN VARCHAR2,
    p_cod_area_vta             IN VARCHAR2,
    p_cod_filial               IN VARCHAR2,
    p_cod_vendedor             IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_clausula_compra      IN vve_pedido_veh.cod_clausula_compra%TYPE,
    p_num_ficha_vta_veh        IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_tipo_ficha_vta_veh   IN VARCHAR2,
    p_cod_tipo_pago            IN VARCHAR2,
    p_cod_moneda_ficha_vta_veh IN VARCHAR2,
    p_cod_moneda_cred          IN VARCHAR2,
    p_cod_clie                 IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_familia_veh          IN VARCHAR2,
    p_cod_marca                IN vve_proforma_veh_det.cod_marca%TYPE,
    p_cod_baumuster            IN vve_proforma_veh_det.cod_baumuster%TYPE,
    p_cod_config_veh           IN vve_proforma_veh_det.cod_config_veh%TYPE,
    p_cod_estado_ficha_vta_veh IN VARCHAR2,
    p_fec_ficha_vta_veh_ini    IN VARCHAR2,
    p_fec_ficha_vta_veh_fin    IN VARCHAR2,
    p_num_prof_veh             IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh           IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_inactivo             IN vve_ficha_vta_veh_aut.ind_inactivo%TYPE,
    p_cod_adquisicion          IN VARCHAR2,
    p_cod_zona                 IN VARCHAR2,
    p_fech_cierre_ini          IN VARCHAR2,
    p_fech_cierre_fin          IN VARCHAR2,
    p_cod_usua_sid             IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado             IN VARCHAR2,
    p_limitinf                 IN VARCHAR2,
    p_limitsup                 IN INTEGER,
    p_nom_perso                IN generico.gen_persona.nom_perso%TYPE,
    p_ret_cursor               OUT SYS_REFCURSOR,
    p_ret_cantidad             OUT NUMBER,
    p_ret_esta                 OUT NUMBER,
    p_ret_mens                 OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_estado_vta     VARCHAR2(1);
    v_query          VARCHAR2(10000);
    v_where          VARCHAR2(10000);
    v_order          VARCHAR2(10000);
    v_final          VARCHAR2(10000);
    v_ind_vendedores NUMBER;
  BEGIN

    v_estado_vta := 'E';
    v_query      := 'SELECT DISTINCT  FVF.*
                     FROM (
                        SELECT FVF.NUM_FICHA_VTA_VEH,
                          FVF.FEC_CREA_REG,
                          FVF.COD_FILIAL,
                          FVF.FEC_FICHA_VTA_VEH,
                          FVF.COD_ESTADO_FICHA_VTA_VEH,
                          FVF.COD_CLIE,
                          FVF.COD_MONEDA_CRED,
                          FVF.COD_MONEDA_FICHA_VTA_VEH,
                          FVF.COD_TIPO_PAGO,
                          FVF.COD_TIPO_FICHA_VTA_VEH,
                          FVF.VENDEDOR,
                          FVF.COD_AREA_VTA,
                          FVF.COD_CIA,
                          FVF.FEC_ENTREGA_APROX,
                          FVF.VAL_TIPO_CAMBIO_CRED,
                          FVF.OBS_FICHA_VTA_VEH,
                          FVF.CO_USUARIO_CREA_REG,
                          FVF.VAL_TIPO_CAMBIO_FICHA_VTA,
                          FVF.COD_SUCURSAL,
                          DECODE(FVF.COD_MONEDA_FICHA_VTA_VEH, ''SOL'', ''SOLES'', ''DOLARES'') DES_MONEDA_FICHA_VTA_VEH,
                          A.COD_ADQUISICION,
                          A.DES_ADQUISICION,
                          O.COD_TIPO_PERSO,
                          DECODE(O.COD_TIPO_PERSO, ''J'', ''Jurídica'', ''Natural'') DES_TIPO_PERSO,
                          O.NUM_RUC,
                          O.NUM_DOCU_IDEN,
                          O.NUM_TELF_MOVIL,
                          O.COD_AREA_TELF_MOVIL,
                          O.NOM_PERSO,
                          PD.COD_MARCA,
                          PD.COD_FAMILIA_VEH,
                          D.DES_ESTADO_FICHA_VTA,
                          TP.DES_TIPO_PAGO,
                          V.DESCRIPCION,
                          T.DES_TIPO_FICHA_VTA_VEH,
                          G.DES_AREA_VTA,
                          L.NOM_FILIAL,
                          S.NOM_SUCURSAL,
                          C.NOMBRE,
                          SP_FUN_CLAUS_COMP_FICHA(FVF.NUM_FICHA_VTA_VEH) CLAUS_COMP,
                        SP_FUN_NRO_PROF_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) NRO_PROF,
                        SP_FUN_NRO_PEDIDO_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) PED_ASIG,
                        SP_FUN_PEDIDO_FACT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) PED_FACT,
                        SP_FUN_ESTADO_PEDIDO_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''E'') PED_ENTR,
                        SP_FUN_CLAUS_COMP_DES_FICHA(FVF.NUM_FICHA_VTA_VEH) CLAUS_COMP_DES,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''01'') AUT_VEND,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''02'') AUT_JEFE,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''09'') AUT_GER,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''12'') AUT_GCOM,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''04'') AUT_USAD,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''07'') AUT_EESP,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''05'') AUT_SEG,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''08'') AUT_CRED,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''06'') AUT_ASIG,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''03'') AUT_CLIE,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''10'') AUT_FACT,
                        SP_FUN_AUT_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH,''11'') AUT_ENTR,
                        SP_FUN_COD_ULTAUT_FICHA(FVF.NUM_FICHA_VTA_VEH) COD_ULT_AUT,
                        SP_FUN_DES_ULTAUT_FICHA(FVF.NUM_FICHA_VTA_VEH) DES_ULT_AUT,
                        SP_FUN_USU_ULTAUT_FICHA(FVF.NUM_FICHA_VTA_VEH) USU_ULT_AUT,
                        SP_FUN_FEC_ULTAUT_FICHA(FVF.NUM_FICHA_VTA_VEH) FEC_ULT_AUT,
                        pkg_sweb_five_mant.SP_FUN_STR_PROF_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) PROFORMA,
                        pkg_sweb_five_mant.SP_FUN_STR_PEDIDO_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) PEDIDO,
                        pkg_sweb_five_mant.SP_FUN_STR_MARCA_FICHA_VTA(FVF.NUM_FICHA_VTA_VEH) MARCA,
                        ''-''  CONFIGURACION
                        FROM VENTA.VVE_FICHA_VTA_VEH FVF
                          INNER JOIN CXC.ARCCVE V
                          ON FVF.VENDEDOR=V.VENDEDOR
                          INNER JOIN GENERICO.GEN_SUCURSALES S
                          ON FVF.COD_SUCURSAL=S.COD_SUCURSAL
                          INNER JOIN VENTA.ARFAMC C
                          ON FVF.COD_CIA=C.NO_CIA
                          INNER JOIN GENERICO.GEN_FILIALES L
                          ON FVF.COD_FILIAL=L.COD_FILIAL
                          INNER JOIN GENERICO.GEN_AREA_VTA G
                          ON FVF.COD_AREA_VTA=G.COD_AREA_VTA
                          INNER JOIN VENTA.VVE_TIPO_FICHA_VTA_VEH T
                          ON FVF.COD_TIPO_FICHA_VTA_VEH=T.COD_TIPO_FICHA_VTA_VEH
                          INNER JOIN VENTA.VVE_ESTADO_FICHA_VTA D
                          ON FVF.COD_ESTADO_FICHA_VTA_VEH=D.COD_ESTADO_FICHA_VTA
                          INNER JOIN GENERICO.GEN_PERSONA O
                          ON FVF.COD_CLIE=O.COD_PERSO
                          INNER JOIN VENTA.VVE_TIPO_PAGO TP
                          ON FVF.COD_TIPO_PAGO=TP.COD_TIPO_PAGO
                          LEFT OUTER JOIN VENTA.VVE_FICHA_VTA_PROFORMA_VEH FP
                          ON FVF.NUM_FICHA_VTA_VEH = FP.NUM_FICHA_VTA_VEH
                          LEFT OUTER JOIN VENTA.V_FICHA_VTA_VEH_AUT FVA
                          ON FVF.NUM_FICHA_VTA_VEH = FVA.NUM_FICHA_VTA_VEH                          
                          LEFT OUTER JOIN VENTA.VVE_PROFORMA_VEH_DET PD
                          ON FP.NUM_PROF_VEH = PD.NUM_PROF_VEH
                          LEFT OUTER JOIN VENTA.VVE_FICHA_VTA_PEDIDO_VEH FPV
                          ON FPV.NUM_FICHA_VTA_VEH = FVF.NUM_FICHA_VTA_VEH AND FPV.IND_INACTIVO = ''N''
                          LEFT OUTER JOIN VVE_PEDIDO_VEH P
                          ON FPV.NUM_PEDIDO_VEH = P.NUM_PEDIDO_VEH
                          LEFT OUTER JOIN VVE_ADQUISICION A
                          ON P.COD_ADQUISICION_PEDIDO_VEH = A.COD_ADQUISICION
                          GROUP BY
                                FVF.NUM_FICHA_VTA_VEH,
                                FVF.FEC_CREA_REG,
                                FVF.COD_FILIAL,
                                FVF.FEC_FICHA_VTA_VEH,
                                FVF.COD_ESTADO_FICHA_VTA_VEH,
                                FVF.COD_CLIE,
                                FVF.COD_MONEDA_CRED,
                                FVF.COD_MONEDA_FICHA_VTA_VEH,
                                FVF.COD_TIPO_PAGO,
                                FVF.COD_TIPO_FICHA_VTA_VEH,
                                FVF.VENDEDOR,
                                FVF.COD_AREA_VTA,
                                FVF.COD_CIA,
                                FVF.FEC_ENTREGA_APROX,
                                FVF.VAL_TIPO_CAMBIO_CRED,
                                FVF.OBS_FICHA_VTA_VEH,
                                FVF.CO_USUARIO_CREA_REG,
                                FVF.VAL_TIPO_CAMBIO_FICHA_VTA,
                                FVF.COD_SUCURSAL,
                                A.COD_ADQUISICION,
                                A.DES_ADQUISICION,
                                O.COD_TIPO_PERSO,
                                O.NUM_RUC,
                                O.NUM_DOCU_IDEN,
                                O.NUM_TELF_MOVIL,
                                O.COD_AREA_TELF_MOVIL,
                                O.NOM_PERSO,
                                PD.COD_MARCA,
                                PD.COD_FAMILIA_VEH,
                                D.DES_ESTADO_FICHA_VTA,
                                TP.DES_TIPO_PAGO,
                                V.DESCRIPCION,
                                T.DES_TIPO_FICHA_VTA_VEH,
                                G.DES_AREA_VTA,
                                L.NOM_FILIAL,
                                S.NOM_SUCURSAL,
                                C.NOMBRE
                     ) FVF
                     left JOIN vve_ficha_vta_proforma_veh a ON A.NUM_FICHA_VTA_VEH=FVF.NUM_FICHA_VTA_VEH
                     left JOIN vve_proforma_veh b
                              ON a.num_prof_veh = b.num_prof_veh
                     left JOIN vve_proforma_veh_det c
                              ON a.num_prof_veh = c.num_prof_veh
                     WHERE 1=1 AND ';

    SELECT COUNT(1)
      INTO v_ind_vendedores
      FROM sis_view_usua_porg a
     WHERE a.txt_usuario = p_cod_usua_sid
       AND a.ind_acceso_vendedores = 'S';

    --Fecha de Cierre
    IF p_fech_cierre_ini IS NULL AND p_fech_cierre_fin IS NOT NULL THEN
      p_ret_mens := 'Debe ingresar fecha inicial del rango de consulta para Fecha de cierre.';
      RAISE ve_error;
    END IF;

    IF p_fech_cierre_ini IS NOT NULL AND p_fech_cierre_fin IS NULL THEN
      p_ret_mens := 'Debe ingresar fecha final del rango de consulta para Fecha de cierre.';
      RAISE ve_error;
    END IF;

    IF p_nom_perso IS NOT NULL THEN
      v_where := v_where || ' FVF.NOM_PERSO LIKE ''%' || upper(p_nom_perso) ||
                 '%'' AND ';
    END IF;

    IF p_cod_adquisicion IS NOT NULL THEN
      v_where := v_where ||
                 ' EXISTS (SELECT 1 FROM VENTA.VVE_FICHA_VTA_PEDIDO_VEH FP, VENTA.VVE_PEDIDO_VEH P, VENTA.VVE_ADQUISICION A
                             WHERE FP.NUM_FICHA_VTA_VEH = FVF.NUM_FICHA_VTA_VEH AND FP.IND_INACTIVO = ''N'' AND
                                   FP.NUM_PEDIDO_VEH = P.NUM_PEDIDO_VEH and FP.cod_cia = P.cod_cia and FP.cod_prov = P.cod_prov AND
                                   P.COD_ADQUISICION_PEDIDO_VEH = A.COD_ADQUISICION AND
                                   FVF.COD_ADQUISICION IN (' ||
                 p_cod_adquisicion || ')) AND ';
    END IF;

    IF p_cod_zona IS NOT NULL THEN
      v_where := v_where ||
                 ' EXISTS (SELECT 1 FROM VENTA.VVE_MAE_ZONA_FILIAL VMZF WHERE  FVF.COD_FILIAL = VMZF.COD_FILIAL AND VMZF.COD_ZONA IN (' ||
                 p_cod_zona || ')) AND ';
    END IF;

    IF p_cod_cia IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_CIA IN (' || p_cod_cia || ') AND ';
    END IF;

    IF p_cod_area_vta IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_AREA_VTA IN (' || p_cod_area_vta ||
                 ') AND ';
    END IF;

    IF p_cod_filial IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_FILIAL IN (' || p_cod_filial ||
                 ') AND ';
    END IF;

    IF p_cod_vendedor IS NOT NULL THEN
      v_where := v_where || ' FVF.VENDEDOR = ''' || p_cod_vendedor ||
                 ''' AND ';
    END IF;

    IF p_cod_clausula_compra IS NOT NULL THEN
      v_where := v_where || ' FVF.CLAUS_COMP = ''' || p_cod_clausula_compra ||
                 ''' AND ';
    END IF;

    IF p_num_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.NUM_FICHA_VTA_VEH LIKE ''%' ||
                 p_num_ficha_vta_veh || ''' AND ';
    END IF;

    IF p_cod_tipo_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_TIPO_FICHA_VTA_VEH IN (' ||
                 p_cod_tipo_ficha_vta_veh || ') AND ';
    END IF;

    IF p_cod_tipo_pago IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_TIPO_PAGO IN (' || p_cod_tipo_pago ||
                 ') AND ';
    END IF;

    IF p_cod_moneda_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_MONEDA_FICHA_VTA_VEH IN (' ||
                 p_cod_moneda_ficha_vta_veh || ') AND ';
    END IF;

    IF p_cod_moneda_cred IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_MONEDA_CRED IN (' ||
                 p_cod_moneda_cred || ') AND ';
    END IF;

    IF p_cod_clie IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_CLIE = ''' || p_cod_clie || ''' AND ';
    END IF;

    IF p_cod_familia_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_FAMILIA_VEH IN (' ||
                 p_cod_familia_veh || ') AND ';
    END IF;

    IF p_cod_marca IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_MARCA IN (' || p_cod_marca ||
                 ') AND ';
    END IF;

    IF p_cod_baumuster IS NOT NULL THEN
      v_where := v_where || ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH F,
        VENTA.VVE_PROFORMA_VEH P,
        VENTA.VVE_PROFORMA_VEH_DET PD ' ||
                 ' WHERE F.NUM_PROF_VEH=P.NUM_PROF_VEH
          AND P.NUM_PROF_VEH=PD.NUM_PROF_VEH
          AND PD.COD_BAUMUSTER=''' || p_cod_baumuster ||
                 ''') AND ';
    END IF;

    IF p_cod_config_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH F,
        VENTA.VVE_PROFORMA_VEH P,
        VENTA.VVE_PROFORMA_VEH_DET PD ' ||
                 ' WHERE F.NUM_PROF_VEH=P.NUM_PROF_VEH
          AND P.NUM_PROF_VEH=PD.NUM_PROF_VEH
          AND PD.COD_CONFIG_VEH=''' || p_cod_config_veh ||
                 ''') AND ';
    END IF;

    IF p_cod_estado_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.COD_ESTADO_FICHA_VTA_VEH IN (' ||
                 p_cod_estado_ficha_vta_veh || ') AND ';
    END IF;

    IF p_fec_ficha_vta_veh_ini IS NOT NULL AND p_num_prof_veh IS NULL AND
       p_num_ficha_vta_veh IS NULL AND p_num_pedido_veh IS NULL THEN
      v_where := v_where ||
                 ' TRUNC(FVF.FEC_FICHA_VTA_VEH) >= TRUNC( TO_DATE(''' ||
                 p_fec_ficha_vta_veh_ini || ''', ''DD/MM/YYYY'')) AND ';
    END IF;

    IF p_fec_ficha_vta_veh_fin IS NOT NULL AND p_num_prof_veh IS NULL AND
       p_num_ficha_vta_veh IS NULL AND p_num_pedido_veh IS NULL THEN
      v_where := v_where ||
                 ' TRUNC(FVF.FEC_FICHA_VTA_VEH) <= TRUNC( TO_DATE(''' ||
                 p_fec_ficha_vta_veh_fin || ''', ''DD/MM/YYYY'')) AND ';
    END IF;

    IF p_num_prof_veh IS NOT NULL THEN
      v_where := v_where ||
                 ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PROFORMA_VEH O ' ||
                 ' WHERE O.NUM_FICHA_VTA_VEH=NUM_FICHA_VTA_VEH
          AND O.NUM_PROF_VEH=''' || p_num_prof_veh || '''
          AND NVL(O.IND_INACTIVO,''N'')=''N'') AND ';
    END IF;

    IF p_num_pedido_veh IS NOT NULL THEN
      v_where := v_where || ' FVF.NUM_FICHA_VTA_VEH IN (
        SELECT NUM_FICHA_VTA_VEH
        FROM VENTA.VVE_FICHA_VTA_PEDIDO_VEH P ' ||
                 ' WHERE P.NUM_FICHA_VTA_VEH=NUM_FICHA_VTA_VEH
          AND P.NUM_PEDIDO_VEH=''' || p_num_pedido_veh || '''
          AND NVL(P.IND_INACTIVO,''N'')=''N'') AND ';
    END IF;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_BUSQUEDA_WHERE',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_where,
                                        NULL);

    IF p_fech_cierre_ini IS NOT NULL AND p_fech_cierre_fin IS NOT NULL THEN

      v_where := v_where ||
                 ' EXISTS(SELECT 1
                           FROM VVE_FICHA_VTA_VEH_ESTADO VVE
                           WHERE VVE.NUM_FICHA_VTA_VEH=FVF.NUM_FICHA_VTA_VEH
                             AND VVE.COD_ESTADO_FICHA_VTA= ''' ||
                 v_estado_vta ||
                 ''' AND TRUNC(VVE.FEC_ESTADO_FICHA_VTA) >= TRUNC( TO_DATE(''' ||
                 p_fech_cierre_ini ||
                 ''', ''DD/MM/YYYY'' )) AND TRUNC(VVE.FEC_ESTADO_FICHA_VTA) <= TRUNC( TO_DATE(''' ||
                 p_fech_cierre_fin || ''', ''DD/MM/YYYY'' )) ) AND ';
    END IF;

    v_where := v_where ||
               '  (B.COD_AREA_VTA,C.COD_FAMILIA_VEH, C.COD_MARCA) IN
          (SELECT UM.cod_area_vta, UM.cod_familia_veh,UM.cod_marca FROM sis_view_usua_marca UM WHERE UM.txt_usuario=''' ||
               p_cod_usua_sid || ''') ';

    v_where := v_where || '
          and fvf.cod_filial in (select uf.cod_filial from sis_view_usua_filial uf where uf.txt_usuario=''' ||
               p_cod_usua_sid || ''')
          ';

    IF v_ind_vendedores = 0 THEN
      v_where := v_where ||
                 'AND (FVF.VENDEDOR IN (SELECT Y.VENDEDOR FROM ARCCVE_ACCESO Y WHERE Y.CO_USUARIO = ''' ||
                 p_cod_usua_sid ||
                 ''' AND NVL(Y.IND_INACTIVO, ''N'') = ''N'')
                        OR
                        EXISTS(
                      SELECT 1 FROM gen_perso_vendedor pv, arccve_acceso q
                      WHERE pv.cod_perso = FVF.cod_clie
                        AND pv.vendedor  = q.vendedor
                        AND nvl(pv.ind_inactivo,''N'') = ''N''
                        AND Q.CO_USUARIO = ''' ||
                 p_cod_usua_sid || '''
                        AND NVL(Q.IND_INACTIVO, ''N'') = ''N''
                      )    ) ';

    END IF;

    v_query := v_query || v_where;

    v_order := ' ORDER BY FVF.FEC_CREA_REG DESC ';
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_BUSQUEDA',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_query,
                                        NULL);

    EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM (' || v_query || ')'
      INTO p_ret_cantidad;

    v_query := v_query || v_order;

    v_final := v_query;

    IF nvl(p_ind_paginado, 'S') = 'S' THEN
      v_final := 'SELECT ROWNUM RM, QY.* FROM (' || v_query ||
                 ') QY
                  WHERE ROWNUM <= ' || p_limitsup || '';
      v_final := 'SELECT /*+ FIRST_ROWS */ PG.NUM_FICHA_VTA_VEH,
                    PG.NUM_FICHA_VTA_VEH,
                    PG.VENDEDOR,
                    PG.DESCRIPCION,
                    PG.COD_TIPO_FICHA_VTA_VEH,
                    PG.DES_TIPO_FICHA_VTA_VEH,
                    PG.COD_CIA,
                    PG.NOMBRE,
                    PG.COD_AREA_VTA,
                    PG.DES_AREA_VTA,
                    PG.COD_SUCURSAL,
                    PG.NOM_SUCURSAL,
                    PG.COD_FILIAL,
                    PG.NOM_FILIAL,
                    PG.FEC_FICHA_VTA_VEH,
                    PG.COD_CLIE,
                    PG.NOM_PERSO,
                    PG.COD_MONEDA_FICHA_VTA_VEH,
                    PG.VAL_TIPO_CAMBIO_FICHA_VTA,
                    PG.COD_ESTADO_FICHA_VTA_VEH,
                    PG.DES_ESTADO_FICHA_VTA,
                    PG.CO_USUARIO_CREA_REG,
                    PG.FEC_CREA_REG,
                    PG.OBS_FICHA_VTA_VEH,
                    PG.COD_TIPO_PAGO,
                    PG.DES_TIPO_PAGO,
                    PG.COD_MONEDA_CRED,
                    PG.VAL_TIPO_CAMBIO_CRED,
                    PG.FEC_ENTREGA_APROX,
                    PG.COD_ADQUISICION,
                    PG.DES_MONEDA_FICHA_VTA_VEH,
                    PG.COD_TIPO_PERSO,
                    PG.DES_TIPO_PERSO,
                    PG.NUM_RUC,
                    PG.NUM_DOCU_IDEN,
                    PG.NUM_TELF_MOVIL,
                    PG.COD_AREA_TELF_MOVIL,
                    PG.COD_MARCA,
                    PG.COD_FAMILIA_VEH,
                    PG.DES_ADQUISICION,
                    PG.NRO_PROF,
                    PG.PED_ASIG,
                    PG.PED_FACT,
                    PG.PED_ENTR,
                    PG.CLAUS_COMP,
                    PG.CLAUS_COMP_DES
                  FROM (' || v_final ||
                 ') PG
                  WHERE RM >= ' || p_limitinf || '';
    END IF;
    OPEN p_ret_cursor FOR v_final;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_BUSQUEDA',
                                        p_cod_usua_sid,
                                        NULL,
                                        v_final,
                                        NULL);

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_cantidad := 0;
        p_ret_esta     := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_FICHA_VENTA_web',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_FICHA_VENTA_web',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

  END sp_list_ficha_venta_reporte;

  /********************************************************************************
    Nombre:     SP_LIST_PROF_FICH_VNTA
    Proposito:  Busqueda de fichas de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH         ---> Código de ficha de venta.
                P_COD_USUA_WEB              ---> Id del usuario.
                P_COD_USUA_SID              ---> Código del usuario.
                P_LIMITINF                  ---> Limite inicial de registros.
                P_LIMITSUP                  ---> Limite final de registros.
                P_RET_CURSOR                ---> Resultado de la busqueda.
                P_RET_CANTIDAD              ---> Cantidad total de registros.
                P_RET_ESTA                  ---> Estado del proceso.
                P_RET_MENS                  ---> Resultado del proceso.
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        17/10/2017  MEGUILUZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_prof_fich_vnta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN VARCHAR2,
    p_limitsup          IN INTEGER,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_estado_vta VARCHAR2(1);
    v_query      VARCHAR2(10000);
    v_where      VARCHAR2(10000);
    v_order      VARCHAR2(10000);
    v_final      VARCHAR2(10000);
  BEGIN

    v_query := 'SELECT FVP.*
              FROM VVE_FICHA_VTA_PROFORMA_VEH FVP
              WHERE 1=1 ';

    v_where := '';
    v_query := v_query || v_where;

    EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM (' || v_query || ')'
      INTO p_ret_cantidad;

    v_order := ' ORDER BY FVF.NUM_FICHA_VTA_VEH DESC ';
    v_query := v_query || v_order;

    v_final := 'SELECT ROWNUM RN, X.* FROM (' || v_query || ') X ';

    IF nvl(p_ind_paginado, 'S') = 'S' THEN
      v_final := 'SELECT * FROM (' || v_final || ') X WHERE RM BETWEEN ' ||
                 p_limitinf || ' AND ' || p_limitsup;
    END IF;

    OPEN p_ret_cursor FOR v_final;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_cantidad := 0;
        p_ret_esta     := 0;
      END IF;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_FICH_VNTA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_PROF_FICH_VNTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_FICH_VNTA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_list_prof_fich_vnta;

  /********************************************************************************
    Nombre:     SP_INSE_CORREO_FICHA_VENTA
    Proposito:  Inserta correo enviado desde ficha de venta.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH ---> Código del solicitud.
                P_DESTINATARIOS     ---> Lista de correos destinatarios.
                P_COPIA             ---> Lista de correos CC.
                P_ASUNTO            ---> Asunto.
                P_CUERPO            ---> Contenido del correo.
                P_CORREOORIGEN      ---> Correo remitente.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0         26/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_inse_correo_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_correo vve_correo_prof.cod_correo_prof%TYPE;
  BEGIN
    --<I - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>
    SELECT VVE_CORREO_PROF_SQ01.NEXTVAL INTO V_COD_CORREO FROM DUAL;
    --<F - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       p_num_ficha_vta_veh,
       'FV',
       p_destinatarios,
       p_copia,
       p_asunto,
       p_cuerpo,
       p_correoorigen,
       'N',
       'N',
       SYSDATE,
       p_cod_usua_web);

    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CORREO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_inse_correo_ficha_venta;

  /********************************************************************************
    Nombre:     SP_LIST_CORREO_FICHA_VENTA
    Proposito:  Lista de correos a enviar.
    Referencias:
    Parametros: P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_RET_CORREOS       ---> Lista de correos a enviar.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0         26/05/2017  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_list_correo_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN

    OPEN p_ret_correos FOR
      SELECT a.destinatarios, a.copia, a.asunto, a.cuerpo, a.correoorigen
        FROM vve_correo_prof a
       WHERE a.cod_ref_proc = p_num_ficha_vta_veh
         AND a.tipo_ref_proc = 'FV'
         AND a.ind_enviado = 'N';

    UPDATE vve_correo_prof a
       SET ind_enviado           = 'S',
           a.cod_id_usuario_modi = p_cod_usua_web,
           a.fec_modi_reg        = SYSDATE
     WHERE a.cod_ref_proc = p_num_ficha_vta_veh
       AND ind_enviado = 'N';

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_CORREO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CORREO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_list_correo_ficha_venta;

  PROCEDURE sp_vali_cliente
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia           IN vve_ficha_vta_veh.cod_cia%TYPE,
    p_vendedor          IN vve_ficha_vta_veh.vendedor%TYPE,
    p_cod_area_vta      IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_clie          IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_clie       vve_ficha_vta_veh.cod_clie%TYPE;
    v_cod_clie_val   vve_ficha_vta_veh.cod_clie%TYPE;
    v_num_pedido_veh vve_pedido_veh.num_pedido_veh%TYPE;
    vc_ficha         NUMBER;
    vc_prof          NUMBER;
    vc_pedido        NUMBER;
    vc_aut_area_vta  NUMBER;
    v_cursor         SYS_REFCURSOR;
    --<i-85385>
    v_dato_numerico VARCHAR2(50);
    v_dato_cadena   VARCHAR2(50);
    v_dato_booleano VARCHAR2(50);
    v_cod_rpta      NUMBER;
    v_mensaje       VARCHAR2(100);
    v_cod_fami      VARCHAR2(50);
    --<f-85385> 
    --<i REQ 86408 Validación de correo>

    CURSOR v_cur_clie IS
      SELECT ltrim(rtrim(g.num_ruc)) num_ruc
        FROM gen_persona g
       WHERE g.cod_perso = p_cod_clie;
    v_num_ruc NUMBER;
    --<f REQ 86408>
  BEGIN
    --<i REQ 86408 Validación de correo>

    IF pkg_sweb_ven_gene.fu_vali_acce_usua(p_cod_usua_sid, '', p_vendedor) = 0 THEN

      p_ret_mens := 'El usuario no tiene acceso de realizar operaciones en documentos del Vendedor.';
      RAISE ve_error;
    END IF;

    --Valida que cliente exista y no sea prospecto
    IF pkg_sweb_gest_clie.fu_vali_tipo_clie(p_cod_clie) = 1 THEN
      --Valida si es cliente
      --<I 84921>
      OPEN v_cur_clie;
      FETCH v_cur_clie
        INTO v_num_ruc;
      CLOSE v_cur_clie;
      IF (pkg_sweb_gest_clie.fu_vali_mail_clie(p_cod_clie) = 1) OR
         (v_num_ruc IS NULL) THEN
        p_ret_mens := 'ok';
      ELSE

        p_ret_mens := 'El cliente no tiene una cuenta de correo valida en SID. No se puede crear Ficha de Venta.';
        RAISE ve_error;

      END IF;
      --<F 84921>
    ELSE

      p_ret_mens := 'El cliente esta registrado como Prospecto. No se puede crear Ficha de Venta.';
      RAISE ve_error;
    END IF;

    --<f REQ 86408>
    BEGIN
      SELECT cod_clie
        INTO v_cod_clie_val
        FROM cxc_mae_clie
       WHERE cod_clie = p_cod_clie;
    EXCEPTION
      WHEN no_data_found THEN
        p_ret_mens := '¡ El cliente, no esta registrado como cliente, registrelo como cliente valido!';
        RAISE ve_error;
    END;
    IF p_num_ficha_vta_veh <> 0 THEN
      SELECT a.cod_clie
        INTO v_cod_clie
        FROM vve_ficha_vta_veh a
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
      IF p_cod_clie != v_cod_clie THEN
        SELECT nvl(COUNT(num_ficha_vta_veh), 0)
          INTO vc_ficha
          FROM venta.vve_proforma_veh_det       p,
               venta.vve_ficha_vta_proforma_veh f
         WHERE p.num_prof_veh = f.num_prof_veh
           AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND nvl(f.ind_inactivo, 'N') = 'N';

        SELECT nvl(COUNT(num_ficha_vta_veh), 0)
          INTO vc_prof
          FROM venta.vve_proforma_veh_det       p,
               venta.vve_ficha_vta_proforma_veh f
         WHERE p.num_prof_veh = f.num_prof_veh
           AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND f.num_soli_cred_veh IS NOT NULL
           AND nvl(f.ind_inactivo, 'N') = 'N';

        SELECT nvl(COUNT(num_ficha_vta_veh), 0)
          INTO vc_pedido
          FROM venta.vve_pedido_veh p, venta.vve_ficha_vta_pedido_veh f
         WHERE p.num_pedido_veh = f.num_pedido_veh
           AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND nvl(f.ind_inactivo, 'N') = 'N';

        IF vc_ficha > 0 THEN
          p_ret_mens := '¡ La Ficha de Venta tiene Proformas Relacionadas, No es Posible Modificar el Cliente !';
          RAISE ve_error;
        END IF;

        IF vc_prof > 0 THEN
          p_ret_mens := '¡ La Ficha de Venta tiene Solicitudes de Crédito Relacionadas, No es Posible Modificar el Cliente !';
          RAISE ve_error;
        END IF;

        IF vc_pedido > 0 THEN
          p_ret_mens := '¡ La Ficha de Venta tiene Pedidos Relacionados, No es Posible Modificar el Cliente !';
          RAISE ve_error;
        END IF;
      ELSE
        BEGIN
          SELECT cod_perso
            INTO v_cod_clie
            FROM gen_persona
           WHERE cod_perso = p_cod_clie;
        EXCEPTION
          WHEN no_data_found THEN
            p_ret_mens := '¡ Ingrese un Cliente Válido, el Cliente Ingresado No Existe.  !';
            RAISE ve_error;
        END;
      END IF;

      --<I-85385> 
      BEGIN
        SELECT p.cod_familia_veh
          INTO v_cod_fami
          FROM vve_proforma_veh_det p, vve_ficha_vta_proforma_veh f
         WHERE p.num_prof_veh = f.num_prof_veh
           AND nvl(f.ind_inactivo, 'N') = 'N'
           AND f.num_ficha_vta_veh = p_num_ficha_vta_veh;
      EXCEPTION
        WHEN OTHERS THEN
          v_cod_fami := NULL;
      END;

      pkg_sweb_mant_datos_mae.sp_dato_gen(p_cod_area_vta        => p_cod_area_vta,
                                          p_cod_familia_veh     => v_cod_fami,
                                          p_cod_marca           => NULL,
                                          p_cod_baumuster       => NULL,
                                          p_cod_config_veh      => NULL,
                                          p_cod_tipo_veh        => NULL,
                                          p_cod_clausula_compra => NULL,
                                          p_id_tipo_dato        => 4, --4=reservsa de vehiculos
                                          o_dato_numerico       => v_dato_numerico,
                                          o_dato_cadena         => v_dato_cadena,
                                          o_dato_booleano       => v_dato_booleano,
                                          o_cod_rpta            => v_cod_rpta,
                                          o_mensaje             => p_ret_mens);

      IF v_cod_rpta = 1 AND v_dato_cadena = k_val_s THEN
        --IF nvl(vc_aut_area_vta, 0) > 0 THEN--<85385 comentado>
        --<F-85385>
        OPEN v_cursor FOR
          SELECT a.num_pedido_veh
            FROM vve_pedido_veh_reserva b, vve_pedido_veh a
           WHERE b.cod_cia = p_cod_cia
             AND b.vendedor = p_vendedor
             AND b.cod_clie = p_cod_clie
             AND b.fec_fin_reserva_pedido >= trunc(SYSDATE)
             AND cod_estado_reserva_pedido = '001'
             AND a.cod_cia = b.cod_cia
             AND a.cod_prov = b.cod_prov
             AND a.num_pedido_veh = b.num_pedido_veh;
        FETCH v_cursor
          INTO v_num_pedido_veh;
        CLOSE v_cursor;
        IF v_num_pedido_veh IS NULL THEN
          p_ret_mens := '¡ El cliente no tiene reserva, debe hacer la reserva del vehículo !';
          RAISE ve_error;
        END IF;
      END IF;
    END IF;
    p_ret_esta := 1;
    p_ret_mens := 'La validación es correcta';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_CORREO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CORREO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_vali_cliente;

  PROCEDURE sp_auto_gral
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_aut_ficha_vta IN sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_cod_area_vta      IN vve_ficha_vta_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_ficha_vta_veh.cod_filial%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    v_numero NUMBER;
  BEGIN
    SELECT COUNT(u.co_usuario)
      INTO v_numero
      FROM sistemas.usuarios_aut_marca_veh u
     WHERE u.co_usuario = p_cod_usua_sid
       AND u.cod_aut_ficha_vta = p_cod_aut_ficha_vta
       AND u.cod_area_vta = p_cod_area_vta
       AND u.cod_filial = p_cod_filial
       AND nvl(u.ind_inactivo, 'N') = 'N'
       AND nvl(u.ind_realiza_acti, 'N') = 'S';

    IF v_numero > 0 THEN
      p_ret_esta := 1;
      p_ret_mens := 'La validación es correcta';
    ELSE
      p_ret_esta := 0;
      p_ret_mens := '¡ Usuario no autorizado !';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_AUTO_GRAL:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_AUTO_GRAL',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          NULL);
  END sp_auto_gral;

  /********************************************************************************
    Nombre:     fu_auto_five_usu
    Proposito:  verifica si se tiene permiso para autorizar ficha de venta.
    Referencias:


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        12/02/2018  GARROYO        Creación del procedure.
  ********************************************************************************/

  FUNCTION fu_auto_five_usu
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_aut_ficha_vta IN sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE
  ) RETURN VARCHAR2 IS
    l_cod_area_vta    vve_ficha_vta_veh.cod_area_vta%TYPE;
    l_cod_familia_veh vve_proforma_veh_det.cod_familia_veh%TYPE;
    l_cod_marca       vve_proforma_veh_det.cod_marca%TYPE;
    l_cod_filial      vve_ficha_vta_veh.cod_filial%TYPE;
    l_cod_id_procesos sis_mae_procesos.cod_id_procesos%TYPE;
    l_existe          VARCHAR2(1);
    l_cantidad        NUMBER;
    l_importer        vve_aut_ficha_vta.ind_importer%TYPE;
    --<Inicio 86487 Problema con varias marcas  >
    v_cursor SYS_REFCURSOR;
    --<Fin 86487 Problema con varias marcas  >
    --<Inicio usuario web vacio>
    l_cod_usua_web sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    --<fin usuario web vacio>
  BEGIN
    --<Inicio usuario web vacio>
    SELECT a.cod_id_usuario
      INTO l_cod_usua_web
      FROM sis_mae_usuario a
     WHERE upper(a.txt_usuario) LIKE upper('ACRUZ')
       AND rownum = 1;
    --<fin usuario web vacio>
    SELECT a.cod_id_procesos, nvl(a.ind_importer, 'N')
      INTO l_cod_id_procesos, l_importer
      FROM vve_aut_ficha_vta a
     WHERE a.cod_aut_ficha_vta = p_cod_aut_ficha_vta;

    IF p_num_pedido_veh IS NULL THEN
      --<Inicio 86487 Problema con varias marcas  >

      OPEN v_cursor FOR
        SELECT DISTINCT b.cod_area_vta,
                        c.cod_familia_veh,
                        c.cod_marca,
                        b.cod_filial

          FROM vve_ficha_vta_proforma_veh a
         INNER JOIN vve_ficha_vta_veh b
            ON a.num_ficha_vta_veh = b.num_ficha_vta_veh
         INNER JOIN vve_proforma_veh_det c
            ON a.num_prof_veh = c.num_prof_veh
         WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
      --<FIN 86487 Problema con varias marcas  >
    ELSE
      OPEN v_cursor FOR --<FIN 86487 Problema con varias marcas  >
        SELECT DISTINCT b.cod_area_vta,
                        b.cod_familia_veh,
                        b.cod_marca,
                        c.cod_filial
          FROM vve_ficha_vta_pedido_veh a
         INNER JOIN vve_pedido_veh b
            ON a.cod_cia = b.cod_cia
           AND a.cod_prov = b.cod_prov
           AND a.num_pedido_veh = b.num_pedido_veh
         INNER JOIN vve_ficha_vta_veh c
            ON a.num_ficha_vta_veh = c.num_ficha_vta_veh
         WHERE a.num_pedido_veh = p_num_pedido_veh
           AND a.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND a.cod_prov = p_cod_prov
           AND a.cod_cia = p_cod_cia;
    END IF;

    l_existe := 'S';
    --<Inicio 86487 Problema con varias marcas  >
    LOOP
      FETCH v_cursor
        INTO l_cod_area_vta, l_cod_familia_veh, l_cod_marca, l_cod_filial;
      EXIT WHEN v_cursor%NOTFOUND;

      SELECT COUNT(*)
        INTO l_cantidad
        FROM sistemas.sis_view_usua_proc a
       INNER JOIN sistemas.sis_view_usua_marca b
          ON a.cod_id_usuario = b.cod_id_usuario
       INNER JOIN sis_view_usua_filial c
          ON a.cod_id_usuario = c.cod_id_usuario
       WHERE a.cod_id_procesos = l_cod_id_procesos
         AND b.cod_area_vta = l_cod_area_vta
         AND b.cod_familia_veh = l_cod_familia_veh
         AND b.cod_marca = l_cod_marca
         AND c.cod_filial = l_cod_filial
         AND a.cod_id_usuario = nvl(p_cod_usua_web, l_cod_usua_web);
      --<Inicio REQ 86405  Mejora AUTORIZACIONES FICHA DE VENTA >
      --<FIN REQ Mejora validación ficha venta>    
      IF l_cantidad = 0 THEN
        l_existe := 'N';

      END IF;
    END LOOP;
    CLOSE v_cursor;
    --<FIN 86487 Problema con varias marcas  >
    RETURN(l_existe);
  EXCEPTION
    WHEN OTHERS THEN
      --<Inicio REQ 86405  Mejora AUTORIZACIONES FICHA DE VENTA >
      --RETURN null;
      RETURN 'N';
      --<FIN REQ Mejora validación ficha venta>       
  END fu_auto_five_usu;

  /********************************************************************************
    Nombre:     fu_auto_five_usu
    Proposito:  verifica si se tiene permiso para autorizar ficha de venta.
    Referencias:


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        12/02/2018  GARROYO        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_auto_five_usu
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_aut_ficha_vta IN sistemas.usuarios_aut_marca_veh.cod_aut_ficha_vta%TYPE,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS

    l_existe   VARCHAR2(1);
    l_cantidad NUMBER;
  BEGIN

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_auto_five_usu_alex - ' ||
                                        p_cod_aut_ficha_vta,
                                        p_cod_usua_sid,
                                        'Error',
                                        p_ret_mens,
                                        NULL);

    IF fu_auto_five_usu(p_cod_usua_sid,
                        p_cod_usua_web,
                        p_cod_aut_ficha_vta,
                        p_num_ficha_vta_veh,
                        p_num_pedido_veh,
                        p_cod_cia,
                        p_cod_prov) = 'S' THEN
      p_ret_esta := 1;
      p_ret_mens := 'La validación es correcta';
    ELSE
      p_ret_esta := 0;
      p_ret_mens := '¡ Usuario no autorizado !';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_auto_five_usu:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_auto_five_usu',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          NULL);
  END sp_auto_five_usu;

  PROCEDURE sp_vali_acti
  (
    p_cod_usua_sid        IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_acti_pedido_veh IN sistemas.usuarios_acti_pedido_veh.cod_acti_pedido_veh%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR2
  ) AS
    v_numero NUMBER;
  BEGIN
    SELECT COUNT(cod_acti_pedido_veh)
      INTO v_numero
      FROM sistemas.usuarios_acti_pedido_veh
     WHERE co_usuario = p_cod_usua_sid
       AND cod_acti_pedido_veh = p_cod_acti_pedido_veh
       AND nvl(ind_realiza_acti, 'N') = 'S'
       AND nvl(ind_inactivo, 'N') = 'N';

    IF v_numero > 0 THEN
      p_ret_esta := 1;
      p_ret_mens := 'La validación es correcta';
    ELSE
      p_ret_esta := 0;
      p_ret_mens := '¡ Usuario no autorizado !';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_VALI_ACTI:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_ACTI',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          NULL);
  END sp_vali_acti;

  PROCEDURE sp_vali_pedi_asig
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    v_numero NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO v_numero
      FROM vve_ficha_vta_pedido_veh v
     WHERE v.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND nvl(v.ind_inactivo, 'N') = 'N';

    IF v_numero = 0 THEN
      p_ret_esta := 1;
      p_ret_mens := 'La validación es correcta';
    ELSE
      p_ret_esta := 0;
      p_ret_mens := 'La Ficha de Venta no Tienes Pedidos Asignados';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_VALI_PEDI_ASIG:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_VALI_PEDI_ASIG',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          NULL);
  END sp_vali_pedi_asig;

  PROCEDURE sp_list_cond_pago
  (
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT a.cod_valdet, a.des_valdet
        FROM gen_lval_det a
       WHERE a.cod_val = 'CONDPAGO';

    p_ret_esta := 1;
    p_ret_mens := 'La consulta ejecuto correctamente';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_COND_PAGO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_COND_PAGO',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          NULL);
  END sp_list_cond_pago;

  PROCEDURE sp_list_cond_pago_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT f.nur_ficha_vta_pedido,
             f.num_pedido_veh,
             f.num_prof_veh,
             generico.pkg_gen_select.func_sel_gen_marca(p.cod_marca) des_marca,
             decode(p.ind_nuevo_usado,
                    'N',
                    pkg_venta_select.func_sel_vve_baumuster(p.cod_familia_veh,
                                                            p.cod_marca,
                                                            p.cod_baumuster),
                    'U',
                    nvl(p.des_modelo_veh_usado,
                        pkg_venta_select.func_sel_vve_baumuster(p.cod_familia_veh,
                                                                p.cod_marca,
                                                                p.cod_baumuster))) des_modelo,
             f.tipo_pago,
             f.con_pago
        FROM vve_ficha_vta_pedido_veh f
       INNER JOIN vve_pedido_veh p
          ON p.num_pedido_veh = f.num_pedido_veh
         AND p.cod_cia = f.cod_cia
         AND p.cod_prov = f.cod_prov
       WHERE f.num_pedido_veh = p_num_ficha_vta_veh;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta ejecuto correctamente';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_COND_PAGO_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_COND_PAGO_FICHA_VENTA',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_list_cond_pago_ficha_venta;

  PROCEDURE sp_actu_cond_pago
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_nur_ficha_vta_pedido IN vve_ficha_vta_pedido_veh.nur_ficha_vta_pedido%TYPE,
    p_tipo_pago            IN vve_ficha_vta_pedido_veh.tipo_pago%TYPE,
    p_con_pago             IN vve_ficha_vta_pedido_veh.con_pago%TYPE,
    p_ind_apl_todo         IN CHAR,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN
    IF p_tipo_pago IS NULL THEN
      p_ret_mens := 'Debe Seleccionar el Tipo de Pago';
      RAISE ve_error;
    END IF;

    IF p_con_pago IS NULL THEN
      p_ret_mens := 'Debe Seleccionar la condición de Pago';
      RAISE ve_error;
    END IF;

    IF p_tipo_pago = 'C' AND p_con_pago <> '1' THEN
      p_ret_mens := 'Si El Tipo de Pago es al Contado, La condición de Pago Tiene que ser al Contado';
      RAISE ve_error;
    END IF;

    IF p_tipo_pago = 'P' AND p_con_pago = '1' THEN
      p_ret_mens := 'Si El Tipo de Pago es al Crédito, La condición de Pago Tiene que ser al Crédito';
      RAISE ve_error;
    END IF;

    UPDATE vve_ficha_vta_pedido_veh
       SET tipo_pago = p_tipo_pago,
           con_pago  = p_con_pago
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND ((p_ind_apl_todo = 'S') OR
           (nur_ficha_vta_pedido = p_nur_ficha_vta_pedido));

    COMMIT;

    p_ret_mens := 'La condición de pago se actualizo con éxito';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_COND_PAGO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_COND_PAGO',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END sp_actu_cond_pago;

  /*-----------------------------------------------------------------------------
    Nombre : SP_LIST_HIST_ESTA_FICH
    Proposito : Lista el historial de los estados de una ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    11/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_hist_esta_fich
  (
    p_num_ficha_vta_veh VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT fe.num_ficha_vta_veh,
             fe.nur_ficha_vta_estado,
             fe.cod_estado_ficha_vta,
             e.des_estado_ficha_vta,
             fe.fec_estado_ficha_vta,
             fe.obs_estado_ficha_vta,
             fe.co_usuario_crea_reg,
             fe.fec_crea_reg,
             fe.ind_inactivo,
             fe.co_usuario_inactiva,
             fe.fec_inactiva
        FROM vve_ficha_vta_veh_estado fe
        JOIN venta.vve_estado_ficha_vta e
          ON fe.cod_estado_ficha_vta = e.cod_estado_ficha_vta
       WHERE fe.num_ficha_vta_veh = p_num_ficha_vta_veh;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_HIST_ESTA_FICH',
                                          NULL,
                                          'Error al listar historial de estados de ficha',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

  END;

  /*-----------------------------------------------------------------------------
    Nombre : SP_LIST_DCOR
    Proposito : Lista direcciones de correo por codigo de usuario
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    17/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_dcor
  (
    p_co_usuario IN VARCHAR2,
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT di_correo
        FROM usuarios
       WHERE upper(co_usuario) = upper(p_co_usuario);

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_DCOR',
                                          NULL,
                                          'Error al listar las direcciones de correo',
                                          p_ret_mens,
                                          p_co_usuario);
  END;

  /*-----------------------------------------------------------------------------
   Nombre : SP_LIST_ESTA_FICH
   Proposito : Lista los estados de una ficha de venta
   Referencias :
   Parametros :
   Log de Cambios
   Fecha        Autor         Descripcion
   11/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_esta_fich
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT des_estado_ficha_vta, cod_estado_ficha_vta, ind_inactivo
        FROM venta.vve_estado_ficha_vta
       WHERE cod_estado_ficha_vta IN ('I', 'E', 'V')
         AND nvl(ind_inactivo, 'N') = 'N';
    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_ESTA_FICH',
                                          NULL,
                                          'Error al listar estados de ficha',
                                          p_ret_mens);
  END;

  /********************************************************************************
      Nombre:     SP_LIST_CORREO_HIST
      Proposito:  Proceso que me permite Obtener los correos a notificar y actualiza la tabla correo Proforma.
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_CORREOS         ---> Cursor con los correos a notificar.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         25/10/2017  JVELEZ           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_list_correo_sol_fact(
                                    --P_COD_PLAN_ENTR_VEHI   IN VARCHAR2,
                                    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                    p_ret_correos       OUT SYS_REFCURSOR,
                                    p_ret_esta          OUT NUMBER,
                                    p_ret_mens          OUT VARCHAR2) AS
    ve_error EXCEPTION;
  BEGIN

    OPEN p_ret_correos FOR
      SELECT a.destinatarios, a.copia, a.asunto, a.cuerpo, a.correoorigen
        FROM vve_correo_prof a
       WHERE a.cod_ref_proc = p_num_ficha_vta_veh
         AND a.tipo_ref_proc = 'SF' -- SOLICITUD DE FACTURACION
         AND a.ind_enviado = 'N';

    UPDATE vve_correo_prof a
       SET ind_enviado           = 'S',
           a.cod_id_usuario_modi = p_id_usuario,
           a.fec_modi_reg        = SYSDATE
     WHERE a.cod_ref_proc = p_num_ficha_vta_veh
       AND ind_enviado = 'N';

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_LIST_CORREO_HIST:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CORREO_HIST',
                                          NULL, --P_COD_USUA_SID,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /********************************************************************************
      Nombre:     SP_INSE_NOTIF_HIST
      Proposito:  Proceso que me permite insertar en la tabla Historial de Notificaciones
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_HISTORIAL        ---> Codigo del Historial
                  P_COD_USUA_NOTI       ---> Codigo de usuarios notificados
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         25/10/2017  JVELEZ           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_inse_notif_soli_fact(p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                    --P_COD_PLAN_ENTR_VEHI     IN VVE_PLAN_HIST_NOTI.COD_PLAN_ENTR_VEHI%TYPE,
                                    p_id_historial  IN vve_plan_hist_noti.num_plan_entr_hist%TYPE,
                                    p_cod_usua_noti IN VARCHAR2,
                                    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                    p_ret_esta      OUT NUMBER,
                                    p_ret_mens      OUT VARCHAR2) AS
    ve_error EXCEPTION;
    v_num_plan_hist_noti vve_plan_hist_noti.num_plan_hist_noti%TYPE;
    c_usuarios           SYS_REFCURSOR;
    v_query              VARCHAR2(4000);
    v_cod_id_usuario     sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
  BEGIN

    -- Obtenemos los correos a Notificar
    IF p_cod_usua_noti IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_cod_usua_noti || ') ';
    END IF;

    IF p_cod_usua_noti IS NOT NULL THEN

      OPEN c_usuarios FOR v_query;
      LOOP

        BEGIN
          SELECT seq_vve_plan_hist_noti.nextval
            INTO v_num_plan_hist_noti
            FROM dual;
        EXCEPTION
          WHEN OTHERS THEN
            v_num_plan_hist_noti := NULL;
        END;

        FETCH c_usuarios
          INTO v_cod_id_usuario;
        EXIT WHEN c_usuarios%NOTFOUND;

        INSERT INTO vve_plan_hist_noti n
          (n.cod_plan_entr_vehi,
           n.num_plan_entr_hist,
           n.num_plan_hist_noti,
           n.cod_usu_plan_hist,
           n.ind_inactivo,
           n.fec_crea_reg,
           n.cod_usuario_crea

           )
        VALUES
          (p_num_ficha_vta_veh,
           p_id_historial,
           v_num_plan_hist_noti,
           v_cod_id_usuario,
           'N',
           SYSDATE,
           p_id_usuario

           );

      END LOOP;
      CLOSE c_usuarios;

      COMMIT;

      p_ret_mens := 'Se registró correctamente';
      p_ret_esta := 1;
    ELSE
      p_ret_mens := 'No se han enviado destinatarios para procesar';
      p_ret_esta := 0;
    END IF;

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_NOTIF_HIST',
                                          NULL,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /********************************************************************************
      Nombre:     SP_GEN_CORREO_FV
      Proposito:  Proceso que me permite Obtener los correos de los usuarios y generar la plantilla del correo.
      Referencias:
      Parametros: P_COD_REF_PROC     ---> Código de Referencia del proceso.
                  P_TIPO_CORREO      ---> Tipo de Correo.
                  P_DESTINATARIOS    ---> Lista de direcciones de los destinatarios,
                  P_ID_USUARIO       ---> Id del usuario.
                  P_TIPO_REF_PROC    ---> Tipo de Referencia del proceso.
                  P_RET_ESTA         ---> Estado del proceso.
                  P_RET_MENS         ---> Resultado del proceso.

      TIPO DE CORREO: 1, 2 Adjuntos

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         18/12/2017  JFLORESM         Creacion del procedure.
  *********************************************************************************/
  PROCEDURE sp_gen_correo_fv
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_tipo_correo   IN VARCHAR2,
    p_destinatarios IN VARCHAR2,
    p_correos       IN VARCHAR2,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc IN VARCHAR2,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto            VARCHAR2(2000);
    v_mensaje           CLOB;
    v_html_head         VARCHAR2(2000);
    v_correoori         usuarios.di_correo%TYPE;
    v_query             VARCHAR2(4000);
    c_usuarios          SYS_REFCURSOR;
    v_cod_id_usuario    sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo        sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario       sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres       sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos     sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    v_ambiente          VARCHAR2(100);
    v_num_ficha_vta_veh vve_ficha_vta_veh.num_ficha_vta_veh%TYPE;
    v_nom_cliente       gen_persona.nom_perso%TYPE;
    v_des_area_vta      gen_area_vta.des_area_vta%TYPE;
    v_docs              VARCHAR2(3000);

  BEGIN

    -- Obtenemos el ambiente del servidor
    SELECT decode(upper(instance_name),
                  'DESA',
                  'Desarrollo',
                  'QA',
                  'Pruebas',
                  'PROD',
                  'Producción')
      INTO v_ambiente
      FROM v$instance;

    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ') ';
    END IF;

    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;

    v_html_head := '<head>
        <title>Divemotor - Ficha de Venta</title>
        <meta charset="utf-8">

        <style>
          div, p, a, li, td { -webkit-text-size-adjust:none; }

          @media screen and (max-width: 500px) {
            .mainTable,.mailBody,.to100{
              width:100% !important;
            }

          }
        </style>
        <style>
          @media screen and (max-width: 500px) {
            .mailBody{
              padding: 20px 18px !important
            }
            .col3{
              width: 100%!important
            }
          }

        </style>
      </head>';

    -- Obtenemos los datos generales de la Ficha de Venta
    BEGIN

      SELECT a.num_ficha_vta_veh,
             d.des_area_vta,
             e.nom_perso,
             rtrim(xmlagg(xmlelement(e, b.nom_adj || ', '))
                   .extract('//text()'),
                   ', ') docs
        INTO v_num_ficha_vta_veh, v_des_area_vta, v_nom_cliente, v_docs
        FROM venta.vve_ficha_vta_veh a,
             venta.vve_five_adj      b,
             vve_tabla_maes          c,
             generico.gen_area_vta   d,
             generico.gen_persona    e
       WHERE a.num_ficha_vta_veh = b.num_ficha_vta_veh
         AND b.cod_tipo_adj = c.cod_tipo
         AND c.cod_grupo = '43'
         AND a.cod_area_vta = d.cod_area_vta
         AND a.cod_clie = e.cod_perso
         AND a.num_ficha_vta_veh = '000000034562'
       GROUP BY a.num_ficha_vta_veh, d.des_area_vta, e.nom_perso;

    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No existen datos de la planificación para el envio de correo';
        RAISE ve_error;

    END;

    --Asunto del mensaje
    v_asunto := 'FICHA DE VENTA NRO.: ' ||
                rtrim(ltrim(to_char(p_cod_ref_proc)));

    --Para la opcion de adjuntos (2)--
    IF p_tipo_correo = '2' THEN

      OPEN c_usuarios FOR v_query;
      LOOP
        FETCH c_usuarios
          INTO v_cod_id_usuario,
               v_txt_correo,
               v_txt_usuario,
               v_txt_nombres,
               v_txt_apellidos;
        EXIT WHEN c_usuarios%NOTFOUND;

        v_mensaje := '<!DOCTYPE html>
      <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
        ' || v_html_head || '
        <body style="background-color: #eeeeee; margin: 0;">
          <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
            <tr>
              <td style="padding: 0;">

                <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                  <tr>
                    <td style="padding: 0;">
                      <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                        <tr style="background-color: #222222;">
                          <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                          <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta</td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>

                <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                  <tr>
                    <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                      <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Notificación</h1>
                      <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                     rtrim(ltrim(v_txt_nombres)) ||
                     '</span>, se ha generado una notificación dentro del módulo de Ficha de Venta:</p>

                      <div style="padding: 10px 0;">

                      </div>

                      <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                        <tr>
                          <td>
                            <div class="to100" style="display:inline-block;width: 265px">
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                     rtrim(ltrim(v_nom_cliente)) ||
                     '</span></p>
                            </div>

                            <div class="to100" style="display:inline-block;width: 110px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nº de Ficha de Venta</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"><a href="#" style="color:#0076ff">' ||
                     v_num_ficha_vta_veh ||
                     '</a></p>
                            </div>
                          </td>
                        </tr>
                      </table>
                      <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee;">
                        <tr>
                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Area de Venta</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(v_des_area_vta)) ||
                     '</p>

                            </div>

                            <div class="to100" style="display:inline-block;width: 190px">
                               <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"></p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"></p>

                            </div>
                          </td>
                        </tr>
                      </table>

                      <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                        <tr>
                          <td style="padding: 0;">
                            <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Se adjuntaron los siguientes documentos:</span></p>
                            <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"></p>
                            <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                     v_docs ||
                     '</p>
                          </td>
                        </tr>
                      </table>

                      <div style="padding: 10px 0;">

                      </div>

                      <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                    </td>
                  </tr>
                </table>
                <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                     rtrim(ltrim(v_ambiente)) || '</p>
                </div>
              </td>
            </tr>
          </table>
        </body>
      </html>';

        sp_inse_correo_fv(p_cod_ref_proc,
                          v_txt_correo,
                          NULL,
                          v_asunto,
                          v_mensaje,
                          v_correoori,
                          NULL,
                          p_id_usuario,
                          p_tipo_ref_proc,
                          p_ret_esta,
                          p_ret_mens);

      END LOOP;
      CLOSE c_usuarios;

    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GEN_CORREO_FV:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GEN_CORREO_FV',
                                          NULL,
                                          'Error',
                                          p_ret_mens || ' ' ||
                                          p_destinatarios,
                                          p_cod_ref_proc);
  END;

  /********************************************************************************
      Nombre:     SP_INSE_CORREO
      Proposito:  Registra en la tabla Correo Proforma
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI ---> Código de la Planificacion.
                  P_DESTINATARIOS      ---> correo destinatario.
                  P_COPIA              ---> Lista de correos CC.
                  P_ASUNTO             ---> Asunto.
                  P_CUERPO             ---> Contenido del correo.
                  P_CORREOORIGEN       ---> Correo remitente.
                  P_COD_USUA_SID       ---> Código del usuario.
                  P_COD_USUA_WEB       ---> Id del usuario.
                  P_RET_ESTA           ---> Estado del proceso.
                  P_RET_MENS           ---> Resultado del proceso.
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0        18/12/2017  JFLORESM        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_inse_correo_fv
  (
    p_cod_ref_proc  IN VARCHAR2,
    p_destinatarios IN vve_correo_prof.destinatarios%TYPE,
    p_copia         IN VARCHAR2,
    p_asunto        IN vve_correo_prof.asunto%TYPE,
    p_cuerpo        IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen  IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid  IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc IN VARCHAR2,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_correo vve_correo_prof.cod_correo_prof%TYPE;
  BEGIN
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX-6.1',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX',
                                        'Error al listar los pedidos',
                                        p_copia,
                                        'Error al listar los pedidos');
    
    --<I - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>

    SELECT VVE_CORREO_PROF_SQ01.NEXTVAL INTO V_COD_CORREO FROM DUAL;
    --<F - REQ.89338 - SOPORTE LEGADOS - 22/05/2020>

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX-6.2',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX',
                                        'Error al listar los pedidos',
                                        p_destinatarios,
                                        'Error al listar los pedidos');

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       p_cod_ref_proc,
       p_tipo_ref_proc,
       p_destinatarios,
       p_copia,
       p_asunto,
       p_cuerpo,
       p_correoorigen,
       'N',
       'N',
       SYSDATE,
       p_cod_usua_web);

    COMMIT;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX-4',
                                        'SP_LIST_PEDI_USOCOLR_FV-ALEX',
                                        'Error al listar los pedidos',
                                        'Error al listar los pedidos',
                                        'Error al listar los pedidos');

    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CORREO_FV',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_ref_proc);
  END;

  /********************************************************************************
      Nombre:     SP_LIST_CORREO_HIST
      Proposito:  Proceso que actualiza los correos enviados.
      Referencias:
      Parametros: P_COD_PLAN_ENTR_VEHI  ---> Código de Referencia del proceso.
                  P_ID_USUARIO          ---> Id del usuario.
                  P_RET_CORREOS         ---> Cursor con los correos a notificar.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         18/12/2017  JFLOREM           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_act_correo_env
  (
    p_cod_ref_proc IN VARCHAR2,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos  OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN

    OPEN p_ret_correos FOR
      SELECT a.destinatarios, a.copia, a.asunto, a.cuerpo, a.correoorigen
        FROM vve_correo_prof a
       WHERE a.cod_ref_proc = p_cod_ref_proc
         AND a.tipo_ref_proc = 'FV'
         AND a.ind_enviado = 'N';

    UPDATE vve_correo_prof a
       SET ind_enviado           = 'S',
           a.cod_id_usuario_modi = p_id_usuario,
           a.fec_modi_reg        = SYSDATE
     WHERE a.cod_ref_proc = p_cod_ref_proc
       AND ind_enviado = 'N';

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACT_CORREO_ENV:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACT_CORREO_ENV',
                                          NULL, --P_COD_USUA_SID,
                                          'Error',
                                          p_ret_mens,
                                          p_cod_ref_proc);
  END;

  /********************************************************************************
      Nombre:     SP_REGLAS_NEGOCIO_FV
      Proposito:  Valida las reglas del negocio de la ficha de venta.
      Referencias:
      Parametros: P_COD_AREA_VTA        ---> Código de area de venta.
                  P_COD_MARCA           ---> Código de marca.
                  P_COD_FAMILIA_VEH     ---> Código de familia.
                  P_COD_AUT_AREA_VTA    ---> Código del proceso que se va a ejecutar.
                  P_COD_USUARIO         ---> Código de Usuario.
                  P_ID_USUARIO          ---> Id de usuario.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         31/01/2018  ARAMOS           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_reglas_negocio_fv
  (
    p_cod_area_vta     IN VARCHAR,
    p_cod_marca        IN VARCHAR,
    p_cod_familia_veh  IN VARCHAR,
    p_cod_aut_area_vta IN VARCHAR,
    p_cod_usuario      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor       OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_query       VARCHAR2(1000);
    v_where       VARCHAR2(1000);
    v_query_final VARCHAR2(1000);

  BEGIN

    v_query := 'SELECT COD_AREA_VTA FROM gen_area_vta_aut WHERE 1=1 ';

    IF p_cod_area_vta IS NOT NULL THEN
      v_where := ' AND COD_AREA_VTA = ' || p_cod_area_vta;
    END IF;

    IF p_cod_aut_area_vta IS NOT NULL THEN
      v_where := ' AND COD_AUT_AREA_VTA = ' || p_cod_aut_area_vta;
    END IF;

    v_query_final := v_query || v_where;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_REGLAS_NEGOCIO_FV',
                                        p_cod_usuario,
                                        NULL,
                                        v_query_final,
                                        NULL);

    OPEN p_ret_cursor FOR v_query_final;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_REGLAS_NEGOCIO_FV:' || SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                          'SP_REGLAS_NEGOCIO_FV' || v_where,
                                          p_cod_usuario,
                                          NULL,
                                          v_query_final,
                                          NULL);

  END;

  /********************************************************************************
      Nombre:     SP_REGLAS_NEGOCIO_FV
      Proposito:  Permite la actualización del cliente de la ficha de venta.
      Referencias:


      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         31/01/2018  GARROYO           Creación del procedure.
  *********************************************************************************/

  PROCEDURE sp_act_clie_five
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_clie          IN vve_ficha_vta_veh.cod_clie%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN

    UPDATE vve_ficha_vta_veh a
       SET a.cod_clie = p_cod_clie
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN

      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_act_clie_five',
                                          p_cod_usuario,
                                          'Error codigo de cliente en ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  PROCEDURE sp_perm_usua_ficha
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tab_ficha         OUT SYS_REFCURSOR,
    p_tab_proforma      OUT SYS_REFCURSOR,
    p_tab_pedidos       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    l_cursor_proformas     SYS_REFCURSOR;
    l_cursor_pedidos       SYS_REFCURSOR;
    p_query_permis_pedidos SYS_REFCURSOR;
    --Datos de Ficha
    l_cod_estado_ficha_vta_veh vve_ficha_vta_veh.cod_estado_ficha_vta_veh%TYPE;
    l_num_prof_veh             vve_ficha_vta_proforma_veh.num_prof_veh%TYPE;
    l_cant_pedidos             NUMBER;
    l_sql_prof                 VARCHAR2(32767);
    l_sql_ped                  VARCHAR2(32767);
    l_sql_ped_desasignar       VARCHAR2(32767);
    l_sql_ped_asignar          VARCHAR2(32767);
    l_sql_ped_uso_color        VARCHAR2(32767);
    l_sql_ped_soli_fact        VARCHAR2(32767);
    l_sql_ped_edit_datos       VARCHAR2(32767);
    l_sql_ped_egragar_equipos  VARCHAR2(32767);
    l_sql_ped_egragar_bonos    VARCHAR2(32767);
    l_sql_ped_fec_compromiso   VARCHAR2(32767);
    l_contador                 NUMBER;
    ---Datos de pedidos
    l_num_pedido_veh        vve_pedido_veh.num_pedido_veh%TYPE;
    l_cod_cia               vve_pedido_veh.cod_cia%TYPE;
    l_cod_prov              vve_pedido_veh.cod_prov%TYPE;
    l_cod_estado_pedido_veh vve_pedido_veh.cod_estado_pedido_veh%TYPE;
    --indicadores libres
    l_ind_nueva_ficha_de_venta VARCHAR2(2);
    l_men_nueva_ficha_de_venta VARCHAR(250);
    l_ind_descargar_excel      VARCHAR2(2);
    l_men_descargar_excel      VARCHAR(250);
    -- indicadores de Ficha
    l_ind_cambiar_estado         VARCHAR(2);
    l_men_cambiar_estado         VARCHAR(250);
    l_ind_crear_solicitud_excep  VARCHAR(2);
    l_men_crear_solicitud_excep  VARCHAR(250);
    l_ind_notificar_lafit        VARCHAR2(2);
    l_men_notificar_lafit        VARCHAR(250);
    l_ind_fdv_resumen            VARCHAR2(2);
    l_men_fdv_resumen            VARCHAR(250);
    l_ind_asociar_proforma       VARCHAR(2);
    l_men_asociar_proforma       VARCHAR(250);
    l_ind_agregar_comentario     VARCHAR(2);
    l_men_agregar_comentario     VARCHAR(250);
    l_ind_adjuntar_archivos      VARCHAR(2);
    l_men_adjuntar_archivos      VARCHAR(250);
    l_ind_nueva_sol_fact         VARCHAR(2);
    l_men_nueva_sol_fact         VARCHAR(250);
    l_ind_editar_datos_fact      VARCHAR(2);
    l_men_editar_datos_fact      VARCHAR(250);
    l_ind_editar_observaciones   VARCHAR(2);
    l_men_editar_observaciones   VARCHAR(250);
    l_ind_accdir_finaciamiento   VARCHAR(2);
    l_men_accdir_finaciamiento   VARCHAR(250);
    l_ind_accdir_gestion_costos  VARCHAR(2);
    l_men_accdir_gestion_costos  VARCHAR(250);
    l_ind_accdir_capacitacion    VARCHAR(2);
    l_men_accdir_capacitacion    VARCHAR(250);
    l_ind_accdir_inmatriculacion VARCHAR(2);
    l_men_accdir_inmatriculacion VARCHAR(250);
    --indicadores de proforma
    l_ind_eliminar_proforma       VARCHAR2(2);
    l_men_eliminar_proforma       VARCHAR(250);
    l_ind_agregar_equipo_cortesia VARCHAR2(2);
    l_men_agregar_equipo_cortesia VARCHAR(250);
    l_ind_asignar_pedido          VARCHAR2(2);
    l_men_asignar_pedido          VARCHAR(250);
    l_ind_agregar_bono            VARCHAR2(2);
    l_men_agregar_bono            VARCHAR(250);
    l_ind_agregar_bono_cortesia   VARCHAR2(2);
    l_men_agregar_bono_cortesia   VARCHAR(250);
    --Indicadores pedido
    l_ind_desasignar            VARCHAR2(2);
    l_men_desasignar            VARCHAR(250);
    l_ind_asigna_defi           VARCHAR(2);
    l_men_asigna_defi           VARCHAR(250);
    l_ind_aplicar_uso_color     VARCHAR(2);
    l_men_aplicar_uso_color     VARCHAR(250);
    l_ind_agregar_equipo        VARCHAR(2);
    l_men_agregar_equipo        VARCHAR(250);
    l_ind_editar_fec_compromiso VARCHAR(2);
    l_men_editar_fec_compromiso VARCHAR(250);
    -- Mensajes
    ve_error EXCEPTION;
    l_ind_aut_ficha_vta INT;
    wn_valor            VARCHAR2(50);
    wn_num_pedido_veh   VARCHAR2(20);
    wn_cod_cia          VARCHAR2(10);
    wn_cod_prov         VARCHAR2(10);
    wn_permiso          VARCHAR2(100);
    wn_valor_permiso    VARCHAR2(1);
    wn_mensaje          VARCHAR2(2000);
  BEGIN
    --L: lectura
    --E: escritura
    --O: oculto
    --V: visible
    --B: Bloqueado
    --Variables Generales

    IF p_num_ficha_vta_veh IS NOT NULL THEN
      SELECT a.cod_estado_ficha_vta_veh
        INTO l_cod_estado_ficha_vta_veh
        FROM vve_ficha_vta_veh a
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
    END IF;

    DELETE FROM vve_permiso_pedidos a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.cod_usuario = p_cod_usua_sid;
    COMMIT;

    --------crear ficha de venta-----------------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   67,
                                                   l_ind_nueva_ficha_de_venta,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_nueva_ficha_de_venta = 'N') THEN
      l_ind_nueva_ficha_de_venta := 'B';
      l_men_nueva_ficha_de_venta := 'Usted no cuenta con permisos para crear Fichas de Venta ';
    ELSE
      l_ind_nueva_ficha_de_venta := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------descargar excel----------------------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   68,
                                                   l_ind_descargar_excel,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (nvl(l_ind_descargar_excel, 'N') = 'N') THEN
      l_ind_descargar_excel := 'V';
    ELSE
      l_ind_descargar_excel := 'O';
      l_men_descargar_excel := 'Usted no cuenta con permisos para Descargar en formato Excel ';
    END IF;

    -----------cambiar estado--------------------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   76,
                                                   l_ind_cambiar_estado,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (nvl(l_ind_cambiar_estado, 'N') = 'S') AND
       l_cod_estado_ficha_vta_veh IN ('C', 'V', 'E') THEN
      l_ind_cambiar_estado := 'V';
    ELSE
      l_ind_cambiar_estado := 'O';
      l_men_cambiar_estado := 'Usted no cuenta con permisos para cambiar de Estado ';
    END IF;
    ---------------------------------------------------------------------------

    -----------Crear solicitud excepcional-------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   55,
                                                   l_ind_crear_solicitud_excep,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (nvl(l_ind_crear_solicitud_excep, 'S') = 'S') AND
       l_cod_estado_ficha_vta_veh IN ('V') THEN
      l_ind_crear_solicitud_excep := 'V';
    ELSE
      l_ind_crear_solicitud_excep := 'O';
      l_men_crear_solicitud_excep := 'Usted no cuenta con permisos para crear una nueva Autorización ';
    END IF;
    ---------------------------------------------------------------------------

    -----------Notificar lafit-------------------------------------------------
    l_ind_notificar_lafit := 'V';
    ---------------------------------------------------------------------------

    --------descargar resumen fv-----------------------------------------------
    IF (l_cod_estado_ficha_vta_veh IN ('C', 'V', 'E')) THEN
      l_ind_fdv_resumen := 'V';
    ELSE
      l_ind_fdv_resumen := 'O';
    END IF;
    ---------------------------------------------------------------------------

    --------Asociar Proforma---------------------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   82,
                                                   l_ind_asociar_proforma,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_asociar_proforma = 'N') THEN
      l_ind_asociar_proforma := 'B';
      l_men_asociar_proforma := 'Usted no cuenta con permisos para asociar Proforma ';
    ELSE
      l_ind_asociar_proforma := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Agregar Comentario-------------------------------------------------
    l_ind_agregar_comentario := 'V';
    ---------------------------------------------------------------------------

    --------Agregar Adjuntos---------------------------------------------------
    l_ind_adjuntar_archivos := 'V';
    ---------------------------------------------------------------------------

    --------Editar Datos de Facturación----------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   86,
                                                   l_ind_editar_datos_fact,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_editar_datos_fact = 'N') THEN
      l_ind_editar_datos_fact := 'B';
      l_men_editar_datos_fact := 'Usted no cuenta con permisos para editar datos de facturación ';
    ELSE
      l_ind_editar_datos_fact := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Editar Observaciones----------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   93,
                                                   l_ind_editar_observaciones,
                                                   p_ret_esta,
                                                   p_ret_mens);

    BEGIN
      SELECT COUNT(1)
        INTO l_ind_aut_ficha_vta
        FROM vve_ficha_vta_veh_aut
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND cod_aut_ficha_vta = '01'
         AND cod_aprob_ficha_vta_aut = 'A'
         AND ind_inactivo = 'N';
    EXCEPTION
      WHEN no_data_found THEN
        l_ind_aut_ficha_vta := 0;
      WHEN OTHERS THEN
        l_ind_aut_ficha_vta := 0;
    END;

    IF (l_ind_editar_observaciones = 'N' OR
       (l_ind_editar_observaciones = 'N' AND l_ind_aut_ficha_vta > 0) OR
       (l_ind_editar_observaciones = 'S' AND l_ind_aut_ficha_vta > 0)) THEN
      l_ind_editar_observaciones := 'B';
      l_men_editar_observaciones := 'Usted no cuenta con permisos para editar Observaciones ';
    ELSE
      l_ind_editar_observaciones := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Nueva Solicitud de Facturación-------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   72,
                                                   l_ind_nueva_sol_fact,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_nueva_sol_fact = 'N') THEN
      l_ind_nueva_sol_fact := 'B';
      l_men_nueva_sol_fact := 'Usted no cuenta con permisos para generar una solicitud de facturación ';
    ELSE
      l_ind_nueva_sol_fact := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Acceso Directo - Financiamiento------------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   78,
                                                   l_ind_accdir_finaciamiento,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_accdir_finaciamiento = 'N') THEN
      l_ind_accdir_finaciamiento := 'B';
      l_men_accdir_finaciamiento := 'Usted no cuenta con permisos para acceder a ver Financiamiento ';
    ELSE
      l_ind_accdir_finaciamiento := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Acceso Directo - Gestión de Costos---------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   79,
                                                   l_ind_accdir_gestion_costos,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_accdir_gestion_costos = 'N') THEN
      l_ind_accdir_gestion_costos := 'B';
      l_men_accdir_gestion_costos := 'Usted no cuenta con permisos para acceder a ver Gestión de Costos ';
    ELSE
      l_ind_accdir_gestion_costos := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Acceso Directo - Capacitación---------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   79,
                                                   l_ind_accdir_capacitacion,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_accdir_capacitacion = 'N') THEN
      l_ind_accdir_capacitacion := 'B';
      l_men_accdir_capacitacion := 'Usted no cuenta con permisos para acceder a ver Capacitación ';
    ELSE
      l_ind_accdir_capacitacion := 'V';
    END IF;
    ---------------------------------------------------------------------------

    --------Acceso Directo - Inmatriculación---------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   79,
                                                   l_ind_accdir_inmatriculacion,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (l_ind_accdir_inmatriculacion = 'N') THEN
      l_ind_accdir_inmatriculacion := 'B';
      l_men_accdir_inmatriculacion := 'Usted no cuenta con permisos para acceder a ver Inmatriculación ';
    ELSE
      l_ind_accdir_inmatriculacion := 'V';
    END IF;
    ---------------------------------------------------------------------------

    -------------INICIO - Permisos Ficha de Venta------------------------------
    OPEN p_tab_ficha FOR
      SELECT 'ind_nueva_ficha_de_venta' permiso,
             l_ind_nueva_ficha_de_venta valor,
             l_men_nueva_ficha_de_venta mensaje
        FROM dual
      UNION
      SELECT 'ind_descargar_excel' permiso,
             l_ind_descargar_excel valor,
             l_men_descargar_excel mensaje
        FROM dual
      UNION
      SELECT 'ind_cambiar_estado' permiso,
             l_ind_cambiar_estado valor,
             l_men_cambiar_estado mensaje
        FROM dual
      UNION
      SELECT 'ind_crear_solicitud_excep' permiso,
             l_ind_crear_solicitud_excep valor,
             l_men_crear_solicitud_excep mensaje
        FROM dual
      UNION
      SELECT 'ind_notificar_lafit' permiso,
             l_ind_notificar_lafit valor,
             l_men_notificar_lafit mensaje
        FROM dual
      UNION
      SELECT 'ind_fdv_resumen' permiso,
             l_ind_fdv_resumen valor,
             l_men_fdv_resumen mensaje
        FROM dual
      UNION
      SELECT 'ind_asociar_proforma' permiso,
             l_ind_asociar_proforma valor,
             l_men_asociar_proforma mensaje
        FROM dual
      UNION
      SELECT 'ind_agregar_comentario' permiso,
             l_ind_agregar_comentario valor,
             l_men_agregar_comentario mensaje
        FROM dual
      UNION
      SELECT 'ind_adjuntar_archivos' permiso,
             l_ind_adjuntar_archivos valor,
             l_men_adjuntar_archivos mensaje
        FROM dual
      UNION
      SELECT 'ind_editar_datos_fact' permiso,
             l_ind_editar_datos_fact valor,
             l_men_editar_datos_fact mensaje
        FROM dual
      UNION
      SELECT 'ind_nueva_sol_fact' permiso,
             l_ind_nueva_sol_fact valor,
             l_men_nueva_sol_fact mensaje
        FROM dual
      UNION
      SELECT 'ind_editar_observaciones' permiso,
             l_ind_editar_observaciones valor,
             l_men_editar_observaciones mensaje
        FROM dual
      UNION
      SELECT 'ind_accdir_finaciamiento' permiso,
             l_ind_accdir_finaciamiento valor,
             l_men_accdir_finaciamiento mensaje
        FROM dual
      UNION
      SELECT 'ind_accdir_gestion_costos' permiso,
             l_ind_accdir_gestion_costos valor,
             l_men_accdir_gestion_costos mensaje
        FROM dual
      UNION
      SELECT 'ind_accdir_capacitacion' permiso,
             l_ind_accdir_capacitacion valor,
             l_men_accdir_capacitacion mensaje
        FROM dual
      UNION
      SELECT 'ind_accdir_inmatriculacion' permiso,
             l_ind_accdir_inmatriculacion valor,
             l_men_accdir_inmatriculacion mensaje
        FROM dual;
    -------------FIN - Permisos Ficha de Venta---------------------------------

    -------------INICIO - Permisos Proforma------------------------------------
    OPEN l_cursor_proformas FOR
      SELECT a.num_prof_veh, COUNT(b.num_pedido_veh)
        FROM vve_ficha_vta_proforma_veh a
        LEFT JOIN vve_ficha_vta_pedido_veh b
          ON a.num_ficha_vta_veh = b.num_ficha_vta_veh
         AND a.num_prof_veh = b.num_prof_veh
         AND b.ind_inactivo = 'N'
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND a.ind_inactivo = 'N'
       GROUP BY a.num_prof_veh;

    l_sql_prof := '';
    l_contador := 0;
    LOOP
      FETCH l_cursor_proformas
        INTO l_num_prof_veh, l_cant_pedidos;
      EXIT WHEN l_cursor_proformas%NOTFOUND;

      -----l_ind_eliminar_proforma---------------------------------------------
      IF l_cant_pedidos = 0 THEN
        l_ind_eliminar_proforma := 'V';
      ELSE
        l_ind_eliminar_proforma := 'O';
        l_men_eliminar_proforma := 'Usted no cuenta con permisos para eliminar Proforma ';
      END IF;
      l_contador := l_contador + 1;

      IF l_contador > 1 THEN
        l_sql_prof := l_sql_prof || ' UNION ';
      END IF;

      l_sql_prof := l_sql_prof || ' select ''' || l_num_prof_veh ||
                    ''' num_prof_veh,
                    ''ind_eliminar_proforma'' permiso,''' ||
                    l_ind_eliminar_proforma || ''' valor, ''' ||
                    l_men_eliminar_proforma || ''' mensaje from dual';
      -------------------------------------------------------------------------

      -----ind_agregar_equipo_cortesia-----------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     73,
                                                     l_ind_agregar_equipo_cortesia,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (nvl(l_ind_agregar_equipo_cortesia, 'N') = 'S') AND
         l_cod_estado_ficha_vta_veh IN ('V') THEN
        l_ind_agregar_equipo_cortesia := 'V';
        l_men_agregar_equipo_cortesia := '';
      ELSE
        l_ind_agregar_equipo_cortesia := 'O';
      END IF;
      l_sql_prof := l_sql_prof || ' UNION ';
      l_sql_prof := l_sql_prof || ' select ''' || l_num_prof_veh ||
                    ''' num_prof_veh,
                    ''ind_agregar_equipo_cortesia'' permiso,''' ||
                    l_ind_agregar_equipo_cortesia || ''' valor, ''' ||
                    l_men_agregar_equipo_cortesia || ''' mensaje from dual';
      -------------------------------------------------------------------------

      -----Asignar Pedido------------------------------------------------------
      /*
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     70,
                                                     l_ind_asignar_pedido,
                                                     p_ret_esta,
                                                     p_ret_mens);
                                                     */
      SELECT decode(COUNT(*), 0, 'N', 'S')
        INTO l_ind_asignar_pedido
        FROM sis_mae_perfil_procesos a
       INNER JOIN sis_mae_perfil_usuario b
          ON a.cod_id_perfil = b.cod_id_perfil
       WHERE a.cod_id_procesos = 70
         AND b.cod_id_usuario = p_cod_usua_web
         AND a.ind_realiza = 'S'
         AND nvl(a.ind_inactivo, 'N') = 'N'
         AND nvl(b.ind_inactivo, 'N') = 'N';

      IF (l_ind_asignar_pedido = 'N') THEN
        l_ind_asignar_pedido := 'O';
        l_men_asignar_pedido := 'Usted no cuenta con permisos para asignar Pedido ';
      ELSE
        l_ind_asignar_pedido := 'V';
      END IF;
      l_sql_prof := l_sql_prof || ' UNION ';
      l_sql_prof := l_sql_prof || ' select ''' || l_num_prof_veh ||
                    ''' num_prof_veh,
                    ''ind_asignar_pedido'' permiso,''' ||
                    l_ind_asignar_pedido || ''' valor, ''' ||
                    l_men_asignar_pedido || ''' mensaje from dual';
      -------------------------------------------------------------------------

      -----Agregar Bono--------------------------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     74,
                                                     l_ind_agregar_bono,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_agregar_bono = 'N') THEN
        l_ind_agregar_bono := 'O';
        l_men_agregar_bono := 'Usted no cuenta con permisos para agregar Bono ';
      ELSE
        l_ind_agregar_bono := 'V';
      END IF;
      l_sql_prof := l_sql_prof || ' UNION ';
      l_sql_prof := l_sql_prof || ' select ''' || l_num_prof_veh ||
                    ''' num_prof_veh,
                    ''ind_agregar_bono'' permiso,''' ||
                    l_ind_agregar_bono || ''' valor, ''' ||
                    l_men_agregar_bono || ''' mensaje from dual';
      -------------------------------------------------------------------------

      -----Agregar Bono Cortesia-----------------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     92,
                                                     l_ind_agregar_bono_cortesia,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_agregar_bono_cortesia = 'N') THEN
        l_ind_agregar_bono_cortesia := 'O';
        l_men_agregar_bono_cortesia := 'Usted no cuenta con permisos para agregar Bono Cortesia ';
      ELSE
        l_ind_agregar_bono_cortesia := 'V';
      END IF;
      l_sql_prof := l_sql_prof || ' UNION ';
      l_sql_prof := l_sql_prof || ' select ''' || l_num_prof_veh ||
                    ''' num_prof_veh,
                    ''ind_agregar_bono_cortesia'' permiso,''' ||
                    l_ind_agregar_bono_cortesia || ''' valor, ''' ||
                    l_men_agregar_bono_cortesia || ''' mensaje from dual';
      -------------------------------------------------------------------------
    END LOOP;
    CLOSE l_cursor_proformas;

    IF l_contador = 0 THEN
      l_sql_prof := 'select * from dual';
    END IF;
    OPEN p_tab_proforma FOR l_sql_prof;
    -------------FIN - Permisos Proforma---------------------------------------

    -------------INICIO - Permisos Pedidos-------------------------------------
    OPEN l_cursor_pedidos FOR
      SELECT a.num_pedido_veh,
             a.cod_cia,
             a.cod_prov,
             b.cod_estado_pedido_veh
        FROM vve_ficha_vta_pedido_veh a
       INNER JOIN vve_pedido_veh b
          ON a.num_pedido_veh = b.num_pedido_veh
         AND a.cod_cia = b.cod_cia
         AND a.cod_prov = b.cod_prov
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND a.ind_inactivo = 'N';

    l_sql_ped                 := '';
    l_sql_ped_desasignar      := '';
    l_sql_ped_asignar         := '';
    l_sql_ped_uso_color       := '';
    l_sql_ped_soli_fact       := '';
    l_sql_ped_edit_datos      := '';
    l_sql_ped_egragar_equipos := '';
    l_sql_ped_egragar_bonos   := '';
    l_sql_ped_fec_compromiso  := '';

    l_contador := 0;
    LOOP
      FETCH l_cursor_pedidos
        INTO l_num_pedido_veh,
             l_cod_cia,
             l_cod_prov,
             l_cod_estado_pedido_veh;
      EXIT WHEN l_cursor_pedidos%NOTFOUND;

      -----l_ind_desasignar----------------------------------------------------
      l_men_desasignar := '';
      IF l_cod_estado_pedido_veh IN ('P', 'D') THEN
        l_ind_desasignar := 'V';
      ELSE
        l_ind_desasignar := 'B';
        l_men_desasignar := 'El pedido:' || l_num_pedido_veh ||
                            ' No se puede desasignar en el estado actual';
      END IF;
      l_contador := l_contador + 1;

      IF l_contador > 1 THEN
        l_sql_ped_desasignar := l_sql_ped_desasignar || ' UNION ';
      END IF;

      l_sql_ped_desasignar := ' select ''' || l_num_pedido_veh ||
                              ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                              ''' cod_cia,''' || l_cod_prov ||
                              ''' cod_prov,
                   ''ind_desasignar'' permiso,''' ||
                              l_ind_desasignar || ''' valor,
                   ''' || l_men_desasignar ||
                              ''' mensaje from dual';
      -------------------------------------------------------------------------

      ------l_ind_asignar definitivamente--------------------------------------
      l_men_asigna_defi := '';
      --<I-86862 Corregir correo por asignación definitiva>
      IF l_ind_asignar_pedido = 'V' THEN
        --<F-86862 Corregir correo por asignación definitiva>
        IF l_cod_estado_pedido_veh IN ('P', 'F') THEN
          l_ind_asigna_defi := 'V';
          IF (pkg_pedido_veh.fun_tipo_stock_sit_pedido(l_cod_cia,
                                                       l_cod_prov,
                                                       l_num_pedido_veh) = '2') THEN
            l_ind_asigna_defi := 'B';
            l_men_asigna_defi := 'El pedido:' || l_num_pedido_veh ||
                                 ' Está en transito, no se puede realizar la asignación definitiva';
          END IF;
        ELSE
          l_ind_asigna_defi := 'B';
          l_men_asigna_defi := 'El pedido:' || l_num_pedido_veh ||
                               ' No se puede asignar definitivamente en el estado actual';

        END IF;
        --<I-86862 Corregir correo por asignación definitiva>
      ELSE
        l_ind_asigna_defi := 'B';
        l_men_asigna_defi := 'Usted no tiene permisos para realizar la asignación definitiva';
      END IF;
      --<F-86862 Corregir correo por asignación definitiva>
      l_sql_ped_asignar := ' UNION ';
      l_sql_ped_asignar := l_sql_ped_asignar || ' select ''' ||
                           l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                           ''' cod_cia,
                   ''' || l_cod_prov ||
                           ''' cod_prov,
                   ''ind_asigna_defi'' permiso,''' ||
                           l_ind_asigna_defi || ''' valor,
                   ''' || l_men_asigna_defi ||
                           ''' mensaje from dual';
      -------------------------------------------------------------------------

      -----Aplicar Uso y Color------------------------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     84,
                                                     l_ind_aplicar_uso_color,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_aplicar_uso_color = 'N') THEN
        l_ind_aplicar_uso_color := 'O';
        l_men_aplicar_uso_color := 'Usted no cuenta con permisos para aplicar Uso y Color ';
      ELSE
        l_ind_aplicar_uso_color := 'V';
      END IF;

      l_sql_ped_uso_color := ' UNION ';
      l_sql_ped_uso_color := l_sql_ped_uso_color || ' select ''' ||
                             l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                             ''' cod_cia,
                   ''' || l_cod_prov ||
                             ''' cod_prov,
                   ''ind_aplicar_uso_color'' permiso,''' ||
                             l_ind_aplicar_uso_color ||
                             ''' valor,
                   ''' ||
                             l_men_aplicar_uso_color ||
                             ''' mensaje from dual';
      -------------------------------------------------------------------------

      --------Nueva Solicitud de Facturación-----------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     72,
                                                     l_ind_nueva_sol_fact,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_nueva_sol_fact = 'N') THEN
        l_ind_nueva_sol_fact := 'B';
        l_men_nueva_sol_fact := 'Usted no cuenta con permisos para generar una solicitud de facturación ';
      ELSE
        l_ind_nueva_sol_fact := 'V';
      END IF;

      l_sql_ped_soli_fact := ' UNION ';
      l_sql_ped_soli_fact := l_sql_ped_soli_fact || ' select ''' ||
                             l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                             ''' cod_cia,
                   ''' || l_cod_prov ||
                             ''' cod_prov,
                   ''ind_nueva_sol_fact'' permiso,''' ||
                             l_ind_nueva_sol_fact || ''' valor,
                   ''' || l_men_nueva_sol_fact ||
                             ''' mensaje from dual';
      -------------------------------------------------------------------------

      --------Editar Datos de Facturación--------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     86,
                                                     l_ind_editar_datos_fact,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_editar_datos_fact = 'N') THEN
        l_ind_editar_datos_fact := 'B';
        l_men_editar_datos_fact := 'Usted no cuenta con permisos para editar datos de facturación ';
      ELSE
        l_ind_editar_datos_fact := 'V';
      END IF;

      l_sql_ped_edit_datos := ' UNION ';
      l_sql_ped_edit_datos := l_sql_ped_edit_datos || ' select ''' ||
                              l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                              ''' cod_cia,
                   ''' || l_cod_prov ||
                              ''' cod_prov,
                   ''ind_editar_datos_fact'' permiso,''' ||
                              l_ind_editar_datos_fact ||
                              ''' valor,
                   ''' ||
                              l_men_editar_datos_fact ||
                              ''' mensaje from dual';
      -------------------------------------------------------------------------

      --------Agregar Equipo---------------------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     87,
                                                     l_ind_agregar_equipo,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_agregar_equipo = 'N') THEN
        l_ind_agregar_equipo    := 'B';
        l_men_editar_datos_fact := 'Usted no cuenta con permisos para agregar Equipo ';
      ELSE
        l_ind_agregar_equipo := 'V';
      END IF;

      l_sql_ped_egragar_equipos := ' UNION ';
      l_sql_ped_egragar_equipos := l_sql_ped_egragar_equipos ||
                                   ' select ''' || l_num_pedido_veh ||
                                   ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                                   ''' cod_cia,
                   ''' || l_cod_prov ||
                                   ''' cod_prov,
                   ''ind_agregar_equipo'' permiso,''' ||
                                   l_ind_agregar_equipo ||
                                   ''' valor,
                   ''' ||
                                   l_men_agregar_equipo ||
                                   ''' mensaje from dual';
      -------------------------------------------------------------------------

      --------Agregar Bono---------------------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     74,
                                                     l_ind_agregar_bono,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_agregar_bono = 'N') THEN
        l_ind_agregar_bono := 'O';
        l_men_agregar_bono := 'Usted no cuenta con permisos para agregar Bono ';
      ELSE
        l_ind_agregar_bono := 'V';
      END IF;
      l_sql_ped_egragar_bonos := ' UNION ';
      l_sql_ped_egragar_bonos := l_sql_ped_egragar_bonos || ' select ''' ||
                                 l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                                 ''' cod_cia,
                   ''' || l_cod_prov ||
                                 ''' cod_prov,
                   ''ind_agregar_bono'' permiso,''' ||
                                 l_ind_agregar_bono ||
                                 ''' valor,
                   ''' ||
                                 l_men_agregar_bono ||
                                 ''' mensaje from dual';
      -------------------------------------------------------------------------    
      --------Editar Fechas de Compromiso--------------------------------------
      sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                     88,
                                                     l_ind_editar_fec_compromiso,
                                                     p_ret_esta,
                                                     p_ret_mens);
      IF (l_ind_editar_fec_compromiso = 'N') THEN
        l_ind_editar_fec_compromiso := 'O';
        l_men_editar_fec_compromiso := 'Usted no cuenta con permisos para editar fechas de compromiso ';
      ELSE
        l_ind_editar_fec_compromiso := 'V';
      END IF;
      l_sql_ped_fec_compromiso := ' UNION ';
      l_sql_ped_fec_compromiso := l_sql_ped_fec_compromiso || ' select ''' ||
                                  l_num_pedido_veh || ''' num_pedido_veh,
                   ''' || l_cod_cia ||
                                  ''' cod_cia,
                   ''' || l_cod_prov ||
                                  ''' cod_prov,
                   ''ind_editar_fec_compromiso'' permiso,''' ||
                                  l_ind_editar_fec_compromiso ||
                                  ''' valor,
                   ''' ||
                                  l_men_editar_fec_compromiso ||
                                  ''' mensaje from dual';
      -------------------------------------------------------------------------

      OPEN p_query_permis_pedidos FOR l_sql_ped_desasignar || l_sql_ped_asignar || l_sql_ped_uso_color || l_sql_ped_soli_fact || l_sql_ped_edit_datos || l_sql_ped_egragar_equipos || l_sql_ped_egragar_bonos || l_sql_ped_fec_compromiso;
      LOOP
        FETCH p_query_permis_pedidos
          INTO wn_num_pedido_veh,
               wn_cod_cia,
               wn_cod_prov,
               wn_permiso,
               wn_valor_permiso,
               wn_mensaje;
        INSERT INTO vve_permiso_pedidos
        VALUES
          (p_num_ficha_vta_veh,
           p_cod_usua_sid,
           wn_num_pedido_veh,
           wn_cod_cia,
           wn_cod_prov,
           wn_permiso,
           wn_valor_permiso,
           wn_mensaje,
           SYSDATE);

        EXIT WHEN p_query_permis_pedidos%NOTFOUND;

      END LOOP CLOSE;

    END LOOP;
    CLOSE l_cursor_pedidos;

    IF l_contador = 0 THEN
      l_sql_ped := 'select * from dual';
      OPEN p_tab_pedidos FOR l_sql_ped;

    ELSE
      OPEN p_tab_pedidos FOR
        SELECT *
          FROM vve_permiso_pedidos
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
           AND cod_usuario = p_cod_usua_sid;

    END IF;

    DELETE FROM vve_permiso_pedidos
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND cod_usuario = p_cod_usua_sid;
    COMMIT;
    p_ret_mens := 'Consulta exitosa';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_perm_usua_ficha' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_perm_usua_ficha',
                                          p_cod_usua_sid,
                                          'Permisos de Ficha',
                                          p_ret_mens || '-' || l_sql_ped,
                                          NULL);
  END sp_perm_usua_ficha;

  FUNCTION sp_fun_str_config_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2 IS
    wn_resultado VARCHAR2(3000);
    wn_valor     VARCHAR2(50);
    contador     NUMBER;
    c_lista      SYS_REFCURSOR;
  BEGIN

    wn_resultado := '';
    contador     := 0;
    OPEN c_lista FOR
      SELECT DISTINCT vc.des_config_veh
        FROM venta.vve_ficha_vta_proforma_veh f,
             venta.vve_proforma_veh           p,
             venta.vve_proforma_veh_det       pd,
             venta.vve_config_veh             vc
       WHERE f.num_prof_veh = p.num_prof_veh
         AND p.num_prof_veh = pd.num_prof_veh
         AND f.num_ficha_vta_veh = x_num_ficha_vta_veh
         AND vc.cod_marca = pd.cod_marca
         AND vc.cod_baumuster = pd.cod_baumuster
         AND vc.cod_config_veh = pd.cod_config_veh
         AND nvl(f.ind_inactivo, 'N') = 'N'
         AND rownum = 1;

    LOOP
      FETCH c_lista
        INTO wn_valor;
      EXIT WHEN c_lista%NOTFOUND;
      IF (contador != 0) THEN
        wn_resultado := wn_resultado || ',';
      END IF;
      wn_resultado := wn_resultado || wn_valor;
      contador     := contador + 1;
    END LOOP;
    CLOSE c_lista;

    RETURN wn_resultado;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;

  END sp_fun_str_config_ficha_vta;

  FUNCTION sp_fun_str_marca_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2 IS
    wn_resultado VARCHAR2(3000);
    wn_valor     VARCHAR2(25);
    contador     NUMBER;
    c_lista      SYS_REFCURSOR;
  BEGIN

    wn_resultado := '';
    contador     := 0;
    OPEN c_lista FOR
      SELECT DISTINCT gm.nom_marca
        FROM venta.vve_ficha_vta_proforma_veh f,
             venta.vve_proforma_veh           p,
             venta.vve_proforma_veh_det       pd,
             generico.gen_marca               gm
       WHERE f.num_prof_veh = p.num_prof_veh
         AND p.num_prof_veh = pd.num_prof_veh
         AND f.num_ficha_vta_veh = x_num_ficha_vta_veh
         AND gm.cod_marca = pd.cod_marca
         AND nvl(f.ind_inactivo, 'N') = 'N';

    LOOP
      FETCH c_lista
        INTO wn_valor;
      EXIT WHEN c_lista%NOTFOUND;
      IF (contador != 0) THEN
        wn_resultado := wn_resultado || ',';
      END IF;
      wn_resultado := wn_resultado || wn_valor;
      contador     := contador + 1;
    END LOOP;
    CLOSE c_lista;

    RETURN wn_resultado;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;

  END sp_fun_str_marca_ficha_vta;

  FUNCTION sp_fun_str_pedido_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2 IS
    wn_resultado VARCHAR2(3000);
    wn_valor     VARCHAR2(10);
    contador     NUMBER;
    c_lista      SYS_REFCURSOR;
  BEGIN

    wn_resultado := '';
    contador     := 0;
    OPEN c_lista FOR
      SELECT DISTINCT (f.num_pedido_veh)
        FROM venta.vve_ficha_vta_pedido_veh f
       WHERE f.num_ficha_vta_veh = x_num_ficha_vta_veh
         AND nvl(f.ind_inactivo, 'N') = 'N';

    LOOP
      FETCH c_lista
        INTO wn_valor;
      EXIT WHEN c_lista%NOTFOUND;
      IF (contador != 0) THEN
        wn_resultado := wn_resultado || ',';
      END IF;
      wn_resultado := wn_resultado || wn_valor;
      contador     := contador + 1;
    END LOOP;
    CLOSE c_lista;

    RETURN wn_resultado;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;

  END sp_fun_str_pedido_ficha_vta;

  FUNCTION sp_fun_str_prof_ficha_vta(x_num_ficha_vta_veh VARCHAR2)
    RETURN VARCHAR2 IS
    wn_resultado VARCHAR2(3000);
    wn_valor     VARCHAR2(10);
    contador     NUMBER;
    c_lista      SYS_REFCURSOR;
  BEGIN

    wn_resultado := '';
    contador     := 0;
    OPEN c_lista FOR
      SELECT DISTINCT (f.num_prof_veh)
        FROM venta.vve_ficha_vta_proforma_veh f
       WHERE f.num_ficha_vta_veh = x_num_ficha_vta_veh
         AND nvl(f.ind_inactivo, 'N') = 'N';

    LOOP
      FETCH c_lista
        INTO wn_valor;
      EXIT WHEN c_lista%NOTFOUND;
      IF (contador != 0) THEN
        wn_resultado := wn_resultado || ',';
      END IF;
      wn_resultado := wn_resultado || wn_valor;
      contador     := contador + 1;
    END LOOP;
    CLOSE c_lista;

    RETURN wn_resultado;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;

  END sp_fun_str_prof_ficha_vta;

END pkg_sweb_five_mant;