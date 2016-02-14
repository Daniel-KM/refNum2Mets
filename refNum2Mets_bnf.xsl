<?xml version="1.0" encoding="UTF-8"?>
<!--
Description : Convertit un fichier refNum en Mets.
Version : 20160215
Auteur : Daniel Berthereau pour l'École des Mines de Paris [http://bib.mines-paristech.fr]

Cette feuille dépend de refNum2Mets.xsl.
Elle prend en compte les spécificités du profil SIP de la BnF (Spar).

@see http://bibnum.bnf.fr/ns/refNum.xsd
@see https://github.com/Daniel-KM/refNum2Mets
@copyright Daniel Berthereau, 2015
@license http://www.cecill.info/licences/Licence_CeCILL_V2.1-fr.html
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:r2m="refNum2Mets"

    xmlns:refNum="http://bibnum.bnf.fr/ns/refNum"

    xmlns:detailsOperation="http://bibnum.bnf.fr/ns/detailsOperation"
    xmlns:spar_dc="http://bibnum.bnf.fr/ns/spar_dc"

    xmlns="http://www.loc.gov/METS/"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:premis="info:lc/xmlns/premis-v2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:niso="http://www.niso.org/Z39-87-2006.pdf"
    xmlns:textmd="info:lc/xmlns/textMD-v3"

    exclude-result-prefixes="
        xsl fn xs r2m refNum detailsOperation
        spar_dc
        mets textmd
        ">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:strip-space elements="*"/>

    <!-- Paramètres -->

    <!-- Fichier de configuration. -->
    <xsl:param name="configuration">refNum2Mets_config.xml</xsl:param>

    <!-- Constantes. -->

    <!-- Liste des paramètres du fichier de configuration. -->
    <xsl:variable name="parametres"
        select="document($configuration)/XMLlist"/>
    <!-- Liste des codes utilisés dans refNum. -->
    <xsl:variable name="codes"
        select="document($parametres/codes)/XMLlist"/>
    <!-- Liste des paramètres du profil choisi. -->
    <xsl:variable name="profil"
        select="document(r2m:cheminFichier($parametres/format/profil))/profil" />
    <!-- Paramètres pour la construction des adresses. -->
    <xsl:variable name="adresse"
        select="$parametres/adresse[@nom = ../formats/adresse_fichier[@utiliser = 'true'][1]/@nom]" />

    <!-- Identifiant ark de la notice en cours, si possible. -->
    <xsl:variable name="arkId" as="xs:string">
        <xsl:choose>
            <xsl:when test="$parametres/ark/institution != ''">
                <xsl:value-of select="r2m:trouveArk(/refNum:refNum/refNum:document/@identifiant)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="arkComplet" as="xs:string">
        <xsl:choose>
            <xsl:when test="$parametres/ark/institution != ''">
                <xsl:value-of select="concat('ark:/', $parametres/ark/institution, '/', $arkId)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ==============================================================
    Templates spécifiques pour le profil BnF.
    =============================================================== -->

    <!-- TODO Valider le contenu. -->
    <xsl:template match="/refNum:refNum" mode="spar_digiprovMD_init">
        <xsl:apply-templates select="." mode="spar_digiprovMD_init_creation" />

        <xsl:apply-templates select="." mode="spar_digiprovMD_init_objets">
            <xsl:with-param name="objetAssocie" select="'master'" />
        </xsl:apply-templates>

        <xsl:for-each select="refNum:document/refNum:production/refNum:objetAssocie">
            <xsl:apply-templates select="ancestor::refNum:refNum" mode="spar_digiprovMD_init_objets">
                <xsl:with-param name="objetAssocie" select="." />
            </xsl:apply-templates>
        </xsl:for-each>

        <xsl:apply-templates select="." mode="spar_digiprovMD_init_preingest" />
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="spar_digiprovMD_init_creation">
        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('spar_creation', 0, '')" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_creation'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>
                        <premis:eventType>packageCreation</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>Création d'un paquet compatible avec SPAR</premis:eventDetail>
                        <premis:linkingAgentIdentifier>
                            <premis:linkingAgentIdentifierType>script</premis:linkingAgentIdentifierType>
                            <premis:linkingAgentIdentifierValue>refNum2Mets.xsl</premis:linkingAgentIdentifierValue>
                            <premis:linkingAgentRole>performer</premis:linkingAgentRole>
                        </premis:linkingAgentIdentifier>
                        <premis:linkingAgentIdentifier>
                            <premis:linkingAgentIdentifierType>producerIdentifier</premis:linkingAgentIdentifierType>
                            <premis:linkingAgentIdentifierValue>NUM</premis:linkingAgentIdentifierValue>
                            <premis:linkingAgentRole>issuer</premis:linkingAgentRole>
                        </premis:linkingAgentIdentifier>
                        <premis:linkingObjectIdentifier>
                            <premis:linkingObjectIdentifierType>productionIdentifier</premis:linkingObjectIdentifierType>
                            <premis:linkingObjectIdentifierValue>
                                <xsl:value-of select="refNum:document/@identifiant" />
                            </premis:linkingObjectIdentifierValue>
                        </premis:linkingObjectIdentifier>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="spar_digiprovMD_init_objets">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('spar_objets', 0, $objetAssocie)" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_objets'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>
                        <premis:eventType>
                            <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@eventType" />
                        </premis:eventType>
                        <premis:eventDateTime>
                            <xsl:choose>
                                <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                                    <xsl:value-of select="refNum:document/refNum:production/refNum:dateNumerisation" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$objetAssocie/@date" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </premis:eventDateTime>
                        <premis:eventDetail>
                            <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@eventDetail" />
                        </premis:eventDetail>
                        <premis:linkingAgentIdentifier>
                            <premis:linkingAgentIdentifierType>producerIdentifier</premis:linkingAgentIdentifierType>
                            <premis:linkingAgentIdentifierValue>NUM</premis:linkingAgentIdentifierValue>
                            <premis:linkingAgentRole>implementer</premis:linkingAgentRole>
                        </premis:linkingAgentIdentifier>
                        <premis:linkingObjectIdentifier>
                            <premis:linkingObjectIdentifierType>productionIdentifier</premis:linkingObjectIdentifierType>
                            <premis:linkingObjectIdentifierValue>
                                <xsl:value-of select="refNum:document/@identifiant" />
                            </premis:linkingObjectIdentifierValue>
                        </premis:linkingObjectIdentifier>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="spar_digiprovMD_init_preingest">
        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('spar_preingest', 0, '')" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_preingest'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>
                        <premis:eventType>preIngest</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventOutcomeInformation>
                            <premis:eventOutcome>arkRetrieval</premis:eventOutcome>
                            <premis:eventOutcomeDetail>
                                <premis:eventOutcomeDetailNote>Récupération de l'identifiant ARK</premis:eventOutcomeDetailNote>
                            </premis:eventOutcomeDetail>
                        </premis:eventOutcomeInformation>
                        <premis:linkingObjectIdentifier>
                            <premis:linkingObjectIdentifierType>ark</premis:linkingObjectIdentifierType>
                            <premis:linkingObjectIdentifierValue>
                                <xsl:value-of select="$arkComplet" />
                            </premis:linkingObjectIdentifierValue>
                        </premis:linkingObjectIdentifier>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>
    </xsl:template>

    <!-- TODO Valider la représentation Premis. -->
    <xsl:template match="/refNum:refNum" mode="spar_techMD">
        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('spar_techMD', 0, '')" />

        <xsl:element name="techMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <mdWrap MIMETYPE="text/xml" MDTYPE="PREMIS:OBJECT">
                <xmlData>
                    <premis:object xsi:type="premis:representation">
                        <premis:objectIdentifier>
                            <premis:objectIdentifierType>ark</premis:objectIdentifierType>
                            <premis:objectIdentifierValue>
                                <xsl:value-of select="$arkComplet" />
                            </premis:objectIdentifierValue>
                        </premis:objectIdentifier>
                        <premis:objectIdentifier>
                            <premis:objectIdentifierType>productionIdentifier</premis:objectIdentifierType>
                            <premis:objectIdentifierValue>
                                <xsl:value-of select="refNum:document/@identifiant" />
                            </premis:objectIdentifierValue>
                        </premis:objectIdentifier>
                        <premis:objectIdentifier>
                            <premis:objectIdentifierType>versionIdentifier</premis:objectIdentifierType>
                            <premis:objectIdentifierValue>version0.release0</premis:objectIdentifierValue>
                        </premis:objectIdentifier>
                        <!-- TODO Premis relatedObjetIdentifier.
                        <premis:relationship>
                            <premis:relationshipType>track</premis:relationshipType>
                            <premis:relationshipSubType>channel</premis:relationshipSubType>
                            <premis:relatedObjectIdentification>
                                <premis:relatedObjectIdentifierType>ark</premis:relatedObjectIdentifierType>
                                <premis:relatedObjectIdentifierValue>ark:/12148/br2d22g</premis:relatedObjectIdentifierValue>
                            </premis:relatedObjectIdentification>
                        </premis:relationship>
                        -->
                        <!-- Uniquement pour un périodique. -->
                        <xsl:if test="$parametres/periodique/@remplir = 'true'">
                            <premis:relationship>
                                <premis:relationshipType>structural</premis:relationshipType>
                                <premis:relationshipSubType>isPartOf</premis:relationshipSubType>
                                <premis:relatedObjectIdentification>
                                    <premis:relatedObjectIdentifierType>ark</premis:relatedObjectIdentifierType>
                                    <premis:relatedObjectIdentifierValue>
                                        <xsl:text>ark:/</xsl:text>
                                        <xsl:value-of select="$parametres/ark/institution" />
                                        <xsl:text>/</xsl:text>
                                        <xsl:value-of select="$parametres/periodique/ark" />
                                    </premis:relatedObjectIdentifierValue>
                                    <premis:relatedObjectSequence>
                                        <xsl:value-of select="$parametres/periodique/processingSet" />
                                    </premis:relatedObjectSequence>
                                </premis:relatedObjectIdentification>
                            </premis:relationship>
                        </xsl:if>
                    </premis:object>
                </xmlData>
            </mdWrap>
    </xsl:element>
    </xsl:template>

    <!-- Informations de fin de traitement Spar. -->
    <xsl:template match="/refNum:refNum" mode="spar_digiprovMD_fin">
        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('spar_fin', 0, '')" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 1" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 1" />
                        </xsl:call-template>
                        <premis:eventType>packageReception</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>packageReception is valid</premis:eventDetail>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="1" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 2" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId  + 2" />
                        </xsl:call-template>
                        <premis:eventType>requestAudit</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>requestAudit is valid</premis:eventDetail>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="2" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 3" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 3" />
                        </xsl:call-template>
                        <premis:eventType>metsValidation</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>metsValidation is valid</premis:eventDetail>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="3" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 4" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 4" />
                        </xsl:call-template>
                        <premis:eventType>packageSearch</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>packageSearch is valid</premis:eventDetail>
                        <premis:eventOutcomeInformation>
                            <premis:eventOutcome>NUM</premis:eventOutcome>
                        </premis:eventOutcomeInformation>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="4" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 5" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 5" />
                        </xsl:call-template>
                        <premis:eventType>packageAudit</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>packageAudit is valid</premis:eventDetail>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="5" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 6" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 6" />
                        </xsl:call-template>
                        <premis:eventType>filesProcessing</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>filesProcessing is valid</premis:eventDetail>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="6" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 7" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 7" />
                        </xsl:call-template>
                        <premis:eventType>idGeneration</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>idGeneration is valid</premis:eventDetail>
                        <premis:eventOutcomeInformation>
                            <premis:eventOutcome>
                                <xsl:value-of select="$arkComplet" />
                            </premis:eventOutcome>
                        </premis:eventOutcomeInformation>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="7" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>

        <!-- Uniquement pour un périodique. -->
        <xsl:if test="$parametres/periodique/@remplir = 'true'">
            <xsl:element name="digiprovMD">
                <xsl:attribute name="ID">
                    <xsl:text>AMD.</xsl:text>
                    <xsl:value-of select="$numeroId + 8" />
                </xsl:attribute>
                <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                    <xmlData>
                        <premis:event>
                            <xsl:call-template name="premisEventIdentifier">
                                <xsl:with-param name="partie" select="'spar_fin'" />
                                <xsl:with-param name="numeroId" select="$numeroId + 8" />
                            </xsl:call-template>
                            <premis:eventType>setProcessing</premis:eventType>
                            <premis:eventDateTime>
                                <xsl:value-of select="current-dateTime()"/>
                            </premis:eventDateTime>
                            <premis:eventDetail>setProcessing is valid</premis:eventDetail>
                            <premis:eventOutcomeInformation>
                                <premis:eventOutcome>
                                    <xsl:text>set already present in SPAR with ark: </xsl:text>
                                    <xsl:text>ark:/</xsl:text>
                                    <xsl:value-of select="$parametres/ark/institution" />
                                    <xsl:text>/</xsl:text>
                                    <xsl:value-of select="$parametres/periodique/ark" />
                                </premis:eventOutcome>
                                <premis:eventOutcomeDetail>
                                    <premis:eventOutcomeDetailNote>
                                        <xsl:text>Related object sequence processing successful: </xsl:text>
                                        <xsl:value-of select="$parametres/periodique/processingSet" />
                                    </premis:eventOutcomeDetailNote>
                                </premis:eventOutcomeDetail>
                            </premis:eventOutcomeInformation>
                            <xsl:call-template name="premisLinkingAgentIdentifier">
                                <xsl:with-param name="numero" select="8" />
                            </xsl:call-template>
                        </premis:event>
                    </xmlData>
                </mdWrap>
            </xsl:element>
        </xsl:if>

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId + 8 + number($parametres/periodique/@remplir = 'true')" />
            </xsl:attribute>
            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'spar_fin'" />
                            <xsl:with-param name="numeroId" select="$numeroId + 8 + number($parametres/periodique/@remplir = 'true')" />
                        </xsl:call-template>
                        <premis:eventType>ingestCompletion</premis:eventType>
                        <premis:eventDateTime>
                            <xsl:value-of select="current-dateTime()"/>
                        </premis:eventDateTime>
                        <premis:eventDetail>ingestCompletion is valid</premis:eventDetail>
                        <premis:eventOutcomeInformation>
                            <premis:eventOutcome>
                                <xsl:text>ark</xsl:text>
                                <xsl:text>-</xsl:text>
                                <xsl:value-of select="$parametres/ark/institution" />
                                <xsl:text>-</xsl:text>
                                <xsl:value-of select="$arkId" />
                                <xsl:text>.version0.release0.tar</xsl:text>
                            </premis:eventOutcome>
                        </premis:eventOutcomeInformation>
                        <xsl:call-template name="premisLinkingAgentIdentifier">
                            <xsl:with-param name="numero" select="8 + number($parametres/periodique/@remplir = 'true')" />
                        </xsl:call-template>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>
    </xsl:template>

    <!-- Renvoie le Premis linkingAgentIdentifier d'un élément pour Spar. -->
    <xsl:template name="premisLinkingAgentIdentifier">
        <xsl:param name="numero" select="0" />

        <premis:linkingAgentIdentifier>
            <premis:linkingAgentIdentifierType>
                <xsl:value-of select="$parametres/spar/linkingAgentIdentifier/type" />
            </premis:linkingAgentIdentifierType>
            <premis:linkingAgentIdentifierValue>
                <xsl:text>ark:/</xsl:text>
                <xsl:value-of select="$parametres/ark/institution" />
                <xsl:text>/</xsl:text>
                <xsl:value-of select="$parametres/spar/linkingAgentIdentifier/valueBase" />
                <xsl:value-of select="r2m:numeroFixe($numero, 2)" />
            </premis:linkingAgentIdentifierValue>
            <premis:linkingAgentRole>performer</premis:linkingAgentRole>
        </premis:linkingAgentIdentifier>
    </xsl:template>

    <!-- ==============================================================
    Fonctions spécifiques pour le profil BnF.
    =============================================================== -->

    <xsl:function name="r2m:attributPagination">
        <xsl:param name="fichier" />

        <xsl:variable name="typePaginationSelect"
        select="$profil/section/DescriptiveMetadataSection_fichiers/titre/typePaginationSelect" />
        <xsl:if test="$typePaginationSelect">
            <xsl:variable name="valeur" select="$codes/typePagination
                    /entry[@code = $fichier/../@typePagination]
                    /@*[name() = $typePaginationSelect]" />
            <xsl:if test="$valeur">
                <xsl:attribute name="xsi:type">
                    <xsl:value-of select="$typePaginationSelect" />
                    <xsl:text>:</xsl:text>
                    <xsl:value-of select="$valeur" />
                </xsl:attribute>
            </xsl:if>
        </xsl:if>
    </xsl:function>

</xsl:stylesheet>

