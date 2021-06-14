create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_MAESTRO AS
PROCEDURE sp_list_maestro
  (
    p_tipo              IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    v_cod_pais           VARCHAR2(10);
  BEGIN
    v_cod_pais := '';
    
    IF p_tipo = 'CIA' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_cia AS cod_tipo, 
               nom_sociedad AS descripcion,
               '' AS  valor_adicional
          FROM gen_mae_sociedad;
    END IF;
    
    IF p_tipo = 'FILIAL' THEN
        OPEN p_ret_cursor FOR
        SELECT DISTINCT(cod_filial) AS cod_tipo, 
                nom_filial AS descripcion, 
                '' AS valor_adicional 
          FROM gen_filial WHERE cod_cia in ('06','09') 
           AND cod_dpto||cod_provincia||cod_distrito IS NOT NULL;
    END IF;
    
    IF p_tipo = 'AV' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_area_vta AS cod_tipo, 
               des_area_vta AS descripcion,
               '' AS  valor_adicional
          FROM gen_area_vta 
         WHERE negocio_ventas = 'S' 
           AND ind_inactivo ='N';
    END IF;
    IF p_tipo = 'ZO' THEN
        OPEN p_ret_cursor FOR
        SELECT TO_CHAR(cod_zona) AS cod_tipo,
               des_zona AS descripcion,
               '' AS  valor_adicional
          FROM vve_mae_zona;
    END IF;
    IF p_tipo = 'PR' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_id_provincia AS cod_tipo,
               des_nombre AS descripcion,
               '' AS  valor_adicional
          FROM gen_mae_provincia;
    END IF;
    IF p_tipo = 'DE' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_id_departamento AS cod_tipo,
                   des_nombre AS descripcion,
                   '' AS  valor_adicional
              FROM gen_mae_departamento;
    END IF;
    IF p_tipo = 'DI' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_id_distrito AS cod_tipo,
               des_nombre AS descripcion,
               '' AS  valor_adicional
          FROM gen_mae_distrito;
    END IF;
    IF p_tipo = 'MA' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_marca AS cod_tipo,
               nom_marca AS descripcion,
               '' AS  valor_adicional
          FROM gen_marca;
    END IF;
    IF p_tipo = 'AC' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_tipo_actividad AS cod_tipo,
               des_tipo_actividad AS descripcion,
               '' AS  valor_adicional
          FROM vve_credito_tipo_actividad;
    END IF;
    IF p_tipo = 'VE' THEN
        OPEN p_ret_cursor FOR
        SELECT cod_tipo_veh AS cod_tipo,
               des_tipo_veh AS descripcion,
               '' AS  valor_adicional
          FROM vve_tipo_veh;
    END IF;
    IF p_tipo = 'PA' THEN
        OPEN p_ret_cursor FOR
      SELECT cod_pais AS cod_tipo,
             nom_pais AS descripcion,
             '' AS valor_adicional
        FROM gen_pais;
    END IF;

    IF p_tipo = 'MO' THEN
        OPEN p_ret_cursor FOR
      SELECT cod_moneda AS cod_tipo,
             des_moneda AS descripcion,
             '' AS valor_adicional
        FROM gen_moneda;
    END IF;
    IF p_tipo = 'TD' THEN
        OPEN p_ret_cursor FOR
        SELECT  cod_tipo_docu_iden AS cod_tipo,
                avb_tipo_docu_iden AS descripcion,
                '' AS valor_adicional
          FROM gen_tipo_docu_iden 
         WHERE avb_tipo_docu_iden IN ('D.N.I ','R.U.C.','C.E ');
    END IF;
    IF p_tipo = 'TG' THEN
        OPEN p_ret_cursor FOR
        SELECT  'Hipotecaria' AS cod_tipo, 'Hipotecaria' AS descripcion, '' AS valor_adicional FROM dual
        UNION
        SELECT  'Mobiliaria' AS cod_tipo, 'Mobiliaria' AS descripcion, '' AS valor_adicional FROM dual;
    END IF;
    IF p_tipo = 'AVTA' THEN
        OPEN p_ret_cursor FOR
          SELECT cod_area_vta AS cod_tipo,
                 des_area_vta AS descripcion,
                 '' as valor_adicional
            FROM gen_area_vta 
            WHERE cod_area_vta in ('001','003','009','008','017','018')
            ORDER BY 1;
    END IF;
    
    IF p_tipo = '06' OR p_tipo = '09'  THEN
        SELECT cod_id_pais INTO v_cod_pais FROM gen_mae_sociedad WHERE cod_cia = p_tipo;
        OPEN p_ret_cursor FOR
            SELECT cod_id_provincia AS cod_tipo,
                   des_nombre AS descripcion,
                   '' AS valor_adicional
              FROM gen_mae_provincia WHERE cod_id_departamento 
                IN (SELECT cod_id_departamento FROM gen_mae_departamento WHERE cod_id_pais = v_cod_pais) ORDER BY 1;
 
    END IF;
    
    
    --IF p_tipo NOT IN ('AV','ZO','86','92','PR','DE','DI','MA','AC','VE','PA','MO','TD','AVTA','06','09') THEN
    IF p_tipo NOT IN ('CIA', 'FILIAL','AV','ZO','PR','DE','DI','MA','AC','VE','PA','MO','TD','TG','AVTA','06','09','PAIS','FILIALES','SUC','RU','USU') THEN
        OPEN p_ret_cursor FOR
        SELECT cod_tipo,
               descripcion,
               valor_adic_1 AS valor_adicional
          FROM vve_tabla_maes WHERE COD_GRUPO = p_tipo
          AND orden_pres IS NOT NULL;
    END IF;
 
    IF p_tipo = 'FILIALES' THEN
        OPEN p_ret_cursor FOR
        SELECT DISTINCT(cod_filial) AS cod_tipo, 
                nom_filial AS descripcion, 
                '' AS valor_adicional 
          FROM gen_filiales WHERE  cod_dpto||cod_provincia||cod_distrito IS NOT NULL;
    END IF;
       
    
   IF p_tipo = 'PAIS' THEN
        OPEN p_ret_cursor FOR
          SELECT cod_id_pais AS cod_tipo,
                 des_nombre AS descripcion,
                  '' AS valor_adicional
            FROM gen_mae_pais;
    END IF;
    
    IF p_tipo = 'SUC' THEN
        OPEN p_ret_cursor FOR
          SELECT cod_sucursal AS cod_tipo,
                 nom_sucursal AS descripcion
            FROM gen_sucursales;
    END IF;
    
    IF p_tipo = 'RU' THEN
        OPEN p_ret_cursor FOR
          SELECT cod_rol_usuario AS cod_tipo,
                 des_rol_usuario AS descripcion
            FROM sistemas.rol_usuario
            ORDER BY des_rol_usuario;
    END IF;
    
    IF p_tipo = 'USU' THEN
        OPEN p_ret_cursor FOR
          SELECT cod_id_usuario AS cod_tipo,
                 txt_usuario AS descripcion
            FROM sis_mae_usuario
            ORDER BY txt_usuario;
    END IF;
    
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
  END;
END PKG_SWEB_CRED_MAESTRO; 