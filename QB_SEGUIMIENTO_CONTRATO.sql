CREATE OR REPLACE PACKAGE                     RHU.QB_SEGUIMIENTO_CONTRATO AS
--******************************************************************************
--** NOMBRE SCRIPT        : QRHU0050
--** OBJETIVO             : HEAD LOGICA APLICATIVO SEGUIMIENTO CONTRATO
--** ESQUEMA              : RHU.QB_SEGUIMIENTO_CONTRATO
--** NOMBRE               : QB_SEGUIMIENTO_CONTRATO / HEAD
--** AUTOR                : DESIERRA
--** FECHA CREACION       : 2023/02/07
--******************************************************************************

TYPE vcrefcursor IS REF CURSOR;
PROCEDURE pl_consultar_coordinadores(
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);
                                      
PROCEDURE pl_consultar_informacion_ana(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2); 
PROCEDURE pl_consultar_informacion_exp(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);    
                                      

PROCEDURE pl_consultar_seguimiento_can(
                                      nmlibconsecutivo       IN NUMBER,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);
                                      
 
PROCEDURE pl_consultar_informacion_can(
                                      nmlibconsecutivo       IN NUMBER,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);                                     

PROCEDURE pl_consultar_contratos_coor(
                                      vcusuario              IN VARCHAR2,
                                      vccoordinador          IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);   
                                      

PROCEDURE pl_consultar_info_analista(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2);                                       

END QB_SEGUIMIENTO_CONTRATO;
/


CREATE OR REPLACE PACKAGE BODY                            RHU.QB_SEGUIMIENTO_CONTRATO  AS
--******************************************************************************
--** NOMBRE SCRIPT        : QRHU0050
--** OBJETIVO             : BODY LOGICA APLICATIVO SEGUIMIENTO CONTRATO
--** ESQUEMA              : RHU.QB_SEGUIMIENTO_CONTRATO
--** NOMBRE               : QB_SEGUIMIENTO_CONTRATO / BODY
--** AUTOR                : DESIERRA
--** FECHA CREACION       : 2023/02/07
--******************************************************************************
PROCEDURE pl_consultar_coordinadores( 
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2) IS

 BEGIN
 OPEN vcconsulta FOR 
 SELECT distinct b.usu_usuario usuario, b.usu_nombre nombre_usuario ,b.ubicacion ubicacion
             FROM  TMP.VDATOS_RIC A ,USUARIOS B 
             WHERE A.EPL_ND=B.EPL_ND
             AND TCA_CODIGO= 5
             and b.rod_id = 5;
                    
            vcestado_proceso     := 'S';
            vcmensaje_proceso    := 'Consulta ok';
    exception
        when others then
            vcestado_proceso     := 'N';
            vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_coordinadores: '||sqlerrm;

 END;
 
 
 PROCEDURE pl_consultar_contratos_coor(
                                      vcusuario              IN VARCHAR2,
                                      vccoordinador          IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2) IS                   
