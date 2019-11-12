<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" 
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#" 
    xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" 
    xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
    xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" 
    xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">

	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
    
    <!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='Invoice']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
    
    <xsl:key name="by-document-additional-reference" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
    
    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>
    
    <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>
    
    <!-- key tributos duplicados por cabecera -->
    <xsl:key name="by-tributos-in-root" match="*[local-name()='Invoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
    
    <!-- key AdditionalMonetaryTotal duplicados -->
    <xsl:key name="by-AdditionalMonetaryTotal" match="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal" use="cbc:ID"/>
    
    
    
    <xsl:template match="/*">
    
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
	
		
		<!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->
        
        <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>
        
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
        
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
                
       
        
        <!-- Esta validacion se hace de manera general -->
        <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template>
        -->
        
        <!-- Numero de Serie del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1035'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroSerie != substring(cbc:ID, 1, 4)" />
        </xsl:call-template>
        
        <!-- Numero de documento en el nombre del archivo no coincide con el consignado en el contenido del XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1036'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroComprobante != substring(cbc:ID, 6)" />
        </xsl:call-template>
        
        <!-- Variables -->
        <xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>

        <xsl:variable name="cbcCustomizationID" select="cbc:CustomizationID"/>
        
        <xsl:variable name="monedaComprobante" select="cbc:DocumentCurrencyCode/text()"/>
        
        <xsl:variable name="codigoProducto" select="cac:PaymentTerms/cbc:PaymentMeansID"/>
        
        <xsl:variable name="tipoOperacion" select="cbc:InvoiceTypeCode/@listID"/>
        
        
        <xsl:variable name="cacContractDocumentReference" select="cac:ContractDocumentReference"/>
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
    
    
        <!-- 
        ===========================================================================================================================================
        
        Datos de la Boleta de Venta Electronica  
        
        ===========================================================================================================================================
        -->
        <!-- cbc:UBLVersionID No existe el Tag UBL ERROR 2075 -->
        <!--  El valor del Tag UBL es diferente de "2.0" ERROR 2074 
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="$cbcUBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.1)$'"/>
        </xsl:call-template>
        -->
        
        <!-- cbc:CustomizationID No existe el Tag UBL ERROR 2073 -->
        <!--  Vigente hasta el 01/01/2018   -->
        <!--  El valor del Tag UBL es diferente de "1.0" ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2073'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="$cbcCustomizationID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
            <!-- Ini PAS20171U210300071 
			<xsl:with-param name="isError" select ="false()"/>
			Fin PAS20171U210300071 -->
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="$cbcCustomizationID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<xsl:with-param name="regexp" select="'^[S][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
		</xsl:call-template>
        <!-- ================================== Verificar con el flujo o con Java ============================================================= -->
        <!-- cbc:ID El número de serie del Tag UBL es diferente al número de serie del archivo ERROR 1035 -->
        <!--  El número de comprobante del Tag UBL es diferente al número de comprobante del archivo ERROR 1036 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 0 o 1 ERROR 1033 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 2 ERROR 1032 -->
        
        <!-- cbc:IssueDate La diferencia entre la fecha de recepción del XML y el valor del Tag UBL es mayor al límite del listado ERROR 2108 -->
        <!--  El valor del Tag UBL es mayor a dos días de la fecha de envío del comprobante ERROR 2329 -->
        
        <!-- cbc:InvoiceTypeCode No existe el Tag UBL ERROR 1004 (Verificar que el error ocurra)-->
        <!--  El valor del Tag UBL es diferente al tipo de documento del archivo ERROR 1003 -->
        <!-- Fecha fin de facturación -->		
		<!-- <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2892'"/>
			<xsl:with-param name="node" select="$cbcInvoicePeriodEndDate"/>
			<xsl:with-param name="regexp" select="'^\d{4}-((0[1-9])|(1[012]))-((0[1-9]|[12]\d)|3[01])$'"/>
		</xsl:call-template>
		-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1004'"/>
            <xsl:with-param name="errorCodeValidate" select="'1003'"/>
            <xsl:with-param name="node" select="cbc:InvoiceTypeCode"/>
            <xsl:with-param name="regexp" select="'^14$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- ================================================================================================================================ -->
        <xsl:variable name="cacInvoicePeriodcbcStartDate" select="date:seconds(cac:InvoicePeriod/cbc:StartDate)" />
		<xsl:variable name="cacInvoicePeriodcbcEndDate" select="date:seconds(cac:InvoicePeriod/cbc:EndDate)" />
		
		<!-- La fecha/hora de recepcion del comprobante por ose, no debe de ser mayor a la fecha de recepcion de sunat -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3198'" />
			<xsl:with-param name="node" select="cacInvoicePeriodcbcEndDate" />
			<xsl:with-param name="expresion" select="$cacInvoicePeriodcbcStartDate &gt; $cacInvoicePeriodcbcEndDate" />
			<xsl:with-param name="descripcion" select="concat('La fecha fin de facturacion ', cac:InvoicePeriod/cbc:EndDate,' no debe de ser menor a la fecha de inicio de facturacion ', cac:InvoicePeriod/cbc:StartDate,'&quot;')"/>
		</xsl:call-template>
		
        
        <!-- cbc:DocumentCurrencyCode No existe el Tag UBL ERROR 2070 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode"/>
		</xsl:call-template>
		
	
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cbc:DocumentCurrencyCode"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Currency)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 4217 Alpha)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!--  La moneda de los totales de línea y totales de comprobantes (excepto para los totales de Percepción (2001) y Detracción (2003)) es diferente al valor del Tag UBL ERROR 2071 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not(ancestor-or-self::cac:PaymentTerms/cbc:Amount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not (ancestor-or-self::cac:PaymentTerms/cbc:Amount)]" />
        </xsl:call-template>        
        
        
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Datos de la Factura electronica  
        
        ===========================================================================================================================================
        -->
        
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del Emisor
        
        ===========================================================================================================================================
        -->
        
                    
        <xsl:apply-templates select="cac:AccountingSupplierParty">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
        
        <!--<xsl:apply-templates select="cac:Delivery/cac:DeliveryLocation/cac:Address">
	            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
        -->
         
        <!-- 
        ===========================================================================================================================================
        
        Fin Datos del Emisor
        
        ===========================================================================================================================================
        --> 
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del cliente o receptor
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="cac:AccountingCustomerParty">
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        fin Datos del cliente o receptor
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Documentos de referencia
        
        ===========================================================================================================================================
        -->
        
        <xsl:for-each select="$cacContractDocumentReference">
        	
        	<!-- Datos del receptor --> 
	        <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'2921'"/>
	            <xsl:with-param name="node" select="./cbc:DocumentTypeCode"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'56'"/>
                <xsl:with-param name="idCatalogo" select="cbc:DocumentTypeCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2922'"/>
                <xsl:with-param name="descripcion" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2922)'"/>
            </xsl:call-template>
	        
	       
	        
            <xsl:if test="cbc:DocumentTypeCode[text() = '5']">
		        <!-- Datos del receptor --> 
		        <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'2923'"/>
		            <xsl:with-param name="node" select="cbc:LocaleCode"/>
		        </xsl:call-template>
		    </xsl:if>
		    
		    <xsl:if test="cbc:DocumentTypeCode[text() != '5']">
		    	<!-- Valida que el documento del adquiriente exista y sea solo uno -->
		        <xsl:if test="cbc:LocaleCode">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2924'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2924)'" /> </xsl:call-template>
		        </xsl:if>
		    </xsl:if>

		        
		    <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'57'"/>
                <xsl:with-param name="idCatalogo" select="cbc:LocaleCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2925'"/>
                <xsl:with-param name="descripcion" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2925)'"/>
            </xsl:call-template>
	     
        
            <xsl:if test="cbc:DocumentTypeCode[text() = '1' or text() = '2']">
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2926'"/>
					<xsl:with-param name="errorCodeValidate" select="'2928'"/>
					<xsl:with-param name="node" select="cbc:ID"/>
					<xsl:with-param name="regexp" select="'^[0-9a-zA-Z]{8}$'"/>
				</xsl:call-template>
		    </xsl:if>
		    <!-- Valida que el documento del adquiriente exista y sea solo uno -->
		    <!-- <xsl:if test="./cbc:DocumentTypeCode[text() != '1' and text() != '2']">		        
		        <xsl:if test="./cbc:ID">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2927'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2927)'" /> </xsl:call-template>
		        </xsl:if>
		    </xsl:if>
		    -->
		    
		    <xsl:if test="cbc:LocaleCode = '2'">
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2929'"/>
					<xsl:with-param name="errorCodeValidate" select="'2931'"/>
					<xsl:with-param name="node" select="cbc:ID"/>
					<xsl:with-param name="regexp" select="'^[0-9]{9}$'"/>
				</xsl:call-template>
			</xsl:if>
			
			<!-- Valida que el documento del adquiriente exista y sea solo uno -->
		    <!-- <xsl:if test="./cbc:LocaleCode != '2'">	        
		        <xsl:if test="./cbc:ID">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2930'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2927)'" /> </xsl:call-template>
		        </xsl:if>
		    </xsl:if>
		    -->
			
		    <xsl:if test="cbc:DocumentTypeCode[text() = '1' or text() = '2']"> 
		        <!-- Valida que el documento del adquiriente exista y sea solo uno -->
		        <xsl:if test="not(cbc:DocumentStatusCode)">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2932'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2932)'" /> </xsl:call-template>
		        </xsl:if>
		    
		    </xsl:if>
	        
	        <xsl:if test="cbc:DocumentTypeCode[text() != '1' and text() != '2']">
		        <!-- Valida que el documento del adquiriente exista y sea solo uno -->
		        <xsl:if test="cbc:DocumentStatusCode">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2933'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2933)'" /> </xsl:call-template>
		        </xsl:if>
		    </xsl:if>
	        
            <xsl:if test="cbc:DocumentStatusCode"> 
				<xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'24'"/>
					<xsl:with-param name="propiedad" select="'tipo'"/>
					<xsl:with-param name="idCatalogo" select="cbc:DocumentStatusCode"/>
					<xsl:with-param name="valorPropiedad" select="cbc:DocumentTypeCode"/>
					<xsl:with-param name="errorCodeValidate" select="'2934'"/>
				</xsl:call-template>
	   		</xsl:if>     	
	        
        </xsl:for-each>
        
		
        <xsl:for-each select="$cacDelivery">
			
			<xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode = '1'">
		        
		        
		        <xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'2937'"/>
		            <xsl:with-param name="errorCodeValidate" select="'2939'"/>
		            <xsl:with-param name="node" select="./cbc:MaximumQuantity"/>
		            <xsl:with-param name="isGreaterCero" select="false()"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2937'"/>
					<xsl:with-param name="errorCodeValidate" select="'2939'"/>
					<xsl:with-param name="node" select="./cbc:MaximumQuantity"/>
					<xsl:with-param name="regexp" select="'^[0-9]{1,3}(\.[0-9]{1,2})?$'"/>
				</xsl:call-template>
				
				<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'2935'"/>
		            <xsl:with-param name="node" select="./cbc:MaximumQuantity/@unitCode"/>
		        </xsl:call-template>		        
				
				<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'2940'"/>
		            <xsl:with-param name="node" select="./cbc:ID/@schemeID"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
	                <xsl:with-param name="catalogo" select="'58'"/>
	                <xsl:with-param name="idCatalogo" select="./cbc:ID/@schemeID"/>
	                <xsl:with-param name="errorCodeValidate" select="'2942'"/>
	                <xsl:with-param name="descripcion" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2942)'"/>
	            </xsl:call-template>
		        
		    </xsl:if>
		    		    
		    <xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode != '1'">
		        <!-- Valida que el documento del adquiriente exista y sea solo uno -->
		        <xsl:if test="./cbc:MaximumQuantity/@unitCode">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2936'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2936)'" /> </xsl:call-template>
		        </xsl:if>
		        
		        <xsl:if test="./cbc:MaximumQuantity">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2938'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2938)'" /> </xsl:call-template>
		        </xsl:if>
		        
		        <xsl:if test="./cbc:ID/@schemeID">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2941'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2941)'" /> </xsl:call-template>
		        </xsl:if>
		    </xsl:if>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="./cbc:ID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Tipo de medidor)$'"/>
				<xsl:with-param name="isError" select ="false()"/>					
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="./cbc:ID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>					
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="./cbc:ID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo58)$'"/>
				<xsl:with-param name="isError" select ="false()"/>					
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4258'"/>
				<xsl:with-param name="node" select="./cbc:MaximumQuantity/@unitCodeListID"/>
				<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
				<xsl:with-param name="isError" select ="false()"/>					
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4259'"/>
				<xsl:with-param name="node" select="./cbc:MaximumQuantity/@unitCodeListAgencyName"/>
				<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
				<xsl:with-param name="isError" select ="false()"/>					
			</xsl:call-template>
			
			
			<xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode[text() = '1']">
		    
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2943'"/>
					<xsl:with-param name="errorCodeValidate" select="'2945'"/>
					<xsl:with-param name="node" select="./cbc:ID"/>
					<xsl:with-param name="regexp" select="'^[0-9a-zA-Z]{6}$'"/>
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4255'"/>
					<xsl:with-param name="node" select="./cbc:ID/@schemeName"/>
					<xsl:with-param name="regexp" select="'^(Tipo de medidor)$'"/>
					<xsl:with-param name="isError" select ="false()"/>					
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4256'"/>
					<xsl:with-param name="node" select="./cbc:ID/@schemeAgencyName"/>
					<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
					<xsl:with-param name="isError" select ="false()"/>					
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4257'"/>
					<xsl:with-param name="node" select="./cbc:ID/@schemeURI"/>
					<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo58)$'"/>
					<xsl:with-param name="isError" select ="false()"/>					
				</xsl:call-template>
				
		    </xsl:if>
		    
		    <xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode[text() != '1']">		    
		        <xsl:if test="./cbc:ID">
		            <xsl:call-template name="rejectCall"> 
		            	<xsl:with-param name="errorCode" select="'2944'" /> 
		            	<xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2944)'" /> 
		            </xsl:call-template>
		        </xsl:if>		       
		    </xsl:if>
		    
		    <xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode[text() = '1' or text() = '2']">
		    
		        <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'2947'"/>
		            <xsl:with-param name="node" select="./cbc:Quantity/@unitCode"/>
		        </xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2950'"/>
					<xsl:with-param name="errorCodeValidate" select="'2952'"/>
					<xsl:with-param name="node" select="./cbc:Quantity"/>
					<xsl:with-param name="regexp" select="'^[0-9]{10}?$'"/>
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4258'"/>
					<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListID"/>
					<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4259'"/>
					<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListAgencyName"/>
					<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				
		    </xsl:if>		    
		    
		    <xsl:if test="$cacContractDocumentReference/cbc:DocumentTypeCode[text() != '1' and text() != '2']">		    
		       
		        <!-- <xsl:if test="./cac:DeliveryLocation/cac:LocationCoordinate">
		            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2946'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2946)'" /> </xsl:call-template>
		        </xsl:if>
		        -->
		        <xsl:if test="./cbc:Quantity/@unitCode">
		            <xsl:call-template name="rejectCall"> 
		            	<xsl:with-param name="errorCode" select="'2948'" /> 
		            	<xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2948)'" /> 
		            </xsl:call-template>
		        </xsl:if>
		        
		        <xsl:if test="./cbc:Quantity">
		            <xsl:call-template name="rejectCall"> 
		            	<xsl:with-param name="errorCode" select="'2951'" /> 
		            	<xsl:with-param name="errorMessage" select="'Error Expr Regular SERVICIO PUBLICO (codigo: 2951)'" /> 
		            </xsl:call-template>
		        </xsl:if>
		    </xsl:if>
		    		
        </xsl:for-each>
        
        <!-- 
        ===========================================================================================================================================
        
        Documentos de referencia
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem de la Factura
        
        ===========================================================================================================================================
        -->
        
        <!--  cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode 
        Si "Código de tributo por línea" es 1000 (IGV) y el valor del Tag UBL es "40" (Exportación), no debe haber otro "Afectación a IGV por la línea" diferente a "40" 
        ERROR 2655
        
        <xsl:variable name="afectacionIgvExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() = '40'])"/>
        <xsl:variable name="afectacionIgvNoExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() != '40'])"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2655'" />
            <xsl:with-param name="node" select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="($afectacionIgvExportacion > 0) and ($afectacionIgvNoExportacion > 0)" />
        </xsl:call-template>
         -->
         
        <xsl:apply-templates select="cac:InvoiceLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem de la Factura
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Totales de la Factura
        
        ===========================================================================================================================================
        -->
        
        
        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation El Tag UBL no debe repetirse en el /Invoice 
        ERROR 2427 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2427'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation" />
            <xsl:with-param name="expresion" select="count(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation) &gt; 1" />
        </xsl:call-template>
        -->
        
        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID 
        El valor del Tag UBL debe tener por lo menos uno de los siguientes valores en el /Invoice: 1001 (Gravada), 1002 (Inafecta), 1003 (Exonerada), 1004 (Gratuita) o 3001 (FISE) 
        ERROR 2047 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2047'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID" />
            <xsl:with-param name="expresion" select="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID[text()='1001' or text()='1002' or text()='1003' or text()='1004' or text()='3001'])" />
        </xsl:call-template>
        -->
        
        <!-- cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2065 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>            
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2064 -->
        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount    
        El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales    ERROR    2064 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- cac:LegalMonetaryTotal/cbc:PayableAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2062 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2031'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3019'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        

        <!-- cac:LegalMonetaryTotal/cbc:PayableAmount Si 
        "Total valor de venta - operaciones gravadas" más 
        "Total valor de venta - operaciones inafectas" más 
        "Total valor de venta - operaciones exoneradas" más 
        "Sumatoria IGV" más 
        "Sumatoria ISC" más 
        "Sumatoria otros tributos" más 
        "Sumatoria otros cargos", es diferente al valor del Tag UBL (con una tolerancia de más/menos uno) 
        OBSERV 4027 -->
        
		<!--
        <xsl:variable name="totalOperacionesGravadas" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID='1001']/cbc:PayableAmount"/>
        <xsl:variable name="TotalOperacionesInafectas" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID='1002']/cbc:PayableAmount"/>
        <xsl:variable name="TotalOperacionesExoneradas" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID='1003']/cbc:PayableAmount"/>
        <xsl:variable name="SumatoriaIGV" select="cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode/text()='1000']/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaISC" select="cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode/text()='2000']/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode/text()='9999']/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaOtrosCargos" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
        <xsl:variable name="ImporteTotal" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
        <xsl:variable name="sumMontosTotales" select="$totalOperacionesGravadas + $TotalOperacionesInafectas + $TotalOperacionesExoneradas + $SumatoriaIGV + $SumatoriaISC + $SumatoriaOtrosTributos + $SumatoriaOtrosCargos"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4027'" />
            <xsl:with-param name="node" select="cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="($ImporteTotal + 1 ) &lt; $sumMontosTotales or ($ImporteTotal -1) &gt; $sumMontosTotales" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        -->
        <!-- sac:AdditionalMonetaryTotal 
        <xsl:apply-templates select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        -->
        
        <!-- Tributos duplicados por cabecera 
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera"/>
        -->
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2956'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3024 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3024'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos de la cabecera-->
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- Cargos y descuentos de la cabecera --> 
        <xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera"/>
        
        
        <!-- cac:TaxTotal/cbc:TaxAmount Si existe una línea con "Código de tributo por línea" igual a "2000" y "Monto ISC por línea" mayor a cero, el valor del Tag UBL es menor igual a 0 (cero) 
        OBSERV 4020 
        <xsl:variable name="detalleIscGreaterCero" select="cac:InvoiceLine/cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount[text() &gt; 0] "/>
        <xsl:if test="$detalleIscGreaterCero">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4020'" />
                <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']" />
                <xsl:with-param name="expresion" select="not(cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000' and text() &gt; 0])" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Totales de la Factura
        
        ===========================================================================================================================================
        -->
        
        
        <!-- Retornamos el comprobante al flujo necesario para lotes -->
        <xsl:copy-of select="."/>
      
    </xsl:template>
        
    <!-- 
    ===========================================================================================================================================
    *******************************************************************************************************************************************
                                                       TEMPLATES
    *******************************************************************************************************************************************
    ===========================================================================================================================================
    -->
    
        <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cbc:Note =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cbc:Note">
		
		<xsl:if test="@languageLocaleID">    
            <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'"/>
				<xsl:with-param name="idCatalogo" select="@languageLocaleID"/>
				<xsl:with-param name="catalogo" select="'52'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="@languageLocaleID = '3000'">
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3028'"/>
				<xsl:with-param name="node" select="text()"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,39}$'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="@languageLocaleID != '3000'">
        	<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3006'"/>
				<xsl:with-param name="node" select="text()"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,99}$'"/>
			</xsl:call-template>
        </xsl:if>
        
	</xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cbc:Note ======================================================
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    ============================================ Template cac:AccountingSupplierParty =========================================================
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AccountingSupplierParty">
    	<xsl:param name="tipoOperacion" select = "'-'" />
        <!-- cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID No existe el Tag UBL ERROR 1006 -->
        <!--  El valor del Tag UBL es diferente al RUC del nombre del XML ERROR 1034 -->
        <!--  El valor del Tag UBL no existe en el listado ERROR 2104 -->
        <!--  El valor del Tag UBL tiene un ind_estado diferente "00" en el listado ERROR 2010 -->
        <!--  El valor del Tag UBL tiene un ind_condicion diferente "00" en el listado ERROR 2011 -->
        
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3089'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <!-- cac:AccountingSupplierParty/cbc:AdditionalAccountID No existe el Tag UBL ERROR 1008 -->
        <!--  El valor del Tag UBL es diferente a "6" ERROR 1007 -->
        <!--  Existe más de un Tag UBL en el XML ERROR 2362 -->
        <!-- Tipo de documento -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1008'"/>
            <xsl:with-param name="errorCodeValidate" select="'1007'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 4092 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4092'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
    
        <!-- Apellidos y nombres, denominación o razón social -->
        <!-- cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL ERROR 1037 -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 1038 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
            <xsl:with-param name="errorCodeValidate" select="'1038'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,24}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4093'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4098 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4041 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4242'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}$'"/> <!-- de 4 dígitoso -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Establecimientos anexos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingSupplierParty ======================================================
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Delivery/cac:DeliveryLocation/cac:Address =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:DeliveryLocation/cac:Address">
		<xsl:param name="tipoOperacion" select = "'-'" />
    	
    	<!-- tipoOperacion es diferente 0104 Venta interna - Itinerante y existe el tag 
        cac:Delivery/cac:DeliveryLocation/cac:Address OBSERVACION 4263 -->
        <xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4263'" />
			<xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
			<xsl:with-param name="expresion" select="cac:AddressLine/cbc:Line" />
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
            <xsl:with-param name="node" select="cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4238'"/>
            <xsl:with-param name="node" select="cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,24}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4239'"/>
            <xsl:with-param name="node" select="cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:if test="cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4231'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4240'"/>
            <xsl:with-param name="node" select="cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4241'"/>
            <xsl:with-param name="node" select="cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4041'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
			<xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>		        
		        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
       
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Delivery/cac:DeliveryLocation/cac:Address =========================================== 
    
    ===========================================================================================================================================
    -->
        
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:AccountingCustomerParty">
        <xsl:param name="tipoOperacion" select = "'-'" />
        
        <!-- numero de documento -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <!-- cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID No existe el Tag UBL 
        ERROR 2014 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2014'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
        
        <xsl:choose>
            <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
            	<!--  Si "Tipo de documento de identidad del adquiriente" es 6, el formato del Tag UBL es diferente a numérico de 11 dígitos 
        		ERROR 2017 -->
				<xsl:call-template name="regexpValidateElementIfExist">
		             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
		             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
		         </xsl:call-template>					
			</xsl:when>
			<xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='1'">
				<!--  Si "Tipo de documento de identidad del adquiriente" es "1", el formato del Tag UBL es diferente a numérico de 8 dígitos 
       				OBSERV 4207 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4207'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	            </xsl:call-template>						
			</xsl:when>
			<xsl:otherwise>
				<!-- Si "Tipo de documento de identidad del adquiriente" es diferente de "1" y diferente "6", el formato del Tag UBL es diferente a alfanumérico de hasta 15 caracteres 
		        	OBSERV 4208 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4208'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <!-- <xsl:with-param name="regexp" select="'^.{15}$'"/> -->
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	            </xsl:call-template>		        
			</xsl:otherwise>
		</xsl:choose>
        
        <!-- No existe el Tag UBL 
        ERROR 2015 -->
        <!-- El Tag UBL es diferente al listado 
        ERROR 2016  TODO agregar la validacion contra el catalogo-->        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2015'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
		
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
        	<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'2016'"/>
				<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
				<xsl:with-param name="catalogo" select="'06'"/>
			</xsl:call-template>
        </xsl:if>
        
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <!-- No existe el Tag UBL ERROR 
        2021 -->
        <!-- El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres 
        ERROR 2022 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
        </xsl:call-template>
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:InvoiceLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:InvoiceLine">
    
        <xsl:param name="root"/>
        
        <xsl:variable name="nroLinea" select="cbc:ID"/>
        
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoProducto" select="$root/cac:PaymentTerms/cbc:PaymentMeansID"/>
        <xsl:variable name="codigoPrecio" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode"/>
        
        <!-- cac:InvoiceLine/cbc:ID El formato del Tag UBL es diferente de numérico de 3 dígitos ERROR 2023 -->
        <!-- Numero de item -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
            <xsl:with-param name="errorCodeValidate" select="'2023'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL no debe repetirse en el /Invoice ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode No existe el atributo del Tag UBL ERROR 2883 -->
        <!-- Unidad de medida por item -->
        <xsl:if test="cbc:InvoicedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
                <xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4258'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListID"/>
			<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4259'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        <!-- cac:InvoiceLine/cbc:InvoicedQuantity No existe el Tag UBL ERROR 2024 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2025 -->
        <!-- Cantidad de unidades por item -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2024'"/>
            <xsl:with-param name="errorCodeValidate" select="'2025'"/>
            <xsl:with-param name="node" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- cac:InvoiceLine/cac:Item/cbc:Description No existe el Tag UBL ERROR 2026 -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de 1 hasta 250 caracteres ERROR 2027 -->
        <!-- Descripción detallada del servicio prestado, bien vendido o cedido en uso, indicando las características. -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2026'"/>
            <xsl:with-param name="errorCodeValidate" select="'2027'"/>
            <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{1,250})$'"/> <!-- Texto de un caracter a 250. acepta saltos de linea, no permite que inicie con espacios -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        
        <!-- cac:InvoiceLine/cac:Price/cbc:PriceAmount No existe el Tag UBL ERROR 2068 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2369 -->
        <!-- Valor unitario por ítem -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2068'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode El valor del Tag UBL es diferente al listado ERROR 2410 -->
        <!-- Código de precio unitario -->
        <xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">
        	
        	<!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount No existe el Tag UBL o es vacío 
	        ERROR 2028 -->
	        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales 
	        ERROR 2367 -->	        
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2410'"/>
                <xsl:with-param name="node" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'16'"/>
                <xsl:with-param name="idCatalogo" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2410'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2409'" />
	            <xsl:with-param name="node" select="cbc:PriceTypeCode" />
	            <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>
            
            
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4252'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listName"/>
				<xsl:with-param name="regexp" select="'^(Tipo de Precio)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4251'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4253'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
            
        </xsl:for-each>
        
                
         
        <xsl:if test="$codigoPrecio='02'">
        
	        <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount Si 
	        "Afectación al IGV por línea" es 10 (Gravado), 20 (Exonerado) o 30 (Inafecto) y "cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode" es 02 (Valor referencial en operaciones no onerosa), 
	        el Tag UBL es mayor a 0 (cero) 
	        ERROR 2425 -->
	    	<!-- Valor referencial unitario por ítem en operaciones no onerosas -->
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2425'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode" />
	            <xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount > 0 and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template> 
	        
	        <!--  cac:InvoiceLine/cac:Price/cbc:PriceAmount Si "Código de precio" es 02 (Gratuita), el valor del Tag UBL es mayor a 0 (cero) 
        	ERROR 2640 --> 	
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2640'" />
                <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
                <xsl:with-param name="expresion" select="cac:Price/cbc:PriceAmount &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
            </xsl:call-template>
            
        </xsl:if>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3195'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3026'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
              
        
        <!-- Valor de venta por línea -->
        <!-- cac:InvoiceLine/cbc:LineExtensionAmount El formato del Tag UBL es diferente de decimal (positivo o negativo) de 12 enteros y hasta 2 decimales ERROR 2370 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- cbc:LineExtensionAmount    
            Si "Tipo de operación" es 0102 (Venta interna - Anticipo), el Tag UBL es menor igual a 0 (cero)   
            ERROR   2501
            
        <xsl:if test="$tipoOperacion='0102'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2501'" />
                <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
                <xsl:with-param name="expresion" select="cbc:LineExtensionAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>                
       
        </xsl:if>
        -->
        <!-- Cargos y tributos por linea de detalle --> 
        <xsl:apply-templates select="cac:AllowanceCharge" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        
        
        
    </xsl:template>
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:InvoiceLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:TaxSubtotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        <xsl:variable name="tasaTributo" select="cac:TaxCategory/cbc:Percent"/>
        <xsl:variable name="MontoBaseTributo" select="cbc:TaxableAmount"/>
        <xsl:variable name="MontoTributo" select="cbc:TaxAmount"/>
        
        <xsl:variable name="codTributo">
            <xsl:choose>
                <xsl:when test="$codigoTributo = '1000'">
                    <xsl:value-of select="'igv'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '1016'">
                    <xsl:value-of select="'iva'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9995'">
                    <xsl:value-of select="'exp'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9996'">
                    <xsl:value-of select="'gra'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9997'">
                    <xsl:value-of select="'exo'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9998'">
                    <xsl:value-of select="'ina'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3031 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3031'"/>
            <xsl:with-param name="errorCodeValidate" select="'3031'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:choose>
        
            <xsl:when test="$codigoTributo = '1000' or $codigoTributo = '1016' ">
            	
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3111'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3102'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
					<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
	            
	            
	            <xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
		            <xsl:with-param name="errorCodeValidate" select="'3102'"/>
		            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
		            <xsl:with-param name="isGreaterCero" select="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	            
	            <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
		        ERROR 2378 -->
		        <xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="'1'"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
				
				<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
            </xsl:when>
            
            <xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">
            	<!-- 
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3111'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            -->
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3102'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
					<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
		       	
            	<xsl:if test="$codigoTributo = '2000'">
	            	
	            	 <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3104'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent = 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
	            	
	            	<!-- <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3108'" />
		                <xsl:with-param name="node" select="cbc:TaxAmount" />
		                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoBaseTributo * $tasaTributo / 100 or ($MontoTributo - 1) &gt; $MontoBaseTributo * $tasaTributo / 100" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
		            -->
		            
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3050'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
		            
		            <xsl:call-template name="existElement">
		                <xsl:with-param name="errorCodeNotExist" select="'2373'"/>
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange"/>
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
		            
		            <xsl:call-template name="findElementInCatalog">
			            <xsl:with-param name="catalogo" select="'08'"/>
			            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TierRange"/>
			            <xsl:with-param name="errorCodeValidate" select="'2041'"/>
			            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			        </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:if test="$codigoTributo = '9999'">
	            	
		            <!--
		             <xsl:if test="cac:TaxCategory/cbc:Percent != 0">	            	            
			             
			            <xsl:call-template name="isTrueExpresion">
			                <xsl:with-param name="errorCodeValidate" select="'3109'" />
			                <xsl:with-param name="node" select="cbc:TaxAmount" />
			                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; ($MontoBaseTributo * $tasaTributo / 100) or ($MontoTributo - 1) &gt; ($MontoBaseTributo * $tasaTributo / 100)" />
			                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			            </xsl:call-template>	
			            			                       
		            </xsl:if>
		            -->
		            
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'2993'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template> 
	            </xsl:if>
	            
            </xsl:when>
            
            <xsl:when test="$codigoTributo = '9995' or $codigoTributo = '9996' or $codigoTributo = '9997' or $codigoTributo = '9998'">
            	
            	<xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
	            	<xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3110'" />
		                <xsl:with-param name="node" select="cbc:TaxAmount" />
		                <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:if test="$codigoTributo = '9996' and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17']">
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3111'" />
		                <xsl:with-param name="node" select="cbc:TaxAmount" />
		                <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:if test="$codigoTributo = '9996' and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '40']">
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3110'" />
		                <xsl:with-param name="node" select="cbc:TaxAmount" />
		                <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3102'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
					<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
			       
	            <xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3101'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent != 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:if test="$codigoTributo = '9996' and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17']">
		            <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'2993'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent = 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:if test="$codigoTributo = '9996' and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '40']">
	                <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3101'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent != 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		            </xsl:call-template>
	            </xsl:if>
	            
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
		        ERROR 2378 -->
		        <xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="1"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
				
				<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
            </xsl:when>
           
        </xsl:choose>
        
        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
        
            <!-- Si "Código de tributo por línea" es 1000 (IGV) y "Tipo de operación" es 02 (Exportación), el valor del Tag UBL es diferente a 40 (Exportación) 
            ERROR 2642 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2642'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode != '40'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <!-- Validaciones para IVAP -->
        <xsl:if test="$tipoOperacion='0120'">
        
            <!-- Si "Código de tributo por línea" es 1000 (IGV) y "Tipo de operación" es 02 (Exportación), el valor del Tag UBL es diferente a 40 (Exportación) 
            ERROR 2642 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2644'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode != '17'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
					
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->	
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2036'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
        <!-- cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el cac:InvoiceLine ERROR 2355 -->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
        
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <!-- Validaciones para IVAP -->
        <xsl:if test="$tipoOperacion='0120'">
        
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9995' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2996'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'3051'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2377'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        
        
        <!-- <xsl:variable name="tipoOperacion" select="$root/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID"/>-->
        
        <!-- cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount No existe el Tag UBL o es diferente al Tag anterior 
        ERROR 2372 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2372'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number(cac:TaxSubtotal/cbc:TaxAmount) != number(cbc:TaxAmount)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        -->
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:variable name="totalImpuestosxLinea" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxSubtotal/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3022'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $SumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1) &gt; $SumatoriaImpuestosxLinea" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos duplicados por linea -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
        
        <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
        ERROR 3100 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3105'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3106'" />
           <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
           <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &gt; 1" />
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AllowanceCharge =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
         
        <xsl:choose>
        
            <!-- <xsl:when test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '47' or $codigoCargoDescuento = '48' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'"> -->
            <xsl:when test="$codigoCargoDescuento = '47' or $codigoCargoDescuento = '48'">
            	
            	<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
            	
            </xsl:when>
            
            <!-- <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01' or $codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'">-->
            <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01'">
            
	            <xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
		        
            </xsl:when> 
        
        </xsl:choose>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3073'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2954'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'53'"/>
			<xsl:with-param name="propiedad" select="'item'"/>
			<xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="valorPropiedad" select="'si'"/>
			<xsl:with-param name="errorCodeValidate" select="'4268'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
                
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3052'"/>
			<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2955'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:if test="cbc:MultiplierFactorNumeric">
        
	        <xsl:variable name="MontoCalculado" select="cbc:BaseAmount * cbc:MultiplierFactorNumeric"/>
	        <xsl:variable name="Monto" select="cbc:Amount"/>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4289'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="($Monto + 1 ) &lt; $MontoCalculado or ($Monto - 1) &gt; $MontoCalculado" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	        </xsl:call-template>
        
        </xsl:if>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3053'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Allowancecharge =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'4235'"/>
            <xsl:with-param name="node" select="cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:NameCode"/>
            <xsl:with-param name="errorCodeValidate" select="'4279'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Propiedad del item)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:variable name="codigoConcepto" select="cbc:NameCode"/>
        
		<xsl:choose>
			<!-- INICIO Información Adicional  - Transporte terrestre de pasajeros -->
            <xsl:when test="$codigoConcepto = '3050'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,20})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
			
        	<!-- INICIO Información Adicional  - Transporte terrestre de pasajeros -->
            <xsl:when test="$codigoConcepto = '3050'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,20})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3051'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,20})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3052'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,15})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3053'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3054'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3055'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3056'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3057'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3058'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            
            <xsl:when test="$codigoConcepto = '3059'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            <!-- FIN Información Adicional  - Transporte terrestre de pasajeros -->
            
            <!-- INICIO - Migración de documentos autorizados - Carta Porte Aéreo -->
            <xsl:when test="$codigoConcepto = '4030'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4031'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4032'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4033'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN - Migración de documentos autorizados - Carta Porte Aéreo -->
            
            <!-- INICIO Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            <xsl:when test="$codigoConcepto = '4040'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4041'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4042'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4043'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>	
		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4044'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4045'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,200})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4046'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,20})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4047'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4048'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4049'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){1,15})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            
            <!-- INICIO Migración de documentos autorizados - Pago de regalía petrolera -->
            <xsl:when test="$codigoConcepto = '4060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,30})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4061'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,10})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4062'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4063'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:EndDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>		        
            </xsl:when>
            <!-- FIN Migración de documentos autorizados - Pago de regalía petrolera -->
            
            <!-- INICIO - Ventas Sector Público -->
            <xsl:when test="$codigoConcepto = '5000'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){1,20})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){1,10})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){1,30})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){1,30})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN - Ventas Sector Público -->
            
        </xsl:choose>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxSubtotal" mode="cabecera">
        <xsl:param name="root"/>
        
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        
        <xsl:variable name="codTributo">
            <xsl:choose>
                <xsl:when test="$codigoTributo = '1000'">
                    <xsl:value-of select="'igv'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '1016'">
                    <xsl:value-of select="'iva'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9995'">
                    <xsl:value-of select="'exp'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9996'">
                    <xsl:value-of select="'gra'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9997'">
                    <xsl:value-of select="'exo'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9998'">
                    <xsl:value-of select="'ina'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3031 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3003'"/>
            <xsl:with-param name="errorCodeValidate" select="'2999'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:choose>
        	<!-- 
            <xsl:when test="$codigoTributo = '1000' or $codigoTributo = '1016' ">
            	
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3111'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            
            </xsl:when>
            
            <xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">
            	 
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3111'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	                
            </xsl:when>
            -->
            <xsl:when test="$codigoTributo = '9997' or $codigoTributo = '9998'">
            	
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3000'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            	             
            </xsl:when>
           
        </xsl:choose>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->	
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'3007'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
        
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3107'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <!-- Validaciones para IVAP -->
        <xsl:if test="$tipoOperacion='0120'">
        
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3107'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9995' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2996'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'3051'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2377'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        
        <!-- cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /Invoice 
        ERROR 2352 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) > 1" />
        </xsl:call-template>     
        
      
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
<!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxTotal" mode="cabecera">
        
        <xsl:param name="root"/>
        
        <!-- <xsl:variable name="tipoOperacion" select="$root/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID"/>-->
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3020 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3020'"/>
            <xsl:with-param name="errorCodeValidate" select="'3020'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>            
        </xsl:call-template>
        
        <xsl:variable name="totalImpuestos" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'or text() = '9999']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3196'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestos + 1 ) &lt; $SumatoriaImpuestos or ($totalImpuestos - 1) &gt; $SumatoriaImpuestos" />            
        </xsl:call-template>
        
        <!-- Tributos duplicados por linea -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="cabecera">
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
                    
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AllowanceCharge =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="cabecera">
        
		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
         
        <xsl:choose>
        
            <xsl:when test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '47' or $codigoCargoDescuento = '48' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
            	
            	<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />		           
		        </xsl:call-template>
            	
            </xsl:when>
            
            <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01' or $codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'">
            
	            <xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />		           
		        </xsl:call-template>
		        
            </xsl:when> 
        
        </xsl:choose>
        
        <!-- Codigo de tributo, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3072'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'3071'"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'53'"/>
			<xsl:with-param name="propiedad" select="'global'"/>
			<xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="valorPropiedad" select="'si'"/>
			<xsl:with-param name="errorCodeValidate" select="'3071'"/>
		</xsl:call-template>
        
        <!-- 
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'53'"/>
			<xsl:with-param name="propiedad" select="'servicios'"/>
			<xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="valorPropiedad" select="'si'"/>
			<xsl:with-param name="errorCodeValidate" select="'4284'"/>
		</xsl:call-template>
		-->
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
                
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3025'"/>
			<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
		</xsl:call-template>
		
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2968'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
        	<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2792'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>				
			</xsl:call-template>
        </xsl:if>        
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3016'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2788'"/>
				<xsl:with-param name="node" select="cbc:BaseAmount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>				
			</xsl:call-template>
        </xsl:if>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Allowancecharge =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Delivery/cac:DeliveryLocation/cac:Address =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:Shipment/cac:Delivery/cac:DeliveryAddress">
		
		
    	<xsl:if test="cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4231'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
            <xsl:with-param name="node" select="cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4238'"/>
            <xsl:with-param name="node" select="cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,24}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4239'"/>
            <xsl:with-param name="node" select="cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
                
        
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4240'"/>
            <xsl:with-param name="node" select="cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4241'"/>
            <xsl:with-param name="node" select="cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>	
		        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
       
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Delivery/cac:Shipment/cac:Delivery/cac:DeliveryAddress =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== cac:PrepaidPayment =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:PrepaidPayment" mode="cabecera">
        
        <!-- /Invoice/cac:PrepaidPayment/cbc:ID Si "Monto anticipado" existe y no existe el Tag UBL 
        OBSERV 2504 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2504'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and not(string(cbc:ID))" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        -->
        
        <xsl:choose>
            <!-- /Invoice/cac:PrepaidPayment/cbc:ID 
            Si "Tipo de documento del emisor del anticipo" existe y "Tipo de comprobante que se realizo el anticipo" es 02 (Factura), el formato del Tag UBL  es diferente a:
            [F][A-Z0-9]{3}-[0-9]{1,8}
            E001-[0-9]{1,8}
            [0-9]{1,4}-[0-9]{1,8} 
            OBSERV 2521 -->
            <xsl:when test="cbc:ID/@schemeID ='02'">
                <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2521'"/>
                    <xsl:with-param name="node" select="cbc:ID"/>
                    <xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8})|((E001)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position(), ', Tipo comprobante: ', cbc:ID/@schemeID,'. ')"/>
                </xsl:call-template>
            </xsl:when>
             
            <!-- /Invoice/cac:PrepaidPayment/cbc:ID
            
            Si "Tipo de documento del emisor del anticipo" existe y "Tipo de comprobante que se realizo el anticipo" es 03 (Boleta), el formato del Tag UBL  es diferente a:
            [B][A-Z0-9]{3}-[0-9]{1,8}
            [F][A-Z0-9]{3}-[0-9]{1,8}
            E001-[0-9]{1,8}
            EB01-[0-9]{1,8}
            [0-9]{1,4}-[0-9]{1,8}
            OBSERV 2521 -->
            <xsl:when test="cbc:ID/@schemeID ='03'">
                <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2521'"/>
                    <xsl:with-param name="node" select="cbc:ID"/>
                    <xsl:with-param name="regexp" select="'^(([B][A-Z0-9]{3}-[0-9]{1,8})|(EB01-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position(), ', Tipo comprobante: ', cbc:ID/@schemeID,'. ')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- /Invoice/cac:PrepaidPayment/cbc:ID/@schemeID Si el atributo del Tag UBL existe y es diferente a 02 (Factura) y 03 (Boleta) 
                OBSERV 2505 -->
                <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'2505'" />
                    <xsl:with-param name="node" select="cbc:ID/@schemeID" />
                    <xsl:with-param name="expresion" select="true()" />
                    <xsl:with-param name="isError" select ="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position())"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    
    
        <!-- /Invoice/cac:PrepaidPayment/cbc:PaidAmount Si el Tag UBL existe y es menor o igual a 0 (cero) 
        OBSERV 2503 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2503'" />
            <xsl:with-param name="node" select="cbc:PaidAmount" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and cbc:PaidAmount &lt;= 0" />
            <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position())"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <!-- /Invoice/cac:PrepaidPayment/cbc:InstructionID Si "Tipo de documento del emisor del anticipo" existe y el formato del Tag UBL es diferente a númerico de 11 dígitos 
        OBSERV 2529 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2529'"/>
            <xsl:with-param name="node" select="cbc:InstructionID"/>
            <xsl:with-param name="regexp" select="'^(?!(0)0+$)[0-9]{11}$'"/> <!-- numero decimal de 11 enteros. No acepta solo cero -->
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position(), '. Ruc del emisor del anticipo.')"/>
        </xsl:call-template>
        
        <!-- /Invoice/cac:PrepaidPayment/cbc:InstructionID/@schemeID Si el atributo del Tag UBL existe y es diferente a 6 (RUC) 
        OBSERV 2520 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2520'"/>
            <xsl:with-param name="errorCodeValidate" select="'2520'"/>
            <xsl:with-param name="node" select="cbc:InstructionID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^[6]$'"/>
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Documento de anticipo numero: ', position())"/>
         </xsl:call-template>
        
    </xsl:template>
        
        
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin cac:PrepaidPayment =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:PaymentTerms =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:PaymentTerms">
		<xsl:param name="tipoOPeracion"/>
		
		<xsl:if test="cbc:PaymentMeansID">
		
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3033'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="catalogo" select="'54'"/>
			</xsl:call-template>
			
			<xsl:call-template name="existAndValidateValueTwoDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'3035'"/>
	            <xsl:with-param name="errorCodeValidate" select="'3037'"/>
	            <xsl:with-param name="node" select="cbc:Amount"/>
	        </xsl:call-template>        
					
	        <xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'54'"/>
				<xsl:with-param name="propiedad" select="tasa"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="valorPropiedad" select="cbc:PaymentPercent"/>
				<xsl:with-param name="errorCodeValidate" select="'3062'"/>
			</xsl:call-template>
		</xsl:if>
		
    	<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de detraccion)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo54)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:PaymentTerms =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:PaymentMeans =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:PaymentMeans">
		<xsl:param name="tipoOPeracion"/>
		<xsl:param name="codigoProducto"/>
		
		<xsl:if test="$codigoProducto">
	    	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3034'"/>
				<xsl:with-param name="node" select="cac:PayeeFinancialAccount/cbc:ID"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$tipoOPeracion = '0302'">
	    	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3173'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansCode"/>
			</xsl:call-template>
			
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3175'"/>
				<xsl:with-param name="node" select="cbc:PaymentID"/>
			</xsl:call-template>
			
        </xsl:if>
        
        <xsl:if test="cbc:PaymentMeansCode">
        	<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3174'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansCode"/>
				<xsl:with-param name="catalogo" select="'59'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Forma de Pago)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo59)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:PaymentMeans =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =============== ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty ============== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty">
    
        <xsl:param name="tipoOPeracion"/>
        
        <!-- /Invoice/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty/cbc:ID Si existe el Tag UBL y el formato del Tag UBL es diferente a numérico de 4 dígitos 
        ERROR 2366 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2366'"/>
            <xsl:with-param name="errorCodeValidate" select="'2366'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^\d{4}$'"/> 
        </xsl:call-template>
        
        <!-- /Invoice/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty/cbc:Value Si existe el Tag UBL y el formato del Tag UBL es diferente a alfanumérico de hasta 100 caractéres 
        ERROR 2066 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2066'"/>
            <xsl:with-param name="errorCodeValidate" select="'2066'"/>
            <xsl:with-param name="node" select="cbc:Value"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,999}$'"/> 
        </xsl:call-template>
        
    </xsl:template>
            
    <!-- 
    ===========================================================================================================================================
    
    =============== fin ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty ============== 
    
    ===========================================================================================================================================
    -->       
   
   

</xsl:stylesheet>