BEGIN
 OPEN vcconsulta FOR
          SELECT lib.TDC_TD_EPL tipo_documento, 
          lib.epl_nd numero_documento ,
          Fb_Epl_nombres(lib.TDC_TD_EPL, lib.epl_nd) nombre_empleado,
          lib.REC_FECHA  fecha_registro,
          rhu.fb_empresa(lib.tdc_td_fil,lib.emp_nd_fil) empresa,
          adm.FB_CAL_TIEM_FECHAS(lib.lib_fecha_estado,sysdate) timepo_trancurrido,
          lib.TDC_TD_FIL tipo_documento_filial,
          lib.EMP_ND_FIL numero_documento_filial,
          Fb_Epl_Telefono(lib.TDC_TD_EPL, lib.epl_nd, 'CELULAR') telefono,
          lib.LIB_FECHA_ESTADO fecha_estado,
          vdt.DAR_RESPONSABLE responsable,
          lib.LIB_ESTADO estado_lib, 
          lib.LIB_CONSECUTIVO lib_consecutivo,
          seg.OBSERVACION observacionTemporal,
          seg.SEG_ESTADO estadoTemporal,
          SFC.SCC_URL_ENVIADA url_enviada,
               (SELECT *
                    FROM (SELECT ID
                    FROM (SELECT *
                           from ADM.SEG_FIRMA_CTO_CONCATENADO where LIB_CONSECUTIVO =lib.LIB_CONSECUTIVO 
                           ),
                   JSON_TABLE ( SCC_RESPUESTA, '$data'
                   COLUMNS ( "id" PATH '$.status'))t )) respuestaws  
       FROM 
          (SELECT MAX(INC_FECHA_MOD) , LIB_CONSECUTIVO
           FROM aud_estado_li WHERE  INC_USUARIO_NUE = 'WFORERO'  group by LIB_CONSECUTIVO) aud ,
          (SELECT DISTINCT(DAR_RESPONSABLE), TDC_TD_FIL,EMP_ND_FIL  , LISTAGG(USU_USUARIO, ', ') WITHIN GROUP(ORDER BY USU_USUARIO) usuarios
           FROM TMP.VDATOS_RIC A ,USUARIOS B 
           WHERE A.EPL_ND=B.EPL_ND AND TCA_CODIGO=5  group by (DAR_RESPONSABLE), TDC_TD_FIL, EMP_ND_FIL ) vdt,
           LIBROINGRESO lib , rhu.seg_firma_cto_expira seg ,  ADM.SEG_FIRMA_CTO_CONCATENADO SFC
           WHERE aud.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           and lib.TDC_TD_FIL = vdt.TDC_TD_FIL
           and lib.EMP_ND_FIL = vdt.EMP_ND_FIL
           and seg.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           and SFC.LIB_CONSECUTIVO =  lib.LIB_CONSECUTIVO
           AND lib.LIB_ESTADO IN ('PFC','PFR','CTO')
           AND vdt.DAR_RESPONSABLE = vccoordinador;
    
             
           vcestado_proceso     := 'S';
           vcmensaje_proceso    := 'Consulta ok';
             
    EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
            vcmensaje_proceso    := 'Error consultando RHU.QB_SEGUIMIENTO_CONTRATO.pl_consultar_contratos_coor: '||sqlerrm;
END;

 
 PROCEDURE pl_consultar_informacion_ana(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2) IS
BEGIN
 OPEN vcconsulta FOR
          SELECT lib.TDC_TD_EPL tipo_documento, 
          lib.epl_nd numero_documento ,
          Fb_Epl_nombres(lib.TDC_TD_EPL, lib.epl_nd) nombre_empleado,
          lib.REC_FECHA  fecha_registro,
          rhu.fb_empresa(lib.tdc_td_fil,lib.emp_nd_fil) empresa,
          adm.FB_CAL_TIEM_FECHAS(lib.lib_fecha_estado,sysdate) timepo_trancurrido,
          lib.TDC_TD_FIL tipo_documento_filial,
          lib.EMP_ND_FIL numero_documento_filial,
          Fb_Epl_Telefono(lib.TDC_TD_EPL, lib.epl_nd, 'CELULAR') telefono,
          lib.LIB_FECHA_ESTADO fecha_estado,
          vdt.DAR_RESPONSABLE responsable,
          lib.LIB_ESTADO estado_lib, 
          lib.LIB_CONSECUTIVO lib_consecutivo,
          seg.OBSERVACION observacionTemporal,
          seg.SEG_ESTADO estadoTemporal,
          SFC.SCC_URL_ENVIADA url_enviada,
               (SELECT *
                    FROM (SELECT ID
                    FROM (SELECT *
                           from ADM.SEG_FIRMA_CTO_CONCATENADO where LIB_CONSECUTIVO =lib.LIB_CONSECUTIVO 
                           ),
                   JSON_TABLE ( SCC_RESPUESTA, '$data'
                   COLUMNS ( "id" PATH '$.status'))t )) respuestaws  
       FROM 
          (SELECT MAX(INC_FECHA_MOD) , LIB_CONSECUTIVO
           FROM aud_estado_li WHERE  INC_USUARIO_NUE = 'WFORERO'  group by LIB_CONSECUTIVO) aud ,
          (SELECT DISTINCT(DAR_RESPONSABLE), TDC_TD_FIL,EMP_ND_FIL  , LISTAGG(USU_USUARIO, ', ') WITHIN GROUP(ORDER BY USU_USUARIO) usuarios
           FROM TMP.VDATOS_RIC A ,USUARIOS B 
           WHERE A.EPL_ND=B.EPL_ND AND TCA_CODIGO=5  group by (DAR_RESPONSABLE), TDC_TD_FIL, EMP_ND_FIL ) vdt,
           LIBROINGRESO lib , rhu.seg_firma_cto_expira seg ,  ADM.SEG_FIRMA_CTO_CONCATENADO SFC
           WHERE aud.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           and lib.TDC_TD_FIL = vdt.TDC_TD_FIL
           and lib.EMP_ND_FIL = vdt.EMP_ND_FIL
           and seg.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           and SFC.LIB_CONSECUTIVO =  lib.LIB_CONSECUTIVO
           AND lib.LIB_ESTADO IN ('PFC','PFR','CTO');
             
           vcestado_proceso     := 'S';
           vcmensaje_proceso    := 'Consulta ok';
             
    EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
            vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_informacion_ana: '||sqlerrm;
END;


 PROCEDURE pl_consultar_informacion_exp(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2) IS
BEGIN
 OPEN vcconsulta FOR
   SELECT lib.TDC_TD_EPL tipo_documento, 
          lib.epl_nd numero_documento ,
          Fb_Epl_nombres(lib.TDC_TD_EPL, lib.epl_nd) nombre_empleado,
          lib.REC_FECHA  fecha_registro,
          rhu.fb_empresa(lib.tdc_td_fil,lib.emp_nd_fil) empresa,
          adm.FB_CAL_TIEM_FECHAS(lib.lib_fecha_estado,sysdate) timepo_trancurrido,
          lib.TDC_TD_FIL tipo_documento_filial,
          lib.EMP_ND_FIL numero_documento_filial,
          Fb_Epl_Telefono(lib.TDC_TD_EPL, lib.epl_nd, 'CELULAR') telefono,
          lib.LIB_FECHA_ESTADO fecha_estado,
          vdt.DAR_RESPONSABLE responsable,
          lib.LIB_ESTADO estado_lib, 
          lib.LIB_CONSECUTIVO lib_consecutivo,
          lib.cto_numero numero_contrato,
          seg.OBSERVACION observacionTemporal,
          seg.SEG_ESTADO estadoTemporal,
          SFC.SCC_URL_ENVIADA url_enviada,
           (SELECT *
                    FROM (SELECT ID
                    FROM (SELECT *
                           from ADM.SEG_FIRMA_CTO_CONCATENADO where LIB_CONSECUTIVO =lib.LIB_CONSECUTIVO 
                           ),
                   JSON_TABLE ( SCC_RESPUESTA, '$data'
                   COLUMNS ( "id" PATH '$.status'))t )) respuestaws   
          
        FROM 
          (SELECT MAX(INC_FECHA_MOD) , LIB_CONSECUTIVO
           FROM aud_estado_li WHERE  INC_USUARIO_NUE = vcusuario  group by LIB_CONSECUTIVO) aud ,
          (SELECT DISTINCT(DAR_RESPONSABLE), TDC_TD_FIL,EMP_ND_FIL  , LISTAGG(USU_USUARIO, ', ') WITHIN GROUP(ORDER BY USU_USUARIO) usuarios
           FROM TMP.VDATOS_RIC A ,USUARIOS B 
           WHERE A.EPL_ND=B.EPL_ND AND TCA_CODIGO=5  group by (DAR_RESPONSABLE), TDC_TD_FIL, EMP_ND_FIL ) vdt,
           LIBROINGRESO lib , rhu.seg_firma_cto_expira seg ,  ADM.SEG_FIRMA_CTO_CONCATENADO SFC
           WHERE aud.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           and lib.TDC_TD_FIL = vdt.TDC_TD_FIL
           and lib.EMP_ND_FIL = vdt.EMP_ND_FIL
           and seg.LIB_CONSECUTIVO = lib.LIB_CONSECUTIVO
           AND lib.LIB_ESTADO IN ('PFC','PFR');
             
           vcestado_proceso     := 'S';
           vcmensaje_proceso    := 'Consulta ok';
             
    EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
                  vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_informacion_exp: '||sqlerrm;
END;


PROCEDURE pl_consultar_seguimiento_can(
                                      nmlibconsecutivo       IN NUMBER,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2) IS
 BEGIN   
       EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MONTH-YYYY HH24:MI:SS''';
       OPEN vcconsulta FOR
       SELECT TIPO_EVENTO ,AUD_FECHA
       FROM adm.seg_firma_msct   
       WHERE LIB_CONSECUTIVO = nmlibconsecutivo
       ORDER BY aud_fecha DESC;
       
       vcestado_proceso     := 'S';
           vcmensaje_proceso    := 'Consulta ok';
       
 EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
                   vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_informacion_ana: '||sqlerrm;
END;

PROCEDURE pl_consultar_informacion_can(
                                      nmlibconsecutivo       IN NUMBER,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2)IS
   BEGIN
   OPEN vcconsulta FOR
   SELECT  lib.epl_nd epl_nd
                           , lib.tdc_td_epl tdc_td_epl 
                           , lib.tdc_td_fil tdc_td_fil
                           , lib.emp_nd_fil emp_nd_fil
                           , rhu.fb_empresa(lib.tdc_td_fil,lib.emp_nd_fil) emp_nom_filial
                           , rhu.fb_empresa(lib.TDC_TD_PPAL,lib.EMP_ND_PPAL) emp_nom_principal
                           , lib.lib_CONSECUTIVO Lib_CONSECUTIVO
                           , FB_EMPLEADO_COLUMNA (lib.TDC_TD_EPL, lib.EPL_ND ,'NOMBRE') nombre_empleado
                           , cno.cno_nombre cargo_empleado
                           , rhu.FB_CORREO_EMPLEADO(lib.TDC_TD_EPL, lib.EPL_ND) correo_empleado
                           , lib.cto_numero cto_numero 
                           , seg.OBSERVACION observacion_exp
                           , lib.lib_estado estado_libro
                           , Fb_Epl_Telefono(lib.TDC_TD_EPL, lib.epl_nd, 'CELULAR') telefono
                           , lib.SUC_NOMBRE_ADMIN sucursal_administrativa
                           , lib.SUC_NOMBRE_FIL sucursal_filial
                           , lib.DPT_NOMBRE departamento
                           , lib.CIU_NOMBRE ciudad
                     FROM rhu.libroingreso lib, cno cno , rhu.seg_firma_cto_expira seg
                     WHERE cno.cno_codigo = lib.cno_codigo
                     and seg.LIB_CONSECUTIVO=lib.LIB_CONSECUTIVO
                     AND LIB.LIB_CONSECUTIVO=nmlibconsecutivo;
                
       
       vcestado_proceso     := 'S';
       vcmensaje_proceso    := 'Consulta ok';
       
 EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
                   vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_informacion_can: '||sqlerrm;            
END;

PROCEDURE pl_consultar_info_analista(
                                      vcusuario              IN VARCHAR2,
                                      vcconsulta             OUT VCREFCURSOR,
                                      vcestado_proceso       OUT VARCHAR2,
                                      vcmensaje_proceso      OUT VARCHAR2)
     IS   
    
  BEGIN
   pb_seguimiento2('infoAnalista',vcusuario);
   
  OPEN vcconsulta FOR
  select TDC_TD tipo_documento,
  EPL_ND documento 
  ,USU_NOMBRE nombre_completo
  from usuarios 
  where USU_USUARIO =REPLACE(vcusuario, '"', '' ) OR USU_LDAP =REPLACE(vcusuario, '"', '' );
  
                     vcestado_proceso     := 'S';
                     vcmensaje_proceso    := 'Consulta ok';
       
 EXCEPTION
          WHEN OTHERS THEN
                  vcestado_proceso     := 'N';
                   vcmensaje_proceso    := 'Error consultando RHU.pl_consultar_informacion_can: '||sqlerrm;    
    
  END;


END QB_SEGUIMIENTO_CONTRATO;
/
